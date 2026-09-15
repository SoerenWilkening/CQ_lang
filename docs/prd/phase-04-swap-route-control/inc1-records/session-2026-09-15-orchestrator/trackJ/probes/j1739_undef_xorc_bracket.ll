; bd 1739 HOLE 2, the A2 (write-history reduction) half: a self-adjoint
; `cqrt_xorc_i32` bracket whose immediate is `undef` in BOTH slots cancels
; TEXTUALLY and need not cancel at run time.
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %r, i32 undef)
  call void @cqrt_xorc_i32(i32 %r, i32 undef)
  call void @cqrt_free(i32 %r)
  ret void
}
