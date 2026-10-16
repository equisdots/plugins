#!/usr/bin/env bash
# kernelbar — value producer for the Kernel bar module.
set -uo pipefail
printf '%s' "$(uname -r | cut -d- -f1)"
