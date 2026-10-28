; Rule 20 index operand: a signed C index into a known object from its start. The sext is address
; arithmetic (a negative index is outside the object: undefined); the index is the i32 rail itself.
@F = internal constant [4 x x86_fp80] [x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK40008000000000000000, x86_fp80 0xK4000C000000000000000, x86_fp80 0xK40018000000000000000]
declare i32 @cq_theta_si32(i32, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @sext_object(i32 %x0, double %t) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %s = sext i32 %x to i64
  %e = getelementptr inbounds [4 x x86_fp80], ptr @F, i64 0, i64 %s
  %v = load x86_fp80, ptr %e, align 16
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %v)
  ret x86_fp80 %m
}
; CHECK sext_object: call i32 @cq_template_qrom_load_f80(ptr @F, i64 4, i32 %{{x}})
