; R4b — CONTROL for R4: i32 seed 0 and a post-branch i32 value pinned to 0 on
; the TRUE edge (%1 == 1 => %1-1 == 0).  Predict DECLINE — F2's forward half
; bites at i32 too, so R4's accept is the TYPE filter and not F2 being inert.
define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %z = add nsw i32 %1, -1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %zm = tail call i32 @cq_measure_si32(i32 noundef %z)
  %11 = add nsw i32 %8, %9
  %12 = add nsw i32 %11, %zm
  ret i32 %12
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
