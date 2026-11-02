; cq-1dlz / cq-hzji: fegetenv on one classical path saves the quantum FLAGS into e; on the other path e keeps
; its earlier (empty) quantum part. e's saved part is an SSA variable too: merged at the join, and fesetenv
; makes the merge the flags.
; CHECK k: %cq.fenv.merge = phi i32
; CHECK k: call i32 @cq_template_and_i32_hl(i32 %cq.fenv.merge, i32 63)
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
%struct.fenv_t = type { i16, i16, i32, i32 }
define i32 @k(double %x0, double %th, double %k, i1 %c) #0 {
entry:
  %e = alloca %struct.fenv_t, align 4
  %x = call double @cq_theta_f64(double %x0, double %th)
  %g0 = call i32 @fegetenv(ptr %e) #0
  %q = call i1 @llvm.experimental.constrained.fcmp.f64(double %x, double %k, metadata !"ogt", metadata !"fpexcept.ignore") #0
  %bits = select i1 %q, i32 8, i32 0
  %r0 = call i32 @feraiseexcept(i32 %bits) #0
  br i1 %c, label %t, label %j
t:
  %g1 = call i32 @fegetenv(ptr %e) #0
  br label %j
j:
  %s = call i32 @fesetenv(ptr %e) #0
  %f = call i32 @fetestexcept(i32 63) #0
  %m = call i32 @cq_measure_si32(i32 %f)
  ret i32 %m
}
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare i32 @fegetenv(ptr)
declare i32 @fesetenv(ptr)
declare i32 @feraiseexcept(i32)
declare i32 @fetestexcept(i32)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
