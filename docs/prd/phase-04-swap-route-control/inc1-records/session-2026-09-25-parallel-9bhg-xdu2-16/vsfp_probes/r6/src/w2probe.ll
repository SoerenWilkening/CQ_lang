; w2probe.ll — bd vsfp round 6, Rule 14: an inner clone call whose dead slot is NOT null-safe (a string
; attribute on the int parameter — IR-only; clang -O1 emits only noundef/signext/zeroext), feeding a
; value the enclosing clone then reassigns in place (M-C arm (d0)) and rotates (M-A's hop walk).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @g(i32 noundef "cq.probe.opaque" %a, i32 noundef %k) {
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %t, label %m
t:
  br label %m
m:
  %r = add nsw i32 %k, 1
  ret i32 %r
}

define i32 @h(i32 noundef %a, i32 noundef %k) {
  %p = mul nsw i32 %a, 3
  %t = call i32 @g(i32 noundef %p, i32 noundef %k)
  %u = add nsw i32 %p, %t
  ret i32 %u
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %q = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %r = tail call i32 @h(i32 noundef %q, i32 noundef %5)
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 7.000000e-01)
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %r)
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %q2)
  %s = add nsw i32 %m1, %m2
  ret i32 %s
}
