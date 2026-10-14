; lowering_reject_qram_store_dropped_record_used_after_move.ll — DECLINE (bd
; test_C_libtooling-r2j3.21, batch 053 unit D). The bd r2j3.21 repro with its
; terminal's last use moved AFTER the move of the store's index, so the group's
; reversal point no longer precedes it.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int used(int seed) {
;       int arr[8] = {0};
;       int k = seed & 7; cq_theta(&k, 0.5);
;       arr[k] = 7;
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5);
;       int v = arr[p];
;       int t = v * 5;
;       cq_theta(&k, -0.5);
;       cq_theta(&t, 0.4);
;       return cq_measure(p) + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return used(argc); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0 with one M-A `live derived record`
; warning, the store never reversed. The array's last reader (`v = arr[p]`) precedes
; k's move, so the store is a dead record of k there (owner ruling 2026-10-05).
;
; NOW: hazardous cut store; walking the array would place its `_unc` at the group's
; point, after `cqrt_ry_i32(t, 0.4)` and so after k's move, which k's window refuses:
; LOUD at the store. (Reversing the store right after the load, before the move, is
; the follow-up early-reversal schedule — the owner ruling's named gap.)
; RETIREMENT TRIGGER (L7): that schedule makes this an ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function used i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @used(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @used(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #6
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %5
  store i32 7, ptr %6, align 4
  %7 = lshr i32 %0, 1
  %8 = and i32 %7, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #6
  %10 = sext i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4
  %13 = mul nsw i32 %12, 5
  %14 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %15 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 4.000000e-01) #6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %17 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %18 = add nsw i32 %17, %16
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %18
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
