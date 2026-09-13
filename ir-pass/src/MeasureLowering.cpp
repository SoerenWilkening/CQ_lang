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

// The undef/poison operand (21mg verdict (a)). A classical measure is a READ of
// a classical value, and an `undef`/`poison` literal is not a value: the `-O0`
// stage-3 link may materialize it differently at each use (the
// `LiteralIntegrity` / `declineUnpairedUndefLiterals` posture — one `undef`
// token read as two values), so the outcome this "measurement" reports is not
// reproducible and the golden byte-diff contract (Rule 2) has nothing to pin.
// The frontend's own declaration agrees: every `cq_measure_<sfx>` parameter
// carries `noundef`, so an `undef` there is already a contract violation, and
// reaching one means the source read an uninitialized object (UB in C — there is
// no circuit, trivial or otherwise, to emit). Over-declining is safe; a silently
// arbitrary measurement outcome is not (Prime Directive).
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
// `$SES/trackC/review_C_r1_probes/r12_measure_undef_phi.c`. Grounds 1 and 2 (an
// `undef` token is not a value at the `-O0` stage-3 link; the `noundef`
// parameter attribute) are the ones that cover exactly what the predicate does.
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
