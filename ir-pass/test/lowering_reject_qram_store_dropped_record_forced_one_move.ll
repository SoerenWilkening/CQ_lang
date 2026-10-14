; lowering_reject_qram_store_dropped_record_forced_one_move.ll — DECLINE (bd
; test_C_libtooling-r2j3.21, batch 053 unit D, R11 round 2 finding F1, probe
; h1_forced_arm). The forced-record exemption must be asked per MOVE.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int f(int seed) {
;       int arr[8] = {0};
;       int k = seed & 7; cq_theta(&k, 0.5);
;       arr[k] = 7;
;       if (seed & 64) { cq_theta(&k, 0.7); return 100 * cq_measure(k); }
;       cq_theta(&k, -0.5);
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5);
;       int v = arr[p];
;       int t = v * 5; cq_theta(&t, 0.4);
;       return cq_measure(p) + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return f(argc); }
;
; main fc6ee653 and the round-1 snapshot f6e00154: rc 0. On the fall-through path
; the array is read after `cqrt_ry_i32(k, -0.5)`, so the store is kept across THAT
; move (bd 01po.8). The snapshot asked "forced" once per register and so also waived
; the arm's `cqrt_ry_i32(k, 0.7)`, where the array is never read again: there the
; store is a dead record of k (no store `_unc` precedes the arm's Ry).
; NOW: `recordLiveAcrossMove` is asked of each move (`OnlyMove`); the arm move is not
; forced, not preceded by a measurement of the array on every path, not garbage:
; hazardous; the array-walking retry cannot place a reversal before it: LOUD at the
; store. The no-arm twin (reviewer h1b) still lowers byte-identical to main.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function f i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @f(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @f(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #6
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %5
  store i32 7, ptr %6, align 4
  %7 = and i32 %0, 64
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %13, label %9

9:
  %10 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 0x3FE6666666666666) #6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %12 = mul nsw i32 %11, 100
  br label %26

13:
  %14 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %15 = lshr i32 %0, 1
  %16 = and i32 %15, 7
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 5.000000e-01) #6
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4
  %21 = mul nsw i32 %20, 5
  %22 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 4.000000e-01) #6
  %23 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %24 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %25 = add nsw i32 %24, %23
  br label %26

26:
  %27 = phi i32 [ %12, %9 ], [ %25, %13 ]
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %27
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }
