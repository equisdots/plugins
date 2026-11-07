#!/usr/bin/env bash
set -uo pipefail
python3 - <<'PY' 2>/dev/null
import os, urllib.parse, xml.etree.ElementTree as ET
p = os.path.expanduser("~/.local/share/recently-used.xbel")
try:
    root = ET.parse(p).getroot()
except Exception:
    raise SystemExit(0)
files = []
for b in root.iter():
    if not b.tag.endswith("bookmark"):
        continue
    href = b.get("href", "")
    if not href.startswith("file://"):
        continue
    path = urllib.parse.unquote(urllib.parse.urlparse(href).path)
    if not os.path.isfile(path):
        continue
    files.append((b.get("modified", ""), path, os.path.basename(path)))
for _, path, name in sorted(files, reverse=True)[:20]:
    print(path + "\t" + name)
PY
