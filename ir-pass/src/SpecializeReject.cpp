// SpecializeReject.cpp — the single authoritative accept predicate for Phase 6
// specialization (Rule 14), plus the loud-diagnostic renderer. WHITELIST body
// scan: `BinaryOperator` / `UnaryOperator` / `CmpInst` / `CastInst` data ops,
// `phi` and `select` muxes, the `ret` / `br` / `switch` / `unreachable`
// terminators the clone's PredMux flatten collapses, the curated intrinsics and
// QROM reads, nested visible calls (scanned recursively), and quantum-primitive
// calls (which themselves reject) are recognized; EVERYTHING else is an unproven
// shape and rejects loudly (never silently). Each such reject of a valid program
// is an over-decline to remove (R1), not a free safety margin.

#include "SpecializeReject.h"

#include "CalleeBody.h"         // calleeBodyTrusted (bd p3kd.2 — the one body-trust predicate)
#include "IntrinsicLowering.h"
#include "LiteralIntegrity.h"   // slotCarriesUndef (bd 3p2a — the return-cone fence)
#include "OpcodeSupport.h"
#include "QramLowering.h"
#include "ReturnMerge.h"        // mustTailForwardBlocksDemotion (bd dm7f.5 ruling)
#include "SpecializePlan.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Exact-pointer membership of the front-end intrinsic call sites
// `propagate` already collected module-wide (NEVER name-prefix — C7). A clone
// candidate's body is the ORIGINAL callee body, whose theta/phi/measure calls
// were collected by `propagate`, so a body `CallInst` is a quantum primitive iff
// it is one of those exact pointers.
struct IntrinsicSets {
  SmallPtrSet<const CallInst *, 8> Rotations;  // theta + phi
  SmallPtrSet<const CallInst *, 8> Measures;
};

IntrinsicSets buildIntrinsicSets(const TaintSet &taint) {
  IntrinsicSets S;
  S.Rotations.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  S.Rotations.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  // bd test_C_libtooling-3qlq Inc 1 part A, Rule-13 round-1 finding F-L3-3.
  // `taint.PhiCalls` is the RETIRED register-form `@cq_phi_<sfx>` family and is
  // now PERMANENTLY EMPTY (`resolveSources` drops it, D1/D2), so without this
  // line no branch phase was recognized as a quantum primitive here at all.
  //
  // WHAT THAT ACTUALLY COST, measured rather than assumed: the reject stayed
  // LOUD, but on the WRONG GROUND. A `cq_phi` inside a specialization candidate
  // declined `callee contains a non-reversibilizable construct under quantum lift
  // (nested call)` — the unrelated DECLARATION-ONLY-CALLEE fallback — where the
  // pre-3qlq oracle said `callee contains a quantum primitive (cq_*); only
  // classical functions are lifted`. Two consequences, and the second is why this
  // is not cosmetic: the diagnostic named a cause that is not the cause, and the
  // fallback became the ONLY thing standing — if `@cq_phi` ever acquires a body
  // in the module the scan would recurse into it, find nothing, and clone a
  // Bennett-wrapped body containing an unlowered branch phase.
  S.Rotations.insert(taint.PhaseCalls.begin(), taint.PhaseCalls.end());
  S.Measures.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  return S;
}

// Does any operand or the result of `I` carry a vector type? A SIMD value has no
// per-lane reversible-copy story (`cqrt_copy` is scalar), so it is a
// non-reversibilizable construct.
bool touchesVector(const Instruction &I) {
  if (I.getType()->isVectorTy())
    return true;
  for (const Value *Op : I.operands())
    if (Op->getType()->isVectorTy())
      return true;
  return false;
}

// The first exception-handling construct in `F` (an `invoke`, a landing pad, a
// `resume`, or a Windows funclet pad/return), or null if `F` is EH-free. EH
// unwinding splits the body across blocks and threads a non-value control edge
// the straight-line Bennett reverse has no story for. Detected BEFORE the
// `size() != 1` gate so the diagnostic names "exception handling" rather than
// the generic in-body-control message (PRD §2.11).
Instruction *firstEHConstruct(Function &F) {
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (isa<InvokeInst>(I) || isa<LandingPadInst>(I) || isa<ResumeInst>(I) ||
          isa<CatchSwitchInst>(I) || isa<CatchPadInst>(I) ||
          isa<CleanupPadInst>(I) || isa<CatchReturnInst>(I) ||
          isa<CleanupReturnInst>(I))
        return &I;
  // A vestigial personality with no EH instruction (defensive): still EH intent.
  if (F.hasPersonalityFn())
    return F.getEntryBlock().getTerminator();
  return nullptr;
}

// Is `T` a scalar whose width has NO reversible template — i256+ / fp80 / fp128 /
// ppc_fp128 / a pointer / a non-power-of-2 _BitInt(N) / any other width
// `abiWidthFromType` does not recognize? Vectors are EXCLUDED (handled earlier
// with the more specific "vector SIMD" kind). NOTE (n0ui Tier-1): i128 is now a
// RECOGNIZED intermediate width (abiWidthFromType non-empty), so an i128 arith/
// cast intermediate inside a clone is ACCEPTED here (it lowers to cq_template_*_i128
// + reverses via the _unc twins; cf. spec_accept_i128_body.ll). The icmp-i128
// surface is NOT covered by this gate (the i1 result has a valid width) — it is
// declined by the dedicated compare-width fence in scanBody (mirrors
// CompareLowering's i128 fence). This is the body-op analog of the lowerOps width
// gate, catching the decline at the offending body op's `!dbg` rather than the
// late, clone-named lowerOps backstop (the WI-1.13 over-accept finding).
bool unsupportedWidth(Type *T) {
  return !T->isVectorTy() && abiWidthFromType(T).empty();
}

// bd p3kd.7.1 — the select gate, which asks only what the clone emitter cannot
// answer for itself. `scanBody` runs before any clone exists and is MASK-BLIND:
// one body verdict serves every call site, so it cannot know whether a select's
// condition or arms are quantum at a given site. `lowerCloneSelect`
// (Specialization.cpp) can, and it already disposes of every select by taint:
//   * all classical → left as a classical select;
//   * classical condition over a quantum arm → since bd p3kd.7.2 a classical
//     choice of rail (CloneRailSelect.h; spec_accept_clone_classical_cond.ll);
//   * quantum condition → the controlled-copy data-mux over any mix of quantum
//     arms (threaded as handles) and classical arms (materialized by
//     `materializeCopySource`), or, for a condition off the `collectCondTree`
//     grammar or a width with no controlled copy, left in place for the loud
//     "no tainted select survives" backstop in `buildClone`.
// So detection refuses only what no taint assignment can make lowerable, and
// admits everything else. It used to admit two hand-picked shapes
// (`isLiftableSelect`: an i32 select with a const-zero false arm or two derived
// arms; `isLiftableFpSelect`: an f32/f64/f80 select with derived or ConstantFP
// arms), which declined shapes the emitter lowers: two integer constant arms
// (exp/expf/tgammal, `select i1 %c, i32 C1, i32 C2`), a non-zero constant arm, a
// derived arm next to a constant one, and any i1/i8/i16/i64 select.
//
// What stays refused, each a property of the select alone:
//   * a vector select: a lane has no scalar controlled copy, and no ABI width
//     names a vector type, so the width clause below refuses it (a separate
//     vector test was a redundant clause: its mutant survived,
//     spec_reject_select_vector.ll);
//   * a width with no ABI name (pointer, fp128, i256 and up), and an fp width
//     outside {f32, f64, f80}: f16 has the runtime symbols but no tested clone
//     coverage (spec_reject_fp_select_f16.ll);
//   * an arm that is a constant other than a `ConstantInt`/`ConstantFP` (undef,
//     poison, a ConstantExpr): it has no basis value to materialize, and a twin
//     re-reading an undef would see a different one (bd xy9n)
//     (spec_reject_fp_select_undef_arm.ll, spec_reject_fp_select_poison_arm.ll,
//     spec_reject_select_int_undef_arm.ll).
// The condition's compare is a body instruction of its own, so the data-op
// whitelist below already refuses an out-of-scope predicate or compare width.
//
// ANGLE SAFETY (kmdc, re-verified for the widening): a clone body is
// rotation-free (`scanBody` refuses every `cq_theta`/`cq_phi` as
// `QuantumPrimitive`, and `buildClone` lowers no rotation), so no select value,
// integer or fp, can reach a rotation-angle slot inside the clone. A quantum fp
// return leaves the clone as an i32 handle (`cqrt_copy_f<W>`), so a caller that
// steers it into an angle meets the top-level `declineTaintedAngle`
// (spec_reject_fp_return_used_as_angle.ll).
bool isAdmissibleCloneSelect(const SelectInst &SI) {
  Type *Ty = SI.getType();
  const StringRef W = abiWidthFromType(Ty);
  if (W.empty())
    return false;
  if (Ty->isFloatingPointTy() && W != "f32" && W != "f64" && W != "f80")
    return false;
  auto armAdmissible = [](const Value *A) {
    return !isa<Constant>(A) || isa<ConstantInt>(A) || isa<ConstantFP>(A);
  };
  return armAdmissible(SI.getTrueValue()) && armAdmissible(SI.getFalseValue());
}

// bd 3p2a — DOES THE CALLEE'S RETURNED VALUE DERIVE FROM A LITERAL
// `undef`/`poison`? A backward walk over `RV`'s cone inside ONE function body,
// terminated by a visited set (so a loop-carried `phi` cannot diverge; the body
// is not proven acyclic here — `lowerCloneControl`'s post-flatten backstop owns
// that).
//
// ─── WHAT THE HOLE IS, AND WHAT IT IS NOT ───────────────────────────────────
//
// `scanBody` certifies "this callee computes a reversible classical FUNCTION of
// its arguments". That certificate is what licenses cloning the body, CACHING the
// clone per `(callee, mask)`, DUPLICATING it verbatim into an uncompute twin, and
// reversing it with an adjoint whose entire correctness argument is "the adjoint
// reads the same operands the forward read". A body that returns `poison` earns
// that certificate VACUOUSLY: the scan whitelists instruction OPCODES and
// `continue`s past every terminator, so `define i32 @leaf(i32 %a) { ret i32
// poison }` passes without a single check touching the returned value.
//
// *** BE HONEST ABOUT THE MEASURED HARM — the ticket's version is FALSE and a
// reviewer falsifies it in one run. *** bd 3p2a says the clone's poison return
// "is used as an i32 QUBIT HANDLE". It is not, and it structurally cannot be:
// `buildClone` sets `ReturnTainted = cloneTaint.Tainted.count(RV)` and a
// `Constant` is never in a taint set, so a literal-poison return is ALWAYS
// classified classical and lands in a template's LITERAL slot, never a handle
// slot. Measured end-to-end on the shipped plugin at the `-O0` stage 3, the whole
// trace of the exhibit is
//
//     cqrt_alloc_i32(3) -> h0
//     cqrt_ry_i32(h0, 0x1p-1)
//     cq_template_add_i32_hl(h0, 0)      ; h0 is a REAL rail; 0 is the poison
//
// — `h0` came from `cqrt_alloc_i32`, and the poison is the classical addend. So
// there is no gate on a phantom rail, and (checked) no forward/adjoint pairing
// break either: an adjoint copies the forward's OPERANDS, so both read the one
// SSA register and see one value.
//
// REACH IS PROVEN, though, and cheaply: `int leaf(int a) { int x; return x; }`
// gives `ret i32 undef` under stock `clang -O1`. It is unreachable single-TU
// (IPSCCP folds the call away), but CQ ships `run_slice_multi.sh` (per-TU `-O1` →
// `llvm-link` → one `cq-lowering`), and there the clone IS minted — measured:
// `opt` exit 0, `@__cq_q_leaf_1` emitted with a `ret i32 undef` body.
//
// SO WHY FENCE IT. Because the ONE mechanism in this pass that turns a shared
// register into two INDEPENDENT materialisations — `synthUncomputeTwin`'s
// verbatim `CloneFunctionInto` — is the measured bd xy9n miscompile, and the only
// thing standing between this accept and it is `findUndefOperandInBody`'s
// transitive walk at the duplication site (measured ON THE PRE-CHANGE PLUGIN: a
// three-level probe whose poison-returning leaf is reached through a twinned
// middle clone declined there). That is a fence at a DIFFERENT site, keyed on a
// DIFFERENT property, and it is one widening away from not covering this — e.g.
// any future change that lets a poison-derived value be `ReturnTainted` turns the
// literal slot above into a real rail. Certifying "computes a function of its
// arguments" for a body that computes nothing at all is exactly the unproven
// accept surface the Prime Directive says should not exist, and the input is UB,
// so declining it costs no capability.
//
// *** AND THAT FENCE HAS A HOLE OF ITS OWN, WHICH THIS ONE DOES NOT CLOSE — say
// so rather than leaning on it. *** `ensureTwin` is called from EXACTLY ONE site
// (`Specialization.cpp`, inside `buildClone`'s inner-call drain, gated on
// `Rec.ReturnTainted`), while `EmitInverse` mints an `@__cq_q_<f>_<mask>_unc`
// CALL for ANY `__cq_q_`-prefixed forward — including a TOP-LEVEL clone call the
// whole-DAG spine reverses. On that path no twin is synthesized and NO
// literal-integrity fence runs at all. Measured (Rule-13 round, IR-only reach):
// `opt` exit 0 and `free_pairing_check.py` clean on a module referencing an
// UNDEFINED `@__cq_q_leaf_1_unc` — only the stage-3 LINK catches it — and, if the
// input DEFINES that symbol, it is used verbatim with zero validation. Filed as
// its own ticket; do not cite "no twin is synthesized at the top level" as a
// safety property, because nothing in the pass enforces it.
//
// ─── WHY THE RETURN CONE, AND WHAT IT DOES TO THE TWIN FENCE ────────────────
//
// The scope is the RETURN CONE: a backward walk from the returned value, not the
// whole body. That is not a hedge — a body-wide scan would additionally refuse
// undef in DEAD and SCRATCH positions, which is measurably harmless (below) and
// would make this a pure over-decline widening on top of a real fix.
//
// *** AND SAY THE UNCOMFORTABLE PART PLAINLY, BECAUSE THE FIRST DRAFT OF THIS
// COMMENT GOT IT WRONG AND THE FIXTURES CAUGHT IT. *** That draft asserted the
// return-cone scope leaves `Specialization::ensureTwin`'s `findUndefOperandInBody`
// fence (bd xy9n) untouched. FALSE, measured: all three of that fence's fixtures
// (spec_reject_twin_undef_dup{,_pretwin,_transitive}.ll) are built on
// `%c = xor i32 undef, 7` feeding `%y = mul i32 %a, %c` and then `ret i32 %y` —
// the undef IS in the return cone, so this fence now declines all three EARLIER,
// at detection.
//
// That is not an accident of those probes; it is EXACT SUBSUMPTION of the twin
// fence's HARMFUL cell, and the argument is short. The twin's job is to zero the
// clone's out rail, which it does by RE-EXECUTING the body and un-copying the
// recomputed result: `cqrt_copy_i32(<recomputed ResultRail>, out)`. `ResultRail`
// IS the clone's returned value. So the twin's un-copy fails — leaving `out`
// dirty for the `cqrt_free` that follows, the Rule-6/8 hidden measurement — iff
// the recomputed RETURN differs between the two bodies, iff the return derives
// from `undef`. Every other divergence is self-cancelling: a SCRATCH gate's
// forward and adjoint read the SAME materialisation, so each copy restores its own
// rail.
//
// *** THAT SENTENCE USED TO READ "sit in the SAME body", AND THE RULE-13 ROUND
// MEASURED IT FALSE FOR THE ONE CASE THAT MATTERS. *** A `ReturnTainted` INNER
// clone call goes into `TaintedCloneCalls`, and the wrap reverses it via
// `@__cq_q_inner_<mask>_unc` — a SEPARATE body, produced by the very
// `CloneFunctionInto` this argument is about — so forward and adjoint demonstrably
// do NOT share a body there. The CONCLUSION is unaffected and the correct reason is
// one clause further along: that pair's operands are materialised ONCE in the
// CALLER's body and passed to both calls (measured — `mul_i32_hl(h0, 73903)` on
// both sides, out rail zeroed, stage 2b `4 verified, 0 violation(s)`), so its only
// remaining divergence channel is the INNER clone's own RETURN, which THIS fence
// adjudicates recursively one `scanBody` frame down. Do not restore the "same
// body" wording: it is the load-bearing premise for any future decision about the
// twin fence, and it named the wrong mechanism.
//
// MEASURED on the isolated shape (the undef feeds a scratch `mul`, the return is
// clean) with this fence armed off — the trace does show two different multipliers,
// `mul_i32_hl(h0, 73903)` in the clone and `mul_i32_hl(h0, 7)` in the twin, and the
// out rail is still correctly zeroed because the twin un-copies via the recomputed
// `add(h0,1)`, which never reads the undef-derived operand. (That last step is READ
// OFF the trace, not observed: the runtime is trace-only and no gate reports whether
// a rail is `|0⟩`.) That is spec_reject_twin_undef_dup_scratch.ll, kept precisely so
// the twin fence retains a reaching fixture (Rule 12) — and labelled there as the
// OVER-DECLINE it is.
//
// The twin fence STAYS. Deleting it now would be an accept WIDENING inside a
// tightening commit, which is the one thing bd ajw7 exists to remember; and its
// over-decline is free. Tracked for deliberate re-scoping, never a silent drop.
//
// The division of labour after this change, with every cell owned:
//   * a literal in an emitted GATE SLOT      → `declineUnpairedUndefLiterals`
//                                              (bd xy9n guard 1, counts ≥2 slots)
//   * a literal reaching the RETURNED VALUE → HERE — the twin's un-copy channel,
//                                              declined before a clone is minted
//   * a literal in a DEAD or SCRATCH body
//     position, duplicated into the twin    → `findUndefOperandInBody`, retained
//                                              as defence in depth (over-decline)
//
// `spec_accept_undef_outside_return_cone.ll` pins the scope from the accept side:
// a dead undef outside the return cone still lowers at the TOP level, where no
// twin is synthesized at all.
//
// The walk stops at any non-`Instruction` (an `Argument` or a `Constant`, tested
// by `slotCarriesUndef` on the way in) and descends through every operand of an
// `Instruction`, INCLUDING a call's arguments. It never enters a callee's BODY —
// a `Function` is not an `Instruction` — and it does not need to: `scanBody`
// recurses into every nested visible callee in its own frame, so that callee's
// return cone is adjudicated there (verified by
// spec_reject_ret_poison_nested.ll).
//
// *** THE EFFECTIVE SCOPE IS THEREFORE WIDER THAN "THE RETURN CONE", and the
// Rule-13 round measured the difference. *** "Return cone" is exact WITHIN one
// function; across the transitive recursion it means "the return cone of the
// candidate OR of any visible callee it reaches". So a nested callee whose result
// is DEAD and whose arguments are ALL CLASSICAL — a shape `buildClone`'s inner
// drain skips with `continue`, leaving it a plain classical subcall copied
// verbatim into the clone — now kills the whole outer specialization. Measured:
// pre-change `opt` exit 0 with the dead subcall harmlessly present, post-change a
// loud `UndefReturn` naming the nested callee. That is a genuine ACCEPT LOSS on
// top of the fix, it is a pure over-decline (loud, never silent, but a gap to
// remove per R1, not a safe margin), and it is not carved out yet — a carve-out
// would need its own proof that the dead subcall is really dead in BOTH the
// clone and any twin, which is exactly the kind of unproven accept surface this
// fence exists to remove.
//
// The predicate is `slotCarriesUndef`, the GlobalValue-address-skipping one: a
// global's operands are its INITIALIZER while the value in the slot is its
// ADDRESS, and `clang -O1` really emits a partially-`undef` initializer for the
// fp80-union idiom this project is built on. Do NOT swap in `valueCarriesUndef`
// — its one caller is the PredMux cone predicate, where the over-decline is
// PRE-EXISTING and removing it would be an accept WIDENING (bd ajw7).
bool returnDerivesFromUndef(const Value *RV) {
  SmallPtrSet<const Value *, 16> Seen;
  SmallVector<const Value *, 16> WL;
  WL.push_back(RV);
  while (!WL.empty()) {
    const Value *V = WL.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (slotCarriesUndef(V))
      return true;
    const auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // Argument / Constant / global — a leaf, already tested above.
    for (const Value *Op : I->operands())
      WL.push_back(Op);
  }
  return false;
}

// The Callee-only body-shape verdict (arity cap, straight-line value shape, no
// `cq_*`/measure/non-reversibilizable construct, integer-i32 return), recursing
// through nested calls (Phase 6.3 transitive). `OnStack` is the DFS recursion
// stack of callees currently being scanned; a nested call whose target is on the
// stack (self OR mutual) is a call-graph cycle → `Recursion` (the convergence
// argument requires the accepted subset to be acyclic, §2.8). A nested call to a
// VISIBLE classical body recurses (it will be transitively specialized); a nested
// call with no static body (indirect / declaration-only / inline-asm) is an
// unproven shape → reject. The per-Site argument-ABI (tainted args are i32) is
// NOT checked here — it needs the call's real taint mask and is verified by
// `classifyCandidate` for every concrete `(Site, mask)` (the top at detection,
// each inner at specialize-time).
SpecReject scanBody(Function *Callee, const IntrinsicSets &Sets,
                    WidthDispatch &wd, SmallPtrSetImpl<const Function *> &OnStack,
                    Instruction *&WhereOut, std::string &KindOut) {
  // (0-pre) A body this pass may lift (bd gxhi; bd p3kd.2 — CalleeBody.h).
  //      Specialization ANALYZES this body and CLONES it into a Bennett twin the
  //      tainted path calls IN PLACE OF the callee. If the linker may bind a
  //      NON-EQUIVALENT body (an INTERPOSABLE definition: weak/linkonce/common/
  //      extern_weak, or a non-dso_local one under SemanticInterposition), the
  //      cloned unitary diverges from the program with NO diagnostic: decline.
  //      Which question depends on the DEPTH (bd p3kd.2):
  //        * the TOP callee of the candidate (`OnStack` empty: `classifyCandidate`
  //          calls in with a fresh stack, and every recursion below inserts the
  //          caller first) asks `Execute`. Its call is retargeted to the clone, so
  //          the analyzed body IS the body that runs there, and a `weak_odr`/
  //          `linkonce_odr`/`available_externally` body (a derefinable but not
  //          interposable one) is lifted like an exact one: LLVM's inlining rule.
  //        * a NESTED callee asks `AssumeOfLinkedCall` (an exact definition). A
  //          nested call the clone does not taint (mask 0 at `buildClone`'s inner
  //          loop) stays a call to the LINKED body, and `synthUncomputeTwin`
  //          copies the clone verbatim, so that body runs twice and the twin's
  //          `_unc` reads its second result as the literal the forward read from
  //          its first. A derefined ODR variant need not return the same value
  //          twice (spec_reject_nested_odr_callee.ll). Conservative for a nested
  //          ODR callee that WOULD be cloned: telling the two apart needs the
  //          inner mask, which only `buildClone` has (a follow-up).
  //      A top candidate is a definition by contract, and a nested declaration is
  //      declined as "nested call" BEFORE recursing here, so this fires only on a
  //      real BODY. Placed first: an untrusted body must not be scanned as if its
  //      instructions were the ones that run.
  const CalleeBodyUse Use = OnStack.empty() ? CalleeBodyUse::Execute
                                            : CalleeBodyUse::AssumeOfLinkedCall;
  if (!calleeBodyTrusted(Callee, Use)) {
    WhereOut = &*Callee->getEntryBlock().begin();
    return SpecReject::Interposable;
  }

  // (0a) Varargs: `taintArgMask` reads the call site's `arg_size()` (incl. the
  //      vararg tail) while seeding iterates the callee's FIXED params only — a
  //      tainted vararg-tail arg would set a mask bit that is never seeded
  //      (silent under-taint). Unreachable in 6.1/6.2 (a vararg site never became
  //      a candidate), but the transitive worklist broadens the set, so decline
  //      loudly now ([[6-3-drain-ordering-varargs-recheck]]).
  if (Callee->isVarArg()) {
    WhereOut = Callee->getEntryBlock().getTerminator();
    KindOut = "varargs";
    return SpecReject::NonReversibilizable;
  }

  // (0) Arity cap (DD-5): a 65th parameter truncates the 64-bit mask and silently
  //     aliases two distinct signatures. Applies to every specialized body — a
  //     nested callee included.
  if (Callee->arg_size() > kSpecMaxArity) {
    WhereOut = &*Callee->getEntryBlock().begin();
    return SpecReject::ArityOverflow;
  }

  // (0c) Exception handling (PRD §2.11). An `invoke` / landing-pad / funclet body
  //      unwinds via a non-value control edge spanning multiple blocks; detected
  //      BEFORE the single-block gate below so the diagnostic names "exception
  //      handling" rather than the generic "tainted control flow".
  if (Instruction *EH = firstEHConstruct(*Callee)) {
    WhereOut = EH;
    KindOut = "exception handling";
    return SpecReject::NonReversibilizable;
  }

  // (1) Body shape: a SINGLE straight-line value block, OR (5po2 I1) a multi-block
  //     acyclic tainted VALUE region that the clone's scoped PredMux flatten
  //     (`lowerCloneControl`) collapses to straight-line. The whitelist walk below
  //     covers EVERY block, so a non-value construct in ANY arm still declines;
  //     `br` (diamond edge), `switch` (N-way edge, bd p3kd.7.1), `unreachable`
  //     (a dead sink, bd p3kd.7.1) and `phi` (merge mux) are accepted as
  //     flattenable control, and `indirectbr`/`callbr` decline in the walk
  //     (`invoke` declines at (0c)). A shape PredMux cannot claim (multi-exit —
  //     the I2 controlled-return shape; a loop; a compound region; a classical
  //     region holding an op that cannot run speculatively, bd p3kd.7.2) is
  //     caught by the
  //     `lowerCloneControl` post-flatten "still multi-block → decline" backstop
  //     and, for a surviving unlowered mux, the "no tainted select survives" guard
  //     in `buildClone` — detection stays permissive here (a shape it lets
  //     through declines loudly later, never silently), and the emission proves
  //     the flatten by construction. Detection is mask-blind, so it must not
  //     refuse a terminator the emitter lowers under SOME mask: a switch is
  //     lowered whether its scrutinee is quantum (a controlled-copy mux) or
  //     classical (a choice of rail, bd p3kd.7.2) (spec_accept_clone_switch.ll,
  //     spec_accept_clone_switch_classical_scrutinee.ll).

  // (2) ABI return: a (possibly-tainted) return must have a reversible copy-out
  //     to an i32 handle. Two admitted families (bd 3c6m.54):
  //       * integer i32 (`wd.copyFn("i32")` — `cqrt_copy_i32`); and
  //       * an fp width with an uncontrolled `cqrt_copy_f<W>`
  //         (`abiWidthHasReversibleFpCopy` = {f16,f32,f64,f80}). A tainted fp
  //         return copies out to an i32 handle in `emitBennettWrap` (clone-return
  //         rewritten to i32); a classical fp return stays fp and is returned
  //         verbatim (`predictReturnTainted` decides the signature — see
  //         `cloneFor`). The escaping fp return is thus ALWAYS an i32 handle, so
  //         the top-level `declineTaintedAngle` fence backstops any caller-angle
  //         misuse (the f64-angle family; 3c6m.54 PRD §ANGLE-SAFETY).
  //     Still declines FpAbi: fp128 / vector / half-of-nothing → empty or
  //     non-reversible `abiWidthFromType`; non-i32 int (i16/i64/i128) → no
  //     reversible i32-handle copy-out in the shipped scope. `void` is a classical
  //     no-output — exempt.
  Type *RetTy = Callee->getReturnType();
  if (!RetTy->isVoidTy()) {
    StringRef RetW = abiWidthFromType(RetTy);
    const bool IntI32 = RetW == "i32" && wd.copyFn(RetW);
    const bool RevFp = abiWidthHasReversibleFpCopy(RetW);
    if (!IntI32 && !RevFp) {
      WhereOut = Callee->getEntryBlock().getTerminator();
      return SpecReject::FpAbi;
    }
  }

  // (3) WHITELIST body scan over the single basic block (guaranteed by (1)). The
  //     `OnStack` insert/erase brackets this callee's frame so a deeper recursion
  //     sees it (cycle detection); `Inserted` guards the (impossible here, but
  //     defensive) re-entry of an already-stacked callee.
  bool Inserted = OnStack.insert(Callee).second;
  auto pop = [&]() {
    if (Inserted)
      OnStack.erase(Callee);
  };
  for (BasicBlock &BB : *Callee)
  for (Instruction &I : BB) {
    // Terminators: a plain `ret` (the whitelist proves the returned value
    // reversible), a `br` (5po2 I1's diamond edge), a `switch` (bd p3kd.7.1: the
    // N-way edge PredMux flattens with one `icmp eq` flag per case, exactly as at
    // the top level) or an `unreachable` (bd p3kd.7.1: the dead sink PredMux
    // tolerates inside a region since bd 20xt.5 (d); outside one it keeps the
    // clone multi-block and the backstop declines; a body with no `ret` at all
    // declines at the wrap, `kMsgCloneNoReturn`, spec_reject_clone_no_return.ll).
    // An `indirectbr`/`callbr` → InBodyControl (a loud over-decline to remove, R1).
    if (I.isTerminator()) {
      if (!isa<ReturnInst>(I) && !isa<BranchInst>(I) && !isa<SwitchInst>(I) &&
          !isa<UnreachableInst>(I)) {
        WhereOut = &I;
        pop();
        return SpecReject::InBodyControl;
      }
      // bd 3p2a — the ONE check this whitelist ever makes on a terminator, and
      // the reason the scan is no longer VACUOUS on `ret i32 poison`. See
      // `returnDerivesFromUndef` above for the full argument (incl. why the
      // ticket's "used as a qubit handle" harm is measurably false, and why the
      // walk is scoped to the return cone rather than the body).
      if (const auto *R = dyn_cast<ReturnInst>(&I))
        if (const Value *RV = R->getReturnValue())
          if (returnDerivesFromUndef(RV)) {
            WhereOut = &I;
            pop();
            return SpecReject::UndefReturn;
          }
      continue;
    }
    // Calls: a quantum primitive (rejects), a recursion/cycle, inline asm, or a
    // nested classical call (Phase 6.3 — recurse into its body).
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (CB->isInlineAsm()) {
        WhereOut = &I;
        KindOut = "inline assembly";
        pop();
        return SpecReject::NonReversibilizable;
      }
      if (auto *CI = dyn_cast<CallInst>(CB)) {
        if (Sets.Rotations.count(CI)) {
          WhereOut = &I;
          pop();
          return SpecReject::QuantumPrimitive;
        }
        if (Sets.Measures.count(CI)) {
          WhereOut = &I;
          pop();
          return SpecReject::Measurement;
        }
        // Curated reversible llvm.* idiom intrinsic (Phase 7.1-E): a pure total
        // function lowered to a FROZEN `cq_template_<op>_<W>` additive producer
        // with an `_unc` twin (`bswap`/`bitreverse`/`fshl`-`fshr` rotation/
        // `ctpop`/`ctlz`/`cttz`/`abs`/`smin`/`smax`/`umin`/`umax`/`*.sat`). An
        // intrinsic call is a `CallInst` to an llvm INTRINSIC DECLARATION, so
        // without this it falls through to the declaration-only "nested call"
        // decline below (the loud over-decline this follow-up lifts). Inside a
        // specialized clone it is a reversibilizable data op exactly like the
        // `BinaryOperator`/`CastInst` whitelist further down: `seedClone`'s
        // transitive-user closure taints it, `lowerOps` (taint-gated) lowers it
        // via `rewriteIntrinsic` to the producer, the Bennett wrap captures that
        // producer in its forward stream, copies out only the i32 clone result,
        // and `emitInverseChain` reverses it through the generic `cq_template_`
        // `_unc` branch (EmitInverse.cpp:128) — clone-internal source liveness is
        // held because every scratch rail is freed only AFTER the complete
        // reverse (`emitBennettWrap` step e), so a Class-2 `_unc`'s recompute
        // reads still-live sources. ZERO new lowering/uncompute code; adds NO
        // frozen symbol (the templates are frozen by 7.1-E regardless).
        // Membership is EXACT `Intrinsic::ID` + table width + rotation-form,
        // NEVER a `starts_with("llvm.")` (the cq_theta_evil hazard, C7) —
        // symmetric with `declineTaintEscapes`' top-level acceptance
        // (TaintPropagation.cpp:530). A non-curated id, a non-table width
        // (`bswap.i8`, `abs.i128`), or a dynamic/general funnel shift fails the
        // predicate and rides the loud "nested call" decline below. A curated
        // intrinsic's result width is in-table (i8/i16/i32/i64) by the predicate,
        // and for every curated shape its tainted operands share that result
        // width, so the data-op width gate below is already satisfied — accept it
        // as a data op (`continue`, advancing the body scan, NOT a `pop()+return`
        // — this frame stays on `OnStack` for the rest of the callee).
        // [[7-1-E-intrinsics-frozen-clearance]]
        if (isCuratedReversibleIntrinsic(CI))
          continue;
        // p119: a DIRECT-libm call (cbrt/atan2/ilogb/ldexp/hypot/…) in a clone body
        // is a LIBRARY function (removed from recognition). It is a declaration-only
        // libc extern with no body, so it falls through to the loud declaration-only
        // "nested call" decline below — the correct outcome under Rule 18: a library
        // function must be SOURCE-INJECTED to lower, never recognized by name.
        // setjmp/longjmp: a `returns_twice` callee can re-enter the body
        // mid-stream, breaking the single-entry straight-line assumption the
        // Bennett reverse needs. Keyed on the ATTRIBUTE clang stamps on
        // setjmp/sigsetjmp (its longjmp twin is `noreturn`), NOT the name —
        // Rule 11/C7.
        if (CI->hasFnAttr(Attribute::ReturnsTwice)) {
          WhereOut = &I;
          KindOut = "setjmp/longjmp";
          pop();
          return SpecReject::NonReversibilizable;
        }
        // bd nlfd/ev3m round 2 (Rule-13 r1B F-r1B-2): a `musttail` call that
        // forwards a `preallocated` argument. The clone of this body DEMOTES every
        // `musttail` (`stripStaleClassicalAttrs`, bd m5pn — its Bennett wrap emits code
        // after an inner clone call), and a `preallocated` operand is legal only on a
        // `musttail` call or on one carrying the `"preallocated"` bundle — which a
        // forwarded argument has no token for: the verifier then ABORTED the run
        // (exit 134; the ORACLE aborted too, on the old `musttail … must precede a
        // ret` rule). There is no plain-`tail` spelling to be identical to (the same
        // call without `musttail` is invalid input IR), so this is a decline of a
        // shape with no valid alternative spelling, loud instead of an abort. AND
        // `inalloca` (owner ruling 2026-10-05, bd dm7f.5 review round 2, superseding
        // the owner's 2026-09-29 invariant for `inalloca`): LangRef — a `musttail`
        // call forwards an `inalloca` argument in place, and on any other call the
        // operand must be the `alloca` set up for that call; the demoted forward was
        // verifier-clean (the verifier checks provenance only when the operand is an
        // `alloca`) and byte-identical to its plain-`tail` spelling, and both are
        // invalid. Both cases are asked through the ONE shared predicate,
        // `mustTailForwardBlocksDemotion` (ReturnMerge.h), which the module-level
        // `ret` merge asks too. IR-only: clang emits both attributes only for the
        // 32-bit Windows C++ ABI.
        if (StringRef Why = mustTailForwardBlocksDemotion(CI); !Why.empty()) {
          WhereOut = &I;
          KindOut = Why.str();
          pop();
          return SpecReject::NonReversibilizable;
        }
        Function *Inner = CI->getCalledFunction();
        // syscall: a direct call to the libc `syscall` trap is an irreversible
        // kernel side effect. The ONE exact-name match in the classifier — an
        // external libc SYMBOL we lower nothing for, never a taint-identity
        // decision (the no-name-prefix discipline of C7 governs `cq_*` intrinsic
        // identification, a different axis).
        if (Inner && Inner->getName() == "syscall") {
          WhereOut = &I;
          KindOut = "syscall";
          pop();
          return SpecReject::NonReversibilizable;
        }
        // Call-graph cycle (self OR mutual): the convergence argument needs the
        // accepted subset acyclic, so a recursive callee has no static depth
        // bound and is declined loudly (§2.8, §2.11).
        if (Inner && OnStack.count(Inner)) {
          WhereOut = &I;
          pop();
          return SpecReject::Recursion;
        }
        // A nested call to a VISIBLE classical body recurses — it is the
        // transitive-specialization candidate (6.3). Its argument-ABI is checked
        // at specialize-time with the inner's real mask.
        if (Inner && !Inner->isDeclaration()) {
          SpecReject R = scanBody(Inner, Sets, wd, OnStack, WhereOut, KindOut);
          if (R != SpecReject::Accept) {
            pop();
            return R;
          }
          continue;  // nested specializable call — OK.
        }
        // Indirect (null callee) or declaration-only (no IR) nested call — an
        // unproven shape with no body to reversibilize (DD-2).
        WhereOut = &I;
        KindOut = "nested call";
        pop();
        return SpecReject::NonReversibilizable;
      }
      // A non-`CallInst` CallBase reached as a non-terminator (defensive — an
      // invoke/callbr is a terminator caught above): an unproven shape.
      WhereOut = &I;
      KindOut = "nested call";
      pop();
      return SpecReject::NonReversibilizable;
    }
    // Memory / synchronization — never pure, no reversible copy.
    if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I)) {
      WhereOut = &I;
      KindOut = "atomic";
      pop();
      return SpecReject::NonReversibilizable;
    }
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      // bd 20xt.4: a const-global tainted-index QROM read (`tbl[id]`) is a
      // reversibilizable data producer inside a clone — the clone's flatten
      // masks a NeedsMask index, `lowerQramReads` (under `cloneTaint`) lowers it
      // to `cqrt_qram_alloc/load_<W>`, and the Bennett wrap captures+reverses the
      // load (its `_unc` un-copies the dead value rail). Admit the SHAPE here
      // (taint-blind, the SAME `matchQramAccess` structure the emitter re-proves —
      // Rule 14); its address gep is admitted symmetrically in the catch-all
      // below. Everything off this shape (a store, a non-const/non-array global, a
      // punned or unsupported-width cell) keeps the loud memory-access decline.
      if (qromReadShapeInScope(LI))
        continue;
      WhereOut = &I;
      KindOut = LI->isVolatile() ? "volatile" : "memory access";
      pop();
      return SpecReject::NonReversibilizable;
    }
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      WhereOut = &I;
      KindOut = SI->isVolatile() ? "volatile" : "memory access";
      pop();
      return SpecReject::NonReversibilizable;
    }
    // Control muxes. A PHI join is a diamond merge (5po2 I1) — the clone's PredMux
    // flatten dissolves it into a `select` the two-arm `lowerCloneSelect` lowers.
    // Its incomings are proven by the per-block whitelist (they are body ops in
    // the arms). Accept it as a flattenable construct, but keep the width/vector
    // fence (a phi is not a BinaryOperator/Cast, so it skips the width gates
    // below): an i128/half/fp128/vector merge has no reversible copy and would
    // survive the flatten as an unlowerable select → reject at the phi, precise.
    if (auto *PH = dyn_cast<PHINode>(&I)) {
      if (touchesVector(I) || unsupportedWidth(PH->getType())) {
        WhereOut = &I;
        KindOut = touchesVector(I) ? "vector SIMD" : "unsupported width";
        pop();
        return SpecReject::NonReversibilizable;
      }
      continue;
    }
    // A SELECT is a straight-line mux, disposed of by taint in the clone
    // (`lowerCloneSelect`); detection refuses only the shapes no mask can lower
    // (`isAdmissibleCloneSelect`, bd p3kd.7.1).
    if (auto *SI = dyn_cast<SelectInst>(&I)) {
      if (isAdmissibleCloneSelect(*SI))
        continue;
      WhereOut = &I;
      pop();
      return SpecReject::InBodyControl;
    }
    // The reversibilizable data-op whitelist. A vector lane has no scalar copy.
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<CmpInst>(I) ||
        isa<CastInst>(I)) {
      if (touchesVector(I)) {
        WhereOut = &I;
        KindOut = "vector SIMD";
        pop();
        return SpecReject::NonReversibilizable;
      }
      // Pointer / bit-reinterpret casts (`bitcast`/`ptrtoint`/`inttoptr`/
      // `addrspacecast`) cross the pointer domain or reinterpret bits and have
      // no reversible template — reject precisely at the cast (the WI-1.13
      // over-accept finding; previously slipped into the clone and was caught
      // only LATE at lowerOps, naming the clone not the source op).
      if (auto *CA = dyn_cast<CastInst>(&I)) {
        switch (CA->getOpcode()) {
        case Instruction::BitCast:
          // bd vqlq: a VALUE bitcast between non-pointer scalars falls THROUGH
          // to the width + castInScope gates below (Rule 14: detection must
          // MIRROR the lowerOps accept — castInScope admits exactly the eight
          // shipped same-width fp<->int relabels incl. f80<->i80, the promoted
          // fp80-union extraction form; every other value bitcast still
          // declines there, source-located). Only a pointer-typed side keeps
          // the categorical reject with its precise "pointer cast" kind.
          if (!CA->getSrcTy()->isPointerTy() && !CA->getDestTy()->isPointerTy())
            break;
          [[fallthrough]];
        case Instruction::PtrToInt:
        case Instruction::IntToPtr:
        case Instruction::AddrSpaceCast:
          WhereOut = &I;
          KindOut = "pointer cast";
          pop();
          return SpecReject::NonReversibilizable;
        default:
          break;
        }
      }
      // Intermediate-width scope (the WI-1.13 over-accept finding): a result or
      // operand at a width with no reversible template (i128/half/fp80/fp128/
      // pointer) is over-accepted into the clone today and only backstopped LATE
      // at lowerOps (naming the CLONE, not source-located). Reject it HERE, at the
      // offending body op, with its precise `!dbg`. Taint-agnostic: detection has
      // no clone taint yet, so a classical wide op declines too: loud, never
      // silent, but an over-decline to remove (R1), not a safe margin.
      if (unsupportedWidth(I.getType())) {
        WhereOut = &I;
        KindOut = "unsupported width";
        pop();
        return SpecReject::NonReversibilizable;
      }
      for (const Value *Op : I.operands())
        if (unsupportedWidth(Op->getType())) {
          WhereOut = &I;
          KindOut = "unsupported width";
          pop();
          return SpecReject::NonReversibilizable;
        }
      // Predicate / cast-direction scope — the SAME over-accept class as the
      // width gate, completed (Rule 14: detection-time accept must MIRROR the
      // lowerOps accept predicate). An out-of-scope `fcmp` predicate (after
      // 8rvn, only the degenerate `true`/`false`) or an out-of-scope arithmetic cast
      // (e.g. signed `sitofp` from `i1`) has no template; without these it slips
      // into the clone and only backstops LATE at lowerOps' `diagnoseNoTemplate`
      // (naming the CLONE, not source-located). The width-empty / pointer-cast
      // shapes already returned above, so the operands here carry valid ABI
      // widths and these calls read the true (pre-RAUW) types.
      if (auto *Cmp = dyn_cast<CmpInst>(&I)) {
        if (!compareInScope(Cmp->getOpcodeName(),
                            CmpInst::getPredicateName(Cmp->getPredicate()))) {
          WhereOut = &I;
          KindOut = "unsupported compare predicate";
          pop();
          return SpecReject::NonReversibilizable;
        }
        // i128 compare fence (n0ui Tier-1): icmp is OUT of the i128 frozen
        // surface. EXACT mirror of CompareLowering's `AbiWidth == "i128"` decline
        // (NOT `widthHasReversibleCopy`, which would also wrongly reject a
        // legitimate `fcmp f32/f64` — fp widths have intBits 0). The compare's
        // data width is its OPERAND width, NOT the i1 result; the unsupportedWidth
        // gate above tests the i1 result (supported) and the i128 OPERAND is now a
        // recognized width (`abiWidthFromType` non-empty), so without this a
        // clone-body `icmp i128` over-accepts and declines LATE at lowerOps naming
        // the CLONE (the WI-1.13 detect-mirrors-lowerOps gap). fcmp f16/f32/f64 and
        // icmp i1..i64 stay accepted; i128 (the only recognized >64 width) declines.
        if (abiWidthFromType(Cmp->getOperand(0)->getType()) == "i128") {
          WhereOut = &I;
          KindOut = "unsupported width";
          pop();
          return SpecReject::NonReversibilizable;
        }
      }
      // i80 binary fence (bd vqlq, the Rule-13 F1 mirror): i80 is a recognized
      // Tier-1 INTERMEDIATE width, but only the four extraction/field-insert
      // rows ship (`i80BinaryInScope`: and/lshr/or/shl — exactly what the
      // promoted-union form emits). Any other i80 binary op (add/sub/mul/xor/
      // ashr/div/rem) has no template; without this it over-accepts into the
      // clone and declines LATE at lowerOps naming the CLONE (the WI-1.13
      // detect-mirrors-lowerOps gap, the exact class of the i128 compare fence
      // above). Made newly reachable by the value-bitcast carve below.
      if (auto *BO = dyn_cast<BinaryOperator>(&I))
        if (abiWidthFromType(BO->getType()) == "i80" &&
            !i80BinaryInScope(BO->getOpcodeName())) {
          WhereOut = &I;
          KindOut = "unsupported width";
          pop();
          return SpecReject::NonReversibilizable;
        }
      if (auto *CA = dyn_cast<CastInst>(&I))
        if (!castInScope(CA->getOpcodeName(), abiWidthFromType(CA->getSrcTy()),
                         abiWidthFromType(CA->getDestTy()))) {
          WhereOut = &I;
          KindOut = "unsupported cast";
          pop();
          return SpecReject::NonReversibilizable;
        }
      continue;  // accepted data op.
    }
    // bd 20xt.4: the address gep of an admitted const-global QROM read (the sole
    // user of a single-use gep is that load). Mirrors the LoadInst admit above and
    // the PredMux region-walk E4-gep case, so detection is consistent across the
    // two spec-clone entry points (Rule 14). Any other gep (a non-QROM-read user,
    // a captured/escaping address) rides the loud decline below.
    if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
      if (GEP->hasOneUse())
        if (auto *LU = dyn_cast<LoadInst>(GEP->user_back()))
          if (LU->getPointerOperand() == GEP && qromReadShapeInScope(LU))
            continue;
    }

    // Anything else (getelementptr, freeze, va_arg, extract/insert, …) is an
    // unproven shape — decline loudly (R1: never guess; each is a gap to
    // close).
    WhereOut = &I;
    KindOut = "unsupported instruction";
    pop();
    return SpecReject::NonReversibilizable;
  }

  pop();
  return SpecReject::Accept;
}

}  // namespace

SpecReject classifyCandidate(const SpecCandidate &Cand, const TaintSet &taint,
                             WidthDispatch &wd, Instruction *&WhereOut,
                             std::string &KindOut) {
  WhereOut = nullptr;
  KindOut.clear();

  // (A) Per-Site argument ABI (Rule 15): the runtime handle is ALWAYS i32, so
  //     every TAINTED argument (mask bit set) must have an i32-handle
  //     representation. Two admitted families (bd 3c6m.54):
  //       * an i32 value (already the handle type); and
  //       * a reversible-fp value {f16,f32,f64,f80} (`abiWidthHasReversibleFpCopy`)
  //         — a tainted `cq_theta_f<W>` result (or fp derivation) that lowers to an
  //         i32 handle by the time `lowerRotations`/`lowerOps` run (specialize is
  //         PRE-rotation, so the fp param slot is rewritten to i32 in `cloneFor`
  //         and the caller's fp arg becomes the handle after the RAUW-to-handle).
  //     Inside the clone the fp arg is only ever a template arg-0 DATA operand —
  //     never a rotation angle (a clone body is rotation-free; `scanBody` rejects
  //     every cq_theta/cq_phi), so the f64-angle family cannot arm here.
  //     A classical pass-through arg (mask bit clear) may be any width. Still
  //     declines FpAbi: a tainted i16/i64/i128 (no reversible i32-handle copy in
  //     the shipped scope) and a tainted fp128/vector. This is the one check that
  //     needs the call's concrete taint mask — verified for the top candidate at
  //     detection and every inner candidate at specialize-time.
  for (unsigned i = 0, n = Cand.Site->arg_size(); i < n; ++i) {
    if (!(Cand.Mask & (SpecMask(1) << i)))
      continue;  // classical pass-through arg — any width is fine.
    Type *ArgTy = Cand.Site->getArgOperand(i)->getType();
    if (!ArgTy->isIntegerTy(32) &&
        !abiWidthHasReversibleFpCopy(abiWidthFromType(ArgTy))) {
      WhereOut = Cand.Site;
      return SpecReject::FpAbi;
    }
  }

  // (B) Callee body shape + transitive closure (arity, straight-line value body,
  //     no `cq_*`/measure/non-reversibilizable construct, i32 return, no
  //     call-graph cycle), recursing through nested calls (6.3). The single
  //     authoritative body verdict (Rule 14).
  IntrinsicSets Sets = buildIntrinsicSets(taint);
  SmallPtrSet<const Function *, 8> OnStack;
  return scanBody(Cand.Callee, Sets, wd, OnStack, WhereOut, KindOut);
}

void diagnoseReject(Instruction *Where, SpecReject Why, StringRef Kind) {
  std::string Msg;
  switch (Why) {
  case SpecReject::Recursion:
    Msg = kMsgRecursion;
    break;
  case SpecReject::FpAbi:
    Msg = kMsgFpAbi;
    break;
  case SpecReject::QuantumPrimitive:
    Msg = kMsgQuantumPrimitive;
    break;
  case SpecReject::Measurement:
    Msg = kMsgMeasurement;
    break;
  case SpecReject::InBodyControl:
    Msg = kMsgInBodyControl;
    break;
  case SpecReject::ArityOverflow:
    Msg = kMsgArityOverflow;
    break;
  case SpecReject::Interposable:
    Msg = kMsgInterposable;
    break;
  case SpecReject::UndefReturn:
    Msg = kMsgUndefReturn;
    break;
  case SpecReject::NonReversibilizable:
    Msg = (Twine(kMsgNonRevizPrefix) + " (" + Kind + ")").str();
    break;
  case SpecReject::Accept:
    return;  // never diagnosed.
  }
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

}  // namespace cq
