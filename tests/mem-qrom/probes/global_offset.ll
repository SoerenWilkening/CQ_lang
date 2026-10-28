; Rule 20 length of a known object read from an interior element: (&T[2])[x & 3] over T[8] has
; (32 - 8 - 4) / 4 + 1 = 6 elements from its base T + 8.
@T = internal constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @global_offset(i32 %x0, double %t) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %z = zext nneg i32 %i to i64
  %b = getelementptr inbounds [8 x i32], ptr @T, i64 0, i64 2
  %e = getelementptr inbounds i32, ptr %b, i64 %z
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK global_offset: call i32 @cq_template_qrom_load_i32(ptr getelementptr inbounds (i8, ptr @T, i64 8), i64 6, i32 %{{i}})
