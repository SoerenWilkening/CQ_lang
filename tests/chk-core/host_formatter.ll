; cq-jp8qu: a module that defines the C library's string formatters, as cqcc's injection bundle does (musl's vsnprintf,
; vsprintf, swprintf and vswprintf, linked unrenamed and external). The evaluator's own formatting (the tape's events and
; its end-of-shot text, rt_tape.c sb_printf) must stay the host's: these bodies write nothing and return -1. (snprintf
; and sprintf, which the bundle defines too, are left out: run.py's driver prelude still calls them by name.)
target triple = "x86_64-apple-macosx16.0.0"
@.f = private constant [7 x i8] c"v=%d\0A\00\00"
define i32 @fx(i32 %x) {
  %t = call i32 @cqrt_tape_alloc()
  %r = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_tape_fmt(i32 %t, ptr @.f)
  %w = call i32 @cqrt_tape_write_i32(i32 %t, i32 %r)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
}
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_tape_fmt(i32, ptr)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
define i32 @vsnprintf(ptr %s, i64 %n, ptr %f, ptr %ap) {
  ret i32 -1
}
define i32 @vsprintf(ptr %s, ptr %f, ptr %ap) {
  ret i32 -1
}
define i32 @vswprintf(ptr %s, i64 %n, ptr %f, ptr %ap) {
  ret i32 -1
}
define i32 @swprintf(ptr %s, i64 %n, ptr %f, ...) {
  ret i32 -1
}
