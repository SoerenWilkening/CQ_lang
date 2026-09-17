; control_phase_kickback_inloop_hoisted_tree_leaf.ll — ACCEPT. bd
; `test_C_libtooling-drbq.12` (2026-09-17), the TREE spelling of the LICM-hoisted
; loop-invariant compare, and the fixture that pins `classifyPhaseKickback`'s step-5a
; half of the widening (the other half is `condWireDisposition`'s P4).
;
;     int a = cq_theta(0, 0.5);
;     int r = cq_theta(0, 0.3);
;     for (int i = 0; i < 2; ++i) {
;         if (a == 5 && r > 2) { cq_phi(0.7); }
;         r = cq_theta(r, 0.9);
;     }
;     return cq_measure(a) + cq_measure(r);
;
; `clang -O1` output verbatim, and the SPLIT is what makes this a distinct fixture:
; `a` is loop-INVARIANT so LICM hoists the `a == 5` LEAF (`%3`) into the entry block,
; while `r` is loop-VARIANT so the `r > 2` leaf (`%11`) and the `&&` NODE (`%12`, a
; `select i1`) stay in `Pred`. Step 5a's `Leaf->getParent() != Region.Pred` was the
; ONLY wall — measured on the ORACLE, which declines `control flow under quantum
; control` at the `select`.
;
; ⚠ THE NODE PRONG IS UNTOUCHED AND MUST STAY UNTOUCHED. A few lines below step 5a,
; every `Tree.Nodes` member must still live in `Pred`, and that prong carries a
; SECOND, non-positional reason its own comment states: the `ClaimedSelects` hand-off
; is what stops the caller's tainted-`select` scan from ALSO claiming a logical-select
; node as an i1 data mux, and that scan is per-block. Widening the NODE prong is a
; different change with a different hazard (an ordering one), and it is filed, not
; taken — see `control_phase_kickback_reject_inloop_hoisted_tree_node.ll`, which pins
; the shape where `-O1` hoists the WHOLE tree and which still declines.
;
; ⚠ WHY THE BODY'S OWN Ry DOES NOT STALE THE HOISTED LEAF. `%15 = cq_theta(%10, 0.9)`
; in the latch is a non-diagonal gate that, around the back edge, executes BEFORE the
; next activation of the mint. For the hoisted leaf `%3` it is off-rail
; (`crossBlockCompareMintable`'s closure of `%3` is `{%3, %1}`; the theta's arg-0 is
; the `r` header φ). For the in-`Pred` leaf `%11` it IS on-rail, and it is admitted by
; the drbq Inc-3 PER-ACTIVATION machinery, not by anything this bead added: `%11` is
; re-executed every trip from the refreshed header φ, so the record the mint reads is
; never the stale one. Both halves are pre-existing except the position.
;
; THE STREAM IS THE SHIPPED TREE KICKBACK: one flag per leaf, a `cqrt_toffoli` into a
; fresh `|0>` ancilla for the AND, the `cqrt_rz_i1` on THAT ancilla carrying
; `!cq.branchphase`, then the network torn down LIFO — toffoli, free the ancilla,
; strip and free each leaf flag in reverse. ⚠ `%h` and `%h2` are USER registers: they
; appear only as arg-0 of a mint or a strip, or in a measure. Never
; `cqrt_x`-bracketed, never freed.
;
; RETIREMENT TRIGGER (L8): if step 5a's cross-block admission is narrowed back, this
; file becomes a decline expecting `cq controlled lowering: control flow under quantum
; control`, anchored on the `select`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTRZ %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTTOF %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTANC %s < %t.cqd0.ll
; ---- MUTATION-MATRIX HARDENING (bd `test_C_libtooling-drbq.12`, 2026-09-17) ----
; Rule 12(c): a fixture is validated by MUTATION, not by re-reading its prefixes.
; The first injection-matrix run over this batch reported 21 MISSED over 9 accept
; fixtures — a stray `cqrt_ry` before the `ret`, a duplicated mint, a duplicated
; free, and a `cqrt_x` injected onto the USER REGISTER all slipped through, because
; no whole-file prefix counted those symbols here. The block below is the closure:
; an EXACT count per symbol (a `COUNT-n` followed by its own `-NOT`, which is what
; turns "at least n" into "exactly n"), ONE PREFIX PER SYMBOL because consecutive
; `COUNT`s under a shared prefix scan FORWARD and fall through to the trailing
; `declare` lines, and a pure-negative prefix for the two gates that must never
; appear. Counts are MEASURED off this fixture's own lowered output, never guessed.
; RUN: %filecheck --check-prefix=MXALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRZ %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXTOF %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-3: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-3: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRZ-COUNT-1: call void @cqrt_rz_i1(
; MXRZ-NOT: call void @cqrt_rz_i1(
; MXMINT-COUNT-2: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-2: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-3: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXTOF-COUNT-2: call void @cqrt_toffoli(
; MXTOF-NOT: call void @cqrt_toffoli(
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK: %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: %[[FB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 2)
; CHECK: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G]])
; CHECK: call void @cqrt_rz_i1(i32 %[[G]], double 0x3FE6666666666666), !cq.branchphase
; CHECK: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G]])
; CHECK: call void @cqrt_free(i32 %[[G]])
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FB]], i32 %[[R]], i32 2)
; CHECK: call void @cqrt_free(i32 %[[FB]])
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FA]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[FA]])
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 9.000000e-01)

; Negatives name the CALL, never the bare symbol (bd `qta2`: the module keeps unused
; `declare`s). No controlled rotation is emitted anywhere — a PHASE arm puts the
; answer on the FLAG (Rule 7), and nothing is emitted on a user register at all.
; NEG-NOT: call void @cqrt_ry_i32_controlled
; NEG-NOT: call void @cqrt_rz_i32
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call{{.*}}@cq_phi
; NEG-NOT: call{{.*}}@cq_theta_

; Counts, one prefix per symbol (Rule 12(a); consecutive COUNTs under one prefix scan
; forward and silently fall through to the trailing `declare` lines). The loop is
; ROLLED, so exactly one network per trip is also the trip-count-independence witness.
; CNTRZ-COUNT-1: call void @cqrt_rz_i1(
; CNTRZ-NOT: call void @cqrt_rz_i1(
; CNTTOF-COUNT-2: call void @cqrt_toffoli(
; CNTTOF-NOT: call void @cqrt_toffoli(
; CNTFREE-COUNT-3: call void @cqrt_free(
; CNTFREE-NOT: call void @cqrt_free(
; CNTANC-COUNT-1: call i32 @cqrt_alloc_i1(
; CNTANC-NOT: call i32 @cqrt_alloc_i1(

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %8

4:                                                ; preds = %14
  %5 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %15) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %14
  %9 = phi i32 [ 0, %0 ], [ %16, %14 ]
  %10 = phi i32 [ %2, %0 ], [ %15, %14 ]
  %11 = icmp sgt i32 %10, 2
  %12 = select i1 %3, i1 %11, i1 false
  br i1 %12, label %13, label %14

13:                                               ; preds = %8
  tail call void @cq_phi(double noundef 0x3FE6666666666666) #2
  br label %14

14:                                               ; preds = %13, %8
  %15 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  %16 = add nuw nsw i32 %9, 1
  %17 = icmp eq i32 %9, 0
  br i1 %17, label %8, label %4, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
