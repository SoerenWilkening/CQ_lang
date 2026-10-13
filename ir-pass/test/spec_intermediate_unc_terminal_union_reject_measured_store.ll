; spec_intermediate_unc_terminal_union_reject_measured_store.ll — DECLINE, as main,
; character for character (bd test_C_libtooling-p3kd.13, R11 review round 6, F1).
; Reviewer probe P5, @mlg alone.
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
; THE DEFECT THIS PINS (snapshot 408bf287, measured: rc 0). The template terminal t
; is itself measured upstream (p, k), so its first frontier had already BORROWED
; the array, and the r5 first-DAG test (`T.Walked ⊆ U.Walked`) passed vacuously for
; the store. Its own plan refuses on the open copy v (the clone call consumes it), so
; `TmplOk` was false and the union, closing v, was emitted: `cqrt_qram_store_i32`
; was never reversed, then `Ry(k, -0.5)` and a measure of k — per bit P(flip) =
; sin²θ/2 ≈ 0.115 where the source gives 0 (the dead-record-live-across-move
; ruling of 2026-10-05). Stage 2b was clean; two M-A `live derived record`
; warnings fired, neither naming the store. Main declines this function loudly.
; NOW (`neverWorse`): under `!TmplOk` the union must leave nothing cut
; (`GroupProbe::Cut` empty; R11 r7-r8 — r6 asked this of QRAM stores only, which the
; measured-rail half of the cut escaped: ..._reject_measured_rail_cut.ll). It
; borrows the array and cuts the store, so the group splits and the template
; terminal gets main's decline. The store-only-the-clone-reaches form is
; spec_intermediate_unc_terminal_union_reject_clone_store.ll.
; The all-template twin (@mlgk of the probe) is main's own planner and emits the
; same wrong stream at rc 0: that is bd r2j3.21, pre-existing, NOT fixed here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function mlg i32 (i32): cq uncompute: dead chain would free a measured register
; CHECK-NOT: internal invariant

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
