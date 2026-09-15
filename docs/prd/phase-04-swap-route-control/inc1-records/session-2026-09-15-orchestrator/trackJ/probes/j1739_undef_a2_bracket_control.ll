; CONTROL for j1739_undef_a2_bracket.ll — the same shape with a REAL literal.
; It must stay OK via A2-reduces-to-identity, so the fix cannot be faked by
; refusing every xorc bracket.
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %c = call i32 @cqrt_alloc_i1(i1 false)
  %r = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %r, i32 12)
  call void @cqrt_cnot(i32 %c, i32 %r)
  call void @cqrt_cnot(i32 %c, i32 %r)
  call void @cqrt_xorc_i32(i32 %r, i32 12)
  call void @cqrt_free(i32 %r)
  ret void
}
