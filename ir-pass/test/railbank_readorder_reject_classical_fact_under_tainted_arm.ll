; railbank_readorder_reject_classical_fact_under_tainted_arm.ll — DECLINE (bd `xdu2.10`, Rule-13 round 2 F-1).
;
; Pins the READ-SIDE half of F-1's fix: a read INSIDE a TAINTED branch's REGION
; (reachable from the branch without passing its immediate post-dominator —
; `readInsideTaintedRegion`; round 3 replaced `instUnderTaintedControl`, which
; also refused reads AFTER a fully-merged tainted diamond) gets no semantic read-order path,
; only header dominance — EVEN WHEN every fact that refutes the bypass is
; CLASSICAL. Here the read sits under `if (c) { if (k > 0) … b[k&1] … }`, with
; `c` a `cq_theta` result. The dominating `k > 0` edge is classical and would
; refute the write guard's false edge; but the classical branch is NESTED in the
; tainted arm, and PredMux flattening of such a region may predicate the inner
; classical branch too and speculate the load (the E4 classical-table read), so
; the classical fact no longer guarantees the load does not run on `k <= 0`.
; The walk's premise — an execution path is an IR CFG path — does not hold there.
;
; ⚠ HAND IR — `clang -O1` fuses the C spelling into `and i1 (k>0), c` (the
; `railbank_readorder_reject_tainted_fact.ll` shape, where the tainted-closure
; conjunct alone catches it). This spelling keeps the classical branch separate,
; so ONLY the read-side conjunct separates the two binaries' traces.
;
; What pins it: a decline would follow elsewhere either way; the witness is the
; read-order anchor and the absent `railbank [Bank]` line.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]'
; CHECK: CQ_CTRL_DBG: railbank C6 read-order refused:
; CHECK: cq rail bank: array has cells no iteration writes

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %k) {
entry:
  %b = alloca [3 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.000000e-01)
  %c = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %pos = icmp sgt i32 %k, 0
  br i1 %pos, label %w, label %join

w:
  %i = phi i64 [ %inext, %w ], [ 0, %entry ]
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %g1 = getelementptr inbounds [3 x i32], ptr %b, i64 0, i64 %i
  store i32 %t, ptr %g1, align 4
  %inext = add nuw nsw i64 %i, 1
  %wdone = icmp eq i64 %inext, 3
  br i1 %wdone, label %join, label %w

join:
  br i1 %c, label %arm, label %merge

arm:
  br i1 %pos, label %inner, label %merge

inner:
  %lo = and i32 %k, 1
  %idx = zext nneg i32 %lo to i64
  %gr = getelementptr inbounds [3 x i32], ptr %b, i64 0, i64 %idx
  %cell = load i32, ptr %gr, align 4
  %s = add nsw i32 %cell, %x
  %m = mul nsw i32 %s, 3
  %v = xor i32 %m, 5
  br label %merge

merge:
  %out = phi i32 [ %v, %inner ], [ %x, %arm ], [ %x, %join ]
  %r = tail call i32 @cq_measure_si32(i32 noundef %out)
  %res = add nsw i32 %r, %k
  ret i32 %res
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
