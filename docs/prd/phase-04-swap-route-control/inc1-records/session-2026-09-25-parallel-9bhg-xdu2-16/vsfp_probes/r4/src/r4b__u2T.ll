; u2T.ll — the fenv-intended twin of r3B u2.ll (bd vsfp round 4): the volatile local is never
; observable, both arms are empty, so the program is its theta and its measure.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m1
}
