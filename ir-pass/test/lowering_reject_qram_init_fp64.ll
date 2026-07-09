; lowering_reject_qram_init_fp64.ll — DECLINE (bd 38t2 Rule-13 clearance): the FP
; twin of lowering_reject_qram_nonzero_init.ll. 38t2 lifts the integer-only cell
; width gate, making fp the first NEW shape class to reach the alloca-wide guards
; (kMsgQramInit / kMsgQramMidSeq / kMsgQramCohEscape) that previously sat behind the
; blanket fp decline. The PRD names keeping these guards ordered BEFORE the fp emit a
; LOAD-BEARING IMPL INVARIANT — this fixture pins it at fp width: a non-zero
; `memset(arr, 0xAA, …)` into `[8 x double]` cannot be represented by the |0>-init
; trace model (a later load of an un-overwritten cell would silently read 0), so it
; must loud-decline, never emit.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare double @cq_measure_f64(double)

define double @nz_fp(i32 %u0, i32 %u1) {
entry:
  %a = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 -86, i64 64, i1 false)  ; 0xAA — non-zero fill
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x double], ptr %a, i64 0, i64 %ip
  store double 7.000000e+00, ptr %gp, align 8   ; overwrites ONE cell (arr[p])
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x double], ptr %a, i64 0, i64 %iq
  %v = load double, ptr %gq, align 8            ; reads an INITIALIZER cell (q != p)
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq QRAM store: alloca array has a non-zero initializer the trace model cannot represent
