; j1739_undef_pairing.ll — bd 1739 HOLE 2, minimal.
; The forward and its `_unc` carry the SAME TEXT `i32 undef` in the literal
; slot, so the checker's textual arg-tuple match discharges the free. At the
; -O0 stage-3 link each `undef` may materialise as a DIFFERENT value, so the
; adjoint inverts a DIFFERENT predicate and %c is freed DIRTY (bd u7z9 /
; LiteralIntegrity::declineUnpairedUndefLiterals is the compiler-side guard).
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
define void @f() {
  %h = call i32 @cqrt_alloc_i32(i32 3)
  %c = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 undef)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %c, i32 %h, i32 undef)
  call void @cqrt_free(i32 %c)
  ret void
}
