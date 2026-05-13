#!/usr/bin/env bash
set -euo pipefail

if ! kaggle kernels push -p kaggle_kernels/notebook_b_asstloss/ --accelerator NvidiaRtxPro6000; then
  echo "ERROR: Notebook B push with --accelerator NvidiaRtxPro6000 failed." >&2
  echo "Fallback: verify your Kaggle CLI version supports NvidiaRtxPro6000 and that your account or competition allows it." >&2
  echo "If needed, inspect 'kaggle kernels push --help' and retry with a supported accelerator for your account." >&2
  exit 1
fi
