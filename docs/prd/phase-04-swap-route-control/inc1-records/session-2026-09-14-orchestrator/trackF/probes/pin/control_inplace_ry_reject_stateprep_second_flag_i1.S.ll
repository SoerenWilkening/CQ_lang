; control_inplace_ry_reject_stateprep_second_flag_i1.ll — DECLINE.
;
; THE `i1` RESIDUAL THE 2026-09-11 RULING KEEPS (SCOPE H-7), and the reason the
; ruling must be phrased *"the `i1` width is no longer CATEGORICALLY out"* and
; never *"`i1` is in"*.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; THE SHAPE:
;
;     %q = cq_theta(%u0, .5)
;     %d = icmp sgt %q, 7          ; an INDEPENDENT tainted i1 — live, measured
;     %c = icmp sgt %q, 100        ; the branch condition
;     if (%c) r = cq_theta(i1 true, .9);
;
; On the true edge `q > 100`, so `%d` is pinned to `{true}` — which is the seed.
; `%d` is a FORWARD user of `%q`, not a member of `condProvenance(%c) = {%q}`
; and not on `%q`'s rail (an `icmp` mints a fresh rail), so it is NOT in
; `CondWire` and it still collides. The source this module is `-O1`'s image of
; could have been `r = cq_theta(d, .9)` — an in-place Ry on the SECOND flag's
; rail, which is live and measured here — and that is a different unitary from
; preparing a third wire.
;
; ⚠ RED-GREEN, MEASURED 2026-09-11 ON THE NARROWED BINARY. Moving ONLY the
; off-wire compare — `icmp sgt %q, 7` → `icmp sgt %q, 200`, so that it is no
; longer determined on the branch's edge, with the branch condition and its cone
; untouched — turns this into an ACCEPT (rc 0). The decline is carried by `%d`
; alone.
;
; CONTRAST, and it is one token wide:
; `control_inplace_ry_stateprep_bool_seed_int_cond.ll` is the same `i1`-seed
; question with the pinning `i1` being the branch's OWN condition, and it
; ACCEPTS. One `i1` on the wire, one off it, opposite dispositions — which is
; what "the narrowing is the wire" means at this width.
;
; ⚠ RETIREMENT TRIGGER — bd `test_C_libtooling-rb9x`, increment R-1 (2026-09-13).
; R-1 added a SECOND exclusion at the same test: `MergePhiPeel`'s compare CLONES
; (`TaintSet::PeelClones`), on the PREIMAGE ground — a value the compiler
; manufactured has no source program behind it. **THIS FILE STILL DECLINES —
; MEASURED 2026-09-13 on the R-1 binary, same string, same anchor** — because
; `%d` is USER code: the author wrote it, the rival `r = cq_theta(%d, .9)` is a
; well-formed program, and R-1's ground does not reach it. So the residual this
; file pins is now TWO-SIDED: an `i1` seed still collides with a tainted `i1`
; that is neither on the branch's wire NOR compiler-manufactured. ⚠ The
; NEAR trigger is bd `rb9x`'s follow-on R-2 (`SCOPE_R.md` §2), which would exclude
; a pinned value that is used as the condition of a conditional `br`: `%d` here is
; MEASURED and never branched on, so R-2 as scoped leaves this file declining —
; if a future R-2 spelling turns it green, that spelling has widened past its own
; argument and must be re-derived, not blessed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ THE IR-TEXT `CHECK-NOT`s BELOW ARE VACUOUS BY CONSTRUCTION and are
; kept only as documentation: a `DS_Error` decline writes ZERO bytes to
; stdout, so `2>&1 | FileCheck` sees the diagnostic and nothing else.
; The property they describe — no gate is emitted — is pinned by the
; `not` inversion on the RUN line above, which is what actually fails
; if this module ever lowers.
; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled


declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = icmp sgt i32 %q, 7
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  %md = call i1 @cq_measure_i1(i1 %d)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %md to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}

