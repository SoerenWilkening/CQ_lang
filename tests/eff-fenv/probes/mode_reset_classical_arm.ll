; cq-1dlz / cq-hzji: fesetround(const) on one classical path drops a quantum MODE; after the join the other
; path still rounds in the quantum mode: MODE is a merge of the quantum rail and a seed of the classical
; mode (fegetround() where that edge leaves), and the division rounds in it (_rmq).
; CHECK k: %cq.fenv.merge = phi i32
; CHECK k: call i32 @cq_template_fdiv_f64_ll_rmq(double %a, double %b, i32 %cq.fenv.merge)
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @k(double %x0, double %th, double %k, double %a, double %b, i1 %c) #0 {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %q = call i1 @llvm.experimental.constrained.fcmp.f64(double %x, double %k, metadata !"ogt", metadata !"fpexcept.ignore") #0
  %r = select i1 %q, i32 2048, i32 1024
  %s0 = call i32 @fesetround(i32 %r) #0
  br i1 %c, label %t, label %j
t:
  %s1 = call i32 @fesetround(i32 0) #0
  br label %j
j:
  %y = call double @llvm.experimental.constrained.fdiv.f64(double %a, double %b, metadata !"round.dynamic", metadata !"fpexcept.ignore") #0
  %m = call double @cq_measure_f64(double %y)
  %i = fptosi double %m to i32
  ret i32 %i
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @fesetround(i32)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
