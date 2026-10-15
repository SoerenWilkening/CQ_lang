; control_angle_select_reject_nested_select.ll — DECLINE (S2): a NESTED angle
; select (bd drbq Inc 2b).
;
;     cq_theta(&r, q == 5 ? .9 : (q == 6 ? .3 : .1));
;
; The inner select's only user is the OUTER select, not a rotation arg-1, so S2
; refuses it; the outer select's FALSE operand is the inner select's result,
; which S1 would also have to accept as classical. A three-way angle needs a
; two-flag composition (the by-difference identity chains, but the second
; difference must be controlled on the CONJUNCTION of the two flags), which is
; outside this increment. Both selects decline; the first diagnostic wins.
;
; ⚠ FLIPPED TO AN ACCEPT BY bd test_C_libtooling-dm7f.54 (item E, the reporter's t4
; line 3), NAME KEPT (L8). The "two-flag composition ... controlled on the
; CONJUNCTION of the two flags" the paragraph above asks for is what the mux
; emitter builds, without any difference: `%inner` is an inner MUX MEMBER
; (`angleMuxParent`), gate 3 defers it to the root, and the root emits
;   f1 = (q == 5); ry_c(f1, r, .9); x(f1)
;   f2 = (q == 6); p = f1 ∧ f2 (toffoli); ry_c(p, r, .3); undo p
;   x(f2); p = f1 ∧ ¬f2; ry_c(p, r, .1); undo p; x(f2); free(p); strip f2
;   x(f1); strip f1
; ANALYTIC: q == 5 -> Ry(.9); q != 5 ∧ q == 6 -> Ry(.3); otherwise Ry(.1); each
; angle in exactly one controlled gate; r is off q's wire (S8), so both strips
; recompute their compares on an untouched q.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 6)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[P]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[P]], i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[P]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c1 = icmp eq i32 %q, 5
  %c2 = icmp eq i32 %q, 6
  %inner = select i1 %c2, double 3.000000e-01, double 1.000000e-01
  %ang = select i1 %c1, double 9.000000e-01, double %inner
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
