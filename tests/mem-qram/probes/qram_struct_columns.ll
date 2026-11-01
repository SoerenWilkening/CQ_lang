; An array of structs at a quantum index (rules 20, 26, 168): one bus per field column, the GEP's field
; picks the column, the element is the index.
%struct.cell = type { i32, i16 }
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @columns(i32 %x0, double %t, i32 %v) {
  %a = alloca [4 x %struct.cell], align 16
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x %struct.cell], ptr %a, i64 0, i64 %iz, i32 1
  %h = trunc i32 %v to i16
  store i16 %h, ptr %p, align 4
  %q = getelementptr inbounds [4 x %struct.cell], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %q, align 8
  %f = getelementptr inbounds i8, ptr %a, i64 12
  %r = load i16, ptr %f, align 4
  %rz = zext i16 %r to i32
  %m = call i32 @cq_measure_ui32(i32 %rz)
  ret i32 %m
}
; CHECK columns: %{{v}} = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK columns: %{{w}} = call i32 @cqrt_qram_alloc_i16(i32 4)
; CHECK columns: call void @cqrt_qram_store_i16(i32 %{{w}}, i32 %{{i}}, i32 %{{h}})
; CHECK columns: call void @cqrt_qram_store_i32(i32 %{{v}}, i32 %{{i}}, i32 %{{s}})
; CHECK columns: call i32 @cqrt_qram_load_i16_hl(i32 %{{w}}, i32 1)
