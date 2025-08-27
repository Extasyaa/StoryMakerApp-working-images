#!/usr/bin/env bash
set -Eeuo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$here"

# Подхватить .env (ключи и настройки провайдеров)
if [[ -f "$here/.env" ]]; then
  set -a
  . "$here/.env"
  set +a
fi

# Гарантируем, что Python увидит пакет appstories
export PYTHONPATH="$here:${PYTHONPATH:-}"

venv_py="$here/.venv/bin/python"
if [[ ! -x "$venv_py" ]]; then
  echo "Venv not found at $venv_py. Run bootstrap.sh first." >&2
  exit 2
fi

exec "$venv_py" -m appstories.cli "$@"
