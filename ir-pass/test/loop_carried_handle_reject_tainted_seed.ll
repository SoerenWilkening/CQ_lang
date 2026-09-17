; loop_carried_handle_reject_tainted_seed.ll — bd `test_C_libtooling-zujr`, the
; (Z4) ISOLATING CONTROL for `loop_carried_handle_accept_select_merge.ll`.
;
; ONE EDIT from the positive: the entry incoming is already a RAIL
; (`%seed = cq_theta(5, .25)`), not a classical literal.  There is nothing to
; promote — the register exists — and this is NOT the loop-carried HANDLE
; variable but the ordinary loop-carried rail, whose own owners are
; `collapseRailPhisIn` (the closed self-cycle) and X1 (everything else).
;
; It matters because (Z4) is what keeps the promotion from RE-ALLOCATING a
; register the program already holds: `materializeCopySource` returns its input
; unchanged for a tainted value, so without (Z4) the clause would be a silent
; no-op here rather than a refusal — and a no-op that leaves the phi
; UNPROMOTED while `PromotedCarriedHandlePhis` records it would hand
; `declineClassicalMuxes` an accept it was never owed.
; ⚠ MUTANT-VALIDATED, AND IT HAD TO BE (Rule-13 round 1, F-6; CLAUDE.md L10 —
; *an instrument is worth citing only once it has been made to fail on purpose*).
; THIS FILE PRINTS THE SAME STRING ON THE ORACLE, so no RUN line of its own
; discriminates the conjunct it names; what does is a SOURCE MUTANT.  Measured by
; deleting each of the four conjuncts in turn from a scratch build and running the
; whole `loop_carried_handle` family against each:
;
;     MUTANT Z3 (drop the width test)         KILLS accept_narrow_width   and nothing else
;       ⚠ THAT ROW IS HISTORY AS WRITTEN AND IS KEPT FOR ITS REASON, NOT ITS
;       VERDICT.  bd `test_C_libtooling-11qv` (2026-09-20) RETIRED the `i32` test:
;       the promotion now RETYPES the phi (`mutateType(i32)` + the `HandleWidth`
;       record), so the narrow width is an ACCEPT and its file is
;       `loop_carried_handle_accept_narrow_width.ll`.  What the Z3 mutant showed
;       still stands as the reason the retype is owed: dropping the width test
;       WITHOUT the retype emitted `PHI node operands are not the same type as
;       the result!` and `opt` aborted with exit 134.
;     MUTANT Z4 (drop the classical-seed test) KILLS reject_tainted_seed  and nothing else
;     MUTANT Z6 (drop latchIsControlMergeRail) KILLS reject_accumulator   and nothing else
;     MUTANT Z8 (drop the reader walk)         KILLS accept_guarded       and nothing else
;       ⚠ ALSO HISTORY AS WRITTEN.  bd `test_C_libtooling-h1ip` (2026-09-20,
;       owner ruling Q1) RETIRED the guarded DECLINE: the promotion now mints the
;       trip-1 register in the GUARD'S OWN block and rewrites the exit phi's
;       zero-trip incoming, so the file is `loop_carried_handle_accept_guarded.ll`.
;       What the Z8 mutant showed still stands as the reason the hoist is owed:
;       without it the guarded module declined at the EXIT PHI, a true sentence
;       about the wrong instruction (CLAUDE.md L6).
;
; A 1:1 matrix, MISSED 0.  THIS FILE IS THE ONE `MUTANT Z4` KILLS.
; (The Z3 mutant does not merely change a string: it emits
; `PHI node operands are not the same type as the result!` and `opt` aborts with
; exit 134 — a verifier-invalid module, which is what the conjunct exists to stop.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f() {
entry:
  %seed = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i32 [ %seed, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %anext)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; CHECK: cq loop lowering: loop-carried tainted value crosses iterations
