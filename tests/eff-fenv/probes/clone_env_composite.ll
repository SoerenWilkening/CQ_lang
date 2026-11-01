; cq-xhv4 (E1, rule 23 with rule 26 / CR §1.4): a clone carrying the environment whose result is
; field-wise: it returns the literal struct of its result fields (handles where quantum) followed by the
; new flags handle; the caller binds the fields, the flags become its FLAGS, and the twin takes every
; handle field then the flags as its outs.
; CHECK g: call fastcc { i32, i32, i32 } @__cq_q_pair_10(i32 %{{x}}, double %{{c}}, i32 %{{m}}, i32 %{{f}})
; CHECK g: extractvalue { i32, i32, i32 } %{{r}}, 2
; CHECK g: call void @__cq_q_pair_10_unc(i32 %{{a}}, i32 %{{b}}, i32 %{{n}}, i32 %{{x}}, double %{{c}}, i32 %{{m}}, i32 %{{f}})
; CHECK __cq_q_pair_10: ret { i32, i32, i32 }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define internal fastcc { double, double } @pair(double %v, double %c) #1 {
  %a = call double @llvm.experimental.constrained.fmul.f64(double %v, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %b = call double @llvm.experimental.constrained.fadd.f64(double %v, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %s0 = insertvalue { double, double } poison, double %a, 0
  %s1 = insertvalue { double, double } %s0, double %b, 1
  ret { double, double } %s1
}
define i32 @g(double %x0, double %th, double %c) #0 {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %p = call fastcc { double, double } @pair(double %x, double %c) #0
  %p0 = extractvalue { double, double } %p, 0
  %p1 = extractvalue { double, double } %p, 1
  %s = call double @llvm.experimental.constrained.fadd.f64(double %p0, double %p1, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %ms = call double @cq_measure_f64(double %s)
  %f = call i32 @fetestexcept(i32 63) #0
  %m = call i32 @cq_measure_si32(i32 %f)
  ret i32 %m
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @cq_measure_si32(i32)
declare i32 @fetestexcept(i32)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
attributes #1 = { noinline strictfp }
