; control_inplace_ry_lifted_phi_after_region.ll — ACCEPT: a FLAT control-in-place
; Ry arm followed by the canonical 5j5 one-register merge-phi lift (a classical
; `if (OPQ) cq_theta(&r, θ);` join φ) over the ROTATED register.
;
; bd test_C_libtooling-drbq Increment 3, ROUND-1 Rule-13 review finding F-L5-1.
; RED-GREEN: this file DECLINED `cq taint escape: tainted value muxed by a
; classical-condition phi` at the increment's hand-back commit and accepts now.
;
; WHY IT BROKE, and why the fix is in the LIFT and not in M-β. M-β (§13.4)
; RAUWs the region's merge φ to the HOISTED GATE `%t` rather than to the base
; `%r0`, which is the whole mechanism that lets `LoopLowering` read the truth
; with no exemption. But `TaintPropagation::resolveWireBase` then PEELS `%t`
; like any other in-place rotation, so the classical join φ below the region
; got `Gates = {%t}` on its straight edge and `{%11, %t}` on its arm edge —
; and TWO independent lift clauses refuse a chain gate that is HOISTED into a
; block dominating every edge: (6) `G->getParent() != Self`, and (7a) `%t`
; reaches every other edge's terminator. The house rule verbatim: when you
; widen a set, ask what OTHER set is computed over the same closure — M-β
; widened the value the merge names, and `WireChain::Gates` is that other set.
;
; THE FIX (`resolveWireBase`): a call recorded in `taint.ControlledRotations`
; is a STOP, not a peel step — its result IS the base. It is a gate ANOTHER
; owner (the region emitter) already adjudicated, it executes unconditionally
; in the CFG (the conditionality is quantum, carried by the flag operand), and
; its OPERAND names a record the register no longer holds. See the site comment.
;
; The region lowers control-in-place and the classical `if` keeps its own block
; with a plain uncontrolled `cqrt_ry_i32` on the same rail inside it.
;
; VERBATIM `clang -O1` output (attribute groups and metadata trimmed) for
;   volatile int OPQ = 1;
;   int slice(void) { int q=3, r=7;
;                     cq_theta(&q,0.5); cq_theta(&r,0.25);
;                     if (q == 5)  { cq_theta(&r, 0.9); }   /* Ry arm, M-β */
;                     if (OPQ)     { cq_theta(&r, 0.5); }   /* 5j5 lift */
;                     return cq_measure(q) + cq_measure(r); }
;
; History: pre-3qlq the OPQ arm held the register form `r = cq_phi(r, 0.5)` (an
; in-place Rz). The 3qlq migration deleted it as an uncontrolled phase and left
; the arm empty; bd jttf (2026-10-05) re-spelled it as the in-place Ry above,
; together with the phase-arm twin control_inplace_rz_lifted_phi_after_region.ll,
; so the two files again differ ONLY in the first region's arm.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

@OPQ = global i32 1, align 4

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = load volatile i32, ptr @OPQ, align 4
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %6
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 5.000000e-01)
  br label %12

12:                                               ; preds = %10, %6
  %13 = phi i32 [ %11, %10 ], [ %7, %6 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %16 = add nsw i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; The region: flag mint, ONE controlled Ry on the disjoint rail, strip, free.
; CHECK: %[[Q:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK: %[[R:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; The CLASSICAL guard keeps its own block and an UNCONTROLLED Ry on the same rail.
; CHECK: br i1
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 5.000000e-01)
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[R]])

; Whole-file: the lift ERASED the join φ, no route, no work rail, and every
; front-end intrinsic is lowered.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_si
; NOROUTE-NOT: cq_measure_si
