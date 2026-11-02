; A signed quantum index into memory of unknown extent: t[i] with i < 0 is legal C. Rule 20's range facts
; give the window [-2^31, 2^31): the table starts 2^31 cells before p and the index moves up by 2^31 (cq-k65d).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @sext_param(i32 %x0, double %t, ptr %p) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %s = sext i32 %x to i64
  %e = getelementptr inbounds i32, ptr %p, i64 %s
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK sext_param: %{{i}} = call i32 @cq_template_add_i32_hl(i32 %{{x}}, i32 -2147483648)
; CHECK sext_param: %{{b}} = getelementptr i8, ptr %p, i64 -8589934592
; CHECK sext_param: call i32 @cq_template_qrom_load_i32(ptr %{{b}}, i64 4294967296, i32 %{{i}})
