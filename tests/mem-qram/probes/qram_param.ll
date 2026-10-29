; A QRAM reached through a parameter: the caller's bus crosses the call as a rule 21 triple. Not built.
; EXPECT-ERROR: mem-qram: a QRAM access through a parameter
declare i32 @cq_theta_ui32(i32, double)

define void @qram_param(ptr %a, i32 %x0, double %t, i32 %v) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds i32, ptr %a, i64 %iz
  store i32 %v, ptr %p, align 4
  ret void
}
