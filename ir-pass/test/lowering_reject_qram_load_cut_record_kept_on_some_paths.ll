; lowering_reject_qram_load_cut_record_kept_on_some_paths.ll — DECLINE (bd
; test_C_libtooling-r2j3.23, batch 053 unit D, R11 round 2 finding F2, probe
; h2b_condkept2). The GARBAGE exemption's kept reader must be kept on EVERY path to
; the move.
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int pred(int s) { return (s * 7) % 13 == 3; }
;     __attribute__((noinline)) static int g(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int a = tbl[k]; cq_theta(&a, 0.3);
;       int m = a >> 1;
;       int t = a * 5; cq_theta(&t, 0.4);
;       int acc = 0; if (s > 100 || pred(s)) acc = cq_measure(a) + cq_measure(m);
;       cq_theta(&k, -0.5);
;       return acc + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return g(argc); }
;
; main fc6ee653 and the round-1 snapshot f6e00154: rc 0. The rotated load record `a`
; of k is read by `m = a >> 1`, and the snapshot counted that reader as KEPT because
; m has a measurement somewhere — but it is measured on the `s > 100 || pred(s)`
; paths only, so on the others `a` and m stay un-collapsed dead records of k across
; `cqrt_ry_i32(k, -0.5)`.
; NOW: a reader's rail is kept across the move only if it is used after the move,
; or a measurement of it lies on EVERY path from the reader to the move; neither
; holds, and no measurement of `a` covers every path to the move: hazardous,
; unreversed, LOUD at the load.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function g i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @g(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @g(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01) #4
  %8 = ashr i32 %7, 1
  %9 = mul nsw i32 %7, 5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 4.000000e-01) #4
  %11 = icmp sgt i32 %0, 100
  br i1 %11, label %15, label %12

12:
  %13 = tail call fastcc i32 @pred(i32 noundef %0)
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %19, label %15

15:
  %16 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %17 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %18 = add nsw i32 %17, %16
  br label %19

19:
  %20 = phi i32 [ %18, %15 ], [ 0, %12 ]
  %21 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #4
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #5
  %23 = add nsw i32 %22, %20
  ret i32 %23
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

define internal fastcc range(i32 0, 2) i32 @pred(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, 7
  %3 = srem i32 %2, 13
  %4 = icmp eq i32 %3, 3
  %5 = zext i1 %4 to i32
  ret i32 %5
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
