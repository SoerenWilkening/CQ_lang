#!/bin/bash
# run every listed probe through run.sh with an optional cq-opt (scratch)
cd "$(dirname "$0")"
OPT=$1; shift
for f in "$@"; do bash run.sh $f.c $OPT; done
