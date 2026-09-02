; lowering_uncompute_interior_region_ifelse_chain.ll — ACCEPT (M-B Increment 6,
; clause (d2)). THE FOUR-MEMBER ROUTE GROUP: an IF/ELSE phase region routes the
; base TWICE (once per arm, the else arm X-bracketed on ¬flag), so the recorded
; `RestoringRoute` has FOUR `cqrt_cswap` members and the discharge is legal only
; if ALL FOUR lie inside the interval.
;
;     q = cq_theta(u, 0.5);
;     if (((q * 37) >> 3) == 5) r = cq_phi(q, PI);
;     else                      r = cq_phi(cq_phi(q, 0.25), 0.75);
;     return cq_measure(r);
;
; WHY THE GROUP IS STILL THE IDENTITY ON THE BASE'S LABEL. The true arm's pair
; fires on `flag`, the else arm's on `¬flag` (the `cqrt_x` brackets are on the
; FLAG rail, opened and closed by `emitRoute` in the same step). At most one of
; the two exchanges is active on any branch, so the four calls commute and each
; active pair is its own inverse: the base leaves the region with the label it
; entered with. Two `Rz` gates run in between, both DIAGONAL and both on WORK
; RAILS, never on the base.
;
; THE ELSE ARM CARRIES TWO GATES DELIBERATELY. Written with one gate per arm,
; `clang -O1` merges the two `cq_phi` calls and muxes their ANGLES through a
; phi — a rotation angle under quantum control, which declines (Rule 3). Two
; gates in one arm keeps the two spines distinct. (The angle mux decline is not
; what this fixture is about; it is why the shape is spelled this way.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ifelse_chain(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = mul nsw i32 %q, 37
  %k  = and i32 %d, -8
  %c  = icmp eq i32 %k, 40
  br i1 %c, label %armt, label %armf

armt:
  %g1 = call i32 @cq_phi_si32(i32 %q, double 0x400921FB54442D18)
  br label %merge

armf:
  %g2 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  %g3 = call i32 @cq_phi_si32(i32 %g2, double 7.500000e-01)
  br label %merge

merge:
  %p = phi i32 [ %g1, %armt ], [ %g3, %armf ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK-LABEL: define i32 @ifelse_chain(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 40)
; the FOUR route members, all on the same base and all in one recorded group:
; The two arms, CONTROL-IN-PLACE since drbq Inc 2a: the THEN gate on %[[F]], the
; ELSE gate run X-bracketed so it fires on ¬flag. Four `cqrt_cswap`s and two work
; rails became three `cqrt_rz_i32_controlled` calls on %[[H]] itself.
; CHECK:      call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 7.500000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K]], i32 %[[D]], i32 -8)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 37)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; THE ROUTE'S ABSENCE, ON ITS OWN PREFIX ANCHORED AT THE FUNCTION HEADER (bd
; drbq Inc 2a round-1 review, L3 F2). The trailing `CHECK-NOT: cqrt_cswap`
; above scans only PAST the last positive of the `CHECK` prefix, so a route
; re-inserted AT the arm gate lands before its window and the assertion cannot
; fire (bd memory filecheck-check-not-window-trap). Anchoring at `define` makes
; the window the whole function. MUTATION-VERIFIED: re-inserting
; `cqrt_alloc_<W>(0) + cqrt_cswap` before the first controlled gate turns this
; prefix RED.
; NOROUTE:     define{{.*}}@ifelse_chain
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
