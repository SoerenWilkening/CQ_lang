; lowering_mc_subc_i32.ll — M-C IN-PLACE REASSIGNMENT for `sub` at the i32 ABI
; (bd test_C_libtooling-6uqc, Increment 2b — the `sub` batch).
;
; `q = q - c` with a CONSTANT immediate and a parent handle that has NO DATA USE
; AFTER the op lowers to the VOID in-place `cqrt_addc_i32(handle, -c)` — the
; SAME already-frozen symbol batch 2a uses (Rule 15: no new runtime symbol; the
; subtraction is an addition of the NEGATED classical immediate). No fresh rail
; is minted, so no ANCESTOR is left standing as a basis record of the wire.
;
; WHY `sub` REUSES `cqrt_addc_` RATHER THAN GETTING A `cqrt_subc_`: `q - c` and
; `q + (-c)` are the SAME permutation of the computational basis at every width
; (the runtime contract is `h := (h + imm) mod 2^W`, cq_runtime.h), and adding a
; symbol to the frozen grid for a value the compiler can compute at emission
; time would be a freeze change for nothing. The negation happens in CLASSICAL
; IR: constant-folded here, an ordinary `sub i32 0, %v` when the immediate is an
; SSA value (lowering_mc_subc_ssa_imm.ll).
;
; ONLY HANDLE-LHS IS ELIGIBLE. `c - q` is negate-then-add ON THE RAIL, not an
; immediate tweak, and it is refused at EVERY batch — pinned by
; lowering_mc_sub_fence_fallback.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 -99)
; The adjoint (negate the negated immediate = the original), then the
; un-rotation, then the free of the ONE rail this program ever allocated:
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 99)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; No out-of-place rail is minted, and the classical negation was folded (no
; residual `sub` instruction survives at all):
; CHECK-NOT: cq_template_sub_
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: sub i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = sub i32 %a, 99        ; parent DEAD after -> in place, imm negated
  ret void
}
