; control_swap_select_cmp_inloop_hoisted_measure_after.ll — ACCEPT (Track A.1,
; bd test_C_libtooling-r10v): the CONSTANT-ARM spelling of the r10v reproducer,
; and what `clang -O1` actually does to it.
;
;     int b = 0; cq_theta(&b, .5);
;     for (int i = 0; i < 3; ++i) {
;         int a = (b == 1) ? 7 : 5;              // arm is loop-INVARIANT
;         acc += cq_measure(a) + cq_measure(b);
;     }
;
; MEASURED (probe `a6_sel_cmp_inloop_measure_after_constarm.c`): `-O1` LICM-hoists
; the WHOLE select into the entry block, so the merge stream — flag mint, both
; controlled copies, strip, free — runs ONCE, BEFORE the loop, on a coherent
; register. The body measure cannot precede it: no path returns to the entry
; block. ACCEPT, and BYTE-UNCHANGED from `main` 0c7380c.
;
; IT IS THE DISCRIMINATOR FOR THE READ POINT. Its loop-VARIANT sibling
; (`..._reject_select_cmp_inloop_measure_after.ll`, one token apart — `? i :`
; instead of `? 7 :`) keeps the select in the body, which puts the read point on
; the cycle, and declines. What makes r10v wrong is WHERE the register is read,
; not that a loop is present.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  %3 = select i1 %2, i32 7, i32 5
  br label %5

4:
  ret i32 %11

5:
  %6 = phi i32 [ 0, %0 ], [ %11, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %12, %5 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %10 = add i32 %8, %6
  %11 = add i32 %10, %9
  %12 = add nuw nsw i32 %7, 1
  %13 = icmp eq i32 %12, 3
  br i1 %13, label %4, label %5
}

; THE WHOLE MERGE IS OUTSIDE THE LOOP — pinned by the `br label` that follows the
; flag's free, which is the entry block's terminator.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK:      call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: br label

; ORD: call i32 @cq_template_icmp_eq_i32_hl(
; ORD: call void @cqrt_free(
; ORD: br label
; ORD: call i32 @cqrt_measure_i32(

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: call i32 @cq_theta_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CPCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CPCNT-NOT:     call void @cqrt_copy
