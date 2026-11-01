; A function pointer read at a quantum index whose value is unused past the QROM (97's load without the call):
; the derived constant table of callee tags @fps.cqtag (dbl = 1, sq = 2: the module's address-taken
; functions in order) and one QROM over it at the logical index rail, uncomputed.
@fps = internal unnamed_addr constant [2 x ptr] [ptr @dbl, ptr @sq], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @dbl(i32 %v) {
  %r = shl nsw i32 %v, 1
  ret i32 %r
}
define internal i32 @sq(i32 %v) {
  %r = mul nsw i32 %v, %v
  ret i32 %r
}
define i32 @fn_table_unused(i32 %x0, double %t, i32 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = and i32 %x, 1
  %z = zext nneg i32 %a to i64
  %e = getelementptr inbounds [2 x ptr], ptr @fps, i64 0, i64 %z
  %f = load ptr, ptr %e, align 8
  %s = add nsw i32 %x, %c
  %r = add i32 %s, 0
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
; CHECK fn_table_unused: call i32 @cq_template_qrom_load_i32(ptr @fps.cqtag, i64 2, i32 %{{a}})
; CHECK fn_table_unused: call void @cq_template_qrom_load_i32_unc(i32 %{{t}}, ptr @fps.cqtag, i64 2, i32 %{{a}})
; CHECK-COUNT fn_table_unused: cq_template_zext 0
