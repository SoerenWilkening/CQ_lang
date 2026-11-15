; Rule 16 with rule 5's in-place form after the arm (cq-z4yh `amem`): a[i] = b; cq_theta(&a[i]) after the abort
; rotates the cell's content (swap-in, Ry, swap-out), a copy the store made after the abort, never b's rail: no
; snapshot of b (one would be a rail no rule keeps, CR §6 item 1).
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort() noreturn nounwind

define i32 @abort_inplace_cell(i32 %b0, i32 %i) {
entry:
  %a = alloca [4 x i32], align 16
  store <4 x i32> <i32 0, i32 1, i32 2, i32 3>, ptr %a, align 16
  %b = call i32 @cq_theta_si32(i32 %b0, double 1.0)
  %lo = and i32 %b, 3
  %f = icmp eq i32 %lo, 3
  br i1 %f, label %die, label %ok
die:
  call void @abort()
  unreachable
ok:
  %ix = and i32 %i, 3
  %iz = zext nneg i32 %ix to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %iz
  store i32 %b, ptr %p, align 4
  %r = call i32 @cq_theta_si32(i32 %b, double 0.2)
  store i32 %r, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK abort_inplace_cell: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK abort_inplace_cell: call void @cqrt_qram_swap_i32_hl(
; CHECK-COUNT abort_inplace_cell: cqrt_copy_i32_controlled 0
