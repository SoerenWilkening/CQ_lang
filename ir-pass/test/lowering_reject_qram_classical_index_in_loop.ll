; lowering_reject_qram_classical_index_in_loop.ll — DECLINE (bd
; test_C_libtooling-01po.9, the neighbour kept LOUD: classical-index accesses INSIDE A
; LOOP on a QRAM-backed array). `clang -O1` of
;
;     int arr[8] = {0};
;     for (int i = 0; i < n && i < 8; i++) arr[i] = i;   // classical stores in a loop
;     int q = x; cq_theta(&q, .5);
;     int v = arr[q & 7];                                  // quantum-index read
;
; A QRAM access in a loop is the 7.3 unroll's (`matchQramAccess`, and the carve's
; `cq QRAM access: tainted-index memory access inside a loop` for the quantum-index
; twin); a classical-index store in a loop is no different, and its per-iteration
; literal index is not built. The alloca-wide mixed-access decline stays.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM store: alloca array mixes a tainted-index and a classical access

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %10

5:                                                ; preds = %2
  %6 = add nsw i32 %1, -1
  %7 = tail call i32 @llvm.umin.i32(i32 %6, i32 7)
  %8 = add nuw nsw i32 %7, 1
  %9 = zext nneg i32 %8 to i64
  br label %19

10:                                               ; preds = %19, %2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %12 = and i32 %11, 7
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %13
  %15 = load i32, ptr %14, align 4
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15)
  %17 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %18 = add nsw i32 %17, %16
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %18

19:                                               ; preds = %5, %19
  %20 = phi i64 [ 0, %5 ], [ %23, %19 ]
  %21 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %20
  %22 = trunc nuw nsw i64 %20 to i32
  store i32 %22, ptr %21, align 4
  %23 = add nuw nsw i64 %20, 1
  %24 = icmp eq i64 %23, %9
  br i1 %24, label %10, label %19
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = add nsw i32 %0, 4
  %4 = tail call i32 @f(i32 noundef %0, i32 noundef %3)
  ret i32 %4
}

declare i32 @llvm.umin.i32(i32, i32)
