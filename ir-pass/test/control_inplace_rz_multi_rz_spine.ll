; control_inplace_rz_multi_rz_spine.ll — the §6a Rz peephole on a MULTI-GATE arm
; spine (bd test_C_libtooling-drbq Inc 2a; PRD §12.2 admits multi-Rz spines
; because a diagonal chain has no basis hazard).
;
; `if (q > 5) { rz(r,a); rz(r,b); rz(r,c); }` — three gates, ONE work rail under
; the route (which routed once, replayed all three on the rail, and routed back).
; The peephole re-mints each gate as its own `cqrt_rz_i32_controlled` on the
; register: the route's ONE quintuple becomes THREE controlled gates, so the
; collapse is per-GATE for the rz and per-ARM for the alloc/cswap/free — which is
; exactly the arithmetic `tools/golden_multiset_audit.py` checks.
;
; ORDER IS THE POINT. Rz gates commute with each other, so this fixture is not
; pinning a correctness hazard in the composition; it pins that the SPINE ORDER
; (a then b then c, forward, the order `collectArmPhis` returns) survives the
; hoist. A reversal would be invisible to any angle-blind check and is exactly the
; kind of thing a regenerated golden cannot see.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header. A
; trailing CHECK-NOT scans only past the LAST positive of its own prefix, and every
; route line lands BEFORE that, so it could never fire (bd memory
; filecheck-check-not-window-trap). The window reaches the declares too, hence the
; `call void @` anchors.
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b, double %c2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  call void @cq_phi(double %b)
  call void @cq_phi(double %c2)
  br label %merge
merge:
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %o = add i32 %m1, %m2
  ret i32 %o
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double %a)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double %b)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double %c2)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32
