; Rule 16, an effect entry (102's remove): a host call with a readonly constant string argument under a
; quantum predicate is cqrt_tape_effect_controlled(flag, t, @.cq.effect.remove) and the string as a
; str_lit field; the call is not executed. The flag is uncomputed after the entry.
target triple = "x86_64-apple-macosx16.0.0"
@.path = private unnamed_addr constant [4 x i8] c"tmp\00", align 1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @remove(ptr nocapture noundef readonly)

define i32 @effect_remove(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @remove(ptr @.path)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK effect_remove: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.remove)
; CHECK effect_remove: call void @cqrt_tape_write_str_lit(i32 %{{t}}, ptr @.path)
; CHECK effect_remove: call void @cq_template_icmp_sgt_i32_hl_unc(
; CHECK-COUNT effect_remove: @remove( 0
