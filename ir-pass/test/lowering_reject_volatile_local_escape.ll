; lowering_reject_volatile_local_escape.ll — DECLINE PIN (bd etiq): the
; volatile-const LOCAL fold must NOT fire when the alloca's address ESCAPES
; (here: passed to an unknown external call) — an escaped address admits
; writers the user scan cannot see, so load == stored-constant is unprovable.
; Any user other than the single store / same-type loads / lifetime markers
; forfeits the fold for the WHOLE alloca. The escaping call sits OUTSIDE the
; tainted region (entry) so the volatile pair stays the region's ONLY
; blocker: if the fold over-fired here the region would flatten and compile,
; and this test would fail. Unfolded, the volatile access blocks the tainted
; region (PredMux E4) and it declines loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @sink(ptr)

define double @probe(double %u0) {
entry:
  %vd = alloca double, align 8
  call void @sink(ptr nonnull %vd)              ; address escapes — no fold
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  store volatile double 0x41F0000000000000, ptr %vd, align 8
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

; (bd vyqi, W5 re-label: the INNER flat fp diamond of the nested-W1 skeleton
; now flattens first — its sole-2-incoming fp merge phi is a claim witness —
; so the residual outer region declines UN-nested. The access above still
; blocks the fold/promotion and the region still declines LOUDLY; only the
; label narrowed from `nested control flow` to `control flow`.)
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
