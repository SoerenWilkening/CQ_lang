; lowering_reject_qram_classical_cell0_in_loop.ll — DECLINE (bd test_C_libtooling-01po.9;
; hand-built: the in-loop classical access that `matchQramAccess` does not already
; refuse). A store to the BARE array pointer (cell 0) inside a loop, on an array that
; also has a quantum-index read after the loop. `classicalCellAccess` refuses an
; in-loop access itself; for an address GEP `matchQramAccess`'s own loop gate would
; refuse it anyway (lowering_reject_qram_classical_index_in_loop.ll), so this module,
; whose cell-0 access has no GEP, is what pins that conjunct. The per-iteration
; literal-index store is not built (the 7.3 unroll's domain); the bare-pointer user
; keeps the emitter's escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM store: alloca array escapes to an unsupported user

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %x, i32 %n) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  store i32 %i, ptr %arr, align 16                ; classical store to cell 0, in a loop
  %i.next = add i32 %i, 1
  %c = icmp slt i32 %i.next, %n
  br i1 %c, label %loop, label %exit
exit:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %qi = and i32 %q, 7
  %qz = zext i32 %qi to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %qz
  %v = load i32, ptr %g, align 4                  ; quantum-index read
  %m = call i32 @cq_measure_si32(i32 %v)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %mq
  ret i32 %s
}
