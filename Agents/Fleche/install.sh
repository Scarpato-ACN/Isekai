#!/usr/bin/env bash
# Flèche — installazione su macOS e Linux
#
# Rileva l'interprete Python, scrive hooks.json, verifica che gli hook
# funzionino davvero. Non basta che i file esistano: un hook che c'è ma non
# parte non produce alcun segnale durante l'uso — l'azione passa e nessuno se
# ne accorge.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1; then
    if "$c" -c 'import sys;exit(0 if sys.version_info[0]==3 else 1)' 2>/dev/null; then
      PY="$c"; break
    fi
  fi
done

if [[ -z "$PY" ]]; then
  echo "✗ nessun interprete Python 3 trovato." >&2
  echo "  Flèche richiede Python 3. Installalo e ripeti." >&2
  exit 1
fi

exec "$PY" "$HERE/tools/setup.py"
