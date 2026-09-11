; control_swap_select_cmp_measure_after.ll — ACCEPT (Track A.1, bd
; test_C_libtooling-r10v): the condition register is measured AFTER the select,
; in the SAME BLOCK. The discriminating twin of
; `control_swap_reject_select_cmp_measured_before.ll`, one line apart.
;
;     int q = cq_theta(0, .5);
;     int a = (q == 1) ? 2 : 5;        // the merge reads a COHERENT q
;     int m = cq_measure(q);           // the measurement owns it from here on
;
; VERBATIM `clang -O1` (probe `a1_sel_cmp_measure_after.c`), and BYTE-UNCHANGED
; from `main` 0c7380c. THIS IS WHY RUNG (ii) TAKES A READ POINT and tests
; POSITIONALLY at the select: `SelectMergeEmit` emits its whole stream
; immediately BEFORE the select, so a same-block measurement AFTER it is the
; ordinary downstream case. The rail twin is
; `control_swap_select_rail_measure_after.ll`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 1
  %a = select i1 %c, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %q)
  %r = add nsw i32 %a, %m
  ret i32 %r
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)

; THE MINT MUST PRECEDE THE MEASURE. If rung (ii) ever swaps these two the
; program is the miscompile this fixture's twin pins, so ORDER is the assertion.
; ORD: call i32 @cq_template_icmp_eq_i32_hl(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cq_template_icmp_eq_i32_hl_unc(
; ORD: call void @cqrt_free(
; ORD: call i32 @cqrt_measure_i32(

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the Inc-4 F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_ry{{.*}}_controlled
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call i32 @cq_measure_
; MCNT-COUNT-1: call i32 @cqrt_measure_
; MCNT-NOT:     call i32 @cqrt_measure_
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
