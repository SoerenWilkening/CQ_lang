; lowering_mc_subc_i1.ll — M-C `sub` at the i1 ABI (bd test_C_libtooling-6uqc,
; Increment 2b). The width where the negation is its own inverse.
;
; `-1 == 1 (mod 2)`, so at i1 the negated immediate is spelled IDENTICALLY to the
; original: `sub i1 %q, true` emits `cqrt_addc_i1(h, true)`, and its adjoint
; (negate again) is `cqrt_addc_i1(h, true)` as well. That collision is the reason
; `free_pairing_check.py`'s `is_negation` carries an explicit `i1 true`/`i1 true`
; arm (added in Inc 2a, selftest `addc-i1-self-inverse`): the pairing rule has to
; ACCEPT two identical booleans here, and the mutant `addc-i1-adjoint-flipped-to-
; false` is what stops that acceptance from being a hole.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 true)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i1(i32 %[[H]], i1 true)
; CHECK:     call void @cqrt_addc_i1(i32 %[[H]], i1 true)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; bd 5c5b (libcqops vmz9): the root holds its seed `true` after Ry-dagger, so it is kept.
; CHECK-NEXT: ret void
;
; CHECK-NOT: cq_template_sub_
; CHECK-NOT: sub i1

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i1 @cq_theta_i1(i1, double)

define void @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 true, double 5.000000e-01)
  %c = sub i1 %a, true        ; parent DEAD after -> in place; -true == true
  ret void
}

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 true)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
