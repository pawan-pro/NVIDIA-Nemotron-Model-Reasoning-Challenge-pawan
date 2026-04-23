Skip to
content
Kaggle

Create
Home

Competitions

Datasets

Models

Benchmarks

Game Arena

Code

Discussions

Learn

More


View Active Events

Search

Kaggle Competition Metrics +1 · 20d ago · 7,308 views

Copy & Edit

246

Download
NVIDIA Nemotron Metric
Copied from Kaggle Competition Metrics (+428,-51)


Version 14 of 14
Runtime
4m 29s · GPU RTX Pro 6000

Input
DATASETS

[Private Dataset]

MODELS

Nemotron-3-Nano-30B-A3B-BF16 · ...b-a3b-bf16 · V1

Tags
Competition Metric
Other
Language
Python

Competition Metric Notebook
Validation Succeeded (eligible for use as a metric)


Collaborators
Kaggle Competition Metrics (Owner)

Ryan Holbrook (Editor)

License
This Notebook has been released under the Apache 2.0 open source license.

Continue exploring

Input
2 files

Output
1 file

Logs
269.1 second run - successful

Comments
3 comments


"""Metric for NVIDIA (129716)."""

import subprocess
import sys

# Set up environment
commands = [
    'uv pip uninstall torch torchvision torchaudio',
    'tar -cf - -C /kaggle/usr/lib/notebooks/metric/nvidia_metric_utility_script . | tar -xf - -C /tmp',
    'chmod +x /tmp/triton/backends/nvidia/bin/ptxas',
    'chmod +x /tmp/triton/backends/nvidia/bin/ptxas-blackwell',
]
for cmd in commands:
    print(f'Running: {cmd}')
    subprocess.run(cmd, shell=True, check=True)
sys.path.insert(0, '/tmp')

import glob
import math
import multiprocessing
import os
import re
import time
from pathlib import Path

import kagglehub
import pandas as pd
from tqdm import tqdm

# Configuration
MODEL_PATH = kagglehub.model_download(
    'metric/nemotron-3-nano-30b-a3b-bf16/transformers/default'
)
DATA_PATH = Path(kagglehub.dataset_download('metric/nvidia-nemotron-rerun-data-129716'))


class ParticipantVisibleError(Exception):
    pass


def cache_model(
    path: str | Path,
    exts: tuple[str, ...] = ('.bin', '.pt', '.safetensors'),
    num_workers: int | None = None,
    chunk_mb: int = 256,
) -> int:
    """Pre-read model weight files into the OS page cache to speed up later loads.

    Args:
        path        : Directory containing model files, or a single file path.
        exts        : File extensions treated as model weight files.
        num_workers : Number of threads (default = min(CPU cores, 8)).
        chunk_mb    : Size of each read chunk in MB.

    Returns:
        Total bytes read (int).
    """
    from concurrent.futures import ThreadPoolExecutor, as_completed

    def warmup_file(fpath: Path) -> tuple[Path, int]:
        """Sequentially read an entire file in chunks."""
        chunk_size = chunk_mb * 1024 * 1024
        total = 0
        try:
            with open(fpath, 'rb') as f:
                while True:
                    data = f.read(chunk_size)
                    if not data:
                        break
                    total += len(data)
        except Exception as e:
            print(f'Error reading {fpath}: {e}')
        return fpath, total

    path = Path(path)
    # Collect files to read
    files: list[Path] = []
    if path.is_dir():
        files = [p for p in path.rglob('*') if p.is_file() and str(p).endswith(exts)]
        files.sort()
    else:
        files = [path] if path.exists() else []

    if not files:
        print(f'No model files found to cache at: {path}')
        return 0

    # Decide number of worker threads
    if num_workers is None:
        try:
            num_workers = min(multiprocessing.cpu_count(), 8)
        except Exception:
            num_workers = 4

    print(f'[cache_model] {len(files)} file(s), {num_workers} worker(s)')
    t0 = time.time()
    total_bytes = 0
    # Read files in parallel
    with ThreadPoolExecutor(max_workers=num_workers) as pool:
        futures = {pool.submit(warmup_file, f): f for f in files}
        for i, fut in enumerate(as_completed(futures), 1):
            fpath, n = fut.result()
            total_bytes += n
            print(f'[{i}/{len(files)}] cached {fpath.name}')

    elapsed = time.time() - t0
    gb = total_bytes / 1024**3
    speed = gb / elapsed if elapsed > 0 else 0
    print(f'[cache_model] total read ≈ {gb:.2f} GB')
    print(f'[cache_model] elapsed {elapsed:.2f} s, ~{speed:.2f} GB/s')
    return total_bytes


def extract_final_answer(text: str | None) -> str:
    r"""Extracts the final answer from the model response.

    Prioritizes extracting answers inside `\boxed{}`.
    If no `\boxed{}` format is found, attempts to extract numbers from other formats.

    Examples:
        >>> extract_final_answer(r"The answer is \boxed{42}")
        '42'
        >>> extract_final_answer("The final answer is: 3.14")
        '3.14'
        >>> extract_final_answer("Just a number 100 in text")
        '100'
        >>> extract_final_answer(None)
        'NOT_FOUND'
    """
    if text is None:
        return 'NOT_FOUND'

    # Search for boxed answer
    # Match all instances of \boxed{...} or unclosed \boxed{ at the end
    matches = re.findall(r'\\boxed\{([^}]*)(?:\}|$)', text)
    if matches:
        non_empty = [m.strip() for m in matches if m.strip()]
        if non_empty:
            return non_empty[-1]
        return matches[-1].strip()

    # Other common formats if \boxed{} is not found
    patterns = [
        r'The final answer is:\s*([^\n]+)',
        r'Final answer is:\s*([^\n]+)',
        r'Final answer\s*[:：]\s*([^\n]+)',
        r'final answer\s*[:：]\s*([^\n]+)',
    ]
    for pattern in patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        if matches:
            return matches[-1].strip()

    # If no structured format is found, extract the last valid number in the text
    matches = re.findall(r'-?\d+(?:\.\d+)?', text)
    if matches:
        return matches[-1]

    # If no numeric answer is found, return the last line of text as a fallback
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return lines[-1] if lines else 'NOT_FOUND'


def verify(stored_answer: str, predicted: str) -> bool:
    """Verify if the answer matches.

    For numerical answers, allow them to be judged as equal within a certain relative tolerance (1e-2);
    otherwise, compare strictly as strings (case-insensitive).

    Examples:
        >>> verify("10011000", "10011000")
        True
        >>> verify("10011000", "10011001")
        False
        >>> verify("24.64", "24.6401")
        True
        >>> verify("XLVII", "xlvii")
        True
        >>> verify("11011", "00011011")
        False
    """
    # Clean up strings
    stored_answer = stored_answer.strip()
    predicted = predicted.strip()

    # If the answer is a binary string, compare strictly as strings
    if re.fullmatch(r'[01]+', stored_answer):
        return predicted.lower() == stored_answer.lower()

    try:
        # Try to convert the answers to floating point numbers
        stored_num = float(stored_answer)
        predicted_num = float(predicted)
        # Use a small absolute tolerance for numbers near zero
        return math.isclose(stored_num, predicted_num, rel_tol=1e-2, abs_tol=1e-5)
    except Exception:
        # Fallback to case-insensitive string comparison
        return predicted.lower() == stored_answer.lower()


def generate_standard_submission(submission_dir: str):
    """Processes an extracted submission archive to produce a standard submission file."""
    # Locate the LoRA files within the extracted directory
    possible_extraction_dirs = {
        '/kaggle/tmp',
        '/kaggle/working',
        submission_dir,
    }
    adapter_configs = []
    for search_dir in possible_extraction_dirs:
        if os.path.exists(search_dir):
            adapter_configs.extend(
                glob.glob(
                    os.path.join(search_dir, '**/adapter_config.json'), recursive=True
                )
            )
    if not adapter_configs:
        raise ParticipantVisibleError(
            'No adapter_config.json found in submission. Found:\n\n'
            f'{submission_dir} {os.listdir(submission_dir)}\n\n'
            f'/kaggle/tmp {os.listdir("/kaggle/tmp")}\n\n'
            f'/kaggle/input/competition_evaluation {os.listdir("/kaggle/input/competition_evaluation")}'
        )

    lora_path = os.path.dirname(adapter_configs[0])

    # Load test data
    test_df = pd.read_csv(DATA_PATH / 'test.csv', index_col=None)

    row_id_col = str(test_df.columns.to_list()[0])
    predictions = []
    for item in test_df.itertuples(index=False):
        predictions.append(
            {
                row_id_col: getattr(item, row_id_col),
                'prediction': lora_path,
            }
        )

    submission_df = pd.DataFrame(predictions)

    # Write the standard submission file to the current working directory
    submission_df.to_csv('submission.csv', index=False)


def generate_predictions(
    test_df: pd.DataFrame,
    lora_path: str,
    row_id_col: str,
    max_lora_rank: int,
    max_tokens: int,
    top_p: float,
    temperature: float,
    max_num_seqs: int,
    gpu_memory_utilization: float,
    max_model_len: int,
    debug: bool = False,
) -> pd.DataFrame:
    """Load the model and generate predictions for the provided test data.

    Args:
        debug: If True, writes a CSV file with raw model outputs and extracted predictions.
    """
    # Cache Model
    cache_model(MODEL_PATH, num_workers=16, chunk_mb=1024)

    os.environ['TRANSFORMERS_NO_TF'] = '1'
    os.environ['TRANSFORMERS_NO_FLAX'] = '1'
    os.environ['TRANSFORMERS_OFFLINE'] = '1'
    os.environ['CUDA_VISIBLE_DEVICES'] = '0'
    os.environ['TRITON_PTXAS_PATH'] = '/tmp/triton/backends/nvidia/bin/ptxas'

    from vllm import LLM, SamplingParams
    from vllm.lora.request import LoRARequest

    # Initialize vLLM Offline inference Engine
    llm = LLM(
        model=str(MODEL_PATH),
        tensor_parallel_size=1,
        max_num_seqs=max_num_seqs,
        gpu_memory_utilization=gpu_memory_utilization,
        dtype='auto',
        max_model_len=max_model_len,
        trust_remote_code=True,
        enable_lora=True,
        max_lora_rank=max_lora_rank,
        enable_prefix_caching=True,
        enable_chunked_prefill=True,
    )

    sampling_params = SamplingParams(
        temperature=temperature,
        top_p=top_p,
        max_tokens=max_tokens,
    )

    tokenizer = llm.get_tokenizer()
    prompts = []
    for item in test_df.itertuples(index=False):
        user_content = (
            item.prompt
            + '\nPlease put your final answer inside `\\boxed{}`. For example: `\\boxed{your answer}`'
        )
        # Format using the tokenizer's chat template directly
        try:
            prompt = tokenizer.apply_chat_template(
                [{'role': 'user', 'content': user_content}],
                tokenize=False,
                add_generation_prompt=True,
                enable_thinking=True,
            )
        except Exception:
            # Fallback if chat template fails
            prompt = user_content
        prompts.append(prompt)

    # Generate predictions using continuous batching
    outputs = llm.generate(
        prompts,
        sampling_params=sampling_params,
        lora_request=LoRARequest('adapter', 1, lora_path),
    )

    predictions = []
    debug_records = []
    for item, output in zip(test_df.itertuples(index=False), outputs):
        raw_text = output.outputs[0].text
        extracted_answer = extract_final_answer(raw_text)

        row_id_val = getattr(item, row_id_col)

        predictions.append(
            {
                row_id_col: row_id_val,
                'prediction': extracted_answer,
            }
        )

        if debug:
            debug_records.append(
                {
                    row_id_col: row_id_val,
                    'raw_output': raw_text,
                    'extracted_prediction': extracted_answer,
                }
            )

    # Write debug CSV if requested
    if debug and debug_records:
        debug_df = pd.DataFrame(debug_records)
        debug_df.to_csv('debug_predictions.csv', index=False)
        print('Debug data saved to debug_predictions.csv')

    return pd.DataFrame(predictions)


def score(
    solution: pd.DataFrame,
    submission: pd.DataFrame,
    row_id_column_name: str,
    max_lora_rank: int = 32,
    max_tokens: int = 3584,
    top_p: float = 1.0,
    temperature: float = 1.0,
    max_num_seqs: int = 128,
    gpu_memory_utilization: float = 0.85,
    max_model_len: int = 4096,
    debug: bool = False,
) -> float:
    r"""Evaluate the generated predictions against the ground truth.

    Submissions are evaluated based on their **Accuracy** in solving the provided
    tasks. The NVIDIA Nemotron-3-Nano-30B model is loaded with the participant's
    submitted LoRA adapter (which must include an `adapter_config.json`) using
    the vLLM inference engine. For each test case, the model is prompted to
    generate a response and instructed to place its final answer within a `\boxed{}`
    LaTeX command. The metric extracts the final answer from the generated text,
    prioritizing content within the boxed format while falling back to other
    heuristic patterns or the first numeric value found. A prediction is graded as
    correct if it matches the ground truth either exactly as a string or within a
    relative numerical tolerance of $10^{-2}$. The final score is the proportion of
    correctly answered questions.

    Args:
        solution: DataFrame containing the ground truth answers. Must include the
            row_id_column_name and an 'answer' column.
        submission: DataFrame containing the predicted answers. Must include the
            row_id_column_name and a 'prediction' column.
        row_id_column_name: The name of the ID column used to join solution and
            submission.
        max_lora_rank: Maximum rank for LoRA adapters.
        max_tokens: Maximum number of tokens to generate.
        top_p: Top-p sampling parameter.
        temperature: Temperature sampling parameter.
        max_num_seqs: Maximum number of sequences to process concurrently.
        gpu_memory_utilization: Fraction of GPU memory to allocate for the vLLM execution.
        max_model_len: Maximum context length (input + output tokens).
        debug: If True, writes raw outputs and extracted predictions to a CSV file.

    Returns:
        The accuracy score (fraction of matches) as a float.
    """
    lora_path = submission['prediction'].iloc[0]

    # Load test data and filter it to only include rows present in the solution
    test_df = pd.read_csv(DATA_PATH / 'test.csv', index_col=None)
    row_id_col = str(test_df.columns.to_list()[0])
    test_df = test_df[test_df[row_id_col].isin(solution[row_id_column_name])]

    submission = generate_predictions(
        test_df=test_df,
        lora_path=lora_path,
        row_id_col=row_id_column_name,
        max_lora_rank=max_lora_rank,
        max_tokens=max_tokens,
        top_p=top_p,
        temperature=temperature,
        max_num_seqs=max_num_seqs,
        gpu_memory_utilization=gpu_memory_utilization,
        max_model_len=max_model_len,
        debug=debug,
    )

    dataset = solution.merge(submission, on=row_id_column_name)
    num_correct = 0

    # Verify the predictions
    for item in dataset.itertuples(index=False):
        ground_truth = item.answer
        extracted_answer = item.prediction

        match = verify(str(ground_truth), str(extracted_answer))
        if match:
            num_correct += 1

    accuracy = num_correct / len(solution)
    return float(accuracy)

    Running: uv pip uninstall torch torchvision torchaudio
Using Python 3.12.12 environment at: /usr
Uninstalled 3 packages in 894ms
 - torch==2.9.0+cu126
 - torchaudio==2.9.0+cu126
 - torchvision==0.24.0+cu126
Running: tar -cf - -C /kaggle/usr/lib/notebooks/metric/nvidia_metric_utility_script . | tar -xf - -C /tmp
Running: chmod +x /tmp/triton/backends/nvidia/bin/ptxas
Running: chmod +x /tmp/triton/backends/nvidia/bin/ptxas-blackwell

Logs - 

Logs

Download Logs
Successfully ran in 269.1s
Accelerator
GPU RTX Pro 6000

Environment
Latest Container Image

Output
14.79 kB

Time
#
Log Message
2.8s	1	/usr/local/lib/python3.12/dist-packages/mistune.py:435: SyntaxWarning: invalid escape sequence '\|'
2.8s	2	  cells[i][c] = re.sub('\\\\\|', '|', cell)
3.3s	3	/usr/local/lib/python3.12/dist-packages/nbconvert/filters/filter_links.py:36: SyntaxWarning: invalid escape sequence '\_'
3.3s	4	  text = re.sub(r'_', '\_', text) # Escape underscores in display text
6.0s	5	[NbConvertApp] Converting notebook /kaggle/src/script.ipynb to script
6.8s	6	[NbConvertApp] Writing 14787 bytes to /kaggle/working/metric.py
11.6s	7	0.00s - Debugger warning: It seems that frozen modules are being used, which may
11.6s	8	0.00s - make the debugger miss breakpoints. Please pass -Xfrozen_modules=off
11.6s	9	0.00s - to python to disable frozen modules.
11.6s	10	0.00s - Note: Debugging will proceed. Set PYDEVD_DISABLE_FILE_VALIDATION=1 to disable this validation.
12.0s	11	0.00s - Debugger warning: It seems that frozen modules are being used, which may
12.0s	12	0.00s - make the debugger miss breakpoints. Please pass -Xfrozen_modules=off
12.0s	13	0.00s - to python to disable frozen modules.
12.0s	14	0.00s - Note: Debugging will proceed. Set PYDEVD_DISABLE_FILE_VALIDATION=1 to disable this validation.
13.3s	15	Running: uv pip uninstall torch torchvision torchaudio
13.4s	16	Using Python 3.12.12 environment at: /usr
13.6s	17	Using Python 3.12.12 environment at: /usr
13.6s	18	
13.6s	19	Using Python 3.12.12 environment at: /usr
14.2s	20	Uninstalled 3 packages in 894ms
14.2s	21	 - torch==2.9.0+cu126
14.2s	22	 - torchaudio==2.9.0+cu126
14.2s	23	 - torchvision==0.24.0+cu126
14.4s	24	Uninstalled 3 packages in 894ms
14.4s	25	 - torch==2.9.0+cu126
14.4s	26	 - torchaudio==2.9.0+cu126
14.4s	27	 - torchvision==0.24.0+cu126
14.4s	28	
14.4s	29	Uninstalled 3 packages in 894ms
14.4s	30	 - torch==2.9.0+cu126
14.4s	31	 - torchaudio==2.9.0+cu126
14.4s	32	 - torchvision==0.24.0+cu126
14.4s	33	Running: tar -cf - -C /kaggle/usr/lib/notebooks/metric/nvidia_metric_utility_script . | tar -xf - -C /tmp
261.9s	34	Running: chmod +x /tmp/triton/backends/nvidia/bin/ptxas
261.9s	35	Running: chmod +x /tmp/triton/backends/nvidia/bin/ptxas-blackwell
265.8s	36	/usr/local/lib/python3.12/dist-packages/traitlets/traitlets.py:2915: FutureWarning: --Exporter.preprocessors=["remove_papermill_header.RemovePapermillHeader"] for containers is deprecated in traitlets 5.0. You can pass `--Exporter.preprocessors item` ... multiple times to add items to a list.
265.8s	37	  warn(
265.9s	38	[NbConvertApp] Converting notebook __notebook__.ipynb to notebook
266.0s	39	[NbConvertApp] Writing 21783 bytes to __notebook__.ipynb
268.1s	40	/usr/local/lib/python3.12/dist-packages/traitlets/traitlets.py:2915: FutureWarning: --Exporter.preprocessors=["nbconvert.preprocessors.ExtractOutputPreprocessor"] for containers is deprecated in traitlets 5.0. You can pass `--Exporter.preprocessors item` ... multiple times to add items to a list.
268.1s	41	  warn(
268.2s	42	[NbConvertApp] Converting notebook __notebook__.ipynb to html
268.6s	43	[NbConvertApp] Writing 329338 bytes to __results__.html