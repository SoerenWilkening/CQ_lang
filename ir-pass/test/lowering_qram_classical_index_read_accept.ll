; lowering_qram_classical_index_read_accept.ll — ACCEPT (bd test_C_libtooling-01po.9;
; a DECLINE->ACCEPT flip, main 7b4e6359 declined it with `cq QRAM store: alloca
; array mixes a tainted-index and a classical access`). `clang -O1` of
;
;     int f(int x, int k) {               // k classical
;       int arr[8] = {0};
;       int q = x; cq_theta(&q, .5);
;       arr[q & 7] = 5;                   // quantum-index store
;       int v = arr[k & 7];               // CLASSICAL-index read
;       return cq_measure(v) + cq_measure(q);
;     }
;
; After a quantum-index write the array's cells are quantum, so the read is a QRAM
; read at a LITERAL index (owner ruling 2026-10-05: `cqrt_qram_load_<W>_hl`; R13, no
; rail for `k`). `propagate` seeds the load as tainted (the rail-bank load seed's
; clause), which is what makes `cq_measure(v)` a quantum measurement.
;
; SEMANTIC EVIDENCE (hand trace of the stream below). arr = 8 |0> cells; q = Ry(.5)|x>;
; i = q & 7 (fresh rail); store 5 into cell i; i uncomputed against the unmoved q and
; freed (the store is not reversed: its index source q is measured). Then
; `load_hl(arr, k & 7)` copies cell k&7 out into a fresh rail: 5 on the basis states
; with (q & 7) == (k & 7), 0 elsewhere, which is the source's `v = arr[k & 7]`. The
; copy-out to a kept carrier, the load's `_hl_unc` against the preserved cell and the
; free are the existing measured-load discipline (bd sxuk); the carrier and q are
; measured. No `cqrt_alloc` reads `%1`: the index is never a rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      %[[K:[a-zA-Z0-9_.]+]] = trunc i64 %{{[0-9]+}} to i32
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32_hl(i32 %[[ARR]], i32 %[[K]])
; CHECK:      call void @cqrt_copy_i32(i32 %[[V]], i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_qram_load_i32_hl_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[K]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OUT]])
; NORAIL-NOT: call i32 @cqrt_alloc_i32(i32 %1)
; NORAIL-NOT: = load i32

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %6
  store i32 5, ptr %7, align 4
  %8 = and i32 %1, 7
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %14 = add nsw i32 %13, %12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %14
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
