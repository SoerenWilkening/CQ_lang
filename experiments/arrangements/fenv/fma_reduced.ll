target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #0

; Function Attrs: strictfp
define double @fma(i1 %0) #1 {
  br i1 %0, label %2, label %6

2:                                                ; preds = %1
  br i1 %0, label %5, label %3

3:                                                ; preds = %2
  %4 = tail call double @llvm.experimental.constrained.fsub.f64(double 0.000000e+00, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #1
  br label %5

5:                                                ; preds = %3, %2
  br label %6

6:                                                ; preds = %5, %1
  %7 = load double, ptr null, align 8
  ret double 0.000000e+00
}

attributes #0 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #1 = { strictfp }
