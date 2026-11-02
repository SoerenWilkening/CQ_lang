; Rule 20 / CR 1.3 (cq-k65d, 2026-11-02): a heap QRAM from an allocator whose size the IR does not state
; (no allocsize) is an object of unknown extent: qram_alloc(0), 2^64 cells. A classical cell index of such
; an object that may not fit i32 is an i64 seed index rail (the idx form; the _hl j is an i32).
declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_measure_ui8(i8)
declare noalias ptr @my_alloc(i64) allockind("alloc,uninitialized")

define i8 @unk(i32 %k0, double %tk, i8 %v, i64 %j) {
  %a = call ptr @my_alloc(i64 4)
  %k = call i32 @cq_theta_ui32(i32 %k0, double %tk)
  %kz = zext i32 %k to i64
  %p = getelementptr inbounds i8, ptr %a, i64 %kz
  store i8 %v, ptr %p, align 1
  %q = getelementptr inbounds i8, ptr %a, i64 %j
  %r = load i8, ptr %q, align 1
  %m = call i8 @cq_measure_ui8(i8 %r)
  ret i8 %m
}
; CHECK unk: %{{a}} = call i32 @cqrt_qram_alloc_i8(i32 0)
; CHECK unk: %{{h}} = call i32 @cqrt_alloc_i64(i64 %j)
; CHECK unk: call i32 @cqrt_qram_load_i8(i32 %{{a}}, i32 %{{h}})
; CHECK-COUNT unk: _hl 0
