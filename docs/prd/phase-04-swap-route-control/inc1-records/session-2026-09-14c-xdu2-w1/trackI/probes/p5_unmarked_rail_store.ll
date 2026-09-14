; p5 — THE PREMISE ITSELF, made checkable. A rail handle is stored to memory
; that carries NO `!cq.railbank` marker. That is the promoter having forgotten
; the marker, or a second escape mechanism nobody told this file about; either
; way `free_pairing_check.py:1292`'s premise is false for this module and the
; load classification below it is guesswork. The checker must REFUSE TO RENDER A
; VERDICT, the way it refuses for an unmodelled `cqrt_*` symbol.
define i32 @slice() local_unnamed_addr {
entry:
  %slot = alloca i32, align 4
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)
  store i32 %hb, ptr %slot, align 4
  %r = call i32 @cqrt_alloc_i32(i32 7)
  %v = load i32, ptr %slot, align 4
  call void @cqrt_xorc_i32(i32 %r, i32 %v)
  call void @cqrt_free(i32 %r)
  ret i32 0
}
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_free(i32)
