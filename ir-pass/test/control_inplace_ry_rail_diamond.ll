; control_inplace_ry_rail_diamond.ll — ACCEPT: THE FLAGSHIP SHAPE of bd
; test_C_libtooling-l4x4 sub-increment l4x4.b — the in-place controlled-Ry arm on
; a bare `_Bool` (rail-root) condition, `if (b) r = cq_theta(r, .9);` with `r`'s
; physical wire disjoint from `b`'s (probe `t1`).
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_raw_i1_cond.ll` AND ITS IR IS
; BYTE-UNCHANGED — only the RUN line, the assertions and this header moved
; (`git mv`, the 3qlq.4 / r9e5 precedent). That matters: the module below is
; exactly the one the drbq Inc-1 and 3qlq.4 reviews argued over, so "the same
; program now lowers" is a statement about the compiler and not about a rewritten
; test. Its own header PREDICTED this flip — *"Controlling on it directly is a
; real (3-gate cheaper) capability and is DEFERRED … it is NOT a physics wall"* —
; and the prediction is measured: the emitted stream is the compare twin's
; (`slice_control_inplace_ry_diamond`) MINUS the mint, MINUS the strip, MINUS the
; free, with `%h_cmp` replaced by the register itself. Three deletions and one
; rename.
;
; ---- HISTORY (the decline this file used to pin, kept verbatim) ------------
; control_inplace_ry_reject_raw_i1_cond.ll — DECLINE: control on a RAW i1 QUBIT,
; with no compare to mint a flag from (PRD shape S4, owner Q6 deferred; bd
; test_C_libtooling-drbq §8).
;
;     _Bool c = cq_theta((_Bool)0, 1.1); int r = cq_theta(0,.3);
;     if (c) r = cq_theta(r, .9);
;
; Every accepted tainted-control region in this compiler mints its flag AT A
; COMPARE (`cq_template_icmp_<pred>_<W>_hl`) and strips it with that compare's
; `_unc`. A bare `br i1 %theta` has no compare, so there is nothing to mint and
; nothing to strip — the register IS the control. Controlling on it directly is a
; real (3-gate cheaper) capability and is DEFERRED with its own PRD; it is NOT a
; physics wall. The `cq_phi` twin of this source declines identically today, which
; is why the deferral costs nothing this increment.
;
; Transcribed from `clang -O1`. This fixture exists to pin that the new
; rotation-arm clause did not accidentally claim the shape: the classifier's very
; first gate is `isa<CmpInst>(Region.Condition)`, unchanged.
;
; ⚠ SINCE bd test_C_libtooling-3qlq.4 (Inc 1b, 2026-09-10) TWO SENTENCES ABOVE
; ARE HISTORY, and this file is the 1b-C FLIP TARGET (bd test_C_libtooling-l4x4).
; (i) "The `cq_phi` twin of this source declines identically today" is FALSE:
; `_Bool c = cq_theta(…); if (c) cq_phi(θ)` now LOWERS — the register is its own
; flag and the kickback rides its rail (`control_phase_kickback_rail_diamond.ll`).
; (ii) The string is no longer the generic `control flow`: `classifyArms`' first
; gate names a bare `_Bool` register condition with `bare i1 register condition`
; (`kBareRailCondReason`, SelectClassify.h — the ONE string every not-yet-lowered
; rail consumer shares, so each follow-on flips its own fixture and no other).
; The DISPOSITION is unchanged: the in-place controlled-Ry arm on a rail
; condition still declines, and still before any emission.
;
; (the old RUN line and its decline assertions are dropped from this
;  quotation: lit and FileCheck match their prefixes as substrings
;  anywhere on a line, so quoting one would make it LIVE again.);
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
  %c = call i1 @cq_theta_i1(i1 false, double 1.100000e+00)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 1.100000e+00)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
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
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
