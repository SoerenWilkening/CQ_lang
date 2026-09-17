; loop_carried_handle_reject_accumulator.ll — bd `test_C_libtooling-zujr`, the
; (Z6) ISOLATING CONTROL for `loop_carried_handle_accept_select_merge.ll`.
;
; ONE EDIT from the positive: the latch incoming is `acc = acc + q`, a FRESH
; TEMPLATE RAIL, instead of a tainted-condition `select`'s merge `%out`.  That is
; X1's own shape — the cross-iteration dirty rail — and clause (Z6)
; (`latchIsControlMergeRail`) is what keeps it there.
;
; ⚠ IT PINS A **DIAGNOSTIC**, WHICH IS WHY IT IS A FIXTURE AND NOT A COMMENT.
; Both verdicts are declines either way; without (Z6) the accurate
; `cq loop lowering: loop-carried tainted value crosses iterations` became
; `cq taint escape: tainted value muxed by a classical-condition phi` — the
; predicate deferred, the promotion refused, and the mux guard spoke instead.
; A structural guard wearing the wrong label is CLAUDE.md's L6 and is exactly the
; defect class bd `8h7d.12` is open for.  MEASURED before (Z6) was written.
;
; ⚠ AND IT IS THE `i32` SPELLING ON PURPOSE.  `lowering_reject_loop_cross_iter.ll`
; is the same program at `double`, where clause (Z3)'s `isIntegerTy(32)` refuses
; the phi before (Z6) is ever asked — so that file cannot witness this and this
; one can.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i32 [ 5, %entry ], [ %anext, %head ]
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %anext = add nsw i32 %a, %q
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
