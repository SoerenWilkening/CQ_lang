; lowering_reject_qram_classical_index_quantum_value.ll — DECLINE (bd
; test_C_libtooling-01po.9, the neighbour kept LOUD and NOT owned here: a QUANTUM
; value written at a CLASSICAL index of a QRAM-backed array). `clang -O1` of
;
;     arr[q & 7] = 5;                  // quantum-index store
;     arr[k & 7] = p;                  // quantum VALUE, classical index
;
; "A CLASSICAL index over quantum cells" is the rail-bank carve's domain (L-1a,
; TaintPropagation.cpp's `declineTaintEscapes` and `classicalCellAccess`'s own
; refusal), so the literal-index QRAM write takes a CLASSICAL value only and this
; store keeps the taint-escape decline it had on main 7b4e6359.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value stored to memory

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = add nsw i32 %0, 1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %7 = and i32 %4, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %8
  store i32 5, ptr %9, align 4
  %10 = and i32 %1, 7
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 %6, ptr %12, align 4
  %13 = add nsw i32 %1, 1
  %14 = and i32 %13, 7
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %15
  %17 = load i32, ptr %16, align 4
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17)
  %19 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %20 = add nsw i32 %19, %18
  %21 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %22 = add nsw i32 %20, %21
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %22
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = tail call i32 @f(i32 noundef %0, i32 noundef 3)
  ret i32 %3
}
