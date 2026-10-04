; control_inplace_ry_derived_base_add_late_use_frozen.ll — ACCEPT + FREEZE.
; The `add` spelling of `..._derived_base_mul_late_use_frozen.ll` (read that
; fixture's header for the defect and the root cause), kept as a SEPARATE
; fixture because its failure mode was WORSE and lands on a different rail.
;
;     int q=0; cq_theta(&q,.5); int p=0; cq_theta(&p,.3);
;     int r = p + 5;                     // an add — M-C lowers it IN PLACE
;     if (q > 5) cq_theta(&r, .9);
;     int s = r + 1;                     // a POST-REGION user
;     return cq_measure(q);
;
; `mul` mints a fresh rail, so there the dirty free landed on a rail nothing else
; owned. `add` is the M-C in-place case: `cqrt_addc_i32(%h1, 5)` relabels `p`'s
; OWN rail, so `r` and `p` are ONE physical wire, and the pre-fix stream freed
; THAT rail dirty —
;
;     cqrt_free(%h_cmp)
;     cqrt_addc_i32(%h1, 1) ; cqrt_addc_i32(%h1, -1)
;     cqrt_ry_i32_controlled(%h_cmp, %h1, -0.9)   <-- USE AFTER FREE
;     cqrt_addc_i32(%h1, -5) ; cqrt_ry_i32(%h1, -0.3)
;     cqrt_free(%h1)                              <-- DIRTY FREE of the SOURCE rail
;
; — i.e. a hidden measurement of the register the source register `p` lives on,
; entangled with the condition register `q` through the controlled Ry (Rules
; 6/8). Measured, `opt` exit 0, verify-clean.
;
; NOTE this shape is an ACCEPT, not the R4 decline: R4 intersects the base's wire
; closure with the CONDITION's, and `p` is a second, independent `cq_theta`
; source. `control_inplace_ry_reject_derived_base.ll` is the other case (the base
; derived FROM the condition register), and it declines.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOREV < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT   < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %r = add i32 %p, 5
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %s  = add i32 %rm, 1
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The base's `add` lowers IN PLACE onto `%h1`, and the controlled Ry fires on
; that same rail.
; CHECK:      call void @cqrt_addc_i32(i32 %h1, i32 5)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %h1, double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %h1, i32 1)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %h)

; Nothing reverses the frozen rail: no negated addc (of either immediate), no
; controlled-Ry adjoint, no source-theta adjoint, and no free of `%h1`.
; NOREV-NOT: cqrt_addc_i32(i32 %h1, i32 -1)
; NOREV-NOT: cqrt_addc_i32(i32 %h1, i32 -5)
; NOREV-NOT: double -9.000000e-01
; NOREV-NOT: double -3.000000e-01
; NOREV-NOT: cqrt_free(i32 %h1)

; EXACTLY one free in the whole module: the flag's.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
