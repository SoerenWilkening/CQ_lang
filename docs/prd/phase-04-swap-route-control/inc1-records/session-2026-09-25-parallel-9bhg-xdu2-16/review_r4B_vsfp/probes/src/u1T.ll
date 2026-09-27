; u1T.ll — the fenv-intended twin of r3B u1.ll (bd vsfp round 4): the never-stored internal
; volatile globals read at their initializers (KB = true, K2 = 5), so p = c and r = c ? 5 : 9.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  %r = select i1 %c, i32 5, i32 9
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m1, %m3
  ret i32 %s
}
