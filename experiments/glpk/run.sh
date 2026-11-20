#!/bin/sh
# q.c with every GLPK source file (src/, glpk-5.0 from ftp.gnu.org) as one module. Extra arguments go to cqcc.
set -eu
cd "$(dirname "$0")"
. ../common.sh
G=src/glpk-5.0/src
cq_run q.c $(find "$G" -name '*.c' | sort) $(for d in "$G" "$G"/*/; do printf ' -I%s' "$d"; done) "$@"
