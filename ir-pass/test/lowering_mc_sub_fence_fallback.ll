; lowering_mc_sub_fence_fallback.ll — THE M-C `sub` DECLINE PARTITION (bd
; test_C_libtooling-6uqc, Increment 2b). Rule 12's negative half for the batch
; that widened G1 to `sub`; the `add` partition lives in
; lowering_mc_fence_fallback.ll and is UNCHANGED by this increment.
;
; THE FALLBACK IS NOT A DIAGNOSTIC (2a's ruling, restated because it is the
; thing most easily got wrong here). Failing this fence means the op keeps the
; EXISTING out-of-place lowering, so every function below but @arg_immediate
; (in place since bd dm7f.83.1) still lowers, `opt` exits 0, and the CHECKs
; assert the out-of-place form. A probe in any OTHER function here that started
; emitting `cqrt_addc_` is an ACCEPT WIDENING, the silent-miscompile direction.
;
; @classical_lhs  — THE `sub`-SPECIFIC CLAUSE, and the only structural one this
;                   increment adds. `c - q` is NOT `q + (-c)`: it is
;                   negate-the-rail THEN add, i.e. a rewrite of the register's
;                   whole value rather than an immediate tweak, and
;                   `cqrt_addc_<W>` cannot express it at any width. It is refused
;                   in EVERY batch — not deferred to 2c — and it is the numerous
;                   shape: census 0.2 measured 84 `cq_template_sub_<W>_lh` calls
;                   corpus-wide (openlibm's `1023 - hx` exponent-bias idiom and
;                   its siblings) against 7 `_hl` ones, so a fence that got this
;                   direction backwards would mis-lower most of the corpus.
; @later_use      — G6. The parent is MEASURED after the op. Identical to the
;                   `add` clause; re-probed on `sub` because G6 reads the PARENT
;                   picked by the new operand rule, and a `sub` picker that
;                   returned the wrong operand would silently pass G6 on the
;                   immediate's user list instead.
; @arg_immediate  — WAS G4 (out of place). bd dm7f.83.1: G4 is RETIRED for a classical formal parameter. Stage 2b vouches
; for it on the pass's `!cq.classical.params` claim, which it CHECKS (every
; in-function use in a classical slot, every in-module caller classical;
; free_pairing_check.py `vouched_params`), so the site converts IN PLACE.
;                  (the historical G4 note follows) G4. The immediate is a FORMAL PARAMETER, so
;                   `free_pairing_check.py`'s rule (A1) cannot vouch that the
;                   slot is classical ("arrives from outside"). Note the extra
;                   edge this batch gives the clause: for `sub` the emitted
;                   immediate would be a `sub i32 0, %k` the checker CAN see is
;                   not a rail — but its operand still is not, and the fence
;                   refuses on the SOURCE immediate, before the negation exists.
;
; NOT PROBED HERE (G3, the width grid): unreachable through the shipped surface
; for exactly the reason 2a measured — G2's <=64-integer bound, and every path
; that could carry taint to an off-grid integer op declines FIRST at the cast.
; The five positive widths for this batch are pinned by lowering_mc_subc_i1.ll
; and lowering_mc_subc_i32.ll plus the shared grid probe in the `add` files.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; No in-place gate in any function but @arg_immediate (bd dm7f.83.1 converts it)
; — asserted INSIDE each function's CHECK-LABEL block (R11 rL2b-F2: a CHECK-NOT
; before the first label covers only the text before it, so the old
; module-wide pair was vacuous).

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; CHECK-LABEL: define i32 @classical_lhs
; CHECK-NOT:   call void @cqrt_addc_
; CHECK-NOT:   call void @cqrt_xorc_
; CHECK:       call i32 @cq_template_sub_i32_lh(i32 100, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT:   call void @cqrt_addc_
; CHECK-NOT:   call void @cqrt_xorc_
define i32 @classical_lhs(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = sub i32 100, %q           ; c - q: NEVER an in-place immediate add
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK-LABEL: define i32 @later_use
; CHECK-NOT:   call void @cqrt_addc_
; CHECK-NOT:   call void @cqrt_xorc_
; CHECK:       call i32 @cq_template_sub_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:   call void @cqrt_addc_
; CHECK-NOT:   call void @cqrt_xorc_
define i32 @later_use(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = sub i32 %q, 3
  %m1 = call i32 @cq_measure_si32(i32 %d)
  %m2 = call i32 @cq_measure_si32(i32 %q)   ; DATA USE OF THE PARENT, after the op
  %r  = add nsw i32 %m1, %m2
  ret i32 %r
}

; CHECK-LABEL: define i32 @arg_immediate
; CHECK:       [[NEG:%[a-zA-Z0-9_.]+]] = sub i32 0, %k
; CHECK-NEXT:  call void @cqrt_addc_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 [[NEG]])
define i32 @arg_immediate(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = sub i32 %q, %k            ; immediate is a FORMAL PARAMETER
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
