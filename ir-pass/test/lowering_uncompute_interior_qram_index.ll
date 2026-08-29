; lowering_uncompute_interior_qram_index.ll — ACCEPT (M-B Increment 5a, bd
; test_C_libtooling-6uqc). THE QROM INDEX RAIL IS AN INTERIOR RAIL.
;
; `%h_op = and(%h, 3)` is the address the QROM read is performed at. Its ONLY
; consumer is the `cqrt_qram_load_i32`, which `ChainWalk::isInteriorConsumer`
; admits as a forward reassigning producer (it READS its operands and mints a
; fresh cell copy — there is no mutating slot). Once the load has run, the index
; is dead, and its own chain is a basis permutation of the borrowed source wire —
; so `and_unc(%h_op, %h, 3)` returns it to |0> and it frees. At HEAD (c36934a)
; it was minted and left standing for the rest of the program.
;
; THE ORDERING RISK THIS FIXTURE ALSO PINS. If the load rail `%h3` were ever a
; DEAD terminal, the whole-DAG spine would recover it, walk to `%h_op` as a
; PARENT, and emit `cqrt_qram_load_i32_unc(%h3, %arr, %h_op)` — which READS the
; index. Freeing the index here first would then be a use-after-free. It cannot
; happen: the dead-terminal groups run FIRST and record every rail they reversed,
; and `%h_op` in that scenario is one of them, so the interior partition skips it
; on the single-ownership test. Here the load rail is MEASURED, so no dead-terminal
; group exists and the index is the interior partition's alone.
;
; Contrast lowering_uncompute_interior_leak_qram_load.ll: the LOAD rail stays
; deferred; only the index moves.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@tbl = internal unnamed_addr constant [4 x i32] [i32 7, i32 11, i32 13, i32 17]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_qram_index(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = and i32 %q, 3
  %i = sext i32 %k to i64
  %g = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %i
  %v = load i32, ptr %g
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK-LABEL: define i32 @interior_qram_index(
; CHECK:      %[[ARR:.*]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[K:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[V:.*]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[K]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])
; the LOAD rail and the ARRAY handle are untouched (severance class 4, deferred)
; CHECK-NOT: cqrt_qram_load_i32_unc
; CHECK-NOT: call void @cqrt_free(i32 %[[V]])
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
