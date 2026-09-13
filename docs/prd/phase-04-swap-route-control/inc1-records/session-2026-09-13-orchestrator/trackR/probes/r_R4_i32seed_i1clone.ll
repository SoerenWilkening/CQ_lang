; R4 — the SAME clone, but the prep seed is i32 0.  The clone is i1, so the
; `V->getType() == Seed->getType()` test at ArmClassify.cpp:1616 cannot match.
; Predict ACCEPT — this is why the rb9x defect is specific to a _Bool prep.
define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %clone = icmp eq i32 %1, 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %cz = zext i1 %clone to i32
  %11 = add nsw i32 %8, %9
  %12 = add nsw i32 %11, %cz
  ret i32 %12
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
