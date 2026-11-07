#!/usr/bin/env bash
# mos-topbar — Wi-Fi networks for the floating Wi-Fi panel.
# TSV: <in-use * or empty>\t<ssid>\t<signal>\t<security>
set -uo pipefail
nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | awk -F: '
  NF >= 4 {
    inuse = $1; ssid = $2; signal = $3; security = $4
    for (i = 5; i <= NF; i++) security = security ":" $i
    if (ssid == "" || seen[ssid]++) next
    print inuse "\t" ssid "\t" signal "\t" security
  }
' | head -n 20
