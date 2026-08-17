// LiteralIntegrity.h — the two module-wide guards that hold ONE invariant:
//
//     *** every LITERAL operand of an emitted gate must denote, at run time,
//         exactly the value the source program specified — and the SAME value
//         at every site the lowering copies it to. ***
//
// `opt -verify` cannot see a violation of this: the emitted module is
// well-typed, `free_pairing_check.py` reports STRICT CLEAN because the
// forward/`_unc`/`cqrt_free` triple is STRUCTURALLY correct, and the trace even
// looks plausible. The operands differ only at RUN TIME. Both defects below were
// found by adversarial review (bd u1rp's Rule-13 round), never by a gate.
//
// ── GUARD 1: `declineUnpairedUndefLiterals` (bd xy9n and its whole family) ───
//
// A literal `undef`/`poison` lowers to `IMPLICIT_DEF`, which LLVM materialises
// PER USE. `EmitInverse` builds every adjoint by copying the FORWARD call's
// operands verbatim (`Forward->getArgOperand(i)`) — so a poison literal reached
// by BOTH a forward gate and its adjoint is read as two DIFFERENT values.
// Measured on the bd u1rp H1 exhibit at the shipped `-O0` stage 3, deterministic
// and identical across runs (so NOT the ASLR artefact bd bu96 refuted):
//
//     cq_template_icmp_slt_i32_hl(h0, 73896)      -> h4
//     cq_template_icmp_slt_i32_hl_unc(h4, h0, 1401299752)
//     cqrt_free(h4)
//
// The adjoint inverts a different predicate than the forward computed, so rail
// `h4` is left dirty AND entangled with `h0`, and the `cqrt_free` on the next
// line is a hardware reset — a hidden measurement that collapses `q`.
// Rules 6 and 8.
//
// *** WHY MODULE-WIDE AND NOT PER-SURFACE. *** bd xy9n proposed a refusal at the
// 4.4 select classify gate, reading the u1rp fence (which lives in
// `coneDefinedAfterFlagDrop`, so runs only on a poison-SHIELDED select-form
// inside a claimed PredMux region) as having left the select uncovered. MEASURED
// on the pre-change plugin, before writing any code: the pairing break reaches
// with **NO CONTROL FLOW OF ANY KIND** —
//
//     define void @slice(i32 %x) {
//       %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
//       %d = add i32 %q, poison        ; dead terminal
//       ret void }
//
// emits `cq_template_add_i32_hl(%h, i32 poison)` + its
// `..._hl_unc(%h_op, %h, i32 poison)`, `opt` exit 0, verify clean. So the
// channel is not the select, not PredMux and not any control emitter: it is
// `EmitInverse`'s operand copy, which EVERY surface with an adjoint shares. A
// per-surface gate would have been whack-a-mole on a surface list nobody can
// prove complete. The measured surface count that decided this is in
// `docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/`
// `xy9n-7udx-literal-integrity-decision.md` §1.
//
// *** THE PREDICATE IS THE PAIRING CHANNEL, NOT THE PRESENCE OF `undef`. *** The
// first draft of this guard refused ANY emitted call with a literal
// undef/poison operand, and MEASUREMENT killed it: across 966 fixtures + 257
// e2e stage-1 modules + 251 openlibm modules there is exactly ONE real-code
// occurrence, `slice_libm_real_nexttoward` —
//
//     %selop = call i32 @cqrt_alloc_f64(double undef)
//     call void @cqrt_copy_f64_controlled(i32 %h_cmp85, i32 %selop, i32 %out86)
//
// — `clang -O1`'s own `select i1 %c, double undef, double %v` for a dead
// early-exit merge edge. That module holds 985 emitted calls and exactly ONE
// undef-bearing slot; `%selop` is never freed (so no Rule-6 hidden measurement)
// and `double undef` appears exactly once module-wide, so there is NO SECOND
// READ to disagree with. It is a shipped, golden-pinned, already-reviewed slice
// (see its own header's GOLDEN-FRAGILITY note), and refusing it would have been
// a regression dressed as a tightening.
//
// So the guard counts: it declines iff **TWO OR MORE** emitted-runtime-call
// operand slots in ONE FUNCTION carry a literal `undef`/`poison` (see the
// per-function rationale further down). Two or more is the pairing channel; one is
// not.
//
// *** STATE THE REASON CORRECTLY. An earlier draft justified the threshold with
// "one slot is one materialisation", and the Rule-13 round MEASURED THAT FALSE: a
// single static slot inside a rolled loop is read once per trip, and the trace
// shows one `cqrt_rz_f64(h0, <angle>)` slot yielding SIX dynamic reads with TWO
// distinct values. `undef` may take a different value at every DYNAMIC read, not
// merely at every static use. ***
//
// The conclusion survives on a different and stronger invariant: **CQ never
// creates an adjoint by re-executing the forward site.** Every adjoint is a FRESH
// STATIC CALL — `EmitInverse` builds them with `B.CreateCall` /
// `CreateFNeg` / `CreateNeg`, and `BreakReversePlay` reverse-plays via
// `C->clone()`. So a forward gate and its adjoint are always two DISTINCT static
// slots, and therefore any real pairing is always ≥2 slots and always caught. A
// lone slot has no adjoint at all — nothing claims to invert it, so no `cqrt_free`
// asserts `|0⟩` on its behalf, and repeated dynamic reads of it are exactly what
// the source's `undef` already licenses.
//
// This is the bu96 doctrine (a poison-generating `ConstantExpr` is uniqued into
// ONE link-time relocation, so its forward and adjoint agree and there is no wrong
// circuit) applied to the literal spelling: reason from PAIRING, never from
// LangRef refinement — refinement is true of both kinds and is therefore not what
// makes the literal spelling wrong.
//
// Counting is per FUNCTION. An earlier draft counted per MODULE, to reach the
// Phase-6 clone/twin pair that lives in two separate functions, and the Rule-13
// round measured what that cost: a TU holding TWO libm cells — each with its own
// `clang -O1` dead-edge `select i1 %c, double undef, double %v` — has two
// independent single slots in two different functions and DECLINED, though each is
// individually the shape the accept fixture certifies as sound. Two cells in one TU
// is an ordinary multi-slice, so that is a real regression, not a hypothetical.
//
// Per-function is sound only because the cross-function pairing is fenced
// SEPARATELY, at the duplication site (`findUndefOperandInBody` below), and every
// other adjoint the pass emits lands in the same function as its forward. Do NOT
// re-widen this to per-module without deleting that fence's reason for existing.
//
// And do NOT "sharpen" it to `Constant`-identity counting: `undef`/`poison` are
// UNIQUED PER TYPE, so every `double undef` in a module is one `Constant *` and
// identity-keying reproduces the very over-decline per-function just fixed.
//
// Counting is spelling-independent, also deliberately: it catches the `_unc`
// adjoint, the `_inv` adjoint, and the NEGATED-ANGLE re-emission form that no
// name test would find — `cq_phi(x, poison)` emits `cqrt_rz_<W>(h, poison)`
// twice, because the adjoint is `CreateFNeg(arg1)` and `fneg poison` folds back
// to `poison`. Any future adjoint form is covered without editing this guard.
//
// Placed LAST in the pipeline (after `uncompute`, before `eraseDeadDecls`, in
// BOTH entry points) because that is the only position that provably sees EVERY
// emitted call, forward and adjoint. Nothing after it emits a call or mints a
// constant — `eraseDeadDecls` erases declarations only — so provenance does not
// need arguing: whatever sits in an emitted slot at that point is exactly what
// stage 3 will read.
//
// (An earlier draft justified this with "the pass never synthesizes an
// `undef`/`poison` … the only constant it mints is `Constant::getNullValue`, i.e.
// zero". That is FALSE — `ir-pass/src` has 16 `ConstantInt::get` sites and 8
// `ConstantInt::getTrue`/`getFalse` sites (24 in all), plus `EmitInverse`'s
// `CreateFNeg`/`CreateNeg` folding to fresh negated constants. `ConstantFP::get`
// has ZERO real sites — an intermediate correction of this very paragraph asserted
// otherwise and the round caught that too, so the number here is 24 and the
// `ConstantFP` claim is gone. None of those constants can be `undef`, so the guard
// was never affected; the point is that the claim sat in this change's own audit
// trail. The `UndefValue::get`/`PoisonValue::get` grep IS clean, and is simply not
// needed, because placement-last makes provenance irrelevant.)
//
// GUARD 1 IS NOT COMPLETE ON ITS OWN, and the one hole is fenced elsewhere. It
// counts literal SLOTS, so it is blind to an `undef` sitting ONE classical
// instruction above the slot — and `Specialization::synthUncomputeTwin` DUPLICATES
// such a computation into the uncompute twin, giving the forward clone and the
// adjoint twin two independent materialisations. See `findUndefOperandInBody`
// below: that fence lives at the duplication site, which is the exact parallel of
// GUARD 2 living at the erase site.
//
// ─── GUARD 2: `declineAddressTakenBlocks` (bd 7udx) ─────────────────────────
//
// *** THIS ONE IS NOT A POISON BUG, and it is the more serious of the two: the
// source program is WELL-DEFINED. There is no UB and no LangRef refinement
// argument to excuse the divergence — the compiler simply emits a different
// number than the source says. Everything in the poison family above leans on
// "poison permits any value"; this cannot. ***
//
//     icmp sgt i32 %q, ptrtoint (ptr blockaddress(@f, %arm) to i32)
//       lowered to  cq_template_icmp_sgt_i32_hl(%h, i32 1)
//
// `BasicBlock::~BasicBlock()` (LLVM 19) replaces every `BlockAddress` of a
// block it destroys with `inttoptr (i32 1 to ptr)`, which folds through the
// `ptrtoint` to `i32 1`. So a region flatten that erases the named block
// silently rewrites the compared-against address to 1 — and because that RAUW is
// module-wide on the `BlockAddress` constant, a plain
// `store ptr blockaddress(@f, %arm)` ANYWHERE in the module is corrupted by the
// same erase, not only a use inside the region.
//
// The guard is therefore keyed on the BLOCKS ABOUT TO BE ERASED, not on the
// uses. A `blockaddress` naming a block OUTSIDE every claimed region is
// untouched and keeps lowering — that accept control is
// `control_swap_accept_blockaddress_outside_region.ll`, and without it this
// guard would over-decline every function containing a computed `goto` with
// nobody noticing.
//
// Call it at each site that erases a BasicBlock, BEFORE that site's first erase.
// The ERASE site is the choke point on purpose: claim-time placement would mean
// touching six independent detectors, because there is no single claim funnel.
// Measured order in `CQLoweringPass::run`: `flattenPredMuxRegions` (its OWN
// `recoverRegion`, a different function from `ControlDetect`'s) runs at ~179 and
// again inside the unroll fixpoint at ~203; `lowerControlledIOSinks` at ~248;
// `detectControlRegions` at ~276, and it is INSIDE that call that
// `classifyAbortPark` and the guarded-store classifier are tried BEFORE
// `ControlDetect::recoverRegion`. So the claims are spread across three pipeline
// steps and one intra-step ladder, and a seventh detector added later could simply
// forget. Precedent for the
// predicate: `LoopUnrollPrepass.cpp:211`, which already refuses a loop whose
// header `hasAddressTaken()` — the ONLY `hasAddressTaken()` in the pass before
// this file, and a SILENT non-claim rather than a diagnostic.
//
// THE COMPLETE SITE LIST, measured rather than assumed (a census over all 966
// `ir-pass/test` fixtures injected a `store ptr blockaddress(@F, %BB)` into a
// holder function and diffed the emitted store; 308 of 448 (fixture, block)
// variants corrupted, across 126 of the 164 fixtures that had BOTH an accepting
// control AND at least one injectable non-entry block — NOT of the ~451 accepting
// fixtures overall; the qualifier is the whole point of the denominator):
//
//   EXPOSED, now guarded:
//     * `flattenRegion`         — arms + MERGE   (4.1/4.2, and everything that
//                                 reuses it: 4.5 eq-folded diamond, 6.5
//                                 ClassicalCallArmEmit, 7.6 IOSinkLowering)
//     * `flattenRegionTree`     — Mid + InnerArm + shared Merge  (4.3)
//     * `flattenSwitchRegion`   — every arm + Merge               (4.5)
//     * `PredMuxFlatten`        — `R.Topo \ {Entry}`; the WIDEST site, since that
//                                 is an arbitrary acyclic sub-CFG. Merge SURVIVES
//                                 here (it is the branch target), unlike
//                                 `flattenRegion` — so "in region" is NOT a safe
//                                 characterisation of the exposed set; the
//                                 per-stage DOOMED set is.
//     * `AbortParkEmit`         — the sink arm
//     * `GuardedStoreArmEmit`   — the arm only (its merge survives)
//     * `Fp80Union`'s `removeUnreachableBlocks(F)` — reaps the classical dead arm
//                                 after `ConstantFoldTerminator`. Reached from
//                                 `promoteFp80Union` AND from
//                                 `foldConstantConesInFunction`, which PredMux
//                                 calls after every flatten. Guarded by the
//                                 `Function&` overload below.
//   NOT EXPOSED, measured:
//     * `LoopLowering` (7.3/7.4) — rolls IN PLACE and erases only instructions
//       (EscapePhi / RailPhi / FusedI / P), never a block. 13 `lowering_loop_*`
//       fixtures clean.
//     * `Specialization` — mints a NEW function, so the original's blocks survive.
//       Its `MergeBlockIntoPredecessor` DOES destroy a block, and the earlier
//       reasoning here ("clone blocks whose addresses are not taken") was WRONG:
//       `CloneFunctionInto` deliberately mints `BlockAddress::get(NewFunc, CBB)`
//       for the VMap, so a clone block's `hasAddressTaken()` IS true. The row holds
//       on two OTHER grounds, both checked: that `BlockAddress` is a user-less
//       artifact (nothing observable is destroyed — the same fact the use-test in
//       `declineAddressTakenBlocks` rests on), AND `llvm::MergeBlockIntoPredecessor`
//       independently refuses any `hasAddressTaken()` block. Probed with two shapes
//       carrying a USER-bearing `BlockAddress` into the clone; both decline earlier,
//       identically on both plugins, on the pre-existing specialization gate.
//     * `ByRefInline`'s `Callee->eraseFromParent()` — gated on
//       `Callee->use_empty()`, and a `BlockAddress(Callee, BB)` IS an
//       operand-use of the Function, so the erase is skipped by construction.
//
// Population today is ZERO — no `blockaddress` and no `indirectbr` in any of the
// 966 fixtures, 257 e2e stage-1 modules or 251 openlibm modules — so this guard
// is free. It is not hypothetical, though: `void *p = &&L;` plus a computed `goto`
// is a legal, clang-accepted C extension, and what IS measured is that an ordinary
// `store ptr blockaddress(@f, %arm)` in a function the lowering never touches comes
// out as `store ptr inttoptr (i32 1 to ptr)`.
//
// A stronger claim — that a LIVE `indirectbr` destination can be erased out from
// under a still-live computed `goto`, so the program jumps to address 1 — was
// asserted by the surface census and then NOT reproducible by the Rule-13 round,
// which argues structurally that it may be unreachable here: every erase site
// requires the doomed block's predecessors to be in-region or unreachable, and an
// `indirectbr` edge IS a predecessor edge. Treat it as UNPROVEN, not measured. The
// corruption of ordinary pointer data is measured and is enough on its own.
//
// ─── WHAT A DECLINE HERE DOES AND DOES NOT GUARANTEE ────────────────────────
//
// Both guards return `bool`, and every caller that CAN act on it does. One cannot:
// `removeUnreachableBlocksChecked` is a drop-in for `removeUnreachableBlocks(F)`, so
// its `bool` already means "did anything change" and it returns true for BOTH
// "changed" and "declined" — no caller could tell them apart, and `Fp80Union`
// discards it by design because `Any` already records the change. If a caller ever
// needs to distinguish, add an out-param rather than overloading the return.
// Under `opt` — the only supported host — the distinction is moot anyway: `LLVMContext::diagnose` on
// `DS_Error` calls `exit(1)` from inside the callee (verified: exit=1,
// `stdout_bytes=0`), so nothing downstream runs and nothing is written.
//
// *** BE PRECISE ABOUT THE REST, because an earlier draft of this paragraph
// over-claimed and the Rule-13 round caught it. *** On a host that installs its
// own diagnostic handler and keeps running, a decline from GUARD 1 hands back a
// module that is fully lowered and still carries the pairing break, because guard
// 1 runs after every mutation. That is NOT a property this guard invents: it is
// what EVERY post-mutation decline in the pass does — `Uncomputation`'s
// `kMsgLineageMeasured` and `kMsgUninvertible` are the precedent, and they run at
// the same point. It is filed as its own pass-wide follow-up rather than papered
// over here.
//
// GUARD 2 is in the same boat at 6 of its 7 sites: each fires at the top of a
// FLATTEN, which its emitter reaches only after emitting gates, so on a
// non-exiting host a decline there leaves a half-lowered region rather than
// "lower nothing". The bool return prevents a CRASH (dereferencing blocks the
// stage would otherwise go on to erase); it does not promise an unmutated module.
// Only the PredMux site is a true claim-time decline.
//
// *** AND THE `Fp80Union` SITE IS WORSE THAN THAT CLASS — say so rather than filing
// it alongside the other six. *** Because it OBSERVES the deletion set instead of
// predicting it, the deletion (and therefore the module-wide RAUW of the
// `BlockAddress` to `inttoptr (i32 1 to ptr)`) has ALREADY HAPPENED when the
// diagnostic fires. On a non-exiting host that site does not leave a region
// unfinished; it leaves the very corruption the guard exists to prevent. This is a
// KNOWINGLY CHOSEN trade: the predicting alternative was measured to MISS the defect
// outright on three `markAliveBlocks` triggers (arm `D6_predict_dfs`), and under
// `opt` the decline exits with zero stdout bytes so nothing corrupted is ever
// written. Do not "improve" it back into a prediction.
//
// One site was MOVED to make its placement genuinely strict.
// `GuardedStoreArmEmit`'s check now sits at the TOP of its emitter rather than
// "just before the erase", because by the erase line that emitter has already
// hoisted the arm body — INCLUDING THE GUARDED STORE — unconditionally into the
// pred and dropped the conditional branch; a decline there would leave a module
// that stores on every path, which is WRONG rather than unlowered.
// `hasAddressTaken()` is position-independent, so moving the check up costs
// nothing. The three `RegionFlatten` entry points still run at the top of the
// FLATTEN, which is after their emitter has emitted gates — the same
// post-mutation class as guard 1, and the same follow-up covers it.

#ifndef CQ_IRPASS_LITERAL_INTEGRITY_H_
#define CQ_IRPASS_LITERAL_INTEGRITY_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class BasicBlock;
class CallBase;
class Constant;
class Function;
class Instruction;
class Module;
class Value;
}  // namespace llvm

namespace cq {

// Does this Constant CONTAIN a literal `undef`/`poison`, however deeply it is
// buried in a constant aggregate or expression? `PoisonValue` derives from
// `UndefValue`, so the `isa` catches both spellings. Carries a visited set
// rather than a depth budget on purpose: a budget inside a yes/no predicate
// makes the ANSWER depend on the cut-off (bd memory
// [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]]), and constants form
// a finite DAG that a visited set terminates on structurally.
//
// LIFTED VERBATIM out of `PredMuxFlatten.cpp`'s anonymous namespace (bd
// 3c6m.14.2 wrote it there) so the cone proof and the module-wide guard cannot
// drift apart (Rule 14). Behaviour is unchanged — `PredMuxFlatten` now calls
// THIS one, and the corpus verdict diff over 966 fixtures + 257 slices + 251
// openlibm modules is byte-neutral for every pre-existing PredMux fixture.
//
// KNOWN OVER-DECLINE, DELIBERATELY LEFT (carried over with the lift): a
// `GlobalValue`'s operands are its INITIALIZER, and the value being tested is
// the global's ADDRESS, which is defined no matter what it is initialised to. So
// `@u = global {i32 1, [4 x i8] undef}` reached through a `ptrtoint` reads as an
// undef leaf. An `isa<GlobalValue>` early return fixes it in two lines and was
// written — then REVERTED, because measurement showed it is an accept WIDENING
// relative to the shipped plugin, and a widening does not belong in a tightening
// commit. Filed with its own red-green pair owed.
//
// KNOWN INCOMPLETENESS, filed as bd bu96 (DECLINE TO FIX): this tests for a
// CONTAINED `UndefValue`, so a constant expression that GENERATES poison without
// containing one — e.g. an out-of-bounds
// `ptrtoint (ptr getelementptr inbounds (...) to i64)` — reads as defined. That
// is sound on the pairing axis: a `ConstantExpr` is uniqued, so it becomes ONE
// link-time relocation and the forward and adjoint read the SAME value. Anyone
// reopening bu96 must use `!isGuaranteedNotToBeUndefOrPoison(C)` scoped to
// `isa<Constant>`; `canCreateUndefOrPoison` is a NO-OP THAT READS AS A FIX
// (measured on libLLVM 19.1.7: 0 on the bu96 witness, 1 on a benign in-bounds
// gep — it queries the OUTERMOST operator only).
//
// *** AND THAT PAIRING GROUND IS NOW A RULING, NOT JUST A DECLINE REASON (bd hg8s,
// owner 2026-08-17). *** `classifyConeNode` (PredMuxFlatten.cpp) admits a Constant
// on PAIRING and a `noundef` Argument on DEFINEDNESS, and those are two different
// SUFFICIENT GROUNDS for one obligation — `ONE VALUE AT EVERY USE` — which each
// kind can supply only one of. The asymmetry is deliberate; read the ruling at that
// clause BEFORE re-grounding either half. The measurement that settled it, and the
// reason it does not transfer between the kinds: a Constant's uniquing holds at
// EVERY `-O` level (measured paired at `default<O1>`, 8507392 == 8507392), whereas
// an ARGUMENT's one-value property is a property of the LINK and holds only at the
// pinned `-O0` stage 3 — above it, argument forwarding turns one parameter into N
// independent `undef` tokens and the forward/adjoint slots diverge with THIS file's
// own recorded constants, 73896 vs 1401299752. So bu96's cell is safe for a reason
// that is unavailable to an Argument, which is exactly why the two halves differ.
bool constantCarriesUndef(const llvm::Constant *C,
                          llvm::SmallPtrSetImpl<const llvm::Constant *> &Seen);

// `constantCarriesUndef` for any `Value*`: false for anything that is not a
// `Constant` (an `Instruction` operand is a run-time value, not a literal).
bool valueCarriesUndef(const llvm::Value *V);

// `valueCarriesUndef` for an EMITTED GATE SLOT: identical, except that it does NOT
// descend into a `GlobalValue`, because a `GlobalValue`'s operands are its
// INITIALIZER while the value in the slot is the global's ADDRESS — defined no
// matter what it is initialised to.
//
// *** THE TWO PREDICATES MUST STAY DISTINCT. *** `clang -O1` really emits
// `@v = global { i32, [12 x i8] } { i32 3, [12 x i8] undef }` for a
// partially-initialised `union { long double f; int i; }` — the fp80-union idiom
// this project is built on — so `ptrtoint (ptr @v to i32)` in a gate slot reads as
// an undef leaf without the skip, and the Rule-13 round measured GUARD 1 declining
// that WELL-DEFINED program. Yet `PredMuxFlatten`'s cone proof must keep the
// un-skipped `valueCarriesUndef` byte-for-byte: there the over-decline is
// PRE-EXISTING, and removing it would be an accept WIDENING in a tightening commit
// (bd ajw7, filed with its own red-green pair owed). New code gets the correct
// semantics; shipped code keeps its measured behaviour.
// TWO REASONS THE SKIP CANNOT LOSE A SIBLING `undef`, because "the early return
// abandons the unvisited operands" is the obvious way to get this wrong:
//   1. STRUCTURAL — the `return false` exits only the GlobalValue's own recursion
//      level; the PARENT's operand loop continues to the next sibling. So
//      `{ ptr @g, i32 undef }` still reports true, via the second operand.
//   2. NOT a second reason — an earlier draft claimed the case "cannot arise" because
//      the folder collapses an `undef` gep index at parse time. That is FALSE and the
//      Rule-13 judge measured it: only the TRAILING-index and `i8` spellings fold, so
//      `ptrtoint (ptr getelementptr inbounds ([4 x i32], ptr @g, i64 undef, i64 1)
//      to i32)` reads back VERBATIM with its `undef` intact. The shape IS reachable,
//      and reason 1 is what handles it — verified: that module lowers on the
//      pre-change plugin and declines here with the undef-paired diagnostic. Do not
//      restore the folding claim.
bool slotCarriesUndef(const llvm::Value *V);

// Is `CB` a call to one of the three EMITTED runtime families — `cqrt_*`
// (hand-written core ABI), `cq_template_*` (generated reversible bodies) or
// `__cq_q_*` (Phase-6 clones and their uncompute twins)? These are the calls that
// become gates; a surviving classical call carrying `undef` is the source's own
// business, not a lowering defect.
//
// Takes the `CallBase` and tests the CALLED OPERAND's own name, NOT
// `getCalledFunction()`. `Module::getOrInsertFunction` returns whatever
// `GlobalValue` bears the name, and `EmitInverse` mints every `_unc` twin through
// it — so an input module defining `@cq_template_add_i32_hl_unc` as a
// `GlobalAlias` makes `getCalledFunction()` null and the adjoint invisible. The
// Rule-13 round shipped the full xy9n break through exactly that hole. Testing the
// operand's name covers `Function`, `GlobalAlias` and `GlobalIFunc` uniformly, and
// `stripPointerCasts()` would REOPEN it by resolving the alias to a body whose
// name has no family prefix.
bool isEmittedRuntimeCallee(const llvm::CallBase *CB);

// The first instruction with a literal `undef`/`poison` operand (global ADDRESSES
// excluded, per `slotCarriesUndef`) in `F`'s body OR in any DEFINED function
// transitively reachable from it by direct calls, or null.
//
// The transitive reach is not decoration: the delta round showed that putting the
// undef-bearing computation in a classical helper the clone CALLS lets the twin
// duplicate the CALL instead of the computation, so a body-only scan returns null
// while two static call sites share one `undef` slot that is read twice dynamically.
// Bounded by a `Function*` visited set, and every callee a clone can reach is already
// proven pure and acyclic by `SpecializeReject::scanBody`.
//
// This exists for ONE caller: `Specialization::synthUncomputeTwin`, which builds
// the Phase-6 uncompute twin with `CloneFunctionInto(Twin, &Clone, …)` — the ONLY
// place in the pass that re-materialises a whole gate-feeding COMPUTATION that a
// forward gate already read. GUARD 1 counts literal SLOTS and is therefore blind
// to an undef sitting ONE classical instruction above the slot: measured, a
// `%c = xor i32 undef, 7` feeding `cq_template_mul_i32_hl(%a, %c)` is duplicated
// verbatim into the twin, so the forward clone and the adjoint twin each read their
// OWN materialisation (73903 vs 7 in the trace) and the rail is freed dirty.
// Guarding at the DUPLICATION site is the exact parallel of GUARD 2's "the erase
// site is the choke point".
//
// *** DO NOT instead widen GUARD 1 to "the argument is defined by an instruction
// with an undef operand". *** That over-declines every `clang` dead-edge
// phi/select — including `slice_libm_real_nexttoward`'s whole family — for no
// pairing gain, because outside the twin there is only ever ONE copy of the
// computation and both reads see the same register.
const llvm::Instruction *findUndefOperandInBody(const llvm::Function &F);

// GUARD 1 (bd xy9n). Walks all of `M`, counts PER FUNCTION, runs LAST, pure
// analysis — mutates nothing. Declines loudly iff TWO OR MORE
// emitted-runtime-call operand slots in ONE function carry a literal
// `undef`/`poison` (see the header comment for why the threshold is two and not
// one, and why the scope is the function and not the module). Returns true if it
// declined.
bool declineUnpairedUndefLiterals(llvm::Module &M);

// GUARD 2 (bd 7udx). Call with the blocks a stage is about to erase, BEFORE its
// first erase. `At` anchors the `!dbg` (any still-live instruction of the
// enclosing function; may be null, in which case the offending block's own
// terminator is used). Null entries in `Blocks` are skipped, so a caller can
// pass an optional block (`R.ArmFalse` is null for a diamond) without a guard of
// its own. Returns true if it declined.
bool declineAddressTakenBlocks(llvm::ArrayRef<llvm::BasicBlock *> Blocks,
                               llvm::Instruction *At);

// GUARD 2 for a stage that erases a set it does not NAME — `Fp80Union`'s
// `removeUnreachableBlocks(F)`. A drop-in replacement for that call: same return
// value (did anything change), plus the guard.
//
// *** IT OBSERVES THE DELETION SET RATHER THAN PREDICTING IT, and that is the
// whole point. *** An earlier draft predicted the set with a depth-first walk from
// the entry, on the reading that `llvm::removeUnreachableBlocks` deletes exactly
// the DFS-unreachable blocks. The Rule-13 round measured that WRONG: LLVM 19 runs
// `markAliveBlocks` FIRST, which MUTATES — a store to null, a `noreturn` call or
// an `llvm.assume(false)` becomes `unreachable` — so blocks that were reachable a
// moment earlier are orphaned and the real deletion set is a strict SUPERSET. The
// round shipped the `blockaddress`→`i32 1` miscompile through that gap on three
// independent triggers, with `opt` exit 0.
//
// So this wrapper watches every block whose address is genuinely USED with a
// `WeakTrackingVH`, calls the real utility, and declines if a watched block
// actually died. Nothing is modelled, so nothing can drift when LLVM changes.
// Checking the whole function up front instead would over-decline a SURVIVING
// address-taken block — the case
// `control_swap_accept_blockaddress_outside_region.ll` pins.
bool removeUnreachableBlocksChecked(llvm::Function &F, llvm::Instruction *At);

}  // namespace cq

#endif  // CQ_IRPASS_LITERAL_INTEGRITY_H_
