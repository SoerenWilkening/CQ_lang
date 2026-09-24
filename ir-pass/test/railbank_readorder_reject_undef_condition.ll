; railbank_readorder_reject_undef_condition.ll — DECLINE (bd `xdu2.10`, Track A).
;
; Pins the `undef`/`poison` conjunct of `singleValuedClosure`. The write is
; skipped when `%a = icmp ne i32 undef, 0` is false; the read runs when
; `%a2 = icmp ne i32 undef, 0` is true. `isImpliedCondition` matches the two
; compares operand-for-operand (one uniqued `undef` constant) and would answer
; "`%a` false implies `%a2` false" — but each USE of `undef` may denote a
; different value (LangRef), so both can be read as different bits at run time
; and the bypass path reaches a read of never-written cells. The closure test
; refuses any condition that reaches `undef`, so the edge is FOLLOWED and C6
; declines. (The second guard, `n > 0`, is refuted on its own by `%wg` false;
; the `undef` edge is the only one left for the walk to reach the read over.)
;
; ⚠ HAND IR — `clang -O1` folds `icmp ne undef, 0` away before the pass sees it;
; the pass is a module plugin and must be sound on any module `opt` is handed.
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
  %a = icmp ne i32 undef, 0
  br i1 %a, label %wguard, label %rguard

wguard:
  %wg = icmp sgt i32 %n, 0
  br i1 %wg, label %wph, label %rguard

wph:
  %wn = zext nneg i32 %n to i64
  br label %w

rguard:
  %a2 = icmp ne i32 undef, 0
  br i1 %a2, label %rguard2, label %exit

rguard2:
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
  %res = phi i32 [ 0, %rguard ], [ 0, %rguard2 ], [ %s2, %r ]
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
