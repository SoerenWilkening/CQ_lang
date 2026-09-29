; ia2.ll — r1B pa2.ll with `inalloca` in place of `preallocated`: `h` musttail-forwards an inalloca
; argument to `h2`, which reads only the scalar. IR-only (clang emits inalloca only for the 32-bit
; Windows C++ ABI). Plain-tail spelling: iaN.ll.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @atoi(ptr)
define i32 @h2(i32 %x, ptr inalloca(i32) %s) noinline {
  %r = add i32 %x, 1
  ret i32 %r
}
define i32 @h(i32 %a, ptr inalloca(i32) %s) noinline {
  %r = musttail call i32 @h2(i32 %a, ptr inalloca(i32) %s)
  ret i32 %r
}
define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = alloca inalloca i32
  store i32 3, ptr %p
  %r = call i32 @h(i32 %q, ptr inalloca(i32) %p)
  %mr = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mr
}
