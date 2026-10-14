; lowering_uncompute_cut_record_benign.ll — ACCEPT, the record LEFT ALLOCATED (bd
; test_C_libtooling-r2j3.21 / r2j3.23 / r2j3.24, batch 053 unit D). The
; must-not-over-decline pins of the cut-record hazard: a dead record the frontier
; retry cuts that NO later move reaches, or that the program itself keeps across the
; move, is not hazardous (TerminalGroups.h, `isHazardousCutRecord`), so the module
; lowers exactly as main fc6ee653 lowered it (measured byte-identical, cq-opt
; f4379f18).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int benign(int seed) {      /* R11 r6 P2 */
;       int arr[8] = {0}; int k = seed & 7; cq_theta(&k, 0.5); arr[k] = 7;
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5); int v = arr[p];
;       int t = v * 5; cq_theta(&t, 0.4); return cq_measure(p) + cq_measure(k); }
;     __attribute__((noinline)) static int forced(int seed) {      /* unit D p12 */
;       ... arr[k] = 7; cq_theta(&k, -0.5); int p = ...; int v = arr[p]; ... }
;     __attribute__((noinline)) static int qforced(int s) {
;       int k = s & 7; cq_theta(&k, 0.5); int a = tbl[k]; cq_theta(&k, -0.5);
;       int m = a >> 1; int v = m ^ 9; int t = v * 5; cq_theta(&t, 0.4);
;       int mm = cq_measure(m); return mm + cq_measure(k); }
;     __attribute__((noinline)) static int partial(int s) {        /* r2j3.24 `cmk`, no move */
;       int x = s & 7; cq_theta(&x, 0.5); int q = x * 3; int a = q + 2;
;       int t = a * 5; cq_theta(&t, 0.4); int r = a * 7; cq_theta(&r, 0.2);
;       int acc = 0; if (s > 100) acc = cq_measure(q); return acc + cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv;
;       return benign(argc) + forced(argc) + qforced(argc) + partial(argc); }
;
; @benign: the store `arr[k] = 7` is cut by the array borrow, but k is never moved
; again — a benign leak (Rule 5). @forced: k IS moved, but before the load, so the
; array is read after the move on every path to the reversal point: the program
; keeps the record across the move (`recordLiveAcrossMove`, bd 01po.8 — lyyf), and
; the store stays. @qforced: the same for a QROM load `a = tbl[k]` cut by the
; measured `m` (r2j3.23's class) — read by `a >> 1` after k's move, so forced; M-B
; leaves it too (its window holds the move). @partial: q is measured on SOME paths
; only, so its own gate is a cut record (r2j3.24), but nothing moves x afterwards.
; The hazardous twins are lowering_qram_store_dropped_record_reversed.ll (reversed),
; lowering_reject_qram_store_dropped_record_*.ll and
; lowering_reject_uncompute_partial_measure_cut_record.ll (loud); the GARBAGE
; exemption (a rotated record no schedule can clean: kept and warned, owner ruling
; 2026-10-03) is lowering_qram_load_cut_record_rotated_garbage.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error

; CHECK-LABEL: define internal fastcc i32 @benign(
; CHECK:      call void @cqrt_qram_store_i32(
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK:      ret i32

; CHECK-LABEL: define internal fastcc i32 @forced(
; CHECK:      %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K]], double -5.000000e-01)
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK:      ret i32

; CHECK-LABEL: define internal fastcc i32 @qforced(
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
; CHECK-NEXT: call i32 @cq_template_ashr_i32_hl(i32 %[[A]], i32 1)
; CHECK-NOT:  cqrt_qram_load_i32_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[A]])
; CHECK:      ret i32

; CHECK-LABEL: define internal fastcc i32 @partial(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:      call void @cq_template_add_i32_hl_unc(
; CHECK-NOT:  call void @cq_template_mul_i32_hl_unc(i32 %[[Q]]
; CHECK-NOT:  call void @cqrt_free(i32 %[[Q]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK:      ret i32


@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @benign(i32 noundef %0)
  %4 = tail call fastcc i32 @forced(i32 noundef %0)
  %5 = add nsw i32 %4, %3
  %6 = tail call fastcc i32 @qforced(i32 noundef %0)
  %7 = add nsw i32 %5, %6
  %8 = tail call fastcc i32 @partial(i32 noundef %0)
  %9 = add nsw i32 %7, %8
  ret i32 %9
}

define internal fastcc i32 @benign(i32 noundef %0) unnamed_addr #1 {
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
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 4.000000e-01) #6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %17 = add nsw i32 %16, %15
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %17
}

define internal fastcc i32 @forced(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #6
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %5
  store i32 7, ptr %6, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %8 = lshr i32 %0, 1
  %9 = and i32 %8, 7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 5.000000e-01) #6
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = mul nsw i32 %13, 5
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 4.000000e-01) #6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %17 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %18 = add nsw i32 %17, %16
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %18
}

define internal fastcc i32 @qforced(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #6
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #6
  %8 = ashr i32 %6, 1
  %9 = xor i32 %8, 9
  %10 = mul nsw i32 %9, 5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 4.000000e-01) #6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

define internal fastcc i32 @partial(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #6
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, 2
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #6
  %8 = mul nsw i32 %5, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #6
  %10 = icmp sgt i32 %0, 100
  br i1 %10, label %11, label %13

11:
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  br label %13

13:
  %14 = phi i32 [ %12, %11 ], [ 0, %1 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %16 = add nsw i32 %15, %14
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
