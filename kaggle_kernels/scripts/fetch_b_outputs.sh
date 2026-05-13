#!/usr/bin/env bash
set -euo pipefail

mkdir -p kaggle_outputs/notebook_b_asstloss
kaggle kernels output jatalepawan/notebook-b-v12-nemotron-sft-with-assistant-only -p kaggle_outputs/notebook_b_asstloss
