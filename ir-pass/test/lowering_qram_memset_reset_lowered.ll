; lowering_qram_memset_reset_lowered.ll — ACCEPT (bd test_C_libtooling-r2j3.15, P1
; silent miscompile on main 7b4e6359, quantum indices only). `clang -O1` of
;
;     int arr[8] = {0};
;     int p = argc; cq_theta(&p, .3);
;     arr[p & 7] = 7;
;     if (argc > 2) memset(arr, 0, sizeof arr);     // classical RESET of the array
;     int q = 0; cq_theta(&q, .5);  arr[q & 7] = 5;
;     int r = 1; cq_theta(&r, .7);  int v = arr[r & 7];
;     return cq_measure(v);
;
; `processShadowAlloca` sent EVERY zero-fill memset to the initializer erase list,
; wherever it sat: main emitted the guarded block EMPTY, so `arr[p & 7] = 7` survived
; the reset and `v` could read 7 where the source reads 0 or 5. Only a memset that
; runs before every access, and never again after one, is the `|0>` initializer
; `cqrt_qram_alloc_<W>` models (`provablyBefore`); any other full-cell zero-fill is a
; classical WRITE of 0 into each cell it covers, lowered as that many literal-index
; QRAM stores (`cqrt_qram_store_<W>_hl`, bd 01po.9) at the memset's own position.
;
; SEMANTIC EVIDENCE (hand trace). The entry memset precedes every access: erased, the
; array is born `|0>`. Cell (p&7) := 7. On the `argc > 2` path cells 0..7 := 0, each a
; QRAM write displacing the old value onto the backend's tape (the classical value 0
; materialized as a basis-state handle, the §2.5 `val` contract); on the other path
; nothing. Then cell (q&7) := 5 and v = copy of cell (r&7): the source's array on
; both paths. `main` reverses nothing.
;
; ⚠ NOW A DECLINE (bd test_C_libtooling-01po.25, batch 055; delegated ruling
; ruling-r2j3-7-qram-copyout-and-backedge-2026-10-16). Since bd r2j3.7 `main` runs
; the helper's dead-record discipline, and `emitCopyOutIfDirectMeasure` no longer
; skips `main`: the measured load is copied out and its local array's history is
; planned for reversal exactly as in a helper body — which declines here, on base
; and now, with the message below. No later move exists here, so base `main`'s leak was
; benign: this is a pure OVER-DECLINE inherited from the helper path (R1).
; RETIREMENT TRIGGER: bd test_C_libtooling-01po.27 (build the lowering); then
; restore the accept: rename every `ACC01PO25<prefix>` directive below back to
; `<prefix>`, restore its RUN lines from git (pre-01po.25), drop the DECL RUN.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DECL
; DECL: error{{.*}}in function main{{.*}}cq uncompute: dead chain spans divergent control-flow arms
;
; ACC01PO25DIAG-NOT: error
; ACC01PO25CHECK-LABEL: define i32 @main(
; ACC01PO25CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; ACC01PO25CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; ACC01PO25CHECK:      br i1 %{{[0-9]+}}, label %[[RESET:[0-9]+]], label %[[JOIN:[0-9]+]]
; ACC01PO25CHECK:      {{^}}[[RESET]]:
; ACC01PO25CHECK-NEXT: %[[Z0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; ACC01PO25CHECK-NEXT: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 0, i32 %[[Z0]])
; ACC01PO25CHECK-COUNT-6: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 {{[1-6]}}, i32
; ACC01PO25CHECK:      %[[Z7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; ACC01PO25CHECK-NEXT: call void @cqrt_qram_store_i32_hl(i32 %[[ARR]], i32 7, i32 %[[Z7]])
; ACC01PO25CHECK-NEXT: br label %[[JOIN]]
; ACC01PO25CHECK:      {{^}}[[JOIN]]:
; ACC01PO25CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; ACC01PO25CHECK:      call i32 @cqrt_qram_load_i32(i32 %[[ARR]],
; ACC01PO25NOMS-NOT: call void @llvm.memset

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %6
  store i32 7, ptr %7, align 4
  %8 = icmp sgt i32 %0, 2
  br i1 %8, label %9, label %10

9:                                                ; preds = %2
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  br label %10

10:                                               ; preds = %9, %2
  %11 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %12 = and i32 %11, 7
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %13
  store i32 5, ptr %14, align 4
  %15 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 0x3FE6666666666666)
  %16 = and i32 %15, 7
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %20
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
