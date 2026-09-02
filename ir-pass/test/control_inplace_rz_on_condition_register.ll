; control_inplace_rz_on_condition_register.ll — the §6a Rz peephole where the
; ROTATED REGISTER **IS** THE CONDITION REGISTER (bd test_C_libtooling-drbq Inc 2a;
; PRD S6-on-q / S8, and §3c permits phase ops on a condition variable).
;
; THE FIXTURE THAT SEPARATES THE TWO STEMS. Inc 1's R4 refuses a controlled **Ry**
; whose target wire is in the condition's wire set, because after a non-diagonal
; gate the flag is no longer a function of q's basis and the `icmp_..._unc` strip
; cannot return it to |0>. For the **Rz** stem that fence does not apply and must
; not be copied over: a controlled Rz is `diag(1, e^{iθ})` on the f=1 branch and
; `I` on f=0 — DIAGONAL EITHER WAY — so q's basis label is not merely restored,
; it is never moved, and the strip is valid pointwise.
;
; The identical shape with `cq_theta` in the arm DECLINES
; (control_inplace_ry_reject_cond_register.ll and its alias family). Keeping both
; in the tree is what makes R4's Ry-only scope a decision rather than an accident.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header. A
; trailing CHECK-NOT scans only past the LAST positive of its own prefix, and every
; route line lands BEFORE that, so it could never fire (bd memory
; filecheck-check-not-window-trap). The window reaches the declares too, hence the
; `call void @` anchors.
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact free count: ONE (the flag).
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; the flag is minted from q...
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; ...and the gate fires on q ITSELF, controlled by a flag derived from q
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; ...and the strip still recomputes q > 5 from the SAME q, because Rz moved no basis
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
