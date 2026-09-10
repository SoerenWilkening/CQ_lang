; control_swap_reject_select_rail_round2_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1 — a CONFIRMED
; silent miscompile, plain-C reachable through the shipped two-TU 6.5 recipe;
; the reviewer's probe `ll/e04` verbatim). `%y` is the 6.5 classical-call-arm
; `%out`: CLASSICAL when `classifySelectRegion` asks the §14.3 rail ladder
; (round 1) and TAINTED when `lowerRotations` decides chained-vs-source
; (`Chained = taint.Tainted.count(arg0)`, after `repropagateControlMerges`). In
; that WINDOW `%b` is a SOURCE theta to both closures — `railWireNamesBackward`
; stops at it and `findNonDiagonalWireGate`'s F-1b-1 tainted-parent ancestry does
; not cross — so the sibling `%b3` is off the wire and rung (iii) is clean, while
; the LOWERING puts both siblings in place on ONE rail.
;
; RED ON f8d29e8 (the round-1-fix checkpoint), where it ACCEPTS at exit 0,
; verify-clean and STRICT-stage-2b clean, emitting the select's control read on a
; register BOTH rotations have moved:
;
;   %h_cast = call i32 @cq_template_trunc_i32_to_i1(i32 %out)
;   call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)   <- %b
;   call void @cqrt_ry_i1(i32 %h_cast, double 9.000000e-01)   <- %b3, SAME RAIL
;   %bf = call i32 @cqrt_alloc_i1(i1 false)
;   call void @cqrt_cnot(i32 %h_cast, i32 %bf)                <- the control read
;
; The select's condition is `%b` = Ry(0.5)|x>; the emitted copies are controlled
; on Ry(0.9)Ry(0.5)|x>. A different unitary. The fix is `reverifyRailCondReads`
; (`ArmClassify`, run in BOTH entry points immediately after the round-2 fixpoint
; — the "a stage that runs ONCE has a round-2-FALSE premise" lesson, and the slot
; `deleteGlobalPhases` was moved to for the same reason): every EMITTED rail
; control read is recorded at its emission site and rungs (ii)+(iii) are re-asked
; against it with FINAL taint. The round-1 twin — the same shape with the seed
; tainted at round 1 — is `control_swap_reject_select_rail_stale_sibling_theta.ll`
; and declines with this same string on both binaries; the DISCRIMINATOR that
; this is a re-verification and not a blanket refusal of a classical seed is the
; accept `control_swap_select_rail_round2_opaque_seed_accept.ll`.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %zz
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
