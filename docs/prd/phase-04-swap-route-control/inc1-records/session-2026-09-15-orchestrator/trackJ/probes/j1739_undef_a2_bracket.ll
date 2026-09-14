; bd 1739 HOLE 2, the (A2) write-history half.
; The two `cqrt_xorc_i32(%r, undef)` calls are SELF-ADJOINT and cancel by
; `key()` equality — i.e. by operand TEXT. The intervening `cqrt_cnot` pair is
; not a classical-immediate write, so rule (A1) does not fire and (A2) owns the
; verdict. Each `undef` may materialise separately, so the bracket need not
; close and %r need not be back at its alloc value when it is freed.
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %c = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %r, i32 undef)
  call void @cqrt_cnot(i32 %c, i32 %r)
  call void @cqrt_cnot(i32 %c, i32 %r)
  call void @cqrt_xorc_i32(i32 %r, i32 undef)
  call void @cqrt_free(i32 %r)
  ret void
}
