; control_angle_select_reject_compound_cond.ll — DECLINE (S4): a COMPOUND
; `and i1` condition tree (bd drbq Inc 2b).
;
; S4 requires a BARE `CmpInst` (`Tree.Nodes` empty, ONE leaf). A real and/or tree
; needs the 3c6m.12 flag NETWORK — a fresh `|0>` ancilla per node, a toffoli, and
; a reverse strip in LIFO order — which the 4.4 select emitter has and this
; emitter does not.
;
; HAND-WRITTEN, DELIBERATELY, and the reason is worth recording: `clang -O1` does
; NOT produce this shape from `if (q > 5 && q < 100)`. It folds the whole
; conjunction to ONE compare on a derived value (`add q,-6; icmp ult ..., 94`),
; which this increment ACCEPTS — see
; `control_angle_select_ry_derived_cond.ll`. So the tree form is reachable only
; from hand IR or a spelling `-O1` does not canonicalize, and this fixture is the
; fence for it rather than a shape the C surface hits.
;
; ⚠ FLIPPED TO AN ACCEPT BY bd test_C_libtooling-dm7f.54 (2026-10-15), NAME KEPT
; (gahu precedent, L8), and found by that change's green run rather than
; predicted (recorded). The emitter now HAS the 3c6m.12 network: a Ry-stem
; angle select whose condition is not a bare compare mints through
; `CondTreeEmit` (the network the 4.4 select and the dm7f.52 in-place Ry tree
; use). The stream: one flag per compare leaf, `toffoli` onto a fresh `g`, the
; X-bracket pair on `g` (owner ruling angle-select-xbracket 2026-10-13), then
; the exact LIFO strip (node, then leaves in reverse mint order).
; ANALYTIC: g = (q > 5) ∧ (q < 100); g = 1 -> Ry(.9) on r, g = 0 -> Ry(.3);
; q is never relabelled (S8: r is off q's wire), so each `_unc` returns its
; flag to |0> and every free is proven-|0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[G]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[G]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 100)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; NEG-NOT: = select
; NEG-NOT: = icmp
; NEG-NOT: = and
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  %c2 = icmp slt i32 %q, 100
  %c = and i1 %c1, %c2
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
