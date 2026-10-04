; control_swap_select_cmp_other_register_measured.ll — ACCEPT (Track A.1, bd
; test_C_libtooling-r10v): THE CLOSURE'S STOP PIN. A DIFFERENT register is
; measured before the select, on the same path.
;
;     int p = 0; cq_theta(&p, .7);
;     int q = 1; cq_theta(&q, .5);
;     int m = cq_measure(p);           // another register entirely
;     int a = (q == 1) ? 2 : 5;
;
; VERBATIM `clang -O1` (probe `a2_sel_cmp_other_register_measured.c`), and
; BYTE-UNCHANGED from `main` 0c7380c. Rung (ii) asks its question over
; `railWireNamesBackward`'s closure of each `condProvenance` member, and that
; closure STOPS at the wire origin: `%q` is a SOURCE theta (its arg-0 is the
; classical seed `1`), so `%p` is on no name of `%q`'s wire and the measurement
; refuses nothing. Delete the stop and this goes red — which is the point: the
; rung must be about ONE register, not about "a measure happened earlier". The
; rail twin is `control_swap_select_rail_other_register_measured.ll`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %p = call i32 @cq_theta_si32(i32 0, double 0x3FE6666666666666)
  %q = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %p)
  %c = icmp eq i32 %q, 1
  %a = select i1 %c, i32 2, i32 5
  %r = add nsw i32 %a, %m
  ret i32 %r
}

; TWO SEPARATE REGISTERS is the assertion: the measure names %[[HP]] and the
; mint names %[[HQ]].
; CHECK:      %[[HP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[HP]])
; CHECK-NEXT: {{.*}} = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 1)

; ORD: call i32 @cqrt_measure_i32(
; ORD: call i32 @cq_template_icmp_eq_i32_hl(
; ORD: call void @cqrt_free(

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: call i32 @cq_theta_
; ACNT-COUNT-5: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
