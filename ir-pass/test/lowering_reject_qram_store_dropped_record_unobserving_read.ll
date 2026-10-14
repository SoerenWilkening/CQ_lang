; lowering_reject_qram_store_dropped_record_unobserving_read.ll — DECLINE (bd
; test_C_libtooling-r2j3.21, batch 053 unit D, R11 round 1 finding A-F2, probe
; a3_boolidx).
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int boolidx(int seed) {
;       int arr[8] = {0};
;       _Bool b = seed & 1; cq_theta(&b, 0.5);
;       arr[b] = 7;
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5);
;       int v = arr[p];
;       int t = v * 5;
;       cq_theta(&b, -0.5);
;       int w = arr[5];
;       cq_theta(&t, 0.4);
;       return cq_measure(p) + cq_measure(b) + cq_measure(w); }
;     int main(int argc, char **argv) { (void)argv; return boolidx(argc); }
;
; main and snapshot 3aa47cb3: rc 0. Without `int w = arr[5];` the snapshot is loud
; (lowering_reject_qram_store_dropped_record_used_after_move.ll's shape). With it,
; the forced-record test counted ANY later user of the array as keeping the store's
; record across b's move — but `arr[5]` can never read a cell `arr[b]` wrote (b is
; one bit), so the store is still a dead record of b there. NOW: a store record is
; kept only by a later read that may observe a written cell (`mayObserveStore`,
; TerminalGroups.h); a literal index above a one-bit index's range does not: LOUD
; at the store. A quantum-index later read may alias and still keeps it
; (@forced of lowering_uncompute_cut_record_benign.ll stays accepted).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function boolidx i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @boolidx(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @boolidx(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 1
  %4 = icmp ne i32 %3, 0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 5.000000e-01) #6
  %6 = zext i1 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %6
  store i32 7, ptr %7, align 4
  %8 = lshr i32 %0, 1
  %9 = and i32 %8, 7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 5.000000e-01) #6
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = mul nsw i32 %13, 5
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef -5.000000e-01) #6
  %16 = getelementptr inbounds i8, ptr %2, i64 20
  %17 = load i32, ptr %16, align 4
  %18 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 4.000000e-01) #6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #5
  %21 = zext i1 %20 to i32
  %22 = add nsw i32 %19, %21
  %23 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %24 = add nsw i32 %22, %23
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %24
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #4

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }
