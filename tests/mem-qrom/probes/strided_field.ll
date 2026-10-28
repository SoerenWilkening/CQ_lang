; Rule 20 strided form (78's shape): p[x & 7].v over a pointer parameter of { i32, double } records.
; The field column is base p + 8, stride 16; the length is the index's range fact x & 7 < 8.
%struct.P = type { i32, double }
declare i32 @cq_theta_ui32(i32, double)
declare double @cq_measure_f64(double)

define double @strided_field(i32 %x0, double %t, ptr %p) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 7
  %z = zext nneg i32 %i to i64
  %e = getelementptr inbounds %struct.P, ptr %p, i64 %z
  %f = getelementptr inbounds i8, ptr %e, i64 8
  %v = load double, ptr %f, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}
; CHECK strided_field: %{{b}} = getelementptr inbounds i8, ptr %{{p}}, i64 8
; CHECK strided_field: call i32 @cq_template_qrom_load_f64_s(ptr %{{b}}, i64 8, i64 16, i32 %{{i}})
; CHECK-COUNT strided_field: cq_template_zext 0
