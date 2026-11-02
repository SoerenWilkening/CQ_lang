; Rule 20 (CR 1.3, BACKEND_ABI 1.10; cq-pf4n, 2026-11-02): every global QRAM is qram_alloc_host_<W>(ptr @g, i64 n)
; in the module constructor, the cells seeded from the global's own storage at program start, the handle in the
; compiler-made @g.qram. The global keeps its definition or declaration.
;  - @ext: `extern int ext[]` of unknown extent (a declaration of no size): n = 0 (2^64 cells), cells addressed
;    by an i64 index rail; its contents are the definer's.
;  - @known: an extern of known size: n = its cell count.
;  - @recs: an array of structs with a non-zero initializer: one bus per column; a column is not the object's
;    element array, so the constructor copies it into a contiguous buffer of its frame and seeds from that.
%struct.rec = type { i32, i16 }
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
@ext = external global [0 x i32], align 4
@known = external global [6 x i32], align 4
@recs = internal global [3 x %struct.rec] [%struct.rec { i32 1, i16 2 }, %struct.rec { i32 3, i16 4 }, %struct.rec { i32 5, i16 6 }], align 16

define i32 @host(i32 %x0, double %t, i32 %v) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 1
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds i32, ptr @ext, i64 %iz
  store i32 %v, ptr %p, align 4
  %q = getelementptr inbounds [6 x i32], ptr @known, i64 0, i64 %iz
  store i32 %v, ptr %q, align 4
  %a = load i32, ptr @known, align 4
  %r0 = getelementptr inbounds [3 x %struct.rec], ptr @recs, i64 0, i64 %iz
  store i32 %v, ptr %r0, align 8
  %r = getelementptr inbounds [3 x %struct.rec], ptr @recs, i64 0, i64 %iz, i32 1
  %b = load i16, ptr %r, align 4
  %bz = zext i16 %b to i32
  %s = add i32 %a, %bz
  %m = call i32 @cq_measure_ui32(i32 %s)
  ret i32 %m
}
; CHECK __cq_qram_init_ext: %{{a}} = call i32 @cqrt_qram_alloc_host_i32(ptr @ext, i64 0)
; CHECK __cq_qram_init_ext: store i32 %{{a}}, ptr @ext.qram, align 4
; CHECK __cq_qram_init_known: %{{a}} = call i32 @cqrt_qram_alloc_host_i32(ptr @known, i64 6)
; CHECK __cq_qram_init_recs: %{{a}} = call i32 @cqrt_qram_alloc_host_i32(ptr %{{b}}, i64 3)
; CHECK __cq_qram_init_recs: %{{c}} = call i32 @cqrt_qram_alloc_host_i16(ptr %{{d}}, i64 3)
; CHECK-COUNT __cq_qram_init_recs: alloca i8, i64 12 1
; CHECK-COUNT __cq_qram_init_recs: alloca i8, i64 6 1
; CHECK __cq_qram_init_recs: store i32 %{{a}}, ptr @recs.qram, align 4
; CHECK-COUNT host: cqrt_qram_store_i32_unc 0
