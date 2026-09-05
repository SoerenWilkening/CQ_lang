; control_inplace_ry_then_phase_region.ll — ACCEPT spec: a control-in-place
; ROTATION region followed by a swap-routed PHASE region on the SAME register
; (bd test_C_libtooling-drbq Inc 1).
;
;     if (q > 5) r = cq_theta(r, .9);      // control-in-place  (new)
;     if (q > 7) r = cq_phi(r, .4);        // swap route        (4.1, unchanged)
;
; THE COMPOSITION CHECK, and the reason it is worth a fixture of its own: the two
; mechanisms are different (one relabels in place, the other routes onto a |0>
; work rail), they run on ONE physical register, and each has to leave the other's
; premises intact.
;
;   * The phase region CSWAPs a register a controlled Ry has already relabelled.
;     That is fine — the route is basis-agnostic and its join is the adjoint of
;     its split, so it hands the register back exactly as it found it, whatever
;     the Ry put there.
;   * The phase region's own flag strip reads `q`, which neither region touched.
;   * The phase region's work rail is |0> for free (Rz|0>=|0>) and IS freed; the
;     rotation region mints no rail at all. Three frees total: flag, rail+flag.
;
; And the register itself stays FROZEN (`ChainWalk::railCarriesControlledRotation`
; — asked structurally of the emitted gate, never from a recorded `Value *`), so the
; whole-DAG spine adds no reversal of either region on top.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 4.000000e-01)
  br label %merge2
merge2:
  %m   = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; region 1 — control-in-place: no rail, no route
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; region 2 — ALSO control-in-place since drbq Inc 2a (it was the 4.1 swap route
; when this fixture was written), over the register region 1 relabelled. THE TWO
; STEMS SIT SIDE BY SIDE HERE, WHICH IS NOW THIS FILE'S REAL SUBJECT: the Ry above
; is a DAG link, frozen, never adjointed (its adjoint would need a flag the region
; already freed); the Rz below is NOT a link, not frozen, transparent — a diagonal
; gate relabels nothing on either branch. Same emitter, same flag mint/strip/free
; spine, two different uncompute treatments (PRD §12.1).
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[R]], double 4.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  phi i32
; No swap route survives on either region — window `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
