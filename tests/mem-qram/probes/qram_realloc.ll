; realloc of a heap QRAM (M5, CR 1.3): cqrt_qram_realloc_i8(a, 6) -> a'; its _unc(a', 4) (n_old) runs before
; the pop of the store made through a (cq-vtfq).
declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_measure_ui8(i8)
declare noalias ptr @malloc(i64) allockind("alloc,uninitialized") allocsize(0)
declare ptr @realloc(ptr allocptr, i64) allockind("realloc") allocsize(1)

define i8 @rea(i32 %k0, double %tk, i8 %v) {
  %a = call ptr @malloc(i64 4)
  %k = call i32 @cq_theta_ui32(i32 %k0, double %tk)
  %k3 = and i32 %k, 3
  %kz = zext nneg i32 %k3 to i64
  %p = getelementptr inbounds i8, ptr %a, i64 %kz
  store i8 %v, ptr %p, align 1
  %b = call ptr @realloc(ptr %a, i64 6)
  %q = getelementptr inbounds i8, ptr %b, i64 1
  %r = load i8, ptr %q, align 1
  %m = call i8 @cq_measure_ui8(i8 %r)
  ret i8 %m
}
; CHECK rea: %{{b}} = call i32 @cqrt_qram_realloc_i8(i32 %{{a}}, i32 6)
; CHECK rea: call i32 @cqrt_qram_load_i8_hl(i32 %{{b}}, i32 1)
; CHECK rea: call void @cqrt_qram_realloc_i8_unc(i32 %{{b}}, i32 4)
