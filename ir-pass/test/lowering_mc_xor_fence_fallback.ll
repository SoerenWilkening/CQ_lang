; lowering_mc_xor_fence_fallback.ll — THE M-C DECLINE PARTITION FOR `xor` (bd
; test_C_libtooling-6uqc, Increment 2c). Rule 12's negative half for the `Xor`
; admission in `classifyInPlaceReassignment`: six shapes that DO reach the fence
; and are refused by it, each for a different clause.
;
; THE FALLBACK IS NOT A DIAGNOSTIC (as in 2a/2b): failing this fence means the op
; keeps the EXISTING out-of-place lowering — today's behavior, byte for byte — so
; every function below still lowers and `opt` exits 0. A probe here that started
; emitting `cqrt_xorc_` is an ACCEPT WIDENING, which for an in-place rewrite is
; the silent-miscompile direction (the parent register is mutated under a reader
; that still needs its old value).
;
; @later_measure  — G6. The parent is MEASURED after the op. A measurement is a
;                   data use; mutating the register first changes what is
;                   measured.
; @later_rotation — G6. The parent is read by a later `cq_phi` (Rz) on its own
;                   wire. Diagonal or not, it is a use of the register AFTER the
;                   op, so the fence refuses it. (Over-decline, safe direction,
;                   costs one kept rail — the same G6 correction 2a recorded
;                   against census 0.2's `cqrt_ry`/`cqrt_rz` whitelist.)
; @cross_block    — G6, the modality half. The parent's other use sits in a block
;                   that does NOT dominate the op's, so `provablyBefore` cannot
;                   show the use already ran. Unproven => out of place.
; @arg_immediate  — G4. The immediate is a FORMAL PARAMETER, the one shape rule
;                   (A1) of tools/free_pairing_check.py refuses to vouch for
;                   ("arrives from outside"). Converting it would turn a green
;                   slice into a stage-2b UNPROVEN.
; @qq_xor         — G2. BOTH operands are tainted, so there is no classical
;                   immediate for the gate's second slot at all. This is the
;                   `xor` member of the two-quantum exclusion the shared shape
;                   predicate `inPlaceValueRailOperand` has always applied; it is
;                   the QQ template's job (a Feynman/CNOT-network lowering), not
;                   an in-place-by-a-literal one.
; @wide_i128      — G3/G2, THE WIDTH GRID — and unlike 2a's `add`, this one is
;                   REACHABLE and therefore probed rather than argued. `xor` is a
;                   shipped i128 row (int_bitwise, opcode_table.yaml), so a
;                   tainted `zext i64 -> i128` feeds a real
;                   `cq_template_xor_i128_hl`. There is no `cqrt_xorc_i128` (the
;                   in-place grid stops at 64 bits — i128 is INTERMEDIATE-only,
;                   n0ui Tier-1), so the <=64-integer bound in the shape
;                   predicate refuses it and the site stays out of place. 2a
;                   could not pin its equivalent from a positive: its off-grid
;                   `add` paths all die on an earlier cast decline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; NOT ONE in-place gate anywhere in this module — the single strongest assertion
; this file makes, and the one that goes red if the fence is widened:
; CHECK-NOT: cqrt_xorc_
; CHECK-NOT: cqrt_addc_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

; CHECK-LABEL: define i32 @later_measure
; CHECK:       call i32 @cq_template_xor_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[H]])
define i32 @later_measure(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = xor i32 %q, 3
  %m1 = call i32 @cq_measure_si32(i32 %d)
  %m2 = call i32 @cq_measure_si32(i32 %q)   ; DATA USE OF THE PARENT, after the op
  %r  = add nsw i32 %m1, %m2
  ret i32 %r
}

; CHECK-LABEL: define i32 @later_rotation
; CHECK:       call i32 @cq_template_xor_i32_hl(i32 %[[H2:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:       call void @cqrt_rz_i32(i32 %[[H2]], double 1.000000e-01)
define i32 @later_rotation(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = xor i32 %q, 3
  %p  = call i32 @cq_phi_si32(i32 %q, double 1.000000e-01)  ; later read of the PARENT
  %m1 = call i32 @cq_measure_si32(i32 %d)
  %m2 = call i32 @cq_measure_si32(i32 %p)
  %r  = add nsw i32 %m1, %m2
  ret i32 %r
}

; CHECK-LABEL: define i32 @cross_block
; CHECK:       call i32 @cq_template_xor_i32_hl(
define i32 @cross_block(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %d  = xor i32 %q, 3            ; the parent's other use does NOT dominate this
  %ma = call i32 @cq_measure_si32(i32 %d)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @arg_immediate
; CHECK:       call i32 @cq_template_xor_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %k)
define i32 @arg_immediate(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = xor i32 %q, %k            ; immediate is a FORMAL PARAMETER
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK-LABEL: define i32 @qq_xor
; CHECK:       call i32 @cq_template_xor_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
define i32 @qq_xor(i32 %u0, i32 %u1) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %d  = xor i32 %q1, %q2         ; TWO tainted operands - no classical immediate
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK-LABEL: define i64 @wide_i128
; CHECK:       call i32 @cq_template_xor_i128_hl(i32 %{{[a-zA-Z0-9_.]+}}, i128 7)
define i64 @wide_i128(i64 %u0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %w = zext i64 %q to i128       ; parent of the xor, dead after it...
  %x = xor i128 %w, 7            ; ...but i128 is OFF the in-place grid
  %t = trunc i128 %x to i64
  %m = call i64 @cq_measure_sll(i64 %t)
  ret i64 %m
}
