; lowering_reject_lift_stale_qram_store_value.ll — DECLINE (bd
; test_C_libtooling-r2j3.12's reader-family audit: the QRAM-store VALUE). `clang -O1`
; of
;
;     int r = q;
;     if (c) { cq_theta(&q, .125); r = q; cq_theta(&q, .25); }
;     arr[p & 7] = r;                  // QRAM store of the stale name r
;
; A QRAM access is asked by the post-lift pure-op re-sweep (`qramAccessReads`: its
; index and its stored value), under the per-use exemption since bd dm7f.1, so this
; already declined at the branch base; it is pinned here so the audit's verdict
; ("re-asked") has a fixture. Accept twin: lowering_lift_qram_store_value_accept.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01)
  %6 = icmp eq i32 %0, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.250000e-01)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.500000e-01)
  br label %10

10:                                               ; preds = %7, %2
  %11 = phi i32 [ %8, %7 ], [ %4, %2 ]
  %12 = phi i32 [ %9, %7 ], [ %4, %2 ]
  %13 = and i32 %5, 7
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %14
  store i32 %11, ptr %15, align 4
  %16 = add nsw i32 %5, 1
  %17 = and i32 %16, 7
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %12)
  %23 = add nsw i32 %22, %21
  %24 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %25 = add nsw i32 %23, %24
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %25
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
