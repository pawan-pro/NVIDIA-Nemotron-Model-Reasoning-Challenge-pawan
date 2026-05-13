#!/usr/bin/env bash
set -euo pipefail

if ! command -v kaggle >/dev/null 2>&1; then
  echo "WARN: kaggle CLI not found in PATH." >&2
  echo "Install the official GitHub-backed CLI before pushing kernels." >&2
  exit 0
fi

echo "kaggle binary: $(command -v kaggle)"
kaggle --version

if [[ -n "${KAGGLE_API_TOKEN:-}" ]]; then
  echo "PASS: KAGGLE_API_TOKEN is set"
elif [[ -f "${HOME}/.kaggle/access_token" ]]; then
  echo "PASS: Kaggle access token exists at ~/.kaggle/access_token"
elif [[ -f "${HOME}/.config/kaggle/kaggle.json" ]]; then
  echo "PASS: legacy Kaggle credentials file exists at ~/.config/kaggle/kaggle.json"
else
  echo "WARN: Kaggle credentials are missing." >&2
  echo "Run 'kaggle auth login' or save an API token to ~/.kaggle/access_token." >&2
fi
