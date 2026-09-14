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
// ⚠ AND THE RESIDUAL MAY ITSELF BE AN OVER-DECLINE — recorded, not fixed. The
// operand is defined, so a classical measure of it is well-defined, and
// `slotCarriesUndef` (the `SkipGlobals=true` twin, which exists for exactly
// this distinction) would accept it. That swap was NOT taken with `fve8`
// because the ruling scopes the retirement to the `undef`/`poison` OPERAND, and
// because it would leave this string with no customer at all — a string with no
// fixture is the mirror of a fixture with no subject. Filed as an over-decline
// candidate (owner ruling 2026-09-11: an over-decline is a defect to remove,
// not a free safety margin); the fixture carries the retirement trigger.
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
      //     `$SES/trackE2/IMPL_E2.md` §4; this is the same text at the
      //     mechanism. ***
      //
      // THE RIVAL READING, AS A PROGRAM AND NOT AS AN IR SHAPE:
      //
      //     int u; return cq_measure(u);
      //
      // The author read an UNINITIALIZED OBJECT. On a real machine that object
      // holds whatever the stack slot held — not zero — so the rival reading is
      // "this measurement reports garbage, and the program has no defined
      // outcome". The compiler now reports 0, in every spelling, silently.
      //
      // WHY THE RIVAL HAS NO LOWERING TO BE ROBBED OF — two halves, because
      // either alone would be an assertion. (1) On the ORACLE the module is a
      // LOUD DECLINE, so there was no circuit for the rival reading and nothing
      // is displaced. (2) The accept it now receives is a REFINEMENT, not a
      // choice between two circuits: LangRef lets an `undef` stand for ANY
      // value of its type, so `0` at the read is a value the source ALREADY
      // LICENSED, and the emitted stream is BYTE-IDENTICAL to what a written
      // `= 0` produces — measured over the decline's whole censused
      // population, 0 divergences, 0 `A→D` (`IMPL_E2.md` §3). And the
      // measurement is CLASSICAL: branch (1) emits no gate, no rail and no
      // trace line, so the QUANTUM stream is untouched — the only thing that
      // moves is a classical value LangRef already permitted to be anything.
      //
      // WHY DISCLOSURE AND NOT A PREDICATE. After `-O1` there is nothing left
      // to discriminate: "the author meant to read garbage" and "the author
      // forgot an initializer" are THE SAME MODULE. A fence that refused the
      // first would refuse the second, which is the program the ruling exists
      // to compile. And a warning was DELIBERATELY NOT ADDED, for the reason
      // the owner has now given twice on this family — "both codes are supposed
      // to compie!! also no warnings."
      //
      // ⚠ A SECOND THING IS ABSORBED AND IT IS NOT ABOUT `undef` AT ALL:
      // `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so
      // this decline used to PREEMPT THE WHOLE MODULE. A module with one
      // uninitialized classical measure beside real quantum content was refused
      // entire; it now proceeds — to an accept, or to whatever LATER decline it
      // always had. A program that moves `D→D` on a DIFFERENT string is
      // therefore an expected mover of this change, not an anomaly, and the
      // corpus sweep is read with that in mind.
      //
      // ⚠ RETIREMENT TRIGGERS, each naming what would make the paragraph above
      // WRONG rather than merely out of date:
      //   (i)   THE RAUW TARGET STOPS BEING THE TYPE'S ZERO (a switch to
      //         `Handle`, or a "simplification" that drops the explicit
      //         `Measure->getType()`). The refinement claim is a claim about
      //         THAT value; with any other target it is false, and the
      //         `NOUNDEF` prefix of `lowering_accept_measure_undef_zero.ll` is
      //         the tripwire.
      //   (ii)  THIS CLAUSE STARTS REWRITING ANYTHING THAT IS NOT
      //         `isa<UndefValue>`, or `undef` stops being uniqued per type.
      //         Those are the refinement's only two load-bearing facts — the
      //         same pair `RotationLowering.cpp` names as ITS trigger (ii),
      //         which now has a SECOND customer here — and either one gone
      //         makes this an OVER-ACCEPT.
      //   (iii) THE 7.6 OUTPUT TAPE DECIDES THAT EVERY USER-WRITTEN
      //         `cq_measure` REACHES THE TAPE. Branch (1) emits no trace line
      //         at all, and this clause moves one more shape into it. It is the
      //         same open question bd `21mg` left (`CQLoweringPass` Q-1) and it
      //         must be answered together with that one, not separately.
      //   (iv)  `valueCarriesUndef` STOPS WALKING GLOBAL INITIALIZERS
      //         (`SkipGlobals` flips, or `slotCarriesUndef` replaces it at
      //         (1b)). Then the residual has no member, `kMsgUndefOperand` has
      //         no customer, and the string must be DELETED in that same change
      //         — not left standing with a fixture that pins nothing.
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
