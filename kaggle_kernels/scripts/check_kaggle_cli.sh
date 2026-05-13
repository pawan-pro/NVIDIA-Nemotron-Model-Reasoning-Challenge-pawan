#!/usr/bin/env bash
set -euo pipefail

if ! command -v kaggle >/dev/null 2>&1; then
  echo "WARN: kaggle CLI not found in PATH." >&2
  echo "Install the official GitHub-backed CLI before pushing kernels." >&2
  exit 0
fi

echo "kaggle binary: $(command -v kaggle)"
kaggle --version

if [[ -f "${HOME}/.config/kaggle/kaggle.json" ]]; then
  echo "PASS: Kaggle credentials file exists at ~/.config/kaggle/kaggle.json"
else
  echo "WARN: Kaggle credentials file missing at ~/.config/kaggle/kaggle.json" >&2
fi
