; R5 — the same second compare, placed in the ENTRY block BEFORE the branch, so
; it dominates `BI` and is in the backward (LVI/Cand) half as well.
; Predict DECLINE — an exclusion must cover both positions, not just the merge.
define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %clone = icmp eq i32 %1, 1
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %cz = zext i1 %clone to i32
  %11 = add nsw i32 %8, %10
  %12 = add nsw i32 %11, %cz
  ret i32 %12
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
