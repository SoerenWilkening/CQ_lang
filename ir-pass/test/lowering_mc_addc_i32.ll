; lowering_mc_addc_i32.ll — M-C IN-PLACE REASSIGNMENT at the i32 ABI (bd
; test_C_libtooling-6uqc, Increment 2a — `add` only). The POSITIVE twin of
; lowering_add_qc_i32.ll (the fence-fallback at the same width).
;
; `q = q + c` where the parent handle `%a` has NO DATA USE AFTER the op lowers to
; the VOID in-place `cqrt_addc_i32(handle, imm)` — the ALREADY-FROZEN dtzb symbol
; (Rule 15: no new runtime symbol; the handle is i32 at every width, the
; immediate carries the logical width). No fresh rail is minted, so there is no
; ANCESTOR left standing as a basis record of the wire — which is the whole point
; (bd test_C_libtooling-nepx: an out-of-place `q += c` between two rotations
; DEPHASES the second one, verify-clean and byte-consistent).
;
; The reversal is the spine's, not a special case: `ChainWalk::isInPlaceGateOn`
; learned `cqrt_addc_<W>` in this same increment, so the gate joins `%a`'s DAG,
; `EmitInverse` adjoints it by NEGATING the immediate, and reverse program order
; puts that adjoint before the `cqrt_ry` un-rotation and the `cqrt_free`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 99)
; The adjoint (negated immediate), then the un-rotation, then the free of the
; ONE rail this program ever allocated:
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 -99)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; No out-of-place rail is minted and none is uncomputed by a data `_unc`:
; CHECK-NOT: cq_template_add_
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = add i32 %a, 99        ; parent DEAD after -> in place
  ret void
}
