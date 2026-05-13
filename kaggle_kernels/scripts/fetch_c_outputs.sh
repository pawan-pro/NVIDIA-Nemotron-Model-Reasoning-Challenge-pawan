#!/usr/bin/env bash
set -euo pipefail

mkdir -p kaggle_outputs/notebook_c_packaging
kaggle kernels output jatalepawan/notebook-c-adapter-validation-submission-pack-tr -p kaggle_outputs/notebook_c_packaging

if [[ -f "kaggle_outputs/notebook_c_packaging/submission.zip" ]]; then
  echo "PASS: kaggle_outputs/notebook_c_packaging/submission.zip exists"
else
  echo "FAIL: kaggle_outputs/notebook_c_packaging/submission.zip missing" >&2
  exit 1
fi
