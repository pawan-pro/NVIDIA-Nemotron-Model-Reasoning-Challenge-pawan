# Kaggle CLI Workflow

This folder contains a CLI-first workflow for the NVIDIA Nemotron Model Reasoning Challenge kernels.

Install the official Kaggle CLI from the current GitHub-backed codebase, not the deprecated unofficial `kaggle-cli` package:

```bash
pipx install 'git+https://github.com/Kaggle/kaggle-cli.git'
```

If you prefer `pip`:

```bash
python3.11 -m pip install --user 'git+https://github.com/Kaggle/kaggle-cli.git'
export PATH="$HOME/Library/Python/3.11/bin:$PATH"
```

Authenticate with OAuth:

```bash
kaggle auth login
```

The check script verifies OAuth without printing the cached token.

If you prefer a token file, generate an API token in Kaggle settings and save it at:

```text
~/.kaggle/access_token
```

The older `~/.config/kaggle/kaggle.json` path is kept as a legacy fallback. Never commit `kaggle.json`, `access_token`, or any Kaggle secret.

Current best:

- Version 15
- `adapter_sft_v2_bit_bal128_asstloss`
- public score `0.56`

Safety:

- Keep the current `0.56` submission selected until a higher score is confirmed.

Warning:

- Notebook C must package `adapter_sft_v2_bit_bal128_asstloss.zip`, not `adapter_sft64_v1_1.zip`.

Run order:

1. `bash kaggle_kernels/scripts/check_kaggle_cli.sh`
2. `bash kaggle_kernels/scripts/push_b.sh`
3. `bash kaggle_kernels/scripts/status_b.sh`
4. Once Notebook B completes, `bash kaggle_kernels/scripts/push_c.sh`
5. `bash kaggle_kernels/scripts/status_c.sh`
6. `bash kaggle_kernels/scripts/fetch_c_outputs.sh`
7. Submit `submission.zip` via the Kaggle UI or notebook submit panel

Category validation run order:

1. Notebook B trains the LoRA adapter.
2. Notebook C packages the adapter into `/kaggle/working/submission.zip`.
3. Notebook D validates category-level behavior from the Notebook C output.

Notebook D:

- Push with `bash kaggle_kernels/scripts/push_d.sh`.
- Check with `bash kaggle_kernels/scripts/status_d.sh`.
- Inspect logs with `bash kaggle_kernels/scripts/logs_d.sh`.
- It may require RTX Pro 6000 because it runs vLLM inference with the submitted LoRA.
- It is validation-only and must not be used for leaderboard submission.
- Do not fetch large adapter files locally.
- If fetching D outputs, fetch only diagnostic CSVs where possible, not `submission.zip` or large adapter artifacts.

Notebook wiring:

- Notebook C must have competition input `nvidia-nemotron-model-reasoning-challenge`.
- Notebook C must also include Notebook B output input from `jatalepawan/notebook-b-v12-nemotron-sft-with-assistant-only`.
- In Kaggle kernel metadata, `kernel_sources` is represented as `username/kernel-slug`, so this repo uses that slug in Notebook C metadata.
- Notebook D must include Notebook C output input from `jatalepawan/notebook-c-adapter-validation-submission-pack-tr`.
