; loop_carried_handle_reject_narrow_untyped_call_user.ll — bd `test_C_libtooling-11qv`,
; the (P4) CRASH FENCE, and the RED half of the red-green pair for a Rule-13
; round-4 **P1**.
;
; THE DEFECT THIS PINS, in the words it has to be said in: for a short while the
; subject binary ANSWERED A NARROW CARRIED HANDLE BY ABORTING `opt` AT EXIT 134
; where the ORACLE emitted a clean loud decline.  That is a Rule-1 violation —
; *the answer to "unsure" is a LOUD DECLINE, never a crash* — and it was
; committed by the very clause written to prevent it.
;
; WHY THE FIRST (P4) FAILED.  It allowed a user whose callee NAME began `cq_` or
; `cqrt_`, on the stated ground that *"their own lowering stage rewrites the
; operand to the i32 handle"*.  That ground is false for all three families the
; prefix admits: `cqrt_*` IS the already-lowered runtime ABI and nothing rewrites
; it; a hand-written `cq_template_*` is a recognised input class in this tree and
; also matches `cq_`; `cq_invert_*` is an unbuilt Phase-8 handoff.  Worse, those
; are EXACTLY the three prefixes `declineTaintEscapes` EXEMPTS — so every call
; that survived the escape guard through that exemption also passed here.  **The
; second list trusted what the first one merely tolerated.**
;
; WHAT REPLACED IT, and the shape of the lesson.  The question was never "what is
; this called" — it is *"after `mutateType(i32)`, is this operand still
; well-typed?"*, and that is answered from the CALLEE'S DECLARED PARAMETER TYPE.
; A `cqrt_copy_<W>_controlled(i32, i32, i32)` minted by the merge emitter takes
; the phi in an `i32` slot, so for THAT call the retype is the REPAIR, not the
; hazard — refusing it would decline this increment's own headline.
; `@cqrt_sink_i16(i16)` below is the opposite and must SKIP.
; ⚠ A NAME TEST COULD NOT HAVE SEPARATED THOSE TWO: both are `cqrt_*`.
;
; ⚠ THE SAME CLAUSE ALSO ASKS THE QUESTION OF THE **LATCH VALUE**, for a
; DIFFERENT and PRE-EXISTING defect: the merge emitter's `%out` is `i32` at every
; width, so a narrow-typed external user of that rail is ill-typed the moment the
; region lowers — and its loop-FREE twin aborts identically on the ORACLE
; (measured).  That defect is not this increment's, but the promotion is what
; lets such a loop lower at all, so without the check a program the oracle
; refused cleanly would ABORT.  *"Pre-existing" is true of the defect and FALSE
; of its population*, and Rule 1 does not care whose defect it is.
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves when (P4)'s parameter-type test, its
; theta/measure membership clause, or its latch-value half changes.  RE-DERIVE it
; then; do not delete it, and do not predict the string it lands on.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i16 @cq_measure_si16(i16)
declare void @cqrt_sink_i16(i16)

define i32 @main(i32 %n) {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i16 [ 5, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i16 %a, -3
  %anext = select i1 %b, i16 %sub, i16 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  call void @cqrt_sink_i16(i16 %a)
  %m = call i16 @cq_measure_si16(i16 %anext)
  %z = zext i16 %m to i32
  ret i32 %z
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; A LOUD DECLINE, exit non-zero — the promotion SKIPPED, so the unpromoted phi is
; refused by the very next stage. ⚠ What this fixture really pins is the `not` on
; the RUN line: an abort is ALSO non-zero, so read the string too.
; CHECK: cq taint escape: tainted value muxed by a classical-condition phi

; ⚠ AND IT MUST NOT BE THE CRASH. `opt` exiting 134 prints the verifier's own
; text, never a `cq ` diagnostic; these two negatives are what tell the decline
; and the abort apart, and they are the whole reason this file exists.
; CHECK-NOT: Broken module found
; CHECK-NOT: does not match function signature
