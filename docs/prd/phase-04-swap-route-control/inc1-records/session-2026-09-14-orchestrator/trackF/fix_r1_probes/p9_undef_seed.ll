
define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 undef, double noundef 5.000000e-01)
  %2 = select i1 %1, i32 2, i32 5
  br i1 %1, label %5, label %3

3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 undef, double noundef 5.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ undef, %0 ]
  %8 = select i1 %6, i32 -1, i32 %2
  %9 = icmp sgt i32 %8, 2
  br i1 %9, label %10, label %12

10:
  %11 = tail call zeroext i1 @cq_theta_i1(i1 undef, double noundef 5.000000e-01)
  br label %12

12:
  %13 = phi i1 [ %11, %10 ], [ false, %5 ]
  %m1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %m6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %m9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  %z1 = zext i1 %m1 to i32
  %z6 = zext i1 %m6 to i32
  %z9 = zext i1 %m9 to i32
  %a1 = add nsw i32 %z1, %z6
  %a2 = add nsw i32 %a1, %z9
  ret i32 %a2
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 zeroext)



