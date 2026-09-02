; control_inplace_ry_derived_base_mul_late_use_frozen.ll — ACCEPT + FREEZE, and
; THE REGRESSION PIN for a CONFIRMED silent miscompile found by the round-1
; Rule-13 review of bd test_C_libtooling-drbq Inc 1 (reviewer lenses L3 §1 and
; L5 §1, independently).
;
;     int q=cq_theta(0,.5); int p=cq_theta(0,.3);
;     int r = p * 5;                     // an OUT-OF-PLACE DERIVED base
;     if (q > 5) r = cq_theta(r, .9);    // the accepted in-place Ry arm
;     int s = r + 1;                     // a POST-REGION user
;     return cq_measure(q);
;
; This is the increment's own §4b probe `a1` (a `mul` base ACCEPTS: a `mul`
; always mints a FRESH rail, so the rotated wire really is disjoint from the
; condition's and R4 is satisfied) crossed with `..._dead_base_late_use_frozen`'s
; POST-REGION USER. Each axis had been probed; the CROSS had not.
;
; THE DEFECT, as emitted before the fix (verbatim, `opt` exit 0, verify-clean,
; all 37 committed fixtures of this family GREEN):
;
;     cq_template_icmp_sgt_i32_hl_unc(%h_cmp, %h, 5)
;     cqrt_free(%h_cmp)                              <-- the flag is reclaimed
;     cqrt_addc_i32(%h_op, 1)
;     cqrt_addc_i32(%h_op, -1)
;     cqrt_ry_i32_controlled(%h_cmp, %h_op, -0.9)    <-- USE AFTER FREE
;     cq_template_mul_i32_hl_unc(%h_op, %h1, 5)
;     cqrt_free(%h_op)                               <-- DIRTY FREE
;     cqrt_ry_i32(%h1, -0.3) ; cqrt_free(%h1)        <-- and a SECOND dirty free
;
; ROOT CAUSE — the freeze was keyed on a POINTER a later stage erases. Inc 1
; recorded `taint.ControlledRotationRails.insert(Handle)` in `lowerRotations`,
; where `Handle` is the theta's arg-0 AT THAT MOMENT. For a derived base that is
; the raw `mul` INSTRUCTION; `lowerOps` — the very next pipeline stage — RAUWs it
; to the `cq_template_mul_i32_hl` result and ERASES it. All three spine query
; sites then compared the live `%h_op` against a dangling pointer and answered
; "not frozen". The set is GONE; the question is now asked structurally of the
; emitted gate (`ChainWalk::railCarriesControlledRotation`, which derives the
; rail from the gate's arg-1 USE and therefore cannot go stale).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The CHECK-NOTs run as their OWN prefix so FileCheck scans the WHOLE file, not
; only the tail after the last positive CHECK (the L6 finding-1 lesson).
; RUN: %filecheck %s --check-prefix=NOREV < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT   < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %r = mul i32 %p, 5
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

; The forward stream, in order: the derived rail is minted, the flag is minted at
; the compare, the controlled Ry fires on the DERIVED rail, the flag is stripped
; and freed. No route, no work rail.
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 5)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[OP]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the post-region `r + 1` still lowers in place (M-C) — the freeze is about the
; REVERSAL, not the forward program
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[OP]], i32 1)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %h)

; NOTHING reverses the frozen rail, and nothing reverses the chain hanging off it
; (the whole DAG is `NotClosed`): no negated addc, no controlled-Ry adjoint, no
; `mul` `_unc`, no free of any rail but the flag.
; NOREV-NOT: cqrt_addc_i32(i32 %h_op, i32 -1)
; NOREV-NOT: double -9.000000e-01
; NOREV-NOT: cq_template_mul_i32_hl_unc
; NOREV-NOT: double -3.000000e-01
; NOREV-NOT: cqrt_free(i32 %h_op)
; NOREV-NOT: cqrt_free(i32 %h1)

; EXACTLY one free in the whole module: the flag's.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
