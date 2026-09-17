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
