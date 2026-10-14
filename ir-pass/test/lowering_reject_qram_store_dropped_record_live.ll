; lowering_reject_qram_store_dropped_record_live.ll — DECLINE (bd
; test_C_libtooling-r2j3.21, batch 053 unit D; owner ruling
; owner-ruling-qram-dropped-store-2026-10-13, the P3 shape it names).
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int f(int seed) {
;       int arr[8] = {0};
;       int b = seed & 7; cq_theta(&b, 0.5);
;       arr[b] = 7;
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5);
;       int v = arr[p];
;       cq_theta(&b, -0.5);
;       return cq_measure(b) + cq_measure(v); }
;     int main(int argc, char **argv) { (void)argv; return f(argc); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0, NO warning, with
; `cqrt_qram_store_i32(arr, b, 7)` never reversed before `cqrt_ry_i32(b, -0.5)`: the
; measured `v` is copied out and its load reversed after the copy, so the group's
; reversal point lies AFTER b's move, and the array borrow (bd 01po.4) cut the store.
; The store is a dead record of b (`v` has taken its copy; the array is never read
; again), so b's Ry acts on a register entangled with garbage the source does not
; have (owner ruling 2026-10-05).
;
; NOW: the cut store is hazardous (TerminalGroups.h, CUT RECORDS); walking the array
; puts the store `_unc` at the group's point, after b's move, which the borrowed
; b's clause-(d) window refuses; so the planner fails LOUDLY at the store. The
; schedule that would compile it — `cqrt_qram_store_i32_unc` right after the load,
; before the move, keeping `v` — is the follow-up early-reversal gap the ruling names,
; not a physics decline.
; RETIREMENT TRIGGER (L7): when that early-reversal schedule lands, this module
; lowers with the store `_unc` between the load and `cqrt_ry_i32(b, -0.5)`; flip
; this file to that ACCEPT in the same reviewed change.
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
  %7 = lshr i32 %0, 1
  %8 = and i32 %7, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #6
  %10 = sext i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %15 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  %16 = add nsw i32 %15, %14
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %16
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
