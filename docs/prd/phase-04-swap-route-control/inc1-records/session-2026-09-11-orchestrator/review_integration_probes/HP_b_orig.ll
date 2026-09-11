; Hand-peeled P2 with a CLONE of the compare feeding the select (what MergePhiPeel emits)
define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  %clone = add i32 0, 0 ; unused
  %sel = select i1 %2, i32 2, i32 5
  br i1 %2, label %3, label %5
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %8, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %sel)
  %13 = add nsw i32 %11, %12
  ret i32 %13
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
