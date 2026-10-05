; lowering_qram_classical_index_constant_cells_accept.ll — ACCEPT (bd
; test_C_libtooling-01po.9, the CONSTANT-index spellings; main 7b4e6359 declined it
; with `cq QRAM store: alloca array escapes to an unsupported user`). `clang -O1` of
;
;     int arr[8] = {0};
;     int q = argc; cq_theta(&q, .5);
;     arr[q & 7] = 5;
;     int v = arr[1];      // getelementptr inbounds i8, ptr %arr, i64 4
;     int w = arr[0];      // the bare array pointer
;
; Both reads are QRAM reads at literal cells 1 and 0 (`cqrt_qram_load_i32_hl`): a
; constant byte offset that is a whole in-bounds cell, and the array pointer itself.
;
; SEMANTIC EVIDENCE (hand trace). cell (q & 7) := 5 under the quantum index; v and w
; copy cells 1 and 0 out (5 on the basis states with q & 7 == 1, resp. 0, else 0), as
; the source reads them; all three registers are measured (`main`: nothing reversed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32_hl(i32 %[[ARR]], i32 1)
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32_hl(i32 %[[ARR]], i32 0)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[W]])

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %6
  store i32 5, ptr %7, align 4
  %8 = getelementptr inbounds i8, ptr %3, i64 4
  %9 = load i32, ptr %8, align 4
  %10 = load i32, ptr %3, align 16
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %15 = add nsw i32 %13, %14
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %15
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
