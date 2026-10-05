; lowering_qram_memset_reset_cell0.ll — ACCEPT (bd test_C_libtooling-r2j3.15; the
; review-round-1 repro on 336d7b12, which bd 01po.9 newly reached). `clang -O1` of
;
;     int arr[8] = {0};
;     arr[0] = 7;                                   // classical store (bare pointer)
;     if (argc > 2) memset(arr, 0, sizeof arr);     // classical reset
;     int q = 0; cq_theta(&q, .5);
;     arr[q & 7] = 5;
;     int v = arr[0];                               // classical read (bare pointer)
;     return cq_measure(v);
;
; MEASURED on 336d7b12: rc 0, the guarded block emitted empty, so cell 0 kept 7 on the
; `argc > 2` path and `v` read 7 whenever `q & 7 != 0`, where the source reads 0. The
; reset is now eight literal-index zero writes in its own block (see
; lowering_qram_memset_reset_lowered.ll for the rule).
;
; SEMANTIC EVIDENCE (hand trace). Born `|0>` (entry memset erased); cell 0 := 7; on
; `argc > 2`, cells 0..7 := 0; cell (q&7) := 5; v = copy of cell 0, i.e. 5 on the
; basis states with q&7 == 0 and else 7 (no reset) or 0 (reset), exactly the source.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[S7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 0, i32 %[[S7]])
; CHECK:      br i1 %{{[0-9]+}}, label %[[RESET:[0-9]+]], label %[[JOIN:[0-9]+]]
; CHECK:      {{^}}[[RESET]]:
; CHECK-COUNT-8: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 {{[0-7]}}, i32
; CHECK-NEXT: br label %[[JOIN]]
; CHECK:      {{^}}[[JOIN]]:
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; CHECK:      call i32 @cqrt_qram_load_i32_hl(i32 %[[ARR]], i32 0)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  store i32 7, ptr %3, align 16
  %4 = icmp sgt i32 %0, 2
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  br label %6

6:                                                ; preds = %5, %2
  %7 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %8 = and i32 %7, 7
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %9
  store i32 5, ptr %10, align 4
  %11 = load i32, ptr %3, align 16
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %12
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
