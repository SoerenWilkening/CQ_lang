; e1c (CONTROL, dead phi deleted): RESIDUAL ESCAPE A -- a `use_empty()` carried-handle header phi.
; `%dead` has NO users.  It satisfies every conjunct of `loopCarriedHandlePhi`,
; so `collectCarriedHandleChains` puts {%dead, %anext} into `RootsOut` and
; `iterationLocalTaintEscape` (R7-loop clause (c3)) stops counting `%anext` as an
; iteration-local temp that escapes the loop.  The control `e1c` is this module
; with the dead phi DELETED and nothing else changed.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %sub = add nsw i32 %q, -3
  %anext = select i1 %b, i32 %sub, i32 %q
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %anext)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
