; lowering_reject_volatile_local_atomic.ll — DECLINE PIN (bd etiq): the
; volatile-const LOCAL fold must NOT fire for an ATOMIC access — atomics
; carry ordering semantics the fold has no story for (mirrors the global
; fold's atomic gate). The region skeleton is the claimable nested-W1 shape
; of lowering_volatile_local_fold.ll, so the accesses are the region's ONLY
; blocker: if the fold over-fired here the region would flatten and compile,
; and this test would fail. Unfolded, the access blocks the tainted region
; (PredMux E4 admits only simple loads) and it declines loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %vd = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  store volatile double 0x41F0000000000000, ptr %vd, align 8
  %t = load atomic volatile double, ptr %vd seq_cst, align 8   ; atomic — no fold
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
