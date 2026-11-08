#!/usr/bin/env bash
set -euo pipefail
file="${1:?settings file}"
key="${2:?key}"
value="${3:?json value}"
python3 - "$file" "$key" "$value" <<'PY'
import json, os, sys, tempfile
path, key, raw = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    value = json.loads(raw)
except Exception:
    value = raw
os.makedirs(os.path.dirname(path), exist_ok=True)
try:
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    data = {}
if not isinstance(data, dict):
    data = {}
scope = data.setdefault("w11", {})
if not isinstance(scope, dict):
    scope = {}
    data["w11"] = scope
scope[key] = value
fd, tmp = tempfile.mkstemp(prefix="settings.json.", dir=os.path.dirname(path))
with os.fdopen(fd, "w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
os.replace(tmp, path)
PY
