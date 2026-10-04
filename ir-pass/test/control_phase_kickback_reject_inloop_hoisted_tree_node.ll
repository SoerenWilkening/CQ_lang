; control_phase_kickback_reject_inloop_hoisted_tree_node.ll — DECLINE, and it is the
; RESIDUE of bd `test_C_libtooling-drbq.12` (2026-09-17): the LICM-hoisted
; loop-invariant condition that this bead did NOT move, recorded so the boundary is a
; deliberate line rather than an absence.
;
;     int a = 0; cq_theta(&a, 0.5);
;     _Bool b = 0; cq_theta(&b, 0.5);
;     for (int i = 0; i < 2; ++i) { if (b && a == 5) cq_phi(M_PI); }
;     return cq_measure(a) + (int) cq_measure(b);
;
; This is the twin-matrix cell `m_none_ablphi_none_none_binv` (bd `uq96`, Track T,
; 2026-09-14), filed on `drbq.12` as a customer WITH a live flat twin: the
; hand-unrolled spelling ACCEPTS on the oracle and on HEAD, the rolled one does not.
; `clang -O1` output verbatim.
;
; ⚠ WHY IT STILL DECLINES, AND IT IS NOT THE PRONG THIS BEAD WIDENED. `-O1` hoists
; the WHOLE condition tree, not just the invariant leaf: `%3 = icmp eq i32 %1, 5`
; AND the `&&` NODE `%4 = select i1 %2, i1 %3, i1 false` both land in the entry
; block, while the region's `Pred` is the loop header. Step 5a's compare-LEAF
; residency check — the one `drbq.12` widened, via `crossBlockCompareMintable` — is
; therefore no longer the wall; the NODE check a few lines below it is:
;
;     if (IsTree) for (Instruction *N : Tree.Nodes)
;       if (N->getParent() != Region.Pred) decline "control flow";
;
; and that prong carries a SECOND, NON-POSITIONAL reason its own comment states: the
; `ClaimedSelects` hand-off is what stops the caller's tainted-`select` scan from
; ALSO claiming a logical-select node as an i1 data mux, and that scan is PER-BLOCK
; and runs after its block's terminator — so a node in another block can be visited
; BEFORE this region claims it. Widening it is an ORDERING change, not a position
; one, with a different hazard and its own Rule-13 obligation. Declining is the
; Prime-Directive side of a real question, not a punt (Rule 17: the shape this bead
; set out to build is the compare LEAF, and that one IS built —
; `control_phase_kickback_inloop_hoisted_tree_leaf.ll`).
;
; ⚠ CONTRAST IT WITH ITS SIBLING, WHICH IS THE POINT OF SHIPPING BOTH.
; `control_phase_kickback_inloop_hoisted_tree_leaf.ll` is the same tree shape with a
; LOOP-VARIANT second leaf (`r > 2`), so `-O1` hoists the leaf and leaves the node in
; `Pred` — and it ACCEPTS. One file per side of the node/leaf line.
;
; RETIREMENT TRIGGER (L8): the day the NODE prong gains a cross-block admission (it
; needs a `ClaimedSelects` ordering argument, not a wire one), this file becomes an
; ACCEPT whose stream is the tree kickback on a `cqrt_toffoli` of the `_Bool` RAIL
; leaf `%2` and the compare leaf `%3` — `%2` read only as a control, one ancilla,
; one free. Re-derive it then; do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: control flow under quantum control
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so IR-text negatives would be
; VACUOUS here (Rule 12(b)); the property is pinned by the `not` inversion and the
; string. None is written, deliberately.

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare i1 @cq_measure_i1(i1 noundef zeroext)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  %4 = select i1 %2, i1 %3, i1 false
  br label %10

5:                                                ; preds = %13
  %6 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2
  %8 = zext i1 %7 to i32
  %9 = add nsw i32 %6, %8
  ret i32 %9

10:                                               ; preds = %0, %13
  %11 = phi i32 [ 0, %0 ], [ %14, %13 ]
  br i1 %4, label %12, label %13

12:                                               ; preds = %10
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %13

13:                                               ; preds = %10, %12
  %14 = add nuw nsw i32 %11, 1
  %15 = icmp eq i32 %11, 0
  br i1 %15, label %10, label %5, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
