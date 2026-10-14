; spec_intermediate_unc_terminal_union_cut_benign.ll — ACCEPT, a BENIGN cut store
; left allocated (bd test_C_libtooling-p3kd.14, batch 053 unit D; R11 r6 probe P2,
; reconstructed as spec_intermediate_unc_terminal_union_clone_store.ll WITHOUT the
; move of k).
;
; SOURCE (`clang -O1` IR below): @mcs of spec_intermediate_unc_terminal_union_clone_store.ll
; without `cq_theta(&k, -0.5);`:
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int mcs(int s) {
;       int arr[8] = {0}; int k = s & 7; cq_theta(&k, 0.5); arr[k] = 7;
;       int q = (s >> 3) & 7; cq_theta(&q, 0.5); int t2 = q * 5; cq_theta(&t2, 0.4);
;       int acc = 0;
;       if (s > 3) { int u = (s >> 2) & 7; cq_theta(&u, 0.3); int t1 = u * 3;
;                    cq_theta(&t1, 0.25); acc = s; }
;       int p = (s >> 1) & 7; cq_theta(&p, 0.35); int v = arr[p];
;       int r = h(v); cq_theta(&r, 0.2);
;       return acc + cq_measure(p) + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return mcs(argc) + mcs(argc + 4); }
;
; main fc6ee653 (cq-opt f4379f18): rc 1, `dead chain spans divergent control-flow
; arms` — the template terminals' own plan, after R11 r7-r8 split every `!TmplOk`
; union that left anything cut (THE `Cut` CLAUSE IS COARSE). Here the only cut
; record is `arr[k] = 7`, and k is never touched again: a benign leak (Rule 5).
; NOW (bd p3kd.14): `neverWorse` asks the planner's `isHazardousCutRecord`, which
; finds no later move, so the union is emitted; the store stays, never reversed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define internal fastcc i32 @mcs(
; CHECK:      call void @cqrt_qram_store_i32(
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(
; CHECK:      call fastcc void @__cq_q_h_1_unc(
; CHECK:      call void @cqrt_qram_load_i32_unc(i32 %[[V]],
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK:      ret i32


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @mcs(i32 noundef %0)
  %4 = add nsw i32 %0, 4
  %5 = tail call fastcc i32 @mcs(i32 noundef %4)
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

define internal fastcc i32 @mcs(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #7
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %5
  store i32 7, ptr %6, align 4
  %7 = lshr i32 %0, 3
  %8 = and i32 %7, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #7
  %10 = mul nsw i32 %9, 5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 4.000000e-01) #7
  %12 = icmp sgt i32 %0, 3
  br i1 %12, label %13, label %19

13:
  %14 = lshr i32 %0, 2
  %15 = and i32 %14, 7
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 3.000000e-01) #7
  %17 = mul nsw i32 %16, 3
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 2.500000e-01) #7
  br label %19

19:
  %20 = phi i32 [ %0, %13 ], [ 0, %1 ]
  %21 = lshr i32 %0, 1
  %22 = and i32 %21, 7
  %23 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 3.500000e-01) #7
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %24
  %26 = load i32, ptr %25, align 4
  %27 = tail call fastcc i32 @h(i32 noundef %26)
  %28 = tail call i32 @cq_theta_si32(i32 noundef %27, double noundef 2.000000e-01) #7
  %29 = tail call i32 @cq_measure_si32(i32 noundef %23) #6
  %30 = add nsw i32 %29, %20
  %31 = tail call i32 @cq_measure_si32(i32 noundef %4) #6
  %32 = add nsw i32 %30, %31
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %32
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #5 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }
