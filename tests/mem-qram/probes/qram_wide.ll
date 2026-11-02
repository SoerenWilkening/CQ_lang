; CR 1.3 (cq-k65d, cq-pf4n 2026-11-02): a global QRAM of 2^32 cells or more: qram_alloc_host takes its i64 count;
; spelled 0 (2^64 cells; an index past the C object is undefined, outside the domain). A global of 2^32 + 4
; bytes; the classical cell 2^32 + 1 is an i64 seed index rail, the quantum index the logical rail.
declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_measure_ui8(i8)
@big = global [4294967300 x i8] zeroinitializer

define i8 @wide(i32 %k0, double %tk, i8 %v) {
  %k = call i32 @cq_theta_ui32(i32 %k0, double %tk)
  %kz = zext i32 %k to i64
  %p = getelementptr inbounds [4294967300 x i8], ptr @big, i64 0, i64 %kz
  store i8 %v, ptr %p, align 1
  %q = getelementptr inbounds [4294967300 x i8], ptr @big, i64 0, i64 4294967297
  %r = load i8, ptr %q, align 1
  %m = call i8 @cq_measure_ui8(i8 %r)
  ret i8 %m
}
; CHECK __cq_qram_init_big: call i32 @cqrt_qram_alloc_host_i8(ptr @big, i64 4294967300)
; CHECK wide: %{{j}} = call i32 @cqrt_alloc_i64(i64 4294967297)
; CHECK wide: call i32 @cqrt_qram_load_i8(i32 %{{a}}, i32 %{{j}})
