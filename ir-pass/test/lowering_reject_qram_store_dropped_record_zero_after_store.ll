; lowering_reject_qram_store_dropped_record_zero_after_store.ll — DECLINE (bd
; test_C_libtooling-r2j3.21, batch 053 unit D). The IDENTITY-STORE exemption's E3
; refuses: a store of 0 is no record only if every cell already holds 0, and here an
; earlier store wrote 7.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int f(_Bool u0, _Bool u1, _Bool u2) {
;       int arr[8] = {0};
;       _Bool j = u2; cq_theta(&j, 0.5);
;       arr[j] = 7;
;       _Bool b = u0; cq_theta(&b, 0.5);
;       arr[b] = 0;
;       _Bool p = u1; cq_theta(&p, 0.5);
;       int v = arr[p];
;       cq_theta(&b, -0.5);
;       return cq_measure(b) + cq_measure(v) + cq_measure(j); }
;     int main(int argc, char **argv) { (void)argv;
;       return f(argc > 1, argc > 2, argc > 3); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0, silent, with both stores never
; reversed before `cqrt_ry_i1(b, -0.5)`. `arr[b] = 0` overwrites the 7 when b == j,
; so the runtime tape holds 7 or 0 depending on b: a record of b (with j), dead once
; `v` has its copy.
;
; NOW: the zero store is NOT an identity store (TerminalGroups.h: E3 — the earlier
; `arr[j] = 7` can reach it and writes non-zero), so it is a hazardous cut record;
; the array-walking retry places its `_unc` after b's move (the measured v's copy-out
; is the group's point), which b's window refuses: LOUD at a store. Contrast
; lowering_qram_store_measured_index_nonmain.ll, where 0 is stored into a fresh
; array and the exemption keeps the accept unchanged.
; RETIREMENT TRIGGER (L7): the early-reversal schedule (follow-up of the ruling)
; makes this an ACCEPT with both store `_unc`s before the move.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function f i32 (i1, i1, i1): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %0, 1
  %4 = icmp sgt i32 %0, 2
  %5 = icmp sgt i32 %0, 3
  %6 = tail call fastcc i32 @f(i1 noundef zeroext %3, i1 noundef zeroext %4, i1 noundef zeroext %5)
  ret i32 %6
}

define internal fastcc i32 @f(i1 noundef zeroext %0, i1 noundef zeroext %1, i1 noundef zeroext %2) unnamed_addr #1 {
  %4 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %4, i8 0, i64 32, i1 false)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 5.000000e-01) #6
  %6 = zext i1 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %6
  store i32 7, ptr %7, align 4
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef 5.000000e-01) #6
  %9 = zext i1 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %9
  store i32 0, ptr %10, align 4
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 5.000000e-01) #6
  %12 = zext i1 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef -5.000000e-01) #6
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #5
  %17 = zext i1 %16 to i32
  %18 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %19 = add nsw i32 %18, %17
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #5
  %21 = zext i1 %20 to i32
  %22 = add nsw i32 %19, %21
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #5
  ret i32 %22
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }
