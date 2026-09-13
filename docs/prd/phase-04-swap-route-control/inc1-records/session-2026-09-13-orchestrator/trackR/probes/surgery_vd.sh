#!/bin/zsh
# The three vd.c stage-1 IR surgeries that IDENTIFY the collider.  Run from the
# repo root; writes into $CQW (default: a mktemp dir).  ORACLE only.
set -u
LLVM=/usr/local/opt/llvm@19/bin; R=$(pwd); W=${CQW:-$(mktemp -d)}
V=docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/probes/vd.c
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S $V -o $W/vd.s1.ll
# S1: the downstream guard can no longer be pinned to FALSE on either edge.
sed 's/%9 = icmp sgt i32 %8, 2/%9 = icmp sgt i32 %8, -5/' $W/vd.s1.ll > $W/S1_cmp_true.ll
# S2: the guard is pinned on NEITHER edge (true-edge range contains 0).
sed 's/%9 = icmp sgt i32 %8, 2/%9 = icmp sgt i32 %8, 0/' $W/vd.s1.ll > $W/S2_cmp_mixed.ll
# S3: the b1 prep's SEED flipped to `true` (arm arg-0 + pred incoming); the
#     guard still pins to FALSE, so the types match but the constants do not.
sed -e 's/%4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false/%4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true/' \
    -e 's/%6 = phi i1 \[ %4, %3 \], \[ false, %0 \]/%6 = phi i1 [ %4, %3 ], [ true, %0 ]/' $W/vd.s1.ll > $W/S3_seed_true.ll
for f in S1_cmp_true S2_cmp_mixed S3_seed_true; do
  "$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $W/$f.ll -o $W/$f.s2.ll 2>$W/$f.err
  echo "$f | exit=$? | $(grep -m1 error: $W/$f.err | sed 's/^.*: cq /cq /' || echo ACCEPT)"
done
echo "# work dir: $W"
