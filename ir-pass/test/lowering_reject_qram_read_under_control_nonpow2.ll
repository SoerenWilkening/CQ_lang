; lowering_reject_qram_read_under_control_nonpow2.ll — DECLINE (3c6m.14 L6
; Inc 3): the SURVIVING under-control QROM-read decline after the Inc-3 claim
; widening. The table is `[3 x double]` — NOT a power of two — and the index
; is not provably in-bounds, so neither the known-bits proof nor the pow2
; mask applies (QromClaim::No): a speculated read would be genuinely OOB on
; excluded basis states with no sound masking. The precise Inc-3 signpost
; replaces the retired `needs nested-control lowering` message (nested-
; control lowering now EXISTS — the honest blocker is the bounds proof).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@tbl3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qi = fptosi double %q to i32
  %idx = sext i32 %qi to i64               ; unprovable index
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [3 x double], ptr @tbl3, i64 0, i64 %idx
  %v = load double, ptr %g, align 8
  %hi = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hi, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
