; lowering_reject_qram_mid_seq_fp64.ll — DECLINE (bd 38t2 Rule-13 clearance): the FP
; twin of lowering_reject_qram_mid_seq.ll — a mid-sequence observation of an
; `[8 x double]` Shadow array (store, measured load, then ANOTHER store). 38t2 makes
; fp the first new shape class to reach this alloca-wide guard (previously masked by
; the blanket integer-only width gate); the PRD's load-bearing invariant requires it
; to keep firing BEFORE the fp emit. The measurement observes an INTERMEDIATE array
; state a later store-reversal would corrupt → loud decline, never a silent leak.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare double @cq_measure_f64(double)

define double @midseq_fp(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double 7.000000e+00, ptr %gq, align 8   ; store
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %ip
  %v = load double, ptr %gp, align 8
  %m = call double @cq_measure_f64(double %v)   ; mid-sequence OBSERVATION
  %ir = sext i32 %r to i64
  %gr = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %ir
  store double 9.000000e+00, ptr %gr, align 8   ; store AFTER the observation
  ret double %m
}

; CHECK: error{{.*}}cq QRAM store: array is observed before its last store
