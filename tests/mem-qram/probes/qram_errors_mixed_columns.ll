; An array of structs whose v column is a QRAM while its w column is classical memory: the site has no
; host block once it is a QRAM, so this is not built (rule 20).
; EXPECT-ERROR: mem-qram: an array of structs whose field columns are of different classes
%struct.cell = type { i32, i32 }
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @mixed(i32 %x0, double %t, i32 %v, i32 %c) {
  %a = alloca [4 x %struct.cell], align 16
  %w = getelementptr inbounds i8, ptr %a, i64 4
  store i32 %c, ptr %w, align 4
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x %struct.cell], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %p, align 8
  %r = load i32, ptr %a, align 8
  %r2 = load i32, ptr %w, align 4
  %s = add i32 %r, %r2
  %m = call i32 @cq_measure_ui32(i32 %s)
  ret i32 %m
}
