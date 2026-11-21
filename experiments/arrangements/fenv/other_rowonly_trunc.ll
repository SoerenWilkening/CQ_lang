target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: strictfp
define double @e_fma() #0 {
  %1 = tail call double @cq_measure_f64(double 0.000000e+00) #0
  ret double 0.000000e+00
}

declare double @cq_measure_f64(double)

; Function Attrs: strictfp
define double @qfma(i32 %0) #0 {
  %2 = zext i32 %0 to i64
  %3 = lshr i64 %2, 32
  %4 = trunc i64 %3 to i32
  ret double 0.000000e+00
}

attributes #0 = { strictfp }
