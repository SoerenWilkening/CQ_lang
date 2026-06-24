; lowering_qram_store_return_load.ll — ACCEPT (Phase 7.5, bug sxuk): the reported
; silent-miscompile shape — a LOCAL alloca array mutated by a tainted-index store,
; then a tainted-index load whose value is DIRECTLY RETURNED from a non-main
; function. The array pointer never escapes; only the loaded VALUE leaves.
;
; WITHOUT the fix the loaded value is the sole tainted data terminal, FreePoint
; classifies it Escaped (the `ret`), and the whole-DAG reversal — INCLUDING the
; array's STORES — is skipped (`InsertTerms.empty()` bail): the returned value is
; left entangled with the leaked LOCAL scratch array (dephasing for superposed
; cells). The fix copies the loaded value out to a kept carrier (`cqrt_alloc_i32(0)`
; + `cqrt_copy_i32`) that is returned, so the load+store chain uncomputes (method-B):
; `cqrt_qram_load_i32_unc` then `cqrt_qram_store_i32_unc`, the index rotation rails
; reverse-play and free, and the array handle is left allocated but CLEAN |0> (a
; classical resource, never freed, §2.9). The returned carrier is disentangled from
; the now-clean array. NO measurement is inserted (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define i32 @shadow_return_load(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)   ; zero-init
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4                ; arr[q] = 7  (classical value)
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  %v = load i32, ptr %gp, align 4              ; arr[p]  (tainted-index load)
  ret i32 %v                                   ; the loaded value escapes directly
}

; Forward: array handle, materialized store value, store, load:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IQ:[a-zA-Z0-9_.]+]], i32 %[[VAL]])
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IP:[a-zA-Z0-9_.]+]])
; sxuk method-B copy-out: copy the loaded value into a kept |0> carrier that is the
; one actually returned:
; CHECK:     %[[RET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[V]], i32 %[[RET]])
; The local array uncomputes (load + store reverse), array handle never freed:
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[IP]])
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[IQ]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
; The carrier — not the loaded value — is what is returned:
; CHECK:     ret i32 %[[RET]]
; CHECK-NOT: alloca
; CHECK-NOT: getelementptr
; CHECK-NOT: = load
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape
