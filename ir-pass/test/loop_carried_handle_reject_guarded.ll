; loop_carried_handle_reject_guarded.ll — bd `test_C_libtooling-zujr`, the (Z8)
; ISOLATING CONTROL for `loop_carried_handle_accept_select_merge.ll`.
;
; ONE EDIT from the positive: the loop is ROTATED behind a ZERO-TRIP GUARD, which
; is what a RUNTIME trip bound produces.  The promotion's `cqrt_alloc` lives in
; the PREHEADER, and the guard's false edge BYPASSES it — so the exit phi muxes
; the CLASSICAL seed `5` with the handle `%anext`, and no promotion can fix that
; from the preheader.
;
; ⚠ THE MODULE DECLINED BEFORE AND DECLINES NOW; (Z8) DECIDES **WHICH OWNER
; SPEAKS**.  Without it the predicate admitted the phi, both X1 sites deferred,
; the promotion ran, and `declineClassicalMuxes` refused the EXIT phi with
; `cq taint escape: tainted value muxed by a classical-condition phi` — a true
; sentence about the wrong instruction, pointing at the merge instead of at the
; loop.  MEASURED.
;
; ⚠ IT IS A DECLINE-DIRECTION CONJUNCT AND IT IS NOT THE CAPABILITY.  Hoisting
; the alloc ABOVE the guard and rewriting the exit phi would make this lower too;
; that is an ACCEPT-direction widening with its own Rule-13 round and its own
; zero-trip question (an allocation the program may never use).  L8 RETIREMENT
; TRIGGER: the day that lands, this file becomes an ACCEPT.  Re-derive it then;
; do NOT delete it.
; ⚠ MUTANT-VALIDATED, AND IT HAD TO BE (Rule-13 round 1, F-6; CLAUDE.md L10 —
; *an instrument is worth citing only once it has been made to fail on purpose*).
; THIS FILE PRINTS THE SAME STRING ON THE ORACLE, so no RUN line of its own
; discriminates the conjunct it names; what does is a SOURCE MUTANT.  Measured by
; deleting each of the four conjuncts in turn from a scratch build and running the
; whole `loop_carried_handle` family against each:
;
;     MUTANT Z3 (drop `isIntegerTy(32)`)      KILLS reject_narrow_width   and nothing else
;     MUTANT Z4 (drop the classical-seed test) KILLS reject_tainted_seed  and nothing else
;     MUTANT Z6 (drop latchIsControlMergeRail) KILLS reject_accumulator   and nothing else
;     MUTANT Z8 (drop the reader walk)         KILLS reject_guarded       and nothing else
;
; A 1:1 matrix, MISSED 0.  THIS FILE IS THE ONE `MUTANT Z8` KILLS.
; (The Z3 mutant does not merely change a string: it emits
; `PHI node operands are not the same type as the result!` and `opt` aborts with
; exit 134 — a verifier-invalid module, which is what the conjunct exists to stop.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %n) {
entry:
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit

ph:
  br label %head

head:
  %i = phi i32 [ 0, %ph ], [ %inext, %head ]
  %a = phi i32 [ 5, %ph ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %r = phi i32 [ 5, %entry ], [ %anext, %head ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; CHECK: cq loop lowering: loop-carried tainted value crosses iterations
