; cq-6r4r: the value field of {u,s}{add,sub,mul}.with.overflow is CR rule 6's bijection (112
; usub_overflow_qq): d = x - y with x dead cleans x by t = d + y; the overflow field's template reads x
; too, a reader that only moves the clean-up. @mul3: x * 3 (odd) cleans x by t = d * 3^-1.
declare i64 @cq_theta_ul(i64, double)
declare i64 @cq_measure_ul(i64)
declare i32 @cq_measure_si32(i32)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)

define i64 @usub(i64 %x0, i64 %y0, double %tx, double %ty) {
  %x = call i64 @cq_theta_ul(i64 %x0, double %tx)
  %y = call i64 @cq_theta_ul(i64 %y0, double %ty)
  %r = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %x, i64 %y)
  %o = extractvalue { i64, i1 } %r, 1
  %d = extractvalue { i64, i1 } %r, 0
  %oz = zext i1 %o to i32
  %md = call i64 @cq_measure_ul(i64 %d)
  %mo = call i32 @cq_measure_si32(i32 %oz)
  %mos = sext i32 %mo to i64
  %my = call i64 @cq_measure_ul(i64 %y)
  %s1 = add i64 %md, %mos
  %s = add i64 %s1, %my
  ret i64 %s
}
; CHECK-COUNT usub: call void @cqrt_copy_i64( 1
; CHECK usub: call i32 @cq_template_add_i64(i32 %{{d}}, i32 %{{y}})

define i64 @mul3(i64 %x0, double %tx) {
  %x = call i64 @cq_theta_ul(i64 %x0, double %tx)
  %r = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %x, i64 3)
  %o = extractvalue { i64, i1 } %r, 1
  %d = extractvalue { i64, i1 } %r, 0
  %oz = zext i1 %o to i32
  %md = call i64 @cq_measure_ul(i64 %d)
  %mo = call i32 @cq_measure_si32(i32 %oz)
  %mos = sext i32 %mo to i64
  %s = add i64 %md, %mos
  ret i64 %s
}
; CHECK-COUNT mul3: call void @cqrt_copy_i64( 1
; CHECK mul3: call i32 @cq_template_mul_i64_hl(i32 %{{d}}, i64 -6148914691236517205)
