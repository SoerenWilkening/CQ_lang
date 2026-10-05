; lowering_reject_qram_memset_reset_partial_cell.ll — DECLINE (bd
; test_C_libtooling-r2j3.15, the reset this lowering does not build). `clang -O1` of
;
;     int arr[8] = {0};
;     int q = argc; cq_theta(&q, .5);
;     arr[q & 7] = 5;
;     memset(arr, 0, 6);               // cell 0 and HALF of cell 1
;     int p = 1; cq_theta(&p, .7);  int v = arr[p & 7];
;
; A zero-fill after an access is lowered as whole-cell literal-index stores of 0; one
; that ends inside a cell (here), has a non-constant length, is volatile, runs in a
; loop or under tainted control is a shape that lowering does not cover. It is no
; longer erased as an initializer (bd r2j3.15: main erased it and lost the write), so
; it declines loudly with its own message (R1: a gap, not a design limit).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM store: alloca array is re-zeroed by a memset the QRAM model cannot lower

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %6
  store i32 5, ptr %7, align 4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(6) %3, i8 0, i64 6, i1 false)
  %8 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 0x3FE6666666666666)
  %9 = and i32 %8, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %13
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
