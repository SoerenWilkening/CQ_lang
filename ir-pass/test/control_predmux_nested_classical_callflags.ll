; dm7f.16.1 R11 round 3: nested call flags can create poison on defined inputs.
; nan_leaf is exact and total, but the ordinary inner nnan call makes its NaN
; result poison. Returning it as noundef causes immediate UB. A source-untaken
; outer call must never be speculated; dropping the root's flags cannot repair
; this call inside the original classical callee.
; RUN: not %cq-opt -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @nan_leaf(double %x) noinline {
  ret double 0x7FF8000000000000
}
define noundef double @outer(double %x) noinline {
  %v = call nnan double @nan_leaf(double %x)
  ret double %v
}
define double @probe(double %seed, double noundef %d) {
entry:
  %q = call double @cq_theta_f64(double %seed, double 0.5)
  %qc = fcmp ogt double %q, 0.0
  br i1 %qc, label %inner, label %merge
inner:
  %cc = fcmp ogt double %d, 0.0
  br i1 %cc, label %arm, label %merge
arm:
  %v = call double @outer(double %d)
  %r = fadd double %q, %v
  br label %merge
merge:
  %out = phi double [ %r, %arm ], [ %q, %inner ], [ 5.0, %entry ]
  %m = call double @cq_measure_f64(double %out)
  ret double %m
}
