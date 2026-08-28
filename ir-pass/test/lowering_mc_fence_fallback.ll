; lowering_mc_fence_fallback.ll — THE M-C DECLINE PARTITION (bd
; test_C_libtooling-6uqc, Increment 2a). Rule 12's negative half for
; `classifyInPlaceReassignment`: five shapes that DO reach the fence and are
; refused by it, each for a different clause.
;
; THE FALLBACK IS NOT A DIAGNOSTIC, AND THAT IS THE POINT. Failing this fence
; means the op keeps the EXISTING out-of-place lowering — today's behavior, byte
; for byte — so every function below still lowers, `opt` exits 0, and the CHECKs
; assert the out-of-place form. Rule 17's decline belongs to inputs outside the
; target shape; `q + c` out of place is a shape this compiler lowers correctly.
; A probe here that started emitting `cqrt_addc_` is an ACCEPT WIDENING, which
; for an in-place rewrite is the silent-miscompile direction (the parent register
; is mutated under a reader that still needs its old value).
;
; @later_measure  — G6. The parent is MEASURED after the op. A measurement is a
;                   data use; mutating the register first changes what is
;                   measured.
; @later_rotation — G6. The parent is read by a later `cq_phi` (Rz) on its own
;                   wire. Diagonal or not, it is a use of the register AFTER the
;                   op, so the fence refuses it. (Rz is basis-preserving, so this
;                   is an OVER-decline; it is the safe direction and it costs one
;                   kept rail.)
; @cross_block    — G6, the modality half. The parent's use sits in a block that
;                   does NOT dominate the op's, so `provablyBefore` cannot show
;                   the use already ran. Unproven ⇒ out of place.
; @arg_immediate  — G4. The immediate is a FORMAL PARAMETER. `cqrt_addc_<W>`
;                   declares that slot classical, but at i32 both parameters are
;                   `int32_t` and the runtime prints the slot as a bare decimal —
;                   so a rail handle there is invisible to BOTH shipped gates.
;                   Rule (A1) of tools/free_pairing_check.py therefore CHECKS it,
;                   and its `provably_not_a_rail` refuses a parameter: it
;                   "arrives from outside; nothing here can vouch". Converting
;                   this site would turn a green slice into a stage-2b UNPROVEN.
;                   (Census 0.5 cleared the rest of the surface — a volatile load
;                   and ordinary classical arithmetic both pass — so the
;                   parameter is the ONE shape held out.)
; @mul_op         — G1/G2. `mul` is information-losing: there is no in-place
;                   reversible form, so `inPlaceValueRailOperand` excludes it at
;                   EVERY batch, not just this one.
;
; NOT PROBED HERE, AND WHY (G3, the width grid). `wd.addcFn` returns null off the
; frozen {i1,i8,i16,i32,i64} grid. It is unreachable through the shipped surface
; rather than merely untested: G2 already applies the same <=64-integer bound,
; and MEASURED, every path that could carry taint to an off-grid integer `add`
; declines FIRST — `%t = trunc i64 %q to i40` dies on
; "no template for opcode 'trunc i40' in tainted context" before the add is ever
; classified. The five positive widths are pinned by lowering_mc_addc_i{1,8,16,
; 32,64}.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; NOT ONE in-place gate anywhere in this module — the single strongest assertion
; this file makes, and the one that goes red if the fence is widened:
; CHECK-NOT: cqrt_addc_
; CHECK-NOT: cqrt_xorc_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; CHECK-LABEL: define i32 @later_measure
; CHECK:       call i32 @cq_template_add_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[H]])
define i32 @later_measure(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = add i32 %q, 3
  %m1 = call i32 @cq_measure_si32(i32 %d)
  %m2 = call i32 @cq_measure_si32(i32 %q)   ; DATA USE OF THE PARENT, after the op
  %r  = add nsw i32 %m1, %m2
  ret i32 %r
}

; CHECK-LABEL: define i32 @later_rotation
; CHECK:       call i32 @cq_template_add_i32_hl(i32 %[[H2:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:       call void @cqrt_rz_i32(i32 %[[H2]], double 1.000000e-01)
define i32 @later_rotation(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = add i32 %q, 3
  %p  = call i32 @cq_phi_si32(i32 %q, double 1.000000e-01)  ; later read of the PARENT
  %m1 = call i32 @cq_measure_si32(i32 %d)
  %m2 = call i32 @cq_measure_si32(i32 %p)
  %r  = add nsw i32 %m1, %m2
  ret i32 %r
}

; CHECK-LABEL: define i32 @cross_block
; CHECK:       call i32 @cq_template_add_i32_hl(
define i32 @cross_block(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %d  = add i32 %q, 3            ; the parent's other use does NOT dominate this
  %ma = call i32 @cq_measure_si32(i32 %d)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @arg_immediate
; CHECK:       call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %k)
define i32 @arg_immediate(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = add i32 %q, %k            ; immediate is a FORMAL PARAMETER
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK-LABEL: define i32 @mul_op
; CHECK:       call i32 @cq_template_mul_i32_hl(
define i32 @mul_op(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul i32 %q, 3
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
