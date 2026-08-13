; lowering_qram_read_nested_index.ll — ACCEPT (bd gyc9, the Inc-1 twin of the
; Shadow index staleness): the nested const-global QROM read `tbl2[tbl1[q]]` —
; the inner read's result IS the outer read's gep index, directly (no widening
; cast). `lowerQramReads` captured `RawIndex` at classify time for ALL reads
; before emitting any; the inner read's RAUW then replaced every LIVE use of the
; original inner load, but the outer read's captured pointer bypassed the RAUW,
; so the outer `cqrt_qram_load` was minted referencing the original load — which
; the deferred erase then deleted (dangling operand → verifier UAF SIGSEGV,
; exactly the Shadow-side gyc9 crash). Fix: re-read the index from the LIVE
; gep's trailing operand at emit time. Both tables get their own array handle;
; the outer load's index is the INNER load's new handle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
@tbl1 = internal constant [4 x i32] [i32 0, i32 1, i32 2, i32 3]
@tbl2 = internal constant [4 x i32] [i32 7, i32 6, i32 5, i32 4]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @qromnested(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %g1 = getelementptr inbounds [4 x i32], ptr @tbl1, i32 0, i32 %q
  %i1 = load i32, ptr %g1, align 4
  %g2 = getelementptr inbounds [4 x i32], ptr @tbl2, i32 0, i32 %i1
  %i2 = load i32, ptr %g2, align 4
  %m = call i32 @cq_measure_si32(i32 %i2)
  ret i32 %m
}

; CHECK:     %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]],
; The outer read consumes the INNER read's new handle as its index (the
; fresh-read fix; a stale capture would reference the erased original load):
; CHECK:     %[[I1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[A1]], i32 %[[H]])
; CHECK:     %[[I2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[A2]], i32 %[[I1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[I2]])
; CHECK-NOT: cq QRAM access
