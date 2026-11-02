; Rule 16 (a result the program reads): printf's count is snprintf(0, 0, fmt, args...) in front of the
; deferred printf, a rule 27 declared clone here (no injected body). The rewrite is eff-tape's; the declared
; clone of a pointer-taking callee with a result is the calls module's open stop (rule 27).
; EXPECT-ERROR: cq: unimplemented: calls: a declared clone with a pointer argument and a result
target triple = "x86_64-apple-macosx16.0.0"
@.fmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

define i32 @printf_result_used(i32 %x0, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %r = call i32 (ptr, ...) @printf(ptr @.fmt, i32 %x)
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
}
