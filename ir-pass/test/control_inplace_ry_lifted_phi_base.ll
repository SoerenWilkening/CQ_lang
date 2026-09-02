; control_inplace_ry_lifted_phi_base.ll — ACCEPT. THE CONTROL that keeps the R6
; φ-crossing fix (round-1 Rule-13 review, lens L2 §1) a FENCE and not a BAN.
;
;     int m; if (c) { m = cq_phi(r, .1); } else { m = r; }   /* CLASSICAL diamond */
;     if (q == 5) { m = cq_theta(m, .9); }                   /* rotate THE φ ITSELF */
;     return cq_measure(m) + cq_measure(q);
;
; Same launder CFG as the seven `..._reject_lifted_phi_*` fixtures, one line
; different: the region rotates `m` — the classical join φ — instead of `r`. So
; there IS no post-region read of a pre-Ry record: every consumer reads the
; region's own merge φ, which the emitter RAUWs to the base.
;
; WHY IT MATTERS: the fix WIDENED the member set (a φ / select / freeze user is
; now crossed forward from a tainted member). A widening that turned this shape
; into a decline would have bought the fence at the cost of the accept class —
; and this is exactly the case where the base IS a lifted φ, so the walk seeds
; ON the crossed node. The members become {m, cq_phi(r,·), r} and every user is
; either a member, an arm-block user, or the region's own merge φ (the ONE
; forward exclusion), so R6 has nothing left to refuse. MEASURED accepting both
; before and after the fix.
;
; Hand-written IR is not needed here — this is `clang -O1` output for the C above
; (reviewer probe `L2/l_base_is_liftedphi.c`), renamed for legibility.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %cc = icmp eq i32 %c, 0
  br i1 %cc, label %join, label %alias
alias:
  %m0 = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  br label %join
join:
  %m = phi i32 [ %m0, %alias ], [ %r, %entry ]
  %t = icmp eq i32 %q, 5
  br i1 %t, label %arm, label %merge
arm:
  %mt = call i32 @cq_theta_si32(i32 %m, double 9.000000e-01)
  br label %merge
merge:
  %mm = phi i32 [ %mt, %arm ], [ %m, %join ]
  %a = call i32 @cq_measure_si32(i32 %mm)
  %b = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %a, %b
  ret i32 %s
}

; The classical arm's Rz stays in its own block (the region does not claim it),
; and the controlled Ry is hoisted into the region's pred with the flag mint,
; strip and free around it. Both measurements read the ONE rail %h1.
; CHECK:      call void @cqrt_rz_i32(i32 %h1, double 1.000000e-01)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %h1, double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %h1)
; CHECK:      call i32 @cqrt_measure_i32(i32 %h)

; No route: no work rail is minted, so the only allocs are the two sources.
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
