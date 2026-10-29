; A local array written at a quantum index and read at a classical one is a QRAM (rule 20): one
; cqrt_qram_alloc at the alloca, the quantum-index store with the logical i32 index rail (the zext and
; the GEP are not emitted), the classical-index load in its _hl form, every store popped and the bus
; released by cqrt_qram_free.
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @qram_local(i32 %x0, double %t, i32 %v) {
  %a = alloca [4 x i32], align 16
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %p, align 4
  %q = getelementptr inbounds i8, ptr %a, i64 8
  %r = load i32, ptr %q, align 8
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK qram_local: %{{a}} = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK qram_local: %{{s}} = call i32 @cqrt_alloc_i32(i32 %v)
; CHECK qram_local: call void @cqrt_qram_store_i32(i32 %{{a}}, i32 %{{i}}, i32 %{{s}})
; CHECK qram_local: %{{r}} = call i32 @cqrt_qram_load_i32_hl(i32 %{{a}}, i32 2)
; CHECK qram_local: call void @cqrt_qram_store_i32_unc(i32 %{{a}}, i32 %{{i}}, i32 %{{s}})
; CHECK qram_local: call void @cqrt_qram_free(i32 %{{a}})
; CHECK-COUNT qram_local: zext 0
; CHECK-COUNT qram_local: getelementptr 0
