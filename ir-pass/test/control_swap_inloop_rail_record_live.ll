; control_swap_inloop_rail_record_live.ll — ACCEPT, and the ACCEPT BOUNDARY of the
; F1 rail-record fence (bd test_C_libtooling-8h7d.5, Rule-13 round 1).
;
;     for (...) { d = q * 7; if (q == 5) q = cq_phi(q, b); q += 3; use(d); }
;
; The `mul` reads the loop-carried register at the TOP of the iteration, BEFORE
; any gate on that rail fires, and `%d` is consumed inside the same iteration. So
; at the read position the wire really does hold what `%q` names, and the fence
; must NOT fire — a blanket "a rail member has a value-op consumer ⇒ decline"
; would refuse this, and would also refuse the region's own emitted compare
; (`cq_template_icmp_eq_i32_hl(%h, 5)`), which is a value-op consumer of the very
; same header phi in every shipped Grover-loop slice.
;
; The two RED twins are lowering_reject_inloop_rail_record_midbody.ll (the SAME
; program with the `mul` moved after the `add`) and
; lowering_reject_inloop_rail_record_escape.ll (the `mul` sunk past the loop).
; Move the `%d` line down past `%qn` and this file must go red; that is the
; mutation this fixture exists to make available.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %d = mul i32 %q, 7                                   ; LIVE read — before every gate
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = add i32 %q, 3                                 ; in-place rail self-update
  %mm = call i32 @cq_measure_si32(i32 %d)              ; consumed in-body
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m1 = call i32 @cq_measure_si32(i32 %qn)
  %s = add i32 %m1, %mm
  ret i32 %s
}

; ONE rail, minted outside the loop; the rolled body reads it at the top:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     loop:
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %b)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 3)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[D]])
;
; CHECK-NOT: rail record read past an in-place gate
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
