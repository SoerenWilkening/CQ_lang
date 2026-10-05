; control_angle_select_ry_lifted_phi_after_select.ll — ACCEPT: an Inc-2b
; BY-DIFFERENCE angle select followed by the canonical 5j5 one-register
; merge-phi lift over the ROTATED register.
;
;     cq_theta(&r, q == 5 ? .9 : .3);      // 2b, consumer rotation T
;     if (OPQ) { }                         // 5j5 classical join phi
;
; bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review, F-L5-1's
; SECOND customer. Read this file together with
; `control_inplace_ry_lifted_phi_after_region.ll`, which is the same shape one
; emitter over.
;
; SAY PLAINLY WHAT THIS ONE IS. Unlike its Inc-1 sibling, this cell is **not** an
; Inc-3 regression repair — the PRE-Inc-3 oracle (`1bdaa60`, which already ships
; 2b) declines it `cq taint escape: tainted value muxed by a classical-condition
; phi`. It is a PRE-EXISTING over-decline that the F-L5-1 fix repairs incidentally,
; because the fix corrects a CATEGORY ERROR both instances share: lift clauses (6)
; and (7a) ask an EDGE-LOCAL question ("did taking this edge imply the gate ran?")
; of a gate that DOMINATES every edge, and a dominating gate discharges that
; obligation a different way. `AngleSelectEmit` does no CFG surgery at all, so the
; consuming rotation stands where the source wrote it and every path into the join
; below it executed it.
;
; ⚠ AND SAY WHAT THE FIX DELIBERATELY DOES **NOT** DO. The same domination
; argument would admit an ordinary UNCONTROLLED pre-branch in-place rotation, and
; that shape STILL DECLINES — it is the documented conservative over-decline in
; `lowering_reject_classical_mux_phi_crossblock_chain.ll`'s closing paragraph.
; Generalizing `resolveWireBase` to a dominance-based common-prefix strip would
; cover all three uniformly and is a REAL widening of the 5j5 accept class: it
; needs its own probe family (Rule 12) and its own Rule-13 round, and it is not
; this fix. The shipped stop is keyed on `taint.ControlledRotations` — the gates
; another owner (`ControlDetect`+`ArmClassify`, or `classifyAngleSelect`) has
; ALREADY adjudicated — and nothing wider.
;
; VERBATIM `clang -O1` output (pre-3qlq register form; the migration then
; deleted the OPQ arm's uncontrolled phase) for
;   volatile int OPQ = 1;
;   int slice(void) { int q=3, r=7;
;                     cq_theta(&q,0.5); cq_theta(&r,0.25);
;                     if (q == 5) { cq_theta(&r,0.9); } else { cq_theta(&r,0.3); }
;                     if (OPQ)    { r = cq_phi(r,0.5); }
;                     return cq_measure(q) + cq_measure(r); }
; (SimplifyCFG merges the two arms into ONE call with a `select` on the ANGLE —
; PRD §12.3 — which is why this is the 2b emitter and not a diamond.)
; ⚠ bd test_C_libtooling-fmt3 (2026-09-28): for `cq_theta` the sentence above is
; no longer true. `include/CQ.h` puts `nomerge` on every `cq_theta_*`, so `-O1` keeps
; that if/else an if/else (it lowers through the in-place Ry arm, the same unitary).
; THIS select shape now comes from C only when the select is written out,
; `cq_theta(&r, c ? A : B)` (`tests/e2e/slice_control_angle_select_ry*_ternary.c`,
; measured to give the pre-fmt3 fold's function bodies). The IR and this fixture are
; unchanged; only the C spelling that reaches them moved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

@OPQ = global i32 1, align 4

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  %4 = select i1 %3, double 9.000000e-01, double 3.000000e-01
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %4)
  %6 = load volatile i32, ptr @OPQ, align 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %10, label %8

8:                                                ; preds = %0
  br label %10

10:                                               ; preds = %8, %0
  %11 = phi i32 [ %5, %8 ], [ %5, %0 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; The 2b by-difference stream: unconditional R(h,B=.3), flag mint, ONE controlled
; R(h, A−B = .6), strip, free — then the CLASSICAL guard's (now empty) blocks.
; CHECK: %[[Q:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK: %[[R:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK: br i1
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[R]])

; No route, no work rail, no surviving phi, and every front-end intrinsic lowered.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_si
; NOROUTE-NOT: cq_measure_si
