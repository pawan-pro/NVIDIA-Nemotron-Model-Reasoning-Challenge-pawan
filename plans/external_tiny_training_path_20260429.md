# External Tiny Training Path — 2026-04-29

## Goal
Define the smallest realistic training path outside the current Kaggle notebook runtime, then bring the resulting adapter back into the safe Kaggle packaging notebook for submission.

## Why this plan exists
Current evidence shows:
- Kaggle packaging notebook works and creates `submission.zip`
- Kaggle offline prompt-eval notebook works
- Kaggle tiny training notebook remains blocked by the OOM vs auto-offload/backward tradeoff for Nemotron-3-Nano-30B hybrid Mamba/MoE

So the next meaningful improvement should come from a more compatible training environment.

## Frozen notebook roles
### Keep frozen
- `notebooks/nemotron_submission_packaging_20260428.ipynb`
  - submission-only
  - creates `adapter_config.json`, `adapter_model.safetensors`, `submission.zip`

### Keep for research only
- `notebooks/nemotron_offline_prompt_eval_20260427.ipynb`
  - local prompt comparison only
  - best local prompt so far: `P3_metric_aligned`

### Keep as blocker reference only
- `notebooks/nemotron_submission_packaging_ls_20260428.ipynb`
  - reference for failed Kaggle tiny-training attempts
  - do not keep spending Kaggle compute retrying this path

## External training target
Train a tiny LoRA adapter outside Kaggle with the smallest meaningful settings:
- model: Nemotron-3-Nano-30B
- LoRA rank: 32
- target modules: `q_proj`, `k_proj`, `v_proj`, `o_proj`
- train subset: 8 to 32 rows first
- epochs: 1
- max length: 256 to 512
- answer format: boxed final answer aligned to `P3_metric_aligned`

## Minimum success criterion
A win is:
1. training completes in the external environment
2. adapter files are saved:
   - `adapter_config.json`
   - `adapter_model.safetensors`
3. adapter can be dropped into Kaggle safe packaging flow
4. resulting `submission.zip` is valid and submit-ready

## Recommended implementation sequence
1. external environment loads base model and tokenizer successfully
2. verify one forward + backward pass works
3. run 4-row micro-train
4. if stable, run 8-row tiny train
5. export adapter artifacts only
6. bring artifacts into Kaggle submission packaging notebook
7. create final `submission.zip`
8. submit and compare against shell baseline

## Main risk controls
- do not change the frozen Kaggle packaging notebook
- do not run repeated full-model tiny-training retries in Kaggle notebooks
- treat prompt formatting and adapter packaging as solved subproblems
- focus only on the external training environment compatibility

## Immediate next operational tasks
1. attach latest failed LS notebook reference to Linear blocker issue `KAG-1`
2. keep Git and Linear aligned on blocker status
3. define the external runtime that will be used for the first 4-row micro-train
4. once adapter artifacts exist, use Kaggle only for packaging and submission
