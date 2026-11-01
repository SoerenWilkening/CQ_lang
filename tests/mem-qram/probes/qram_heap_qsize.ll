; A heap QRAM of quantum size (rule 20, §1.3: allocated at its upper bound): malloc(zext(n & 3)) of i8
; cells is cqrt_qram_alloc_i8(3).
declare i8 @cq_theta_ui8(i8, double)
declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_measure_ui8(i8)
declare noalias ptr @malloc(i64) allockind("alloc,uninitialized") allocsize(0)

define i8 @qram_heap_qsize(i8 %n0, double %tn, i32 %k0, double %tk, i8 %v) {
  %n = call i8 @cq_theta_ui8(i8 %n0, double %tn)
  %k = call i32 @cq_theta_ui32(i32 %k0, double %tk)
  %n3 = and i8 %n, 3
  %sz = zext nneg i8 %n3 to i64
  %a = call ptr @malloc(i64 %sz)
  %k3 = and i32 %k, 3
  %kz = zext nneg i32 %k3 to i64
  %p = getelementptr inbounds i8, ptr %a, i64 %kz
  store i8 %v, ptr %p, align 1
  %q = getelementptr inbounds i8, ptr %a, i64 1
  %r = load i8, ptr %q, align 1
  %m = call i8 @cq_measure_ui8(i8 %r)
  ret i8 %m
}
; CHECK qram_heap_qsize: call i32 @cqrt_qram_alloc_i8(i32 3)
; CHECK qram_heap_qsize: call i32 @cqrt_qram_load_i8_hl(i32 %{{a}}, i32 1)
