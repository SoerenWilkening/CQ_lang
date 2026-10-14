; spec_intermediate_unc_terminal_union_measured_store.ll — ACCEPT, the store
; REVERSED (bd test_C_libtooling-p3kd.14 + r2j3.21, batch 053 unit D; formerly
; ..._reject_measured_store.ll, a decline equal to main — R11 r6 F1, reviewer probe
; P5, @mlg alone). Its retirement trigger (a) fired: the r2j3.21 fix lands.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int mlg(int seed) {
;       int arr[8] = {0}; int k = seed & 7; cq_theta(&k, 0.5); arr[k] = 7;
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5); int v = arr[p];
;       int t = v * 5; cq_theta(&t, 0.4); int r = h(v); cq_theta(&r, 0.2);
;       cq_theta(&k, -0.5); return cq_measure(p) + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return mlg(argc); }
;
; HISTORY. Snapshot 408bf287 emitted the union at rc 0 with the store never
; reversed before `Ry(k, -0.5)` (per bit P(flip) ≈ 0.115, the source 0); R11 r6-r8
; then required the union to leave NOTHING cut, so the group split and the template
; terminal got main's decline (`dead chain would free a measured register`, its
; own plan refusing on the open copy v the clone call consumes).
; NOW. The union's frontier borrows the array and cuts `arr[k] = 7`, a HAZARDOUS cut
; record (k is moved later; TerminalGroups.h, CUT RECORDS), so the planner retries
; with only the measured rails borrowed: the ARRAY IS WALKED and the store joins the
; union's reversal, LIFO at its point — after the load's `_unc`, before the user's
; Ry. The retry's cut is clean, the probe records no hazardous cut (`neverWorse`,
; bd p3kd.14), and the union is emitted Silent: r's twin, t's Ry/`mul_unc`, the
; load, the store. The all-template twin is @mlgk of
; lowering_qram_store_dropped_record_reversed.ll (main's own planner, same stream
; up to the twin).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define internal fastcc i32 @mlg(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[K]], i32 %[[VAL:[a-zA-Z0-9_.]+]])
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[P]])
; CHECK:      call fastcc void @__cq_q_h_1_unc(
; CHECK:      call void @cq_template_mul_i32_hl_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[K]], i32 %[[VAL]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K]], double -5.000000e-01)
; CHECK-NOT:  call void @cqrt_free(i32 %[[K]])
; CHECK-NOT:  call void @cqrt_free(i32 %[[ARR]])
; CHECK:      ret i32

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3
declare i32 @cq_theta_si32(i32 noundef, double noundef) #4
declare i32 @cq_measure_si32(i32 noundef) #4
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @mlg(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @mlg(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #7
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %5
  store i32 7, ptr %6, align 4
  %7 = lshr i32 %0, 1
  %8 = and i32 %7, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #7
  %10 = sext i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4
  %13 = mul nsw i32 %12, 5
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 4.000000e-01) #7
  %15 = tail call fastcc i32 @h(i32 noundef %12)
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 2.000000e-01) #7
  %17 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #7
  %18 = tail call i32 @cq_measure_si32(i32 noundef %9) #6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17) #6
  %20 = add nsw i32 %19, %18
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %20
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
