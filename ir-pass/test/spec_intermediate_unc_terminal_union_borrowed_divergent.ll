; spec_intermediate_unc_terminal_union_borrowed_divergent.ll — ACCEPT, a BENIGN cut
; left allocated (bd test_C_libtooling-p3kd.14, batch 053 unit D; formerly
; ..._reject_borrowed_divergent.ll, a decline equal to main — R11 r5, reviewer
; probe r4_tmplok_false_qram, @ml alone).
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int ml(int seed) {
;       int arr[8] = {0}; int q = seed; cq_theta(&q, 0.5); int p = seed + 1;
;       cq_theta(&p, 0.5); if (seed > 3) arr[q] = 7; int v = arr[p];
;       int w = (seed >> 3) & 7; cq_theta(&w, 0.3); int r = h(w); cq_theta(&r, 0.2);
;       int b = cq_measure(v); return b + cq_measure(w); }
;     int main(int argc, char **argv) { (void)argv; return ml(argc); }
;
; THE SHAPE. The template terminals alone decline (the conditional store at a
; superposed index sits in a divergent arm: main, rc 1), so `TmplOk` is false. The
; union is measured upstream through w; its frontier borrows the array, so the
; conditional store `arr[q] = 7` and q's prep Ry are CUT. R11 r5-r8 required a
; `!TmplOk` union to leave nothing cut, which split this group into main's decline
; — an over-decline, since q is never touched again (THE `Cut` CLAUSE IS COARSE,
; retired).
; NOW (bd p3kd.14, `neverWorse` asks the planner's `isHazardousCutRecord`): q's own
; Ry is a register root's gate (exempt) and the store is a cut record no later move
; reaches — a benign leak (Rule 5) — so the probe records no hazardous cut and the
; union is emitted: v's copy-out, r's twin, the load `_unc` and p's prep reverse-play
; (p frozen: recorded by the copy-out); the store and q are left allocated, never
; reversed, never freed. The hazardous twins (a store's index moved later) are
; spec_intermediate_unc_terminal_union_measured_store.ll and
; spec_intermediate_unc_terminal_union_clone_store.ll, both now reversing the store.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define internal fastcc i32 @ml(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[Q]],
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[P]])
; CHECK:      call void @cqrt_copy_i32(i32 %[[V]],
; CHECK:      call fastcc void @__cq_q_h_1_unc(
; CHECK:      call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double -5.000000e-01)
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK-NOT:  call void @cqrt_ry_i32(i32 %[[Q]]
; CHECK-NOT:  call void @cqrt_free(i32 %[[Q]])
; CHECK:      ret i32

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3
declare i32 @cq_theta_si32(i32 noundef, double noundef) #4
declare i32 @cq_measure_si32(i32 noundef) #4
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @ml(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @ml(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #7
  %4 = add nsw i32 %0, 1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 5.000000e-01) #7
  %6 = icmp sgt i32 %0, 3
  br i1 %6, label %7, label %10

7:
  %8 = sext i32 %3 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %8
  store i32 7, ptr %9, align 4
  br label %10

10:
  %11 = sext i32 %5 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = lshr i32 %0, 3
  %15 = and i32 %14, 7
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 3.000000e-01) #7
  %17 = tail call fastcc i32 @h(i32 noundef %16)
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 2.000000e-01) #7
  %19 = tail call i32 @cq_measure_si32(i32 noundef %13) #6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  %21 = add nsw i32 %20, %19
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %21
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
