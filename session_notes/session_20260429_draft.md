# Session Note — 2026-04-29 (Draft)

## Objective
Pivot from the failed improvised tiny-learning notebook toward a Kaggle-first training pipeline patterned after the successful public competition approach.

## Starting point
- Safe submission notebook works and creates a valid `submission.zip`.
- Offline prompt-eval notebook works and best local prompt remains `P3_metric_aligned`.
- Tiny LS notebook remains blocked by the OOM vs auto-offload/backward tradeoff in Kaggle.
- Public competition materials now strongly suggest that strong SFT results are achievable in a Kaggle-centered workflow.

## What was reviewed
Reviewed public competition materials including:
- Tong Hui Kang’s public discussion posts
- attached training metrics and training logprobs
- official competition overview, metric notebook, and model/material files

## Main conclusion from review
The updated conclusion is:
- stay **Kaggle-first**
- but stop using the improvised tiny LS notebook as the main training path
- rebuild around a pipeline of:
  1. deterministic trace generation
  2. Kaggle SFT notebook
  3. adapter validation notebook
  4. frozen packaging notebook

This is more consistent with the successful public pattern than our current LS notebook path.

## What was implemented today
### 1. Created Notebook A v1 in GitHub
Notebook created:
- `notebooks/nemotron_trace_generator_20260429.ipynb`

Purpose:
- read `train.csv`
- classify problems by category
- generate deterministic boxed-answer traces
- export an SFT-ready corpus for later training

### 2. Fixed a notebook syntax bug
The first pushed version had a multiline string bug in `user_content`. This was fixed and pushed.

### 3. Ran Notebook A v1 in Kaggle
Notebook A v1 successfully exported:
- `train_traces_v1.jsonl`
- `train_traces_v1_preview.csv`
- `train_traces_v1_stats.csv`
- `train_traces_v1_skipped.csv`

Generated category counts:
- `gravity`: 1597
- `unit_conversion`: 1594
- `numeral`: 1576

## What was learned
### Working
- The trace-generation pipeline works end-to-end in Kaggle.
- Category partitioning for the first three categories looks correct.
- We now have a data-generation notebook that can feed a later SFT notebook.

### Remaining issue in Notebook A v1
Generated traces currently lose the leading backslash in the final answer marker:
- observed output: `oxed{...}`
- expected output: `\boxed{...}`

So the next immediate fix is formatting/escaping in the final answer string before expanding to more categories.

### Important interpretation
This is a much better place to be than the earlier LS notebook loop:
- we are now building the training data pipeline first
- instead of forcing a fragile direct training attempt without a proper trace corpus

## Linear update
Linear blocker issue updated:
- `KAG-1 — Nemotron Kaggle blocker: tiny LoRA training fails in notebook runtime`

Update added:
- public-material review summary
- Notebook A v1 creation
- Kaggle run result
- current formatting bug
- updated Kaggle-first plan

## Recommended next steps
1. Patch the `\boxed{...}` formatting bug in Notebook A v1.
2. Re-run Notebook A v1 and verify traces end with correct boxed answers.
3. Build Notebook A v2 for:
   - `cipher`
   - `bit_manipulation`
   - `equation_numeric`
4. After trace generation coverage is good enough, build the new Kaggle SFT notebook based on this generated corpus.
5. Keep the frozen packaging notebook unchanged.

## Summary line
2026-04-29 successfully shifted the project onto a Kaggle-first training-data path: the new trace generator notebook works for numeral, gravity, and unit conversion, and the immediate next task is to fix boxed-answer formatting and then expand trace generation to the harder categories.