#!/usr/bin/env bash
# diskusage.sh — value producer for the Disks panel.
#
# Runs `df -P -h`, drops pseudo/virtual filesystems (tmpfs, overlay, devtmpfs,
# squashfs, ...) and prints one line per real filesystem:
#   <mountpoint>|<used>|<size>|<use%>|<filesystem>

set -uo pipefail

command -v df >/dev/null 2>&1 || exit 0

df -P -h 2>/dev/null | awk '
NR == 1 { next }
{
    fs=$1; size=$2; used=$3; avail=$4; cap=$5; mnt=$6
    if (fs == "" || mnt == "") next

    # skip pseudo / virtual filesystems by source
    if (fs ~ /^(tmpfs|devtmpfs|overlay|squashfs|ramfs|proc|sysfs|devpts|cgroup|cgroup2|autofs|mqueue|hugetlbfs|debugfs|tracefs|configfs|fusectl|pstore|bpf|nsfs|securityfs|efivarfs|binfmt_misc|rpc_pipefs)$/) next

    # skip kernel pseudo mount points
    if (mnt ~ /^\/(proc|sys|dev)(\/|$)/) next
    if (mnt ~ /^\/run(\/|$)/) next
    if (mnt ~ /^\/var\/(lib\/(docker|containers|podman|snapd)|run)(\/|$)/) next

    gsub(/%/, "", cap)
    if (cap == "") cap=0
    print mnt "|" used "|" size "|" cap "|" fs
}'
