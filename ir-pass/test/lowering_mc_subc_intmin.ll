; lowering_mc_subc_intmin.ll — M-C `sub` whose immediate is INT_MIN (bd
; test_C_libtooling-6uqc, Increment 2b). The WRAP-AROUND probe.
;
; `-INT_MIN` is not representable in a signed i32, and the source op carries
; `nsw`. The emission must NOT constant-fold through a signed-overflow-asserting
; path: the runtime contract is `h := (h + imm) mod 2^W` (runtime/cq_runtime.h),
; so the negation is a WRAPPING APInt negation and `-2147483648` maps to
; `-2147483648` — which is the arithmetically correct answer mod 2^32 and the
; only one the reversible gate can mean.
;
; Both the forward gate and its adjoint carry the SAME immediate here (`-INT_MIN
; == INT_MIN` mod 2^W — INT_MIN is the other fixed point of negation, the i32 twin
; of the i1 collision in lowering_mc_subc_i1.ll). MEASURED end to end on this
; shape made dead instead of measured (so the spine emits the adjoint and the
; free): the gate stream is CORRECT — `addc(h, INT_MIN)` twice is `h += 2*INT_MIN
; == 0` mod 2^32, an exact identity, and `opt` exits 0 — but
; `free_pairing_check.py` reports
;     UNPROVEN A-not-reducible ... cannot prove it holds a known classical basis
;     state at the free
; because its DECIMAL `is_negation` arm reads `-2147483648` vs `-2147483648` as
; not-a-negation. That is the SAFE direction (loud, never a silent verify), and
; it is NOT specific to `sub`: `add %q, -2147483648` reaches the identical gate
; pair through batch 2a. MEASURED across all 250 e2e slices: ZERO `cqrt_addc_*`
; sites carry a negation-fixed-point immediate, so no shipped slice is affected.
; Closing it means an explicit fixed-point arm in `is_negation` beside the `i1
; true` one — an ACCEPT widening of a gate, so it is left for a deliberate
; decision rather than folded into this batch. THIS FIXTURE MEASURES ONLY THE
; EMISSION (the rail is measured here, so no adjoint is emitted); the pairing
; behaviour above is recorded, not asserted by a RUN line.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 -2147483648)
;
; CHECK-NOT: cq_template_sub_
; CHECK-NOT: sub i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = sub nsw i32 %a, -2147483648
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}
