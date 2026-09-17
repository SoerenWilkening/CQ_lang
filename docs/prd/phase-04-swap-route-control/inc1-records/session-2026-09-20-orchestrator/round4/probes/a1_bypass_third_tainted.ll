; a1 — PROBE: the guarded loop's EXIT phi carries a THIRD incoming that is a
; DIFFERENT tainted register.  `loopCarriedHandlePhi`'s bypass walk SKIPS every
; tainted incoming with no proof at all, yet the promotion inserts the whole phi
; into `taint.PromotedCarriedHandlePhis`, which `declineClassicalMuxes` accepts.
; Base file: ir-pass/test/loop_carried_handle_accept_guarded.ll (ONE edit: the
; extra %qside predecessor).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %n, i32 %m) {
entry:
  %mc = icmp eq i32 %m, 0
  br i1 %mc, label %g, label %qside

qside:
  %qh = call i32 @cq_theta_si32(i32 9, double 2.500000e-01)
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
  %r = phi i32 [ %qh, %qside ], [ 5, %g ], [ %anext, %head ]
  %mm = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mm
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
