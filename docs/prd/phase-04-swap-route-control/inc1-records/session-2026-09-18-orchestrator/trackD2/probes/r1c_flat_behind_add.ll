; R1-c — the ACYCLIC form of R1-b. Two sequential regions on ONE CSE'd compare;
; `%d = add %1, 3` is an M-C in-place candidate on the condition's rail, and
; `%post = cq_theta(%d, 0.1)` sits in the SHARED MERGE block, i.e. in region 2's gap
; and nowhere near a back edge. Runs at most once, so the bd `3d8q` stale-reader
; fence has no subject; behind an `add`, so `WireWalk`'s forward walk cannot see it.
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %d = add nsw i32 %1, 3
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %post = tail call i32 @cq_theta_si32(i32 noundef %d, double noundef 1.000000e-01) #2
  br i1 %3, label %8, label %10

8:                                                ; preds = %6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %6
  %11 = phi i32 [ %9, %8 ], [ %7, %6 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %post) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
