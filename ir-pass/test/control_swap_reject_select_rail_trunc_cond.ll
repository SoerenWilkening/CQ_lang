; control_swap_reject_select_rail_trunc_cond.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1): a `trunc i32 %q to i1` select condition is
; NOT a rail leaf. `isCondRailLeaf` is `cq_theta_i1`-ONLY on purpose (bd 3qlq.4,
; PRD §13.4): a trunc/zext/sext is a DERIVED rail that would need its own mint
; and discharge design, a phi is a loop-carried or region-merge rail a preceding
; emitter dissolves, a template result / clone `Argument` / QRAM load are each a
; different rail story. None is admitted, and the tree grammar has no other slot
; for them — so `collectCondTree` returns false and gate 2 declines generically.
;
; GREEN ON BOTH BINARIES: this is a pure DISCRIMINATOR for the narrowness of
; `isCondRailLeaf`, not a red-green pin. MEASURED with a mutant that admits an
; i1 `trunc`/`phi` as a rail leaf: SIX fixtures redden — this file,
; `..._reject_select_rail_phi_cond.ll`, and the four pre-existing pins of the
; same narrowness (`control_phase_kickback_reject_bare_i1_{trunc,loop_phi}.ll`,
; `control_angle_select_reject_raw_i1_cond.ll`,
; `control_swap_reject_select_badcond.ll`). The predicate is SHARED, so its
; narrowness is pinned across all four consumers and these two are the SELECT's
; share of that pin, not the whole of it.
; NOTE the plain-C route does NOT reach it: `if (q & 1) a -= 3;` gives
; `and`+`icmp` (a COMPARE, which accepts and always did — probe `s19`), so this
; module is deliberately hand-written IR.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %a = select i1 %t, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %o = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %n, %o
  ret i32 %r
}

; CHECK: cq controlled lowering: control flow under quantum control
