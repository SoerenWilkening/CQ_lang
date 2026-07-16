; lowering_reject_volatile_local_nonconst_store.ll — DECLINE PIN (bd etiq):
; the volatile-const LOCAL fold must NOT fire when the single store's value is
; NOT a Constant — a runtime value is not foldable, and (the same gate) a
; TAINTED store value can never satisfy it, so quantum shadow allocas are
; structurally excluded. The region skeleton is the claimable nested-W1 shape
; of lowering_volatile_local_fold.ll, so the volatile pair is the ONLY
; blocker: if the fold over-fired here the region would flatten and compile,
; and this test would fail. Unfolded, the volatile access blocks the tainted
; region (PredMux E4) and it declines loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0, double %rt) {
entry:
  %vd = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  store volatile double %rt, ptr %vd, align 8   ; runtime value — no fold
  %t = load volatile double, ptr %vd, align 8
  %u = fmul double %q, %t
  %c2 = fcmp ogt double %q, -1.000000e+00
  br i1 %c2, label %arm2, label %join
arm2:
  %v2 = fadd double %u, 1.000000e+00
  br label %join
join:
  %hi = phi double [ %v2, %arm2 ], [ %u, %arm ]
  br label %merge
merge:
  %r = phi double [ %hi, %join ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
