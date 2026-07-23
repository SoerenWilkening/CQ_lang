; spec_reject_qrom_read_arm_nonpow2.ll — DECLINE mirror of
; spec_accept_qrom_read_arm_coherent_escape.ll (bd 20xt.5.2). IDENTICAL shape — a
; const-global tainted-index QROM read in a tainted diamond arm of a spec-clone,
; value coherently escaping to the clone ret — EXCEPT the table is `[3 x double]`
; (NON power-of-two) and the region-internal phi-index is not known-bits provable.
;
; The `inBennettClone` coherent-escape bypass removes ONLY the no-cloning reason,
; NOT the OOB/bounds safety: `classifyQromReadUnderControl` still returns `No` (a
; non-pow2 table cannot admit the `and idx, N-1` mask, and the index is not
; provably in-bounds), so the clone's PredMux `ClaimAll` flatten LEAVES at its
; E4-gep gate and `lowerCloneControl` LOUD-declines. A silent OOB `cqrt_qram_load`
; on the excluded basis states (out-of-contract for the frozen QROM ABI: idx ∈
; [0,N)) is thus NEVER emitted — the blocker-c OOB discipline is intact under the
; bypass (this is the Rule-13 "bypass didn't weaken bounds" probe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK:     error{{.*}}callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_qram_load_f64

@tbl3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @lookup3(double %x) {
entry:
  %c1 = fcmp ogt double %x, 1.000000e+00
  br i1 %c1, label %inner, label %base
inner:
  %c2 = fcmp olt double %x, 4.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i64 [ 0, %ia ], [ 4294967295, %ib ]   ; non-pow2 [3] tbl → not maskable
  %g = getelementptr inbounds [3 x double], ptr @tbl3, i64 0, i64 %id
  %v = load double, ptr %g, align 8
  %s = fadd double %x, %v
  br label %exit
base:
  br label %exit
exit:
  %r = phi double [ %s, %join ], [ %x, %base ]
  ret double %r
}

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup3(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
