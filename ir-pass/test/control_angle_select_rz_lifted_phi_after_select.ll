; control_angle_select_rz_lifted_phi_after_select.ll — ACCEPT: the **Rz** twin of
; `control_angle_select_ry_lifted_phi_after_select.ll`. An Inc-2b BY-DIFFERENCE
; angle select on the PHASE stem, followed by the canonical 5j5 one-register
; merge-phi lift over the rotated register.
;
;     r = cq_phi(r, q == 5 ? .9 : .3);        // 2b, consumer rotation T (Rz)
;     if (OPQ) { r = cq_phi(r, .5); }         // 5j5 classical join phi
;
; bd test_C_libtooling-drbq Increment 3, ROUND-2 Rule-13 review, finding R1-Q1(c).
; WHY IT EXISTS: the F-L5-1 `resolveWireBase` stop was documented, and pinned, as
; an **Ry** story — `AngleSelectEmit.cpp` records its consumer in
; `taint.ControlledRotations` for **BOTH stems** (one `record` call, no stem
; test), so the Rz-stem angle select flips ORACLE-decline → HEAD-accept exactly
; like its Ry twin and nothing pinned it. Round 2 constructed this file; it is
; committed unchanged.
;
; MEASURED, both binaries, on this exact module:
;   ORACLE (`1bdaa60`, pre-Inc-3, already ships 2b):
;     error: ... cq taint escape: tainted value muxed by a classical-condition phi
;   HEAD: exit 0, the stream CHECKed below.
; So this is a PRE-EXISTING over-decline repaired incidentally, not an Inc-3
; regression — the same reading as the Ry twin's header, and the same category
; error behind it: lift clauses (6)/(7a) ask an EDGE-LOCAL question ("did taking
; this edge imply the gate ran?") of a gate that DOMINATES every edge into the
; join. `AngleSelectEmit` does no CFG surgery, so the consuming rotation stands
; where the source wrote it.
;
; WHY THE EMITTED STREAM IS SOUND, said for the Rz stem specifically:
;   * DIAGONAL. Both 2b gates and the lifted arm gate are `Rz`, which commutes
;     with the computational basis, so no gate here can dephase the flag mint or
;     the strip that surrounds it (PRD §12.1 — the reason the Rz stem is exempt
;     from Inc-1's R4/R6 fences in the first place).
;   * ONE HANDLE throughout. `%h1` is allocated once and every gate below —
;     unconditional `R(h,B)`, the controlled `R(h,A−B)`, the lifted arm `Rz` and
;     the measure — names it. The lift RAUWs the join φ to that handle; it does
;     not mint a rail, a route or a copy.
;   * THE CLASSICAL `if` KEEPS ITS BLOCK. `@OPQ` is a volatile load, so its guard
;     is classical control over a quantum handle and stays a real `br` — the
;     lifted `cqrt_rz_i32(%h1, .5)` fires on ONE path, exactly as written. This
;     is the half a reader should check first: if the lift had flattened that
;     branch, the arm gate would fire unconditionally and the unitary would be
;     wrong on the `OPQ == 0` path.
;   * `%h1` is FROZEN (`ChainWalk::railCarriesControlledRotation`): no `_unc` and
;     no `cqrt_free` on it anywhere below, because a controlled gate's adjoint
;     would need the flag that was already stripped and freed.
;
; VERBATIM `clang -O1` output for
;   volatile int OPQ = 1;
;   int slice(void) { int q=3, r=7;
;                     q = cq_theta(q,0.5); r = cq_theta(r,0.25);
;                     if (q == 5) { r = cq_phi(r,0.9); } else { r = cq_phi(r,0.3); }
;                     if (OPQ)    { r = cq_phi(r,0.5); }
;                     return cq_measure(q) + cq_measure(r); }
; (SimplifyCFG merges the two arms into ONE call with a `select` on the ANGLE —
; PRD §12.3 — which is why this is the 2b emitter and not a diamond.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

@OPQ = global i32 1, align 4

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  %4 = select i1 %3, double 9.000000e-01, double 3.000000e-01
  %5 = tail call i32 @cq_phi_si32(i32 noundef %2, double noundef %4)
  %6 = load volatile i32, ptr @OPQ, align 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %10, label %8

8:                                                ; preds = %0
  %9 = tail call i32 @cq_phi_si32(i32 noundef %5, double noundef 5.000000e-01)
  br label %10

10:                                               ; preds = %8, %0
  %11 = phi i32 [ %9, %8 ], [ %5, %0 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_phi_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; The 2b by-difference stream on the PHASE stem: unconditional Rz(h,B=.3), flag
; mint, ONE `cqrt_rz_i32_controlled(h, A−B = .6)`, strip, free — then the
; CLASSICAL guard's own surviving block with a plain uncontrolled Rz on the same
; rail, and the two measures.
; CHECK: %[[Q:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK: %[[R:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; The classical guard SURVIVES as a branch, and the lifted arm gate sits under it.
; CHECK: br i1
; CHECK: call void @cqrt_rz_i32(i32 %[[R]], double 5.000000e-01)
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[R]])

; Whole-file (the trailing-CHECK-NOT trap of round-1 F-L6-1): no route, no work
; rail, no surviving phi, and every front-end intrinsic lowered.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_si
; NOROUTE-NOT: cq_measure_si
