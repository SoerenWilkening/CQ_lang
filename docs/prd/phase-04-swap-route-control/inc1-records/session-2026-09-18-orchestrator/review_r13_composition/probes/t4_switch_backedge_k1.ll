; (T4) ATTACK — the K:1 shape that (T4f) exists to refuse, reached through a
; SWITCH back edge. `free_pairing_check.py` records a block's successors from
; `term = ln.strip()`, i.e. the FIRST LINE of the terminator only, and matches
; `label %x` in it; an LLVM textual `switch` puts its case targets on the
; FOLLOWING lines, so `fn.succ[%body]` here holds only the DEFAULT target and
; `cyclic_blocks()` never learns %body reaches itself.
; %r is minted ONCE in entry and reversed-and-freed PER TRIP in %body: a
; use-after-free from the second trip on, and a 1-forward/K-adjoint rail.
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

define i32 @f(i32 %x) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %body

body:
  %c = call i32 @cq_template_icmp_eq_i32_hl(i32 %r, i32 0)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %c, i32 %r, i32 0)
  call void @cqrt_free(i32 %c)
  call void @cq_template_and_i32_hl_unc(i32 %r, i32 %h, i32 1)
  call void @cqrt_free(i32 %r)
  switch i32 %x, label %out [
    i32 0, label %body
  ]

out:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
