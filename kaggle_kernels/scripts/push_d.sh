#!/usr/bin/env bash
set -euo pipefail

kaggle kernels push -p kaggle_kernels/notebook_d_category_validation/ --accelerator NvidiaRtxPro6000
