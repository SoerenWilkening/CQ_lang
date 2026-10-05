// RotationLowering.cpp — Lower tainted `@cq_theta_<sfx>` rotations to runtime
// calls (the retired `@cq_phi_<sfx>` loop is deleted, see `lowerRotations`). See
// header for the contract; backend.md §5.1 for the operand-dispatch table and
// IMPLEMENTATION.md §1 for the cross-type-RAUW invariant. Single pass over the
// collected `taint.ThetaCalls` (from `propagate`; `taint.PhiCalls` is
// permanently empty since 3qlq); no module re-walk.

#include "RotationLowering.h"

#include "DeadValueLiveness.h"  // isRecordedDeadSlot (bd vsfp r3: the ONE "slot unread")

#include "ControlPlan.h"
#include "ControlledSymbols.h"
#include "LiteralIntegrity.h"  // valueCarriesUndef (bd z9t1 — the ONE spelling)
#include "OpcodeSupport.h"  // abiWidthFromType
#include "RailBankPromote.h"  // isRailBankSeedAlloc
#include "TaintPropagation.h"
#include "WidthDispatch.h"
#include "WireWalk.h"  // provablyBefore (the shared position-aware proof)

#include <cassert>

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <optional>
#include <string>
#include <utility>
#include <vector>

using namespace llvm;

namespace cq {

// Strip a known prefix (`cq_theta_` / `cq_phi_`) from the call's callee
// name → suffix (`si32`). Returns "" on mismatch (callee absent or name
// doesn't start with the prefix).
//
// DE-ANONYMIZED (bd drbq Inc 2b) so `classifyAngleSelect` can ask the MINT's own
// width expression rather than a second spelling of it — see the header. PURE
// REFACTOR: only the linkage changed (anonymous → named `cq`).
StringRef suffixFromName(const CallInst *CI, StringRef Prefix) {
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return {};
  StringRef N = Callee->getName();
  if (!N.starts_with(Prefix))
    return {};
  return N.substr(Prefix.size());
}

// ─── bd z9t1 — THE UNDEF SEED IS A ZERO AT THE ALLOCATION ───────────────────
//
// OWNER RULING 2026-09-14, verbatim: *"we should NOT make every uninitialized
// variable to 0. Jut before it hits cq_alloc_*. then clang still can exploid
// it"* and *"both codes are supposed to compie!! also no warnings."*
//
// So the rule attaches to the QUBIT ALLOCATION, never to the C variable. An
// `undef`/`poison` SEED reaching a SOURCE `@cq_theta_<sfx>`'s arg-0 becomes a
// concrete zero of that type; CQ makes NO claim about the object the seed was
// read from, and `clang` keeps every liberty it already had — including deleting
// a branch that reads the same uninitialized value, which is MEASURED and
// documented rather than fenced (DIAG_2026-09-14.md Q2 row iv: an uninitialized
// `int` in a guard makes the guard vanish before this pass ever runs).
//
// *** THIS IS A TIGHTENING, NOT A LOOSENING, AND THE DIRECTION MATTERS. ***
// Before the rule, `bool b; cq_theta(&b,.5);` compiled SILENTLY and handed
// `i1 undef` to `cqrt_alloc_i1`, so which basis state the rail started in was
// whatever the `-O0` stage-3 link materialised — the trace printed
// `cqrt_alloc_i1(1)`, a value the program never wrote. After it, the rail is
// deterministically |0> and every reader of the emitted module sees ONE
// constant: the `declineUnpairedUndefLiterals` multi-materialisation hazard
// (LiteralIntegrity.h GUARD 1) is REMOVED from this path, not created.
//
// ── WHY THE PREDICATE AND THE ACTION ARE TWO DIFFERENT QUESTIONS ───────────
//
// The question "is this literal an undef?" has exactly ONE owner in this pass,
// `valueCarriesUndef` (LiteralIntegrity.h), and Rule 14 says to CALL it rather
// than re-spell it — so it is the gate below. But its answer is TRUE for a
// `ConstantExpr` that merely CONTAINS an undef leaf, and for that shape the
// ACTION would be unsound:
//
//   * replacing a WHOLE-VALUE `undef`/`poison` with zero is a REFINEMENT —
//     LangRef lets any value of the type stand in, so the emitted circuit is one
//     the source already licensed. This is the ruled case.
//   * replacing an EXPRESSION with zero is NOT. `ptrtoint (gep @g, undef, 1)`
//     denotes an address; no choice of the leaf makes that address 0, so
//     rewriting it would be a silent VALUE CHANGE — the one unforgivable
//     direction (Prime Directive). And the ruling's own justification does not
//     reach it: a `ConstantExpr` is UNIQUED into ONE link-time relocation (bd
//     bu96), so it has no multi-materialisation hazard for the rule to remove.
//
// Note the SAFETY POLARITY FLIPS relative to every other caller of that
// predicate. Everywhere else it gates a DECLINE, where over-firing is safe;
// here it gates a REWRITE, where over-firing is a miscompile. That is why the
// action carries its own `isa<UndefValue>` conjunct instead of trusting the
// shared predicate alone, and why the conjunct has its own negative fixture
// (`control_inplace_ry_reject_stateprep_constexpr_undef_seed.ll`, whose seed
// makes `valueCarriesUndef` true and must NOT be normalized).
//
// ── THE MOTIVATION IS "ONE OBJECT, READ TWICE"; THE SCOPE IS WIDER ─────────
//
// MEASURED, not predicted (`$SES/trackU/probes/u2.c`): for the second ruled
// spelling `bool b1; if (c) cq_theta(&b1,.5);`, `clang -O1` writes the SAME
// uninitialized object twice —
//
//     %3 = call i1 @cq_theta_i1(i1 undef, double 5.0e-01)   ; the SEED
//     %6 = phi i1 [ %3, %2 ], [ undef, %0 ]                 ; the MERGE INCOMING
//
// — and normalizing only the seed leaves F1's SECOND sub-clause (the Pred
// incoming must be POINTER-IDENTICAL to the seed, `ArmClassify.cpp:3905-3908`)
// comparing `i1 false` against `undef`, so the module STILL declines with the
// same string and the ruling's clause 2 ("both spellings compile") is not met.
// That is WHY the phi incomings move. It is a MOTIVATION, not a precondition,
// and the next paragraph exists because the two were once written as if they
// were the same sentence.
//
// ── THE ACTUAL SCOPE, AND IT IS A SUPERSET — MEASURED ──────────────────────
//
// ⚠ CORRECTED. This paragraph read, for two review rounds: "A phi incoming is
// normalized ONLY when that phi carries THIS theta's result as another incoming
// — i.e. only where the object was undefined on BOTH edges." The clause before
// the dash IS what the code asks. *** THE "i.e." IS FALSE ***, it was found by
// review round 2 (F-U2-2), it did not land, and review round 3 (F-U3-2)
// measured it wronger than round 2 had: the "i.e." describes a rule whose
// population is about FOUR modules; the shipped clause's is 164.
//
// The code asks the first half ALONE — `for (User *U : Theta->users())`, then
// EVERY `UndefValue` incoming of every phi user. That is wider than "one object
// read twice" in THREE independent directions, each measured over the 711
// corpus modules that contain a phi carrying a `@cq_theta_*` result
// (`$SES/trackU/review_r3_probes/census_main.json`; re-derived independently by
// the fix round):
//
//   1. SEVERAL PHIS PER THETA — the walk is over every phi USER, not the
//      region's merge phi. **164 of the 972 carried thetas are carried by MORE
//      THAN ONE phi**, and every undef incoming of every one of them is
//      rewritten (probe `pL_second_unrelated_phi`).
//   2. SEVERAL INCOMINGS PER PHI — the inner loop rewrites EVERY undef
//      incoming, not the Pred edge. **37 phis in that corpus have >= 2
//      non-theta incomings**, so ONE visit can equate SEVERAL DISTINCT C
//      OBJECTS (probe `pA_three_edges`).
//   3. A DIFFERENT OBJECT ENTIRELY — the seed's object and the straight-through
//      incoming's object need not be the same one. Nothing in the source
//      equates them; the rule equates them anyway (probe `pD_two_objects`,
//      which moves D→A on that ground alone). ⇒ THE DISCLOSURE, below.
//
// POPULATION, isolated against a seed-only oracle (SUBJECT(undef seed + undef
// phi) vs ORACLE(zero seed + undef phi), 710 measurable modules): **164 modules
// move** — 124 decline→accept, 39 decline-string changes, 1 IR-only. All 164
// land BYTE-IDENTICALLY on the zero twin (0 divergences), which is why this is
// a SCOPE CORRECTION and not a defect.
//
// ⚠ TWO DIFFERENT 164s, AND THEY ARE EQUAL BY COINCIDENCE. "164 of 972 carried
// thetas" (direction 1) is a COUNT OF THETAS; "164 modules" is the phi half's
// module population. Different instruments, different denominators. *** DO NOT
// CITE ONE AS EVIDENCE FOR THE OTHER. ***
//
// THE SOUNDNESS GROUND IS NOT THE SCOPE — IT IS THE PER-REWRITE REFINEMENT.
// Every rewrite is `isa<UndefValue>(In)` → `Constant::getNullValue(T)`, and
// LangRef lets any value of the type stand at an `undef`, so each one
// INDEPENDENTLY yields a circuit the source already licensed. The clause cannot
// turn a DEFINED value into a different one: the `isa<UndefValue>` test is
// literal and the `ConstantExpr` residual is excluded by its own conjunct
// above. That argument never needed the "i.e.", which is why removing it costs
// nothing.
//
// WHY THE SHIPPED DECLINE FIXTURES STAY GREEN — the TRUE reasons, one each,
// because the false "i.e." was carrying this weight and could not:
//   * `control_inplace_ry_reject_stateprep_undef_incoming.ll`: its SEED is
//     `i32 0`, so this function returns at the `valueCarriesUndef` gate and the
//     phi loop NEVER RUNS (round-1 F-U1-2 re-grounding, measured on both
//     binaries, full-stderr sha `0af03bddc2cc` on each).
//   * `control_peel_reject_{undef,poison}_incoming.ll` (`MergePhiPeel` P3b):
//     the undef-bearing phi there is `%6 = phi i32 [ 5, %3 ], [ undef, %0 ]`,
//     which DOES NOT CARRY A THETA — and the theta-carrying phi in the same
//     module (`%7`) has no undef incoming. The two shapes simply miss each
//     other; nothing about the scope narrows. RETIREMENT TRIGGER in both
//     headers.
//
// ── THE P3b INTERACTION, WHICH IS REAL AND WAS UNRECORDED ──────────────────
//
// Make that phi CARRY the theta and `MergePhiPeel`'s P3b stops firing: the
// incoming is a concrete `i32 0` by the time the peel looks, so the peel
// proceeds and the module reaches F2 instead (measured on both binaries, probes
// `pC_p3b_carrier` / `pA_peel_p3b`; the zero twin is IDENTICAL). *** THAT IS
// SOUND, AND THE REASON IS P3b'S OWN. *** P3b's hazard is a literal read as TWO
// DIFFERENT VALUES at the `-O0` stage-3 link; a uniqued `i32 0` is
// single-valued, which is the same ground `MergePhiPeel.cpp` already gives for
// peeling a `freeze`. So the disarm and the removal of the hazard are the SAME
// EVENT — and that is the test to apply to any other undef-keyed gate this
// clause reaches (`PredMuxFlatten::classifyConeNode`'s leaf `Fail`,
// `QramLowering`'s `convertPhis` mirror: both pass it). ⚠ `GUARD 1`
// (`declineUnpairedUndefLiterals`) is the ONE gate that FAILS that test,
// because it is a COUNTING gate over a population this clause only PARTIALLY
// empties — that is F-U1-1, it is OPEN WITH THE OWNER, and it is stated below.
//
// ── ⚠ DISCLOSURE — WHAT THIS RULE SILENTLY ABSORBS ────────────────────────
//
// *** IN THE WORDS CLAUDE.md §4 INSISTS ON, BECAUSE THIS IS THE SAME CLASS OF
//     SILENT WIDENING AS THE F2 α/β NARROWING AND IT OWES THE SAME PARAGRAPH.
//     (Review round 3, F-U3-3. The normative copy is `$SES/trackU/IMPL_U.md`
//     §2(b′); this is the same text at the mechanism.) ***
//
// 136 modules that the ORACLE loudly REFUSED now compile SILENTLY, and 116 of
// them move through ONE mechanism: **F1's pointer-identity proof is
// MANUFACTURED, not found.** F1's second sub-clause is a literal `Value*`
// comparison — `MergePhi->getIncomingValue(PredIdx) != RotBase`
// (`ArmClassify.cpp:3905-3908`) — and `Constant::getNullValue` is UNIQUED, so
// rewriting a seed `undef` and a straight-through `undef` to "the type's zero"
// makes them THE SAME `Value*`, for two operands the source never equated. The
// other 20: 14 `control flow` (the `MergePhiPeel` P3b route above), 4
// `cq_measure_<sfx> operand is an undef/poison literal` (the ruled clause-4
// decline reached UPSTREAM of the sink — F-U3-1, OPEN WITH THE OWNER, NOT
// covered by this paragraph), 1 `condition predates a non-diagonal gate`, 1
// `nested control flow`.
//
// THE RIVAL READING, AS A PROGRAM AND NOT AS AN IR SHAPE: the seed and the
// merge's straight-through incoming were TWO DIFFERENT uninitialized C objects,
// and the source never said they were equal. `pD_two_objects` is the minimal
// witness — the prep seeds from object X, the straight-through edge carries
// object Y, and it moves D→A. The compiler now treats them as ONE VALUE at the
// state-prep proof.
//
// WHY THE RIVAL HAS NO LOWERING TO BE ROBBED OF — the two halves, because
// either alone would be an assertion. (1) On the oracle the two-object module
// is a LOUD DECLINE, so there was no circuit for the other reading and nothing
// is displaced. (2) The accept it now receives is a REFINEMENT, not a choice
// between two circuits: LangRef lets an `undef` stand for any value of its
// type, so `0` at each read is a value the source ALREADY LICENSED, and the
// emitted stream is BYTE-IDENTICAL to what a written `= 0` on both objects
// produces — measured on all 164 modules of the phi half's population, 0
// divergences, 0 `A→D`. On the ¬flag component the fresh rail holds |0>, which
// is a value object Y was permitted to have. No fence is deceived about a value
// the program actually WROTE.
//
// WHY DISCLOSURE AND NOT A PREDICATE. After `-O1` there is nothing left to
// discriminate: "one object read twice" and "two objects that were both
// uninitialized" are THE SAME MODULE — `undef` is uniqued per type, so the IR
// carries no record of how many C objects there were. A fence that refused the
// two-object reading would have to refuse the one-object reading this rule was
// RULED to compile. And a warning was deliberately NOT added, for the same
// reason CLAUDE.md §4 gives for the F2 one: it would fire on the owner's own
// ruled spelling — "both codes are supposed to compie!! also no warnings."
//
// ⚠ RETIREMENT TRIGGERS, three, each naming what would make this paragraph
// wrong rather than merely out of date:
//   (i)   F1's second sub-clause stops being a `Value*` IDENTITY test. A
//         value-equality or provenance test would make the manufacture VISIBLE,
//         and that is the only place a real predicate could live. Re-derive.
//   (ii)  the clause rewrites anything that is not `isa<UndefValue>`, or
//         `undef` stops being uniqued per type. Those are the refinement's only
//         two load-bearing facts; either one gone makes this an OVER-ACCEPT.
//   (iii) the 4 `cq_measure` rows: this paragraph does NOT cover them. They are
//         a RULED clause reached by a new route and they are with the owner.
//
// ── SOURCE ONLY, BY CONSTRUCTION ───────────────────────────────────────────
//
// A CHAINED theta's arg-0 is an SSA handle, i.e. an `Instruction`, and
// `valueCarriesUndef` is false for every non-`Constant`. So this never touches a
// chained rotation and there is no second spelling of `lowerRotations`' own
// `Chained = taint.Tainted.count(arg0)` relation to drift from it (the bd 9pum /
// L1 PREDICATE species: a fence asked at round-1 taint against a lowering
// decided at FINAL taint). Pinned by
// `lowering_accept_undef_theta_seed_chained.ll`.
//
// ARG-1 IS THE ANGLE AND IS NEVER TOUCHED (Rule 3). An `undef` angle is out of
// scope for this increment and keeps today's behaviour exactly: it survives into
// `cqrt_ry_<W>(h, undef)` as ONE slot, which `declineUnpairedUndefLiterals`
// counts but does not decline on, and its paired twin (a chained theta on a
// template rail: forward + negated adjoint, two slots) already declines through
// `lowering_reject_undef_literal_paired_rz_angle.ll`. Measured 2026-09-14 on the
// oracle and re-measured after this change: byte-identical.
//
// ⚠ ── CORRECTION (review round 1, F-U1-1) — "arg-1 is untouched" IS TRUE OF
//      ARG-1 IN ISOLATION AND FALSE OF ONE COMPOSITION. OPEN, NOT DECIDED. ────
//
// The paragraph above was recorded as "out of scope, unchanged, pinned", and a
// review round measured that this rule ALSO moves modules through a THIRD
// diagnostic nobody predicted — `declineUnpairedUndefLiterals` (GUARD 1) — by
// DELETING one of the two slots that guard was counting:
//
//   double d; cq_theta(&d, d);          // review probe r14
//
// At CQ type `double` the SEED and the ANGLE share the LLVM type, and `undef` is
// UNIQUED PER TYPE, so ONE `double undef` object filled BOTH emitted gate slots
// (`cqrt_alloc_f64(undef)` + `cqrt_ry_f64(h, undef)`) and GUARD 1's per-function
// threshold of TWO fired. Normalizing the seed drops the count 2 → 1, the guard
// goes SILENT, and the module compiles emitting
// `call void @cqrt_ry_f64(i32 %h, double undef)`.
//
// MEASURED 2026-09-14, both binaries, same stage-1 file: ORACLE `f7b65d8c`
// exit 1 / 246 B; this build exit 0 / 0 B. It is NOT confined to the width
// coincidence — `_Bool b; double th; cq_theta(&b, th);` (probe r21) pairs
// `i1 undef` with `double undef`, TWO DIFFERENT uniqued constants, and moves the
// same way (oracle exit 1 / 248 B). Nor is it confined to one call: probe r22
// puts the surviving slot on a DIFFERENT theta and moves the same way, which no
// conjunct local to this call could see.
//
// *** WHETHER THAT DECLINE WAS PROTECTING ANYTHING IS AN OPEN OWNER QUESTION,
//     AND IT IS WHY NO CONJUNCT IS ADDED HERE. *** GUARD 1 is the PAIRING break
// (bd xy9n): its invariant is that a literal the LOWERING COPIES to several
// emitted sites must denote ONE value at every site. In the r14 module the two
// occupied slots are the alloc SEED and the rotation ANGLE — two INDEPENDENT
// source operands that are the same `Constant` only because `undef` is uniqued
// per type. On that reading the oracle's decline is a TYPE COINCIDENCE rather
// than a pairing break, i.e. itself an over-decline, and restoring it would
// refuse a program no more undefined than the one this rule was RULED to
// compile. GUARD 1's own residual note already calls the neighbouring shape
// ("two INDEPENDENT single-slot occurrences in ONE function") merely *safe* in
// direction, with a measured population of *zero*.
//
// WHAT IS NOT IN DISPUTE, so it is not re-litigated: a DEFINED seed with an
// undef ANGLE accepts on BOTH binaries, unchanged by this rule — that is the
// deliberately BLESSED one-slot case (`lowering_accept_undef_literal_single_slot.ll`,
// the threshold of TWO, and the committed `slice_libm_ld80_nexttoward` golden
// that rests on it). Probes `r17_double_angle_only.c` / `r03_angle_undef.c`: IR
// IDENTICAL on both binaries, `cqrt_ry_<W>(h, double undef)` preserved.
//
// The measurements the ruling needs — whether the GENUINE pairing hazard (a
// forward gate and its `_unc` adjoint re-emitting the negated angle) still
// fires after this rule, the surviving slot count in the r14 module, where the
// blessed single slot actually sits, and whether the emitted circuit is
// REPRODUCIBLE — are in `$SES/trackU/FIX_U_R1.md` §2 with their commands.
//
// ── PLACEMENT, AND THE L1 (ROUND-2) OBLIGATION ─────────────────────────────
//
// Called from `collectAndSeed` (TaintPropagation.cpp), i.e. from inside
// `propagate` — the ONE funnel that BOTH pipeline entry points (`run` /
// `runOnFunction`) and EVERY re-propagate fixpoint round come through. That is
// deliberate and it is the whole L1 argument:
//
//   * "EARLY, before classification" is the ruling's own requirement (clause 2)
//     — at the emission site the in-region spelling would still have died at F1,
//     which runs ~500 lines earlier;
//   * control detect+lower runs TWICE (`repropagateControlMerges`), and every
//     stage that DUPLICATES a theta (`LoopUnrollPrepass`, and the PredMux /
//     fp80-union / ctlz fixpoints) is followed by a full
//     `taint = propagate(M, wd)` in its own loop, so the normalization is
//     re-asked after each of them without a second call site to forget (the L1
//     cure, discharged STRUCTURALLY rather than by a record).
//
// ⚠ *** THAT DISCHARGE IS TRUE OF THE SEED HALF AND ONLY HALF-TRUE OF THE PHI
//     HALF, AND THE DIFFERENCE IS MEASURED, NOT STRUCTURAL. *** (Review round
//     3, F-U3-4.) The function EARLY-RETURNS once the seed is concrete —
//     `valueCarriesUndef(i32 0)` is false — so from the SECOND propagate round
//     onward the phi loop below is UNREACHABLE. The function is therefore
//     IDEMPOTENT, and "re-asked at every fixpoint round" means, for the phi
//     half, "re-asked and the answer is *nothing to do*". An undef phi incoming
//     that APPEARED or was EXPOSED between rounds would be left alone, F1 would
//     then compare `i32 0` against `undef`, and the module would DECLINE — the
//     over-decline direction, and an L1-species asymmetry.
//
//     IT IS UNREACHABLE TODAY, AND THAT WAS MEASURED RATHER THAN ASSUMED
//     (Rule 11 — the fix round re-ran every grep itself and found two spellings
//     the review's own greps did not):
//       (a) NOTHING REWRITES A PHI INCOMING BUT THIS CLAUSE. `setIncomingValue`
//           has exactly ONE site in `ir-pass/{src,include,tools}` — the loop
//           below. ⚠ The write-spelling FAMILY is wider than that one name and
//           must be asked as a family (lesson L2): `addIncoming` has 3 sites
//           (`Specialization.cpp:487` a clone `ret` value, `BreakReversePlay.cpp:834/837`
//           two `sub` Instructions) and `removeIncomingValue` 2
//           (`CtlzIdiomPrepass.cpp:433-434`, which only REMOVES). None can put
//           an `undef` on a phi that carries a theta.
//       (b) THE PASS MINTS NO UNDEF AT ALL. `UndefValue::get` / `PoisonValue::get`
//           have ZERO call sites; the single textual hit is the comment at
//           `LiteralIntegrity.h:136` recording that this grep is clean.
//       (c) BOTH PHI MINTERS ARE STRUCTURALLY EXCLUDED. `PHINode::Create` /
//           `CreatePHI` have exactly 2 sites. `cqq.ret` (`Specialization.cpp:484`)
//           merges CLONE RETURN VALUES, and `SpecializeReject::scanBody` rejects
//           any body containing a call in `Sets.Rotations` (`SpecializeReject.cpp:636`,
//           seeded from `taint.ThetaCalls` at `:53`) — its own "load-bearing
//           precondition R2" — so no theta result can be returned and that phi
//           can never be a theta user. `cq.brk.ip` (`BreakReversePlay.cpp:831`)
//           takes exactly two incomings, `NMinus1` and `IDec`, both `sub`
//           Instructions.
//       (d) NOT ENUMERATED, and stated rather than implied: a RAUW whose
//           replacement value is an `undef` ALREADY PRESENT in the input module
//           could in principle land on a phi incoming. (b) bounds it — the pass
//           creates no new undef — but the RAUW targets were not enumerated.
//
//     ⚠ RETIREMENT TRIGGERS, one per limb: (a) a SECOND writer in the
//     phi-incoming write family appears; (b) any `UndefValue::get` /
//     `PoisonValue::get` call site appears; (c) a third phi-creation site
//     appears, or either existing one stops being excluded (R2 stops rejecting
//     `Sets.Rotations`, or `cq.brk.ip` gains a non-`sub` incoming). On ANY of
//     them the phi half must be RE-ASKED after the round-2 fixpoint.
//
//     *** AND THE FIX IS A SECOND ENTRY POINT, NEVER A RELAXED GUARD. *** The
//     seed guard is also the ACTION guard for `setArgOperand`: relaxing it to
//     reach the phi loop would let the rewrite fire on a seed that is not a
//     whole-value `undef`, which is the silent VALUE CHANGE the
//     `isa<UndefValue>` conjunct exists to prevent. ⚠ Review round 3 gave the
//     reason as "it would make the rewrite non-idempotent"; re-checked here and
//     that is NOT the hazard — the phi loop IS idempotent (`isa<UndefValue>` is
//     false after the first rewrite) and the call site discards the return
//     value. The hazard is the seed operand, not the fixpoint.
//
// THE ONE STAGE BETWEEN THE LAST `propagate` AND `lowerRotations` IS
// `specialize`, AND IT IS MEASURED SAFE RATHER THAN ASSUMED — that gap is
// exactly where an L1 finding would live, so it was checked three ways:
//   (1) `SpecializeReject::scanBody` REJECTS every body containing a
//       `cq_theta`/`cq_phi` — `SpecializeReject.cpp` calls that its
//       "load-bearing precondition R2" and `Specialization.cpp` restates it as
//       "a clone body is rotation-free" — so the Phase-6 clone driver cannot
//       produce a theta at all, with or without an argument substitution;
//   (2) DUPLICATION IS MONOTONE: a stage that clones a theta copies its
//       operands, so a clone of a normalized call is normalized
//       (`SwapRouteEmit`'s negated-arm `T->clone()` is the live instance);
//   (3) the only way to RE-introduce an undef seed is to WRITE one into arg-0,
//       every other `setArgOperand(0, ...)` in `ir-pass/src` — four of them,
//       `AngleSelectEmit` ×1 and `SwapRouteEmit` ×3 — writes an SSA VALUE (a
//       hoisted theta, `Prev`, `Q`), never a constant `undef`.
//   So the property "no collected theta has a whole-value undef seed" holds from
//   the first `propagate` through `lowerRotations`, in BOTH entry points. If a
//   future stage mints or rewrites a `@cq_theta` arg-0, re-ask this question:
//   the cheap fix is a second call here, the wrong fix is a check at the alloc.
//
// It is also why no passthrough property moves: a module with no theta call has
// nothing to normalize, so `passthrough_no_quantum` stays byte-identical.
bool normalizeUndefRotationSeed(CallInst *Theta) {
  // `declMatchesPrototype` (TaintPropagation.cpp) has already proven arity 2 and
  // `paramType(0) == returnType == T` for every collected theta, so arg-0 exists
  // and its type IS the suffix's width — which is why the zero below is minted
  // from the OPERAND's own type and no width table is consulted (nine reachable
  // types: i1/i8/i16/i32/i64/half/float/double/x86_fp80; three pinned by
  // `lowering_accept_undef_theta_seed_widths.ll`).
  if (Theta->arg_size() < 1)
    return false;
  Value *Seed = Theta->getArgOperand(0);
  if (!valueCarriesUndef(Seed))  // the ONE shared spelling (Rule 14)
    return false;
  if (!isa<UndefValue>(Seed))  // ... but only a WHOLE-VALUE undef is rewritable
    return false;              //     (the ConstantExpr residual, above)
  // ⚠ NO ARG-1 CONJUNCT HERE — DELIBERATELY, AND THE QUESTION IS OPEN. Review
  // round 1 (F-U1-1) measured that when the ANGLE also carries an undef this
  // rewrite drops `declineUnpairedUndefLiterals` below its threshold of 2 and a
  // module the ORACLE declined compiles silently. Whether that decline was
  // PROTECTING anything is the open question — see the F-U1-1 paragraph above.
  // Do NOT add the conjunct on your own judgement; it is an owner ruling.
  Constant *Zero = Constant::getNullValue(Seed->getType());
  Theta->setArgOperand(0, Zero);
  // The straight-through edge. `PoisonValue` derives from `UndefValue`, so one
  // `isa` covers a mixed `undef`/`poison` spelling; the type test is
  // belt-and-braces (a phi carrying this theta's result has the theta's type by
  // construction).
  //
  // ⚠ READ THE SCOPE PARAGRAPH ABOVE BEFORE QUOTING THIS LOOP. It is NOT "the
  // same uninitialized object, read twice" — that is the motivation. It is
  // EVERY undef incoming of EVERY phi user (measured: 164 of 972 carried thetas
  // have >1 phi user; 37 phis have >= 2 non-theta incomings; population 164
  // modules — ⚠ two different 164s, do not cite one for the other). The
  // soundness ground is the per-rewrite refinement, and the widening it admits
  // is DISCLOSED above, not fenced.
  //
  // ⚠ ONE-SHOT: the `valueCarriesUndef` gate above makes this loop unreachable
  // at every propagate round after the first. That is safe only for the three
  // MEASURED reasons in the PLACEMENT section (no second phi-incoming writer,
  // no undef minted anywhere, both phi minters excluded), each with its own
  // retirement trigger. If one of them retires, add a SECOND CALL — do NOT
  // relax the guards above to get here.
  for (User *U : Theta->users()) {
    auto *P = dyn_cast<PHINode>(U);
    if (!P)
      continue;
    for (unsigned I = 0, N = P->getNumIncomingValues(); I < N; ++I) {
      Value *In = P->getIncomingValue(I);
      if (isa<UndefValue>(In) && In->getType() == Zero->getType())
        P->setIncomingValue(I, Zero);
    }
  }
  return true;
}

namespace {

// "Unsupported rotation" diagnostic — mirrors MeasureLowering's surface so
// the pass speaks one diagnostic dialect. Failure is loud, not silent: the
// offending call is left in place to surface at the verifier. The call's
// `!dbg` is attached so the rejection is source-located (same surface as
// `diagnoseUnderControl`).
void diagnoseUnsupported(CallInst *CI, const char *What) {
  std::string Msg = std::string("cq rotation lowering: unsupported ") + What;
  CI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *CI->getFunction(), Msg, CI->getDebugLoc()));
}

// Straight-line tainted-ANGLE gate (test_C_libtooling-659): quantum-derived
// data in a rotation's arg-1 ANGLE slot has NO fixed unitary — angle =
// f(quantum value), value in superposition — so there is nothing correct to
// emit. The taint discipline keeps the angle operand classical PER-USE (taint
// never propagates THROUGH an arg-1 edge, Rule 3), but the angle VALUE itself
// is tainted when derived from a handle elsewhere (`sitofp(%q)`, `ext(%q)`).
// Two loud-but-wrong outcomes without this guard, both found by the
// test_C_libtooling-9hh §8 adversarial clearance (2026-06-10):
//   (a) cast family — CastLowering cross-type-RAUWs the f64 cast result to an
//       i32 handle inside the already-emitted `cqrt_rz`/`cqrt_ry`, which is
//       FINAL (never erased): Broken module, opt exit 134;
//   (b) opaque-call family — `%ang = call double @ext(i32 %q)` survives
//       well-typed and, after the RAUW-to-handle, reads the i32 RUNTIME
//       HANDLE TAG: a verify-clean silent miscompile.
// The region-level twin is ArmClassify::taintedAngleGate (arms/derived base);
// this is the straight-line root fix: decline loudly BEFORE any emission.
// Returns true (and diagnoses) iff the rotation's angle is tainted.
bool declineTaintedAngle(CallInst *Rot, const TaintSet &taint) {
  if (Rot->arg_size() < 2 || !taint.Tainted.count(Rot->getArgOperand(1)))
    return false;
  diagnoseUnsupported(Rot, "quantum-derived rotation angle");
  return true;
}

// Frozen-quantum-wire guard (test_C_libtooling-4i7r): a tainted `FreezeInst`
// whose result type is NOT `i32` is UN-LAUNDERABLE. The runtime handle is
// ALWAYS i32 (Rule 15); every lowering path RAUWs a tainted quantum value to a
// `cqrt_alloc_*` / `cq_template_*` i32 handle — but a `freeze` is NEVER erased
// by any stage (`declineTaintEscapes` SKIPS an fp freeze so it can ride the
// GATE-3 angle fence; it is never folded). So once the wire under it is
// RAUW'd, `%f = freeze <fp> %handle` is ill-typed AND any `cqrt_*`/`cq_template_*`
// call reading `%f` gets an fp value in an i32 handle slot. With no
// measure/uncompute owner (a dead sibling while the wire is measured/escaped
// elsewhere) NOTHING declines it and `opt` ABORTS on the broken module
// (SIGABRT 134, "Call parameter type does not match function signature")
// instead of the house decline — a crash on VALID input (Rule 1). Scan and
// decline BEFORE the first RAUW so every freeze stays well-typed and `opt`
// exits with the source-located diagnostic, never a crash.
//
// COMPLETENESS: a tainted value derives (transitively) from a `@cq_theta`
// result — the sole taint source — whose lowering yields an i32 handle, so a
// tainted freeze at a non-i32 result type is invariably inconsistent with that
// i32 handle and cannot be lowered. An i32 tainted freeze self-launders
// (`freeze i32 %handle` is well-typed) and is not flagged; a non-i32 INTEGER
// freeze is already declined upstream at `declineTaintEscapes` (kMsgOther, the
// non-foldable `freezeResultWouldEscape` path) so in practice only fp freezes
// reach here — the `!isIntegerTy(32)` test is defensively complete for any
// non-i32 remnant. A CLASSICAL freeze (untainted) is left untouched (its
// operand keeps its own type across every RAUW).
//
// FIXTURE INVARIANT: the SELECT-mediated fp-freeze spellings decline EARLIER at
// `detectControlRegions` (which runs strictly before `lowerRotations`) — the
// kjd1 operand/condition fences (`taintedLineageHasFreeze` + the
// condition-provenance `FreezeInst` scan) and the GATE-3 angle walk
// (`selReachesRotationArg1`) — so this guard NEVER fires on those four fixtures
// (`control_swap_reject_select_fp_freeze_{operand,cond}.ll`,
// `control_swap_reject_select_freeze.ll`,
// `control_swap_reject_freeze_phi_angle.ll`); it owns ONLY the straight-line
// frozen-wire shape the detection fences never see. Walk in BB order for a
// deterministic, source-located first report (the DS_Error diagnose exits).
bool declineFrozenWire(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *FI = dyn_cast<FreezeInst>(&I))
          if (taint.Tainted.count(FI) && !FI->getType()->isIntegerTy(32)) {
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F,
                "cq rotation lowering: unsupported frozen quantum wire",
                FI->getDebugLoc()));
            return true;
          }
  }
  return false;
}

}  // namespace

// ⚠ `emitRz` IS **DELETED** (bd test_C_libtooling-3qlq Inc 1 part B). It was the
// `cq_phi` gate-body emitter of the RETIRED register form — both of its arms
// minted the TENSORED per-register gate (`cqrt_rz_<W>` / `cqrt_rz_<W>_controlled`),
// which is exactly the defect PRD `retire-swap-route-PRD.md` §1 records: an Rz on
// EACH qubit of a W-bit register puts phase `(-1)^popcount(target)` on the marked
// branch and cannot mark `|0..0>` at all, so every shipped Grover golden built on
// it was a self-consistent trace of the IDENTITY on `q`.
//
// Part A left it standing with zero callers, deliberately, because two OTHER
// minters of a non-`i1` `cqrt_rz` were still live and were part B's scope
// (`NestedRouteEmit.cpp` and `SwitchRouteEmit.cpp`). Both are now gone — the nest
// emitter is deleted outright and the switch one is rewritten to the kickback —
// so the whole family goes with them. AFTER THIS INCREMENT
// `grep -rn 'rzRtFn' ir-pass/src` yields exactly THREE call sites and every one
// of them asks for `"i1"`: `SwapRouteEmit::emitPhaseKickbackRegion`,
// `SwapRouteEmit::emitPhaseKickbackNestRegion`, `SwitchRouteEmit::
// emitSwitchPhaseRegion` — plus `AngleSelectEmit`, which also spells `"i1"`.
//
// ⚠ DO NOT REVIVE IT FOR A `cq_phi`. The register-free branch phase is an
// UNCONTROLLED `cqrt_rz_i1` on the condition FLAG (kickback, PRD §3); an
// uncontrolled or classically-controlled `cq_phi` is a GLOBAL phase and is
// DELETED (`deleteGlobalPhases`, P7). Neither goes through a per-register Rz.
// The runtime DECLARATIONS of the `cqrt_rz_<W>` family are NOT deleted (owner
// question Q1 — at the Phase-11 freeze, not now); what is deleted is the code
// that could still MINT one.

void lowerRotations(Module &M, WidthDispatch &wd, TaintSet &taint,
                    const ControlPlan *plan) {
  // `plan->InShadow` was this function's only reader of the plan, and it was
  // read ONLY by the deleted PHI loop below. NOTHING has ever inserted into that
  // set (`grep -rn "InShadow" ir-pass/` finds the declaration, its comments and
  // that one read), so the parameter is now unused rather than newly-dead. It is
  // KEPT in the signature: both pipeline entry points pass it, `ControlPlan.h`
  // documents it as the channel for a future control emitter that keeps gate
  // bodies IN PLACE, and removing it would touch the twin-pipeline call sites
  // for no behavioural gain.
  (void)plan;
  // `PhiCalls` is permanently empty since 3qlq Inc 1 and is kept in the
  // predicate as the vacuous term it now is (see TaintPropagation.h).
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty())
    return;

  // Frozen-quantum-wire guard (test_C_libtooling-4i7r): decline any tainted
  // non-i32 `freeze` BEFORE the cross-type RAUW-to-handle below breaks it into a
  // verify-clean-invisible SIGABRT. See `declineFrozenWire` for the invariant.
  // The DS_Error diagnose exits `opt` non-zero; return is a belt-and-braces
  // "lower nothing" for any future non-exiting diagnostic handler.
  if (declineFrozenWire(M, taint))
    return;

  IRBuilder<> Builder(wd.context());
  std::vector<Instruction *> ToErase;

  // --- THETA. Iterate in collection (BB) order. Forward order matters: a
  // chained theta N+1 takes theta N's result as its operand, and lowering
  // theta N RAUWs that result to the handle — so when we re-read theta
  // N+1's operand it is already the handle (tainted), routing it to the
  // ry-only path with no second allocation.
  //
  // ---- H-1, PART 2: CONTROL THETAS FIRST (bd test_C_libtooling-l4x4, l4x4.b)
  //
  // A BARE `_Bool` (rail-root) condition makes the CONTROL of a
  // `cqrt_ry_<W>_controlled` a `@cq_theta_i1` CALL rather than a minted `i32`
  // compare flag (`TaintSet::ControlledRotations`, whose header owns the whole
  // argument). The `WeakTrackingVH` there turns that call INTO its `i32` handle
  // the moment this loop lowers it — but only if it HAS been lowered, and in
  // collection order there is nothing that says a control precedes the arm gate
  // it controls. "It happens to, at `-O1`" is exactly the unwritten dependency
  // this project's record says goes stale (the drbq Inc-1 `Value *`-set defect,
  // one hat over), so the order is MADE deterministic here instead of measured.
  //
  // PASS 1 lowers every theta that is a recorded CONTROL, plus its whole CHAINED
  // ancestry (a rail leaf may be a chained theta — `isCondRailLeaf` admits root
  // OR chained — and its parent must still be lowered before it). PASS 2 lowers
  // the rest. RELATIVE ORDER IS PRESERVED INSIDE EACH PASS, so the "parent before
  // child" invariant the paragraph above states is inherited rather than
  // re-established: any theta-parent of a pass-1 member is itself a pass-1
  // member, and a pass-1 member that is the parent of a pass-2 member is lowered
  // first a fortiori.
  //
  // ⚠ IT IS A NO-OP FOR EVERY MODULE WITHOUT A RAIL CONTROL, BY CONSTRUCTION AND
  // BY MEASUREMENT. `ControlThetas` is empty whenever every recorded control is a
  // compare flag (i.e. every module that existed before 1b-C), and the partition
  // then reproduces `taint.ThetaCalls` verbatim — which matters because the
  // `!Chained` arm below consumes a `BirthOrder` slot, the Q+Q ordering seed, and
  // a reordering that touched it would move goldens for programs this increment
  // has nothing to do with. The whole-corpus lowered-IR diff is the witness.
  // ⚠ NAME-PREFIX ONLY, AND THE ARITY IS **NOT** RE-ASKED HERE — recorded rather
  // than silently relied on. `getArgOperand(0)` below is safe because a theta
  // whose declaration does not match the frozen prototype has ALREADY fired a
  // loud decline: `resolveSources` validates every `cq_theta_<sfx>` in
  // `wd.allSuffixes()` at collection time and `opt` exits non-zero, so no
  // zero-arg `@cq_theta_i1` reaches this loop. That is a dependency on ANOTHER
  // stage, which is exactly the kind this file's history says to write down:
  // RETIREMENT TRIGGER — if the prototype guard is ever narrowed to a subset of
  // the suffixes, or moved after `lowerRotations`, this walk needs its own
  // `C->arg_size() >= 1` conjunct (the spelling `railWireNamesBackward` already
  // carries for the same rail, one file over).
  auto isThetaCallHere = [](const CallInst *C) {
    const Function *F = C ? C->getCalledFunction() : nullptr;
    return F && F->getName().starts_with("cq_theta_");
  };
  SmallPtrSet<const CallInst *, 4> ControlThetas;
  for (const auto &E : taint.ControlledRotations) {
    auto *C = dyn_cast_or_null<CallInst>(E.second);
    while (C && isThetaCallHere(C) && ControlThetas.insert(C).second) {
      // Walk the chained ancestry: a theta whose arg-0 is TAINTED is lowered IN
      // PLACE on the parent's rail, so the parent owns the handle (this is
      // `lowerRotations`' own `Chained` relation, not a second spelling of it).
      Value *Op = C->getArgOperand(0);
      if (!taint.Tainted.count(Op))
        break;  // a SOURCE theta: arg-0 is the classical seed, nothing above it.
      C = dyn_cast<CallInst>(Op);
    }
  }
  SmallVector<CallInst *, 8> ThetaOrder;
  if (ControlThetas.empty()) {
    ThetaOrder.assign(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  } else {
    for (CallInst *T : taint.ThetaCalls)
      if (ControlThetas.count(T))
        ThetaOrder.push_back(T);
    for (CallInst *T : taint.ThetaCalls)
      if (!ControlThetas.count(T))
        ThetaOrder.push_back(T);
  }
  for (CallInst *Theta : ThetaOrder) {
    StringRef Sfx = suffixFromName(Theta, "cq_theta_");
    StringRef Abi = wd.abiWidthFor(Sfx);
    FunctionCallee Ry = Abi.empty() ? FunctionCallee() : wd.ryRtFn(Abi);
    if (!Ry) {
      diagnoseUnsupported(Theta, "theta suffix/width");
      continue;
    }
    Value *Op = Theta->getArgOperand(0);  // re-read: RAUW may have updated it
    Value *Angle = Theta->getArgOperand(1);
    // Quantum-derived angle → loud decline BEFORE any emission (no alloc, no
    // ry); the theta is left standing (test_C_libtooling-659).
    if (declineTaintedAngle(Theta, taint))
      continue;
    Builder.SetInsertPoint(Theta);

    Value *Ctrl = nullptr;
    if (auto It = taint.ControlledRotations.find(Theta);
        It != taint.ControlledRotations.end())
      Ctrl = It->second;

    Value *Handle;
    auto *PreallocatedBankSeed = dyn_cast<CallInst>(Op);
    const bool AdoptBankSeed = isRailBankSeedAlloc(PreallocatedBankSeed);
    const bool Chained = taint.Tainted.count(Op) != 0 || AdoptBankSeed;
    // ⚠ THE SUFFIX/WIDTH BAIL IS HOISTED HERE, ABOVE THE ALLOC, AND THAT IS A
    // FIX RATHER THAN A MOVE (PRD §14.4). It used to sit two lines below the
    // controlled mint, i.e. AFTER the `!Chained` arm had already emitted
    // `cqrt_alloc_<W>(Op)`, inserted `H` into `taint.Tainted`, consumed a
    // `BirthOrder` slot and written `HandleWidth[H]` — so on `continue` the
    // module kept an alloc with ZERO USERS, a still-standing `@cq_theta_*`, and
    // three live side-table entries keyed on the orphan. A MID-EMISSION BAIL,
    // survivable only because `DS_Error` exits `opt` non-zero. Rule 1: never emit
    // half a region. Inc 4 turns the sibling `!Chained` bail into the accept
    // path, so this one had to move or it would have inherited the same shape on
    // a path that now allocates.
    //
    // Detection gated on `abiWidthHasControlledRotation` already, so this is
    // unreachable on a plan-consistent module; it stays LOUD (never a silent
    // fall-through to the UNCONTROLLED gate, which would fire the arm's Ry on
    // BOTH branches — a wrong unitary).
    //
    // ⚠ NO FIXTURE EXISTS FOR THIS STRING AND NONE CAN BE WRITTEN — recorded in
    // place so nobody tries (round-1 Rule-13 review, lens L4 finding F-L4-5,
    // re-derived independently there). `resolveSources` collects only the 16
    // `cq_theta_<sfx>` names in `WidthDispatch::kRows`; every one maps through
    // `abiWidthFor` into `{i1,i8,i16,i32,i64,f16,f32,f64,f80}`, which is EXACTLY
    // `abiWidthHasControlledRotation`'s set. So `Abi` is never a
    // recognized-but-uncontrolled width, and neither this bail nor its sibling
    // detection gate (`ArmClassify`'s `controlled rotation width`) can fire. The
    // check is kept as the Rule-1 SHAPE — one loud bail, above every mutation —
    // not as a live protection, and `grep` finds the string at these two code
    // sites and in no fixture.
    if (Ctrl && !ControlledSymbols(M, wd).controlledRotationFn(
                    Abi, ControlledSymbols::RotStem::Ry)) {
      diagnoseUnsupported(Theta, "controlled theta suffix/width");
      continue;
    }
    // ---- H-1, PART 3: THE RECORDED CONTROL MUST HAVE BEEN RESOLVED, AND A
    //      FAILURE IS LOUD (bd test_C_libtooling-l4x4, l4x4.b).
    //
    // `Ctrl` reaches this line by one of two routes and they are NOT the same
    // object at the emission site: a minted compare flag is already the `i32`
    // result of a `cq_template_icmp_*_hl` (sound as a raw pointer, and the only
    // case that existed before 1b-C), while a BARE `_Bool` condition is recorded
    // as the user's `@cq_theta_i1` CALL and only stops being one when pass 1
    // above lowers it and the `WeakTrackingVH` follows the RAUW. Two things can
    // therefore be wrong, and both are refused here rather than downstream:
    //   * NULL — the recorded control was erased with no replacement;
    //   * STILL A `@cq_theta_*` CALL — pass 1 did not resolve it, so this would
    //     put an un-lowered `iN` theta result in the control slot of a
    //     `void(i32,i32,double)` callee AND hold a use of an instruction this
    //     very loop is about to ERASE. Nothing later repairs either.
    //
    // ⚠ IT IS **NOT** SPELLED `isIntegerTy(32)`, AND THE FIRST SPELLING WAS —
    // measured, and it cost a legitimate accept. A CHAINED theta lowers to
    // `Handle = Op`, its arg-0, which for a rail whose parent is a TEMPLATE value
    // (a `%out`-derived `icmp`, i.e. the round-2 taint window) is a pre-`lowerOps`
    // `iN` value that `lowerOps` RAUWs to an `i32` handle one stage later. That
    // transient is this file's own documented behaviour ("the mismatch is
    // transient and laundered by erasure of the tainted users"), it applies to
    // the UNCONTROLLED gate identically, and refusing it here would decline a
    // shape that has nothing to do with H-1. What H-1 needs is that the control
    // was RESOLVED — i.e. is no longer the theta call — and that is what is asked.
    //
    // IT DECLINES AND LOWERS NOTHING. Falling through to the UNCONTROLLED `Ry`
    // would fire the arm's rotation on BOTH branches — a wrong unitary, verify-
    // clean — which is the identical posture its two sibling bails above take,
    // and for the identical reason. Placed ABOVE the alloc with them (Rule 1:
    // never emit half a region).
    if (taint.ControlledRotations.count(Theta) &&
        (!Ctrl ||
         (isa<CallInst>(Ctrl) && isThetaCallHere(cast<CallInst>(Ctrl))))) {
      diagnoseUnsupported(Theta, "controlled rotation control handle");
      continue;
    }
    if (Chained) {
      // Tainted operand (chained theta) → ry only on the existing handle.
      Handle = Op;
      // The rail-bank promoter already emitted this exact runtime allocation so
      // the skipped preparation path owns a real |0> rail. Detection kept it
      // outside ordinary taint on purpose (it is a fresh state-prep seed, not a
      // source register); from this point onward it is an ordinary live handle.
      if (AdoptBankSeed) {
        taint.Tainted.insert(Op);
        if (!taint.BirthOrder.count(Op))
          taint.BirthOrder[Op] = taint.NextBirth++;
        taint.HandleWidth[Op] = "i32";
      }
    } else {
      // Classical operand → mint a fresh handle, then ry on it.
      FunctionCallee Alloc = wd.allocFn(Abi);
      CallInst *H = Builder.CreateCall(Alloc, {Op}, "h");
      if (DebugLoc DL = Theta->getDebugLoc())
        H->setDebugLoc(DL);
      Handle = H;
      taint.Tainted.insert(H);
      taint.BirthOrder[H] = taint.NextBirth++;  // BB-order seed → stable Q+Q
      // §5.6: record the handle's LOGICAL width from the classical `cq_theta`
      // operand, on the freshly minted i32 handle, BEFORE the RAUW below
      // launders the theta result's type away. Read later when building a Q+Q
      // control condition (PRD §2.4), where both operands are i32 handles.
      // `abiWidthFromType` returns a stable StringRef literal (no storage
      // lifetime concern).
      taint.HandleWidth[H] = abiWidthFromType(Op->getType());
    }

    // CONTROL-IN-PLACE ROTATION ARM (control-in-place-PRD §6, bd
    // test_C_libtooling-drbq Inc 1). `SwapRouteEmit`'s in-place emitter HOISTED
    // this theta out of a tainted arm into the pred and recorded the control
    // flag it must fire under. Mint `cqrt_ry_<W>_controlled(f, handle, θ)` at
    // the hoisted position instead of the unconditional gate; everything else
    // (the handle, the RAUW, the `UserChainedRotations` recording) is unchanged.
    CallInst *RyCall = nullptr;
    if (Ctrl) {
      // A CLASSICAL arg-0 under control is controlled STATE PREP (PRD §14, bd
      // test_C_libtooling-drbq Inc 4) — and since Inc 4 it is an ACCEPT, not a
      // bail. The `!Chained` arm above already minted `cqrt_alloc_<W>(SEED)` AT
      // THE THETA'S HOISTED POSITION (the emitter moved the theta before `BI`,
      // after the flag mint and INSIDE a negated arm's `cqrt_x` bracket), so
      // `Handle` is a rail this region owns outright and the only thing left is
      // to fire the gate under the flag.
      //
      // The two fences that make that sound live in `classifyArms`, not here:
      // F1 (the merge φ's Pred incoming is IDENTICAL to the seed — a
      // `ConstantInt`/`ConstantFP` bit-identical by uniquing, or since bd z0re
      // (2026-09-28) the SAME runtime SSA value — so the `f=0` component's
      // |SEED> IS the source's straight-through value) and F2 (no live tainted
      // register off the condition's wire is provably equal to the seed on
      // either edge, so this is not a `-O1`-folded in-place Ry). Nothing is
      // re-derived here; this stage owns the SYMBOL, detection owns the PROOF.
      // ⚠ `Chained` above is decided on FINAL taint while F1 read the seed's
      // taint at its detection round: a RUNTIME seed that turned quantum in
      // between would land in the `Chained` arm as an unvetted in-place Ry.
      // `declineRound2QuantumPrepSeeds` refuses that before this loop runs; a
      // literal seed cannot turn quantum (bd z0re, the L1 record).
      // ⚠ NO SECOND BAIL HERE — the null-guard that used to sit on this line was
      // HOISTED with its sibling, above the alloc (round-1 Rule-13 review, lens
      // L3 finding F-6). It asked the SAME predicate with the SAME arguments and
      // was genuinely unreachable, but if it had ever fired it would have
      // reproduced exactly the mid-emission residue the hoist removed: a
      // `cqrt_alloc_<W>` with zero users, a still-standing `@cq_theta_*`, and
      // three live side-table entries keyed on the orphan. One bail, one
      // position, above every mutation (Rule 1: never emit half a region).
      ControlledSymbols csyms(M, wd);
      FunctionCallee CRy = csyms.controlledRotationFn(
          Abi, ControlledSymbols::RotStem::Ry);
      assert(CRy && "the hoisted suffix/width bail guarantees a callee here");
      RyCall = Builder.CreateCall(CRy, {Ctrl, Handle, Angle});
      // The register is now FROZEN — never reverse-played, never freed by the
      // whole-DAG spine (a controlled gate's adjoint needs its CONTROL, and the
      // flag is stripped + freed inside the region's own stream). NOTHING IS
      // RECORDED HERE, DELIBERATELY: the freeze is a property of the gate we
      // just minted, and the spine asks it structurally via
      // `ChainWalk::railCarriesControlledRotation(rail)`. Recording `Handle`
      // instead was the Inc-1 shipping defect — for a DERIVED base it is a
      // pre-`lowerOps` SSA value the very next stage erases, so the set went
      // stale and the freeze silently did not apply (round-1 review L3 §1 /
      // L5 §1; see `TaintSet`'s note where the member used to be).
    } else {
      RyCall = Builder.CreateCall(Ry, {Handle, Angle});
    }
    if (DebugLoc DL = Theta->getDebugLoc())
      RyCall->setDebugLoc(DL);
    // M-A Inc 1 (bd test_C_libtooling-6uqc). Record the gate we just minted, and
    // which KIND of user theta minted it. This is THE fact the late live-record
    // guard cannot recover from the lowered text: the spine's adjoint
    // `cqrt_ry(h, -θ)` is textually indistinguishable from a user's chained
    // theta, and the Inc-0 census's angle-pairing heuristic for telling them
    // apart measured wrong in both directions (SPIKE §1.4 blind spot A8). Only
    // this stage knows, because only this stage lowers `@cq_theta`.
    (Chained ? taint.UserChainedRotations : taint.UserSourceRotations)
        .insert(RyCall);

    // RAUW to the HANDLE (i32) — never to the void ry call (§1, PRD §2.5).
    // The handle's i32 type may differ from the theta result's type; that
    // mismatch is transient and laundered by erasure of the tainted users.
    Theta->replaceAllUsesWith(Handle);
    ToErase.push_back(Theta);
  }

  // --- PHI. GONE (bd test_C_libtooling-3qlq Inc 1, 2026-09-05).
  //
  // This loop lowered the 15-width `@cq_phi_<sfx>(x, angle)` family to
  // `cqrt_rz_<W>` / `cqrt_rz_<W>_controlled`, and BOTH targets are exactly the
  // defect the increment exists to remove (PRD `retire-swap-route-PRD.md` §1):
  // `cqrt_rz_<W>` is TENSORED — Rz on EACH qubit of the register — so the
  // routed/controlled form put phase `(−1)^popcount(target)` on the marked
  // branch and could never mark `|0…0⟩` at all. Every Grover golden built on it
  // was a self-consistent trace of the IDENTITY on `q`, and Rule 2 says exactly
  // why nothing caught it.
  //
  // The family is RETIRED at the surface (`CQ.h`) and unresolved by
  // `resolveSources`, so `taint.PhiCalls` is now permanently empty and this loop
  // could not fire. It is DELETED rather than left as a no-op because a dead
  // loop reading `getArgOperand(1)` of a call it can no longer identify is
  // precisely the shape the prototype guard exists to prevent. The RUNTIME
  // DECLARATIONS are NOT deleted (owner question Q1: at the Phase-11 freeze,
  // not now), and `emitRz` itself is DELETED with part B — see the note at the
  // top of this file where it used to live.
  //
  // What replaces it: the register-free `void @cq_phi(double)` is claimed by
  // `ArmClassify::classifyPhaseKickback` (P1) or `classifyAngleSelect` (P2) and
  // emitted as an UNCONTROLLED `cqrt_rz_i1` on the CONDITION FLAG, or deleted as
  // a global phase by `deleteGlobalPhases` (P7). None of those paths runs here:
  // all three complete before `lowerRotations` is reached.

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}


// ── M-A (Increments 1 + 3) — the LATE live-record guard (bd test_C_libtooling-6uqc) ──
//
// See RotationLowering.h for the ruled predicate, the three clause-1 closures
// (descendants · ancestors + copy-destination · descendants-of-ancestors), and
// why this runs post-`uncompute`. The implementation notes that do not belong in
// a header:
//
// EVERY POINTER IN THE RECORDED SETS IS STILL VALID HERE, and that is a checked
// property, not an assumption: no stage between `lowerRotations` and this slot
// erases an emitted rotation. `lowerOps` erases the ORIGINAL tainted IR ops (it
// never touches the calls it minted), `lowerMeasures` erases `@cq_measure_*`,
// `lowerBreakReversePlay` erases one branch terminator, and `uncompute` only
// emits. The set is nonetheless consulted ONLY by membership while walking the
// LIVE instruction list (the `StaleDeclined` idiom) — a recorded pointer is never
// dereferenced — and each candidate is re-checked to be a 2-arg `cqrt_ry_*` call,
// so even a hypothetical address reuse cannot manufacture a site.
namespace {

// Rule-12 mirror, character-for-character:
//   * lowering_live_record_derived_cond_theta_discharged.ll (bd 6uqc's own P4
//     shape — RE-DISPOSITIONED to an ACCEPT by M-B Increment 5b: the four
//     condition rails are now `_unc`'d and freed BEFORE the chained Ry, so
//     clause 2 exempts them and nothing here changed. The REGION spelling,
//     control_swap_accept_post_region_theta_derived_cond.ll, followed at M-B
//     Increment 6 once the emitter-recorded flag strip gave its chain an anchor;
//     the decline twin that remains is
//     lowering_uncompute_interior_leak_parent_ry_between.ll — a chained Ry INSIDE
//     the discharge interval, which no anchor can move.)
//   * lowering_reject_live_record_two_hop.ll              (a dead INTERIOR record)
//   * lowering_reject_live_record_qram_load.ll            (a `cqrt_qram_load_` record)
//   * lowering_reject_live_record_spine_only_use.ll       (post-T mention is an
//       `_unc` READ of a DIFFERENT rail — the spine-aware reading's defining case)
//   * lowering_reject_live_record_sibling_alias.ll        (record off the wire;
//       its pre-3qlq `cq_phi` sibling alias was deleted by the 3qlq migration)
//   * lowering_reject_live_record_router_phi.ll           (record behind the bd
//       tayx one-register router phi)
//   * lowering_reject_live_record_clone_call_hop.ll       (the record sits behind
//       a Phase-6 `__cq_q_*` clone call — the F1 severance)
//   * lowering_reject_live_record_unreachable_use.ll      (the post-gate data use
//       is in an unreachable block — the F3 vacuous exemption)
//   * (RE-DISPOSED — bd 8h7d.5 Rule-13 round 4) the per-RECORD exemption used to
//       be pinned here by lowering_reject_live_record_dead_compare_flag.ll, "a
//       live measured zext does not rescue its dead i1 sibling". That decline
//       named M-B as its customer and M-B has now arrived: the dead compare rail
//       is discharged before the gate, so the guard has nothing to report and the
//       file ships as lowering_live_record_dead_compare_flag_discharged.ll. NOT
//       ONE CLAUSE HERE MOVED. The per-record lesson keeps its pins in
//       lowering_reject_live_record_two_hop.ll and the anc_dead_sibling pair.
//   * lowering_reject_live_record_qram_borrowed_index_xor.ll (a KNOWN, DELIBERATE
//       over-decline: the dephasing at the gate provably cancels in that module)
// Increment 3 — the ANCESTOR half and the copy-destination class:
//   * lowering_reject_live_record_anc_alloc_parent_mul.ll  (bd nepx's `h0` class:
//       a dead `cqrt_alloc_*` parent, one producer hop up)
//   * lowering_reject_live_record_anc_two_hop.ll           (ancestor transitivity)
//   * lowering_reject_live_record_anc_router_phi.ll        (ancestor behind the bd
//       tayx one-register router phi)
//   * lowering_reject_live_record_anc_dead_sibling.ll      (THE sibling-closure
//       pin: a dead sibling under a LIVE, exempt ancestor)
//   * lowering_reject_live_record_clone_return_rail.ll     (copy-destination class
//       via a Phase-6 clone's `cqq.out` return — Increment 1's owned residual)
//   * lowering_reject_live_record_select_merge_out.ll      (severance class 2, the
//       4.4 merge out — MEASURED `opt` exit 0 at HEAD, i.e. a live over-accept,
//       NOT the lom0-masked shape the Inc-1 note claimed)
//   * lowering_reject_live_record_select_merge_tainted_src.ll (same, with a
//       tainted copy SOURCE so the decline does not rest on constant ancillas)
//   * lowering_reject_live_record_qram_fp64_load_index.ll  (the load-INDEX
//       ancestors of a QRAM read; reverses bd 38t2's shipped positive by owner
//       ruling, and shows the class-4 array boundary in the same module)
//   * lowering_reject_live_record_io_tape_chained_theta.ll (SPIKE §2R.5's
//       CANONICAL case, ruled in by the spine-aware reading §2R.5a)
// Increment 3 — boundary pins that decline at an EARLIER stage, kept so
// Increment 4 has to re-measure them rather than re-derive them:
//   * lowering_reject_live_record_switch_mux_out_masked.ll     ("control flow
//       under quantum control", SwitchClassify)
//   * lowering_reject_live_record_valuearm_merge_out_masked.ll ("value-arm
//       swap-route under quantum control", ArmClassify/SwapRouteEmit)
//   * lowering_reject_live_record_routed_base_anc.ll (RENAMED at Increment 4,
//       was `..._anc_masked.ll`) — the only one that really was bd
//       test_C_libtooling-lom0's "condition predates a non-diagonal gate", and
//       the only one whose message MOVED when Inc 4 lifted that decline: it now
//       lands here, on kMsgLiveRecord. Re-measured, not re-derived.
// ACCEPT controls, each pinning a clause this change must NOT widen:
//   * lowering_stale_record_add_before_theta.ll  }  clause 3 — the ruled LIVE
//   * lowering_stale_record_alias_before_theta.ll}  record boundary (pre-existing)
//   * lowering_live_record_discharged_before_theta.ll   clause 2
//   * lowering_live_record_measured_before_theta.ll     clause 4
//   * lowering_live_record_source_theta_accept.ll       source thetas are not sites
//   * lowering_live_record_clone_call_measured_accept.ll  the clone hop must not
//       turn every clone-calling program into a decline
//   * lowering_qram_array_record_chained_theta_accept.ll the RULED-DEFERRED
//       QRAM-array record class
//   * lowering_reject_live_record_post_theta_user_rz.ll  the RULED F2 boundary
//       (2026-08-28): a bare post-gate user rotation is a liveness NON-use. Its
//       user Rz was a register-form `cq_phi` that the 3qlq migration deleted, so
//       the file now pins only the dead record, not the rotation arm
//   * lowering_live_record_region_owner_probe.ll         an earlier stage still
//       owns its own message; this guard re-owns none
//   * lowering_live_record_anc_measured_before_theta_accept.ll  clause 4 on an
//       ANCESTOR record
//   * lowering_live_record_anc_observed_after_theta_accept.ll   clause 3 on an
//       ANCESTOR record — the ruled accept, and the one-instruction twin of the
//       dead-sibling reject
//   * lowering_live_record_clone_return_rail_measured_accept.ll clause 4 on the
//       COPY-DESTINATION class (this file used to be the ruled-deferred residual
//       over-accept `..._clone_return_rail_accept.ll`; M-C 2a made its `u = r+1`
//       an in-place `cqrt_addc` on the returned rail, so the user's measurement
//       lands on that rail and the accept is now physical, not a scope gap)
//   * lowering_live_record_clone_return_rail_live_accept.ll     clause 3 on the
//       same class
// INCREMENT 3's RULE-13 ROUND (2026-08-28) — the two owner-ruled fixes. Its "F1"
// rewrote clause 3 from "mentioned later" to "reaches an OBSERVING SINK"; its
// "F2" added the clause-6 existence skip. (Both round labels are reused from the
// Inc-1 and Inc-2c rounds, which numbered their own findings the same way — the
// Inc-2c "F2" is the ROTATION ruling pinned by
// lowering_reject_live_record_post_theta_user_rz.ll above. Go by the description,
// not the letter.) Negatives:
//   * lowering_reject_live_record_sibling_region_after_theta.ll  THE F1 fixture:
//       a dead sibling whose only post-gate fate is a compare feeding a phase
//       region — its flag minted, stripped, freed, never observed. MEASURED
//       `opt` exit 0 pre-fix; its region-BEFORE twin
//       (lowering_reject_live_record_anc_dead_sibling.ll) always declined, and
//       closing that before/after asymmetry is what the ruling is for
//   * lowering_reject_live_record_qram_store_no_readback.ll      the array HOP in
//       its FALSE direction: a record stored into a cell nothing ever loads.
//       MEASURED `opt` exit 0 pre-fix
//   * lowering_reject_live_record_post_gate_record_loop.ll       the clause-6
//       back-edge pin (a REGRESSION pin, not an isolating witness — read its
//       header: clause 3's own position test already declines every loop body)
// ACCEPT controls added in the same round:
//   * lowering_live_record_post_gate_record_accept.ll            THE F2 fixture —
//       a dead rail minted strictly AFTER the gate. MEASURED `opt` exit 1 pre-fix
//       (a FALSE decline); the module needs BOTH fixes, since its ancestor is
//       exempt only under F1's "template read that flows to a sink"
//   * lowering_live_record_sibling_region_then_measured_accept.ll the ONE-
//       INSTRUCTION discrimination twin of the F1 negative (`cq_measure(c)`)
//   * lowering_live_record_sibling_qram_store_load_measure_accept.ll the array
//       hop in its TRUE direction (store → load → copy-out → measure)
//   * lowering_live_record_sibling_read_taped_accept.ll          the sink is a 7.6
//       TAPE write, with no measurement anywhere in the module
//   * lowering_live_record_sibling_clone_arg_measured_accept.ll  the sink is
//       reached THROUGH a Phase-6 clone call — and, since ROUND 2 below, ALSO the
//       used-parameter control for the per-argument clone hop (its `inner(int x)`
//       really does read `x`)
// ROUND 2 OF THAT SAME RULE-13 ROUND (2026-08-28) — three exact fixes to the F1
// walk's grammar, found by the independent reviewer on the shipped round-1 tree.
// TWO OF THEM WIDEN AN EXEMPTION (the dangerous direction) and are carried by a
// C-REACHABLE MEASUREMENT, not an argument; the third is a decline. ACCEPT
// controls, each `opt` exit 1 on the round-1 tree and exit 0 after:
//   * lowering_live_record_condtree_toffoli_observed_accept.ll  N1, the AND node:
//       a CONTROL of `cqrt_toffoli` HOPS to the node ancilla, so a sibling read by
//       a condition tree whose merge result is measured IS observed. The route
//       rationale that had filed cnot/toffoli as non-uses is true for `cqrt_cswap`
//       and false for these two
//   * lowering_live_record_condtree_xor_observed_accept.ll      N1, the XOR node
//       (`cqrt_cnot` pair — bd 3c6m.67's openlibm ulp-direction idiom), which the
//       AND fixture's toffoli CHECK cannot cover
//   * lowering_live_record_tape_ctrl_observed_accept.ll         N2: the CTRL slot
//       of `cqrt_tape_write_<W>_controlled` is a SINK — the entry's presence or
//       absence reveals the flag. Its SRC-slot twin always accepted, so this was
//       one slot's worth of asymmetry
// Negatives:
//   * lowering_reject_live_record_condtree_out_unobserved.ll    THE N1
//       DISCRIMINATOR (unchanged by the fix, `opt` exit 1 both sides — that IS its
//       job): the same AND-node module with the merge OUT never read. The hop
//       reaches the out rail; the out rail is not a sink. Without it the two N1
//       accepts read as "a condition-tree gate exempts whatever flows into it",
//       which is the retired MENTIONED-LATER reading
//   * lowering_reject_live_record_clone_unused_arg.ll           N3: the clone hop
//       must not cross an argument the callee IGNORES. MEASURED `opt` exit 0 on
//       the round-1 tree (an over-accept), exit 1 after. IR-ONLY — `clang -O1` DAE
//       drops the dead parameter — and ruled on constructed probes exactly as F1
//       and F2 were
constexpr char kMsgLiveRecord[] =
    "cq rotation lowering: non-diagonal gate over a live derived record";

// The called OPERAND's own name, never `getCalledFunction()` — the bd xy9n
// lesson (LiteralIntegrity.cpp): `getOrInsertFunction` may resolve to a
// `GlobalAlias`, for which `getCalledFunction()` is null and every name test
// silently fails open.
StringRef emittedCalleeName(const CallInst *CI) {
  const auto *GV = dyn_cast_or_null<GlobalValue>(CI->getCalledOperand());
  return GV ? GV->getName() : StringRef();
}

// A RECORD PRODUCER mints a FRESH rail holding a basis function of its operands:
// the `cq_template_*` data/compare/cast family and the 7.5 `cqrt_qram_load_*`
// (a Toffoli copy-out). Clause 1 of the ruled predicate names exactly these two.
//
// DELIBERATELY NOT PRODUCERS, each for its own reason:
//   * `cqrt_alloc_*` — a rail, but ITS OWN predicate (`isAllocRail`, Increment 3):
//     it is a record and the walk stops at its classical seed operand.
//   * `cqrt_qram_alloc_*` — the QRAM ARRAY record class, RULED DEFERRED (owner
//     2026-08-27 (4)); `isQramArrayHandle` stops the walk there. Pinned by
//     lowering_qram_array_record_chained_theta_accept.ll.
//   * `cqrt_tape_write_*` — an OUTPUT sink's kept entry (`taint.OutputRails`),
//     never a scratch record.
//   * anything VOID (`cqrt_qram_store_*`, the route/copy gates, the rotations) —
//     an in-place mutation mints no rail at all.
//   * the `_unc` / `_inv` twins — adjoints, not forward producers.
//
// ── THE SEVERANCE CLASSES: WHERE THEY STAND AFTER INCREMENT 3 ────────────────
//
// A production that mints a basis record of the wire through a VOID writer into
// an ALLOC-MINTED destination is invisible to a PRODUCER-edge walk, because there
// is no producer edge to follow: the record's SSA value comes from
// `cqrt_alloc_<W>`, whose only operand is a classical seed. Four such classes
// exist; Increment 3 closes the first three with the COPY-DESTINATION edge in
// `collectAncestorRecords`/`collectDescendantRecords` (a rail that is the DST
// operand of a void `cqrt_copy_<W>` / `cqrt_copy_<W>_controlled` is a record, and
// the walk crosses to its SRC and CONTROL flag):
//
//   1. `cqrt_copy_<W>(src, out)` DESTINATIONS — the Phase-4 method-B value-arm
//      answer rail and a Phase-6 clone's Bennett return (`cqq.out`). **CLOSED.**
//      The clone-return sub-case was Increment 1's owned residual over-accept and
//      is now `lowering_reject_live_record_clone_return_rail.ll`.
//   2. SELECT-MERGE out rails (4.4) and SWITCH DATA-MUX out rails (4.5) — the
//      `cqrt_copy_<W>_controlled` destinations. **CLOSED** at this guard.
//   3. VALUE-ARM MERGE outs. **CLOSED** at this guard.
//   4. `cqrt_qram_store_<W>` ARRAY CELLS — **STILL THE RULED-DEFERRED CLASS**
//      (owner 2026-08-27, second round, point 4). `isQramArrayHandle` stops the
//      walk dead in both directions; pinned by
//      lowering_qram_array_record_chained_theta_accept.ll.
//
// REACHABILITY, RE-MEASURED FOR INCREMENT 3 — and the Increment-1 note here was
// WRONG about it, in the over-accepting direction. That note said classes (2) and
// (3) "ARE masked today" by bd test_C_libtooling-lom0's position-free
// `condWireDisposition` over-decline. Measured on the four natural C
// spellings, that is FOUR different facts:
//
//   * a tainted `?:` — and a `switch` whose cases `clang -O1` folds into
//     arithmetic — canonicalize to a **`select`**. `SelectClassify` DOES run a
//     position-free wire walk (SelectClassify.cpp ~691, the lom0 mechanism
//     transplanted), but it is seeded from the CONDITION's provenance, and the
//     merge OUT is a fresh `cqrt_alloc`-minted rail that is not on that wire —
//     so a chained theta on the OUT is invisible to it. Both compiled end to end
//     at HEAD (`opt` exit 0): a **LIVE OVER-ACCEPT**, never masked at all. Closed by
//     the copy-destination edge; the flag itself is usually exempt (stripped and
//     freed by the region teardown) but the walk passes THROUGH it to the
//     condition's own operands, which are not.
//     (lowering_reject_live_record_select_merge_out.ll,
//      lowering_reject_live_record_select_merge_tainted_src.ll)
//   * a real `switch` + merge phi declines at `SwitchClassify` with "control flow
//     under quantum control" (lowering_reject_live_record_switch_mux_out_masked.ll).
//   * a real `br` value-arm diamond declines with "value-arm swap-route under
//     quantum control" (lowering_reject_live_record_valuearm_merge_out_masked.ll).
//   * of the four pins only the ROUTED-BASE phase region wore lom0's own
//     message — note `SelectClassify` emits the SAME string for a theta on the
//     condition wire of a `?:`, which is a different shape from the OUT-rail one
//     above.
// RE-MEASURED AT INCREMENT 4 (the lift landed): that one moved to
// `kMsgLiveRecord` and is now `lowering_reject_live_record_routed_base_anc.ll`;
// the other three are byte-identical (they never declined at ArmClassify's wire
// walk). None landed on `opt` exit 0.
//
// The `_unc` twins of all four writers are adjoints, not forward producers, and
// are excluded above for that reason, not as part of any scope gap.
bool isRecordProducer(const CallInst *CI) {
  if (CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  if (N.ends_with("_unc") || N.ends_with("_inv"))
    return false;
  return N.starts_with("cq_template_") || N.starts_with("cqrt_qram_load_");
}

// R's OWN discharge: `cqrt_free(R)`, or an out-first `_unc` whose OUT slot is R
// (the DD-3 convention every adjoint but the QRAM store follows — a store `_unc`
// takes the same args as its forward and mints no rail, so it discharges none).
bool isDischargeOf(const CallInst *CI, const Value *R) {
  StringRef N = emittedCalleeName(CI);
  if (N == "cqrt_free")
    return CI->arg_size() == 1 && CI->getArgOperand(0) == R;
  if (!N.ends_with("_unc") || N.starts_with("cqrt_qram_store_"))
    return false;
  return CI->arg_size() >= 1 && CI->getArgOperand(0) == R;
}

bool isRecordedUserRotation(const CallInst *CI, const TaintSet &taint) {
  return taint.UserSourceRotations.count(CI) ||
         taint.UserChainedRotations.count(CI) ||
         taint.UserPhaseRotations.count(CI);
}

// TEARDOWN traffic — the compiler undoing ITSELF, which the owner ruled is NOT a
// user data use (2026-08-27 (3); SPIKE §2R.5a). Three sources, in order of force:
//   1. `taint.SpineOps` — EMITTER-RECORDED. The only way to recognize a
//      re-emitted SELF-INVERSE gate (`cqrt_cswap` route-back, `cqrt_x` bracket,
//      `cqrt_toffoli`/`cqrt_cnot`, `cqrt_copy_*_controlled`, `cqrt_xorc/addc`),
//      which is byte-identical to its own forward.
//   2. structural, and exact: `cqrt_free` is compiler-emitted only (Rule 6), and
//      the `_unc` family is minted only by `EmitInverse` — no user surface spells
//      either.
//   3. a rotation that is NOT a recorded user gate is the spine's negated-angle
//      adjoint. This is the emitter-keyed answer to census blind spot A8.
//
// "NOT TEARDOWN" IS NOT "DATA USE", AND THIS PARAGRAPH USED TO SAY IT WAS.
// The retired wording read: "EVERYTHING ELSE IS A USER DATA USE — a forward
// template read, `cqrt_measure_*`, a cswap/route slot, a copy/tape sink, a clone
// call, a plain-IR use … a forward Phase-4 route on a record is a real, reachable
// shape the ruling says to ACCEPT." Two owner rulings retired it in two steps:
// 2026-08-28's F2 ruling for rotations, and the SAME DAY's F1 ruling for the
// rest — "a record exempts only if its lineage reaches an OBSERVING sink after
// the gate — measure / ret / tape / a template read that itself flows to one".
//
// So a ROUTE IS NOW A NON-USE, not a data use. `cqrt_cswap` / `cqrt_x` /
// `cqrt_cnot` / `cqrt_toffoli` move a value onto a work rail and back onto its
// own rail; nothing is observed, and if the rail is measured later that measure
// is a DIRECT user of the rail and counts on its own. The over-accept this
// closed is measured, not hypothetical: a dead sibling whose only post-gate fate
// was a compare feeding a phase region — flag minted, stripped and freed —
// exempted on the route/compare mentions and the module ACCEPTED, while the same
// program with the region moved BEFORE the gate DECLINED on identical rails
// (lowering_reject_live_record_sibling_region_after_theta.ll vs
// lowering_reject_live_record_anc_dead_sibling.ll).
//
// WHAT THIS FUNCTION STILL DECIDES, AND ITS FAIL DIRECTION. It answers only "is
// this the compiler undoing ITSELF?", and it is consumed by
// `reachesObservingSink` as ONE of the non-use categories. The three sources
// above stay exactly as written, including the rotation arm — "a user
// `cqrt_ry`/`cqrt_rz` naming a record ⇒ not teardown" is still true, the walk
// simply treats user rotations as non-uses of its own (F2). Because the walk's
// DEFAULT is now "not a sink", an UNRECORDED self-inverse gate no longer
// exempts anything, which reverses the fail direction recorded in
// TaintPropagation.h's `SpineOps` comment for THIS consumer: a missed
// `SpineOps` recording can now only over-DECLINE here. The `BennettWrap`
// residual documented there is unchanged and still structurally unreachable
// from a guard site (its emissions live inside a clone body, and a clone is
// theta-free by construction, so it holds no `UserChainedRotations` member).
// Pinned by lowering_reject_live_record_post_theta_user_rz.ll (F2; its user Rz is
// gone since 3qlq, see above) and ..._sibling_region_after_theta.ll (F1).
bool isTeardownUse(const CallInst *CI, const TaintSet &taint) {
  if (taint.SpineOps.count(CI))
    return true;
  StringRef N = emittedCalleeName(CI);
  if (N == "cqrt_free" || N.ends_with("_unc"))
    return true;
  if (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_"))
    return !isRecordedUserRotation(CI, taint);
  return false;
}

// `provablyBefore` — "IF `B` executes, `A` has already executed, and `A` never
// runs again after it." NO LONGER DEFINED HERE: it is `WireWalk.h`'s exported
// spelling (bd 6uqc Inc 2a folded this private copy into it when the M-C
// deadness fence became a third caller — Rule 14; two spellings of one relation
// are how `railOf`/`isAbiQramStore` came to disagree). The modality note below
// is retained because it is about THIS file's clauses, not about the helper.
//
// READ THE MODALITY, because the two callers need DIFFERENT ones and this helper
// supplies only the first:
//   * CLAUSES 2 and 4 ask "did the discharge / measurement HAPPEN before the
//     gate?" — a CONDITIONAL-on-B property, and `provablyBefore(Use, T)` is
//     exactly it: `T` is the gate, so if the gate executes the discharge did.
//     Sound as written.
//   * CLAUSE 3 asks "WILL a user read this record after the gate?" — an
//     UNCONDITIONAL property (post-dominance), which dominance does NOT give.
//     `provablyBefore(T, Use)` proves only that IF the use runs, it runs after
//     the gate. So a record read on ONE arm of a CLASSICAL branch that follows
//     the gate is EXEMPTED even though the other arm never reads it. That gap is
//     KNOWN and measured, not overlooked:
//       - `b1`: `theta; %d = add; T; br i1 %c` with `measure(%d)` in one arm and
//         nothing in the other  ⇒ ACCEPTS (the permissive edge).
//       - `b2`: the reader in one arm and the chained theta in the OTHER
//         ⇒ DECLINES (dominance fails, so no exemption — the conservative side).
//     Tightening clause 3 to a `PostDominatorTree` query would flip `b1` to a
//     decline; it is left permissive deliberately, on the ruled ground that a
//     record any user can still read is the program's own data. Changing this is
//     a scope decision (bd test_C_libtooling-6uqc), not a bug fix.
//
// ...AND THE SAME MODALITY HAS A COST IN THE *OTHER* DIRECTION, INSIDE A LOOP.
// This is the reviewer's N4 from round 2 of the Increment-3 Rule-13 round
// (2026-08-28), recorded here as a note; NOTHING in this file changes for it, and
// it is tracked in bd rather than fixed under this increment.
//
// `provablyBefore(T, Use)` is `DT.dominates(T, Use) && !isPotentiallyReachable(
// Use, T)`. Inside a LOOP BODY the second half fails for EVERY use — the back edge
// makes `T` reachable again — so NO RECORD IN A LOOP BODY CAN EVER BE EXEMPTED BY
// AN IN-BODY OBSERVATION, no matter how directly the program measures it. That is
// the same back edge the clause-6 existence skip needs (and correctly gets:
// lowering_reject_live_record_post_gate_record_loop.ll), read from the other side.
//
// MEASURED, on ordinary C through the real pipeline:
//     for (int i = 0; i < n; i++) {
//         int q = u0; cq_theta(&q, 0.25);
//         int w = q * 2;
//         cq_theta(&w, 0.5);                    // T
//         acc += cq_measure(q) + cq_measure(w);    // BOTH rails measured, in body
//     }
// HEAD (d2828e3) `opt` exit 0; Increment 3, both round 1 and round 2, exit 1. Every
// record is measured in the iteration that mints it, so nothing is dead at the gate
// — the ancestor rail declines anyway. It is an OVER-decline (the safe direction,
// not a Prime-Directive defect), but it is a real capability loss on the shape
// Grover repetition is written in. A fix belongs with a LOOP-AWARE clause 3 — an
// observation anywhere in the same iteration's body, or a post-dominance reading
// that admits the back edge — which is a scope decision, not a bug fix, and which
// would also hand the loop fixture the isolating F2 witness its header wants.

// A Phase-6 SPECIALIZED CLONE call returning a value (`__cq_q_<callee>_<mask>`).
// A value-preserving HOP the walk crosses in both directions — AND, since M-A
// Increment 3, a RECORD in its own right: the result is a `cqrt_alloc`-minted
// `cqq.out` rail written by a VOID `cqrt_copy_<W>` inside the clone body, i.e.
// the COPY-DESTINATION class (severance class 1), which this increment closes.
// The `_unc` twin (`@__cq_q_<inner>_<mask>_unc`, 6.3) is void and adjoint
// traffic, never a forward hop.
bool isCloneCallHop(const CallInst *CI) {
  if (CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  return N.starts_with("__cq_q_") && !N.ends_with("_unc");
}

// …BUT THE HOP IS PER-ARGUMENT, and only the observing-sink walk is allowed to
// assume otherwise (round 2 of the Increment-3 Rule-13 round, 2026-08-28).
//
// `isCloneCallHop` says "this call forwards a value"; it does NOT say that THIS
// argument is one of the values forwarded. A clone that IGNORES a parameter
// returns a result independent of it, so exempting a record on "the clone's
// result is measured" was an OVER-ACCEPT — the record stands dephasing at the
// gate and nothing anywhere observes it. Measured on
// `@__cq_q_inner_11(%x, %y)` with `%x` unread: `opt` exit 0 in the pre-round-2
// tree, and the whole module's only sink is `cqrt_measure(%r)`. Pinned by
// lowering_reject_live_record_clone_unused_arg.ll UNTIL bd vsfp (2026-09-26).
//
// ⚠ SINCE bd vsfp ROUND 3 NO MODULE-LEVEL CALL READS A RECORDED-DEAD SLOT AT ALL.
// `dropDeadCallArguments` replaces an argument whose callee parameter is DEAD
// (the liveness predicate, `DeadValueLiveness.h`) by a constant before
// `detectSpecializations` (that fixture's `inner(%c, %p)` is now `inner(0, %p)`,
// its dead sibling deleted, and it pins the twin's stream), and
// `resolvePhantomCloneArgReads` NEUTRALISES every slot the specializer RECORDED
// dead in a built clone (a slot only the clone's own flatten killed) right after
// `specialize()`, before this walk runs. ⚠ The round-2 sentence here — "this
// branch is reached only by such a register (never a derived record)" — was
// FALSE (bd vsfp Rule-13 r2B F-WB-3): round 2's keeper exemption let a derived
// record (`k5`: `p = q*3`, kept by a measure) reach this predicate through a dead
// slot, and the `use_empty()` test below then emitted a spurious lyyf-(B) warning
// the twin does not. Both halves are gone: no dead-slot read survives to here,
// and the test asks the specializer's RECORD (`isRecordedDeadSlot`, the ONE
// spelling of "slot unread" — Rule 14; this was a THIRD, `use_empty()` one).
//
// IR-ONLY, and said plainly because it changes how the pin must be read: `clang
// -O1` runs DAE and DROPS a parameter no callee body reads, so the natural C
// spelling never reaches the pass in this shape (measured — the dead sibling is
// DCE'd with it). The ruling direction is the F2/F1 one: a construct nothing
// observes buys nothing by being accepted, and both of those were likewise ruled
// on constructed probes.
//
// FAIL DIRECTION — an UNRESOLVABLE callee gets NO hop. `getCalledFunction()` is
// null for a `GlobalAlias` and every name test then silently fails open (the bd
// xy9n lesson this file already obeys via `emittedCalleeName`), so the callee is
// resolved by an explicit `dyn_cast<Function>` on the called OPERAND — an alias,
// a bitcast or an indirect call does not resolve, and an unresolved callee, a
// body-less declaration and an argument past a varargs boundary all return false.
// That is the DECLINE direction, which is the safe one here.
//
// WHAT THE TEST IS, PRECISELY (bd vsfp round 3; round 6): the specializer's RECORD —
// the slot is read iff the callee is a clone `buildClone` recorded and the record
// does not call the slot dead AND null-safe (`isRewritableDeadSlot`, the one slot
// question liveness, the rewrite and M-C (d0) ask — Rule 14; round 3–5 asked the
// bare `isRecordedDeadSlot` here). ⚠ NOT CONSERVATIVE HERE (bd `x8ut`, r6 F-R6-2):
// this predicate's one caller is `reachesObservingSink`, the clause-3 EXEMPTION
// walk, so a hop EXEMPTS a record; round 6 moved a recorded-dead, not-null-safe
// slot from "no hop" to "hop" — the exempting direction — and called it
// conservative. It is UNREACHABLE today, and that is the whole argument: M-A gates
// are rotations, rotations occur only in non-clone functions (`scanBody` declines
// `cq_theta` in a clone), and there `resolvePhantomCloneArgReads` step 1 DECLINES a
// quantum operand in a recorded-dead, not-null-safe slot before `lowerRotations`.
// RETIREMENT TRIGGER (L8): if that decline is relaxed or moved after
// `lowerRotations`, or a rotation can occur inside a clone body, revert this test
// to the bare `isRecordedDeadSlot` — the honest question here is "does the clone's
// result depend on this argument?", whatever null-safety says. A call to a `__cq_q_*` function
// with NO record gets no hop (the decline direction). The record is LIVENESS, not
// a use test, so it also closes the old residual one level up (Inc-3 Rule-13
// round 2, reviewer probe q3: a parameter read only by an in-body compare that is
// stripped and freed, the return computed from the OTHER parameter — a dead
// compare reaches no root, so the slot is recorded dead and there is no hop). It
// is still not a DATAFLOW test: a parameter that reaches a live root other than
// the returned value (e.g. a measured intermediate) is "read" and hops.
//
// NOT APPLIED TO THE CLAUSE-1 WALKS, deliberately. `collectDescendantRecords` /
// `collectAncestorRecords` cross a clone call to decide what COUNTS as a record;
// crossing an unused parameter there only ADDS records, i.e. over-declines, so
// tightening it would be a scope change with no safety argument behind it.
bool cloneArgReachesResult(const CallInst *CI, const Value *In,
                           const TaintSet &taint) {
  const auto *F = dyn_cast<Function>(CI->getCalledOperand());
  if (!F || F->isDeclaration() || !taint.SpecDeadArgMask.count(F))
    return false;  // no clone record: no hop (the decline direction).
  for (unsigned K = 0, E = CI->arg_size(); K != E; ++K) {
    if (CI->getArgOperand(K) != In)
      continue;
    if (K >= F->arg_size())
      return false;  // past the varargs boundary — no `Argument` to interrogate.
    if (!isRewritableDeadSlot(*CI, K, taint))
      return true;  // a read, or a recorded-dead, not-null-safe slot (kept) — the
                    // EXEMPTING direction; unreachable today (bd x8ut, see above).
  }
  return false;
}

// ── M-A Increment 3 — the ANCESTOR half of clause 1 ──────────────────────────
//
// A `cqrt_alloc_<W>` WORK RAIL. bd test_C_libtooling-nepx's `h0` class: the
// source rail an out-of-place `_hl` template leaves standing behind its own
// result, and the DESTINATION every void copy gate writes into. Increment 1
// excluded it by scope; the ruled predicate's clause 1 says "alloc-minted rails
// included", and this is that clause. NOT `cqrt_qram_alloc_<W>` — the prefixes
// are disjoint (`cqrt_alloc_` vs `cqrt_qram_alloc_`) and the array class is
// ruled DEFERRED, below.
bool isAllocRail(const CallInst *CI) {
  return emittedCalleeName(CI).starts_with("cqrt_alloc_");
}

// A QRAM ARRAY handle (`cqrt_qram_alloc_<W>`) — SEVERANCE CLASS 4, RULED
// DEFERRED (owner 2026-08-27, second round, point 4). The walk STOPS here in
// BOTH directions: the handle is never pushed as a record, and the walk never
// follows a `cqrt_qram_store_<W>` into a cell. Pinned by
// lowering_qram_array_record_chained_theta_accept.ll; the boundary is visible in
// lowering_reject_live_record_qram_fp64_load_index.ll, where the decline is
// carried entirely by the load's INDEX operands while the carrier reachable only
// THROUGH the array stays uncounted.
bool isQramArrayHandle(const CallInst *CI) {
  return emittedCalleeName(CI).starts_with("cqrt_qram_alloc_");
}

// A void BASIS COPY gate. Two spellings, and the DESTINATION is the LAST operand
// in both — verified against runtime/cq_runtime.h:293-343
// (`void cqrt_copy_<W>(src, dst)`, `void cqrt_copy_<W>_controlled(ctrl, src,
// dst)`) and against every emission site rather than assumed — all ten put the
// destination last: BennettWrap.cpp:82 `{ResultRail, Out}`, SwapRouteEmit.cpp:361
// `{Q, Out}` (value-arm route, retired by 3qlq), SelectMergeEmit.cpp:242/250 and
// SwitchDataMuxEmit.cpp:200 `{Flag, Src, Out}`, IOSinkLowering.cpp:779/782,
// ClassicalCallArmEmit.cpp:233/241, Specialization.cpp:351/361/369,
// BreakReversePlay.cpp:552-660, QramLowering.cpp:1883
// (re-verified by the Inc-3 Rule-13 round, 2026-08-28).
// The family is SELF-INVERSE, so there is no `_unc`/`_inv` twin to exclude
// (cq_runtime.h:269, :317).
//
// EXPORTED (bd rhk5 round 2, Rule 14 — r1A F-r1A-6 / r1B F-6): `ChainWalk`'s
// clone-body proof asks the same ABI fact, and its first spelling re-derived it
// inline. The anonymous namespace is closed around this one definition only; the
// body is unchanged.
}  // namespace

bool isCopyGate(const CallInst *CI) {
  if (!CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  if (!N.starts_with("cqrt_copy_"))
    return false;
  return CI->arg_size() == 2 || CI->arg_size() == 3;
}

namespace {

// What the walk does with a value it has reached.
enum class RailKind {
  Opaque,     // not a rail the walk understands — stop, record nothing
  Record,     // a producer / alloc / clone-return rail — count it, keep walking
  Router,     // a phi/select of handles — an ALIAS of the wire, never a record
  QramArray,  // the ruled-deferred class 4 — stop dead
};

RailKind classifyRail(const Value *V) {
  if (isa<PHINode>(V) || isa<SelectInst>(V))
    return RailKind::Router;
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return RailKind::Opaque;
  if (isQramArrayHandle(CI))
    return RailKind::QramArray;
  if (isRecordProducer(CI) || isAllocRail(CI) || isCloneCallHop(CI))
    return RailKind::Record;
  return RailKind::Opaque;
}

// One record set, built by two walks that share a `Recorded` set (so a rail
// reached from both directions is pushed once) and a `Wire` exclusion (clause 5).
struct RecordSet {
  const Value *Wire = nullptr;
  SmallVectorImpl<CallInst *> &Out;
  SmallPtrSet<const Value *, 32> Recorded;

  explicit RecordSet(const Value *W, SmallVectorImpl<CallInst *> &O)
      : Wire(W), Out(O) {}

  void push(Value *V) {
    if (V == Wire)  // clause 5 — the in-place gate chain on the same handle
      return;
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || classifyRail(V) != RailKind::Record)
      return;
    if (Recorded.insert(CI).second)
      Out.push_back(CI);
  }
};

// Collect the transitive DESCENDANT record closure of `Seed` (clause 1, forward).
//
// THE WALK CROSSES A CLONE CALL (the Increment-1 Rule-13 round's F1 blocker,
// measured): a non-void `__cq_q_*` result used to sever the walk, so every
// `cq_template_*` rail computed from a clone's return value was invisible and the
// program compiled end to end — while the SAME program written inline declined.
// Putting an expression behind a `noinline static` cannot change what the wire is
// entangled with. Increment 3 additionally PUSHES the clone result (the
// copy-destination class, severance class 1) and follows the forward
// `cqrt_copy_<W>` SRC→DST edge, so a basis copy of the wire is a record wherever
// the void gate put it.
void collectDescendantRecords(Value *Seed, RecordSet &RS,
                              SmallPtrSetImpl<const Value *> &Seen) {
  SmallVector<Value *, 8> Work;
  if (!Seen.insert(Seed).second)
    return;
  Work.push_back(Seed);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (classifyRail(V) == RailKind::QramArray)
      continue;  // never follow a store into an array cell
    for (User *U : V->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI)
        continue;
      // COPY-DESTINATION edge, forward: `V` is the SRC, so the DST records it.
      if (isCopyGate(CI)) {
        unsigned N = CI->arg_size();
        if (CI->getArgOperand(N - 2) != V)
          continue;
        Value *Dst = CI->getArgOperand(N - 1);
        if (!Seen.insert(Dst).second)
          continue;
        RS.push(Dst);
        Work.push_back(Dst);
        continue;
      }
      if (!isRecordProducer(CI) && !isCloneCallHop(CI))
        continue;
      if (!Seen.insert(CI).second)
        continue;
      RS.push(CI);  // a record minted FROM a record counts too
      Work.push_back(CI);
    }
  }
}

// Collect the transitive ANCESTOR record closure of `W` (clause 1, backward) and
// hand back every rail it reached in `Seeds`, so the caller can run the forward
// walk from each — that second pass is what reaches a DEAD SIBLING under a LIVE
// ancestor, which is the ruling's "transitively entangled" and is pinned by
// lowering_reject_live_record_anc_dead_sibling.ll.
//
// THREE EDGES, and the third is the one that crosses a SEVERANCE:
//   (a) the PRODUCER edge — a `cq_template_*` / `cqrt_qram_load_*` / clone-call
//       definition's own i32 rail operands. Only `Instruction` operands are
//       followed: a literal is a `ConstantInt` and a function parameter is an
//       `Argument`, so both stop the walk without a grammar test (an `_hl` vs
//       `_lh` vs `_qq` suffix parse would be a second spelling of the ABI —
//       Rule 14 says don't mint one).
//   (b) a `cqrt_alloc_<W>` is a RECORD but its operand is a CLASSICAL SEED — the
//       walk stops there rather than wandering into classical provenance.
//   (c) the COPY-DESTINATION edge — if the reached rail is the DST operand of a
//       void copy gate, its SRC (and, for the controlled form, its CONTROL flag)
//       are ancestors. This is the only way to reach the four rails whose basis
//       content arrives through a void writer into an alloc-minted destination:
//       value-arm answer rails, clone `cqq.out` returns, select-merge outs and
//       switch-data-mux outs. Note the flag is USUALLY exempt on its own (it is
//       `_unc`-stripped and freed by the region teardown before the gate) — the
//       walk still passes THROUGH it to reach the condition's own operands, which
//       are typically not.
// A phi/select of handles is NOT a record (it is an alias of the wire — the bd
// tayx one-register router forwards the same physical handle); the walk recurses
// into its incoming values. Void users (`cqrt_addc`/`subc`/`xorc`, the rotations,
// the routes) mint no rail and are never producers — the backward walk looks only
// at DEFINITIONS, plus the copy-destination USER scan of (c).
void collectAncestorRecords(Value *W, RecordSet &RS,
                            SmallVectorImpl<Value *> &Seeds) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<const Value *, 16> Visited;
  auto enqueue = [&](Value *V) {
    if (V && Visited.insert(V).second)
      Work.push_back(V);
  };
  enqueue(W);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    RailKind K = classifyRail(V);
    if (K == RailKind::QramArray)
      continue;  // severance class 4, ruled deferred
    if (K != RailKind::Opaque) {
      RS.push(V);          // no-op for the wire itself and for a Router
      Seeds.push_back(V);  // ...but every rail seeds the sibling pass
    }

    // (c) COPY-DESTINATION edge, backward.
    for (User *U : V->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || !isCopyGate(CI))
        continue;
      unsigned N = CI->arg_size();
      if (CI->getArgOperand(N - 1) != V)
        continue;  // V must be the DESTINATION
      enqueue(CI->getArgOperand(N - 2));  // the copied SOURCE
      if (N == 3)
        enqueue(CI->getArgOperand(0));  // the CONTROL flag
    }

    if (K == RailKind::Router) {
      if (auto *Phi = dyn_cast<PHINode>(V)) {
        for (Value *In : Phi->incoming_values())
          enqueue(In);
      } else {
        auto *Sel = cast<SelectInst>(V);
        enqueue(Sel->getTrueValue());
        enqueue(Sel->getFalseValue());
      }
      continue;
    }
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI)
      continue;
    if (isAllocRail(CI))
      continue;  // (b) classical seed — stop
    if (!isRecordProducer(CI) && !isCloneCallHop(CI))
      continue;
    for (Value *Op : CI->args())  // (a)
      if (isa<Instruction>(Op))
        enqueue(Op);
  }
}

// A Phase-7.5 Shadow STORE, either spelling, and where its ARRAY operand sits.
// Verified against runtime/cq_runtime.h:553-603:
//   `void cqrt_qram_store_<W>(arr, idx, val)`                  — 3 args, arr = 0
//   `void cqrt_qram_store_<W>_controlled(pred, arr, idx, val)` — 4 args, arr = 1
// The `_unc` twins of both are classified as teardown BEFORE this runs, so there
// is no exclusion to make here.
bool isQramStoreGate(const CallInst *CI, unsigned &ArrPos) {
  if (!CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  if (!N.starts_with("cqrt_qram_store_"))
    return false;
  if (N.ends_with("_controlled") && CI->arg_size() == 4) {
    ArrPos = 1;
    return true;
  }
  if (!N.ends_with("_controlled") && CI->arg_size() == 3) {
    ArrPos = 0;
    return true;
  }
  return false;
}

// ── CLAUSE 3's OBSERVING-SINK WALK (owner ruling 2026-08-28, the F1 fix) ─────
//
// "A record exempts only if its lineage reaches an OBSERVING sink after the gate
// — measure / ret / tape / a template read that itself flows to one."
//
// WHAT THIS REPLACED, AND WHY IT HAD TO. Until this fix clause 3 exempted `R` on
// ANY post-gate use that was neither teardown nor a recorded user rotation. That
// read "somebody mentions it later" as "the program's own data", and the two are
// not the same thing: a dead sibling whose only post-gate fate is a COMPARE whose
// flag a Phase-4 region strips and frees is mentioned four times and observed
// zero times. It exempted, and the module ACCEPTED — while the SAME program with
// the region moved BEFORE the gate DECLINED, on identical rails standing at the
// gate with identical physics. That before/after asymmetry is exactly what the F2
// ruling was made to eliminate for rotations; this is the same ruling applied to
// the rest of the use grammar.
//
// Returns true iff a forward walk of the VALUE FLOW out of `U` (the post-gate use
// of record `R`) reaches an OBSERVING SINK. The three categories, and note that
// the SAFE direction is "not a sink": a use the walk does not understand exempts
// nothing, so the module declines.
//
//   SINKS   — `cqrt_measure_*` (any operand: the collapse observes the rail),
//             `ret` (an ESCAPE; the caller owns the register and may observe it),
//             `cqrt_tape_write_*` in its WRITTEN slot (the 7.6 output tape — its
//             `out_handle` is `taint.OutputRails`, a kept output, never freed)
//             AND, since round 2, in the CTRL slot of its guarded 3-argument
//             spelling (the entry's presence or absence reveals the flag).
//   HOPS    — the value flows onward and the walk continues from what it became:
//             a non-void forward `cq_template_*` read or `cqrt_qram_load_*`
//             (`isRecordProducer`) → its result; a `__cq_q_*` clone call
//             (`isCloneCallHop`) → its result, but ONLY for an argument the
//             clone's body actually reads (`cloneArgReachesResult`, round 2); a
//             void `cqrt_copy_<W>` / `_controlled` with the value in the SRC or
//             CTRL slot → the DST rail; a `phi`/`select` → its result; a
//             `cqrt_qram_store_<W>` / `_controlled` with the value in the IDX,
//             VAL or PRED slot → THROUGH THE ARRAY, i.e. the result of every
//             later `cqrt_qram_load_*` on the same array handle (the array-cell
//             class is ruled-deferred as a RECORD — `isQramArrayHandle` — but
//             that is about what counts against the gate; this is about whether
//             the user can still SEE the value, and through a store-then-load
//             they can); and a CONTROL slot of `cqrt_cnot` / `cqrt_toffoli` →
//             their TARGET ancilla (round 2 — the condition-tree node).
//   NON-USES— `cqrt_free`, every `_unc`/`_inv`, `taint.SpineOps` (the compiler
//             undoing itself), ALL rotations (the F2 ruling: a phase written onto
//             a never-observed register is unobservable, so `cqrt_ry`/`cqrt_rz`
//             observe nothing whether the emitter recorded them as USER gates or
//             not), the ROUTE/BRACKET gates `cqrt_cswap` / `cqrt_x`, and the
//             TARGET slot of `cqrt_cnot` / `cqrt_toffoli`. A ROUTE is not an
//             observation: a routed value comes back to its own rail, and if that
//             rail is later measured the measurement is a DIRECT user of the rail
//             and counts on its own. Anything else — a plain-IR instruction, an
//             unmodelled call — is conservatively neither, which is the decline
//             direction.
//
// ROUND 2 OF THIS RULE-13 ROUND (2026-08-28) MOVED THREE ENTRIES OF THAT GRAMMAR,
// and TWO of them WIDEN the exemption — the dangerous direction, so each one is
// stated with the measurement that forced it. The per-entry argument lives at the
// code below; here is the shape of it:
//   N1  `cqrt_cnot`/`cqrt_toffoli`: NON-USE → CONTROL-slot HOP. They had been
//       filed with `cqrt_cswap`/`cqrt_x` on the route argument, which is FALSE for
//       them — they write the controls' information into a FRESH ancilla the merge
//       reads, not back onto the value's own rail. Measured C-reachable
//       over-decline (an `&`/`^` of two tainted compares steering a `?:` whose
//       result is measured): HEAD `opt` exit 0, pre-round-2 tree exit 1.
//   N2  a guarded `cqrt_tape_write_<W>_controlled`'s CTRL slot: not-a-sink → SINK.
//       Measured C-reachable over-decline (`if (c > 3) printf("%d", a);`) whose
//       SRC-slot twin (`printf("%d", c)`) always accepted.
//   N3  the clone hop: unconditional → per-argument. The DECLINE direction, and
//       IR-only (`clang -O1` DAE removes an unread parameter), ruled on
//       constructed probes exactly as F1 and F2 were.
//
// A COMPARE whose flag is only stripped needs no rule of its own: the compare is
// a HOP, and the flag's users are then non-uses (a kickback `cqrt_rz_i1`, `cqrt_x`,
// `_unc`, `cqrt_free`), so the walk runs out: the h4 shape. A compare whose flag
// feeds a condition-tree NODE is the N1 shape and does hop — but only as far as
// the node ancilla, so if nothing reads the merge OUT the walk still runs out
// (`lowering_reject_live_record_condtree_out_unobserved.ll`).
//
// Deeper nodes carry NO position test — they are downstream of `U`, which the
// caller has already proved is after the gate — but they DO carry the F3
// reachability test: a sink in a block with no entry path cannot observe
// anything.
bool reachesObservingSink(Instruction *U, Value *R, const TaintSet &taint,
                          const DominatorTree &DT) {
  // Worklist entries are (INCOMING VALUE, USE) pairs, not bare instructions: a
  // copy gate and a QRAM store classify by WHICH SLOT the tracked value sits in,
  // so the walk has to remember what reached them.
  SmallVector<std::pair<Value *, Instruction *>, 8> Work;
  DenseSet<std::pair<const Value *, const Instruction *>> SeenUse;
  SmallPtrSet<const Value *, 16> Scanned;

  auto pushUse = [&](Value *In, Instruction *Use) {
    if (!In || !Use)
      return;
    if (!DT.isReachableFromEntry(Use->getParent()))
      return;  // F3 — an instruction that can never execute observes nothing.
    if (SeenUse.insert({In, Use}).second)
      Work.push_back({In, Use});
  };
  auto pushValue = [&](Value *V) {
    if (!V || !Scanned.insert(V).second)
      return;
    for (User *X : V->users())
      if (auto *XI = dyn_cast<Instruction>(X))
        pushUse(V, XI);
  };

  pushUse(R, U);
  while (!Work.empty()) {
    auto [In, I] = Work.pop_back_val();
    if (isa<ReturnInst>(I))
      return true;  // SINK — escape; the caller owns the register.
    if (isa<PHINode>(I) || isa<SelectInst>(I)) {
      pushValue(I);  // HOP — a router forwards the same content.
      continue;
    }
    auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;  // conservative: any other plain-IR instruction observes nothing.
    StringRef N = emittedCalleeName(CI);

    // ── SINKS ──
    if (N.starts_with("cqrt_measure_"))
      return true;
    if (N.starts_with("cqrt_tape_write_") && CI->arg_size() >= 2 &&
        CI->getArgOperand(CI->arg_size() - 1) == In)
      return true;  // the WRITTEN slot (`…(tape, src)` / `…(ctrl, tape, src)`).
    // …and so is the CTRL slot of the GUARDED spelling (round 2 of the Inc-3
    // Rule-13 round, 2026-08-28). `cqrt_tape_write_<W>_controlled(ctrl, tape,
    // src)` writes an entry IFF `ctrl` is set, so the PRESENCE OR ABSENCE of that
    // entry on the output tape reveals the flag to whoever reads the tape. A
    // record whose lineage reaches the flag is therefore observed just as surely
    // as one that reaches `src` — the reader learns a bit of it either way.
    // MEASURED as a C-reachable OVER-DECLINE: `c = a*k; cq_theta(&a,.25);
    // if (c > 3) printf("%d", a);` — `opt` exit 0 at HEAD, exit 1 in the
    // pre-round-2 tree; its SRC-slot twin (`printf("%d", c)`) always accepted.
    // Pinned by lowering_live_record_tape_ctrl_observed_accept.ll.
    //
    // ARITY, not the `_controlled` suffix, is the discriminator, and it is exact:
    // `cqrt_tape_write_<W>(tape, src)` is i32(i32,i32) and the `_controlled` twin
    // is i32(i32,i32,i32) — runtime/cq_runtime.h:445-454, WidthDispatch.cpp:242
    // and ControlledSymbols.cpp:147. Neither has an `_unc`/`_inv` twin (a tape
    // entry is a KEPT output, `taint.OutputRails`, never uncomputed), so the
    // prefix test cannot pick up adjoint traffic.
    if (N.starts_with("cqrt_tape_write_") && CI->arg_size() == 3 &&
        CI->getArgOperand(0) == In)
      return true;  // the CTRL slot of the guarded write.

    // ── NON-USES ── (`isTeardownUse` is REUSED verbatim for the spine half —
    // `SpineOps`, `cqrt_free`, the `_unc` family, the spine's negated-angle
    // adjoint rotations — so the two callers cannot drift, Rule 14.)
    if (isTeardownUse(CI, taint))
      continue;
    if (N.ends_with("_inv"))
      continue;  // the pre-8txa adjoint spelling, same reading as `_unc`.
    if (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_"))
      continue;  // the F2 ruling: a USER rotation observes nothing either.
    if (N == "cqrt_cswap" || N == "cqrt_x")
      continue;  // route / bracket gates — a routed value returns to its rail.

    // ── HOPS ──
    // CONDITION-TREE NODE GATES — a CONTROL slot HOPS to the TARGET (round 2 of
    // the Increment-3 Rule-13 round, 2026-08-28). `cqrt_cnot` and `cqrt_toffoli`
    // used to sit on the NON-USE line above beside `cqrt_cswap`/`cqrt_x`, and the
    // cswap rationale DOES NOT TRANSFER: a route puts a value on a work rail and
    // brings it back to its OWN rail, whereas a CNOT/Toffoli WRITES the controls'
    // information into a FRESH `|0⟩` ancilla that somebody else then reads. That
    // ancilla is the `and`/`or`/`xor` node of a condition tree
    // (`SelectClassify`/`ArmClassify`; the xor node is the openlibm ulp-direction
    // idiom bd 3c6m.67 admitted), and the merge reads it as the copy CONTROL.
    // MEASURED as a C-reachable OVER-DECLINE: `((c>3) & (d<9)) ? 10 : 20` with the
    // select's result measured left `c` exempt-less because the walk stopped dead
    // at the toffoli — `opt` exit 0 at HEAD, exit 1 in the pre-round-2 tree.
    // Pinned by lowering_live_record_condtree_toffoli_observed_accept.ll (AND) and
    // lowering_live_record_condtree_xor_observed_accept.ll (XOR).
    //
    // THE TARGET IS THE LAST OPERAND in both spellings — `void cqrt_cnot(ctrl,
    // tgt)` / `void cqrt_toffoli(c1, c2, tgt)` (runtime/cq_runtime.h:227-228),
    // re-verified against every mint site rather than assumed:
    // ControlledSymbols.cpp:57/69 declare them that way, and the four emitters put
    // the ancilla last — SelectMergeEmit.cpp:192/193/196 (forward) and :279/281/282
    // (the LIFO strip), Specialization.cpp:187/188/191, BreakReversePlay.cpp:568
    // (`{G, Fire}`), :589 and :685 (`{…, Efl, Fire}`). Both gates are involutions,
    // so there is no `_unc`/`_inv` twin to exclude; the arity test keeps the
    // 3-argument `cqrt_cnot_controlled` (cq_runtime.h:239) OUT of this arm, where
    // it falls through to "everything else" — the decline direction, since no
    // emitter mints it today.
    //
    // WHEN `In` IS THE TARGET this is a NON-USE, deliberately: the ancilla's own
    // users are scanned independently the moment some path pushes the rail itself,
    // so treating the write as an observation of the written rail would be a
    // second, weaker spelling of the same edge.
    if ((N == "cqrt_cnot" && CI->arg_size() == 2) ||
        (N == "cqrt_toffoli" && CI->arg_size() == 3)) {
      const unsigned NA = CI->arg_size();
      for (unsigned K = 0; K + 1 < NA; ++K)
        if (CI->getArgOperand(K) == In) {
          pushValue(CI->getArgOperand(NA - 1));  // CONTROL → the TARGET ancilla.
          break;
        }
      continue;
    }
    if (isCopyGate(CI)) {
      unsigned NA = CI->arg_size();
      if (CI->getArgOperand(NA - 2) == In ||
          (NA == 3 && CI->getArgOperand(0) == In))
        pushValue(CI->getArgOperand(NA - 1));  // the DESTINATION rail.
      continue;
    }
    unsigned ArrPos = 0;
    if (isQramStoreGate(CI, ArrPos)) {
      bool Feeds = false;
      for (unsigned K = 0, E = CI->arg_size(); K != E; ++K)
        if (K != ArrPos && CI->getArgOperand(K) == In)
          Feeds = true;  // IDX, VAL or (guarded form) PRED.
      if (!Feeds)
        continue;
      Value *Arr = CI->getArgOperand(ArrPos);
      for (User *X : Arr->users()) {
        auto *L = dyn_cast<CallInst>(X);
        if (!L || L->getType()->isVoidTy())
          continue;
        StringRef LN = emittedCalleeName(L);
        if (!LN.starts_with("cqrt_qram_load_") || LN.ends_with("_unc"))
          continue;
        if (!provablyBefore(CI, L, DT))
          continue;  // "SUBSEQUENT" — a load that already ran read the old cell.
        pushValue(L);
      }
      continue;
    }
    if (!CI->getType()->isVoidTy() && isCloneCallHop(CI)) {
      if (cloneArgReachesResult(CI, In, taint))
        pushValue(CI);  // a clone's returned `cqq.out` rail.
      continue;         // …otherwise the argument is DEAD in the callee — no hop.
    }
    if (!CI->getType()->isVoidTy() && isRecordProducer(CI)) {
      pushValue(CI);  // a forward template read or QROM load.
      continue;
    }
    // Everything else: not a sink, not a hop — the decline direction.
  }
  return false;
}

// bd test_C_libtooling-8h7d.5 (closing bd 58tc) — "`R` is NOT ALLOCATED when `T`
// fires", the implicit premise of clause 1, read PER ACTIVATION.
//
// The acyclic form is `provablyBefore(T, R)`: the record is minted strictly
// after the gate, so it cannot be standing at it. In a ROLLED LOOP that form is
// vacuously false for EVERY body record — the back edge always re-reaches `T` —
// and the guard's own comment records that as deliberate, because a record
// minted in the body and NEVER DISCHARGED genuinely IS standing at the next
// trip's gate. The distinction the acyclic form cannot draw is whether the
// previous iteration's instance was discharged before the back edge.
//
// So draw it: `R` is absent at `T` if it is minted after `T` in this activation
// AND every path from `R` back to `T` runs one of `R`'s own discharges. Then no
// instance can be allocated at `T` — an instance alive at `t_T` was minted at
// some `t_R < t_T`, and the trace segment `t_R … t_T` is a path from `R` to `T`,
// which by the walk contains a discharge of it. ∎
//
// MEASURED CUSTOMER: the second oracle's flag in a rolled Grover loop
// (`cq_template_icmp_eq_i32_hl(%h, 0)`), minted, stripped and freed AFTER the
// S-dagger `cqrt_ry` in the same trip. It warned; its hand-unrolled twin, which
// emits a BYTE-IDENTICAL trace, did not. An UNDISCHARGED body record finds no
// barrier on the back-edge path and still warns — which is the whole point.
bool recordAbsentAt(CallInst *R, CallInst *T, const DominatorTree &DT) {
  if (provablyBefore(T, R, DT))
    return true;  // the acyclic form — unchanged.
  for (User *U : R->users())
    if (auto *CI = dyn_cast<CallInst>(U))
      if (isDischargeOf(CI, R) && provablyBeforePerActivation(T, R, CI, DT))
        return true;
  return false;
}

// Clauses 2-4 for ONE record. Returns true iff `R` is EXEMPT at `T`.
bool recordIsExemptAt(CallInst *R, CallInst *T, const TaintSet &taint,
                      const DominatorTree &DT) {
  for (User *U : R->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      continue;
    if (auto *CI = dyn_cast<CallInst>(UI)) {
      // clause 2 — R's own discharge, provably before the gate.
      //
      // PER ACTIVATION since bd test_C_libtooling-8h7d.5 (which closes bd
      // test_C_libtooling-58tc, "no record inside a loop body can be exempted by
      // an in-body observation"). The barrier is `R` ITSELF — the record's own
      // mint. Inside a rolled loop the discharge and the gate BOTH run every
      // trip, in that order, over a rail the mint re-creates every trip; the
      // plain `!isPotentiallyReachable(T, D)` half sees only the back edge and
      // reports the record live, which is a FALSE ALARM: the record reachable
      // "after" `T` is the NEXT iteration's, minted after `T` ran. Measured on
      // the customer program (`example/grover/grover_oracle_uncompute.c`): the
      // rolled loop emits a trace BYTE-IDENTICAL to its hand-unrolled twin's,
      // discharges included, and warned twice where the twin warned not at all.
      // A LOOP-INVARIANT record (minted outside the loop) is untouched — its
      // mint is not on the back-edge path, so the barrier walk finds a
      // barrier-free path and the guard still reports it live, which is right.
      if (isDischargeOf(CI, R) && provablyBeforePerActivation(CI, T, R, DT))
        return true;
      // clause 4 — measured before the gate (collapsed; nothing left to dephase).
      if (emittedCalleeName(CI).starts_with("cqrt_measure_") &&
          provablyBeforePerActivation(CI, T, R, DT))
        return true;
    }
    // clause 3 — an OBSERVED use provably AFTER the gate: the record is LIVE,
    // it is the program's own data, and its dephasing is source semantics.
    //
    // "OBSERVED", NOT "MENTIONED" (owner ruling 2026-08-28, the F1 fix). The use
    // exempts only if its lineage reaches an observing sink — see
    // `reachesObservingSink`, which owns the whole SINK / HOP / NON-USE grammar
    // (teardown traffic and the F2 rotation arm included, so this loop no longer
    // pre-filters them: one place decides what a use means).
    //
    // REACHABILITY FIRST. Both halves of `provablyBefore` are VACUOUSLY TRUE for
    // an instruction in a block with no entry path — LLVM's dominator tree treats
    // an unreachable block as dominated by everything, and nothing is reachable
    // from it — so without this test a use that can NEVER EXECUTE exempted the
    // record (the Rule-13 round's F3 finding). A use that never runs is not the
    // program reading its data; the record stays dead and the module declines.
    // Pinned by lowering_reject_live_record_unreachable_use.ll.
    if (!DT.isReachableFromEntry(UI->getParent()))
      continue;
    // PER ACTIVATION, same barrier and same reason as clauses 2/4 above (bd
    // 8h7d.5 / 58tc): inside a rolled loop the observing use runs after the gate
    // on every trip, and only the back edge makes it look like it might not.
    if (!provablyBeforePerActivation(T, UI, R, DT))
      continue;
    if (reachesObservingSink(UI, R, taint, DT))
      return true;
  }
  return false;
}

}  // namespace

// ⚠ THIS IS NOT A BACKSTOP FOR THE Inc-4 CONTROLLED-STATE-PREP F2 CLASS, AND IT
// LOOKS EXACTLY LIKE ONE (bd test_C_libtooling-drbq Inc 4, ROUND-3 Rule-13
// review, lens R3 finding F-R3-7 item 3). This diagnostic names that hazard
// verbatim — `non-diagonal gate over a live derived record` — and a reader
// meeting F2 for the first time will assume "M-A would have caught it anyway".
// IT WOULD NOT, and the reason is structural rather than a bug: F2's class is a
// controlled Ry on a rail minted INSIDE the region by `cqrt_alloc`, whose record
// set is EMPTY by `RecordSet::push` clause 5, so no site is ever collected.
// MEASURED across the 42 confirmed miscompiles of that review: this guard FIRES
// on their unconditional twins (e.g. `p/u06_uncond_sdiv4.c`, where the source
// rotates the DIVISION's own rail in place) and is SILENT on every one of the 42.
// The only fence for that class is `ArmClassify::f2SeedPinnedByLiveRegister`.
//
// ⚠ AND IT IS NOT A BACKSTOP FOR bd `test_C_libtooling-s82e`'s IN-LOOP DEPHASING
// CLASS EITHER — BUT IT IS **CORRELATED** WITH IT, AND THE RELATIONSHIP IS
// WRITTEN DOWN HERE SO THE NEXT AGENT FINDS IT INSTEAD OF RE-DERIVING IT (closing
// gate 2026-09-14c; the same note is at
// `LoopLowering::declineDephasingUnmarkedLoopRails`, which is that class's fence).
// MEASURED at that gate, counting this diagnostic's string in `opt` stderr:
//
//   ORACLE `5c6f7490a81c7505…`  s1_live_shift 2 · s2_live_derived_region 2 ·
//                               b11_cmp_rail_data 2   (the three DIVERGENT probes
//                               — rolled and hand-unrolled compute different
//                               unitaries) and
//                               s3_live_rootmint_region 0 · w2k_noregion_invread 0
//                               (the two BENIGN ones). A clean split on 5 of 5.
//   MERGED `0e280fc62a91cec2…`  s1 / s2 now exit 1 at the loop fence
//                               (`CQLoweringPass.cpp:772`), so this stage (`:864`)
//                               never runs for them — their count is 0 BY
//                               PREEMPTION, not by silence (`LLVMContext::diagnose`
//                               EXITS on the first `DS_Error`, bd `br4a`).
//                               `b11_cmp_rail_data` still exits 0 and still warns
//                               twice: it is the member that fence MISSES
//                               (bd `test_C_libtooling-7845`, P1).
//
// ⚠⚠ IT IS **NOT** A DIVERGENCE DETECTOR AND MUST NOT BE DESCRIBED AS ONE, however
// suggestive that 5-of-5 split is. MEASURED on the same binary: it fires on
// `slice_control_inplace_ry_loop_leak` (1) and on `…_unrolled` (2), a pair whose
// traces are BYTE-IDENTICAL under the shipped ctest gate
// `e2e-inplace-ry-loop-leak-twin-identical`. ⚠ And byte identity does not prove
// that pair CORRECT: if both halves are wrong the same way the twin witness is
// blind — `CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` cell, which agreed
// with itself while both halves were wrong.
//
// ⚠ WHY IT IS A WARNING, WHICH IS A RULING AND NOT AN ASSESSMENT OF HARM. Owner
// ruling bd `test_C_libtooling-lyyf` (2026-08-29) made it `DS_Warning`, and the
// recorded reason is REPORTING COMPLETENESS — under `DS_Error` the pass was over
// after one site, and a warning that hid the second would send the author round
// the compile loop once per record. It is NOT a finding that the reported gates
// are benign. Promoting it to a decline therefore has a real, measured cost: 5 of
// the 366 accepting e2e slices emit it (`slice_control_angle_select_ry_derived_base`,
// `slice_control_inplace_ry_derived_base`, `slice_control_inplace_ry_loop_leak`,
// `…_unrolled`, `slice_live_record_source_rail_warn`) and would have to be
// re-dispositioned first. Use it as a SIGNAL when hunting bd `7845` / bd `c767`;
// never as a second fence and never as coverage.
bool warnLiveRecordRotations(Module &M, const TaintSet &taint) {
  if (taint.UserChainedRotations.empty())
    return false;  // no site in the whole module — every other cost is skipped.
  bool Warned = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;  // built lazily, only for a function with a site
    // BB order, so the reports come out in program order. EVERY offending gate
    // is reported, not just the first (owner ruling 2026-08-29, bd lyyf): under
    // the old `DS_Error` the pass was over after one, and stopping was the only
    // option; a WARNING that hid the second site would send the author round the
    // compile loop once per record.
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *T = dyn_cast<CallInst>(&I);
        if (!T || !taint.UserChainedRotations.count(T))
          continue;
        // Structural re-check — see the file-scope note on pointer validity.
        // TWO SPELLINGS OF ONE GATE (bd test_C_libtooling-drbq Inc 1 walker
        // audit): the uncontrolled `cqrt_ry_<W>(h, θ)` puts the rotated wire at
        // ARG 0, and the control-in-place `cqrt_ry_<W>_controlled(f, h, θ)` puts
        // it at ARG 1 (arg 0 is the flag). Both are in-place non-diagonal gates
        // on a USER register and both are recorded in `UserChainedRotations`, so
        // both must be asked — reading the wire off arg 0 for the controlled
        // spelling would run this whole guard against the FLAG, which is the
        // widened-one-set-not-the-other hole the 8h7d.5 rounds kept finding.
        const StringRef GateName = emittedCalleeName(T);
        const bool ControlledRy =
            GateName.starts_with("cqrt_ry_") &&
            GateName.ends_with("_controlled") && T->arg_size() == 3;
        if (!ControlledRy &&
            (T->arg_size() != 2 || !GateName.starts_with("cqrt_ry_")))
          continue;
        // Clause 1, in three passes over ONE shared record set (Inc 3):
        //   1. ANCESTORS of the wire, backward through producer / alloc /
        //      clone-return / copy-destination edges;
        //   2. DESCENDANTS of the wire, forward — the Increment-1 half;
        //   3. DESCENDANTS OF EVERY ANCESTOR — the ruling's "transitively
        //      entangled". This is the only pass that reaches a DEAD SIBLING
        //      standing under a LIVE (exempt) ancestor
        //      (lowering_reject_live_record_anc_dead_sibling.ll).
        // Clauses 2-5 are unchanged and are evaluated per record below.
        Value *W = T->getArgOperand(ControlledRy ? 1 : 0);
        SmallVector<CallInst *, 8> Records;
        RecordSet RS(W, Records);
        SmallVector<Value *, 8> Seeds;
        collectAncestorRecords(W, RS, Seeds);
        SmallPtrSet<const Value *, 32> Seen;
        collectDescendantRecords(W, RS, Seen);
        for (Value *S : Seeds)
          collectDescendantRecords(S, RS, Seen);
        if (Records.empty())
          continue;
        if (!DT)
          DT.emplace(F);
        for (CallInst *R : Records) {
          // A record MINTED STRICTLY AFTER THE GATE cannot dephase it (the
          // Rule-13 round's F2 finding: the guard never tested that `R` exists
          // at `T`, so `q=theta; w=q*2; T; z=q*3` — `z` dead — DECLINED, a
          // false decline on a rail that is not allocated when the `Ry` fires).
          //
          // READ THE MODALITY. `provablyBefore(T, R)` is the CONDITIONAL-on-`R`
          // property: IF `R` executes then `T` already did, AND `T` is not
          // reachable again from `R`. That is exactly what is needed — a rail
          // that exists only after the gate is not standing at it — and the
          // second half is load-bearing, not decoration: a LOOP whose back edge
          // re-runs `T` over a record minted in the body fails
          // `isPotentiallyReachable`, so the record still counts. Skipping here
          // rather than inside `recordIsExemptAt` keeps the two questions apart:
          // this is "does R exist at the gate?" (clause 1's implicit premise),
          // not "is R live?" (clause 3).
          if (recordAbsentAt(R, T, *DT))
            continue;
          if (recordIsExemptAt(R, T, taint, *DT))
            continue;
          // ONE report per GATE, not per record: the message names the gate (it
          // carries `T`'s `!dbg`), so a second record on the same rotation would
          // print a duplicate line with nothing new in it.
          //
          // DS_Warning, and the severity is the ENTIRE behavioural change of
          // Increment 7b (owner ruling 2026-08-29, bd lyyf — see the header).
          // The analysis above is byte-identical to the Increment-3 guard, the
          // message string is unchanged, and `opt` now exits ZERO and hands back
          // the lowered module. The record is LEFT ALLOCATED: nothing in this
          // function ever freed anything, and the M-B spine's leak-first
          // fallback is what left it standing, so Rule 6 is untouched — a rail
          // that is not provably |0> is never freed, it is only reported.
          F.getContext().diagnose(DiagnosticInfoUnsupported(
              F, kMsgLiveRecord, T->getDebugLoc(), DS_Warning));
          Warned = true;
          break;
        }
      }
    }
  }
  return Warned;
}

}  // namespace cq
