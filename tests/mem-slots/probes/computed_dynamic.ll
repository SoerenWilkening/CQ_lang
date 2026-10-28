; A computed rail stored into a slot cell read back at a run-time cell: the clean-up needs the loops
; module's reverse loop or a memory-aware uncompute, so it is an internal error, never a kept rail.
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
; EXPECT-ERROR: cq: unimplemented: mem-slots: a computed rail stored into a slot cell that is read back at a run-time cell
