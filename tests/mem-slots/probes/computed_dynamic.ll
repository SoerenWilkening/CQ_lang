; A computed rail stored into a slot cell read back at a run-time cell (M3, cq-w2a-mem-slots): the load is
; a merge over the rails the cell may hold (Uncompute::recordCellLoad). Measured through memory, the rail
; is Measured at its store and kept (179's shape); read by a template, it is garbage and its _unc follows
; the reader's (75's shape).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @computed_dynamic(i32 %x0, double %t, i32 %c, i32 %i, i32 %j) {
  %a = alloca [4 x i32], align 16
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %m = mul i32 %x, %c
  %ii = sext i32 %i to i64
  %pi = getelementptr inbounds i32, ptr %a, i64 %ii
  store i32 %m, ptr %pi
  %jj = sext i32 %j to i64
  %pj = getelementptr inbounds i32, ptr %a, i64 %jj
  %w = load i32, ptr %pj
  %r = call i32 @cq_measure_si32(i32 %w)
  ret i32 %r
}
; CHECK-COUNT computed_dynamic: cq_template_mul_i32_hl_unc 0
; CHECK computed_dynamic: @cqrt_measure_i32(i32 %{{h}})
define i32 @computed_dynamic_read(i32 %x0, double %t, i32 %c, i32 %i, i32 %j) {
  %a = alloca [4 x i32], align 16
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %m = mul i32 %x, %c
  %ii = sext i32 %i to i64
  %pi = getelementptr inbounds i32, ptr %a, i64 %ii
  store i32 %m, ptr %pi
  %jj = sext i32 %j to i64
  %pj = getelementptr inbounds i32, ptr %a, i64 %jj
  %w = load i32, ptr %pj
  %s = add i32 %w, %c
  %r = call i32 @cq_measure_si32(i32 %s)
  ret i32 %r
}
; CHECK-COUNT computed_dynamic_read: cq_template_mul_i32_hl_unc 1
; CHECK computed_dynamic_read: call i32 @cq_template_add_i32_hl(i32 %{{l}}, i32 %c)
