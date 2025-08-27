#!/usr/bin/env bash
set -Eeuo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$here"
: "${PYTHON_BIN:=/Library/Frameworks/Python.framework/Versions/3.13/bin/python3}"
"$PYTHON_BIN" -m venv .venv
./.venv/bin/python -m pip install --upgrade pip
./.venv/bin/python -m pip install -r requirements.txt
./.venv/bin/python -m appstories.cli doctor || true
./.venv/bin/python -m appstories.cli smoke --out "smoke_test.mp4" || true
echo "[OK] bootstrap finished"
