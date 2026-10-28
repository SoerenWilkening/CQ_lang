; Rule 16, printf with a classical %s argument, a classical int and a quantum int, unconditional: one
; format entry, the string copied as tape_write_str_lit, the int as tape_write_i32_lit, the quantum value
; as a fresh write-only tape rail; one tape at the function entry.
target triple = "x86_64-apple-macosx16.0.0"
@.fmt = private unnamed_addr constant [10 x i8] c"%s %d %d\0A\00", align 1
@.name = private unnamed_addr constant [3 x i8] c"ab\00", align 1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

define i32 @printf_string_field(i32 %x0, double %t, i32 %c) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %r = call i32 (ptr, ...) @printf(ptr @.fmt, ptr @.name, i32 %c, i32 %x)
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK printf_string_field: %{{t}} = call i32 @cqrt_tape_alloc()
; CHECK printf_string_field: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.fmt)
; CHECK printf_string_field: call void @cqrt_tape_write_str_lit(i32 %{{t}}, ptr @.name)
; CHECK printf_string_field: call void @cqrt_tape_write_i32_lit(i32 %{{t}}, i32 %{{c}})
; CHECK printf_string_field: = call i32 @cqrt_tape_write_i32(i32 %{{t}}, i32 %{{x}})
; CHECK-COUNT printf_string_field: @cqrt_tape_alloc() 1
; CHECK-COUNT printf_string_field: cqrt_free 0
