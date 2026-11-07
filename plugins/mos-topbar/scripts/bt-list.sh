#!/usr/bin/env bash
# mos-topbar — known Bluetooth devices for the floating Bluetooth panel.
# TSV: <mac>\t<name>\t<connected 1|0>
set -uo pipefail
connected="$(bluetoothctl devices Connected 2>/dev/null | awk '$1 == "Device" { print $2 }' | tr '\n' ' ')"
bluetoothctl devices 2>/dev/null | awk -v conn=" $connected " '
  $1 == "Device" {
    mac = $2
    name = $3
    for (i = 4; i <= NF; i++) name = name " " $i
    linked = (index(conn, " " mac " ") > 0) ? 1 : 0
    if (name == "") name = mac
    print mac "\t" name "\t" linked
  }
'
