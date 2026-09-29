target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @atoi(ptr)
declare token @llvm.call.preallocated.setup(i32)
declare ptr @llvm.call.preallocated.arg(token, i32)
define i32 @h2(ptr preallocated(i32) %s, i32 %x) noinline {
  %r = add i32 %x, 1
  ret i32 %r
}
define i32 @h1(ptr preallocated(i32) %s, i32 %x) noinline {
  %r = musttail call i32 @h2(ptr preallocated(i32) %s, i32 %x)
  ret i32 %r
}
define i32 @h(ptr preallocated(i32) %s, i32 %a) noinline {
  %r = musttail call i32 @h1(ptr preallocated(i32) %s, i32 %a)
  ret i32 %r
}
define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %tok = call token @llvm.call.preallocated.setup(i32 1)
  %p = call ptr @llvm.call.preallocated.arg(token %tok, i32 0) preallocated(i32)
  store i32 3, ptr %p
  %r = call i32 @h(ptr preallocated(i32) %p, i32 %q) [ "preallocated"(token %tok) ]
  %mr = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mr
}
