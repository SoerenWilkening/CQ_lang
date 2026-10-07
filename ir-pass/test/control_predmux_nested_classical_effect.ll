; dm7f.16 survivor: an observable classical call in a value arm has no
; speculative lowering. This stays a loud compiler gap, not a physics decline.
; RUN: not %cq-opt -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @effect(double)
define double @probe(double noundef %x, double noundef %y) {
entry:
  %q = call double @cq_theta_f64(double %x, double 0.5)
  %qc = fcmp ogt double %q, %y
  br i1 %qc, label %inner, label %merge
inner:
  %c = call i32 @effect(double %y)
  %ck = icmp ne i32 %c, 0
  br i1 %ck, label %a, label %b
a:
  %qa = fsub double %q, %y
  br label %merge
b:
  %qb = fadd double %q, %y
  br label %merge
merge:
  %r = phi double [ %qa, %a ], [ %qb, %b ], [ %y, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
