// MeasureLowering.cpp — Lower `@cq_measure_<sfx>` calls to the matching
// `@cqrt_measure_<W>(handle)` runtime entry per PRD §"Width unification".
// Generalizes the original path (which was pinned to `cq_measure_si32` →
// `cqrt_measure_i32`) by deriving the runtime symbol per call site:
//
//   1. Resolve the suffix from the front-end intrinsic name (strip the
//      `cq_measure_` prefix).
//   2. Collapse signedness via `WidthDispatch::abiWidthFor(sfx)` (e.g.
//      `si16` → `i16`, `f64` → `f64`).
//   3. Ask `WidthDispatch::measureRtFn(abiWidth)` for the lazy-declared
//      `@cqrt_measure_<W>` FunctionCallee.
//
// The handle argument is always i32 across every width (PRD §"Width
// unification"); only the return-value type varies.
//
// ── THE CLASSICAL MEASURE (bd test_C_libtooling-21mg) ────────────────────────
// Since 21mg this file has TWO dispositions, selected by TAINT and nothing else
// (Rule 3: taint is the only Q/C boundary):
//
//   * operand TAINTED  → the quantum measure above: `@cqrt_measure_<W>(handle)`.
//   * operand CLASSICAL → the measurement is the IDENTITY on the quantum state
//     and its outcome is the operand's own classical value, so the call is
//     REPLACED BY THE OPERAND: no runtime symbol, no gate, no trace line, no
//     rail. `cq_measure(<classical>)` is a valid (trivial) circuit, and
//     declining it was an OVER-DECLINE (the owner's 2026-09-11 22:18 file —
//     `bool b1 = 0; … cq_measure(b1)` — was refused outright).
//
// ⚠ SINCE bd `test_C_libtooling-fve8` (owner ruling 2026-09-15) THE CLASSICAL
// BRANCH HAS AN INTERNAL SPLIT, AND IT IS **NOT** ON TAINT. Which of the two
// top-level dispositions a measure takes is still decided by taint and nothing
// else; INSIDE the classical one, a WHOLE-VALUE `undef`/`poison` operand is
// RAUW'd to the type's concrete zero — clause (1a) — while a DEFINED constant
// that merely CARRIES an `undef` still declines — clause (1b). ⚠ THE SPLIT
// CHANGES NO VALUE'S ROUTE INTO BRANCH (1): its entry condition
// (`!taint.Tainted.count(Handle)`) is untouched, so exactly the same set of
// measures reaches it as before; only the DISPOSITION of one subset inside it
// moves. That statement is load-bearing for the rail-bank work, which exists to
// keep bank loads OUT of this branch (an untainted bank load taking branch (1)
// emits no gate, no symbol and no trace line, which the golden byte-diff is
// structurally blind to).
//
// ⚠ THE CLASSICAL PATH MUST NEVER MINT A RAIL. `cqrt_alloc_<W>` for a value the
// taint analysis says is classical is the f64/angle miscompile family ("allocate
// a qubit for classical data", Rule 3 / Key Prohibitions); it is also why the
// suffix → ABI width → `measureRtFn` resolution now happens INSIDE the quantum
// branch and not before the split: `measureRtFn` LAZILY DECLARES
// `@cqrt_measure_<W>` in the module, so resolving it for a classical measure
// would leave an unused runtime declaration behind in a module that has no
// quantum content at all.
//
// ⚠ ORDER IS THE WHOLE L1 ARGUMENT FOR THE ROUND-2 CASE. `lowerMeasures` runs
// AFTER `repropagateControlMerges` in BOTH entry points (`CQLoweringPass.cpp`
// `run()` and `runOnFunction()`), so `taint.Tainted` is FINAL here: a value that
// is classical at round 1 and tainted at the round-2 fixpoint — the 6.5 / 4.5
// merge `%out` rails, `taint.UntaintedMergeRails` — is TAINTED when this runs
// and takes the quantum path. That is pinned by
// `control_classical_call_arm_accept.ll` (its `cq_measure_si32(%y)` on the 6.5
// merge rail lowers to `cqrt_measure_i32(%out)`), by
// `lowering_measure_round2_sixfive_handle.ll` (which pins it as its SUBJECT) and
// by the `e2e-slice-classical-call-under-control` golden. RETIREMENT TRIGGER: if
// `lowerMeasures` is ever moved above `repropagateControlMerges`, a round-2 rail
// measure silently becomes a CLASSICAL passthrough of an i32 handle — a
// verify-clean silent miscompile (the measurement vanishes and the handle is
// returned as data). Those three fixtures are what goes red; do not "fix" them
// by regenerating.

#include "MeasureLowering.h"

#include "LiteralIntegrity.h"  // valueCarriesUndef (the undef-operand fence)
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constant.h"   // Constant::getNullValue (the fve8 RAUW target)
#include "llvm/IR/Constants.h"  // UndefValue / PoisonValue (the fve8 conjunct)
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {

// ⚠ CHARACTER-FOR-CHARACTER, and it is a RETAINED string, not a new one: the
// tainted-but-unlowerable operand is this fence's real subject and keeps the
// exact message it has carried since 51f362c. Mirrored by
// `lowering_reject_measure_*` (see `MeasureLowering.h`).
constexpr char kMsgOperand[] =
    "cq_measure_<sfx> operand not recognized; expected a tainted i32 handle";

// ── THE RESIDUAL undef/poison OPERAND ───────────────────────────────────────
//
// ⚠ THIS STRING NO LONGER COVERS THE SHAPE IT WAS WRITTEN FOR, AND SAYING SO IS
// THE POINT OF THIS BLOCK. bd `21mg` verdict (a) declined EVERY operand
// `valueCarriesUndef` answered true for. The owner's ruling of 2026-09-15 —
// bd `test_C_libtooling-fve8`, `DECISIONS.md` E2 — **RETIRED that for the
// WHOLE-VALUE `undef`/`poison` spelling**, which now lowers as the type's
// concrete zero at clause (1a) in `lowerMeasures` below. That ruling RETIRES
// PART OF THE OWNER'S OWN 2026-09-14 RULING (bd `z9t1` clause 4); it is
// recorded here, at the mechanism, and not only in a session record, because a
// record correction that is not applied to the source is not a correction
// (CLAUDE.md L7-with-a-twist, a defect found three times on one sentence).
//
// WHAT IS LEFT IS THE RESIDUAL, and it is a MEASURED customer rather than a
// string kept alive for its fixture:
//
//   `valueCarriesUndef` is `carriesUndefImpl(C, Seen, /*SkipGlobals=*/false)`
//   (`LiteralIntegrity.cpp`), so it walks INTO a referenced global's
//   INITIALIZER. `cq_measure(ptrtoint (ptr @g to i32))` with
//   `@g = global { i32, i32 } { i32 1, i32 undef }` therefore lands HERE with a
//   FULLY DEFINED operand — the address of `@g`, truncated — whose only `undef`
//   is a field that operand never reads. Pinned by
//   `lowering_reject_measure_undef_global_init.ll`; its one-token control
//   (`{ i32 1, i32 2 }`) ACCEPTS, which is what makes the fixture non-vacuous.
//
// ⚠ AND `ptrtoint (ptr undef to i32)` IS **NOT** A MEMBER OF THAT RESIDUAL — it
// only looks like one. The LLVM-19 parser CONSTANT-FOLDS it to plain
// `i32 undef` before the pass runs (measured: `opt -passes=verify -S` reprints
// the call as `@cq_measure_si32(i32 undef)`), so it is the whole-value clause
// under a different source spelling and it ACCEPTS. A residual member needs a
// `GlobalValue` in the constant's operand chain, because that is the one thing
// the folder cannot evaluate. Pinned as `@f_constexpr_undef` in
// `lowering_accept_measure_undef_zero.ll`, with its own retirement trigger.
//
// ⚠ GROUNDS 1 AND 2 OF THE OLD FOUR-GROUND ARGUMENT ARE THE ONES THE
// RETIREMENT CONSUMED — they no longer argue anything, and leaving them
// standing would be the defect this file is required to avoid. "An `undef` token is
// not a value at the `-O0` stage-3 link" and "the parameter carries `noundef`"
// were arguments about a WHOLE-VALUE `undef` in the operand slot — exactly the
// case that now ACCEPTS, because the ruling replaces that token with a concrete
// zero before anything downstream can read it twice. The ground that survives
// for the residual is narrower and is the one clause (1a) turns on: this
// operand IS a value, so the pass can neither rewrite it to zero (that would
// CHANGE a value the source defined) nor pass it through without deciding what
// the referenced initializer's `undef` field means. Declining is the
// Prime-Directive direction for a question nobody has ruled.
//
// ⚠ AND THE RESIDUAL MAY ITSELF BE AN OVER-DECLINE — recorded, not fixed, and
// THE REASON IT IS NOT FIXED WAS RE-GROUNDED ON 2026-09-15 (review round 1,
// item 3). The operand is defined, so a classical measure of it is
// well-defined, and `slotCarriesUndef` (the `SkipGlobals=true` twin, which
// exists for exactly this distinction) would accept it.
//
// THE GROUND THAT HOLDS IS SEMANTIC. `slotCarriesUndef`'s `SkipGlobals=true`
// exists for EMITTED GATE SLOTS, and its argument — "a `GlobalValue`'s operands
// are its INITIALIZER, while the value under test is the global's ADDRESS,
// which is defined no matter what it is initialized to" (`LiteralIntegrity.cpp`)
// — is an argument about LITERAL INTEGRITY AT THE `-O0` STAGE-3 LINK: the same
// token must denote the same value at every slot the lowering copies it to. A
// MEASUREMENT asks a DIFFERENT question — what value does this read report? —
// and nobody has ruled whether an initializer's `undef` field is reachable from
// it. Swapping the predicate here would be ADDING A CALLER TO A SHARED
// PREDICATE WITHOUT ASKING WHETHER THE CALLEE'S ARGUMENT REACHES THE NEW
// CALLER: CLAUDE.md's MIRROR OF L3, the defect that cost a P1 filing on
// 2026-09-14 (`WireWalk.h` / `readerStalesItself`), whose instruction — WIDEN
// THE VOCABULARY OR FENCE THE CALLER IN THE SAME CHANGE — applies verbatim. So
// the swap needs an OWNER RULING on that semantics question; it is not
// developer discretion, and it was out of scope for `fve8`, whose ruling scopes
// the retirement to the `undef`/`poison` OPERAND.
//
// ⚠ AND THE GROUND THAT DOES **NOT** HOLD, recorded because it is the one that
// stood here first: "the swap would leave this string with no customer at all —
// a string with no fixture is the mirror of a fixture with no subject."
// HYGIENE IS NOT A GROUND FOR KEEPING AN OVER-DECLINE (owner ruling 2026-09-11:
// an over-decline is a defect to remove, not a free safety margin); the correct
// response to "no customer" is to DELETE THE STRING, which is exactly what
// retirement trigger (iv) in `lowerMeasures` already requires. That sentence is
// BINDING as a CONSEQUENCE of the swap and was never a REASON against it.
//
// Filed as an over-decline candidate; the fixture
// (`lowering_reject_measure_undef_global_init.ll`) carries the same trigger and
// the same re-grounding. ⚠ Practical weight, measured: a residual member needs
// a `GlobalValue` in the operand's constant chain, i.e. roughly
// `cq_measure((int)(intptr_t)&g)` with `g` partly uninitialized. No customer
// writes it — which is a reason the question is not urgent, and not a reason
// the answer is obvious.
//
// ⚠ BOUND THE CLAIM TO THE LITERAL SHAPE (L5 — review_C_r1 item 2).
// `valueCarriesUndef` is CONSTANT-ONLY (`LiteralIntegrity.cpp:113-119`: a
// non-`Constant` returns false immediately), so this fence catches
// `cq_measure(undef)` / `cq_measure(poison)` and an `undef` nested inside a
// constant — and NOTHING ELSE. The third ground above ("the source read an
// uninitialized object") is therefore BROADER THAN THE PREDICATE: `int u; if
// (q == 3) u = 4; cq_measure(u);` is exactly that UB and it COMPILES, because
// `-O1` folded the φ to a defined value; a surviving `phi`/`select` with an
// `undef` incoming is likewise an ACCEPT, not a decline. Measured:
// `$SES/trackC/review_C_r1_probes/r12_measure_undef_phi.c`. ⚠ AND SINCE `fve8`
// THE THIRD GROUND IS NOT MERELY BROADER — IT IS NO LONGER A GROUND AT ALL for
// the shape it named: `int u; cq_measure(u);` is that same C UB, it is the
// program the ruling was ABOUT, and it now compiles. (The old sentence here
// closed by saying grounds 1 and 2 "cover exactly what the predicate does";
// that is now false in the other direction — see the block above, where those
// two grounds are the ones the retirement consumed.) What the predicate does
// TODAY is: whole-value `undef`/`poison` ⇒ ACCEPT as the type's zero; a DEFINED
// constant that merely CARRIES an `undef` through a `GlobalValue` initializer ⇒
// this decline; everything non-`Constant` ⇒ never reaches either.
constexpr char kMsgUndefOperand[] =
    "cq_measure_<sfx> operand is an undef/poison literal; a classical "
    "measurement needs a defined value";

// Extract the suffix from a front-end measure intrinsic's name
// (`cq_measure_<sfx>`). Returns "" if the name doesn't match the
// expected prefix; callers treat an empty suffix as an unrecognized
// width and surface a diagnostic.
StringRef suffixFromMeasureName(const CallInst *Measure) {
  Function *Callee = Measure->getCalledFunction();
  if (!Callee)
    return {};
  StringRef N = Callee->getName();
  constexpr StringRef kPrefix = "cq_measure_";
  if (!N.starts_with(kPrefix))
    return {};
  return N.substr(kPrefix.size());
}

void diagnoseMeasure(CallInst *Measure, const char *Msg, bool WithDbg) {
  Measure->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Measure->getFunction(), Msg,
      WithDbg ? Measure->getDebugLoc() : DebugLoc()));
}

}  // namespace

void lowerMeasures(Module &M, WidthDispatch &wd, TaintSet &taint) {
  (void)M;
  if (taint.MeasureCalls.empty())
    return;

  Type *I32 = wd.i32Ty();
  IRBuilder<> Builder(wd.context());

  std::vector<Instruction *> ToErase;
  for (CallInst *Measure : taint.MeasureCalls) {
    Value *Handle = Measure->getArgOperand(0);

    // ── (1) THE CLASSICAL MEASURE — bd 21mg ─────────────────────────────────
    // Asked FIRST and asked ONLY of taint (Rule 3). `taint.Tainted` is final
    // here (see the file header on the round-2 order), so "not tainted" means
    // "no quantum lineage in the whole module" — a constant, a function
    // argument, classical arithmetic, a classical `phi`/`select`, or the result
    // of an earlier `cq_measure` (already lowered or not: a measure result is a
    // SINK and is never tainted, `isMeasureSink`).
    if (!taint.Tainted.count(Handle)) {
      // ── (1a) THE WHOLE-VALUE `undef`/`poison` OPERAND — ACCEPT, AS THE
      // TYPE'S CONCRETE ZERO. bd `test_C_libtooling-fve8`, owner ruling
      // 2026-09-15 (`DECISIONS.md` E2). It RETIRES part of the owner's own
      // 2026-09-14 ruling (bd `z9t1` clause 4); the rationale block on
      // `kMsgUndefOperand` above says what survives and why.
      //
      // ⚠ THE RAUW TARGET IS `Constant::getNullValue(Measure->getType())`, NOT
      // `Handle`, AND THAT IS THE LOAD-BEARING DETAIL OF THE WHOLE RULE. The
      // owner's words are "measures the type's concrete zero": the target is
      // the MEASUREMENT'S OUTCOME, not the operand. RAUW-to-`Handle` would
      // leave every downstream reader looking at `undef` again — `add nsw i32
      // %m, undef` where the written-zero twin has `add nsw i32 %m, 0` — and
      // the refinement claim below would be FALSE (measured: the
      // operand-spelling diverges from the twin on the whole measured
      // population; the zero spelling diverges on none of it). Minting from
      // `Measure->getType()` rather than from `Handle->getType()` also makes
      // the RAUW type-correct by construction, independently of the
      // unreachable type guard below.
      //
      // ⚠ ONLY A WHOLE-VALUE `undef` IS REWRITABLE — bd `z9t1`'s conjunct,
      // verbatim in shape (`RotationLowering.cpp`: "the predicate gates a
      // DECLINE everywhere else and a REWRITE here"). `PoisonValue` derives
      // from `UndefValue`, so this one `isa` covers `poison` with no second
      // predicate. The ORDER of (1a) before (1b) is load-bearing:
      // `valueCarriesUndef` is TRUE of a whole-value `undef`, so testing it
      // first would re-swallow exactly the shape the ruling retired.
      //
      // ⚠ THE OPERAND'S **OTHER** USES ARE NOT REWRITTEN, deliberately, and it
      // mirrors `z9t1` (which normalizes a theta seed and its theta-carrying
      // phi incomings and nothing else). `int u; int m = cq_measure(u); return
      // m + u;` keeps `u` as `undef` at the second read. State it; do not
      // quietly widen it — a value-wide normalisation is a different rule with
      // a different soundness argument and it was not ruled.
      //
      // ── ⚠ DISCLOSURE — WHAT THIS RULE SILENTLY ABSORBS ────────────────────
      //
      // *** IN THE WORDS CLAUDE.md §4c INSISTS ON. This is the same class of
      //     silent widening as bd `z9t1`'s own disclosure and the F2 α/β
      //     narrowing: a loud refusal becomes a silent compile, no predicate
      //     can separate the readings after `-O1`, and the mitigation is
      //     DISCLOSURE, not a fence. The normative copy is
      //     `$SES/trackE2/IMPL_E2.md` §6, as extended by `$SES/e2fix/FIX.md`
      //     §1 under the owner ruling `DECISIONS.md` E9; this is the same text
      //     at the mechanism. ***
      //
      // ⚠ THERE ARE **TWO** RIVAL READINGS AND THE SECOND ONE IS QUANTUM.
      // Rival 1 shipped with the ruling. Rival 2 was found by the independent
      // Rule-13 round (`review_r13_e2/REVIEW.md` F-E2-1, P1) on the very
      // binary this block was written against, and is disclosed here by the
      // owner ruling of 2026-09-15 (`DECISIONS.md` E9: ACCEPT, AND DISCLOSE
      // THE QUANTUM RIVAL). Whoever quotes this block must quote BOTH: reading
      // only rival 1 is how this clause was signed off once already.
      //
      // ── RIVAL 1 (CLASSICAL), AS A PROGRAM AND NOT AS AN IR SHAPE:
      //
      //     int u; return cq_measure(u);
      //
      // The author read an UNINITIALIZED OBJECT. On a real machine that object
      // holds whatever the stack slot held — not zero — so the rival reading is
      // "this measurement reports garbage, and the program has no defined
      // outcome". The compiler now reports 0, in every spelling, silently.
      //
      // WHY RIVAL 1 HAS NO LOWERING TO BE ROBBED OF — two halves, because
      // either alone would be an assertion. (1) On the ORACLE the module is a
      // LOUD DECLINE, so there was no circuit for the rival reading and nothing
      // is displaced. (2) The accept it now receives is a REFINEMENT, not a
      // choice between two circuits: LangRef lets an `undef` stand for ANY
      // value of its type, so `0` at the read is a value the source ALREADY
      // LICENSED.
      //
      // ⚠ AND THE CORROBORATION IS STATED AS WHAT WAS MEASURED, NOT AS WHAT
      // WOULD BE NICER TO SAY. The emitted stream is BYTE-IDENTICAL TO THE
      // SAME MODULE WITH THAT ONE OPERAND TOKEN WRITTEN AS THE TYPE'S ZERO —
      // 12 of 12 measured by the track (`IMPL_E2.md` §3), extended to 32 of 32
      // by the review (`REVIEW.md` §3 item 11), 0 divergences, 0 `A→D`. It is
      // **NOT** "byte-identical to what a written `= 0` produces": that
      // sentence stood HERE, in shipped source, until 2026-09-15, and it is
      // FALSE for an operand with more than one use — this clause rewrites the
      // MEASUREMENT'S RESULT and never the operand's other reads, so
      // `int u; int m = cq_measure(u); return m + u;` keeps `undef` at the
      // second read where the written-`= 0` source has `0` (measured:
      // `$SES/trackE2/probes/src/e2e_undef_used_twice.c`, `ret i32 undef` vs
      // `ret i32 0`). The SOUNDNESS ground is LangRef and is UNAFFECTED — each
      // read of an `undef` may independently be any value of its type, so
      // rewriting one read while another stays `undef` is a legal refinement —
      // what was wrong is the CLAIM, by exactly the multi-use case.
      // (F-E2-2, P2, review round 1. CLAUDE.md L7-with-a-twist: the correction
      // is landed AT THE MECHANISM in the same change as the record's, because
      // a record correction that is not applied to the source is not a
      // correction — a defect found THREE times on one sentence in
      // `RotationLowering.cpp` before it landed.)
      //
      // And the measurement is CLASSICAL: branch (1) emits no gate, no rail and
      // no trace line, so the QUANTUM stream is untouched — the only thing that
      // moves is a classical value LangRef already permitted to be anything.
      //
      // WHY DISCLOSURE AND NOT A PREDICATE, FOR RIVAL 1. After `-O1` there is
      // nothing left to discriminate: "the author meant to read garbage" and
      // "the author forgot an initializer" are THE SAME MODULE. A fence that
      // refused the first would refuse the second, which is the program the
      // ruling exists to compile. And a warning was DELIBERATELY NOT ADDED, for
      // the reason the owner has now given twice on this family — "both codes
      // are supposed to compie!! also no warnings."
      //
      // ── RIVAL 2 (QUANTUM), AS A PROGRAM AND NOT AS AN IR SHAPE:
      //
      //     int u; int q = cq_theta(0, 0.3); return cq_measure(q + u);
      //
      // The author wrote A MEASUREMENT OF A QUANTUM REGISTER. `clang -O1` folds
      // `add nsw %q, undef` → `undef`, and that fold DELETES THE DATA-FLOW EDGE
      // TO THE THETA, so the operand this clause sees has no quantum lineage
      // anywhere in the module: `taint.Tainted` is correct and irrelevant,
      // branch (1) is entered legitimately, and (1a) reports 0.
      //
      // MEASURED on the two frozen binaries (`REVIEW.md` §1): ORACLE exit 1,
      // the loud decline. SUBJECT exit 0, **0 BYTES OF STDERR**, a 2-line trace
      // (`cqrt_alloc_i32` + `cqrt_ry_i32`), and **NO `cqrt_measure` IN THE
      // EMITTED MODULE AT ALL** — while the C-level written-zero twin
      // (`int u = 0;`) emits 3 lines WITH the measurement. SAY IT IN THOSE
      // WORDS: **A USER-WRITTEN MEASUREMENT DISAPPEARS AND NOTHING IS
      // PRINTED.** The prepared rail is left allocated. Rule 5's hard invariant
      // — never INSERT a measurement the user did not write — is intact; its
      // MIRROR is not, and CQ does not diagnose that.
      //
      // WHY RIVAL 2 HAS NO LOWERING TO BE ROBBED OF — and note that the SECOND
      // half here is PRE-EXISTENCE, not refinement, because the refinement
      // argument above does NOT reach this rival (see the instrument warning
      // below). (1) On the ORACLE this module is a LOUD DECLINE, so no circuit
      // for the rival reading is displaced. (2) THE CLASS ALREADY SHIPS AT
      // HEAD, on spellings this clause never touches: `cq_measure(q * u)` and
      // `cq_measure(q & u)` fold to a CONCRETE `0` at stage 1 — not to `undef`
      // — so they enter branch (1) with a defined operand and ACCEPT ON THE
      // ORACLE, emitting the IDENTICAL 2-line stream (measured, equal trace
      // sha `684d2394674bd01b`). ⇒ **THIS CLAUSE EMITS NO STREAM HEAD COULD NOT
      // ALREADY EMIT.** What it adds is the `undef`-FOLDING spellings and THE
      // SILENCE. A decline here would be a NEW refusal that leaves `q * u` and
      // `q & u` untouched — it would not close the class, only the half this
      // clause can see.
      //
      // WHY DISCLOSURE AND NOT A PREDICATE, FOR RIVAL 2. The discriminator
      // would have to be "this operand ONCE carried taint", and `-O1` has
      // already erased the edge that fact lived on — which is precisely why
      // branch (1) takes it. A taint-HISTORY test does not exist in the IR in
      // front of the pass (CLAUDE.md L5: a syntactic answer to a semantic
      // question loses). The only decidable alternative is a Rule-5-MIRROR
      // POSTCONDITION — "the module lowered a theta whose handle is never
      // measured" — and it fires on every legitimately unmeasured register,
      // which is most of the tree. ⚠ NO WARNING HERE EITHER: same owner ruling,
      // restated in `DECISIONS.md` E9.
      //
      // ⚠⚠ THE INSTRUMENT AGREES WITH THIS ONE — READ THIS BEFORE CITING THE
      // REFINEMENT NUMBER. `$SES/trackE2/probes/refinement_check.py`, the gate
      // the rival-1 argument rests on, reports the rival-2 module
      // **BYTE-IDENTICAL**, because its twin rewrites ONE TOKEN of the module
      // THE PASS SEES and therefore INHERITS THE VERY FOLD THAT ERASED THE
      // TAINT. The only comparison that can see rival 2 is the C-LEVEL twin
      // (the `undef` source on the subject against the `= 0` source on the
      // oracle), a different and weaker instrument the track ran exactly once,
      // on a program where the two coincide. CLAUDE.md L10 on a checker this
      // repo ships — an instrument's failure mode is to report a PASS — so do
      // NOT read "0 divergences" as covering rival 2. It cannot see it.
      //
      // Rival 2 is PINNED by `lowering_measure_undef_operand_after_taint_fold.ll`
      // (the accept, whose whole-file `NOMEASURE` prefix pins that the user's
      // measurement is ABSENT) and by its one-token control
      // `lowering_measure_taint_fold_control.ll` (the same module with the
      // operand spelled as the theta's result, which emits the measurement on
      // BOTH binaries). Those two files are the only artefacts in the tree that
      // make the next reader see this shape.
      //
      // ⚠ ONE MORE THING IS ABSORBED, AND IT IS ABOUT NEITHER RIVAL AND NOT
      // ABOUT `undef` AT ALL (it was numbered "second" when there was one
      // rival; the rivals are now two and this is not the third of them):
      // `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so
      // this decline used to PREEMPT THE WHOLE MODULE. A module with one
      // uninitialized classical measure beside real quantum content was refused
      // entire; it now proceeds — to an accept, or to whatever LATER decline it
      // always had. A program that moves `D→D` on a DIFFERENT string is
      // therefore an expected mover of this change, not an anomaly, and the
      // corpus sweep is read with that in mind.
      //
      // ⚠ RETIREMENT TRIGGERS, each naming what would make the paragraphs above
      // WRONG rather than merely out of date. ⚠ THE NUMBERING IS DELIBERATELY
      // STABLE: (i)–(iv) are cited by number in `IMPL_E2.md` §6 and in
      // `review_r13_e2/REVIEW.md`, so the 2026-09-15 fix round SPLIT (ii) IN
      // PLACE and APPENDED (v)/(vi) rather than renumbering the list.
      //   (i)   THE RAUW TARGET STOPS BEING THE TYPE'S ZERO (a switch to
      //         `Handle`, or a "simplification" that drops the explicit
      //         `Measure->getType()`). The refinement claim is a claim about
      //         THAT value; with any other target it is false, and the
      //         `NOUNDEF` prefix of `lowering_accept_measure_undef_zero.ll` is
      //         the tripwire.
      //   (ii)  THIS CLAUSE STARTS REWRITING ANYTHING THAT IS NOT
      //         `isa<UndefValue>`. That is the ONE fact this clause shares with
      //         bd `z9t1`'s trigger (ii) in `RotationLowering.cpp` — same
      //         predicate, same direction (it gates a DECLINE everywhere else
      //         and a REWRITE here), same consequence if widened — and widening
      //         it makes this an OVER-ACCEPT.
      //         ⚠ THE OTHER HALF OF `z9t1`'s PAIR — "`undef` stops being
      //         uniqued per type" — DOES **NOT** TRANSFER, AND THIS BLOCK
      //         CLAIMED IT DID (as a "SECOND customer" of the PAIR) UNTIL
      //         2026-09-15. F-E2-3, P2, review round 1; CLAUDE.md's MIRROR OF
      //         L3 — when you ADD A CALLER to a shared argument, read the
      //         callee's trigger and STATE WHICH DIRECTION YOU ARE USING IT IN.
      //         Uniquing is load-bearing for `z9t1` because F1's second
      //         sub-clause is a literal `Value*` IDENTITY test (`ArmClassify`:
      //         `MergePhi->getIncomingValue(PredIdx) != RotBase`), so
      //         manufacturing a uniqued zero makes two operands THE SAME
      //         POINTER — that is the whole `z9t1` disclosure. THIS CLAUSE
      //         PERFORMS NO IDENTITY TEST ANYWHERE: it asks a TYPE question
      //         (`isa<UndefValue>`) and RAUWs the measurement's RESULT to
      //         `Constant::getNullValue(Measure->getType())`. E2 is a HALF
      //         customer of that trigger, not a second customer of the pair,
      //         and (v) is the fact that actually carries the argument the
      //         borrowed half was standing in for.
      //   (iii) THE 7.6 OUTPUT TAPE DECIDES THAT EVERY USER-WRITTEN
      //         `cq_measure` REACHES THE TAPE. Branch (1) emits no trace line
      //         at all, and this clause moves one more shape into it. It is the
      //         same open question bd `21mg` left (`CQLoweringPass` Q-1) and it
      //         must be answered together with that one, not separately.
      //         ⚠ Since 2026-09-15 it is also THE trigger that would close
      //         RIVAL 2: rule that every user-written `cq_measure` reaches the
      //         tape and rival 2 stops compiling — together with the `q * u` /
      //         `q & u` spellings HEAD already ships, which is the only way to
      //         close the CLASS rather than the half this clause can see.
      //   (iv)  `valueCarriesUndef` STOPS WALKING GLOBAL INITIALIZERS
      //         (`SkipGlobals` flips, or `slotCarriesUndef` replaces it at
      //         (1b)). Then the residual has no member, `kMsgUndefOperand` has
      //         no customer, and the string must be DELETED in that same change
      //         — not left standing with a fixture that pins nothing. ⚠ That
      //         swap is an OWNER question, not developer discretion; the
      //         re-grounded argument is on `kMsgUndefOperand` above.
      //   (v)   ⚠ NEW, 2026-09-15 (F-E2-3): `lowerMeasures` RUNS AFTER EVERY
      //         `Value*`-IDENTITY FENCE IN THE PASS. It is called in BOTH entry
      //         points AFTER `repropagateControlMerges`, hence after every
      //         `detectControlRegions` / `classifyArms` / F1 / F2, so a zero
      //         manufactured HERE cannot reach a pointer-identity test at all.
      //         THAT is why `z9t1`'s uniquing worry is vacuous for this clause,
      //         and it was stated NOWHERE before this round. Move
      //         `lowerMeasures` earlier — the same reordering bd `21mg`'s own
      //         trigger already forbids for a DIFFERENT reason (a round-2 rail
      //         measure degrading into a classical passthrough of an i32
      //         handle; see the file header) — and this clause's zeros start
      //         arriving at F1 beside `z9t1`'s, two rules compounding at a test
      //         neither was measured against. ONE ordering fact, two triggers:
      //         read them together.
      //   (vi)  ⚠ NEW, 2026-09-15, owner ruling `DECISIONS.md` E9: THE
      //         PRE-EXISTENCE GROUND FOR RIVAL 2 IS GONE. Either a
      //         taint-history record survives `-O1` folding (then a
      //         discriminator exists and "no predicate can separate the
      //         readings" is false), or `cq_measure(q * u)` / `cq_measure(q &
      //         u)` stop shipping this circuit on `main` (then the class no
      //         longer pre-exists and a decline here would close it rather than
      //         split it). Re-derive the rival-2 paragraph FROM SCRATCH; do not
      //         patch it.
      if (isa<UndefValue>(Handle)) {
        Measure->replaceAllUsesWith(
            Constant::getNullValue(Measure->getType()));
        ToErase.push_back(Measure);
        continue;
      }
      // ── (1b) THE RESIDUAL: a DEFINED constant that merely CARRIES an
      // `undef` (today: through a `GlobalValue`'s initializer). Rewriting it
      // would be a VALUE CHANGE, not a refinement — see `kMsgUndefOperand`.
      if (valueCarriesUndef(Handle)) {
        diagnoseMeasure(Measure, kMsgUndefOperand, /*WithDbg=*/true);
        continue;
      }
      // Type preservation is the frontend's, not ours: `cq_measure_<sfx>` is
      // declared `T (T)` and `declMatchesPrototype` (TaintPropagation.cpp)
      // REFUSES to collect any reserved-name decl that is not — so a collected
      // measure's return type IS its declared parameter type, and a direct
      // call's argument type IS that parameter type in any IR LLVM will parse
      // or verify. No `zext`/`trunc` is therefore owed, and the guard below is
      // unreachable at HEAD. It is kept, and kept LOUD on the retained string,
      // because the alternative failure mode is a Release-build RAUW of a
      // mistyped value (the `replaceAllUsesWith` type assert is compiled out
      // with NDEBUG and Release is what every gate here runs — CLAUDE.md
      // Rule 1).
      //
      // ⚠ IT REUSES `kMsgOperand`, AND THAT STRING NAMES NEITHER OF THIS CASE'S
      // FACTS (review_C_r1 item 1). The message says "expected a tainted i32
      // handle"; here the operand is CLASSICAL by construction (we are inside
      // branch (1)) and the mismatch is against the CALL'S OWN return type, not
      // against `i32`. The retained string is reused deliberately — it is
      // mirrored character-for-character by the negative fixtures and this case
      // is unreachable at HEAD (above), so splitting it would add a string no
      // input can produce — but if it ever fires it MISDIRECTS. The fix then is
      // a NEW string with its own Rule-12 fixture, not a re-reading of this one.
      // RETIREMENT TRIGGER: it becomes reachable, and owes that fixture, the day
      // a stage starts rewriting a CLASSICAL measure's argument slot with a
      // differently-typed value.
      if (Handle->getType() != Measure->getType()) {
        diagnoseMeasure(Measure, kMsgOperand, /*WithDbg=*/false);
        continue;
      }
      // The whole lowering: the outcome of measuring a classical value IS that
      // value. Nothing is emitted — no `cqrt_measure_<W>`, no `cqrt_alloc_<W>`,
      // no trace line — and the call is erased below, so
      // `declineSurvivingIntrinsicCalls` (Rule 1's checked postcondition) stays
      // satisfied. RAUW is dominance-safe by construction: `Handle` is already
      // an operand of `Measure`, so it dominates `Measure`, which dominates
      // every use being rewritten.
      Measure->replaceAllUsesWith(Handle);
      ToErase.push_back(Measure);
      continue;
    }

    // ── (2) THE QUANTUM MEASURE ─────────────────────────────────────────────
    // Resolve the per-call runtime symbol. Suffix → ABI width →
    // FunctionCallee. An unrecognized suffix or width is treated the
    // same as a missing decl: report and skip so the bad call survives
    // to a later verifier run.
    StringRef Sfx = suffixFromMeasureName(Measure);
    StringRef AbiWidth = wd.abiWidthFor(Sfx);
    FunctionCallee MeasureRT = AbiWidth.empty()
                                   ? FunctionCallee()
                                   : wd.measureRtFn(AbiWidth);
    if (!MeasureRT) {
      Measure->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *Measure->getFunction(),
          "cq_measure_<sfx>: unrecognized suffix or unsupported ABI width"));
      continue;
    }

    // Under the plain-SSA surface a TAINTED measure operand is always already an
    // i32 handle — a theta result RAUW'd to its alloc handle by
    // RotationLowering, or a `cq_template_*` result from OpcodeLowering. The
    // retired mid-struct patterns (direct init result, insertvalue unwrap) have
    // no inputs and are gone. A TAINTED operand that is NOT an i32 handle is a
    // tainted value the pass failed to lower — reported (loud) and left in
    // place, which `declineSurvivingIntrinsicCalls` then also catches.
    //
    // ⚠ MEASURED, 2026-09-13 (bd 21mg §2 (i)): no input reaches this branch
    // without an EARLIER `DS_Error`, and the first `DS_Error` terminates the
    // process (`LLVMContext::diagnose` → `exit(1)`), so this message cannot be
    // observed today. Every route to a tainted non-i32 value is a lowering that
    // already declined — `declineTaintEscapes` (vector/ptr/unsupported
    // instruction), `lowerOps`' `no template for opcode`, `declineClassicalMuxes`
    // (a classical-condition select), `declineStaleRecordOps`, or the rotation
    // declines — while every lowering that SUCCEEDS yields an i32 handle (6
    // shapes probed: `frem`/`fdiv` f64, `@llvm.sqrt.f64`, fptrunc/fpext round
    // trip, the one-register phi lift, `freeze` — all exit 0 with an i32
    // operand). It is a POSTCONDITION CHECK, not a primary fence; that is why
    // it ships with no `.ll` fixture of its own and why the predicate's real
    // Rule-12 pin is that a TAINTED operand must not take branch (1) — which
    // every quantum accept in the tree pins.
    if (Handle->getType() != I32) {
      diagnoseMeasure(Measure, kMsgOperand, /*WithDbg=*/false);
      continue;
    }

    Builder.SetInsertPoint(Measure);
    CallInst *NewM = Builder.CreateCall(MeasureRT, {Handle}, "m");
    if (DebugLoc DL = Measure->getDebugLoc())
      NewM->setDebugLoc(DL);
    Measure->replaceAllUsesWith(NewM);
    ToErase.push_back(Measure);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
