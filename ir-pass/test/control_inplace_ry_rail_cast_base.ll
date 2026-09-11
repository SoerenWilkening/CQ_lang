; control_inplace_ry_rail_cast_base.ll — ACCEPT: the ROTATED base is a CAST OF
; THE CONDITION REGISTER (`int rb = (int) b; if (b) rb = cq_theta(rb, .9);`).
;
; It looks like the clobber shape and is not one, and the reason is the rule R4
; is built on: A CAST IS A DIFFERENT PHYSICAL WIRE. Every cast CQ can lower is
; OUT of place — `cq_template_zext_i1_to_i32` mints a FRESH rail holding a
; reversible copy — so `railWireClosure` deliberately does not cross it and the
; intersection R4 computes is genuinely empty. The emitted circuit says the same
; thing: `|b⟩ ⊗ |zext b⟩`, then a controlled Ry on the SECOND rail controlled by
; the first, which is exactly what the source means.
;
; The discriminator is `control_inplace_ry_reject_rail_cond_wire.ll`, whose arm
; rotates the register ITSELF and declines. Two files, one boundary.;
; ⚠ SHARED GROUND, TRUE OF EVERY `control_inplace_ry_rail_*` ACCEPT AND STATED
; ONCE PER FILE RATHER THAN GUESSED (bd test_C_libtooling-l4x4, sub-increment
; l4x4.b; SCOPE §2.1 / §2.7):
;   * THE FLAG IS THE REGISTER. `classifyArms` admits a bare `_Bool` condition
;     (`isCondRailLeaf` — a `cq_theta_i1` result) and `emitInPlaceRotationRegion`
;     sets `Flag = Cond`, so NOTHING IS MINTED (`NOMINT`), NOTHING IS STRIPPED,
;     and the register is NEVER FREED (`FCNT`) — after `Ry(θ)|0⟩` it is not `|0⟩`,
;     so a `cqrt_free` would be a hidden measurement (Rule 6). It is LEFT
;     ALLOCATED, which is the REQUIRED direction: the same Rule-6-safe leak the
;     COMPARE form already gives its own condition register (probe `t11c`).
;   * NO `cqrt_x` ON A USER REGISTER, EVER (`NOX`) — bd `3qlq.4`'s invariant.
;   * THE CONTROL IS ONE QUBIT. `isCondRailLeaf` is a `cq_theta_i1` result, hence
;     a `cqrt_alloc_i1` — exactly the width a minted compare flag has. Nothing
;     about `cqrt_ry_<W>_controlled`'s tensored semantics changes; l4x4.b changes
;     WHO arg-0 is and nothing else.
;   * THE ROTATED RAIL IS FROZEN by `ChainWalk::railCarriesControlledRotation`,
;     which derives it from the emitted gate's own ARG-1 use. ARG-0 — the user's
;     register — is NOT frozen by that predicate and must not be: it is not an
;     in-place gate on it (`isInPlaceGateOn` requires arg-1 == H) and the generic
;     `_controlled` bail refuses it, so `isTerminalHandle` says "not a terminal"
;     and `preservesBasisUnderRecord`'s disqualify list keeps it out of the M-B
;     interior. That asymmetry is the whole disposition of `b` (SCOPE §2.7, H-9).
;   * RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4, which both decline
;     `bare i1 register condition` at `classifyArms`' first gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  %t = trunc i32 %q to i1
  %c = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %rb = zext i1 %c to i32
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rb, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rb, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 2.000000e-01)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i32_to_i1(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[B]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double 9.000000e-01)
;
; ---------------------------------------------------------------------------
; THE NEGATIVES ARE WHOLE-FILE AND PURE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 lesson:
; a POSITIVE directive inside a prefix WINDOWS every negative one of that
; prefix, so every count lives in its own CNT prefix and no `-NOT` shares a
; prefix with a positive). `NOX` is THE NON-NEGOTIABLE: bd `3qlq.4`'s invariant
; is "never a `cqrt_x` on a user register", and the rail path has no ancilla to
; put one on either, so the whole-file form is both stronger and true.
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; NOMINT-NOT: cq_template_icmp
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-1: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
