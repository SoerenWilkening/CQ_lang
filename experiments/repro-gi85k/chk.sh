#!/bin/zsh
# chk.sh FILE: lower FILE with this worktree's pass and check entry f against the C program (2 samples).
H=${0:A:h}; R=${H:h:h}
export CQ_BUILD_DIR=${CQ_BUILD_DIR:-$R/build}
cd $H && $R/driver/cqcc -S -I../cxx_rust $1 -o $(mktemp -t gi85k).ll --cq-check --cq-entry f --cq-samples 2 2>&1 | tail -${N:-4}
