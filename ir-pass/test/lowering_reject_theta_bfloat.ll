; lowering_reject_theta_bfloat.ll — Phase 7.1 Increment D specificity probe:
; f16 means the IEEE `half` type, NOT `bfloat` (the other 16-bit fp format).
; abiWidthFromType keys on `isHalfTy()`, which is FALSE for bfloat (that is
; `isBFloatTy()`), so a `cq_theta_f16` DECLARED over `bfloat` does not match the
; canonical half prototype (declMatchesPrototype: llvmTypeFor("f16") == half ≠
; bfloat) and declines loudly at prototype validation. This forecloses a
; "16-bit width ⇒ f16" over-match: the two formats have different bit layouts, so
; routing bfloat through the half symbol family would be a silent miscompile.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported declared prototype for cq_theta_f16
; CHECK-NOT: cqrt_alloc_f16

declare bfloat @cq_theta_f16(bfloat, double)

define void @example() {
entry:
  %a = call bfloat @cq_theta_f16(bfloat 0xR3F80, double 5.000000e-01)
  %c = fadd bfloat %a, %a
  ret void
}
