; lowering_qram_classical_index_store_accept.ll — ACCEPT (bd test_C_libtooling-01po.9,
; the CLASSICAL-index STORE neighbour, before AND after the first quantum access; a
; DECLINE->ACCEPT flip, main 7b4e6359 declined it with `cq QRAM store: alloca array
; mixes a tainted-index and a classical access`). `clang -O1` of
;
;     int arr[8] = {0};
;     arr[k & 7] = 9;                  // classical store BEFORE any quantum access
;     int q = x; cq_theta(&q, .5);  int p = x + 1; cq_theta(&p, .5);
;     arr[q & 7] = 5;                  // quantum-index store
;     arr[(k + 1) & 7] = 4;            // classical store AFTER it
;     int v = arr[p & 7];              // quantum-index read
;
; A classical write into a quantum array is a QRAM write at a literal index
; (`cqrt_qram_store_<W>_hl`). Its classical VALUE is materialized as a basis-state
; handle exactly as the handle-index store does (the frozen §2.5 `val` contract);
; only the index is a literal. Program order is kept, so the first write lands before
; the quantum one and the second after it.
;
; SEMANTIC EVIDENCE (hand trace). arr = 8 |0> cells; cell (k&7) := 9; q, p rotated;
; i = q & 7, cell i := 5 (displacing whatever was there, on the backend's tape),
; i uncomputed and freed; cell ((k+1)&7) := 4; v = copy-out of cell (p & 7): exactly
; the source's array after its three writes. The stores are not reversed (their
; index sources are measured), as for an all-quantum-index array.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[K1:[a-zA-Z0-9_.]+]] = trunc i64 %{{[0-9]+}} to i32
; CHECK-NEXT: %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 9)
; CHECK-NEXT: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 %[[K1]], i32 %[[V1]])
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; CHECK:      %[[K2:[a-zA-Z0-9_.]+]] = trunc i64 %{{[0-9]+}} to i32
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 4)
; CHECK-NEXT: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 %[[K2]], i32 %[[V2]])
; CHECK:      call i32 @cqrt_qram_load_i32(i32 %[[ARR]],

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = and i32 %1, 7
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %5
  store i32 9, ptr %6, align 4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %8 = add nsw i32 %0, 1
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01)
  %10 = and i32 %7, 7
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 5, ptr %12, align 4
  %13 = add nsw i32 %1, 1
  %14 = and i32 %13, 7
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %15
  store i32 4, ptr %16, align 4
  %17 = and i32 %9, 7
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %23 = add nsw i32 %22, %21
  %24 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %25 = add nsw i32 %23, %24
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %25
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
