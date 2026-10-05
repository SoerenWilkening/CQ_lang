; lowering_qram_mixed_access_static_read_accept.ll — ACCEPT (bd test_C_libtooling-01po.9;
; a DECLINE->ACCEPT flip of `lowering_reject_qram_mixed_access.ll`, Phase 7.5 Inc 2
; §6.6). An alloca mixing a tainted-index store `arr[q] = x` and a static-index read
; `arr[1]` (`getelementptr inbounds i8, ptr %arr, i64 4` after clang -O1).
;
; The decline's reason was the stub model: "it cannot keep a quantum array register
; and a classical pointer view of the same memory coherent". It no longer keeps a
; classical view: after the quantum write the read IS a QRAM read, at the literal cell
; 1 (owner ruling 2026-10-05, `cqrt_qram_load_<W>_hl`), its value a register seeded
; by `propagate`. A fully classical SEPARATE array is still never a candidate
; (lowering_qram_store_mixed_classical_separate.ll); the classical reads that stay
; declined are pinned by lowering_reject_qram_classical_read_before_quantum_write.ll
; and lowering_reject_qram_classical_index_in_loop.ll.
;
; SEMANTIC EVIDENCE (hand trace of the stream below; a non-main function, so the
; scratch array reverses). cell q := x (both registers); c = copy of cell 1 (x on the
; basis states with q == 1, else 0), the source's `arr[1]`; c is copied out to the
; measured carrier, then uncomputed against the preserved cell and freed; the store
; is popped (`store_unc`) and x, q are reverse-rotated, all in strict LIFO.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @mixed(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[Q:[a-zA-Z0-9_.]+]], i32 %[[X:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32_hl(i32 %[[ARR]], i32 1)
; CHECK:      call void @cqrt_copy_i32(i32 %[[C]], i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_qram_load_i32_hl_unc(i32 %[[C]], i32 %[[ARR]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[Q]], i32 %[[X]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OUT]])

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mixed(i32 %u0, i32 %ux) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = call i32 @cq_theta_si32(i32 %ux, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 %x, ptr %gq, align 4               ; tainted-index store
  %g1 = getelementptr inbounds i8, ptr %arr, i64 4   ; arr[1] — CLASSICAL-index access
  %c = load i32, ptr %g1, align 4
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}
