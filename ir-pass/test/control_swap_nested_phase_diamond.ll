; control_swap_nested_phase_diamond.ll — ACCEPT spec (§5g), depth-2 homogeneous
; PHASE nest. The §0 accept shape, pinned from real clang -O1 of
; `if (q>5) { q = rz(q,b); if (q<9) { q = rz(q,a); } }`.
;
; The swap-route nest mints the outer flag, routes q onto rail1, replays the
; intervening Rz on rail1, mints the inner flag FROM rail1 (the value's amplitude
; lives there post-route-in — NOT from the stale %g register), routes rail1 onto
; rail2, replays the inner Rz, routes back, then tears down LIFO: free rail2 →
; STRIP the inner flag vs rail1 (BEFORE the outer route-back, the load-bearing
; §12.3 order) → free inner flag → outer route-back → free rail1 → strip the outer
; flag vs q → free outer flag. ZERO controlled gates, NO cqrt_toffoli, NO phi i32,
; EXACTLY FOUR cqrt_free (rail2, %f2, rail1, %f1).
;
; WI-3 lands NestedRouteEmit — the proven nest now LOWERS to the §5g routed
; stream below (XFAIL removed at WI-3 XPASS).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; 1 outer mint + route-in
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; 2 intervening gate on rail1
; CHECK:     call void @cqrt_rz_i32(i32 %[[R1]], double %b)
; 3 inner mint FROM RAIL1 + route rail1 onto rail2 + inner gate + route back
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[R1]], i32 9)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[R1]], i32 %[[R2]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R2]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[R1]], i32 %[[R2]])
; 4 inner clean-up (LIFO): free rail2, STRIP f2 vs rail1, free f2
; CHECK:     call void @cqrt_free(i32 %[[R2]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[R1]], i32 9)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; 5 outer route-back + clean-up
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; q (not the phi) is measured
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; Hard postconditions.
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: phi i32

; THE 4.3-specific ordered FileCheck (§8, §12.3). The full strip-before-outer-
; route-back order is ALREADY pinned by the ordered main CHECK block above (inner
; strip at the `_slt_..._hl_inv` line, then the outer route-back cswap); this is a
; FOCUSED secondary guard in its OWN pass (a fresh check-prefix, cursor restarts at
; the top) that survives even if the main block is loosened to CHECK-DAG. It pins
; the §6.2/§12.3 NAMED misorder (inner strip placed AFTER the outer route-back),
; which produces the IDENTICAL symbol multiset yet dirty-frees %f2 = a hidden
; measurement collapsing q, invisible to `opt -verify`. (It does not by itself
; exclude a strip hoisted BEFORE the inner route-back — that distinct misorder is
; caught by the main block's inner-route-back→free-rail2→strip ordering.)
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; ORD:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{.*}}, i32 9)
; ORD:     call void @cqrt_cswap(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})

; Exactly four frees (rail2, %f2, rail1, %f1) — no fifth from uncompute.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; CNT-COUNT-4: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
