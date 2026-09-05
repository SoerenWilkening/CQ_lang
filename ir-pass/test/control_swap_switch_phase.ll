; control_swap_switch_phase.ll — ACCEPT spec, homogeneous PHASE switch (N=3).
;
; `switch(q){ case 0: q=cq_phi(q,.1); case 1: q=cq_phi(q,.2); case 2: q=cq_phi(q,.3) }`
; with an empty default. `clang -O1` const-folds each arm gate to
; `cq_phi(i32 c_i, θ_i)` — arg-0 is the CASE LITERAL, not q (the §5 re-anchor
; signature). The swap-route lowering, per content case `i`: mints the eq-flag
; f_i = (q==c_i), CSWAPs q into a |0> work rail under f_i, replays θ_i VERBATIM on
; the rail (the folded gate's ARG-1 only — arg-0 discarded, NO RAUW), CSWAPs back
; (join = adjoint of the split, same f_i), frees the |0> rail, strips f_i with
; icmp_eq_inv(q) (q==q0), frees f_i. ZERO controlled gates beyond the route
; cswaps; q (not the phi) is measured; NO surviving `cq_phi`, NO `phi i32`.
;
; THE BLOCKER (§5, verify-clean-invisible, NO downstream backstop): a folded
; `cq_phi(c_i,θ)` that survives to lowerRotations RAUWs to its constant arg-0 →
; the merge degenerates into a wrong data-mux. Authored at N>=3 to exercise the
; N-way folded-gate scrub + N-way flatten. WI-1 reached the would-be-ACCEPT and
; fired the TRANSITIONAL "switch" decline; WI-2 graduates: push + emit + scrub.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1
                                i32 2, label %a2 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
a2:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; theta lowers to the alloc+ry handle (RAUW q -> the i32 handle); q == this handle
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; case 0: eq -> rail -> cswap -> rz(.1) -> cswap -> free(rail) -> eq_inv -> free(flag)
; CHECK:     %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     %[[R0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[Q]], i32 %[[R0]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R0]], double 1.000000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[Q]], i32 %[[R0]])
; CHECK:     call void @cqrt_free(i32 %[[R0]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F0]])
; case 1
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R1]], double 2.000000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; case 2
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 2)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[Q]], i32 %[[R2]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R2]], double 3.000000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[Q]], i32 %[[R2]])
; CHECK:     call void @cqrt_free(i32 %[[R2]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 2)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; q (not the phi) is measured — RAUW merge phi -> q
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; exact free count — 3 rails + 3 flags, no SEVENTH anywhere (a spurious uncompute
; free is a hidden measurement that collapses q, Rule 6):
; CNT-COUNT-6: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; ORDER is the contract (a mis-ordered N-way emit yields the IDENTICAL symbol
; MULTISET — order-blind structural CHECKs miss it). Pin each case's mint -> its
; θ -> its strip, in case order, with case i's strip BEFORE case i+1's mint:
; ORD: @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; ORD: @cqrt_rz_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 1.000000e-01)
; ORD: @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; ORD: @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; ORD: @cqrt_rz_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e-01)
; ORD: @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; ORD: @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; ORD: @cqrt_rz_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e-01)
; ORD: @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 2)

; route BALANCE — exactly 2 cswaps per case (route-in + route-back) = 6, no
; SEVENTH (a stray/dropped route is a wrong unitary the multiset alone misses):
; XCT-COUNT-6: call void @cqrt_cswap(
; XCT-NOT:     call void @cqrt_cswap(

; whole-output absence scan: the switch ACCEPTS (no decline); the §5 re-anchor
; held (NO folded cq_phi survived, NO data-mux phi degeneration); zero controlled
; gates (a phase arm is method-A-free):
; ACC-NOT: under quantum control
; ACC-NOT: cq_phi
; ACC-NOT: phi i32
; ACC-NOT: _controlled
