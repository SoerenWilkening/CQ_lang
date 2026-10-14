; spec_intermediate_unc_terminal_union_clone_store.ll — ACCEPT, the store REVERSED
; (bd test_C_libtooling-p3kd.14 + r2j3.21, batch 053 unit D; formerly
; ..._reject_clone_store.ll, a decline equal to main — R11 r7, probe P2' of
; review/B7). Its retirement trigger (a) fired: the r2j3.21 fix lands.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int mcs(int s) {
;       int arr[8] = {0};
;       int k = s & 7; cq_theta(&k, 0.5);
;       arr[k] = 7;
;       int q = (s >> 3) & 7; cq_theta(&q, 0.5); int t2 = q * 5; cq_theta(&t2, 0.4);
;       int acc = 0;
;       if (s > 3) { int u = (s >> 2) & 7; cq_theta(&u, 0.3); int t1 = u * 3;
;                    cq_theta(&t1, 0.25); acc = s; }
;       int p = (s >> 1) & 7; cq_theta(&p, 0.35);
;       int v = arr[p];
;       int r = h(v); cq_theta(&r, 0.2);
;       cq_theta(&k, -0.5);
;       return acc + cq_measure(p) + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return mcs(argc) + mcs(argc + 4); }
;
; THE SHAPE. The template terminals {t2, t1} reach no store and decline on the
; divergent arm (`TmplOk` false; main rc 1). Only the CLONE terminal r reaches the
; store, through v = arr[p] -> arr -> arr[k] = 7, and r reads the MEASURED p, so the
; union is measured upstream; its frontier borrows the array (and p) and the
; fixpoint plans {t2, q}, {t1, u} and {r, v}, each at its own point. Round 7's
; template-only store clause emitted it with the store never reversed before
; `Ry(k, -0.5)` (rc 0, P(flip) ≈ 0.115 per bit); R11 r7-r8 then split it whenever
; anything was cut (main's decline).
; NOW. `arr[k] = 7` is a HAZARDOUS cut record (k is moved later), so the planner
; retries with only the measured rails borrowed: the array is WALKED and the {r, v}
; component reverses the store after the load's `_unc`, before the user's Ry; the
; retry's cut is clean and the union is emitted (bd p3kd.14's `neverWorse`). The
; benign form (k never moved again — R11 r6 probe P2) is
; spec_intermediate_unc_terminal_union_cut_benign.ll, where the store stays.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define internal fastcc i32 @mcs(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[K]], i32 %[[VAL:[a-zA-Z0-9_.]+]])
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[P:[a-zA-Z0-9_.]+]])
; CHECK:      call fastcc void @__cq_q_h_1_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[K]], i32 %[[VAL]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K]], double -5.000000e-01)
; CHECK-NOT:  call void @cqrt_free(i32 %[[K]])
; CHECK:      ret i32

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3
declare i32 @cq_theta_si32(i32 noundef, double noundef) #4
declare i32 @cq_measure_si32(i32 noundef) #4
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
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
  %29 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #7
  %30 = tail call i32 @cq_measure_si32(i32 noundef %23) #6
  %31 = add nsw i32 %30, %20
  %32 = tail call i32 @cq_measure_si32(i32 noundef %29) #6
  %33 = add nsw i32 %31, %32
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %33
}

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #5 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}
attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }
