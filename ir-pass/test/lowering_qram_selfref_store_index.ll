; lowering_qram_selfref_store_index.ll — ACCEPT (bd gyc9): the straight-line
; SELF-REFERENTIAL store/load web `arr[q]=q; v0=arr[q]; arr[v0]=v0; v1=arr[q]` —
; a tainted-index load whose result feeds a later access's INDEX (not just its
; stored value) directly, with no widening sext/zext in between. Inc 2 captured
; `RawIndex` at classify time; the load access then RAUW'd its original load to
; the new `cqrt_qram_load` and queued the original for erase, so the new store
; was minted referencing the STALE original-load pointer — a dangling operand
; (verifier "Call parameter type does not match function signature" + SIGSEGV
; printing the erased value). The 7z9k.3 fix re-read only the store's VALUE
; operand fresh; this is its INDEX twin: re-read the index from the LIVE gep's
; trailing operand at emit time, so the new store consumes the NEW load as BOTH
; index and value. A widening cast between load and gep masks the bug (the cast
; stays live and RAUW fixes it up), so the direct-index form is the pin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @shstraight(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %arr = alloca [4 x i32], align 16
  %sgep0 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %q
  store i32 %q, ptr %sgep0, align 4
  %lgep0 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %q
  %v0 = load i32, ptr %lgep0, align 4
  %sgep1 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %v0
  store i32 %v0, ptr %sgep1, align 4
  %lgep1 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %q
  %v1 = load i32, ptr %lgep1, align 4
  %m = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]],
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[H]], i32 %[[H]])
; The first load's NEW handle is what the second store consumes — as BOTH the
; index and the value (the fresh-read fix; a stale capture would reference the
; erased original load):
; CHECK:     %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[H]])
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[V0]], i32 %[[V0]])
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[H]])
; The measured value rides the sxuk direct-measure copy-out carrier, and the
; dead array's whole DAG reverses in strict LIFO — store1's reversal consumes
; the SAME (still-live) V0 handle for index and value:
; CHECK:     call void @cqrt_copy_i32(i32 %[[V1]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V1]], i32 %[[ARR]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[V1]])
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[V0]], i32 %[[V0]])
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V0]], i32 %[[ARR]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[V0]])
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[H]], i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: cq QRAM access

; DISTINCT-form pin (Rule-13 board note): in @shstraight the reused-web store is
; degenerate (idx == val == V0), so it alone cannot prove the INDEX slot was
; fresh-read — a mutation resolving the index from the (fresh-read) VALUE operand
; would emit the same call. Here the index is the RAUW'd load and the value is
; the theta handle, so the emitted store pins idx=V0 and val=H independently.
define i32 @shdistinct(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %arr = alloca [4 x i32], align 16
  %sgep0 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %q
  store i32 %q, ptr %sgep0, align 4
  %lgep0 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %q
  %v0 = load i32, ptr %lgep0, align 4
  %sgep1 = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %v0
  store i32 %q, ptr %sgep1, align 4
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @shdistinct(
; CHECK:     %[[ARR2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR2]], i32 %[[H2]], i32 %[[H2]])
; CHECK:     %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR2]], i32 %[[H2]])
; The index is the NEW load handle while the value is the DISTINCT theta handle:
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR2]], i32 %[[V2]], i32 %[[H2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NOT: cq QRAM access
