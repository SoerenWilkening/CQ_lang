; IR-only: a NAKED callee with no inline asm (clang cannot spell this: a naked C body must be asm-only).
; Its parameter is unused (the verifier forbids any use of a naked function's argument).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@G = internal global i32 7
declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @cq_phi(double noundef)
define i32 @f(i32 noundef %a, i32 noundef %k) noinline naked {

  %r = add i32 %k, 1
  ret i32 %r
}
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %q = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = tail call i32 @f(i32 noundef %p, i32 noundef %5)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  tail call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 7.000000e-01)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q2)
  %s = add nsw i32 %m, %r
  ret i32 %s
}
