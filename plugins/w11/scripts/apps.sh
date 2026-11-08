#!/usr/bin/env bash
# apps.sh — lists installed desktop applications as JSON for the Dock picker.
#
# Output: {"apps":[{"id","name","icon","exec"}, ...]}  (sorted by name)
# Sources: the standard XDG application directories; first definition of a key
# in a .desktop file wins (the desktop spec's grouping rules are ignored on
# purpose — we only need name/icon/exec).
set -euo pipefail

python3 - <<'PY'
import os
import re
import glob
import json

DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/local/share/applications",
    "/usr/share/applications",
]

FIELD_CODES = re.compile(r"\s*%[fFuUdDnNickvm]")
seen = set()
apps = []

for d in DIRS:
    for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                text = fh.read()
        except OSError:
            continue

        entry = {}
        in_main = False
        for raw in text.splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("[") and line.endswith("]"):
                in_main = (line == "[Desktop Entry]")
                continue
            if not in_main or "=" not in line:
                continue
            key, value = line.split("=", 1)
            entry.setdefault(key.strip(), value.strip())

        if entry.get("Type") != "Application":
            continue
        if entry.get("NoDisplay", "").lower() == "true":
            continue
        if entry.get("Hidden", "").lower() == "true":
            continue

        name = entry.get("Name", "").strip()
        if not name:
            continue

        app_id = os.path.basename(f)[: -len(".desktop")]
        if app_id in seen:
            continue
        seen.add(app_id)

        exec_cmd = FIELD_CODES.sub("", entry.get("Exec", "")).strip()
        icon = entry.get("Icon", "").strip()
        apps.append({"id": app_id, "name": name, "icon": icon, "exec": exec_cmd})

apps.sort(key=lambda a: a["name"].lower())
print(json.dumps({"apps": apps}))
PY
