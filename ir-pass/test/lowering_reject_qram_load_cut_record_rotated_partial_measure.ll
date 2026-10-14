; lowering_reject_qram_load_cut_record_rotated_partial_measure.ll — DECLINE (bd
; test_C_libtooling-r2j3.23, batch 053 unit D, R11 round 1 finding A-F1, the QROM
; twin a4_qrom).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int qrom(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int a = tbl[k]; cq_theta(&a, 0.3);
;       int t = a * 5; cq_theta(&t, 0.4);
;       int acc = 0; if (s > 100) acc = cq_measure(a);
;       cq_theta(&k, -0.5); return acc + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return qrom(argc); }
;
; main and snapshot 3aa47cb3: rc 0, the rotated load record `a` of k left
; un-collapsed on s <= 100 before `cqrt_ry_i32(k, -0.5)` (the reader `t = a * 5` is
; reversed by the plan; the measurement covers one arm). NOW: not garbage on every
; path, not measured on every path to the move: LOUD at the load.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function qrom i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @qrom(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @qrom(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01) #3
  %8 = mul nsw i32 %7, 5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #3
  %10 = icmp sgt i32 %0, 100
  br i1 %10, label %11, label %13

11:
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  br label %13

13:
  %14 = phi i32 [ %12, %11 ], [ 0, %1 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  %17 = add nsw i32 %16, %14
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
