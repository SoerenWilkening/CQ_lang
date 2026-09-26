#!/bin/bash
# Rebuild the p1/p2 probe modules from their C sources (the recipe used; clang -O1 per TU,
# then llvm-link, exactly as tests/e2e/run_slice_multi.sh builds a multi-TU module).
# usage: build_probes.sh <subject-worktree>
set -e
S=$1; L=/usr/local/opt/llvm@19/bin; H=$(cd "$(dirname "$0")" && pwd); T=$(mktemp -d)
cd "$H/p1_liftskip"
$L/clang -I$S/include -include CQ.h -O1 -emit-llvm -S caller.c -o $T/c.ll
$L/clang -O1 -emit-llvm -S lib.c -o $T/l.ll
$L/llvm-link -S $T/c.ll $T/l.ll -o k1.ll
cd "$H/p2_liftskip_verdict"
$L/clang -O1 -emit-llvm -S lib.c -o $T/l.ll
for v in C T N; do
  $L/clang -I$S/include -include CQ.h -O1 -emit-llvm -S caller_$v.c -o $T/c_$v.ll
  $L/llvm-link -S $T/c_$v.ll $T/l.ll -o p2_$v.ll
done
rm -rf $T
