; lowering_reject_qram_pun_store_int.ll — DECLINE (bd 38t2 Rule-13 clearance): the
; INTEGER twin of the type-pun hole — `store i32` through an `[8 x i64]` gep. This
; over-accept PRE-DATES 38t2 (the integer width gate passed i64 and the accessed
; type was never checked): the pass emitted `cqrt_qram_store_i64(arr, idx, h)` where
; `h` is an i32 rail — a 64-bit cell write sourced from a 32-bit register. The 38t2
; pun fence (accessed type must BE the cell type in matchQramAccess) closes BOTH
; families with one check; the tainted store loud-declines at the taint-escape guard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_measure_si64(i64)

define i64 @pun_store_int(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i64], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %qi = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i64], ptr %arr, i64 0, i64 %qi
  store i32 %x, ptr %g, align 4                ; PUN: i32 store into an i64 cell
  %g2 = getelementptr inbounds [8 x i64], ptr %arr, i64 0, i64 1
  %v = load i64, ptr %g2, align 8
  %m = call i64 @cq_measure_si64(i64 %v)
  ret i64 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
