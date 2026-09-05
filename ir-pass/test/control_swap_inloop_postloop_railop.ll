; control_swap_inloop_postloop_railop.ll — ACCEPT, and the ACCEPT BOUNDARY of the
; F-1 forward rail extension (bd test_C_libtooling-8h7d.5, Rule-13 ROUND 2).
;
;     for (i<2) { if (q==5) q = cq_phi(q,PI); q = cq_theta(q,-.5); }
;     int mark = q;
;     q = q + 9;                     /* an OUT-of-place value op after the record */
;     return cq_measure(mark) + cq_measure(q);
;
; THE FENCE MUST NOT FIRE HERE, and the reason is a property of the LOWERING, not
; of the shape. F-1 extends the rail forward through the users that keep mutating
; the SAME handle, and a rotation qualifies unconditionally (`lowerRotations`
; always RAUWs an Ry/Rz result to its arg-0 handle). A value self-update does NOT:
; only a chain member, or an op the M-C decision already put in
; `taint.InPlaceRailOps`, becomes `cqrt_{addc,xorc}` on this register. THIS one is
; on no chain and is not marked, so `lowerOps` emits it OUT of place —
;
;     cq_template_add_i32_hl(%h, 9)  →  a FRESH rail %h_op
;
; — the register `%h` never moves, `measure(%h)` really is `mark`, and
; `measure(%h_op)` really is `q + 9`. Counting the add as a gate (the tempting
; symmetric spelling of the F-1 fix) would refuse a program that is CORRECT today.
; The forward walk STOPS there for the same reason: a rotation applied to `%h_op`
; would rotate the fresh rail, not this one.
;
; The RED twin is lowering_reject_inloop_rail_record_postloop_theta.ll — the same
; program with `cq_theta(q, 0.125)` in place of `q + 9`. Swap the `add` for a
; `cq_theta` and this file must go red; that is the mutation it exists to make
; available.
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
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %z = add i32 %qn, 9                                  ; OUT of place — a fresh rail
  %m0 = call i32 @cq_measure_si32(i32 %qn)
  %m1 = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %m0, %m1
  ret i32 %s
}

; ONE rail, minted outside the loop, rolled body, and the post-loop add landing on
; a SECOND handle that the record's own measure does not name:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     loop:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %b)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     exit:
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 9)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
;
; NOT an in-place `cqrt_addc_i32` on the record's own rail, and no decline:
; CHECK-NOT: cqrt_addc_i32
; CHECK-NOT: rail record read past an in-place gate
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
