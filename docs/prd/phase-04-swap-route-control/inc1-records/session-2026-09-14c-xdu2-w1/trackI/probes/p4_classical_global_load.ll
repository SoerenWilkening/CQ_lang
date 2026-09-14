; p4 — the NEGATIVE CONTROL for the whole fix, and the reason the new rule is
; armed by EVIDENCE rather than by opcode class. This is the shipped POSITIVE
; fixture `XORC_SSA` (tools/free_pairing_check_test.py), whose classical
; immediate is a `load volatile i32, ptr @msk` — one of the 4 real corpus sites
; `provably_not_a_rail`'s docstring names (the 2a seq-grover reassignment
; immediate). There is no rail bank and no rail store in this module, so the
; premise HOLDS here and the verdict must not move.
@msk = internal global i32 3
define void @slice(i32 %x) {
  %v = load volatile i32, ptr @msk, align 4
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  call void @cqrt_xorc_i32(i32 %h, i32 %v)
  call void @cqrt_xorc_i32(i32 %h, i32 %v)
  call void @cqrt_ry_i32(i32 %h, double -2.500000e-01)
  call void @cqrt_free(i32 %h)
  ret void
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_free(i32)
