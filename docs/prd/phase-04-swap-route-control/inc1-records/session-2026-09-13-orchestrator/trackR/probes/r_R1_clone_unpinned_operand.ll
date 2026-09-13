; R1 — the peel-clone shape with the clone's operand OFF the condition's wire.
; If the clone reaches F2's collider set as a USER of a PINNED value, an
; unpinned operand must make the decline vanish.  Predict ACCEPT.
define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %u = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %clone = icmp eq i32 %u, 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %um = tail call i32 @cq_measure_si32(i32 noundef %u)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %cz = zext i1 %clone to i32
  %11 = add nsw i32 %8, %10
  %12 = add nsw i32 %11, %cz
  %13 = add nsw i32 %12, %um
  ret i32 %13
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
