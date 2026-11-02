; Rule 16: a host effect's result read by the program has no value (the call never runs): unimplemented.
; EXPECT-ERROR: cq: unimplemented: eff-tape: awaiting owner ruling: SPEC_ISSUES A deferred host call whose result is used
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
