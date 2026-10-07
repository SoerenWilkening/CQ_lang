; dm7f.16.1 R11 round 3: curated intrinsic semantics do not discharge noreturn.
; The source can leave outer's call untaken; hoisting would execute a returning
; intrinsic with a noreturn contract, introducing immediate UB.
; RUN: not %cq-opt -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sqrt.f64(double)
define double @outer(double %x) noinline {
  %v = call double @llvm.sqrt.f64(double %x) noreturn
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
