; lowering_lift_qram_store_value_accept.ll — ACCEPT (bd test_C_libtooling-r2j3.12's
; reader-family audit; the accept twin of lowering_reject_lift_stale_qram_store_value.ll).
; `clang -O1` of
;
;     if (c) cq_theta(&q, .125);
;     arr[p & 7] = q;                  // QRAM store of the phi's own record
;
; Trace (by hand): h = alloc(7), Ry(.5); p rotated; [c] Ry(.125) on h; the store
; copies the register `q` names on each path into cell (p & 7); the index rail is
; uncomputed and freed; the read of cell (p+1)&7 is copied out and measured.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]])

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01)
  %6 = icmp eq i32 %0, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.250000e-01)
  br label %9

9:                                                ; preds = %7, %2
  %10 = phi i32 [ %8, %7 ], [ %4, %2 ]
  %11 = and i32 %5, 7
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %12
  store i32 %10, ptr %13, align 4
  %14 = add nsw i32 %5, 1
  %15 = and i32 %14, 7
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18)
  %20 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %21 = add nsw i32 %20, %19
  %22 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %23 = add nsw i32 %21, %22
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %23
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
