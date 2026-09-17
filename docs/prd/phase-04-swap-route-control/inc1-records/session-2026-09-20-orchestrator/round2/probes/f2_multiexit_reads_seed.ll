; f2: the same multi-exit loop, but the early exit is taken on trip 1, so the
; exit phi's `%a` incoming is the PROMOTED preheader handle itself.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %a = phi i32 [ 5, %entry ], [ %anext, %latch ]
  %early = icmp eq i32 %i, 0
  br i1 %early, label %exit, label %body

body:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %e = phi i32 [ %a, %head ], [ %anext, %latch ]
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
