; Rule 22, a run-time length of whole double cells (k * 8 bytes) from cell 1 with a classical fill byte
; %f: the cell value is the byte splat over 8 bytes as a double; the loop starts at cell 1, the length
; is k cells (the byte length shifted right by 3).
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define double @memset_offset_double(i32 %k, i8 %f, i32 %i, double %t) {
  %a = alloca [16 x double], align 16
  %kk = zext i32 %k to i64
  %len = shl nuw nsw i64 %kk, 3
  %d = getelementptr inbounds i8, ptr %a, i64 8
  call void @llvm.memset.p0.i64(ptr align 8 %d, i8 %f, i64 %len, i1 false)
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds [16 x double], ptr %a, i64 0, i64 %ii
  %v = load double, ptr %p, align 8
  %x = call double @cq_theta_f64(double %v, double %t)
  store double %x, ptr %p, align 8
  %m = call double @cq_measure_f64(double %x)
  ret double %m
}
; CHECK memset_offset_double: lshr exact i64 %{{len}}, 3
; CHECK memset_offset_double: mul i64 %{{z}}, 72340172838076673
; CHECK memset_offset_double: bitcast i64 %{{w}} to double
; CHECK memset_offset_double: add i64 1, %{{j}}
; CHECK-COUNT memset_offset_double: @cqrt_alloc_f64( 1
; CHECK-COUNT memset_offset_double: call void @cqrt_free( 0
