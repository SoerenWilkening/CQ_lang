; spec_accept_two_arg_mask.ll — Phase 6.2 WI-2.1: a TWO-parameter callee with a
; MIXED taint signature — arg0 tainted (a quantum handle), arg1 CLASSICAL — lifts
; under the per-parameter mask (LSB = param0, DD-5). `ipow(tainted, classical)`
; → mask `0b01` → the clone is mangled `@__cq_q_ipow_01` and the CLASSICAL second
; parameter PASSES THROUGH at its original i32: it is fed straight into the
; `cq_template_add_i32_hl` data template as the classical (literal-position)
; operand and is NEVER promoted to a qubit handle (Rule 3 — a classical operand
; in a mixed Q+C op rides the `_hl`/`_lh` template, never `cqrt_alloc`). The body
; mixes a QQ op (`mul %base, %base`, both tainted) and an HL op (`add %sq, %exp`,
; handle + classical) so both template shapes ride the same Bennett wrap.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ipow(i32 %base, i32 %exp) {
entry:
  %sq = mul i32 %base, %base
  %r = add i32 %sq, %exp
  ret i32 %r
}

define void @example(i32 %u0, i32 %e) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %y = call i32 @ipow(i32 %q, i32 %e)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret void
}

; Caller: theta lowered; the call retargets to the mask-`01` clone, carrying the
; quantum handle in arg0 and the UNCHANGED classical %e in arg1.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     %[[Y:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_ipow_01(i32 %[[H]], i32 %e)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Y]])
;
; Clone: internal linkage; signature keeps arg1 as a plain i32 (NOT a handle).
; CHECK:     define internal i32 @__cq_q_ipow_01(i32 %base, i32 %exp)
; CHECK:     %[[SQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %base, i32 %base)
; The classical %exp passes through DIRECTLY as the `_hl` literal-position operand
; — not a handle derived from it — proving no qubit was allocated for it (Rule 3).
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[SQ]], i32 %exp)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[SQ]], i32 %exp)
; CHECK:     call void @cq_template_mul_i32_unc(i32 %[[SQ]], i32 %base, i32 %base)
; CHECK:     ret i32 %[[OUT]]
;
; The classical param is NEVER allocated as a qubit; the source intrinsic is gone.
; CHECK-NOT: cqrt_alloc_i32(i32 %exp)
; CHECK-NOT: cq_theta_si32
