; A18 — TWO loop-carried handle variables in one loop.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
define i32 @f() {
entry:
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i32 [ 5, %entry ], [ %anext, %head ]
  %c = phi i32 [ 9, %entry ], [ %cnext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %add = add nsw i32 %c, 2
  %cnext = select i1 %b, i32 %add, i32 %c
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0
exit:
  %m = call i32 @cq_measure_si32(i32 %anext)
  %m2 = call i32 @cq_measure_si32(i32 %cnext)
  %s = add i32 %m, %m2
  ret i32 %s
}
!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
