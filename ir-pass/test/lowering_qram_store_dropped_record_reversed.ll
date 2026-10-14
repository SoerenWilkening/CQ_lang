; lowering_qram_store_dropped_record_reversed.ll — ACCEPT (bd
; test_C_libtooling-r2j3.21, batch 053 unit D; owner ruling
; owner-ruling-qram-dropped-store-2026-10-13). A QRAM store the bd 01po.4 array
; borrow CUT from a measured-upstream dead-terminal group is reversed EARLY, at the
; group's reversal point, because that point precedes the next non-diagonal gate on
; the store's index or value register.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int mlgk(int seed) {   /* the r2j3.21 repro */
;       int arr[8] = {0}; int k = seed & 7; cq_theta(&k, 0.5); arr[k] = 7;
;       int p = (seed >> 1) & 7; cq_theta(&p, 0.5); int v = arr[p];
;       int t = v * 5; cq_theta(&t, 0.4); int r = v * 3 + 1; cq_theta(&r, 0.2);
;       cq_theta(&k, -0.5); return cq_measure(p) + cq_measure(k); }
;     @computed   — the same with `k = seed & 3; arr[k + 1] = 7`, no `r`;
;     @value      — `arr[k] = w` with `w` rotated back (`cq_theta(&w, -0.5)`), no `r`;
;     @somepaths  — @computed's shape with `arr[k] = 7` and the move only
;                   `if (seed & 64)`;
;     @twostore   — `arr[k] = 7; arr[j] = 3;` and only `j` moved;
;     @unmeasured — @somepaths' shape with the move unconditional and `p` never
;                   measured (`return cq_measure(k)`).
;     int main(int argc, char **argv) { (void)argv; return mlgk(argc) + computed(argc)
;       + value(argc) + somepaths(argc) + twostore(argc) + unmeasured(argc); }
;
; WHAT main fc6ee653 EMITTED (cq-opt f4379f18, measured): every function rc 0 with
; `cqrt_qram_store_i32(arr, ·, ·)` NEVER reversed, then `cqrt_ry_i32` on the store's
; index (or value) register and a measurement of it. The terminals t (and r) read the
; MEASURED p, so the group is measured upstream; its 01po.4/ptue frontier retry
; borrows the array root and every measured rail, so the store, reachable from the
; terminals only through the array, is cut from the reversal. `arr[k] = 7` is a full
; record of k whose last reader (`v = arr[p]`) precedes k's next Ry: per bit
; P(flip) = sin²θ/2 ≈ 0.115 at θ = 0.5 where the source gives 0 (owner ruling
; 2026-10-05, dead-record-live-across-move).
;
; NOW (TerminalGroups.h, CUT RECORDS). The planner takes the CUT SET of its committed
; plans and asks `isHazardousCutRecord` of every cut store: here the index (value)
; register has a later non-permutation move the program does not keep the array
; across. So it retries with only the measured rails borrowed: the ARRAY IS WALKED,
; every store on it joins the reversal and is undone LIFO (`cqrt_qram_store_i32_unc`,
; same args, the runtime pops the old cell value) at the group's point — after the
; load's `_unc`, before the user's Ry. The measured index stays borrowed (never
; un-rotated, never freed), the classical `qval` handle is untouched (untainted), and
; the array is never freed. @computed's `add` index rail is reversed after the store
; `_unc` that reads it and freed; @twostore pops its two stores in reverse order;
; @unmeasured reverse-plays the dead `p` (frozen, never freed) between the load and
; the store `_unc`s, reverse program order.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=NOFREE < %t.ll
; NOERR-NOT: error

; CHECK-LABEL: define internal fastcc i32 @mlgk(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[K]], i32 %[[VAL]])
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[P]])
; CHECK:      call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[K]], i32 %[[VAL]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[P]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[K]])

; CHECK-LABEL: define internal fastcc i32 @computed(
; CHECK:      %[[ARR2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[IX2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[K2]], i32 1)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR2]], i32 %[[IX2]], i32 %[[VAL2:[a-zA-Z0-9_.]+]])
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR2]], i32 %[[IX2]], i32 %[[VAL2]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[IX2]], i32 %[[K2]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[IX2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K2]], double -5.000000e-01)

; CHECK-LABEL: define internal fastcc i32 @value(
; CHECK:      %[[ARR3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[W3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[K3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR3]], i32 %[[K3]], i32 %[[W3]])
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR3]], i32 %[[K3]], i32 %[[W3]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[W3]], double -5.000000e-01)

; CHECK-LABEL: define internal fastcc i32 @somepaths(
; CHECK:      %[[ARR4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR4]], i32 %[[K4]], i32 %[[VAL4:[a-zA-Z0-9_.]+]])
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR4]], i32 %[[K4]], i32 %[[VAL4]])
; CHECK-NOT:  call void @cqrt_ry_i32(i32 %[[K4]]
; CHECK:      br i1
; CHECK:      call void @cqrt_ry_i32(i32 %[[K4]], double -5.000000e-01)

; CHECK-LABEL: define internal fastcc i32 @twostore(
; CHECK:      %[[ARR5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[J5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR5]], i32 %[[K5]], i32 %[[VA5:[a-zA-Z0-9_.]+]])
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR5]], i32 %[[J5]], i32 %[[VB5:[a-zA-Z0-9_.]+]])
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR5]], i32 %[[J5]], i32 %[[VB5]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR5]], i32 %[[K5]], i32 %[[VA5]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[J5]], double -5.000000e-01)

; CHECK-LABEL: define internal fastcc i32 @unmeasured(
; CHECK:      %[[ARR6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR6]], i32 %[[K6]], i32 %[[VAL6:[a-zA-Z0-9_.]+]])
; CHECK:      %[[P6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      call void @cqrt_qram_load_i32_unc(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P6]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR6]], i32 %[[K6]], i32 %[[VAL6]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K6]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[K6]])

; No array handle, store value handle or measured index is ever freed: the only
; frees in this module are of template / load rails.
; NOFREE-NOT: call void @cqrt_free(i32 %arr
; NOFREE-NOT: call void @cqrt_free(i32 %qval
; NOFREE-NOT: call void @cqrt_free(i32 %h)
; NOFREE-NOT: call void @cqrt_free(i32 %h1)
; NOFREE-NOT: call void @cqrt_free(i32 %h2)


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @mlgk(i32 noundef %0)
  %4 = tail call fastcc i32 @computed(i32 noundef %0)
  %5 = add nsw i32 %4, %3
  %6 = tail call fastcc i32 @value(i32 noundef %0)
  %7 = add nsw i32 %5, %6
  %8 = tail call fastcc i32 @somepaths(i32 noundef %0)
  %9 = add nsw i32 %7, %8
  %10 = tail call fastcc i32 @twostore(i32 noundef %0)
  %11 = add nsw i32 %9, %10
  %12 = tail call fastcc i32 @unmeasured(i32 noundef %0)
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

define internal fastcc i32 @mlgk(i32 noundef %0) unnamed_addr #1 {
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
  %15 = mul nsw i32 %12, 3
  %16 = add nsw i32 %15, 1
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 2.000000e-01) #6
  %18 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %20 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  %21 = add nsw i32 %20, %19
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %21
}

define internal fastcc i32 @computed(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #6
  %5 = add nsw i32 %4, 1
  %6 = sext i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %6
  store i32 7, ptr %7, align 4
  %8 = lshr i32 %0, 1
  %9 = and i32 %8, 7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 5.000000e-01) #6
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = mul nsw i32 %13, 5
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 4.000000e-01) #6
  %16 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %18 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %19 = add nsw i32 %18, %17
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %19
}

define internal fastcc i32 @value(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #6
  %5 = lshr i32 %0, 3
  %6 = and i32 %5, 7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #6
  %8 = sext i32 %7 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %8
  store i32 %4, ptr %9, align 4
  %10 = lshr i32 %0, 1
  %11 = and i32 %10, 7
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 5.000000e-01) #6
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %13
  %15 = load i32, ptr %14, align 4
  %16 = mul nsw i32 %15, 5
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 4.000000e-01) #6
  %18 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  %20 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  %21 = add nsw i32 %20, %19
  %22 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %23 = add nsw i32 %21, %22
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %23
}

define internal fastcc i32 @somepaths(i32 noundef %0) unnamed_addr #1 {
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
  %15 = and i32 %0, 64
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %19, label %17

17:
  %18 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  br label %19

19:
  %20 = phi i32 [ %18, %17 ], [ %4, %1 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %22 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %23 = add nsw i32 %22, %21
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %23
}

define internal fastcc i32 @twostore(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #6
  %5 = lshr i32 %0, 4
  %6 = and i32 %5, 7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #6
  %8 = sext i32 %4 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %8
  store i32 7, ptr %9, align 4
  %10 = sext i32 %7 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %10
  store i32 3, ptr %11, align 4
  %12 = lshr i32 %0, 1
  %13 = and i32 %12, 7
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01) #6
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %15
  %17 = load i32, ptr %16, align 4
  %18 = mul nsw i32 %17, 5
  %19 = tail call i32 @cq_theta_si32(i32 noundef %18, double noundef 4.000000e-01) #6
  %20 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef -5.000000e-01) #6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %22 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %23 = add nsw i32 %22, %21
  %24 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %25 = add nsw i32 %23, %24
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #5
  ret i32 %25
}

define internal fastcc i32 @unmeasured(i32 noundef %0) unnamed_addr #1 {
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
  %15 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
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
