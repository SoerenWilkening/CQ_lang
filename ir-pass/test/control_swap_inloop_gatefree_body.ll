; control_swap_inloop_gatefree_body.ll — ACCEPT, and the ACCEPT BOUNDARY of the
; F-2 identity-carry rule (bd test_C_libtooling-8h7d.5, Rule-13 ROUND 2).
;
;     int q = cq_theta(0, .5);
;     for (i<2) { if (q==5) q = cq_phi(q, PI); }     // the body is ONLY a phase region
;     return cq_measure(q);
;
; This is `r2x/z1_gatefree_body.c` at `clang -O1` (the Rz's arg-0 is const-folded
; to `5` on the gated edge, which is what -O1 really emits and why this is not a
; duplicate of control_swap_inloop_diamond.ll). Post-flatten the region's merge
; phi is dissolved, so the loop-carried rail phi becomes an IDENTITY CARRY — the
; exact shape F-2 says never refreshes a record.
;
; IT MUST STILL LOWER, and it does, for a reason that is not a special case: the
; rail's only basis-relabelling gate is the ROOT MINT itself, which sits in the
; entry block and is never re-reachable, so `railGateBetween` finds no path
; `Def → gate → read` whether or not the cut is taken. F-2 REMOVES a cut, and a
; removed cut can only turn a found path into a decline — it cannot invent one.
; The rail is pure-Rz inside the loop (diagonal, no relabelling), so nothing the
; body does can stale the exit read.
;
; The RED twin is lowering_reject_inloop_rail_identity_carry.ll — the same carry
; with a SIBLING chain on the same mint that rotates the wire.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. The F-2 argument above is
; untouched — it is about the RAIL's basis-relabelling gates, and neither the route
; nor the controlled Rz is one (both are diagonal-or-permutation on the register).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 0x400921FB54442D18)  ; -O1 const-folds arg-0
  br label %merge
merge:
  %inext = add i32 %i, 1
  %done = icmp eq i32 %i, %n
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ONE rail minted outside the loop; the rolled body is the in-place phase arm and
; nothing else; the exit measure names the same handle:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     loop:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     exit:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; No rail phi survives, and no decline:
; CHECK-NOT: phi i32 [ %[[H]]
; CHECK-NOT: rail record read past an in-place gate
;
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
