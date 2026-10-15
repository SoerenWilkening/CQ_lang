; control_regcond_negated_guard_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, design D4 case 2): the branch reads the register its arm rotates, and
; the program already computes the guard's negation.
;
; Source (clang -O1 -include CQ.h):
;   bool q2 = 0, q4 = 1; cq_theta(&q2, .5);
;   q4 ^= q2; if (q4) cq_theta(&q2, .7);
;   return cq_measure(q2) | (cq_measure(q4) << 1);
;
; -O1 folds `q4 = 1 ^ q2` into `br %q2` with swapped arms (the arm rotates %q2
; itself) and sinks `%6 = xor %1, true` (q4) past the merge; the 57ch stale-read
; placement moves it back before the gate. The commit stage then rewrites the
; branch to `br %6` with the successors swapped (`substituteNegatedGuard`, the
; identity on values) and tags `%6` a fresh register condition: the control is
; q4's own `_hl` rail, so the controlled Ry's control is off its target. On main
; 27aaf1e1: `condition predates a non-diagonal gate`. This is dicke.c's
; SCS_{3,2} block. Analytic (trace vs textbook, identical to 12 digits):
; P(q2,q4) = 01: 0.828409228833, 10: 0.061208719055, 11: 0.110382052112.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 4) i32 @main()
; CHECK-NEXT:  %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[Q2]], double 5.000000e-01)
; CHECK-NEXT:  %[[Q4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[Q2]], i1 true)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[Q4]], i32 %[[Q2]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[Q2]])
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[Q4]])
; CHECK-NOT:   call void @cqrt_free(
; CHECK-NOT:   call void @cqrt_x(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br i1 %1, label %4, label %2

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666)
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ %1, %0 ]
  %6 = xor i1 %1, true
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5)
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = select i1 %9, i32 2, i32 0
  %11 = or disjoint i32 %10, %8
  ret i32 %11
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
