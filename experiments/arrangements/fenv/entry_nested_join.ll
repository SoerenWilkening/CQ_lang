target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
@g = global double 0.0
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #0
define double @fma(i1 %c0, i1 %d) #1 {
entry:
  br i1 %c0, label %a1, label %out
a1:
  br i1 %d, label %a2, label %j1
a2:
  %x = load double, ptr @g, align 8
  %b = bitcast double %x to i64
  %c = icmp slt i64 %b, 0
  br i1 %c, label %j2, label %a3
a3:
  %t4 = tail call double @llvm.experimental.constrained.fsub.f64(double %x, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #1
  br label %j2
j2:
  %r = phi double [ %x, %a2 ], [ %t4, %a3 ]
  store double %r, ptr @g, align 8
  br label %j1
j1:
  br label %out
out:
  ret double 0.000000e+00
}
attributes #0 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #1 = { strictfp }
