; lowering_mc_xorc_ssa_imm.ll — M-C in-place `xor` with a NON-CONSTANT classical
; immediate (bd test_C_libtooling-6uqc, Increment 2c).
;
; THE POINT OF THIS FILE IS THE CONTRAST WITH 2b, and it is a real asymmetry in
; what tools/free_pairing_check.py can PROVE — not a cosmetic difference:
;
;   2b (`sub`, lowering_mc_subc_ssa_imm.ll): forward `cqrt_addc_i32(%h, %neg)`
;   where `%neg = sub i32 0, %v`; adjoint `cqrt_addc_i32(%h, %neg2)` where
;   `%neg2 = sub i32 0, %neg`. `addc` pairs by `is_negation` on the immediate
;   slot, and that predicate cannot relate two SSA NAMES — so a freed rail on
;   that shape reports UNPROVEN under a strict slice (loud, safe direction).
;
;   2c (`xor`, HERE): `cqrt_xorc_<W>` is SELF-INVERSE, so `EmitInverse` re-emits
;   the identical call and the checker pairs it on `key()` equality — the same
;   SSA name `%v` in both immediate slots, no negation predicate involved. An
;   SSA-immediate xor site therefore pairs where the `add`/`sub` analogue cannot.
;
; The immediate is still held to rule (A1) `provably_not_a_rail` (a `volatile`
; load is classical on positive evidence); a FORMAL PARAMETER immediate is the
; one shape G4 keeps out of place, pinned in lowering_mc_xor_fence_fallback.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
;
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @msk
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; The forward gate takes the loaded value UNCHANGED — no negation is emitted...
; CHECK:      call void @cqrt_xorc_i32(i32 %[[H]], i32 %[[V]])
; ...and neither does the adjoint: it is the SAME call on the SAME SSA name.
; CHECK:      call void @cqrt_xorc_i32(i32 %[[H]], i32 %[[V]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; bd 5c5b (libcqops vmz9): the rail holds its seed 41 after Ry-dagger: kept, not freed.
; CHECK-NEXT: ret void
;
; No classical negation is emitted anywhere (the 2b `sub iW 0, %v` shape):
; CHECK-NOT:  sub i32 0,
; CHECK-NOT:  cq_template_xor_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@msk = global i32 3

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %v = load volatile i32, ptr @msk, align 4
  %a = call i32 @cq_theta_si32(i32 41, double 5.000000e-01)
  %c = xor i32 %a, %v        ; parent DEAD after -> in place, SSA immediate
  ret void
}

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 41)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
