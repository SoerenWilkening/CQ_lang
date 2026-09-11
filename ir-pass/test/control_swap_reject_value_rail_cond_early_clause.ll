; control_swap_reject_value_rail_cond_early_clause.ll — DECLINE: the VALUE class
; on a bare `_Bool` (rail-root) condition, refused by a VALUE-SPECIFIC clause
; ABOVE the §2.6 per-class re-decline, so the string is `value-arm swap-route`
; and NOT `bare i1 register condition`.
;
; *** ROUND-1 RULE-13 REVIEW FINDING F-5 (bd `test_C_libtooling-l4x4`,
; sub-increment l4x4.b), and it is a COVERAGE fix, not a behaviour change. ***
; `SCOPE_l4x4.md` §2.6's partition table lists one disposition per arm class and
; reads as though the VALUE row always answers `kBareRailCondReason`. It does
; not: `classifyArms` asks several value-specific questions BEFORE the §2.6
; re-decline, and a rail region that trips one of them exits there. The row has
; TWO exits and this file pins the one `control_swap_reject_value_rail_cond.ll`
; does not.
;
; PLAIN C AT `-O1`, `review_l4x4b_r1_probes`-adjacent probe `t16_i1_stateprep`:
;
;     _Bool b = 0, r = 0;  b = cq_theta(b, 0.5);
;     if (b) { r = cq_theta(0, 0.9); }
;     return (int)cq_measure(b) + (int)cq_measure(r);
;
; `cq_theta(0, 0.9)` binds the `int` overload, so `-O1` leaves an `icmp ne i32
; %t, 0` in the arm as the merge phi's incoming. That `icmp` is a VALUE-CHANGING
; op the value chain walk does not consume, so the arm bottoms at it and
; `classifyArms` declines `value-arm swap-route` (`ArmClassify.cpp`, the
; `isValueChangingOp(Base)` clause; the `Clobber` half does not apply — the
; straight-through is the constant `false`, which is not in the condition's
; provenance). MEASURED: rc=1 with exactly that string.
;
; WHY IT IS STILL CORRECT, AND WHY THE OTHER FIXTURE IS STILL NEEDED. Both exits
; are LOUD and both refuse the class bd `fg9k` (1b-B.2b) owns, which is all §2.6
; requires. The difference matters to a READER: a future `fg9k` reviewer looking
; for "where does a rail value arm die?" will find `bare i1 register condition`
; in one fixture, this string in another, and — without this file — would
; conclude the second is a hole. `control_swap_reject_value_rail_cond.ll` (hand
; IR, a genuine `add`-chain value arm) is the `kBareRailCondReason` exit; this
; one is the early-clause exit; neither subsumes the other.
;
; ⚠ GREEN ON THE l4x4.b CHECKPOINT 267937d TOO, AND THAT IS CORRECT: F-5 is a
; COVERAGE finding, not a behaviour one. Nothing in the round-1 fix moved this
; module's disposition (measured on both binaries: `value-arm swap-route`, rc=1);
; what was missing was a fixture SAYING so, next to a SCOPE table that implied
; otherwise. Red on `main` 0c7380c and the F2 checkpoint 578dbc4 — but it is the
; weak kind of red: those binaries decline this module at `classifyArms`' FIRST
; GATE with `bare i1 register condition`, i.e. with a DIFFERENT string from a
; DIFFERENT layer, so neither can witness the clause this file names. The
; discriminating mutation is recorded instead:
; delete the `isValueChangingOp(Base)` clause's `declineArm` and the region falls
; through to the §2.6 re-decline, flipping this file's string to
; `bare i1 register condition` — which is exactly the confusion the file exists
; to prevent.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative
; here would be VACUOUS; the `not` INVERSION on the RUN line plus the string
; below (mirrored character-for-character against `ir-pass/src`) are what pin
; "no silent lowering".
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: value-arm swap-route under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i32 @slice() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %arm, label %merge

arm:
  %t = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  %tb = icmp ne i32 %t, 0
  br label %merge

merge:
  %rm = phi i1 [ %tb, %arm ], [ false, %entry ]
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %zr = zext i1 %mr to i32
  %s  = add i32 %zr, %zb
  ret i32 %s
}
