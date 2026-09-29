// AngleSelectEmit.h — ANGLE-SELECT BY DIFFERENCE (control-in-place-PRD §12.3,
// bd test_C_libtooling-drbq Increment 2b). BOTH rotation stems.
//
// Dispatched from `SwapRouteEmit::lowerControlRegions` on
// `R.Kind == AngleSelectRegion`, which `ArmClassify::classifyAngleSelect` pushes
// (via `SelectClassify`'s gate 3). Runs AFTER detection and BEFORE
// `lowerRotations`, exactly like every other Phase-4 emitter.
//
// THE INPUT, which is what `clang -O1` makes of the C the user writes — and WHICH
// C that is CHANGED on 2026-09-28 (bd test_C_libtooling-fmt3, owner ruling,
// option B), so read both halves:
//   * Ry STEM (`cq_theta`): `include/CQ.h` puts `nomerge` on every `cq_theta_*`,
//     so the if/else `if (q == 5) r = cq_theta(r, A); else r = cq_theta(r, B);`
//     is NO LONGER merged into one call — it stays an if/else and lowers through
//     the in-place Ry arm (two controlled Ry, the same unitary). The C spelling
//     that reaches THIS emitter is the select written out:
//     `r = cq_theta(r, (q == 5) ? A : B);` — measured to hand the pass the same
//     function bodies the old fold did (`slice_control_angle_select_ry*_ternary.c`,
//     whose goldens are the pre-fmt3 ones byte for byte). Hand IR reaches it as
//     before (the `control_angle_select_*.ll` fixtures).
//   * Rz STEM (`cq_phi`): unchanged — `cq_phi` carries no `nomerge`, so
//     `if (c) cq_phi(A); else cq_phi(B);` is still merged into ONE call with a
//     `select` on the ANGLE and the branch CFG is gone before the pass runs
//     (Rule 9).
// The sentence that stood here said the Ry-stem if/else is ALWAYS merged; since
// fmt3 that is false, and it is corrected here rather than only in a record (L7).
//
//     %c = icmp eq i32 %q, 5
//     %a = select i1 %c, double A, double B            ; A, B CLASSICAL
//                                                      ; CONSTANTS — `ConstantFP`
//                                                      ; both; see the run-time
//                                                      ; paragraph below
//     %t = call i32 @cq_theta_si32(i32 %r, double %a)  ; %r TAINTED, %a only arg-1
//
// THE OUTPUT — four emitted CALLS and one rewire, all positional around `%t`.
// The difference ALWAYS folds (both arms are `ConstantFP` by the accept
// predicate), so no `fsub` instruction is emitted at all:
//
//     %t0 = call i32 @cq_theta_si32(i32 %r, double B)  ; NEW unconditional twin
//     %f  = cq_template_icmp_eq_i32_hl(i32 %q, i32 5)  ; flag mint
//     %t  = call i32 @cq_theta_si32(i32 %t0, double A−B) ; REWIRED, recorded in
//                                                       ; taint.ControlledRotations
//     cq_template_icmp_eq_i32_hl_unc(i32 %f, i32 %q, i32 5)  ; flag strip
//     cqrt_free(i32 %f)
//
// `lowerRotations` then mints `cqrt_ry_<W>(h, B)` for the twin and
// `cqrt_ry_<W>_controlled(f, h, A−B)` for the recorded consumer (the drbq Inc-1
// path for `cq_theta`, the Inc-2a path for `cq_phi` — NEITHER is changed here).
//
// WHY THIS IS EXACT IN REAL ARITHMETIC: angle additivity on ONE axis.
// `Ry(A) = Ry(B)·Ry(A−B)`, and under this project's `Rz = diag(1, e^{iθ})`
// convention `Rz(A) = Rz(B)·Rz(A−B)` entrywise, so there is no global-phase
// residue either. `f = 0` leaves `R(B)`; `f = 1` composes to `R(A)`. There is NO
// polarity case at all — `select %c, A, B` always means "A when the flag is 1" —
// so a `!=` source (which `clang` canonicalizes to `icmp eq` with the select
// operands SWAPPED) needs nothing special and no `cqrt_x` bracket ever appears in
// this stream.
//
// AND IN IEEE DOUBLE IT IS EXACT UP TO ONE ROUNDING, WHICH IS NOT THE SAME THING
// (bd drbq Inc 2b round-1 Rule-13 review, lens L7-F1). The emitted true-arm angle
// is `B + fl(A−B)`, so the error is `|delta| <= 1/2 ulp(A−B) ~ |A−B|·2^-53`:
// 2^-54 rad on the flagship `0.9 / 0.3` golden — physically nothing, and it IS
// the shape this increment exists for — but 0.858 rad on `pi / 1e16` and a full
// 1.0 rad on `1.0 / 1e300`. CONSTANT arms are fenced at detection
// (`angleSelectArmsAdmissible`, placeholder bound 2^-40 rad) and re-asked here.
//
// RUN-TIME ARMS DECLINE — THE ACCEPT CLASS IS CONSTANT ARMS ONLY (Rule-13
// CLEARANCE review, finding F-11 / ranked blocker B1, graded
// CONFIRMED-MISCOMPILE and BLOCKING; orchestrator decision on that verdict: ship
// owner option (2)). Two earlier wordings here said run-time arms were accepted
// and carried a residual — round-1 called it "the bound", round-2 corrected that
// to both halves. Those halves are now the REASON for the refusal rather than a
// shipped residual:
//   (i)  the ROUNDING residual `|delta| <= 1/2 ulp(A−B)`, which bounds the
//        DIFFERENCE and is UNBOUNDED in absolute radians — measured 0.858 rad
//        from plain C with `A = pi`, `B = 1e16` as run-time angles (the realized
//        true-arm angle is 4.0 rad for a source that wrote `Ry(pi)`); AND
//   (ii) a NON-FINITE `fl(A−B)` FROM TWO FINITE ARMS — measured
//        `cqrt_ry_i32_controlled(f, h, inf)` from plain C with
//        `A = 8.98846567431158e307`, `B = −A`. Half an ulp does not describe
//        `inf`; it is a separate failure and must not be folded into "the bound".
// Neither is fenceable at compile time, which under the Prime Directive is a
// reason to DECLINE: the precondition is DISPROVEN on reachable plain-C inputs,
// and the pre-2b binary refused every one of them loudly with this same
// `rotation angle under quantum control` string (re-measured byte-identical).
// The mitigation the earlier disposition rested on — "it is the same arithmetic
// the manual by-difference twin performs" — is true of the ARITHMETIC and false
// of any PROGRAM CQ compiles: that twin, with run-time arms, DECLINES on BOTH
// binaries because `clang -O1` sinks the `fsub` into the arm block
// (clearance observation 1). So this class was reachable only through 2b.
// Widening back is owner option (1), ONE line at `angleSelectArmsAdmissible`
// clause (2c); option (3), the two-controlled form, retires both halves outright
// and performs no subtraction at all (notes §9's three-way item, §11's record).
//
// WHY THIS EMISSION ORDER AND NO OTHER: with the unconditional twin emitted
// BEFORE the mint, the stream is BYTE-IDENTICAL to the MANUAL by-difference twin
//     r = cq_theta(r, B); if (q == 5) r = cq_theta(r, A − B);
// which is an ordinary in-place DIAMOND that the PRE-2b binary already lowers.
// That byte identity — not a fresh unitary argument — is this increment's
// central witness, and it is checked at the e2e layer by a `compare_files` gate
// per stem (`e2e-angle-select-*-twin-identical`).
//
// WHY THE `cq_theta` SPELLING AND NOT `cqrt_ry_<W>` DIRECTLY: the register is
// still a `cq_*` SSA value at this point (for an f64 register it is
// `double`-typed, so a direct `cqrt_*` call would be ill-typed), and every
// PRE-`lowerRotations` wire walker recognizes a gate by the `@cq_theta_`/
// `@cq_phi_` spelling with the wire at arg 0 (PRD §6, the hoist-and-defer
// rationale). Emitting the twin as a real rotation call means those walkers keep
// seeing an in-place gate where one will fire.
//
// NO CFG surgery, NO hoist, NO `RegionFlatten`, NO `cqrt_x`, NO `cqrt_alloc`, NO
// `cqrt_cswap`, NO reverse-play. The only rails are the user's own register and
// the one flag.
//
// Correctness rests on analytic reasoning plus the twin byte-diff, NOT on
// `opt -verify` (Rule 2). Mutates the module IR and `taint`.

#ifndef CQ_IRPASS_ANGLE_SELECT_EMIT_H_
#define CQ_IRPASS_ANGLE_SELECT_EMIT_H_

namespace cq {

class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Lower one accepted `AngleSelectRegion`. Every DECLINE is LOUD
// (`diagnoseUnderControl`) and every DECLINE precedes the FIRST emitted
// instruction — a silently skipped accepted region would leave the tainted
// select to the backend as classical control over quantum state (Rule 1), and a
// half-emitted region is the 2a round-1 F-5 defect class.
//
// *** THAT SENTENCE WAS FALSE AS SHIPPED, AND THE REPAIR IS WHAT MAKES IT TRUE
// *** (bd drbq Inc 2b ROUND-1 RULE-13 review, lenses L4-1 and L1-1). Step 0
// re-validated the plan by SSA IDENTITY only; S4's SEMANTIC question — exactly
// one TAINTED compare operand, and a mintable flag — was proven at DETECTION and
// never re-asked. A preceding `SwitchDataMux` region in the same
// `lowerControlRegions` loop RAUWs its merge phi to a freshly minted TAINTED
// rail, which turns the angle select's compare Q+Q; steps 1–2 then emitted the
// `fsub` and the unconditional twin before step 3 bailed MID-STREAM. Step 0b now
// re-asks S4 in lockstep BEFORE the first `CreateFSub`. The two remaining
// `return`s (steps 3 and 5) are UNREACHABLE, not bails — see their comments —
// and they are unreachable by that re-ask AND by `DS_Error` calling `exit(1)`,
// which are two independent reasons.
//
// The plan is re-validated by SSA identity before anything is mutated.
void emitAngleSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                           TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ANGLE_SELECT_EMIT_H_
