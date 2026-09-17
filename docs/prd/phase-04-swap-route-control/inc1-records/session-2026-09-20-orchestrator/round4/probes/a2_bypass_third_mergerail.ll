; a2 — PROBE: same as a1, but the THIRD (tainted, unproven) incoming of the exit
; phi is another 4.4 CONTROL-MERGE `%out` rail rather than a bare theta handle, so
; the uncompute spine has a recognised terminal on that edge too.  The promotion
; still records the whole phi in `taint.PromotedCarriedHandlePhis` on the strength
; of ONE incoming, and `declineClassicalMuxes` then accepts a phi muxing TWO
; DISTINCT quantum registers under a classical condition.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %n, i32 %m) {
entry:
  %mc = icmp eq i32 %m, 0
  br i1 %mc, label %g, label %qside

qside:
  %b2 = call zeroext i1 @cq_theta_i1(i1 false, double 7.500000e-01)
  %s2 = select i1 %b2, i32 7, i32 9
  br label %exit

g:
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
  %r = phi i32 [ %s2, %qside ], [ 5, %g ], [ %anext, %head ]
  %mm = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mm
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
