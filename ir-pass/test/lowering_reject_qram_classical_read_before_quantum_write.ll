; lowering_reject_qram_classical_read_before_quantum_write.ll — DECLINE (bd
; test_C_libtooling-01po.9, the neighbour kept LOUD: a classical-index READ that no
; quantum write can reach). `clang -O1` of
;
;     int arr[8] = {0};
;     int q = x; cq_theta(&q, .5);
;     int w = arr[k & 7];              // classical read BEFORE the quantum store
;     arr[q & 7] = 5;
;     int v = arr[(k + 1) & 7];
;     return cq_measure(v) + cq_measure(q) + w;   // w used classically
;
; `w` reads cells no quantum write has touched on any path into it, so in the source
; it is a classical value. Lowering it as a QRAM read would make it a register and
; turn the program's classical use of it into a quantum one (MEASURED on a binary that
; seeded every classical read: `cq taint escape: quantum value returned across a
; function boundary`). Keeping it classical needs the classical memory kept beside the
; QRAM array, which is not built; until then the read is the loud mixed-access
; decline (R1: a gap, not a design limit). The read after the store lowers
; (lowering_qram_classical_index_read_accept.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM store: alloca array mixes a tainted-index and a classical access

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = and i32 %1, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %6
  %8 = load i32, ptr %7, align 4
  %9 = and i32 %4, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %10
  store i32 5, ptr %11, align 4
  %12 = add nsw i32 %1, 1
  %13 = and i32 %12, 7
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %19 = add i32 %17, %8
  %20 = add i32 %19, %18
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %20
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
