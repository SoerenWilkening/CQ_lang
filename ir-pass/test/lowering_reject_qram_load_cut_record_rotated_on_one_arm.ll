; lowering_reject_qram_load_cut_record_rotated_on_one_arm.ll — DECLINE (bd
; test_C_libtooling-r2j3.23, batch 053 unit D, R11 round 1 finding C-F2).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int armrot(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int a = tbl[k]; int m = a >> 1;
;       int t = m * 5; cq_theta(&t, 0.4);
;       int res = cq_measure(m);
;       if (s > 100) { cq_theta(&a, 0.3); return res + (int)cq_measure((unsigned)(a >> 2)); }
;       cq_theta(&k, -0.5); return res + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return armrot(argc); }
;
; main and snapshot 3aa47cb3: rc 0. The snapshot's garbage test asked whether a
; reader of `a` is merely REACHABLE after a's Ry (`isPotentiallyReachable`, a "may"
; test): on s > 100 it is, but k's move is on the s <= 100 path, where `a` (a dead
; load record of k) is neither rotated nor read, so it dephases k. NOW: the rotation
; must dominate the move and a kept reader must lie on every path between them;
; neither holds: LOUD at the load.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function armrot i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @armrot(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @armrot(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = ashr i32 %6, 1
  %8 = mul nsw i32 %7, 5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  %11 = icmp sgt i32 %0, 100
  br i1 %11, label %12, label %16

12:
  %13 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01) #3
  %14 = ashr i32 %13, 2
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #4
  br label %19

16:
  %17 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  br label %19

19:
  %20 = phi i32 [ %15, %12 ], [ %18, %16 ]
  %21 = add nsw i32 %20, %10
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
