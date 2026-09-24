; railbank_readorder_reject_tainted_fact.ll — DECLINE (bd `xdu2.10`, Rule-13 round 2 F-1, P2).
;
; SOURCE (reviewer `reviewA_r2/q06_tvalue.c`, stage 1 at `clang -O1`, verbatim):
;   int b[3]; int x = cq_theta(0, .2); _Bool c = cq_theta((_Bool)0, .3);
;   if (k > 0) for (i<3) b[i] = cq_theta(0, .5);
;   _Bool g = (k > 0) & c;
;   if (g) x = ((x + b[k & 1]) * 3) ^ 5;
;
; The read `b[k&1]` is dominated by the edge `%g → %arm`, whose condition
; `and i1 %pos, %c` IMPLIES `k > 0`, so the round-1 walk pruned the write guard's
; false edge and the carve answered `railbank [Bank]`. But `%c` is a `cq_theta`
; result: `%g` is TAINTED, the branch is FLATTENED by control lowering, and the
; value arm's chain (including this load) is HOISTED into the pred — so the load
; executes on `k <= 0` too, over cells nothing wrote. An execution path is no
; longer an IR CFG path, which is the premise the whole walk rests on.
;
; THE FIX: a condition may be a fact, or justify pruning, only if its operand
; closure is CLASSICAL (not in `taint.Tainted`), and a read that is itself
; inside a tainted branch's region (`readInsideTaintedRegion`, round 3) gets no
; semantic path at all — only header dominance.
;
; ⚠ WHAT PINS IT. The FINAL verdict is a decline on BOTH binaries: before the fix
; the module fell through to D5 (`cq rail bank: unsupported reader of a rail-bank
; cell`), a CONTINGENT closure that any D5 widening would have turned into a P1
; over-accept. So this fixture pins the DIFFERENCE by the debug trace: the
; read-order anchor MUST fire, the C6 string MUST be the diagnostic, and the
; `railbank [Bank]` line (the carve's accept, which also mints the record) must
; be ABSENT. On the pre-fix binary (`afda09e0`) all three fail.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]' \
; RUN:       --implicit-check-not='unsupported reader of a rail-bank cell'
; CHECK: CQ_CTRL_DBG: railbank C6 read-order refused:
; CHECK: cq rail bank: array has cells no iteration writes

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %k) {
entry:
  %b = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %b)
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
  %g = and i1 %pos, %c
  br i1 %g, label %arm, label %merge

arm:
  %lo = and i32 %k, 1
  %idx = zext nneg i32 %lo to i64
  %gr = getelementptr inbounds [3 x i32], ptr %b, i64 0, i64 %idx
  %cell = load i32, ptr %gr, align 4
  %s = add nsw i32 %cell, %x
  %m = mul nsw i32 %s, 3
  %v = xor i32 %m, 5
  br label %merge

merge:
  %out = phi i32 [ %v, %arm ], [ %x, %join ]
  %r = tail call i32 @cq_measure_si32(i32 noundef %out)
  %res = add nsw i32 %r, %k
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %b)
  ret i32 %res
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
