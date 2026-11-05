; cq-kti4: both arms of a quantum if/else raise; the spine linearizes the else arm after the then arm,
; so the then arm's FLAGS rail (or(cmp bits, select)) is not final: it is uncomputed, and only the
; else arm's FLAGS rail is the kept output (before the fix both stayed live).
; CHECK-COUNT p7: call void @cq_template_or_i32_unc( 1
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@g = global double 0.000000e+00, align 8
define i32 @p7(double %x0, double %th, double %c, double %k) #0 {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th) #0
  %q = call i1 @llvm.experimental.constrained.fcmps.f64(double %x, double %k, metadata !"ogt", metadata !"fpexcept.strict") #0
  br i1 %q, label %t, label %e
t:
  %a = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  br label %j
e:
  %b = call double @llvm.experimental.constrained.fdiv.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  br label %j
j:
  %y = phi double [ %a, %t ], [ %b, %e ]
  store double %y, ptr @g, align 8
  ret i32 0
}
declare double @cq_theta_f64(double, double)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
