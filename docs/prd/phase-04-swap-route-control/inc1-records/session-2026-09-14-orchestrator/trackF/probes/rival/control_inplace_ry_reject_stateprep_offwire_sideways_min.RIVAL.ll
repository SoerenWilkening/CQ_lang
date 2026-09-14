; control_inplace_ry_reject_stateprep_offwire_sideways_min.ll — DECLINE.
;
; THE **SIDEWAYS** DISCRIMINATOR, minimised. The F-R3-1 class (drbq Inc-4 round
; 3, THIRTY plain-C confirmed silent miscompiles) is the one where `-O1` moves
; the compare neither DOWN onto an ancestor nor UP onto a user but SIDEWAYS onto
; a SIBLING, so no walk in either direction from the condition can reach the
; rotated register.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; THE SHAPE — `if (q / 4 == 5) r = cq_theta(<q/4>, .9);` after InstCombine:
;
;     %o = and %q, -4              ; what `-O1` rewrites `q/4 == 5` ONTO
;     %c = icmp eq %o, 20
;     %t = sdiv %q, 4              ; THE SIBLING — live and measured
;     if (%c) r = cq_theta(5, .9); ; seed 5
;
; On that edge `q ∈ [20,24)`, so `%t == 5 == seed`, while `%o` is pinned to
; `{20}` (≠ seed) and `%q` to a four-element range (no singleton). So the ONLY
; collider is `%t`, and `%t` is in neither `condProvenance(%c) = {%o, %q}` nor
; any rail closure of them (`and` and `sdiv` both mint fresh rails). It stays
; out of `CondWire` and it stays a decline.
;
; ⚠ RED-GREEN, MEASURED 2026-09-11 ON THE NARROWED BINARY. Moving ONLY the
; sibling — `sdiv %q, 4` → `sdiv %q, 7`, whose value on the same edge is `{2,3}`
; and therefore not a singleton — turns this into an ACCEPT (rc 0).
;
; THIS IS THE MINIMAL COMPANION to `..._sideways_sdiv.ll`,
; `..._sideways_offset.ll` and `..._merge_edge_sideways.ll`, all three of which
; also still decline. It exists because a class this expensive to rediscover
; deserves a fixture small enough to read in one screen.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ THE IR-TEXT `CHECK-NOT`s BELOW ARE VACUOUS BY CONSTRUCTION and are
; kept only as documentation: a `DS_Error` decline writes ZERO bytes to
; stdout, so `2>&1 | FileCheck` sees the diagnostic and nothing else.
; The property they describe — no gate is emitted — is pinned by the
; `not` inversion on the RUN line above, which is what actually fails
; if this module ever lowers.
; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled


declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %o = and i32 %q, -4
  %c = icmp eq i32 %o, 20
  %t = sdiv i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %mt = call i32 @cq_measure_si32(i32 %t)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mt, %mr
  ret i32 %s
}

