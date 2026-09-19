; control_predmux_reject_rail_phi_interior_convertible.ll — DECLINE, and ⚠ THE
; REGRESSION PIN FOR A VERIFY-CLEAN SILENT WRONG UNITARY (bd fn1q increment 5a,
; Rule-13 ROUND 2 finding R5aR2-1, P1).
;
; THE DEFECT. Increment 5a's E6 rail-φ admission is checked BEFORE the
; `dyn_cast<PHINode>` arm, so the φ is never inserted into `S->Recorded`. Round 1
; found ONE consequence (a raw `PHINode` reaching `buildNegation`'s
; `cast<BinaryOperator>`) and fixed it. THIS IS THE OTHER ONE, and it is worse.
;
; `run()` converts every region block's phis EXCEPT the entry's. This φ (`%16`) is
; in a NON-ENTRY region block, so `convertPhis` DOES run; its BoolAlg re-check is
; SCOPE-LESS and a `cq_theta_i1` CALL incoming fails `isBooleanCondTree`; the φ
; therefore falls to the Inc-1 SELECT CHAIN, handing `buildNegation`
; `select(EP, %rail, true)`. Its select arm's `cast<ConstantInt>` is
; ASSERTION-ONLY (`(void)TC`) — so the RELEASE build every gate here runs does NOT
; crash. It returns `and(¬EP, ¬true)` = FALSE, the arm's edge predicate goes
; CONSTANT-FALSE, its value is dropped from the merge and its whole cone is
; dead-swept. ⚠ NOTHING OFF-GRAMMAR SURVIVES FOR A DOWNSTREAM OWNER TO OBJECT TO:
; THE SILENCE IS STRUCTURAL, NOT LUCKY.
;
; ⚠ THE EMITTED CIRCUIT WAS WRONG, NOT MERELY UNPROVEN. On the defective binary
; this module exits 0 with 0 BYTES of stderr and emits a trace that links and runs
; in which the inner `q > 5` compare is ABSENT, both table reads are gone, and the
; rail is `cqrt_alloc_i1` + `cqrt_ry_i1` + `cqrt_measure_i1` — NEVER USED AS A
; CONTROL. On the basis states `r < 9 ∧ q > 5 ∧ b = 0` the source computes
; `v = tbl[s&3]`, `w = tbl[(s+1)&3]`; the circuit computes `v = 5`, `w = 6`.
; `opt -verify` clean. `free_pairing_check.py`: `2 verified, 0 violation(s),
; 0 unproven` — structurally perfect, semantically wrong. NEITHER SHIPPED GATE
; SEES IT, which is the Prime Directive's named failure mode verbatim.
;
; PROVENANCE: this is `clang -O1` output, UNEDITED except for renaming `@main` to
; `@probe`, stripping attribute groups and dropping `!tbaa`. The C is six lines of
; ordinary `CQ.h` with no `volatile` and nothing `CQ.h` cannot emit
; (`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-orchestrator/probes/r13r2/c13.c`).
; ⚠ That matters: the reviewer's hand-written interior-φ IR probes all died at
; `gate=W-witness` instead, so a hand-built module is NOT a substitute here — the
; shape needs an outer region that actually claims.
;
; NON-VACUITY, MEASURED BY MUTATION (both directions):
;   defective binary (5a without the placement conjunct)  -> rc=0, SILENT ACCEPT
;   ORACLE (git a9a227e4, pre-5a)                          -> rc=1, the string below
;   FIXED                                                  -> rc=1, the string below
; So this file is RED on the defect and GREEN on the fix, and it cannot go green
; because its subject stopped existing (Rule 12 hygiene (c)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; ⚠ THE GATE-PREFIXED LINE BELOW IS THE LOAD-BEARING ASSERTION, not the error
; string. A decline string alone would also be printed if some LATER owner refused
; this module for an unrelated reason — the increment-3 round-2 lesson (R2-2).
; Pinning the gate pins that the region was LEFT AT E6, pre-claim, which is what
; the fix does.
; ⚠ AND THIS PARAGRAPH IS WRITTEN WITHOUT SPELLING THE PREFIX, BECAUSE NAMING A
; FileCheck DIRECTIVE IN PROSE CREATES ONE. The first draft of this header said the
; prefix out loud and FileCheck matched the SENTENCE as a directive — a red fixture
; whose only defect was its own comment. That is CLAUDE.md's standing lesson, paid
; for the third time in three sessions; do not reintroduce the token above the RUN
; lines.
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; DBG: CQ_PREDMUX_DBG: leave @probe entry= merge= gate=E6-condtree
;
; ⚠ RETIREMENT TRIGGER (L8). The interior rail φ refused here is REALIZABLE — a
; classical join feeding a quantum control — so this is an OVER-DECLINE by the
; 2026-09-11 owner ruling, not a physics wall. The day someone makes it lower (by
; RECORDING the φ so `convertPhis` cannot select-chain it, which is the only route
; that removes the defect rather than hiding it), this file becomes an ACCEPT and
; its emitted stream must be re-derived from scratch. DO NOT DELETE IT THEN; and do
; not "fix" it by widening E6 again without recording the φ, which is exactly the
; change that produced the wrong unitary above.
@tbl = internal unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

define i32 @probe(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = add nsw i32 %0, 1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01)
  %7 = icmp slt i32 %6, 9
  br i1 %7, label %8, label %28

8:                                                ; preds = %2
  %9 = icmp sgt i32 %4, 5
  br i1 %9, label %10, label %15

10:                                               ; preds = %8
  %11 = and i32 %0, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  br label %15

15:                                               ; preds = %10, %8
  %16 = phi i1 [ %5, %10 ], [ true, %8 ]
  %17 = phi i32 [ %14, %10 ], [ 0, %8 ]
  br i1 %16, label %28, label %18

18:                                               ; preds = %15
  %19 = and i32 %17, 3
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %20
  %22 = load i32, ptr %21, align 4
  %23 = add nsw i32 %17, 1
  %24 = and i32 %23, 3
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %25
  %27 = load i32, ptr %26, align 4
  br label %28

28:                                               ; preds = %2, %15, %18
  %29 = phi i32 [ 7, %2 ], [ %22, %18 ], [ 5, %15 ]
  %30 = phi i32 [ 8, %2 ], [ %27, %18 ], [ 6, %15 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %29)
  %32 = tail call i32 @cq_measure_si32(i32 noundef %30)
  %33 = add nsw i32 %32, %31
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5)
  %35 = zext i1 %34 to i32
  %36 = add nsw i32 %33, %35
  ret i32 %36
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
