; lowering_mc_xorc_i1.ll — M-C IN-PLACE REASSIGNMENT for `xor` at the i1 ABI (bd
; test_C_libtooling-6uqc, Increment 2c).
;
; AT i1, `q ^= true` IS LOGICAL NOT — the classical spelling of a Pauli-X on the
; rail's basis label. It is worth its own fixture for two reasons:
;
;  * it is the ONE width at which the in-place form and a core primitive
;    coincide in meaning (`cqrt_x` would be the same permutation), and the
;    increment deliberately does NOT reach for `cqrt_x`: the M-C path emits the
;    width-parametric `cqrt_xorc_i1` like every other width, so there is exactly
;    one emission rule and one adjoint rule across the grid (Rule 14 — the
;    peephole is not this increment's business, and a second minter of the same
;    permutation would be a second thing to keep in step).
;  * `free_pairing_check.py` reduces the forward/adjoint pair on `key()`
;    equality for a self-inverse gate, and at i1 both immediates spell
;    `i1 true` — so this width pairs on the SAME rule as i32, with none of the
;    `i1 true`/`i1 true` negation special-casing the 2a `addc` immediate needed
;    (`-1 == 1 mod 2`). Self-inverse has no such edge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 true)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_xorc_i1(i32 %[[H]], i1 true)
; The adjoint is the SAME call (self-inverse), then the un-rotation and the free:
; CHECK:     call void @cqrt_xorc_i1(i32 %[[H]], i1 true)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_xor_
; CHECK-NOT: cqrt_x(
; CHECK-NOT: xor i1

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i1 @cq_theta_i1(i1, double)

define void @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 true, double 5.000000e-01)
  %c = xor i1 %a, true        ; parent DEAD after -> in place (logical NOT)
  ret void
}
