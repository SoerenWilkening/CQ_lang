; railbank_readorder_reject_bypass_implies_fact.ll — DECLINE (bd `xdu2.10`, Track A).
;
; Pins the POLARITY of the prune in `readFollowsLoopOnEveryPath`: an edge is
; dropped only when its condition implies the NEGATION of a fact. Here the write
; runs only under `n < 5` (then `n > 0`); the bypass edge `n >= 5` IMPLIES the
; read's fact `n > 0` — it is exactly the path on which the read runs over cells
; nothing wrote. A prune on "implies anything" would drop it and accept.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]'
; CHECK: cq rail bank: array has cells no iteration writes

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %n) {
entry:
  %ext = zext i32 %n to i64
  %b = alloca i32, i64 %ext, align 16
  %small = icmp slt i32 %n, 5
  br i1 %small, label %wguard, label %rguard

wguard:
  %wg = icmp sgt i32 %n, 0
  br i1 %wg, label %wph, label %rguard

wph:
  %wn = zext nneg i32 %n to i64
  br label %w

rguard:
  %rg = icmp sgt i32 %n, 0
  br i1 %rg, label %rph, label %exit

rph:
  %rn = zext nneg i32 %n to i64
  br label %r

w:
  %i = phi i64 [ 0, %wph ], [ %inext, %w ]
  %g = getelementptr inbounds i32, ptr %b, i64 %i
  %seed = load i32, ptr %g, align 4
  %t = tail call i32 @cq_theta_si32(i32 noundef %seed, double noundef 5.000000e-01)
  store i32 %t, ptr %g, align 4
  %inext = add nuw nsw i64 %i, 1
  %wdone = icmp eq i64 %inext, %wn
  br i1 %wdone, label %rguard, label %w

exit:
  %res = phi i32 [ 0, %rguard ], [ %s2, %r ]
  ret i32 %res

r:
  %j = phi i64 [ 0, %rph ], [ %jnext, %r ]
  %s = phi i32 [ 0, %rph ], [ %s2, %r ]
  %gr = getelementptr inbounds i32, ptr %b, i64 %j
  %cell = load i32, ptr %gr, align 4
  %mv = tail call i32 @cq_measure_si32(i32 noundef %cell)
  %s2 = add nsw i32 %mv, %s
  %jnext = add nuw nsw i64 %j, 1
  %rdone = icmp eq i64 %jnext, %rn
  br i1 %rdone, label %exit, label %r
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
