; lowering_ctlz_idiom_i64.ll — ACCEPT (bd ww4c Inc 1). PRD §1.1's honesty
; obligation, the ACCEPT direction: a shape that IS the idiom and is NOT `ilogb`.
; Different width, different seed, no libm context, no enclosing guard.
;
; The point of the width is PRD §4.5(3): the `and` mask is N-1 taken from the
; SHIFT RECURRENCE'S OWN TYPE, never a literal 31. A width-hardcoded mask is a
; silent miscompile at every other width — here it must be 63.
;
; The closed form is width-generic by construction (PRD §4.1's proof holds for
; any power-of-two N), but the i64 row is NOT exhaustively verified — proof plus
; boundary/randomized checks only, unlike the i32 row's full 2^32 sweep. That is
; recorded honestly in PRD §4.2/§13 and this fixture does not claim otherwise.
;
; C0 = 100, so the emitted constant is C0-1 = 99.
;
; @widened_seed below is the WIDTH-ONLY MINIMAL PAIR of
; lowering_ctlz_idiom_reject_i128.ll: identical structure, identical seed route
; (a real-width theta widened by `sext`, narrowed back by `trunc` at the sink),
; differing ONLY in i64 vs i128. That pair is what makes the i128 fixture prove
; something. On its own it declines with Q1 — but so would a fixture that failed
; Z8 for a seeding mistake, or Z3, or anything else, since the recognizer never
; speaks and every miss looks identical from outside. Accepting here and
; declining there, with nothing else different, isolates Z9 as the clause that
; fires. (That is not hypothetical bookkeeping: the FIRST draft of the i128
; fixture declined because `cq_theta_si128` does not exist, so the module carried
; no taint and the pass returned it byte-identical — a passthrough wearing a
; decline's clothes.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; Operands CAPTURED, not wildcarded (bd ww4c.4). The i64 row is the one the PRD
; explicitly does NOT claim as exhaustively verified (§4.2), so its wiring is
; worth pinning hardest.
; CHECK: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 1)
; CHECK: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i64(i32 %[[S1]])
; CHECK: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[Z]], i64 63)
; CHECK: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i64_lh(i64 99, i32 %[[M]])
; CHECK: call i64 @cqrt_measure_i64(i32 %[[C]])
;
; CHECK-LABEL: @widened_seed(
; CHECK: %[[WS1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 1)
; CHECK: %[[WZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i64(i32 %[[WS1]])
; CHECK: %[[WM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[WZ]], i64 63)
; CHECK: %[[WC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i64_lh(i64 -1023, i32 %[[WM]])
; CHECK: %[[WT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[WC]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[WT]])
;
; CLEAN-NOT: = phi
; CLEAN-NOT: br i1
; The intrinsic CALL is gone (the now-unused `declare` is left behind, as it is
; for every other lowered intrinsic — cf. lowering_intrinsic_ctlz_i32.ll).
; CLEAN-NOT: call {{.*}}@llvm.ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i64 @normalize_wide(i64 %u) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %n = phi i64 [ 100, %entry ], [ %dec, %loop ]
  %x = phi i64 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i64 %n, -1
  %sh = shl nuw i64 %x, 1
  %pos = icmp sgt i64 %sh, 0
  br i1 %pos, label %loop, label %exit, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call i64 @cq_measure_sll(i64 %dec)
  ret i64 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}

; The width-only minimal pair of lowering_ctlz_idiom_reject_i128.ll — same shape,
; same sext/trunc seed route, i64 instead of i128. This one ACCEPTS.
define i32 @widened_seed(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %w = sext i32 %q to i64
  br label %loop

loop:                                             ; preds = %entry, %loop
  %n = phi i64 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i64 [ %w, %entry ], [ %sh, %loop ]
  %dec = add nsw i64 %n, -1
  %sh = shl nuw i64 %x, 1
  %pos = icmp sgt i64 %sh, 0
  br i1 %pos, label %loop, label %exit, !llvm.loop !2

exit:                                             ; preds = %loop
  %narrow = trunc i64 %dec to i32
  %m = call i32 @cq_measure_si32(i32 %narrow)
  ret i32 %m
}

!2 = distinct !{!2, !1}
