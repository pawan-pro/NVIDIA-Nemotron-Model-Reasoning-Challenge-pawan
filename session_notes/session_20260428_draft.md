# Session Note — 2026-04-28 (Draft)

## Objective
Move from prompt-only improvements and shell-adapter packaging toward the smallest true learning step that still produces a valid Kaggle submission.

## Starting point
- Known-good packaging path exists and creates a valid `submission.zip`.
- Offline prompt-eval notebook works on RTX Pro 6000.
- Best tested prompt so far is `P3_metric_aligned`.
- Prompt-only uplift was small, so the next real step had to be a tiny non-empty learning update.

## What was done
1. Kept notebook roles separated:
   - `notebooks/nemotron_offline_prompt_eval_20260427.ipynb` → evaluation only
   - `notebooks/nemotron_submission_packaging_20260428.ipynb` → frozen packaging only
   - `notebooks/nemotron_submission_packaging_ls_20260428.ipynb` → tiny-learning attempt

2. Confirmed the submission-only notebook works:
   - loads Nemotron base model
   - attaches LoRA shell
   - saves `adapter_config.json` and `adapter_model.safetensors`
   - creates `submission.zip`

3. Tried the smallest meaningful learning step in the LS notebook:
   - tiny supervised LoRA update on a very small train subset
   - narrow LoRA targets: `q_proj`, `k_proj`, `v_proj`, `o_proj`
   - prompt/target formatting aligned to `P3_metric_aligned`

4. Resolved several notebook/runtime issues while testing the LS path:
   - fixed malformed multiline string / syntax issue in training cell
   - fixed CUTLASS path handling
   - patched Triton / Nemotron runtime:
     - pure PyTorch `rmsnorm_fn` fallback
     - copied `ptxas-blackwell` to `/tmp`
     - set `TRITON_PTXAS_BLACKWELL_PATH=/tmp/ptxas-blackwell`
     - monkeypatched `nv_compiler.get_ptxas_version = lambda arch: "12.0"`
     - disabled `is_fast_path_available`
     - disabled gradient checkpointing after recomputation mismatch

## What was learned
### Working
- Packaging notebook works and produces `submission.zip`.
- Offline prompt-eval notebook works.
- Best prompt remains `P3_metric_aligned`.

### Failing path
The tiny-learning / tiny-SFT notebook remains blocked inside the Kaggle notebook runtime.

Two mutually bad states remain:
1. `device_map={"": 0}`
   - full model forced to GPU
   - fails at model load with CUDA OOM / allocator warmup
2. `device_map="auto"`
   - model loads using offload
   - training backward fails because parts of the graph are offloaded / meta, causing backward device mismatch errors

Previously resolved before this final blocker:
- `cutlass` import error
- `ptxas-blackwell` permission error
- checkpoint recomputation mismatch error

## Conclusion
Kaggle notebook environment is suitable for:
- packaging a valid adapter
- offline inference / prompt evaluation

But it is not robust for actual tiny LoRA training on Nemotron-3-Nano-30B hybrid Mamba/MoE in this setup.

## Project tracking
A dedicated Linear project was created:
- **Kaggle - NVIDIA Nemotron Reasoning Challenge**

Confirmed blocker issue created in Linear:
- **MUB-12 — Nemotron Kaggle blocker: tiny LoRA training fails in notebook runtime**
- URL: https://linear.app/mubama-group-v4-strategy/issue/MUB-12/nemotron-kaggle-blocker-tiny-lora-training-fails-in-notebook fileciteturn19file0

## Recommended next steps
1. Preserve frozen packaging notebook as submission baseline.
2. Preserve prompt-eval notebook as research-only notebook.
3. Stop spending Kaggle compute on repeated tiny-SFT retries in the current environment.
4. Define an alternate compatible training path outside this notebook runtime.
5. Bring resulting adapter artifacts back into the safe packaging notebook for submission.

## Summary line
2026-04-28 confirmed that the remaining Nemotron training blocker is environment-level: packaging and offline prompt evaluation work in Kaggle, but tiny LoRA training still fails due to the OOM vs auto-offload backward tradeoff, so the next meaningful progress likely requires an external or more compatible training environment.
