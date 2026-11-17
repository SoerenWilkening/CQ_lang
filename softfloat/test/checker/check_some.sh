#!/bin/sh
# check_some.sh default|f80 ENTRY...: check.sh on each entry in turn (one heavy run at a time)
T=$(cd "$(dirname "$0")" && pwd)
P=$1; shift
for e in "$@"; do sh "$T/check.sh" "$P" "$e"; done
