; lowering_mc_xorc_i32.ll — M-C IN-PLACE REASSIGNMENT for `xor` at the i32 ABI
; (bd test_C_libtooling-6uqc, Increment 2c — the batch that closes the
; add/sub/xor family). The POSITIVE twin of the out-of-place `xor` fallback
; pinned by lowering_mc_xor_fence_fallback.ll.
;
; `q = q ^ c` where the parent handle `%a` has NO DATA USE AFTER the op lowers to
; the VOID in-place `cqrt_xorc_i32(handle, imm)` — the ALREADY-FROZEN dtzb symbol
; (Rule 15: no new runtime symbol; the handle is i32 at every width, the
; immediate carries the logical width). No fresh rail is minted, so there is no
; ANCESTOR left standing as a basis record of the wire — which is the whole point
; (bd test_C_libtooling-nepx).
;
; `xor` IS THE CHEAPEST OF THE THREE ADMITTED OPCODES, and the reason is the
; adjoint. `add` needs its immediate negated (Inc 2a) and `sub` needs the
; immediate negated at EMISSION and again at reversal (Inc 2b); `cqrt_xorc_<W>`
; is SELF-INVERSE, so `EmitInverse` re-emits the identical call. That is also why
; the two lines below are byte-identical — this is not a copy/paste slip in the
; CHECKs, it is the mathematical content of the increment (`x ^ c ^ c == x`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_xorc_i32(i32 %[[H]], i32 99)
; The adjoint is THE SAME CALL (self-inverse), then the un-rotation; the ONE rail
; this program ever allocated holds its seed 41, not |0>, so it is kept (bd 5c5b):
; CHECK:     call void @cqrt_xorc_i32(i32 %[[H]], i32 99)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: ret void
;
; No out-of-place rail is minted and none is uncomputed by a data `_unc`:
; CHECK-NOT: cq_template_xor_
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: xor i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = xor i32 %a, 99        ; parent DEAD after -> in place
  ret void
}

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
