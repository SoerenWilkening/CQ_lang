; control_inplace_ry_reject_stateprep_nonwire_still_collides.ll — DECLINE.
;
; THE DISCRIMINATOR FOR THE 2026-09-11 NARROWING: it excludes the CONDITION'S
; OWN WIRE, not "anything derived from the condition". A register that is pinned
; to the seed but lies OFF that wire still collides and still declines.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; THE SHAPE — the F-R1-1 class, which is SIX CONFIRMED plain-C silent
; miscompiles (drbq Inc-4 round 2), reduced to its minimum:
;
;     %q = @cq_theta_si32(...)      ; the taint root
;     %c = icmp eq %q, 3            ; the branch condition
;     %t = lshr %q, 31              ; a FORWARD user, on a FRESH rail
;     if (%c) { r = 0; cq_theta(&r, .9); }  ; seed 0
;
; On the true edge `%q == 3`, so `%t == 0 == seed`. `%q` itself is pinned to
; `{3}`, which is NOT the seed, so `%q` is not the collider — `%t` is, and `%t`
; is:
;   * not in `condProvenance(%c)` (that cone is BACKWARD from the compare, and
;     `%t` is forward of `%q`), and
;   * not on `%q`'s RAIL either (`lshr` has no in-place ABI, so it mints a fresh
;     rail and `railWireClosure` stops there).
; Out of `CondWire` twice over ⇒ still a collider ⇒ still a decline.
;
; ⚠ RED-GREEN, MEASURED 2026-09-11 ON THE NARROWED BINARY. Moving ONLY the
; off-wire expression — `lshr %q, 31` → `lshr %q, 1`, which is 1 rather than 0
; on the same edge, with the whole condition cone untouched — turns this into an
; ACCEPT (rc 0). So the decline is carried by the off-wire pin alone and this
; file is a discriminator, not a decoration.
;
; WHY IT MATTERS THAT IT STAYS: `%t` is LIVE and MEASURED here. If the narrowing
; reached it, CQ would prepare a THIRD wire while the source rotates the second
; one and then reads it — the exact wrong unitary F-R1-1 found six plain-C
; instances of.
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
  %c = icmp eq i32 %q, 3
  %t = lshr i32 %q, 31
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mt = call i32 @cq_measure_si32(i32 %t)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mt, %mr
  ret i32 %s
}

