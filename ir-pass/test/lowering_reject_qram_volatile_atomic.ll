; lowering_reject_qram_volatile_atomic.ll — DECLINE PIN (3c6m.14 L6 Inc 3,
; Rule-13 coverage): the volatile-const fold must NOT fire for a global that
; has ANY atomic load user — an atomic access is an observable synchronization
; the fold cannot elide, so the whole global forfeits the fold. Here the global
; is internal, constant, and never stored, but a separate function reads it
; with `load atomic`; the fold refuses, so the `load volatile` in the tainted
; arm survives, blocks the region (E4 admits no volatile access), and the
; region declines loudly — exactly as before Inc 3.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@vg = internal constant double 1.250000e+00, align 8
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @atomic_reader() {
  %a = load atomic double, ptr @vg unordered, align 8
  ret double %a
}

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %t = load volatile double, ptr @vg, align 8
  %u = fmul double %q, %t
  br label %merge
merge:
  %r = phi double [ %u, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
