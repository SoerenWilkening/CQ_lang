// PredMuxFlatten.cpp — 3c6m.14 (L6): general acyclic tainted control via
// block-predicate MUX flattening ("PredMux"). See PredMuxFlatten.h and the
// PRD (docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/) for
// the design of record; the correctness argument is PRD §6 (per-basis-state
// classical IR equivalence + reduction to the Rule-13-cleared select
// substrate).
//
// The one non-negotiable here is the ACCEPT-ONLY discipline: every check
// below LEAVES the region untouched on failure — the existing detection
// declines it loudly exactly as today. Over-declining stays safe; PredMux can
// only widen the accept surface, never replace a decline with silence.
//
// Eligibility (PRD §4.2, E-ladder) in brief:
//   W  — claim witnesses: only shapes today's detection DECLINES are claimed
//        (nested tainted terminators; multi-phi / >2-incoming br merges; —
//        W5, bd vyqi — the flat sole-2-incoming SCALAR-FP-phi diamond with
//        distinct incomings, which ArmClassify's fp fence categorically
//        declines; and — W7, bd 0rwu — the flat sole-2-incoming INTEGER-phi
//        diamond whose ENTRY-edge incoming is a ConstantInt and whose other
//        incoming is a region-INTERIOR instruction, the fdlibm __isnanl tail).
//        Every OTHER flat sole-2-incoming-phi INTEGER diamond (a non-constant
//        straight-through — the 4.2 routed method-B accepts — and the a8c0
//        empty-arm const-fold re-anchor), a straight-line-arm switch, and the
//        depth-2 homogeneous-phase nest (its arms hold cq_phi CALLS, excluded
//        by E4) all stay with their shipped owners byte-identically.
//   E2 — acyclic: no region block (incl. entry) on any CFG cycle.
//   E3 — single-entry/single-exit: successors ⊆ region ∪ {merge}; merge preds
//        ⊆ region; no side entry; only br/switch terminators inside.
//   E4 — pure speculatable dataflow at TEMPLATE-SUPPORTED widths:
//        arithmetic/bit/compare/cast/select/fneg/freeze/phi + curated
//        memory(none) intrinsics; int division only by a nonzero (and, for
//        signed, non-minus-one) constant. No loads (v1), no stores, no other
//        calls (any @cq_* call therefore excludes the shape). The width gate
//        on INTERMEDIATE ops (not just merges/conditions) is a Rule-13
//        clearance hardening: an fp128 arm op would only decline loudly
//        post-flatten at lowerOps; gating it here keeps the whole ladder
//        detect-before-mutate (a claimed region can never half-lower).
//   E6 — every internal conditional terminator is tainted AND its condition
//        is a supported compare/and/or tree (so the false-edge literal can be
//        built by leaf predicate inversion — the no-NOT invariant).
//   E7 — every phi being converted has a mux-lowerable scalar type.
//
// The flatten (PRD §4.3–4.6): process region blocks in topological order,
// moving instructions before the entry terminator (poison flags dropped —
// speculation discipline; bit-semantics and template selection unaffected,
// Rule 15), converting each phi to a chained select over edge predicates
// EP(e) = BP(src) ∧ lit(e), with BP(b) = ∨ EP(in-edges) materialized lazily.
// undef/poison incomings freeze to the type's zero constant (the incoming is
// dead on every basis state that selects it — clang emits undef precisely
// because the source never reads it on that path). Then the entry terminator
// becomes an unconditional branch to the merge and the arm blocks are erased
// in one coordinated teardown (identities captured up front; one region per
// call, so nothing is ever cached across an erasure — Rule 9 / the
// block-lifetime SIGSEGV family).

#include "PredMuxFlatten.h"

#include "Fp80Union.h"      // foldConstantConesInFunction (adia fold residue)
#include "IntrinsicLowering.h"
#include "PoisonFacts.h"  // curatedIntrinsicCanBePoison (lifted, bd s6ao)
#include "LiteralIntegrity.h"  // valueCarriesUndef (lifted); declineAddressTakenBlocks
#include "OpcodeSupport.h"  // abiWidthFromType, binaryStem, castInScope, i80BinaryInScope
#include "QramLowering.h"
#include "TaintPropagation.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/ScopeExit.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Argument.h"    // bd 615s — the poison-generating param attrs
#include "llvm/IR/Attributes.h"  // bd 615s
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/MathExtras.h"  // isPowerOf2_64 (bd 20xt.7 Provable-pow2 mask)
#include "llvm/Transforms/Utils/Local.h"  // RecursivelyDeleteTriviallyDeadInstructions

using namespace llvm;

namespace cq {

namespace {

// ---------------------------------------------------------------------------
// Eligibility predicates (pure — detect-before-mutate, Rule 9)
// ---------------------------------------------------------------------------

// A tainted conditional terminator: the only two shapes PredMux roots or
// admits inside a region. (Everything else — ret/unreachable/invoke/… — fails
// E3 and leaves.)
bool isTaintedCtrlTerm(const Instruction *T, const TaintSet &Taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() && Taint.Tainted.count(BI->getCondition());
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return Taint.Tainted.count(SI->getCondition());
  return false;
}

// E7 — a type the select substrate can mux: integer ≤ 64 bits or the scalar
// fp widths of the kjd1 controlled-copy family. (Mirrors copyControlledFn /
// copyControlledFpFn envelopes so a claimed region cannot half-lower —
// detect-before-mutate.)
bool isMuxableType(Type *Ty) {
  if (auto *IT = dyn_cast<IntegerType>(Ty))
    return IT->getBitWidth() <= 64;
  return Ty->isHalfTy() || Ty->isFloatTy() || Ty->isDoubleTy() ||
         Ty->isX86_FP80Ty();
}

// The wider gate for INTERMEDIATE arm values (they never cross a merge, so
// they only need a forward template, not a controlled copy): the
// opcode-table width surface — integers up to 64 bits plus the Tier-1 i128,
// and the four scalar fp widths. fp128/ppc_fp128, pointers, and everything
// exotic fail here and the region is LEFT (a Rule-13 clearance hardening —
// previously such an arm flattened and then declined loudly at lowerOps).
bool isTemplateWidthType(Type *Ty) {
  if (auto *IT = dyn_cast<IntegerType>(Ty)) {
    unsigned W = IT->getBitWidth();
    return W <= 64 || W == 128;
  }
  return Ty->isHalfTy() || Ty->isFloatTy() || Ty->isDoubleTy() ||
         Ty->isX86_FP80Ty();
}

// A compare whose flag the substrate can mint (icmp on int ≤ 64 / fcmp on the
// scalar fp widths; never vectors or pointers).
bool isSupportedCompareLeaf(const CmpInst *Cmp) {
  // NO SELF-OPERAND / ALIASED-OPERAND FENCE HERE, DELIBERATELY (bd big5,
  // 2026-07-31 — the revert of bd 7q3s / dd2c103). DO NOT RE-ADD ONE. An
  // aliased condition compare is CASE A (aliased INPUTS, FRESH output flag
  // rail) = a realizable unary function of the shared operand, not a defect;
  // the full refutation is at the `collectCondTree` leaf slot in
  // SelectClassify.cpp. Adding one back here would ALSO re-open the posture
  // problem in the opposite direction: PredMux would decline the CLAIM for a
  // region the downstream select now happily lowers.
  Type *OpTy = Cmp->getOperand(0)->getType();
  if (OpTy->isPointerTy() || OpTy->isVectorTy())
    return false;
  if (auto *IT = dyn_cast<IntegerType>(OpTy))
    return IT->getBitWidth() <= 64;
  return OpTy->isHalfTy() || OpTy->isFloatTy() || OpTy->isDoubleTy() ||
         OpTy->isX86_FP80Ty();
}

// bd 3c6m.14.2 — a literal `undef`/`poison` is NOT a defined leaf, however
// deeply it is buried in a constant aggregate/expression.
//
// *** `constantCarriesUndef` / `valueCarriesUndef` NOW LIVE IN
// `LiteralIntegrity.{h,cpp}` (bd xy9n). They were LIFTED verbatim out of this
// anonymous namespace, not reimplemented, so the cone proof here and the
// module-wide emitted-operand guard there cannot drift apart (Rule 14). The
// arguments that used to be written here are RESTATED there, not copied
// verbatim — the visited-set-rather-than-depth-budget rationale and the
// deliberate `GlobalValue` over-decline both moved; the ASLR refutation that
// used to sit in this block did NOT, and the `canCreateUndefOrPoison` measurement
// quoted there is NEW text (it was never in this file — it came from the bu96
// decline-to-fix). Read that header before touching either caller. ***
//
// The two callers in this file are unchanged (`classifyConeNode`'s leaf test at
// the compare-operand walk, and the rotation-argument scan), and the corpus
// verdict diff over 966 fixtures + 257 slices + 251 openlibm modules is
// byte-neutral for every pre-existing PredMux fixture.

// bd 3c6m.14.2 — the three curated intrinsics that can return POISON, and the
// reason they cannot be handled the way every other poison source here is.
//
// `llvm.ctlz(x, is_zero_poison)` / `llvm.cttz(x, is_zero_poison)` return poison
// for x==0, and `llvm.abs(x, is_int_min_poison)` returns poison for INT_MIN,
// when the trailing `i1` is true. That `i1` is an **immarg** — an OPERAND, not
// an annotation. `Instruction::hasPoisonGeneratingAnnotations()` does not see
// it, no `drop*` API can strip it, and it is a `ConstantInt`, so
// `valueCarriesUndef` does not see it either. Every mechanism this file has for
// neutralising poison structurally misses it, so the only sound handling is to
// REFUSE — conservatively, including when the immarg is not a ConstantInt.
//
// This was found by the bd 3c6m.14.2 Rule-13 round, on the FIRST draft of that
// ticket's own fix, and reproduced by the orchestrator: a shielded cone over
// `ctlz(0, true)` was claimed and flattened with `opt` exit 0, `opt -verify`
// clean and `free_pairing_check` STRICT 6/6, and the linked trace fired
// `cq_template_icmp_sgt_i32_hl(h32, 0)` — a gate on a rail index `cqrt_alloc_*`
// never returned. Every OTHER member of the curated set is genuinely total:
// bswap/bitreverse/ctpop, smin/smax/umin/umax, the four `*_sat`, fshl/fshr (the
// rotate amount is taken modulo the width), and the p119 hardware fp survivors
// (which return NaN, never poison). See `intrinsicStem` in IntrinsicLowering.cpp
// for the authoritative set — these two lists are coupled with nothing
// mechanical holding them together, so re-read it when either moves.
// *** THE BODY MOVED TO PoisonFacts.cpp (bd s6ao) — this is now a using-decl. ***
// It was lifted because `qromIndexKnownInBounds` (QramLowering.cpp) needs THE
// SAME answer: the `is_zero_poison` immarg is an ordinary call OPERAND, so no
// flag-stripping API reaches it, and a QROM index bounded by it is bounded by a
// fact Rule 15's ABI discards. Keeping two copies is exactly the drift Rule 14
// exists to stop — and the asymmetry was real, not hypothetical: this predicate
// refused `ctlz(0,true)` correctly HERE while the QROM bounds proof accepted the
// identical intrinsic one ticket later, shipping an out-of-bounds read reachable
// from `__builtin_ctzll`. Same poison source, same file family, two consumers,
// one of them wrong. See PoisonFacts.h for the full channel taxonomy.
using cq::curatedIntrinsicCanBePoison;

// bd 3c6m.14.2 — the per-instruction core of the shielded-cone definedness
// proof, given a name because the fence it draws is referenced from three
// comments and was previously buried inside the walk. Calls are NOT decided
// here; `coneDefinedAfterFlagDrop` owns that.
//
// STRICTER than the `isSpeculatableDataflow` families, because this asks
// DEFINEDNESS, not speculation safety:
//   * icmp/fcmp (FMF dropped), add/sub/mul/and/or/xor (nsw/nuw dropped),
//     udiv/sdiv/urem/srem by the isSpeculatableDataflow-safe CONSTANT only;
//   * shl/lshr/ashr ONLY by an in-range ConstantInt amount (a runtime
//     amount >= bit width is INHERENT poison — no flag to drop);
//   * the defined casts zext/sext/trunc/fpext/fptrunc/sitofp/uitofp/bitcast
//     (fptosi/fptoui are inherent poison on out-of-range inputs — fail);
//   * select/phi/freeze.
// Everything else — loads, geps, fneg, and every call — fails HERE. Those are
// over-declines and they are safe; `fneg` in particular is total and could be
// admitted, but nothing measured needs it and widening a definedness proof is
// not what this ticket is for (Rule 17).
bool definedOpAfterFlagDrop(const Instruction &I) {
  if (isa<CmpInst>(&I) || isa<SelectInst>(&I) || isa<PHINode>(&I) ||
      isa<FreezeInst>(&I))
    return true;
  if (const auto *BO = dyn_cast<BinaryOperator>(&I)) {
    switch (BO->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Mul:
    case Instruction::And:
    case Instruction::Or:
    case Instruction::Xor:
    case Instruction::FAdd:
    case Instruction::FSub:
    case Instruction::FMul:
    case Instruction::FDiv:
    case Instruction::FRem:
      return true;
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr:
      // `APInt::ult`, NOT `getZExtValue() <` (bd 3c6m.14.2 Rule-13 round). In a
      // Release plugin the `getZExtValue` assert is compiled out and it returns
      // the LOW WORD, so `shl i128 %w, 1<<100` — whose low word is 0 — read as
      // an in-range amount of 0 and was ADMITTED, while the same shift by 200
      // correctly declined. Measured on the shipped plugin before the fix.
      if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
        return C->getValue().ult(BO->getType()->getScalarSizeInBits());
      return false;
    case Instruction::UDiv:
    case Instruction::SDiv:
    case Instruction::URem:
    case Instruction::SRem: {
      const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1));
      return C && !C->isZero() &&
             !((BO->getOpcode() == Instruction::SDiv ||
                BO->getOpcode() == Instruction::SRem) &&
               C->isMinusOne());
    }
    default:
      return false;
    }
  }
  if (const auto *CI = dyn_cast<CastInst>(&I)) {
    switch (CI->getOpcode()) {
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::Trunc:
    case Instruction::FPExt:
    case Instruction::FPTrunc:
    case Instruction::SIToFP:
    case Instruction::UIToFP:
    case Instruction::BitCast:
      return true;
    default:  // fptosi/fptoui/ptr casts — inherent poison / out of scope.
      return false;
    }
  }
  return false;
}

// bd u1rp — THE ONE CLASSIFICATION THE PROOF AND THE STRIP BOTH READ.
//
// `coneDefinedAfterFlagDrop` (claim time) decides whether the cone is defined
// once its poison-generating annotations are dropped; `stripPoisonCone` (emit
// time) performs that drop. Those are two halves of ONE statement, and before
// this they were two independent walks that had silently diverged: the strip had
// no `cq_theta`/`cq_phi` leaf case, so it recursed straight past the rotation
// into the CLASSICAL SEED subtree and dropped `nsw`/`nuw` off instructions the
// whitelist REFUSES and the proof never visited. MEASURED on the shipped plugin:
// `%seed = add nsw nuw i32 %u, 1` feeding `cq_theta_si32` came out
// `%seed = add i32 %u, 1`.
//
// Sharing the classifier is the same discipline `PhiCondScope` applies to the
// phi conversion (see `isConvertiblePhiCond`): claim and emit consume ONE
// decision instead of re-deriving it, which is what makes a divergence between
// them impossible rather than merely unobserved.
//
//   Fail        — the proof refuses; the select-form stays unclaimed.
//   Leaf        — defined WITHOUT any drop: no mutation, NO OPERAND RECURSION.
//   Interior    — admitted *conditionally on the drop*: exactly the set the
//                 strip must mutate, and the set to recurse through.
//   PassThrough — the node's VALUE IS ITS OPERAND 0. Recurse into operand 0
//                 only; mutate nothing (there is no annotation on it that could
//                 make operand 0 more defined).
enum class ConeNode { Fail, Leaf, Interior, PassThrough };

ConeNode classifyConeNode(const Value *V) {
  if (valueCarriesUndef(V))
    return ConeNode::Fail;  // bd 3c6m.14.2 — an undef/poison leaf is not defined.
  const auto *I = dyn_cast<Instruction>(V);
  if (!I) {
    // bd 615s — AN ARGUMENT IS NOT AN UNCONDITIONALLY DEFINED LEAF, and the bare
    // `Constant / Argument leaf — defined` shortcut said it was. A caller may pass
    // `poison` to ANY parameter, and `coneDefinedAfterFlagDrop`'s promise ("the
    // cone is DEFINED once its poison-generating annotations are dropped") then
    // licenses rewriting a poison-SHIELDED `select(a, b, false)` into a plain
    // `and(a, b)` — which OBSERVES `b` on the basis states the shield excluded.
    // An argument's poison arrives from OUTSIDE the function, where no drop this
    // pass performs can reach it: `dropPoisonGeneratingAnnotations()` mutates
    // INSTRUCTIONS, while the fact that would have to go lives on the caller's
    // CALL SITE in another function. Refusing beats mutating.
    //
    // *** THE TEST IS `noundef`, AND THAT IS THE WHOLE POINT — DO NOT TURN IT BACK
    // INTO AN ENUMERATION OF POISON CHANNELS. *** Increment 1 of this fix listed
    // the four LLVM 19 attributes that make a parameter poison-if-violated
    // (`nofpclass` / `range` / `nonnull` / `align`) and failed those. That is a
    // PRESENCE SCAN — "is a poison-conditional fact present?" — which is exactly
    // the framing bd s6ao's post-mortem says not to use, because the enumeration
    // is the thing LLVM keeps moving. Ask the CONVERSE question instead: can this
    // argument be proven defined WITHOUT any such fact? LLVM answers it directly.
    // *** QUOTE THE CLAUSE, NOT THE GENERALISATION — the Rule-13 round showed the
    // general form IS the bd s6ao move. *** An earlier draft grounded this on
    // "either the value is fully defined, or the program is already UB, so no
    // transformation is licensed or unlicensed by us". At that generality it is a
    // reusable licence, and applied to a QROM bound or a rail index it is exactly
    // the "in bounds OR poison" reasoning s6ao ruled out. The fact that actually
    // makes THIS case safe is narrower and stronger, and it is a verbatim LangRef
    // 19 clause — from the list of positions where a poison value triggers
    // IMMEDIATE UB:
    //
    //     "The parameter operand of a `call` or `invoke` instruction, when the
    //      function OR INVOKING CALL SITE has a `noundef` attribute in the
    //      corresponding position."
    //
    // The UB is located AT THE CALL, which happens-before every instruction of the
    // callee body. So there is no ordering objection to answer: on any execution
    // that REACHES the rewritten code, the parameter was defined. And "the
    // function or …" is why reading the DEFINITION's attribute is the
    // universally-binding side.
    //
    // THE s6ao DISCRIMINATOR, since the two cases look alike from a distance:
    // s6ao's escape hatch was a WELL-DEFINED execution (poison is not UB) on which
    // CQ's artifact then did a concretely wrong thing — an out-of-bounds read.
    // Here the escape hatch is NO EXECUTION AT ALL. Two independent
    // corroborations: LLVM makes the identical inference on the identical
    // construct (`isGuaranteedNotToBeUndefOrPoison` on an `Argument`, measured by
    // an 11-case `freeze`-fold probe under stock `instcombine`), and the IR CQ
    // consumes has ALREADY been transformed by `clang -O1` under that inference —
    // so if it were unsound the miscompile happened upstream of CQ.
    //
    // COMPOSITION with the four attributes is settled by the same clause: `align`,
    // `nonnull`, `range` and `nofpclass` all say a POISON VALUE is passed instead,
    // and a poison value in a `noundef` parameter operand IS that immediate-UB
    // case. Measured: LLVM folds `freeze` away for `noundef nofpclass(nan inf)`,
    // i.e. `noundef` dominates a co-located attribute.
    //
    // KNOWN AND DELIBERATE INCOMPLETENESS, so nobody "completes" it into the
    // enumeration this comment forbids: LLVM's own Argument clause is
    // `noundef || dereferenceable || dereferenceable_or_null`, and this predicate
    // takes only the first. The other two are a pure over-decline (safe), and both
    // are unreachable here anyway — a pointer cone leaf needs `ptrtoint`, which
    // `definedOpAfterFlagDrop` refuses (measured: `ptr noundef nonnull align 8`
    // through a `ptrtoint` declines under BOTH the old and the new predicate).
    // Likewise a `freeze` does NOT stop the walk (`definedOpAfterFlagDrop` makes it
    // `Interior`), so `freeze(bare_arg)` declines even though LangRef guarantees a
    // freeze is well-defined — the one-line widening is correct and is filed
    // SEPARATELY, because a widening does not belong in a tightening commit.
    //
    // IT IS STRICTLY BETTER THAN THE ENUMERATION IN BOTH DIRECTIONS, measured:
    //   * TIGHTER — a BARE parameter (no attributes at all) now fails. That was
    //     the POPULATED half the enumeration left open.
    //   * LOOSER WHERE IT SHOULD BE — the enumeration DECLINED
    //     `double noundef nofpclass(nan inf) %x`, which is exactly what stock
    //     `clang -O1 -ffinite-math-only` emits (`float noundef nofpclass(nan inf)`),
    //     even though the `noundef` sitting right beside it IS the proof. That was
    //     a latent over-decline on the one build mode the ticket names as the
    //     source of these attributes. It is gone.
    //
    // *** THE ACCEPT THIS COSTS, STATED PLAINLY — AN EARLIER DRAFT OF THIS BULLET
    // SAID "ZERO REAL MODULES" AND THAT WAS A NO-REACH ZERO. *** `clang` omits
    // `noundef` from EVERY register-coerced by-value RECORD parameter (measured
    // across struct/union/small-vector shapes at every `-O` level), so ordinary C
    // like
    //
    //     struct Box { double lo, hi; };
    //     int probe(int u, double uf, struct Box b) { ... q > 3 && qf > b.hi ... }
    //
    // gives `define i32 @probe(i32 noundef %0, double noundef %1, double %2,
    // double %3)` and now DECLINES where it previously lowered a 144-gate circuit
    // — and the decline is MODULE-wide, so a perfectly lowerable sibling function
    // is lost with it. That is a real capability loss for record-taking programs
    // and it must not be described as free.
    //
    // IT IS ALSO EXACTLY THE HOLE, NOT A SIDE-COST. `clang` omits the attribute
    // there BECAUSE the coerced value may genuinely contain undef padding bits, so
    // a coerced record parameter IS a bare `Argument` that may carry undef — the
    // very cell the tightening exists to refuse. Closing the hole necessarily
    // declines it. The fence is coarse rather than wrong: the cone usually reads a
    // DEFINED field out of that value (`lshr`+`trunc`), and CQ has no per-field
    // proof to offer. A field-granular admission is a separate, additive
    // increment with its own red-green pair owed; it is filed, not smuggled in.
    //
    // *** AND BE HONEST ABOUT WHAT THE CORPUS NUMBERS ARE WORTH, because this file
    // has already been forced to retract one powerless number. *** MEASURED with
    // the MAXIMAL arm (`Fail` on EVERY `Argument`, i.e. the strictest setting this
    // predicate can take) over the 220 e2e stage-1 modules, comparing exit code
    // AND emitted IR: **0 differ**. Nothing in any real-code corpus available here
    // can distinguish ANY setting of this clause — not the enumeration, not the
    // `noundef` test, not refuse-everything (0 of 252 openlibm modules carry a
    // `cq_*` intrinsic at all, so the pass early-outs on them as passthrough).
    // So "0 of 220 real modules moved" is LITERALLY TRUE AND CARRIES NO
    // INFORMATION about the predicate, and the same goes for "428/428 openlibm
    // and 60/60 e2e formal parameters carry `noundef`" — that explains why two
    // arms agree, never why every arm does. THE ENTIRE EVIDENTIARY BASIS FOR THIS
    // CLAUSE IS HAND-AUTHORED IR plus the purpose-built C exhibits above. Say that
    // rather than quoting a zero. (A shape census is not a fence measurement — and
    // neither is a fence measurement with no reach.)
    //
    // MONOTONE-RESTRICTIVE relative to the ORIGINAL leaf rule (every `Argument` a
    // leaf): `Leaf` → `Fail` only, so the claimed set can only shrink. Relative to
    // increment 1 it is not monotone — it re-admits the `noundef`-attributed cell
    // above, deliberately, because that cell carries its own proof. Inert on the
    // EMIT side either way: `stripPoisonCone` treats `Fail` exactly like `Leaf`
    // (`C != Interior` → `continue`), an `Argument` has no operands to recurse
    // into and no annotation to drop, and the claim runs first regardless.
    //
    // Fixtures: `..._reject_selectform_bare_arg.ll` (the bare parameter — the half
    // increment 1 left open), `..._reject_selectform_range_arg.ll` and
    // `..._reject_selectform_nofpclass_arg_redgreen.ll` (attributed but NOT
    // `noundef`; the `_redgreen` row is the one where BASE emits a working circuit,
    // so it witnesses a real accept LOSS rather than a relocated decline), and
    // `..._accept_selectform_noundef_arg.ll` (the over-decline this increment
    // removes — `noundef nofpclass(nan inf)`, which increment 1 declined).
    // Recorded in bd 615s and bd memory [[predmux-argument-leaf-615s]].
    //
    // WHAT THIS DOES *NOT* CLOSE, so nobody reads it as more than it is. The
    // RETURN-attribute half of bd 615s (a lying `nofpclass`/`range` on a CALL
    // return inside the cone) is a different route, closed by construction rather
    // than here: `classifyConeNode`'s call clause admits only
    // `isCuratedReversibleIntrinsic`, which requires a real `IntrinsicInst`, and
    // LLVM 19 NORMALISES intrinsic declarations at parse time. And bd 615s
    // OPTION 2 — stripping `nofpclass` alongside the three declared families in
    // `stripPoisonCone` — stays DEFERRED and is now further from needed than it
    // was: zero population, zero readers, a DROP-widening on the exact surface
    // where bd u1rp reverted one, and this predicate never asks whether an
    // annotation is present in the first place. Refusing beats mutating.
    if (const auto *A = dyn_cast<Argument>(V))
      if (!A->hasAttribute(Attribute::NoUndef))
        return ConeNode::Fail;
    return ConeNode::Leaf;  // Constant, or a `noundef` Argument — defined.
  }
  if (const auto *Call = dyn_cast<CallInst>(I)) {
    // *** THE TWO ROTATIONS ARE NOT THE SAME KIND OF NODE, AND TREATING THEM
    // ALIKE WAS A VERIFY-CLEAN SILENT MISCOMPILE. ***
    //
    // `cq_theta` is a genuine defined LEAF: `RotationLowering` replaces it with
    // `cqrt_alloc_<W>(seed)` and the returned handle does not depend on `seed`
    // at all (`cq_runtime.c` — the allocator ignores the init value), so the
    // seed's definedness cannot reach the predicate. Poison in the seed lands in
    // exactly ONE place, the allocator's literal argument, so there is no
    // forward/`_unc` pair to break.
    //
    // `cq_phi` IS NOT A LEAF. `RotationLowering` does
    // `Phi->replaceAllUsesWith(Op)` — the result IS OPERAND 0, verbatim, tainted
    // or not. So its definedness is exactly operand 0's definedness and the
    // cone must continue through it. Calling it a leaf let three separate
    // defects through, all measured on the pre-fix plugin:
    //
    //   (1) LITERAL POISON, at any chain depth. `cq_phi(poison)` feeding the
    //       shielded compare emitted a forward call and its `_unc` adjoint
    //       reading the SAME `i32 poison` operand — which at the shipped -O0
    //       stage 3 materialised as TWO DIFFERENT literals, deterministically
    //       and identically across runs (NOT the ASLR artefact refuted in
    //       bd bu96):
    //           cq_template_icmp_slt_i32_hl(h0, 73896)      -> h4
    //           cq_template_icmp_slt_i32_hl_unc(h4, h0, 1401299752)
    //           cqrt_free(h4)
    //       `poison` lowers to `IMPLICIT_DEF`, which LLVM may materialise
    //       differently PER USE, so the adjoint inverts a different predicate
    //       than the forward computed; the compare rail is left dirty AND
    //       entangled with `h0`, and the free is a hidden measurement that
    //       collapses `q` — Rules 6 and 8. `opt` exit 0, `opt -verify` clean,
    //       `free_pairing_check` STRICT 6/6. *** An arguments-only check fixed
    //       ONLY depth 1: `cq_phi(cq_phi(poison))` walked straight past it, and
    //       the Rule-13 round exhibited exactly that, reachable from stock
    //       `clang -O1` via an uninitialised local through two chained phases.
    //       Recursion is the fix; an operand check is not. ***
    //   (2) INHERENT-POISON OPS, which have no flag to drop. `shl i32 %c, %d`
    //       (variable amount) correctly DECLINES directly in the cone, and was
    //       ACCEPTED one `cq_phi` hop above it. The hop turned a correct decline
    //       into an unsound accept.
    //   (3) POISON-GENERATING FLAGS below the hop were never proved and — once
    //       the bd u1rp narrowing stopped the strip at the leaf — no longer
    //       dropped either.
    //
    // Recursing through operand 0 closes all three at a measured cost of ZERO:
    // no rotation call site in 963 fixtures + 257 slice modules + 251 openlibm
    // modules has an `undef`/`poison` argument, and an ordinary chain
    // (`cq_phi` over a `cq_theta` result, or over whitelisted arithmetic on one)
    // classifies exactly as before.
    const Function *CF = Call->getCalledFunction();
    if (CF && (CF->getName().starts_with("cq_theta_") ||
               CF->getName().starts_with("cq_phi_"))) {
      // The ANGLE (arg 1) never becomes the result, but a poison angle is still
      // a garbage `cqrt_ry`/`cqrt_rz` parameter, so refuse it for both families.
      // For `cq_theta` this is also the only protection its seed gets, since the
      // seed is not recursed into.
      for (const Use &A : Call->args())
        if (valueCarriesUndef(A.get()))
          return ConeNode::Fail;
      return CF->getName().starts_with("cq_phi_") ? ConeNode::PassThrough
                                                  : ConeNode::Leaf;
    }
      // *** THIS CLAUSE ADMITS ONLY THE PROJECT'S OWN CURATED SET. IT USED TO
      // ADMIT ANY `isSpeculatablePureCalleeBody` CALLEE, AND THAT WAS A SILENT
      // MISCOMPILE (bd 3c6m.14.2). ***
      //
      // The purity proof answers "pure + total + terminating". That is NOT
      // "returns a defined value", in two independent ways: it reaches its
      // verdict through `isSpeculatableDataflow`, which admits a variable-amount
      // `shl/lshr/ashr` and `fptosi/fptoui` UNCONDITIONALLY — the very ops
      // `definedOpAfterFlagDrop` refuses inline, because their poison is
      // INHERENT and `stripPoisonCone` walks only `I->operands()` and so never
      // enters a callee body — and it SKIPS TERMINATORS, so a body of just
      // `ret i32 poison` passes VACUOUSLY. Exhibited end-to-end: the emitted
      // Bennett clone returned literal poison AS AN i32 QUBIT HANDLE, which at
      // the shipped -O0 stage 3 materialised as the `%q` rail itself, so the
      // circuit computed `(q>3) ∧ (q>0)` instead of `(q>3) ∧ (leaf(q)>0)` —
      // `opt` exit 0, `opt -verify` clean, `free_pairing_check` STRICT 6/6.
      //
      // WHY DELETION RATHER THAN A SECOND PROOF (the ticket offered both, and
      // asked for the measurement first). MEASURED: the pure-callee disjunct is
      // reached by 1 of 949 ir-pass fixtures and 0 of 238 e2e slices; and of the
      // 39 poison-shielded select-forms `clang -O1` emits across 248 real
      // openlibm TUs, the 5 with a call in the shielded cone carry ONLY curated
      // intrinsics. Its real-code population is EMPTY. The ticket's reason for
      // keeping it — "the plain -O1 expl→floorl shape" — is a DIFFERENT surface:
      // that accept is S1, `recoverRegion`'s E4 call admission, where the call
      // sits in an ARM and this proof never sees it (pinned by
      // lowering_predmux_speccall_flatten.ll, which still passes).
      //
      // A definedness proof over an arbitrary callee body WAS written first, and
      // the Rule-13 round found a fresh verify-clean silent miscompile inside it
      // (the immarg cell below) plus an unsound shift-width check, in ~40 lines
      // serving zero measured inputs. Nobody set out to build "an arbitrary pure
      // callee inside a poison-shielded `&&`" — it was an incidental widening of
      // a SPECULATION clause into a context carrying a strictly stronger
      // obligation — so Rule 17 does not protect it, and the Prime Directive says
      // an unproven, unpopulated accept surface should not exist.
      //
    // The curated disjunct STAYS: those are the project's own set, their
    // totality is a fact about code we ship rather than an inference about
    // user code, and they are the only call shape with any measured
    // population. `curatedIntrinsicCanBePoison` carves out the three cells
    // whose poison rides an immarg no drop can reach.
    //
    // NOTE `isCuratedReversibleIntrinsic` requires a real `IntrinsicInst`
    // (IntrinsicLowering.cpp), so after bd 3c6m.14.2 EVERY call this clause can
    // admit is an `llvm.*` intrinsic. That is what closes bd 94on(a) on this
    // surface — see the note on the return-attribute drop in `stripPoisonCone`.
    return isCuratedReversibleIntrinsic(Call) && Call->doesNotAccessMemory() &&
                   !curatedIntrinsicCanBePoison(Call)
               ? ConeNode::Interior
               : ConeNode::Fail;
  }
  return definedOpAfterFlagDrop(*I) ? ConeNode::Interior : ConeNode::Fail;
}

// bd adia: is every instruction in `V`'s backward cone TOTAL (defined on all
// inputs) once its poison-generating annotations are dropped? The admissibility
// proof for canonicalizing a poison-shielded short-circuit select-form into a
// plain and/or (which observes the shielded operand on basis states the original
// never did). Node classification — including which leaves stop the walk — is
// `classifyConeNode`, shared verbatim with `stripPoisonCone` (bd u1rp).
bool coneDefinedAfterFlagDrop(const Value *Root) {
  SmallPtrSet<const Value *, 16> Seen;
  SmallVector<const Value *, 16> WL;
  WL.push_back(Root);
  while (!WL.empty()) {
    const Value *V = WL.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    switch (classifyConeNode(V)) {
    case ConeNode::Fail:
      return false;
    case ConeNode::Leaf:
      continue;
    case ConeNode::PassThrough:
      // The node's value IS operand 0 (a `cq_phi` result, post-RAUW). Follow
      // only that operand — the angle is already checked by the classifier and
      // never becomes the result.
      WL.push_back(cast<Instruction>(V)->getOperand(0));
      continue;
    case ConeNode::Interior:
      break;
    }
    for (const Value *Op : cast<Instruction>(V)->operands())
      WL.push_back(Op);
  }
  return true;
}

// bd q2wk (Inc 5) — the claim-time context a PATH-PREDICATED PHI condition
// needs (PRD §4.4b rule (A)). `InRegion`/`Entry` decide whether the flatten
// will actually convert the phi (`run()` converts every region block's phis
// EXCEPT the entry's), and `Recorded` collects the phis the claim PROVED
// convertible so `convertPhis` can take the boolean-algebra path for exactly
// those — claim and emit share one decision instead of re-deriving it, which
// is what makes a depth-budget or already-converted-incoming difference
// between the two impossible. Null scope = no phi is admissible (every
// non-claim caller keeps today's grammar byte-identically).
//
// `Entry == nullptr` means NO ENTRY FENCE, and that is a real contract, not an
// accident of a default: the bd oudq W6 witness uses it to ask "would this phi
// convert if its block were a MERGE?" and pairs it with a second scope whose
// `Entry` IS that block, so the two answers differ exactly on the entry-phi
// rule. Every other caller passes a real region entry. A future refinement that
// dereferences `Entry` (a dominance test, an assert) must keep this case alive
// or it silently turns W6 off — or, worse, on for a genuine entry phi. NOTE the
// fence is spelled `PB == S->Entry`, so a DETACHED phi (null parent) also reads
// as fenced under a null `Entry` — the safe direction (both scopes then answer
// false and W6 cannot fire), and unreachable in practice since any phi in a
// verified terminator's condition cone is parented.
struct PhiCondScope {
  const SmallPtrSetImpl<BasicBlock *> *InRegion = nullptr;
  const BasicBlock *Entry = nullptr;
  SmallPtrSetImpl<PHINode *> *Recorded = nullptr;
};

bool isBooleanCondTree(const Value *V, unsigned Depth,
                       const PhiCondScope *S = nullptr);

// bd q2wk (Inc 5) — is this i1 phi one the flatten will convert to boolean
// algebra, so that its value can serve as a branch-condition tree node? All
// four conditions are load-bearing (PRD §4.4b):
//   1. i1 type and 3. >1 UNIQUE incoming block — `convertPhis`' own BoolAlg
//      gate, mirrored exactly (its `In` list dedups by incoming BLOCK).
//   2. parent inside the region but NOT the entry — `run()` skips
//      `R.Entry`, so an entry phi survives the flatten AS A PHI and
//      `buildNegation` would run its terminal `cast<BinaryOperator>` on a
//      `PHINode`: an assert in a `+Asserts` build and an unchecked bad cast in
//      the shipped Release build, not merely invalid IR `-verify` would catch.
//   4. every incoming inside the STRICT substrate grammar (`isBooleanCondTree`,
//      extended with this same phi rule). Deliberately NOT the permissive
//      `isSupportedCondTree`: an incoming admitted only by the permissive
//      grammar (xor-true, a select-form short-circuit) is composed straight
//      INTO the boolean-algebra tree as an OFF-GRAMMAR LEAF (`and(EP, %xor)`,
//      `and(EP, %trunc)`) — because a RECORDED phi bypasses `convertPhis`'
//      grammar re-check — and `literal()` then hands `buildNegation` a tree
//      whose leaf is neither cmp/and/or/xor nor constant, hitting the same
//      `cast<BinaryOperator>`. (The q2wk Rule-13 round corrected this comment:
//      it used to describe a SELECT-CHAIN fallback, which the BoolAlgPhis
//      record makes unreachable for exactly the phis this condition guards.)
// undef/poison incomings are admitted because `convertPhis` freezes them to the
// type's zero (an i1 constant) BEFORE its own grammar check — mirroring that
// freeze here is what keeps claim and emit in step.
bool isConvertiblePhiCond(const PHINode *P, const PhiCondScope *S,
                          unsigned Depth) {
  if (!S || !S->InRegion || !P->getType()->isIntegerTy(1))
    return false;
  BasicBlock *PB = const_cast<BasicBlock *>(P->getParent());
  if (PB == S->Entry || !S->InRegion->count(PB))
    return false;
  SmallPtrSet<BasicBlock *, 8> SeenPreds;
  for (unsigned I = 0, N = P->getNumIncomingValues(); I != N; ++I)
    SeenPreds.insert(P->getIncomingBlock(I));
  if (SeenPreds.size() < 2)
    return false;
  for (unsigned I = 0, N = P->getNumIncomingValues(); I != N; ++I) {
    const Value *IV = P->getIncomingValue(I);
    if (isa<UndefValue>(IV))
      continue;  // frozen to i1 false by convertPhis before its grammar check.
    if (!isBooleanCondTree(IV, Depth + 1, S))
      return false;
  }
  if (S->Recorded)
    S->Recorded->insert(const_cast<PHINode *>(P));
  return true;
}

// E6 — a branch condition PredMux can take BOTH polarities of: a supported
// compare, an and/or tree over such conditions, an xor-true (not), an i1
// constant, or (Inc 5) a path-predicated i1 phi the flatten will convert. The
// false-edge literal is built by pushing the negation to the leaves (De
// Morgan), so every emitted predicate tree stays inside the 3c6m.12-cleared
// and/or-over-compare-leaves shape (the no-NOT invariant).
bool isSupportedCondTree(const Value *V, unsigned Depth,
                         const PhiCondScope *S = nullptr) {
  if (Depth > 8)
    return false;
  if (const auto *P = dyn_cast<PHINode>(V))
    return isConvertiblePhiCond(P, S, Depth);  // Inc 5 (bd q2wk)
  if (isa<ConstantInt>(V))
    return true;
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp);
  if (const auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::And ||
        BO->getOpcode() == Instruction::Or)
      return isSupportedCondTree(BO->getOperand(0), Depth + 1, S) &&
             isSupportedCondTree(BO->getOperand(1), Depth + 1, S);
    if (BO->getOpcode() == Instruction::Xor)
      if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
        if (C->isOne())
          return isSupportedCondTree(BO->getOperand(0), Depth + 1, S);
  }
  // bd adia: clang -O1's poison-shielded short-circuit forms —
  // `select i1 a, i1 b, false` (a && b) and `select i1 a, true, i1 b`
  // (a || b, the coshl `ex < K || (ex == K && mx < M)` exponent ladder). The
  // flatten canonicalizes them to plain and/or (see canonicalizePred), which
  // OBSERVES the shielded operand on basis states where the original select
  // did not — sound ONLY when that operand is provably DEFINED there. The
  // admissibility proof is coneDefinedAfterFlagDrop: every instruction in
  // the shielded operand's backward cone must be total once its
  // poison-generating flags/metadata are dropped (the drop happens in
  // stripPoisonCone at flatten time). Ops whose poison is INHERENT — a shift
  // by a runtime amount that may reach the bit width, the out-of-range
  // fp->int casts — have no flag to drop and fail the proof (the adia
  // Rule-13 board's inherent-poison note), leaving the region for the
  // existing loud declines.
  // *** THE SELECT/PHI ASYMMETRY IS DELIBERATE AND ITS REASON IS A MEASUREMENT
  // (bd 2qvr, resolved 2026-08-16). *** The poison-shielded short-circuit `a && b`
  // reaches PredMux in TWO spellings under TWO standards, and until now nothing
  // wrote down why:
  //   * SELECT `select i1 %a, i1 %b, i1 false` — THIS clause -> the
  //     `coneDefinedAfterFlagDrop` calls below. STANDARD = DEFINEDNESS. Refuses a
  //     variable-amount shl/lshr/ashr, fptosi/fptoui, and a non-`noundef`
  //     Argument.
  //   * PHI `phi i1 [ false, %entry ], [ %b, %rhs ]` -> `isConvertiblePhiCond` ->
  //     `isBooleanCondTree`, which calls `classifyConeNode` ZERO times; the arm
  //     body is admitted by `recoverRegion`'s E4 `isSpeculatableDataflow`.
  //     STANDARD = SPECULATION-SAFETY, which admits poison by design.
  // So the same C lowers or declines on which spelling clang happened to emit.
  // The owner ruled TIGHTENING the phi route out (it must not reduce libm
  // coverage; 14 committed libm goldens run through it), leaving LOOSENING this
  // one — an accept WIDENING on the surface five consecutive Rule-13 rounds have
  // concentrated on. The precondition was: DOES IT BUY ANYTHING?
  //
  // MEASURED BY DIFFERENTIAL, TWICE, INDEPENDENTLY. A deliberately loosened
  // plugin (these two conjuncts replaced by `true`, three changed lines total)
  // was run against the shipped one over 496 REAL-CODE modules: 125 openlibm
  // cells x {O1,O2} through the shipped census machinery + a 26-module
  // all-tainted-argument extension + the 220 e2e stage-1 modules as a control.
  // The openlibm corpus was rebuilt from scratch (the cached one had been
  // tmp-reaped) and gated on the README's 409-symbol fingerprint, reproducing
  // the shipped 104/125 lowering baseline.
  //   decline -> accept ....... 0
  //   accept  -> decline ....... 0
  //   lowered modules with byte-IDENTICAL emitted IR ... 415/415
  // *** AND IT IS NOT A NO-REACH ZERO, WHICH IS THE ONLY THING THAT MAKES A ZERO
  // WORTH QUOTING HERE. *** An instrumented build shows the cone gate is
  // CONSULTED on real code — 17-19 module-instances across 7 distinct O1 libm
  // cells (acoshl, coshl, nextafterl, nexttoward.f64, pow.f64, sinhl, tanhl),
  // every one inside a claimed region — and `cone=FAIL` is **0** in every run.
  // The proof this clause performs SUCCEEDS every time real code asks it. There
  // is nothing for a loosening to buy. (The same loosened build flips 14 of the
  // 1059 committed fixtures decline->accept, so the probe demonstrably detects
  // what it is looking for; those 17 refusals live only in hand-authored
  // fixtures.)
  //
  // QUOTE IT WITH ITS REACH, NEVER AS "496 modules, zero delta". The confidence
  // is set by the 17-19 REACHED instances, not by the denominator — quoting the
  // denominator alone is the exact shape of the three numbers this file family
  // has already had to retract (bd memory [[predmux-argument-leaf-615s]]).
  //
  // TWO LIMITS ON TRANSFER, both load-bearing:
  //   1. The loosening measured is STRICTLY MORE PERMISSIVE than the phi
  //      standard (`sdiv` accepts under it and declines on the phi route), so 0
  //      is an UPPER BOUND over every narrower variant. Nothing in between can
  //      buy more.
  //   2. Only the CLAIM standard was loosened; `stripPoisonCone`'s MUTATED SET
  //      was untouched. A widening that also widened the strip (admitting loads
  //      and geps) is NOT covered by this measurement, and it would collapse two
  //      of the three legs of the 9dc909e shared-mutation closure. That census
  //      does not transfer and would have to be re-run.
  // RESOLUTION: bd 2qvr option (3) — DOCUMENT the asymmetry, change no code.
  // Rule 17's carve-out applies verbatim: an over-safe decline of a shape we were
  // NOT trying to support is still correct, and this one is measurably free.
  if (const auto *Sel = dyn_cast<SelectInst>(V)) {
    if (!Sel->getType()->isIntegerTy(1))
      return false;
    if (const auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue()))
      if (FC->isZero())
        return coneDefinedAfterFlagDrop(Sel->getTrueValue()) &&
               isSupportedCondTree(Sel->getCondition(), Depth + 1, S) &&
               isSupportedCondTree(Sel->getTrueValue(), Depth + 1, S);
    if (const auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue()))
      if (TC->isOne())
        return coneDefinedAfterFlagDrop(Sel->getFalseValue()) &&
               isSupportedCondTree(Sel->getCondition(), Depth + 1, S) &&
               isSupportedCondTree(Sel->getFalseValue(), Depth + 1, S);
  }
  return false;
}

// Inc 2 — the SUBSTRATE-grammar condition tree (a strict subset of
// isSupportedCondTree): compare leaves and distinct-operand `and i1`/`or i1`
// nodes only — no xor-true, no trunc/freeze/select, no compares OVER i1
// operands. This mirrors `collectCondTree` (SelectClassify.cpp) plus its
// self-operand and i1-operand-leaf fences, because an i1 phi converted to
// boolean algebra composes its incomings INTO a select condition the 3c6m.12
// flag-mint must accept verbatim. i1 constants are additionally admitted —
// they never reach the tree (the composer folds ∧true/∧false away). Anything
// off-grammar falls back to the Inc-1 select chain (same loud decline at the
// consuming select as today — posture unchanged).
//
// bd q2wk (Inc 5): with a `PhiCondScope` (the CLAIM-time caller only) a
// convertible i1 phi is also a node — a chained short-circuit
// (`phi i1 [ %p, %a ], [ false, %b ]` where `%p` is itself such a phi) must be
// admissible as a whole, because at EMIT time the inner phi has already been
// RAUW'd to its and/or tree and would pass this grammar anyway. Without a scope
// (the emit-time caller in `convertPhis`) the phi case is off and the grammar is
// byte-identical to Inc 2's.
bool isBooleanCondTree(const Value *V, unsigned Depth, const PhiCondScope *S) {
  if (Depth > 16)
    return false;
  if (const auto *C = dyn_cast<ConstantInt>(V))
    return C->getType()->isIntegerTy(1);
  if (const auto *P = dyn_cast<PHINode>(V))
    return isConvertiblePhiCond(P, S, Depth);  // Inc 5 (bd q2wk); null S ⇒ false
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp) &&
           !Cmp->getOperand(0)->getType()->isIntegerTy(1);
  if (const auto *BO = dyn_cast<BinaryOperator>(V))
    if (BO->getType()->isIntegerTy(1) &&
        (BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or))
      // Self-operand NODE fence — the mirror of `collectCondTree`'s (see the
      // corrected rationale there, SelectClassify.cpp: the original "no backend
      // can realize it" premise is RETRACTED — this is CASE A and the network is
      // already alias-correct — but the fence is KEPT as a scoped conservative
      // decline because the shape is reachable from neither -O1 C nor rail
      // aliasing). The LEAF axis carries no such fence, deliberately (bd big5).
      return BO->getOperand(0) != BO->getOperand(1) &&
             isBooleanCondTree(BO->getOperand(0), Depth + 1, S) &&
             isBooleanCondTree(BO->getOperand(1), Depth + 1, S);
  return false;
}

// E4 — one instruction of pure speculatable dataflow at template-supported
// widths. The ONLY memory op admitted is a const-global QROM READ (and its
// single-use address gep) via the taint-blind `qromReadShapeInScope` (bd 20xt.4
// Inc 2, blocker c) — a pure, side-effect-free load of an immutable table; every
// store/atomic/volatile-load excludes the region. ANY call other than a curated
// memory(none) intrinsic — including every @cq_* front-end intrinsic, so
// phase/value-rotation arms and 6.5 classical-call arms structurally stay with
// their shipped owners — excludes it too. NOTE the QROM-read cases are reached
// ONLY from the pending-spec pure-callee proof (`isSpeculatablePureCalleeBody`);
// `recoverRegion`'s E4 body walk handles load/gep by the STRICTER, taint-aware
// `classifyQromReadUnderControl` BEFORE it ever falls through to here.
//
// `AdmitI80Compare` (bd 3c6m.61) — THE PARAMETER EXISTS BECAUSE THIS PREDICATE
// HAS EXACTLY TWO CALL SITES THAT WANT DIFFERENT ANSWERS. Both are named here;
// keep this list in sync with `grep -n isSpeculatableDataflow` or it rots:
//
//   * `recoverRegion`'s E4 REGION-BODY walk passes `!ClaimAll` — an arm-resident
//     i80 compare enters the flattened SELECT PROGRAM of the region being
//     walked, and only the TOP-LEVEL substrate is reviewed for that. Clone mode
//     keeps the blanket exclusion (pinned: reject_i80_cmp_clonemode.ll).
//   * `isSpeculatablePureCalleeBodyImpl` passes TRUE (bd 3c6m.14.1). There the
//     predicate answers a DIFFERENT question — "is this callee a pure, total,
//     terminating function of its arguments?" — and an `icmp` is pure and total
//     at every width, so the width exclusion was never about that question. The
//     compare stays INSIDE the callee: it is lowered by the callee's own
//     Phase-6 clone, never by the caller's flatten. Stated precisely, because a
//     Rule-13 lens correctly rejected the first wording ("the pass does no
//     inlining"): the pass DOES have one body-splicer, `lowerByRefInline`
//     (ByRefInline.cpp), and it admits `isa<CmpInst>` at any width — but it runs
//     at CQLoweringPass.cpp step ~87, BEFORE the PredMux fixpoint at ~178, so it
//     cannot introduce callee instructions into a region after a claim.
//     Specialization's `CloneFunctionInto` only mints new functions. MEASURED in
//     every accepting probe: the original callee is byte-untouched in the output
//     and the caller's clone contains only the CALL. Its own lowering
//     obligation is discharged separately and it still declines when unmet
//     (reject_i80_cmp_purecallee_armdiamond.ll: the callee's OWN tainted diamond
//     hits the clone-mode `!ClaimAll` fence above and loud-declines).
//
// WHAT THE PURE-CALLEE `true` WIDENS. *** STATE THE COUNTING UNIT — this is the
// third time the number has been re-derived and the first two were wrong,
// including the draft of THIS comment, which said "THREE textual call sites plus
// one recursion" and is not reproducible under ANY consistent unit (bd
// 3c6m.14.4's census). Re-derive by grep over ALL of ir-pass/, never inherit. ***
//
//   grep -rnE "isSpeculatablePureCallee(Body(Impl|Walk)?)?\(" ir-pass/src ir-pass/include
//
// (The `Walk` alternative is load-bearing since bd 3c6m.14.4 split the body out
// of `Impl`; a grep without it silently misses a call expression. The recursion
// is now MUTUAL — `Impl` calls `Walk` calls `Impl` — not self-recursion.)
//
//   textual call EXPRESSIONS of any of the three names ........... 6
//     ... minus the self-recursion ................................ 5
//     ... minus the recursion AND the two pure forwarders ......... 3
//   distinct CONSUMERS that make an accept decision ............... 3
//   distinct CONTEXTS those 3 consumers run in .................... 4
//   self-recursion ................................................ 1
//
// *** THE COUNTING UNIT, SPELLED OUT, because re-deriving it cost ten minutes and
// the block above only implies it. *** "the three names" means
// `isSpeculatablePureCallee` / `...Body` / `...BodyImpl` and EXCLUDES calls to
// `...BodyWalk`, so the `Impl -> Walk` expression is NOT among the 6. (The grep
// must still carry the `Walk` alternative — that is how you SEE that expression in
// order to exclude it deliberately rather than miss it silently.) Under that unit
// the pre-bd-wve8 numbers 5/4/2/2/3/1 were correct; bd wve8 added exactly one
// consumer whose entry point calls `Impl` directly, so every delta is +1.
//
// The two forwarders are `isSpeculatablePureCalleeBody` (mints the query
// context) and the exported `isSpeculatablePureCallee`. S1/S2 are the SAME
// consumer site counted twice because its answer is context-sensitive
// (`ClaimAll` threaded from Specialization.cpp); the site itself has no context
// gate. The surviving surfaces, by the CONSUMER unit:
//   S1 E4 CALL admission, top-level  (under !ClaimAll)
//   S2 E4 CALL admission, CLONE mode (same site under ClaimAll — the call site
//      has NO context gate; deliberately widened, see the note there)
//   S3 `isSpeculatablePureCallee` -> `Fp80Union.cpp`'s AdmitArgDerived seed cone
//   S5 the proof's own recursion — a clean outer callee over a compare-bearing
//      inner one.
//   S6 `isSpeculatableTotalCallee` -> `ArmClassify.cpp`'s `classifyClassicalCallArm`
//      (bd wve8; the Phase-6.5 classical-call arm). *** S6 RUNS THE WALK IN STRICT
//      MODE AND IS THE ONLY CONSUMER THAT DOES. *** It is also the only one that
//      speculates the CALL ITSELF with no clone and no lowering of the callee
//      behind it — which is exactly why it cannot accept the two clauses S1/S2/S3
//      defer. Fixtures: control_classical_call_arm_reject_{opaque,partial,qrom,
//      poisonbr,poison_arg,interposable}_callee.ll, plus the accept pair
//      accept_speculatable_decl.ll / accept_poisonselect_callee.ll.
// Each has a red-green fixture; S1/S2/S3/S5 were each measured to split against a
// pinned pre-change plugin before bd 3c6m.14.1 was written.
//
// *** S4 IS GONE — DELIBERATELY, AND IT IS THE POINT OF bd 3c6m.14.2. *** S4 was
// `coneDefinedAfterFlagDrop`'s shielded-cone CALL admission: this PURITY proof
// being used as a DEFINEDNESS proof, at a surface nobody had enumerated when the
// clause was widened. It produced a verify-clean silent miscompile (a Bennett
// clone returning literal poison as a qubit handle). The clause was DELETED
// rather than reinforced, because its measured population was empty. Do not
// re-add it: if a future ticket wants a call admitted in a shielded cone, the
// obligation is DEFINEDNESS OF THE RETURN VALUE on states the source shielded,
// which this predicate does not and cannot answer.
bool isSpeculatableDataflow(const Instruction &I, bool AdmitI80Compare = false) {
  // No vector lane and no non-template width anywhere — such an op would only
  // decline loudly post-flatten at lowerOps/castInScope; gate it here so a
  // claimed region can never half-lower (detect-before-mutate).
  if (I.getType()->isVectorTy())
    return false;
  for (const Value *Op : I.operands())
    if (Op->getType()->isVectorTy())
      return false;
  if (isa<PHINode>(I))
    return true;  // converted to a select chain, never moved as-is (E7 gates
                  // its type separately)
  if (isa<ICmpInst>(I) || isa<FCmpInst>(I)) {
    Type *OpTy = I.getOperand(0)->getType();
    if (OpTy->isPointerTy())
      return false;
    // i80 (bd 3c6m.61): the x86_fp80 bit-pattern compare — hypotl's
    // `manh == LDBL_NBIT && manl == 0` NaN test, which clang -O1 fuses into
    // `icmp eq i80 (and i80 %bits, 0xFFFF'FFFF'FFFF'FFFF), 0x8000'0000'0000'0000`
    // INSIDE the Inf/NaN arm. This is the shape the old blanket
    // `isTemplateWidthType` exclusion here declared impossible ("the canonical
    // promotion never puts those inside an arm") — a claim hypotl falsifies.
    //
    // ADMIT ONLY THE PROVABLY-`_hl` SHAPE (detect mirrors lower, Rule 12/13).
    // i80 ships the `_hl` compare row for all 10 predicates plus its `_inv`/
    // `_unc` twins. It ALSO ships a QQ row — so, precisely (this was measured;
    // an earlier draft of this comment named the wrong fence and a Rule-13 lens
    // caught it):
    //   * a Q+Q `icmp i80` in the DATA position LOWERS fine, straight through
    //     `lowerCompareImpl` to `cq_template_icmp_<pred>_i80`;
    //   * a Q+Q `icmp i80` used as a SELECT CONDITION cannot mint a flag —
    //     `qqSelectLeafWidth` (CompareLowering.cpp) fences `i80` out of the
    //     select-leaf grid — so a claimed region containing one would flatten
    //     and only THEN decline: verify-clean, loud, but POST-MUTATION, the
    //     detect-before-mutate half-lower the Inc-1 fp128 finding closed.
    // PredMux cannot cheaply tell those two positions apart pre-flatten (the
    // consuming select may not exist yet, and `valueWillTaintAfterFlatten`
    // makes a taint query unreliable here anyway), so ONE conservative gate
    // covers both: exactly one `ConstantInt` operand. That is TAINT-BLIND and
    // MONOTONE — a constant is never tainted, before or after the flatten, so
    // the `_hl` classification cannot drift. Admitting the data-position Q+Q
    // form would be a separate, deliberate widening (bd 3c6m.14.1); declining it
    // here is an over-decline, always safe.
    //
    // WHAT THIS DOES *NOT* EXCLUDE (stated because the natural reading is
    // wrong): a `Constant` that is not a `ConstantInt` — `undef`, `poison`, a
    // `ConstantExpr` — paired with a ConstantInt PASSES this test, and such a
    // compare is CLASSICAL, so the region is claimed and flattens before
    // declining downstream (`declineClassicalMuxes` / SelectClassify GATE-2).
    // That is NOT new and NOT i80-specific: `icmp i32` behaves identically
    // today and always has (measured, exact parity), and it is the residual
    // class PRD §4.4b already documents for classical leaves inside a tainted
    // region. Making i80 the ONE width that also fenced this would be
    // inconsistent, not safer.
    //
    // i80 `select`/`freeze` stay UNCLAIMED (`isTemplateWidthType` excludes
    // i80): a merged i80 value would need `cqrt_copy_i80_controlled`, which
    // does not exist. i80 as a BRANCH condition also stays unclaimed —
    // `isSupportedCompareLeaf` (E6's `isSupportedCondTree` leaf) is NOT
    // widened here; no measured cell needs it and over-declining a shape we
    // did not set out to build is correct (Rule 17).
    // The `!=` (exactly one ConstantInt) rather than `||` (at least one) IS
    // LOAD-BEARING, and the story of how that was established is worth keeping
    // because it is a methodology trap, not an i80 one.
    //
    // The bd 3c6m.14.1 arm-kill matrix flipped this to `||` — which changes
    // behaviour for the const/const shape ALONE, since Q+Q fails both spellings
    // — and the whole suite stayed green. The first explanation written here was
    // that the shape is unreachable, because `flattenPredMuxRegions` calls
    // `foldConstantConesInFunction(F)` and returns on any fold before
    // `recoverRegion` runs. *** THAT EXPLANATION IS FALSE AT THE PURE-CALLEE
    // CALL SITE, and two independent Rule-13 lenses falsified it with a run. ***
    // The folder is applied only to functions that CARRY TAINTED CONTROL, and
    // only to the function being flattened; `isSpeculatablePureCalleeBodyImpl`
    // walks the CALLEE's body, which pre-specialization has neither taint nor a
    // tainted terminator and is therefore never folded. The two probes behind
    // the wrong explanation were both written at the REGION walk — they could
    // not reach the site being defended, which is exactly the
    // probe-with-no-power failure bd memory
    // [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]] is about.
    //
    // What the spelling actually buys, measured on both plugins: under `!=` the
    // proof fails AT THE COMPARE, nothing is claimed and nothing is mutated;
    // under `||` the region is claimed and FLATTENED and the clone is built,
    // and a different diagnostic fires from inside `@__cq_q_leaf_1` — a
    // POST-MUTATION decline, the detect-before-mutate class the Inc-1 fp128
    // finding closed. Pinned by
    // control_predmux_reject_i80_cmp_purecallee_constconst.ll.
    if (OpTy->isIntegerTy(80))
      return AdmitI80Compare && (isa<ConstantInt>(I.getOperand(0)) !=
                                 isa<ConstantInt>(I.getOperand(1)));
    return isTemplateWidthType(OpTy);
  }
  if (isa<SelectInst>(I) || isa<FreezeInst>(I))
    return !I.getType()->isPointerTy() && isTemplateWidthType(I.getType());
  if (const auto *UO = dyn_cast<UnaryOperator>(&I))
    return UO->getOpcode() == Instruction::FNeg &&
           isTemplateWidthType(UO->getType());
  if (const auto *CI = dyn_cast<CastInst>(&I)) {
    if (CI->getType()->isPointerTy() || CI->getSrcTy()->isPointerTy())
      return false;
    // i80 (bd 3c6m.51 Inc 3): the promoteFp80Union canonical extract/insert
    // ops (`bitcast f80<->i80`, `trunc i80 -> iN`, `zext iN -> i80`) land
    // INSIDE claimed arms (scalbnl's field-insert packs live in the normal/
    // subnormal arms). Gate them by `castInScope` ITSELF — the exact predicate
    // castInScope-lowering enforces — so detection mirrors lowering (bd 6-4)
    // and a claimed region still can never half-lower. Every other i80 cast
    // (sext, cross-domain) fails castInScope and leaves the region.
    if (CI->getType()->isIntegerTy(80) || CI->getSrcTy()->isIntegerTy(80))
      return castInScope(CI->getOpcodeName(), abiWidthFromType(CI->getSrcTy()),
                         abiWidthFromType(CI->getType()));
    return isTemplateWidthType(CI->getType()) &&
           isTemplateWidthType(CI->getSrcTy());
  }
  if (const auto *BO = dyn_cast<BinaryOperator>(&I)) {
    // i80 (bd 3c6m.51 Inc 3): admit exactly the four shipped i80 bitwise rows
    // (and/lshr/or/shl — the shared i80BinaryInScope, mirroring the
    // ArithLowering fence); add/sub/mul/xor/ashr/div/rem at i80 have no
    // template and leave the region (detect-before-mutate). NOTE the mirror is
    // one-directional by design elsewhere: select/freeze at i80 stay
    // conservatively UNCLAIMED here (isTemplateWidthType excludes i80) — a
    // merged i80 value has no `cqrt_copy_i80_controlled`. i80 `icmp` USED to
    // ride that same blanket over-decline on the claim that "the canonical
    // promotion never puts those inside an arm"; bd 3c6m.61 (hypotl's
    // `manh == LDBL_NBIT && manl == 0` NaN test) falsified it, so the icmp case
    // above now admits the provably-`_hl` (one-ConstantInt-operand) shape and
    // only that.
    if (BO->getType()->isIntegerTy(80))
      return i80BinaryInScope(binaryStem(BO->getOpcode()));
    if (!isTemplateWidthType(BO->getType()))
      return false;
    switch (BO->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Mul:
    case Instruction::And:
    case Instruction::Or:
    case Instruction::Xor:
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr:
    case Instruction::FAdd:
    case Instruction::FSub:
    case Instruction::FMul:
    case Instruction::FDiv:
    case Instruction::FRem:
      return true;
    case Instruction::UDiv:
    case Instruction::SDiv:
    case Instruction::URem:
    case Instruction::SRem: {
      // Speculating an integer division is UB on a zero divisor (and on
      // INT_MIN / -1 for the signed forms) — admit only the provably-safe
      // constant case (cbrt's hx/3). Anything else leaves.
      const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!C || C->isZero())
        return false;
      if ((BO->getOpcode() == Instruction::SDiv ||
           BO->getOpcode() == Instruction::SRem) &&
          C->isMinusOne())
        return false;
      return true;
    }
    default:
      return false;
    }
  }
  // bd 20xt.4 Inc 2 (blocker c) — a const-global QROM read (and its single-use
  // address gep) is pure speculatable dataflow FOR THE PENDING-SPEC PURE-CALLEE
  // PROOF (`isSpeculatablePureCalleeBodyImpl`). The table is a `constant` global
  // (immutable) and the load has no side effect, so admitting it proves the
  // CALLEE BODY is a pure total terminating function — which is all that is
  // needed to hoist its CALL straight-line under quantum control (the callee's
  // OWN control flow stays intact after the hoist, so the read still executes
  // only on the in-bounds indices the source reaches; nothing is speculated OUT
  // of the callee here). The read's bounds/mask obligation is the CLONE's job:
  // when Phase-6 later flattens the clone body, the region walk's E4' LoadInst
  // case masks a NeedsMask index (`classifyQromReadUnderControl`). TAINT-BLIND
  // `qromReadShapeInScope` — the SAME structural shape the emitter's
  // `classifyQromRead` proves (Rule 14, carve/emit non-divergence) — because the
  // callee body is not in module taint (taint stops at the caller→callee
  // boundary). NOTE this case is unreachable from `recoverRegion`'s E4 walk
  // (which handles load/gep BEFORE its `isSpeculatableDataflow` fallthrough), so
  // it only widens the pure-callee proof, never the region flatten.
  if (const auto *LI = dyn_cast<LoadInst>(&I))
    return qromReadShapeInScope(LI);
  if (const auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
    if (GEP->hasOneUse())
      if (const auto *LU = dyn_cast<LoadInst>(GEP->user_back()))
        if (LU->getPointerOperand() == GEP && qromReadShapeInScope(LU))
          return true;  // the QROM read's address gep (the load re-checks shape).
    return false;
  }
  if (const auto *Call = dyn_cast<CallInst>(&I))
    // Curated pure keep-set intrinsics (fmuladd/fabs/copysign/sqrt/…) are
    // already first-class straight-line citizens of the pass; memory(none)
    // is required so nothing observable moves. (The bd adia pending-spec
    // pure-callee admit is handled at the REGION walk, where the tainted-arg
    // anti-overlap fence has taint in scope; inside a pure-callee proof the
    // inner-call case is handled by isSpeculatablePureCalleeBodyImpl itself.)
    return isCuratedReversibleIntrinsic(Call) && Call->doesNotAccessMemory();
  return false;
}

// bd adia (3c6m.55 Lever C): a direct call to a VISIBLE, acyclic, all-speculatable pure
// body — the pending-specialization callee under tainted control. Every block
// must end in br/ret, sit on no CFG cycle (termination), and every
// non-terminator instruction must itself be speculatable dataflow (phis
// included). Inner calls: curated memory(none) intrinsics, or — recursively —
// another body passing this same proof (the plain -O1 expl→floorl nesting);
// `OnStack` breaks call-graph cycles (a recursive callee has no termination
// bound → false).
//
// bd 3c6m.14.1: the per-instruction predicate runs with `AdmitI80Compare=true`.
// READ THAT AS A SCOPE STATEMENT ABOUT THIS FUNCTION, not as a general lift —
// what this proof asserts is purity/totality/termination, and `icmp` has all
// three at every width. Two call SITES ride this — the E4 call admission in
// both contexts (S1/S2) and S3 `Fp80Union`'s seed cone — plus the recursion
// below (S5); each has a fixture.
//
// bd 3c6m.14.2 — *** DO NOT READ THIS AS A DEFINEDNESS PROOF, AND DO NOT WIRE IT
// TO ONE. *** It asserts pure + total + terminating, and it gets there through
// `isSpeculatableDataflow`, which admits a variable-amount `shl/lshr/ashr` and
// `fptosi/fptoui` unconditionally; it also skips terminators, so a body of just
// `ret i32 poison` passes VACUOUSLY. `coneDefinedAfterFlagDrop` used to consume
// it (the deleted S4) and that was a verify-clean silent miscompile.
//
// *** THE SENTENCE THAT STOOD HERE IS RETRACTED (bd wve8). *** It read: "The three
// surviving consumers are sound because they SPECULATE THE CALL into a program
// that already executed it — they never observe its RESULT on a state the source
// shielded." A FOURTH consumer now exists (S6, the Phase-6.5 classical-call arm)
// for which the first half is simply untrue: it HOISTS the call out of a quantum
// guard into unconditional execution, in a program that specifically might NOT
// have executed it. Rather than patch the sentence, separate the two obligations,
// because they are what actually differ between consumers:
//   * DEFINEDNESS OF THE RESULT on a state the source shielded — S4's obligation,
//     which this predicate does not and cannot discharge, which is why S4 was
//     DELETED. S1/S2/S3 do not carry it, and neither does S6: a
//     `cqrt_copy_<W>_controlled` is the identity wherever the flag is 0, so the
//     speculated result is never observed on a shielded basis state.
//   * TOTALITY — that executing the call introduces no UB the source did not
//     have. S1/S2/S3 satisfy it WITH HELP: the callee is about to be cloned and
//     lowered, and the clone's own flatten re-proves what this walk defers.
//     *** S6 HAS NO SUCH HELP, AND ASSUMING IT DID SHIPPED A SIGSEGV. *** It runs
//     the walk in STRICT mode instead (`isSpeculatableTotalCallee`), where the
//     deferred clauses are named and refused.
// So this predicate is a TOTALITY-MODULO-TWO-DEFERRALS proof and never a
// definedness proof; which of those two a consumer needs is the first question to
// ask about any new consumer.
// bd 3c6m.14.4 — ONE top-level query's context: the cycle breaker, the memo, and
// the cost counters. *** THE MEMO IS PER-QUERY AND MUST STAY THAT WAY. ***
//
// The ticket asked for a memo "on the Function*", i.e. module-lifetime. THAT IS
// UNSOUND, and it is measured, not argued: a pure-callee verdict flips
// FALSE -> TRUE inside a SINGLE `opt` run. `unrollConstTripLoops`
// (CQLoweringPass.cpp ~200) runs BETWEEN the two `flattenPredMuxRegions`
// fixpoints (~178 and ~202) and removes CFG cycles, so a callee that failed the
// `scc_iterator` check at the first fixpoint passes at the second. Reproduced
// with a ONE-CHARACTER edit to a shipped fixture — take
// `lowering_predmux_leave_speccall_loop.ll` and make its data-dependent loop
// bound (`icmp slt i32 %i2, %a`) a constant (`, 4`): `opt` flips exit 1 -> 0, the
// `gate=E4-dataflow` leave line is STILL printed by the first fixpoint, and
// `__cq_q_purefn` is then minted by the second. A module-lifetime memo would
// serve the stale FALSE and silently kill the composition. This is not a
// contrived overlap: the unroller's tainted-callee cone seeds on the SAME
// "direct call, visible callee, >=1 tainted argument" predicate the E4 site
// requires, so every callee this proof can be asked about is in the unroller's
// cone by construction. `promoteFp80Union`'s own fixpoint is a second
// FALSE -> TRUE generator by design (Fp80Union.cpp: the proof only passes after
// the callee's unions promote out of `alloca` form).
//
// A per-QUERY memo needs no staleness argument at all: `Impl` takes a
// `const Function *` and mutates nothing, so within one query the module is
// provably fixed. It removes THIS PROOF'S share of the blowup, because the
// exponential is STRICTLY INTRA-QUERY — `OnStack` is erased on exit (it is a
// cycle breaker, never a visited set), so two sibling calls to the same callee
// re-walk the shared subtree in full and the invocation count is the number of
// distinct PATHS through the call DAG. Cross-query cost stays a linear
// multiplier in the number of queries, and that multiplier IS the soundness
// price of re-deriving against a mutated module — do not "optimise" it away.
//
// *** IT DOES NOT DISCHARGE THE DoS, AND MUST NOT BE QUOTED AS DOING SO. *** A
// Rule-13 round measured a SECOND, independent exponential on the same doubling
// call graph: with the region deleted entirely, so this proof is never queried
// and `CQ_PREDMUX_COUNT` prints nothing at all, D=20 still costs ~4.3 s on both
// the pre-change and post-change plugins, still roughly doubling per unit depth.
// It is off-file — the round's profile points at `SpecializeReject.cpp`'s
// `scanBody`, which self-recurses with a fresh per-candidate `OnStack` popped on
// exit, i.e. exactly the shape fixed here. Filed separately.
//
// Counters live HERE and never in a `static`: a static would accumulate across
// queries and across modules in one `opt` process, making the pinned number a
// function of query count and module order — exactly the flakiness bd xzdx's
// call-count precedent forbids.
struct PureCalleeQuery {
  SmallPtrSet<const Function *, 8> OnStack;
  DenseMap<const Function *, bool> Memo;
  unsigned Invocations = 0;   // entries past the F-local guard
  unsigned BodiesWalked = 0;  // entries that actually walked a body
  unsigned MemoHits = 0;      // COUNTED, not inferred as Invocations-Bodies:
                              // that difference also absorbs guard rejects and
                              // cycle returns, which made `hits` a mislabel.
  // bd wve8 — *** THIS PROOF HAS TWO CLAUSES WHOSE OBLIGATION IS DISCHARGED BY
  // SOMEONE ELSE, AND A CONSUMER THAT DOES NOT DISCHARGE THEM MUST SET THIS
  // FALSE. *** See `isSpeculatableTotalCallee` for the full statement and for
  // the SIGSEGV that established it. Default TRUE so S1/S2/S3 are byte-identical
  // to their pre-wve8 behaviour; only `isSpeculatableTotalCallee` flips it. The
  // flag lives in the QUERY, so the recursion inherits it and the per-query memo
  // can never serve a lax verdict to a strict query (each top-level entry mints
  // a fresh `PureCalleeQuery`).
  bool AdmitDeferred = true;
};

bool isSpeculatablePureCalleeBodyWalk(const Function *F, PureCalleeQuery &Q);

bool isSpeculatablePureCalleeBodyImpl(const Function *F, PureCalleeQuery &Q) {
  // hasExactDefinition: a body this proof reads must be the body that LINKS —
  // an INTERPOSABLE definition (weak_any/linkonce_any/common/extern_weak) may be
  // replaced by the linker, so a purity/termination proof over the module-local
  // body would be baked into the speculated hoist and the Bennett clone while a
  // different function runs at stage 3 (the adia Rule-13 board's confirmed fence
  // gap; the ByRefInline hasLocalLinkage precedent). NOTE (bd gxhi, empirically
  // verified against LLVM 19): `hasExactDefinition()` is `!isDeclaration() &&
  // !mayBeDerefined()`, and `mayBeDerefined()` is TRUE for weak_odr/linkonce_odr/
  // available_externally — so this predicate ALSO declines those ODR variants,
  // NOT only the arbitrary-replacement interposable set. That is a SAFE
  // over-decline (Prime Directive) with zero corpus cost (openlibm has no weak
  // symbols); admitting the ODR variants would be a deliberate `!isInterposable()`
  // widening, a separate ticket. Declarations fail here too.
  //
  // F-local and cheap; deliberately NOT memoised. It is also counted BEFORE
  // `Invocations` is bumped, so that `Invocations - BodiesWalked` really is the
  // memo-hit count: counting guard rejects and cycle returns as "hits" made the
  // number a mislabel (a module with one `declare`d callee and no memo activity
  // at all reported `hits=1`), found by the bd u1rp Rule-13 round.
  if (!F || !F->hasExactDefinition() || F->isVarArg())
    return false;
  ++Q.Invocations;
  // The memo lookup sits BEFORE the OnStack insert on purpose. An in-flight `F`
  // has no entry yet, so a genuine re-entry still falls through to the cycle
  // test below; and the `OnStack` early-return is NOT memoised, which keeps the
  // fix independent of whether a cycle-induced FALSE is permanent. (It is —
  // an OnStack hit always witnesses a real call-graph cycle, and every node on
  // the path to it inherits a permanently-false verdict — but nobody should have
  // to re-derive that to trust the memo.)
  auto It = Q.Memo.find(F);
  if (It != Q.Memo.end()) {
    ++Q.MemoHits;
    return It->second;
  }
  if (!Q.OnStack.insert(F).second)
    return false;  // call-graph cycle: termination unprovable. NOT memoised.
  auto pop = llvm::make_scope_exit([&] { Q.OnStack.erase(F); });
  ++Q.BodiesWalked;
  bool R = isSpeculatablePureCalleeBodyWalk(F, Q);
  Q.Memo[F] = R;  // only a COMPLETED walk is recorded.
  return R;
}

// The body walk proper. Split out of `isSpeculatablePureCalleeBodyImpl` so the
// memo records exactly one thing: the verdict of a full walk.
bool isSpeculatablePureCalleeBodyWalk(const Function *F, PureCalleeQuery &Q) {
  for (scc_iterator<const Function *> It = scc_begin(F); !It.isAtEnd(); ++It)
    if (It->size() > 1 || It.hasCycle())
      return false;  // a CFG cycle: termination unprovable
  for (const BasicBlock &BB : *F) {
    const Instruction *Term = BB.getTerminator();
    if (!isa<BranchInst>(Term) && !isa<ReturnInst>(Term))
      return false;
    // bd wve8, DEFERRED CLAUSE 2 — THE TERMINATOR SKIP. The instruction loop
    // below `continue`s on every terminator, so nothing here ever looked at a
    // conditional branch's CONDITION; and `isSpeculatableDataflow` admits a
    // variable-amount `shl/lshr/ashr` and `fptosi/fptoui`, all of which produce
    // POISON. `br i1 poison` is IMMEDIATE UB. For the lax consumers that is
    // harmless — they never move the branch, and the callee's control flow is
    // re-established by the clone — but a consumer that speculates the whole CALL
    // executes that branch on a path the source did not take.
    //
    // STRICT MODE REFUSES A CONDITIONAL BRANCH OUTRIGHT. An unconditional `br` is
    // admitted: it has no condition and cannot be UB.
    //
    // *** THE OBVIOUS FIX HERE IS A NO-OP THAT READS AS A FIX. MEASURED, DO NOT
    // RE-TRY IT. *** The first draft asked
    // `isGuaranteedNotToBeUndefOrPoison(BrI->getCondition())`, which is the
    // natural spelling and is CIRCULAR at exactly this position. On the shipped
    // probe body (`%s = shl i32 1, %x` / `%c = icmp eq i32 %s, 7` /
    // `br i1 %c`, with `%x` noundef) LLVM 19 answers:
    //     gnp(cond %c) = 1      gnp(op %s = shl i32 1, %x) = 0      gnp(i32 7) = 1
    // `icmp` cannot CREATE poison, so a bottom-up analysis must return 0 for `%c`;
    // it returns 1 because ValueTracking also reasons from USES — `%c` is the
    // condition of a `br`, a use that is UB on poison, so a well-defined program
    // implies `%c` is not poison. That is precisely the question being asked, run
    // backwards. The whole fixture ACCEPTED with the check in place. Same family
    // as the `canCreateUndefOrPoison` no-op recorded in LiteralIntegrity.h: a
    // predicate whose name matches the obligation and whose answer does not.
    //
    // COST OF THE BLUNTER RULE, MEASURED: zero. Every callee body in the corpus
    // that reaches this consumer is single-block (12 e2e sites, 25 fixtures). A
    // branching classical helper is not a shape 6.5 set out to support, so
    // declining it is a safe over-decline (Rule 17's carve-out), and widening it
    // later needs a poison analysis that does not consult uses.
    if (!Q.AdmitDeferred)
      if (const auto *BrI = dyn_cast<BranchInst>(Term))
        if (BrI->isConditional()) {
          if (::getenv("CQ_PREDMUX_DBG"))
            llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                         << " fails at poison-capable conditional branch: "
                         << *Term << "\n";
          return false;
        }
    for (const Instruction &I : BB) {
      if (I.isTerminator())
        continue;
      // bd wve8, DEFERRED CLAUSE 1 — THE QROM READ. `isSpeculatableDataflow`
      // admits a const-global load and its address gep through
      // `qromReadShapeInScope`, which proves the SHAPE and says in its own header
      // that "the index-taint proof, the straight-line/loop gates AND the bounds
      // proof are DEFERRED — re-proven by the emitter under the clone's own
      // cloneTaint". A consumer with no clone never performs that re-proof, so
      // the index is unbounded and the speculated call reads out of bounds.
      // EXHIBITED: `static const int tab[4]; int lookup(int i){return tab[i];}`
      // under `if (q > 3) y = lookup(idx);` with a zero-amplitude guard —
      // SIGSEGV at idx=1e8, and a silent garbage word in the trace at idx=9.
      // Refusing the gep as well as the load is deliberate: the gep case exists
      // only to serve such a load, so admitting it alone would be dead surface.
      if (!Q.AdmitDeferred && (isa<LoadInst>(I) || isa<GetElementPtrInst>(I))) {
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at deferred-bounds memory op: " << I << "\n";
        return false;
      }
      if (const auto *CI2 = dyn_cast<CallInst>(&I)) {
        if (isCuratedReversibleIntrinsic(CI2) && CI2->doesNotAccessMemory())
          continue;
        if (isSpeculatablePureCalleeBodyImpl(CI2->getCalledFunction(), Q))
          continue;
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at call: " << I << "\n";
        return false;
      }
      // bd 3c6m.14.1 — TRUE, deliberately, and it is the whole functional
      // change of that increment. See the `AdmitI80Compare` block on
      // `isSpeculatableDataflow` for why this question ("pure + total") is not
      // the region walk's question ("speculatable into THIS select program"),
      // and for the full S1..S5 list of what one `true` here widens.
      if (!isSpeculatableDataflow(I, /*AdmitI80Compare=*/true)) {
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at: " << I << "\n";
        return false;
      }
    }
  }
  return true;
}

bool isSpeculatablePureCalleeBody(const Function *F) {
  PureCalleeQuery Q;
  bool R = isSpeculatablePureCalleeBodyImpl(F, Q);
  // bd 3c6m.14.4 — the COST PIN, asserted as a CALL COUNT and never a wall time
  // so the fixture cannot go flaky (the bd xzdx precedent). On a chain-doubling
  // call graph of depth D — every `f_i` calling `f_{i+1}` TWICE — the closed
  // forms are:
  //     no memo    : invocations = bodies = 2^(D+1) - 1
  //     per-query  : invocations = 2D + 1,  bodies = D + 1,  hits = D
  // `hits` is COUNTED at the memo lookup, not inferred as
  // `invocations - bodies`: that difference also absorbs cycle returns, and
  // before `Invocations` moved below the F-local guard it absorbed guard
  // rejects too, so a module with one `declare`d callee and NO memo activity
  // reported `hits=1`. On the doubling graph the divergence between
  // `invocations` and `bodies` does witness that the memo is live — but that is
  // a property of THAT graph, not a general rule; read `hits` instead.
  // Its own env var, so the ten fixtures that FileCheck the CQ_PREDMUX_DBG
  // stream do not drift.
  if (::getenv("CQ_PREDMUX_COUNT"))
    llvm::errs() << "CQ_PREDMUX_COUNT: pure-callee root="
                 << (F ? F->getName() : "<null>") << " verdict=" << R
                 << " invocations=" << Q.Invocations
                 << " bodies=" << Q.BodiesWalked << " hits=" << Q.MemoHits
                 << "\n";
  return R;
}

// ---------------------------------------------------------------------------
// Region recovery
// ---------------------------------------------------------------------------

struct PredMuxRegion {
  BasicBlock *Entry = nullptr;   // block whose tainted terminator roots the claim
  BasicBlock *Merge = nullptr;   // immediate post-dominator of Entry
  SmallVector<BasicBlock *, 16> Topo;  // region blocks, topological, Entry first
  SmallPtrSet<BasicBlock *, 16> InRegion;
  // Inc 3 — claimable QROM reads whose index is NOT known-bits-provable but
  // whose pow2 table admits the `and idx, N-1` mask (QromClaim::NeedsMask);
  // the flatten rewrites each gep index before the speculation is final.
  // (load, table element count) pairs, captured at E4-analysis time
  // (detect-before-mutate: analysis decides, the flatten only executes).
  SmallVector<std::pair<LoadInst *, uint64_t>, 4> MaskLoads;
  // Inc 5 (bd q2wk) — the i1 phis the E6 claim PROVED convertible as
  // path-predicated branch-condition tree nodes (PRD §4.4b rule (A)).
  // `convertPhis` takes the boolean-algebra path for exactly these regardless
  // of its own grammar re-check, so claim and emit cannot diverge (a fall-back
  // select chain under a branch literal is a broken module, not a decline).
  // Populated during E6, i.e. AFTER W/E2/E3 and interleaved with E4/E7 — a
  // later `leave` discards the whole `PredMuxRegion` (one fresh `R` per
  // candidate terminator), so a partial record can never reach the flatten.
  SmallPtrSet<PHINode *, 8> BoolAlgPhis;
};

// Blocks that sit on any CFG cycle (any non-trivial SCC, or a self-loop).
// Self-contained (PredMux runs before lowerLoops and cannot lean on it).
void collectCycleBlocks(Function &F, SmallPtrSetImpl<BasicBlock *> &OnCycle) {
  for (scc_iterator<Function *> It = scc_begin(&F); !It.isAtEnd(); ++It) {
    const std::vector<BasicBlock *> &SCC = *It;
    bool Cyclic = SCC.size() > 1 || It.hasCycle();
    if (Cyclic)
      OnCycle.insert(SCC.begin(), SCC.end());
  }
}

// Kahn topological order of the region subgraph (edges into Merge ignored).
// Returns false on any anomaly (should be unreachable once E2/E3 hold).
bool topoOrderRegion(PredMuxRegion &R) {
  DenseMap<BasicBlock *, unsigned> InDeg;
  for (BasicBlock *B : R.InRegion)
    InDeg.try_emplace(B, 0);
  for (BasicBlock *B : R.InRegion)
    for (BasicBlock *S : successors(B))
      if (R.InRegion.count(S))
        ++InDeg[S];
  SmallVector<BasicBlock *, 16> Work;
  if (InDeg[R.Entry] != 0)
    return false;  // side edge into Entry from within the region: not SESE
  Work.push_back(R.Entry);
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    R.Topo.push_back(B);
    for (BasicBlock *S : successors(B)) {
      if (!R.InRegion.count(S))
        continue;
      if (--InDeg[S] == 0)
        Work.push_back(S);
    }
  }
  return R.Topo.size() == R.InRegion.size();
}

// bd 20xt.5 (d) — the merge for an entry `E` whose STANDARD post-dominator is
// the PDT virtual root PURELY because some path from `E` reaches an
// `unreachable` block (a switch default `clang -O1` proved dead — e.g. atan2l's
// exhaustive quadrant `switch i32 %m` over a 2-bit sign pack, whose
// `default.unreachable` LLVM's PostDominatorTree treats as a SECOND function
// exit alongside `ret`, giving every switch-reaching block a virtual-root
// ipdom). `unreachable` is UB: no basis state with defined behaviour ever
// enters it (Rule 5 — the source ASSERTS the path is dead), so for
// post-dominance it is NOT a real exit. We recompute the immediate
// post-dominator over the CFG-VIEW where every `unreachable`-terminated block
// (and the edges into it) is removed and the `ret` blocks are the sole exits —
// exactly the "convert unreachable→br-merge then post-dominate" experiment, but
// as PURE ANALYSIS (no mutation; Rule 9 detect-before-mutate). Returns nullptr
// (→ leave; the caller keeps today's silent virtual-root bail) unless a single
// real merge exists — over-declining is safe (Prime Directive). Downstream E2
// (acyclic) / E3 (single-exit, now unreachable-tolerant) VALIDATE the returned
// merge structurally, so a wrong answer here can only LEAVE, never miscompile.
BasicBlock *mergeIgnoringUnreachable(BasicBlock *E) {
  auto isUnreach = [](BasicBlock *B) {
    return isa<UnreachableInst>(B->getTerminator());
  };
  if (isUnreach(E))
    return nullptr;
  // Forward-reachable node set from E, EXCLUDING unreachable blocks (edges into
  // an unreachable block are dropped — they are never taken).
  SmallVector<BasicBlock *, 32> Order;  // discovery order = a valid RPO seed.
  SmallPtrSet<BasicBlock *, 32> Nodes;
  Nodes.insert(E);
  Order.push_back(E);
  for (unsigned I = 0; I < Order.size(); ++I)
    for (BasicBlock *S : successors(Order[I])) {
      if (isUnreach(S))
        continue;
      if (Nodes.insert(S).second)
        Order.push_back(S);
    }
  // Exits = ret blocks with no in-Node successor. A non-ret node with NO
  // in-Node successor (all its successors were unreachable) is an off-pattern
  // dead-end → bail (over-decline). Multiple rets simply fail to reconverge and
  // yield a nullptr merge below (no virtual bottom needed — the intersection
  // excludes disjoint-exit suffixes on its own).
  DenseMap<BasicBlock *, unsigned> Idx;
  for (unsigned I = 0; I < Order.size(); ++I)
    Idx[Order[I]] = I;
  unsigned N = Order.size();
  auto inNodeSuccs = [&](BasicBlock *B, SmallVectorImpl<BasicBlock *> &Out) {
    for (BasicBlock *S : successors(B))
      if (Nodes.count(S))
        Out.push_back(S);
  };
  for (BasicBlock *B : Order) {
    SmallVector<BasicBlock *, 4> Succ;
    inNodeSuccs(B, Succ);
    if (Succ.empty() && !isa<ReturnInst>(B->getTerminator()))
      return nullptr;
  }
  // Iterative post-dominator SETS (BitVector over Nodes): PostDom(exit)={exit};
  // PostDom(B) = {B} ∪ ⋂_{S ∈ in-Node succ} PostDom(S). Fixpoint (small F).
  SmallVector<BitVector, 32> PD(N, BitVector(N, true));
  for (unsigned I = 0; I < N; ++I) {
    SmallVector<BasicBlock *, 4> Succ;
    inNodeSuccs(Order[I], Succ);
    if (Succ.empty()) {  // an exit (ret): post-dominated only by itself.
      PD[I].reset();
      PD[I].set(I);
    }
  }
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (unsigned I = 0; I < N; ++I) {
      SmallVector<BasicBlock *, 4> Succ;
      inNodeSuccs(Order[I], Succ);
      if (Succ.empty())
        continue;  // exit: fixed.
      BitVector Meet(N, true);
      for (BasicBlock *S : Succ)
        Meet &= PD[Idx[S]];
      Meet.set(I);  // {B} ∪ ⋂
      if (Meet != PD[I]) {
        PD[I] = std::move(Meet);
        Changed = true;
      }
    }
  }
  // ipdom(E) = the member of PostDom(E)\{E} with the LARGEST post-dom set
  // (post-dominators form a strict chain E ≺ D1 ≺ … ≺ ret, and PostDom(D1) ⊋
  // PostDom(D2) ⊋ …, so D1 — the immediate one — has the max popcount). Empty
  // ⇒ no reconvergence before exit ⇒ nullptr.
  unsigned EI = Idx[E];
  int Best = -1;
  unsigned BestPop = 0;
  for (unsigned J = PD[EI].find_first(); J != (unsigned)-1;
       J = PD[EI].find_next(J)) {
    if (J == EI)
      continue;
    unsigned Pop = PD[J].count();
    if (Best < 0 || Pop > BestPop) {
      Best = (int)J;
      BestPop = Pop;
    }
  }
  return Best < 0 ? nullptr : Order[Best];
}

// The full E-ladder. Pure analysis; returns false to LEAVE (never diagnoses).
bool recoverRegion(Instruction *T, PostDominatorTree &PDT, DominatorTree &DT,
                   LoopInfo &LInfo, const SmallPtrSetImpl<BasicBlock *> &OnCycle,
                   const TaintSet &Taint, PredMuxRegion &R, bool ClaimAll) {
  BasicBlock *E = T->getParent();
  auto *Node = PDT.getNode(E);
  BasicBlock *Mg = nullptr;
  if (Node && Node->getIDom() && Node->getIDom()->getBlock()) {
    Mg = Node->getIDom()->getBlock();  // standard path — byte-identical today.
  } else {
    // bd 20xt.5 (d) — virtual-root ipdom (an `unreachable`/non-returning exit
    // poisons post-dominance). Retry the merge ignoring unreachable exits. This
    // path fires ONLY where today's code silently bailed (return false above):
    // a standard-ipdom region can NEVER contain a reachable `unreachable` block
    // (a successorless block reachable from E without crossing Mg would
    // contradict Mg post-dominating E), so BOTH this recompute and the E3
    // `UnreachableInst` tolerance are dead code on the standard path. Hence every
    // existing ACCEPT and every real-ipdom DECLINE is byte-identical; the ONLY
    // behaviour change is the virtual-root decline subset, where an
    // unreachable-poisoned region may now flatten (fully E-ladder-gated) — the
    // intended feature — or still leave. (The helper also runs on non-unreachable
    // virtual roots — infinite loops, disjoint multi-ret — but E2 declines the
    // former and `mergeIgnoringUnreachable` returns nullptr for the latter.)
    Mg = mergeIgnoringUnreachable(E);
    if (!Mg)
      return false;
  }
  // bd adia debug lever (env-gated, byte-neutral). CONTRACT (bd oudq): the
  // `gate=<name>` string and the named `entry=`/`merge=` blocks ARE pinned by
  // fixtures (`ir-pass/test/control_predmux_leave_w6_*.ll` check them through
  // `env CQ_PREDMUX_DBG=1 … --check-prefix=DBG`), so renaming a gate is not a
  // byte-neutral cleanup. The trailing `at: <instruction>` operand is NOT
  // contractual and must never be pinned — its SSA slot numbers are unstable
  // run-to-run even for one unchanged plugin (measured on slice_libm_real_coshl:
  // three runs, three different slot numbers, identical lowered IR).
  auto leave = [&](const char *Why, const Instruction *At = nullptr) {
    if (::getenv("CQ_PREDMUX_DBG")) {
      llvm::errs() << "CQ_PREDMUX_DBG: leave @" << E->getParent()->getName()
                   << " entry=" << E->getName() << " merge=" << Mg->getName()
                   << " gate=" << Why;
      if (At)
        llvm::errs() << " at: " << *At;
      llvm::errs() << "\n";
    }
    return false;
  };

  // Collect region blocks: everything reachable from E without crossing Mg.
  R.Entry = E;
  R.Merge = Mg;
  R.InRegion.insert(E);
  SmallVector<BasicBlock *, 16> Work(succ_begin(E), succ_end(E));
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    if (B == Mg || !R.InRegion.insert(B).second)
      continue;
    Work.append(succ_begin(B), succ_end(B));
  }

  // --- W: claim witnesses (anti-overlap with the shipped emitters) ---------
  bool NestedTainted = false;
  for (BasicBlock *B : R.InRegion) {
    if (B == E)
      continue;
    const Instruction *Term = B->getTerminator();
    if ((isa<BranchInst>(Term) && cast<BranchInst>(Term)->isConditional()) ||
        isa<SwitchInst>(Term))
      if (isTaintedCtrlTerm(Term, Taint))
        NestedTainted = true;
  }
  unsigned NumMergePhis = 0;
  unsigned SolePhiIncomings = 0;
  const PHINode *SoleMergePhi = nullptr;
  for (const PHINode &P : Mg->phis()) {
    ++NumMergePhis;
    SolePhiIncomings = P.getNumIncomingValues();
    SoleMergePhi = &P;
  }
  // W4 (Inc 3) — a claimable const-global QROM read inside an arm is its own
  // claim witness: no shipped owner accepts a load-bearing arm (ArmClassify's
  // walkValueChain breaks on LoadInst; the 4.5 data-mux is all-ConstantInt),
  // so claiming the flat read-mux diamond (exp's `ln2HI[xsb]`, the folded
  // jumptable) steals nothing (anti-overlap preserved).
  bool ClaimableRead = false;
  for (BasicBlock *B : R.InRegion) {
    if (B == E)
      continue;
    for (Instruction &I : *B)
      if (auto *LI2 = dyn_cast<LoadInst>(&I))
        if (classifyQromReadUnderControl(LI2, Taint, DT, LInfo,
                                         /*OutCount=*/nullptr,
                                         &R.InRegion) != QromClaim::No) {
          ClaimableRead = true;
          break;
        }
    if (ClaimableRead)
      break;
  }
  bool Claim = false;
  if (isa<SwitchInst>(T)) {
    // Straight-line-arm switches are 4.5 territory (route/value/data-mux/
    // eq-fold) — claim only when an arm hosts further tainted control (or a
    // claimable read, which 4.5 never accepts).
    Claim = NestedTainted || ClaimableRead;
  } else {
    // W5 (bd vyqi) — a br-rooted flat region whose merge holds EXACTLY ONE
    // 2-incoming SCALAR-FP (muxable) phi with DISTINCT incomings: the
    // distilled log10l `z` accumulator diamond/triangle the zco4 promotion
    // exposed. No shipped owner ever ACCEPTS this shape — ArmClassify's 4.2
    // value path categorically declines an fp-typed merge (the fp-angle
    // fence), and every fp-merge shape the swap-route owners DO accept
    // (phase arms, the eq-fold and a8c0 re-anchor diamonds) holds a
    // `cq_phi`/`cq_theta` CALL inside an arm, which E4 excludes from any
    // PredMux claim; the 6.5 classical-call arm is i32-only. The
    // distinct-incomings fence keeps the degenerate empty-arm identity phi
    // (`phi [%q,%arm],[%q,%entry]`, an ACCEPTED empty phase arm) with its
    // owner. INTEGER sole-phi diamonds are not claimed HERE — the 4.2 value
    // emitter owns their accepts (routed method-B), and the two-base integer
    // mux stays the owner-declined 65wb.5 surface; W7 below claims the ONE
    // integer subset that provably has no such owner (a `ConstantInt`
    // straight-through, which no accept path can match). So W5
    // claims only currently-DECLINING shapes: containment (every existing
    // accept byte-identical) holds by construction, and the flattened
    // select is adjudicated by the kjd1 six-gate ladder (angle fence,
    // stale-condition wire guard, phase-carrier/downstream-rotation
    // declines) exactly like every other PredMux-minted select.
    const bool FpSolePhiMux =
        NumMergePhis == 1 && SolePhiIncomings == 2 && SoleMergePhi &&
        SoleMergePhi->getType()->isFloatingPointTy() &&
        isMuxableType(SoleMergePhi->getType()) &&
        SoleMergePhi->getIncomingValue(0) != SoleMergePhi->getIncomingValue(1);
    // W7 (bd 0rwu) — the CONST-FALLTHROUGH INTEGER sole-phi diamond: a flat br
    // region whose merge holds EXACTLY ONE 2-incoming muxable INTEGER phi with
    // DISTINCT incomings, whose ENTRY-edge incoming is a `ConstantInt`, and whose
    // other incoming is an instruction defined in a region INTERIOR block. This
    // is the fdlibm `__isnanl` tail — `s_isnan.c:63`'s
    // `exp == 32767 && (manl != 0 || manh != 0)` short-circuit, which at the f80
    // ship floor is `%isnan = phi i32 [ 0, %entry ], [ %zext, %arm ]` — and it is
    // the ONLY multi-cell compiler lever left in the libm injection census
    // (`expl.f80` + `log10l.f80`), and both reach `opt` exit 0 once the diamond is
    // flattened. MEASURED 2026-07-30 by re-running the full census under both
    // plugins and diffing CELL BY CELL: exactly 2 of the 123 cells changed status,
    // zero regressed. Do NOT restate that as "only 2 cells decline-anchor at
    // ArmClassify.cpp:1171, so the radius is 2" — the Rule-13 round showed that
    // inference is unsound (W7's predicate says nothing about a decline anchor;
    // a W7-shaped diamond declining `non-routable value multiplexer` moves too),
    // and the census bounds the census alone: three committed e2e goldens also
    // moved by claim-order churn, which only the e2e layer surfaced. The gap was never the merge MECHANICS
    // but only the `br`-CFG SPELLING of them: write the SAME two-base integer mux
    // as a tainted `select` and the 4.4/kjd1 controlled-XOR copy merge has lowered
    // it since kjd1. The Rule-13 round made that concrete rather than plausible —
    // it built the `select` spelling of the value-arm fixture's program and the
    // lowered gate stream is IDENTICAL instruction-for-instruction to the
    // flattened `br` spelling's, so a PredMux claim is exactly the missing
    // adapter and W7 reuses the cleared substrate verbatim.
    // (An earlier draft justified this by claiming the same idiom "arrives as a
    // `select` in `nexttowardf` because it fits SimplifyCFG's one-instruction
    // speculation budget". That is FALSE and was refuted in the Rule-13 round:
    // `ld80/s_nexttowardf.c` never calls `isnan` at all — it hand-writes the NaN
    // test as `(iy >= 0x7fff && ((hy|ly) != 0))`, one `or` plus one `icmp`, a
    // DIFFERENT idiom from `__isnanl`'s two OR-ed compares. Do not reinstate it.)
    //
    // W5 above deliberately claimed only the SCALAR-FP sole-phi diamond and left
    // every INTEGER one to the 4.2 value emitter, which owns their accepts. W7
    // re-admits only the subset no shipped `br` owner CAN accept, and — as with
    // every other witness — that disjointness is BY CONSTRUCTION out of
    // `ArmClassify::classifyArms`, not by measurement. Its `Routed` for a diamond
    // is exactly `StraightThrough`, the ENTRY-edge merge incoming, which clause
    // (c) pins to a `ConstantInt`:
    //   * the 4.2 VALUE path requires `Chain.Base == Routed`, but `walkValueChain`
    //     threads only the TAINTED operand of a tainted `BinaryOperator`, so
    //     `Chain.Base` is always a tainted value and never a `ConstantInt` — the
    //     region declines `non-routable value multiplexer`;
    //   * the 4.1 PHASE path requires `Base == Routed` where
    //     `Base = walkPhaseSpine(ArmIncoming, ArmBB)`, and that walk steps ONLY
    //     through IN-ARM `cq_phi_*` calls, which E4 excludes (an external
    //     declaration fails the pure-callee proof). Under clause (d) `Base` is the
    //     interior instruction itself, never a `ConstantInt`;
    //   * `straightThroughConstFoldHandle` (a8c0) is the ONLY path that accepts a
    //     `ConstantInt` straight-through at all, and it demands `H == Base` where
    //     `H` is the non-constant operand of the ENTRY block's equality condition
    //     — hence defined in the entry or earlier, NEVER in an interior block.
    //     *** CLAUSE (d) IS LOAD-BEARING FOR THE *EMPTY*-ARM ROW, WHERE NOTHING
    //     ELSE COVERS IT. *** An a8c0 EMPTY arm (`phi [k, E], [%q, arm]`, arm a
    //     bare `br`) holds no call for clause (e) and nothing for E4 to reject,
    //     and it satisfies (a)-(c) — so without (d) this clause would STEAL A
    //     SHIPPED ACCEPT; measured, that shape compiles today. Pinned from that
    //     side by control_predmux_leave_int_diamond_constfall_prereg.ll. The
    //     NON-empty a8c0 arm and the 4.5 `tryEqFoldArm` twin hold an in-arm
    //     `cq_phi` CALL and are fenced by clause (e)
    //     (control_swap_straightthrough_constfold.ll). Note for whoever edits
    //     this: the Rule-13 round measured that those rows' W7 witness DOES fire,
    //     i.e. they were relying on a single fence, which is why (e) exists and
    //     does not defer to E4;
    //   * the 4.2 IF/ELSE value accept anchors `Routed` on arm 1's chain
    //     PRECISELY BECAUSE it has no entry-edge phi incoming — clause (b)'s
    //     `getBasicBlockIndex(E) >= 0` excludes it (and the pre-existing
    //     control_predmux_leave_int_diamond_solephi.ll pins that direction);
    //   * every CALL-BASED owner — the 6.5 classical-call arm, a bd-adia
    //     pending-specialization call, `lowerControlledIOSinks`' sink call,
    //     `classifyAbortPark`'s noreturn call, and the a8c0 / 4.5 `tryEqFoldArm`
    //     NON-empty arms' in-arm `cq_phi` — is fenced by clause (e) below, WHICH
    //     DOES NOT DELEGATE TO E4. An earlier draft claimed E4 fenced them
    //     ("admits a call only with >= 1 TAINTED argument"); the Rule-13 round
    //     REFUTED that with a reproducer, because E4's first call clause is
    //     taint-blind for curated readnone intrinsics. See clause (e);
    //   * `classifyGuardedStoreArm` needs a STORE, which E4 genuinely does reject
    //     (`isSpeculatableDataflow` is false for a `StoreInst`); `classifyAbortPark`
    //     additionally needs an `unreachable` arm, which leaves `preds(Mg) = {E}`
    //     so no 2-incoming merge phi exists at all, failing clause (a).
    // Switch owners are unreachable from this `br` arm of the witness, and E2
    // excludes every loop owner. So W7, like every other witness, claims only
    // shapes that decline today — with ONE deliberate exception recorded in
    // control_predmux_accept_straightthrough_value_arm.ll: the a8c0 VALUE-arm sibling
    // (`if (q != 0) q1 = q + 1` merged against the folded literal) was an
    // OVER-decline, and it now flattens and lowers. That is a real accept-surface
    // widening inside W7's own shape class, not a leak: the §3c clobber hazard
    // that motivated its decline is a SWAP-ROUTE hazard (route the register in,
    // rewrite it in place, then strip a flag that must re-read the same basis),
    // and the flattened form never rewrites `%q` at all — it writes a FRESH out
    // rail and strips against the untouched `%q`. The Rule-13 round strengthened
    // that from an inspection of one region to a STRUCTURAL fact: E4's region-body
    // walk admits only pure speculatable dataflow (a `StoreInst` fails
    // `isSpeculatableDataflow`; `cq_phi`/`cq_theta` are external declarations that
    // fail the pure-callee proof; every `cq_template_*` is out-of-place), so NO
    // W7-claimed region can write ANY pre-existing rail — the flag-strip operand
    // cone is untouched by construction, for the whole witness class.
    //
    // MEASURED CLAIM-ORDER CHURN — 3 committed e2e goldens moved, and they were
    // REGENERATED DELIBERATELY (bd `8dwo` class; never regenerate a golden by
    // reflex, Rule 12). `slice_libm_real_{erfl,erfcl,sinhl}` inline `olm_expl`
    // ALWAYS_INLINE, so `expl`'s `__isnanl` diamond lands at top level in each and
    // W7 now claims it. Before W7 those regions were LEFT at `W-witness`
    // (measured: erfl left 15 such regions; with W7, ZERO remain) and were then
    // absorbed into a LARGER enclosing `NestedTainted` claim on a later fixpoint
    // round, whose whole-nest edge-predicate algebra is far more expensive than
    // flattening the inner diamonds first. Result: each trace got ~300 lines
    // SHORTER (2480→2182, 2686→2374, 2703→2447). The change was adjudicated, not
    // assumed — for all three: `opt` exit 0, verify-clean, deterministic, ZERO
    // residual `@cq_*`, stage 2b STRICT pass, Rule 5 intact (1 `cqrt_ry_f80` + 1
    // `cqrt_measure_f80`), every compare-stem delta PAIRED with its `_unc` strip,
    // ZERO `cqrt_cswap` in BOTH streams (so no 4.2 method-B accept existed to
    // steal), IDENTICAL `cqrt_copy_{i32,f80}_controlled` counts (same data muxes),
    // and — the decisive check — ZERO arithmetic/data stems differing: every
    // changed stem is flag/conjunction machinery (compare mints+strips,
    // `cqrt_alloc_i1`, `cqrt_toffoli`, `cqrt_cnot`, `cqrt_free`). The computation
    // is byte-identical; only the control ENCODING got cheaper. `coshl` is
    // deliberately unaffected because its `olm_expl` is plain `static` and rides
    // the Phase-6 clone + `claimAll` path instead.
    //
    // *** i1 IS DELIBERATELY EXCLUDED — this is a SCOPE fence, not a soundness
    // one, and it is measured. *** The anti-overlap argument above is
    // width-independent, and an i1 sole-phi const-fallthrough diamond is a real
    // shape (the f64 spelling of this very `__isnanl` tail is
    // `phi i1 [ false, %entry ], [ %lo, %chk ]`). Admitting it is nonetheless
    // wrong for THIS increment on two measured grounds. (1) PAYOFF: zero. The
    // census's f64/f32 isnan prologues already compile; re-measured 2026-07-30,
    // admitting i1 moves no cell that i32 does not already move. (2) COST: i1
    // merge phis are W6's OWN design territory — W6 exists precisely to claim an
    // i1 merge phi that strands a downstream cond tree — so an i1 W7 claim makes
    // two witnesses race for the same region in the most silent-miscompile-prone
    // file in the project. Measured, it CLAIMED the upstream diamond in all four
    // `control_predmux_leave_w6_*` fixtures, which still declined (no
    // over-accept) but with a different string, destroying the "left at
    // `gate=W-witness`" observable those pins are built on — i.e. it would have
    // cost four W6 pins to buy nothing. Claim-order churn of exactly the bd
    // `8dwo` kind, and here it is NOT in the favourable direction. Whoever lifts
    // this must re-pin the W6 family on a different observable first.
    // KNOWN RESIDUAL, filed as bd `tzfg` and deliberately NOT fixed here:
    // `isMuxableType` admits ANY integer width <= 64, but the runtime family is
    // only `cqrt_copy_i{1,8,16,32,64}_controlled`. So an off-family width (i24,
    // i48, ...) CLAIMS, the flatten rewrites the CFG, and the emitter only then
    // declines — which contradicts the E4 width gate's own "a claimed region can
    // never half-lower" comment. Measured harmless (`opt` exit 1, ZERO module
    // bytes written on a DS_Error, so the user sees a plain loud decline), and
    // PRE-EXISTING: the W5 fp path shares the helper. Left to its own increment
    // because a fix moves W5's claim surface too and needs its own Rule-12 pair.
    bool IntConstFallthroughMux = false;
    if (NumMergePhis == 1 && SolePhiIncomings == 2 && SoleMergePhi &&
        SoleMergePhi->getType()->isIntegerTy() &&
        !SoleMergePhi->getType()->isIntegerTy(1) &&
        isMuxableType(SoleMergePhi->getType()) &&
        SoleMergePhi->getIncomingValue(0) != SoleMergePhi->getIncomingValue(1)) {
      // (b) DIAMOND: the merge is a direct successor of the entry, so the phi
      // carries an entry-edge incoming — `ArmClassify`'s `StraightThrough`.
      const int EIdx = SoleMergePhi->getBasicBlockIndex(E);
      // (c) that incoming is a `ConstantInt` — the whole disjointness argument.
      if (EIdx >= 0 && isa<ConstantInt>(SoleMergePhi->getIncomingValue(EIdx))) {
        // (d) the other incoming is defined in a region INTERIOR block. A
        // degenerate `br i1 %c, label %Mg, label %Mg` leaves BOTH incoming
        // blocks equal to `E`, so `getParent() != E` rejects it here too (and
        // `R.InRegion == {E}` rejects it independently).
        auto *OtherI = dyn_cast<Instruction>(
            SoleMergePhi->getIncomingValue(EIdx == 0 ? 1 : 0));
        IntConstFallthroughMux = OtherI && OtherI->getParent() != E &&
                                 R.InRegion.count(OtherI->getParent()) != 0;
        // (e) NO CALL anywhere in the region INTERIOR — the anti-overlap fence
        // for every CALL-BASED owner, and it must NOT be delegated to E4.
        //
        // *** THIS CLAUSE EXISTS BECAUSE THE RULE-13 ROUND REFUTED THE FIRST
        // DRAFT'S CONTAINMENT ARGUMENT WITH A WORKING REPRODUCER. *** That draft
        // fenced the 6.5 classical-call arm by claiming "E4 admits a call only
        // with >= 1 TAINTED argument". E4 does no such thing: its call handling
        // (see `isCuratedReversibleIntrinsic(CI) && CI->doesNotAccessMemory()`
        // below) has a FIRST, TAINT-BLIND clause that admits any curated readnone
        // intrinsic — `bswap bitreverse fshl fshr ctpop ctlz cttz abs
        // smin smax umin umax *_sat lrint llrint` + the fp keep-set — regardless
        // of its arguments' taint. An ALL-CLASSICAL curated intrinsic in the arm
        // is EXACTLY `classifyClassicalCallArm`'s admission criterion, so without
        // this clause W7 and the 6.5 owner both claim it and W7 wins: measured on
        // `if (q > 5) y = llvm.smax(x, 11);` merged against a folded literal, both
        // plugins exit 0 but emit DIFFERENT streams (inverted flag predicate,
        // swapped copy order) — a trace-observable stolen accept. Every shipped
        // 6.5 accept fixture already satisfies (a)-(d) and survives only because
        // its callee is an external `declare`; swap one for `@llvm.bswap.i64` and
        // the theft reproduces. Two further decline->accept flips rode the same
        // hole: the 6.5 WI-5.8 arm-size fence (`Region.Arm->size() != 2`, which
        // deliberately declines a larger arm because the flatten would ERASE the
        // extra instruction) was bypassed, reachable from ordinary C at -O1 via
        // `if (q > 5) y = __builtin_popcountll(t);`; and a bd-adia
        // pending-specialization call as the arm's merge value flipped to an
        // accept that routes quantum data through a Phase-6 Bennett clone.
        // No wrong unitary was found in any of them — but a stolen accept is a
        // silent GOLDEN divergence and a scope widening past this increment's
        // reviewed surface, and the Prime Directive says narrow.
        //
        // Interior-only is the right scope: `E`'s instructions are never
        // speculated or erased, and `classifyClassicalCallArm` requires its call
        // in the ARM. This subsumes what the draft wrongly attributed to E4 — the
        // a8c0 / 4.5 `tryEqFoldArm` NON-empty arms (an in-arm `cq_phi` CALL,
        // whose W7 witness genuinely does fire, so E4 was their single point of
        // failure), `lowerControlledIOSinks`' sink call, and `classifyAbortPark`'s
        // noreturn call — and it costs the target cells nothing: `__isnanl`'s arm
        // is `and`/`icmp`/`or`/`zext`, call-free by construction.
        if (IntConstFallthroughMux)
          for (BasicBlock *B : R.InRegion) {
            if (B == E)
              continue;
            for (Instruction &I : *B)
              if (isa<CallInst>(&I)) {
                IntConstFallthroughMux = false;
                break;
              }
            if (!IntConstFallthroughMux)
              break;
          }
      }
    }
    // W6 (bd oudq) — the MERGE block's own TAINTED conditional branch reads one
    // of the merge's i1 phis as an and/or cond-tree NODE. That downstream region
    // (rooted at `Mg`) can NEVER be claimed while the phi lives: rule (A)
    // condition 2 refuses a phi whose parent is the region ENTRY, because
    // `RegionFlattener::run()` skips the entry — so `isSupportedCondTree` cannot
    // build its false-edge literal and it leaves at `E6-condtree` forever
    // (nothing else in the pipeline removes an entry phi). Claiming THIS region
    // is the fix: the phi is a MERGE phi here, `convertPhis(R.Merge)` rewrites it
    // to the Inc-2 boolean algebra ∨ᵢ(EPᵢ ∧ vᵢ), and the downstream branch becomes
    // an ordinary cond tree over compare leaves on the next fixpoint round. This
    // is the fdlibm `__isnanl` early-exit chain — `s_isnan.c:63` inlined, which
    // at the log1pl.f80 ship floor is `%16 = phi i1 [ false, %0 ], [ %14, %10 ]`
    // OR-ed into `isinf || iszero` in that same block — and it is what blocks
    // log1pl/log2l/logl.f80.
    //
    // ANTI-OVERLAP (the W witness' whole job) holds by construction, not by
    // measurement: a br region whose MERGE ends in a tainted conditional branch
    // is categorically DECLINED by every shipped br owner. `ControlDetect`'s
    // `recoverRegion` tests `hasTaintedCondBranch` on BOTH successors before any
    // shape match — and a diamond's merge IS a successor of the entry — then
    // repeats the test explicitly on the if/else merge `M`; either way it returns
    // `RegionShape::Nested`, and `recoverRegionTree` declines it too — as a
    // PROOF, not a shape observation (the Rule-13 judge's strengthening):
    // `isConvertiblePhiCond` demands ≥ 2 UNIQUE incoming blocks, so W6 can only
    // fire when `Mg` has ≥ 2 predecessors, and the merge-as-`Mid` candidate's
    // `getSinglePredecessor()` is therefore structurally null. When no interior
    // block carries a tainted branch it declines one criterion earlier still, at
    // `T0 == T1` — what that function's own comment calls the "sequential
    // if/else; if" case. The same ≥ 2-predecessor fact makes W6 disjoint from the
    // abort park by construction: an `unreachable` arm leaves `preds(Mg) = {E}`,
    // so no merge phi can have two unique incoming blocks at all.
    // `classifyAbortPark` and `classifyGuardedStoreArm` run BEFORE
    // `recoverRegion` and require a noreturn-sink CALL / a STORE, neither of
    // which E4 admits; `classifyClassicalCallArm` runs AFTER it, i.e. only on a
    // Diamond/IfElse whose merge `recoverRegion` has already proven does NOT end
    // in a tainted cond branch. The two tainted-`br` owners OUTSIDE that family
    // are fenced independently, and by something other than this witness (both
    // verified by probe in the same round): `lowerControlledIOSinks` needs its
    // arm's recognized SINK CALL, which E4 excludes (a declaration fails the
    // pure-callee proof); and a loop-header merge always has a latch predecessor
    // outside the region, so the region leaves at `E3-mergepred` — AFTER this
    // witness, not before it (two delta lenses caught an earlier draft asserting
    // the opposite ordering; the conclusion is unaffected because the whole
    // E-ladder runs before anything is emitted, but this file is the primary
    // written record). So W6 claims only shapes that decline today.
    // DELIBERATELY NARROW: gated on the phi actually CONVERTING to boolean
    // algebra (a select-chain phi would leave the downstream branch just as
    // unclaimable) and on the phi being read at a cond-tree NODE (an i1 phi
    // behind an `icmp` is an opaque leaf that never stranded anything). NOTE what
    // that does and does not buy (Rule-13 lens 7, with a reproducer): it removes
    // the reason the downstream branch is UNUSABLE, but it does not make the
    // downstream region claimable — that region may still leave on its own
    // W-witness, in which case the only visible change is which decline fires.
    // Claim-order churn of exactly the bd `8dwo` kind is therefore possible here;
    // measured, it is in the favourable (shorter-stream) direction.
    //
    // HOW THE STRANDING IS TESTED — by asking the DOWNSTREAM question itself,
    // not a proxy for it (bd oudq Rule-13, lens 3: the first draft used a
    // hand-rolled tree walk that was strictly more permissive than
    // `isSupportedCondTree` — general `select i1`, off-grammar SIBLINGS, no
    // `coneDefinedAfterFlagDrop`, its own depth budget — and measurably fired
    // ~7:1 against the one stranding it exists to unblock, churning three
    // already-verified goldens for nothing). Run the SHIPPED predicate twice
    // over `Mg`'s branch condition, with scopes that differ in exactly one
    // thing — whether a phi of `Mg` counts as convertible:
    //   * `Convertible` (no entry fence): does the condition become a supported
    //     cond tree once this claim converts `Mg`'s phis?
    //   * `Downstream` (entry fence = `Mg`, i.e. the scope the region rooted at
    //     `Mg` will build for itself): is it supported WITHOUT that conversion?
    // `Convertible && !Downstream` therefore says precisely "a phi of `Mg` is
    // what makes the downstream condition unusable, and converting it is what
    // makes it usable" — Rule 14, one question with one answer, so the claim
    // cannot drift from the E6 gate it is predicting. Everything the old walk
    // over-admitted collapses out: a non-phi off-grammar node fails BOTH calls,
    // a phi behind an `icmp` (the q2wk shield) passes BOTH, and a phi whose
    // incomings leave the strict `isBooleanCondTree` grammar — i.e. one
    // `convertPhis` would send down its select-CHAIN path — fails the first.
    //
    // *** THE `BranchInst` TEST BELOW IS LOAD-BEARING, NOT A CONVENIENCE. *** The
    // anti-overlap argument rests on `ControlDetect`'s `hasTaintedCondBranch`,
    // which is `dyn_cast<BranchInst>` + `isConditional()` + tainted — it is FALSE
    // for a block ending in a tainted `switch`. Generalizing this to the
    // switch-aware `isTaintedCtrlTerm` (used one screen up, so the edit looks
    // harmless) would silently void the whole paragraph above: a merge ending in
    // a tainted switch is 4.5 `SwitchClassify` territory, NOT a categorical
    // decline. That shape is a deliberate residual, filed as bd `ih70`.
    bool StrandedCondPhi = false;
    if (auto *MgBI = dyn_cast<BranchInst>(Mg->getTerminator()))
      // `Mg` phi-less ⇒ the two scopes are indistinguishable (no phi node is
      // reachable, so nothing scope-sensitive fires), both calls return the same
      // value and the conjunction is false — skip two unmemoized depth-8 walks
      // that can descend whole callee bodies through `coneDefinedAfterFlagDrop`.
      // Behaviour-identical by that argument, not by measurement.
      if (MgBI->isConditional() && !Mg->phis().empty() &&
          Taint.Tainted.count(MgBI->getCondition())) {
        // Scope block set = {Mg} alone. A phi of a region-INTERIOR block cannot
        // appear in `Mg`'s condition cone anyway: it would have to dominate
        // `Mg`, hence post-dominate `E`, making IT — not `Mg` — the immediate
        // post-dominator (lens 3's dead-code argument), so the merge's own phis
        // are the entire reachable surface.
        SmallPtrSet<BasicBlock *, 1> MergeOnly;
        MergeOnly.insert(Mg);
        const PhiCondScope Convertible{&MergeOnly, /*Entry=*/nullptr, nullptr};
        const PhiCondScope Downstream{&MergeOnly, /*Entry=*/Mg, nullptr};
        StrandedCondPhi =
            isSupportedCondTree(MgBI->getCondition(), 0, &Convertible) &&
            !isSupportedCondTree(MgBI->getCondition(), 0, &Downstream);
      }
    Claim = NestedTainted || ClaimableRead || NumMergePhis >= 2 ||
            (NumMergePhis == 1 && SolePhiIncomings > 2) || FpSolePhiMux ||
            IntConstFallthroughMux || StrandedCondPhi;
  }
  // ClaimAll (5po2 I2): inside a Bennett clone the anti-overlap witness is
  // irrelevant (no top-level emitter runs there), so claim ANY acyclic SESE
  // tainted value region — incl. the 2-incoming single-guard diamond a
  // normalized single-early-return reduces to. The E2/E3/E4 gates below still
  // apply, so a claimed region can never half-lower.
  if (!ClaimAll && !Claim)
    return leave("W-witness");

  // --- E2: acyclic, not in/around a loop ------------------------------------
  for (BasicBlock *B : R.InRegion)
    if (OnCycle.count(B))
      return leave("E2-cycle");

  // --- E3: single-entry / single-exit ---------------------------------------
  for (BasicBlock *B : R.InRegion) {
    const Instruction *Term = B->getTerminator();
    // bd 20xt.5 (d) — an `unreachable` arm terminator is TOLERATED: it is a
    // dead sink (UB in the source, no basis state enters it — Rule 5), erased
    // by the flatten with NO merge-phi incoming (it has no successors, so no phi
    // lists it). Its body (if any): an impure instruction (store/non-curated
    // call) is excluded by E4 below (→ leave); a pure instruction is hoisted by
    // `moveBody` but is provably dead — a successorless block dominates nothing
    // outside itself, so its SSA values have zero external uses — and `sweepDead`
    // erases the whole cone before `lowerOps` (Rule-13 clearance: verified inert
    // on a non-empty pure dead body; `control_predmux_accept_unreachable_dead_body.ll`).
    // `ret`/`indirectbr`/`invoke`/`callbr` remain real multi-exits and still leave.
    if (!isa<BranchInst>(Term) && !isa<SwitchInst>(Term) &&
        !isa<UnreachableInst>(Term))
      return leave("E3-multiexit", Term);  // ret/invoke/… inside: multi-exit
    for (const BasicBlock *S : successors(B))
      if (S != Mg && !R.InRegion.count(S))
        return leave("E3-escape", Term);  // escapes the region without reconverging
    if (B == E)
      continue;
    for (const BasicBlock *P : predecessors(B))
      if (!R.InRegion.count(P))
        return leave("E3-sideentry");  // side entry
  }
  for (const BasicBlock *P : predecessors(Mg))
    if (!R.InRegion.count(P))
      return leave("E3-mergepred");  // a reaching edge PredMux does not predicate

  // --- E4 + E6 + E7 over the region body ------------------------------------
  // Inc 5 (bd q2wk) — the claim-time phi context (PRD §4.4b rule (A)).
  const PhiCondScope Scope{&R.InRegion, R.Entry, &R.BoolAlgPhis};
  for (BasicBlock *B : R.InRegion) {
    // E6: every conditional terminator tainted, with an invertible condition.
    const Instruction *Term = B->getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(Term)) {
      if (BI->isConditional()) {
        // bd adia (3c6m.55 Lever C): a CONSTANT-condition br (a fold residue the fp80
        // promotion or an earlier flatten materialized late) is degenerate —
        // no runtime classical/quantum mixing; the literal machinery folds
        // ∧true/∧false natively (isSupportedCondTree admits ConstantInt).
        //
        // bd q2wk (Inc 5, PRD §4.4b rule (B)): a condition the FLATTEN ITSELF
        // will taint is not classical control either — it is the region's own
        // tainted decision re-materialized. Every region edge predicate is
        // tainted (the entry terminator is tainted by construction), so a
        // region-internal-phi-derived condition becomes tainted the moment
        // `convertPhis` rewires that phi onto the edge predicates. This is the
        // all-constant `phi i1 [true,%a],[false,%b],[false,%entry]` clang -O1
        // emits for a short-circuit it did not if-convert (log1p's
        // `hx > 0 || hx <= 0xbfd2bec4`), and hypotf's `icmp eq i32 %k, 0` over
        // the phi-merged scale accumulator. SHARED predicate with the Inc-3
        // QROM index gate (Rule 14) — one question, one answer — and `R.Entry`
        // is passed so the two phi shapes the flatten does NOT convert to a
        // tainted value (an ENTRY-block phi; a phi whose incoming values are
        // all one Value) answer honestly instead of on a false promise.
        //
        // WHERE THE RESIDUAL ACTUALLY LANDS, corrected by the q2wk Rule-13
        // round (the original claim here named the wrong guard): a condition
        // that nonetheless stays classical does NOT become a classical-condition
        // select, because every edge predicate is `and(BP, lit)` with BP derived
        // from the tainted entry condition — so the select condition is tainted
        // and `declineClassicalMuxes` can never fire. The classical value
        // survives as an UNTAINTED COMPARE LEAF inside a tainted cond tree, and
        // the load-bearing backstop is `SelectClassify`'s GATE-2 per-leaf taint
        // check, which declines `control flow under quantum control`. That gate
        // is explicitly staged for a future "hybrid classical∧quantum
        // conjunction" widening — whoever lifts it MUST re-derive this
        // argument. And the decline is not universal: a region that mints no
        // select (an i1 merge phi takes the boolean-algebra path) compiles
        // silently, which is SOUND only because a classical runtime operand
        // occupies the sanctioned `_hl` literal slot and is never promoted to a
        // qubit handle (the §5.2 non-negotiable). The SWITCH scrutinee gate
        // below is deliberately NOT widened: no measured cell needs it and
        // over-declining is safe.
        if (!Taint.Tainted.count(BI->getCondition()) &&
            !isa<ConstantInt>(BI->getCondition()) &&
            !valueWillTaintAfterFlatten(BI->getCondition(), Taint, R.InRegion,
                                        R.Entry))
          return leave("E6-classicalbr", BI);  // classical control inside a tainted region: mixed
        if (!isSupportedCondTree(BI->getCondition(), 0, &Scope))
          return leave("E6-condtree", BI);
      }
    } else if (const auto *SI = dyn_cast<SwitchInst>(Term)) {
      if (!Taint.Tainted.count(SI->getCondition()))
        return leave("E6-classicalswitch", SI);
      Type *ScrTy = SI->getCondition()->getType();
      if (!isMuxableType(ScrTy))
        return leave("E6-switchwidth", SI);  // eq/ne flags must be mintable at this width
    }
    if (B == E)
      continue;  // E's own instructions are not moved
    for (Instruction &I : *B) {
      if (isa<PHINode>(I)) {
        if (!isMuxableType(I.getType()))
          return leave("E7-phi", &I);  // E7
        continue;
      }
      if (I.isTerminator())
        continue;
      // E4' (Inc 3) — a claimable const-global QROM read (and its single-use
      // address gep) is speculatable dataflow: the table is immutable, the
      // width has a qram cell, and the index is provable or pow2-maskable
      // (`classifyQromReadUnderControl` — the SAME predicate the carve
      // defers on, so claim and carve can never diverge). A NeedsMask read
      // is recorded for the flatten to rewrite its gep index. Every other
      // load — and any volatile/atomic access (isSimple gates them) — leaves.
      if (auto *LI2 = dyn_cast<LoadInst>(&I)) {
        uint64_t Count = 0;
        // bd 20xt.5.2: `ClaimAll` is the Bennett-clone signal (set only by
        // `lowerCloneControl`); it bypasses the coherent-escape fence so an
        // arm-resident QROM read whose value flows to the clone ret is claimable
        // (the wrap copies-out + reverse-plays the whole stream — the same bypass
        // `lowerQramReads(inBennettClone=true)` applies at the emitter, Rule 14).
        bool IndexBecomesOpaque = false;
        QromClaim QC = classifyQromReadUnderControl(
            LI2, Taint, DT, LInfo, &Count, &R.InRegion,
            /*inBennettClone=*/ClaimAll, &IndexBecomesOpaque);
        if (QC == QromClaim::No)
          return leave("E4-load", &I);
        // bd 20xt.7: a PROVABLE clone read on a pow2 table whose index BECOMES
        // OPAQUE after the flatten ALSO gets the (identity) mask, not only a
        // NeedsMask one. `and idx, N-1` is the IDENTITY on a provable-in-bounds
        // index (Provable ⟹ known-bits max < N = 2^k ⟹ idx fits in k bits ⟹
        // `and idx, N-1` == idx at runtime), so it is semantically inert — its SOLE
        // effect is to carry the flatten's bounds proof to the EMITTER. The index
        // becomes opaque iff it is region-internal-phi-derived (currently untainted,
        // admitted only via `indexWillTaintAfterFlatten`): the flatten +
        // `lowerCloneSelect` lower it to a `cqrt_alloc_i64` handle whose known-bits
        // `lowerQramReads`' `qromIndexKnownInBounds` re-proof cannot see, so it would
        // else loud-decline `kMsgQramCloneUnbounded` (a safe-but-confusing claim/emit
        // divergence). A CURRENTLY-TAINTED Provable index (a source `& 3` straight-
        // line computation) keeps its RAW op at the gep, which the emitter re-proves
        // directly — masking THAT would be a redundant double-`and` that drifts its
        // golden (Rule 14; the e2e slice_spec_qrom_read_arm_escape regression this
        // guard fixes). Gated on `ClaimAll` (clone-only): a top-level Provable read
        // is a faithful source access, bounds the source's obligation, left UNMASKED.
        // A non-pow2 Provable clone read stays unmasked here and, in a clone, still
        // declines at the emitter (rare; the safe residual over-decline).
        if (QC == QromClaim::NeedsMask ||
            (QC == QromClaim::Provable && ClaimAll && IndexBecomesOpaque &&
             Count != 0 && isPowerOf2_64(Count)))
          R.MaskLoads.push_back({LI2, Count});
        continue;
      }
      if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        if (GEP->hasOneUse())
          if (auto *LU = dyn_cast<LoadInst>(GEP->user_back()))
            if (LU->getPointerOperand() == GEP &&
                classifyQromReadUnderControl(LU, Taint, DT, LInfo,
                                             /*OutCount=*/nullptr, &R.InRegion,
                                             /*inBennettClone=*/ClaimAll) !=
                    QromClaim::No)
              continue;  // the claimable read's address gep (load re-checked).
        return leave("E4-gep", &I);
      }
      // bd adia (Lever C) — a PENDING-SPECIALIZATION call is speculatable
      // dataflow: DIRECT, ≥1 TAINTED argument (an all-classical pure call in
      // an arm stays with its 6.5 classical-call-arm owner — anti-overlap),
      // a template-width result, and a callee body passing the pure/acyclic/
      // all-speculatable proof (a pure total terminating function of its
      // arguments — the same class Phase-6 clones; under quantum control the
      // call executes on every basis state, exactly as every other
      // speculated arm op). An off-proof call still excludes the region.
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (isCuratedReversibleIntrinsic(CI) && CI->doesNotAccessMemory())
          continue;
        bool TaintedArg = false;
        for (Value *A : CI->args())
          if (Taint.Tainted.count(A)) {
            TaintedArg = true;
            break;
          }
        //
        // CLONE MODE IS DELIBERATELY NOT FENCED HERE (bd 3c6m.14.1) — this line
        // has no `ClaimAll` gate and that is a DECISION, not an oversight. The
        // pure-callee proof now admits an i80 `_hl` compare, so as of that
        // increment this site accepts, in BOTH contexts, a call whose callee
        // carries one. MEASURED before deciding, against a pinned pre-change
        // plugin: the shape is reachable in clone mode (fixture
        // accept_i80_cmp_purecallee_clonecall.ll — the region claimed inside
        // `@__cq_q_mid_1` and the compare landed in the transitively-specialized
        // `@__cq_q_inner_1`).
        //
        // The reason it is not fenced, in one sentence: the callee's compare
        // NEVER ENTERS THIS REGION'S FLATTENED PROGRAM — only the CALL moves —
        // so the walk's own top-level/clone context is causally unrelated to how
        // that compare is lowered, and a `!ClaimAll` here would be a fence with
        // no correctness content. The compare's lowering obligation is
        // discharged where it lives, by the callee's own clone, under gates that
        // still bite: straight-line it lowers to the frozen
        // `cq_template_icmp_<pred>_i80_hl` (a shape that already lowers today
        // with NO region involved — measured on the pre-change plugin); inside
        // the callee's OWN tainted diamond it hits the `!ClaimAll` bare-compare
        // fence one screen down and loud-declines. Both pinned, and the second
        // one was reproduced on real C as well as on hand-written IR.
        //
        // A THIRD discharge path exists and the first draft of this comment did
        // not name it (found by the Rule-13 clone-mode lens): if the callee takes
        // a TAINTED argument of a width the specialization ABI cannot carry —
        // i80 among them — the proof passes, the ClaimAll region claims AND
        // FLATTENS, and only then does `SpecializeReject`'s site-ABI gate
        // decline. That is a post-mutation decline, and it is PRE-EXISTING
        // (reachable on the pre-change plugin through a compare-free i80-arg
        // callee), but this widening enlarges its reachable set. Filed, not
        // fixed here — see the bd follow-up; do not read the two paths above as
        // exhaustive.
        //
        // This does NOT lift that bare-compare fence below, and the asymmetry is
        // real but principled: there the compare joins the clone's select
        // program, here it does not. `reject_i80_cmp_clonemode.ll` still
        // declines, with a byte-identical message, DBG leave line and exit code
        // (diffed, not assumed).
        if (TaintedArg && isTemplateWidthType(CI->getType()) &&
            isSpeculatablePureCalleeBody(CI->getCalledFunction()))
          continue;
        return leave("E4-dataflow", &I);
      }
      // The `!ClaimAll` half of the `AdmitI80Compare` story (bd 3c6m.61), and
      // as of bd 3c6m.14.1 the ONLY site that still passes anything but `true`:
      //
      //  * `recoverRegion` runs in TWO contexts, the TOP-LEVEL region flatten
      //    and the `ClaimAll` Bennett-CLONE body flatten (threaded from
      //    `Specialization.cpp`). Only the top-level one is in scope and only
      //    it has an i80 fixture family, so clone mode keeps the old blanket
      //    exclusion.
      //  * The pure-callee proof above now passes TRUE (bd 3c6m.14.1) — it
      //    answers "pure + total", not "speculatable into THIS select program",
      //    and its compare never reaches this region. That is a different
      //    clause, not a lift of this one; see the call-admission note above.
      //
      // THE CLONE CONTEXT IS REACHABLE — do not re-derive otherwise. A first
      // draft of this comment claimed it was unreachable and listed three
      // measured fences (fp80 args laundered to i32 handles; the fp-copy
      // specialization fence; the quantum-lift fence). The Rule-13 JUDGE
      // falsified all three with one probe that evades them simultaneously: an
      // i32 parameter (no fp80 anywhere), i80 reached via the in-grid
      // `zext i32 -> i80`, inside a callee carrying its own tainted diamond.
      // Un-gated, that CLAIMED in clone mode and emitted
      // `cq_template_icmp_eq_i80_hl` + its `_unc` inside `@__cq_q_leaf_1`.
      // The judge audited that emission and found it SOUND — so this gate is a
      // SCOPE decision, not a correctness one: it is a new accept surface in
      // the Phase-6 clone + Bennett-wrap path rather than the reviewed select
      // substrate, and Rule 12 wants its own probe family before it ships.
      // bd 3c6m.14.1 CONSIDERED AND KEPT IT (that ticket scopes (A)+(B) only;
      // this is the bare-compare-into-a-clone-select-program axis, a different
      // construct from the widened pure-callee CALL). Pinned by
      // control_predmux_reject_i80_cmp_clonemode.ll, which after 3c6m.14.1 still
      // declines with a byte-identical message, DBG line and exit code.
      //
      // NOTE FOR WHOEVER LIFTS THIS: that is now TWICE this clause has carried
      // a false "this shape cannot occur here" claim — the first being "the
      // canonical promotion never puts those inside an arm", which hypotl
      // falsified and which is the entire reason bd 3c6m.61 exists. Measure;
      // do not reason about reachability here.
      if (!isSpeculatableDataflow(I, /*AdmitI80Compare=*/!ClaimAll))
        return leave("E4-dataflow", &I);  // E4
    }
  }
  // E7 for the merge phis (they all convert: preds(Mg) ⊆ region).
  for (const PHINode &P : Mg->phis())
    if (!isMuxableType(P.getType()))
      return leave("E7-mergephi", &P);

  return topoOrderRegion(R);
}

// ---------------------------------------------------------------------------
// The flatten
// ---------------------------------------------------------------------------

class RegionFlattener {
public:
  RegionFlattener(PredMuxRegion &R, IRBuilder<> &B) : R(R), B(B) {}

  void run() {
    // Process arm blocks in topological order: convert phis to select
    // chains, then move the straight-line body before the entry terminator.
    for (BasicBlock *D : R.Topo) {
      if (D == R.Entry)
        continue;
      convertPhis(D);
      moveBody(D);
    }
    convertPhis(R.Merge);
    // Inc 3 — mask the NeedsMask reads' gep indices (`and idx, N-1`): the
    // speculated read must be in-bounds on EVERY basis state. The mask is the
    // IDENTITY exactly on the in-bounds indices (idx ∈ [0,N)); it only changes
    // an OUT-OF-BOUNDS index — and `tbl[idx]` out of bounds is UB in the source,
    // so that basis state is obligation-free (the original program had no
    // defined result to preserve). Soundness thus rests on OOB-read-is-UB, not
    // on the guard bounding the index (the guard may be unrelated to it); the
    // masked garbage-row value, where it survives the merge predicate, only ever
    // replaces an undefined one. The claim gate (classifyQromReadUnderControl)
    // keeps the index at the pointer-index width, so `and idx, N-1` (N ≤ 2^63)
    // yields a non-negative in-range offset for every bit pattern. Inserted AT
    // the (already-moved) gep so the index dominates textually; the And is
    // tainted by the caller's re-propagate and lowers as an ordinary hl template.
    for (auto &ML : R.MaskLoads) {
      auto *GEP = cast<GetElementPtrInst>(ML.first->getPointerOperand());
      unsigned IdxNo = GEP->getNumOperands() - 1;
      Value *Idx = GEP->getOperand(IdxNo);
      IRBuilder<> MB(GEP);
      MB.SetCurrentDebugLocation(GEP->getDebugLoc());
      Value *Masked = MB.CreateAnd(
          Idx, ConstantInt::get(Idx->getType(), ML.second - 1));
      GEP->setOperand(IdxNo, Masked);
      track(Masked);
    }
    // Entry terminator → unconditional branch to the merge; erase the arms.
    // The entry terminator's own condition/scrutinee joins the sweep set (a
    // Rule-13 clearance follow-up): it normally stays live as a predicate
    // leaf, but if every consuming edge-predicate was dead-swept it would
    // otherwise linger as a dead tainted producer for lowerOps to lower.
    Instruction *T = R.Entry->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional())
        track(BI->getCondition());
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      track(SI->getCondition());
    }
    B.SetInsertPoint(T);
    B.CreateBr(R.Merge);
    T->eraseFromParent();
    for (BasicBlock *D : R.Topo)
      if (D != R.Entry)
        D->dropAllReferences();
    for (BasicBlock *D : R.Topo)
      if (D != R.Entry)
        D->eraseFromParent();
    sweepDead();
  }

private:
  PredMuxRegion &R;
  IRBuilder<> &B;
  DenseMap<BasicBlock *, Value *> BlockPred;   // nullptr = ⊤ (entry)
  DenseMap<std::pair<BasicBlock *, unsigned>, Value *> LitCache;
  SmallVector<WeakTrackingVH, 32> MaybeDead;

  // lit(e) for successor slot Idx of S's terminator: the branch condition in
  // the taken polarity (false edges via leaf-inverted De Morgan negation) or
  // the switch case-equality (default = ∧ of ne). Memoized per (S, Idx).
  Value *literal(BasicBlock *S, unsigned Idx) {
    auto Key = std::make_pair(S, Idx);
    auto It = LitCache.find(Key);
    if (It != LitCache.end())
      return It->second;
    Instruction *Term = S->getTerminator();
    Value *L = nullptr;
    if (auto *BI = dyn_cast<BranchInst>(Term)) {
      assert(BI->isConditional() && "unconditional edge has no literal");
      L = Idx == 0 ? canonicalizePred(BI->getCondition())
                   : buildNegation(BI->getCondition());
    } else {
      auto *SI = cast<SwitchInst>(Term);
      if (Idx == 0) {  // default: ∧ of (scrut != case_k)
        for (const auto &Case : SI->cases()) {
          Value *Ne = B.CreateICmpNE(SI->getCondition(), Case.getCaseValue());
          track(Ne);
          L = L ? track(B.CreateAnd(L, Ne)) : Ne;
        }
        if (!L)  // a switch with no cases is an unconditional edge
          L = ConstantInt::getTrue(SI->getContext());
      } else {
        ConstantInt *CV = SI->case_begin()
                              .operator+(Idx - 1)
                              ->getCaseValue();
        L = track(B.CreateICmpEQ(SI->getCondition(), CV));
      }
    }
    LitCache[Key] = L;
    return L;
  }

  // bd adia (Lever C): drop the poison-generating annotations over the backward
  // cone of a select-form's SHIELDED operand. The rewrite below turns
  // `select(a,b,false)` into `and(a,b)`: in the ORIGINAL program `b` is never
  // observed when `a` is false (the clang short-circuit shield), so a poison `b`
  // on an a=false basis state was harmless there but would poison the rewritten
  // `and`. The claim-time proof `coneDefinedAfterFlagDrop` already restricted
  // the cone to ops that are TOTAL once the annotations are gone; this performs
  // the drop, so the cone is then defined on every basis state.
  //
  // bd u1rp — WHAT CHANGED, AND WHY BOTH HALVES HAD TO CHANGE TOGETHER.
  //
  // HALF 1, THE WALK. This used to be an independent walk over `I->operands()`
  // with no leaf cases at all, so it EXCEEDED the proof's walk: it recursed past
  // the `cq_theta`/`cq_phi` leaf — where the proof stops WITHOUT operand
  // recursion — into the classical seed subtree and mutated instructions the
  // whitelist refuses and the proof never visited. MEASURED on the pre-change
  // plugin: `%seed = add nsw nuw i32 %u, 1` feeding `cq_theta_si32` came out
  // `%seed = add i32 %u, 1`. It now walks `classifyConeNode` — the SAME
  // classification the proof reads — and mutates exactly the `Interior` set:
  // the nodes whose admission was conditional on this drop. `Leaf` nodes are
  // defined WITHOUT a drop, so skipping them loses nothing; `PassThrough`
  // (`cq_phi`) is FOLLOWED to operand 0, which is where its value actually comes
  // from; `Fail` cannot occur on a claimed cone, and mutating it would not
  // rescue an inherent-poison op anyway (there is no flag to drop on a
  // variable-amount shift).
  //
  // *** THE FIRST DRAFT OF THIS NARROWING GOT THAT WRONG AND A RULE-13 ROUND
  // MEASURED IT. *** It treated `cq_phi` as a `Leaf` too, on the strength of the
  // same "defined without a drop" sentence — but `cq_phi`'s value IS operand 0,
  // so the sentence is false there. Measured regression on that draft:
  // `%bad = add nsw nuw i32 %c, %d` one `cq_phi` hop below the shielded compare
  // came out flag-STRIPPED on the pre-change plugin and flag-BEARING on the
  // draft. `PassThrough` is what makes the sentence true again, by making
  // `cq_phi` not a leaf in the first place. Do not re-flatten it back to `Leaf`.
  //
  // HALF 2, THE DROP. This used to call only `dropPoisonGeneratingFlags()` +
  // `dropPoisonGeneratingMetadata()` — TWO of LLVM 19's THREE families named by
  // `hasPoisonGeneratingAnnotations()`; the third is CALL RETURN ATTRIBUTES
  // (`range`/`nonnull`/`align`). That gap is REACHABLE and it breaks the claim's
  // literal promise: a CLASSICAL curated intrinsic in a MIXED compare leaf
  // (`icmp sgt i32 %q_tainted, %r_classical`) is neither replaced by a
  // `cq_template_*` nor declined downstream — it survives verbatim into the
  // emitted module, attribute and all. MEASURED on real C: `clang -O1` on
  // `q > 3 && q > __builtin_popcount(c)` with a two-merge-phi arm emits
  // `tail call range(i32 0, 33) i32 @llvm.ctpop.i32` inside a genuine shielded
  // diamond, and the pre-change plugin keeps the `range` while this one drops
  // it. A lying `range` makes the call return POISON, which is precisely what
  // the proof promised the drop would remove, so the wider drop is a soundness
  // obligation and not tidiness — though note that every `range` clang actually
  // emits is a TRUE range, so in practice this is defence in depth.
  //
  // A CITATION THAT DOES NOT HOLD, recorded so it is not restored: an earlier
  // draft cited openlibm `sqrt`'s
  // `tail call range(i32 12, 33) i32 @llvm.ctlz.i32(%x, i1 true)` as the
  // real-code witness. That cone never reaches the strip — the `i1 true` immarg
  // makes `curatedIntrinsicCanBePoison` refuse it at CLAIM time, so the region
  // is never claimed. It is the only `call range(...)` shape in 251 openlibm
  // TUs, and it is fenced by a different mechanism.
  //
  // The two halves ship together because widening the DROP over the OLD walk
  // would have extended a known over-reach — that is why the earlier attempt at
  // half 2 alone was reverted, and the revert was right. Narrow first, then
  // widen; the order is the whole point.
  //
  // *** THE DROP IS NOT INVISIBLE TO THE REST OF THE PASS — AND ITS DIRECTION IS
  // NOT UNIFORM. *** TWO claims have stood here and BOTH were false. The first
  // ("flag/metadata-stripping only widens definedness, so every other user of a
  // cone value is unaffected") was falsified by a run. The second is RETRACTED
  // HERE: "the direction is SAFE (accept -> loud decline, never a miscompile)".
  // MEASURED — `Fp80Union.cpp:838-841` (`PaddingWalk::eval`) reads
  // `hasNoSignedWrap()`/`hasNoUnsignedWrap()`/`isExact()` as BLOCKERS, doing
  // `return I` = decline; remove the flag and it falls through to the divergence
  // transfer and may `return nullptr` = ACCEPT. Those two lines are the ONLY
  // direct readers of a dropped fact in the whole pass. So the drop CAN move a
  // reader's verdict toward accept, and a future reader who preserves the old
  // premise preserves nothing. Do not re-derive either false claim.
  //
  // WHAT IS TRUE IS STRONGER, AND IT IS AN INVARIANT RATHER THAN A POPULATION:
  // NO DROP-INDUCED ACCEPT IS UNSOUND. Three legs (bd 2qvr round, 2026-08-16).
  //
  //   L1 — THE MUTATED SET IS NARROW BY CONSTRUCTION. The walk mutates only
  //   `ConeNode::Interior` (below), and `classifyConeNode` admits Interior only
  //   from `definedOpAfterFlagDrop` — which has NO Load clause and NO GEP clause
  //   (:228-286 falls through to `return false` = `Fail`) — or from a curated
  //   reversible intrinsic. A gep `inbounds` is therefore unreachable from HERE.
  //   Note this walk and `moveBody` are NOT nested and must not be merged
  //   (bd ei6c): this one calls `dropPoisonGeneratingAnnotations()` (all three
  //   LLVM-19 families) over a narrow set, `moveBody` (:2635) calls
  //   `dropPoisonGeneratingFlags()` (flags only) over every arm instruction of
  //   every claimed region — a far larger instruction surface, a smaller fact
  //   surface. Neither contains the other.
  //
  //   L2 — THE ONE NEGATIVE-POLARITY READER IS FENCED TWICE, AND THE SECOND
  //   FENCE DOES NOT DEPEND ON PIPELINE ORDER. Fence (i), ORDERING: `PaddingWalk`
  //   is instantiated ONLY at `Fp80Union.cpp:1385/:1393`, both inside
  //   `promoteFp80Union`, whose fixpoint (`CQLoweringPass.cpp:170`) completes
  //   before the first `flattenPredMuxRegions` (:194). *** NOTHING PINS THAT
  //   ORDERING — no assertion, no test. *** Fence (ii), ORDER-INDEPENDENT:
  //   `PaddingWalk`'s ONLY non-zero divergence seed is `setD(LI, M)` at
  //   `Fp80Union.cpp:776`, guarded by `dyn_cast<LoadInst>` + `LoadAt.find` (a
  //   straddle load) — every other `setD` is a transfer or sets zero — and the
  //   blocker at :838 is reached only AFTER the `Da.isZero() && Db.isZero()`
  //   early exit. So it only ever examines straddle-load-derived values, and a
  //   cone containing a `load` is `Fail`, never claimed, never stripped. The two
  //   sets are DISJOINT. Pinned by
  //   `control_predmux_reject_selectform_load_in_cone.ll`. GROW
  //   `definedOpAfterFlagDrop` A LOAD CLAUSE AND THIS FENCE VANISHES SILENTLY,
  //   leaving only the unpinned ordering.
  //
  //   L3 — THE READER WHOSE VERDICT THE DROP *CAN* FLIP CANNOT BE MADE UNSOUND
  //   BY IT. `qromIndexKnownInBounds` (`QramLowering.cpp:775-783`) is a
  //   CONJUNCTION. Half 1 (`computeKnownBits`, `UseInstrInfo=false`) IS
  //   drop-sensitive — that flag structurally cannot gate `nneg`, `disjoint` or
  //   a `range` return attribute, as `QramLowering.cpp:717-718` already says in
  //   source. But half 2 (`indexBoundIsPoisonConditional`) is annotation-blind BY
  //   CONSTRUCTION: `PoisonFacts.cpp` contains ZERO flag/metadata/attribute
  //   accessors, so no drop can move it. Per the shipped ruling at
  //   `QramLowering.cpp:693-699`, half 2 ALONE discharges the total obligation
  //   and half 1 only PRUNES. So an accept the drop manufactures at half 1 is an
  //   accept half 2 had ALREADY licensed on a total, fact-free bound holding on
  //   every basis state: a CAPABILITY move, not an over-accept. *** THIS READER
  //   IS CLOSED BY HALF 2, NOT BY `UseInstrInfo=false` — that was the old
  //   sentence here and it was wrong. ***
  //
  // THE ROUTES, corrected — every line number in the old text was stale and it
  // named one route of two. That reader is reached from `declineTaintEscapes`
  // (`CQLoweringPass.cpp:244`) AND from INSIDE this very fixpoint, via
  // `classifyQromReadUnderControl` at :1535 (the W4 claim witness), :2034 and
  // :2068 — so iteration N+1 re-proves a claim against IR iteration N stripped.
  // And there are FIVE `flattenPredMuxRegions` call sites, not two:
  // `CQLoweringPass.cpp:194`, :218, :515, :531 and `Specialization.cpp:484`.
  // Ordering protects none of them; L3 does.
  //
  // STILL OPEN, FILED, AND NOT THIS WALK'S TO CLOSE:
  // `boundComparesInductionToInvariant` (`LoopLowering.cpp:377-384`) ends
  // `return Inv0 != Inv1` — an XOR of two SCEV loop-invariance queries, so
  // NON-MONOTONE by construction — and it is a required conjunct at :1068, with
  // `lowerLoops` (`CQLoweringPass.cpp:279`) running after both flatten fixpoints.
  // It reads FLAGS only, which is exactly the family `moveBody` drops over a
  // strictly larger instruction set, so it is a pass-wide flag exposure dominated
  // by that surface rather than a property of this walk.
  //
  // bd 94on(a) IS CLOSED BY CONSTRUCTION HERE, and this is a measurement, not an
  // inference. `dropPoisonGeneratingReturnAttributes()` writes CALL-SITE attrs
  // only, while `CallBase::getRetAttr` falls back to the callee DECLARATION
  // (InstrTypes.h:1680) — so a lying declaration-level `range` would be neither
  // seen nor dropped. It cannot arise: `classifyConeNode`'s call clause admits
  // only `isCuratedReversibleIntrinsic`, which requires a real `IntrinsicInst`,
  // and LLVM 19 NORMALISES intrinsic declarations at parse time. Verified with
  // stock `opt -passes=verify` and NO plugin, over all eight curated stems:
  // `declare range(i32 0, 33) i32 @llvm.ctpop.i32(i32)` reads back as
  // `declare i32 @llvm.ctpop.i32(i32) #0`. Real `clang -O1` likewise puts
  // `range` on the CALL SITE and nothing on the declaration. A declaration-level
  // guard here would therefore be dead code with no reaching fixture, and
  // Rule 12 forbids shipping an accept-predicate without one.
  void stripPoisonCone(Value *V) {
    SmallPtrSet<const Value *, 16> Seen;
    SmallVector<Value *, 16> WL;
    WL.push_back(V);
    while (!WL.empty()) {
      Value *N = WL.pop_back_val();
      if (!Seen.insert(N).second)
        continue;
      ConeNode C = classifyConeNode(N);
      if (C == ConeNode::PassThrough) {
        // A `cq_phi` node: its value is operand 0, so keep walking there. The
        // call itself carries no annotation whose removal could make operand 0
        // more defined, so it is not mutated.
        WL.push_back(cast<Instruction>(N)->getOperand(0));
        continue;
      }
      if (C != ConeNode::Interior)
        continue;  // Leaf: defined without a drop. Fail: unreachable on a
                   // claimed cone, and no drop would help it.
      auto *I = cast<Instruction>(N);
      I->dropPoisonGeneratingAnnotations();
      for (Value *Op : I->operands())
        WL.push_back(Op);
    }
  }

  // bd adia (Lever C): rewrite the poison-shielded short-circuit select forms
  // (`select(a,b,false)` = a&&b, `select(a,true,b)` = a||b — the clang -O1
  // compound-condition lowering of coshl's `ex < K || (ex == K && mx < M)`
  // range ladder) into plain and/or nodes so the emitted predicate trees stay
  // inside the cleared and/or-over-compare-leaves grammar (collectCondTree /
  // the 3c6m.12 flag mint). Identity on every other supported shape. The
  // shielded operand's cone is flag-stripped first (see stripPoisonCone) so
  // the rewrite is basis-state-equivalent: a defined `b` makes
  // `and(a,b) == select(a,b,false)` on every input.
  Value *canonicalizePred(Value *V) {
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue()))
        if (FC->isZero()) {
          stripPoisonCone(Sel->getTrueValue());
          return track(B.CreateAnd(canonicalizePred(Sel->getCondition()),
                                   canonicalizePred(Sel->getTrueValue())));
        }
      if (auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue()))
        if (TC->isOne()) {
          stripPoisonCone(Sel->getFalseValue());
          return track(B.CreateOr(canonicalizePred(Sel->getCondition()),
                                  canonicalizePred(Sel->getFalseValue())));
        }
      return V;  // unreachable past isSupportedCondTree
    }
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (BO->getOpcode() == Instruction::And ||
          BO->getOpcode() == Instruction::Or) {
        Value *L = canonicalizePred(BO->getOperand(0));
        Value *Rr = canonicalizePred(BO->getOperand(1));
        if (L != BO->getOperand(0) || Rr != BO->getOperand(1))
          return track(BO->getOpcode() == Instruction::And ? B.CreateAnd(L, Rr)
                                                           : B.CreateOr(L, Rr));
      }
    }
    return V;
  }

  // ¬V with the negation pushed to the leaves (PRD §4.3, the no-NOT
  // invariant). Shapes are pre-checked by isSupportedCondTree.
  Value *buildNegation(Value *V) {
    if (auto *C = dyn_cast<ConstantInt>(V))
      return C->isZero() ? ConstantInt::getTrue(C->getContext())
                         : ConstantInt::getFalse(C->getContext());
    if (auto *Cmp = dyn_cast<CmpInst>(V))
      return track(B.CreateCmp(Cmp->getInversePredicate(), Cmp->getOperand(0),
                               Cmp->getOperand(1)));
    // bd adia: select-form short-circuit nodes (see canonicalizePred; the
    // shielded operand's cone is flag-stripped before negation, same
    // basis-state-equivalence argument). ¬(a&&b) = ¬a ∨ ¬b ;
    // ¬(a||b) = ¬a ∧ ¬b — leaf-inverted De Morgan (the no-NOT invariant).
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
          FC && FC->isZero()) {
        stripPoisonCone(Sel->getTrueValue());
        return track(B.CreateOr(buildNegation(Sel->getCondition()),
                                buildNegation(Sel->getTrueValue())));
      }
      auto *TC = cast<ConstantInt>(Sel->getTrueValue());
      (void)TC;
      stripPoisonCone(Sel->getFalseValue());
      return track(B.CreateAnd(buildNegation(Sel->getCondition()),
                               buildNegation(Sel->getFalseValue())));
    }
    auto *BO = cast<BinaryOperator>(V);
    if (BO->getOpcode() == Instruction::Xor)
      return BO->getOperand(0);  // xor-true: ¬¬x = x
    Value *L = buildNegation(BO->getOperand(0));
    Value *Rr = buildNegation(BO->getOperand(1));
    return track(BO->getOpcode() == Instruction::And ? B.CreateOr(L, Rr)
                                                     : B.CreateAnd(L, Rr));
  }

  // BP(D) = ∨ over in-edges of EP(e); ⊤ (nullptr) for the entry. Lazy +
  // memoized; recursion terminates on the region DAG.
  Value *blockPred(BasicBlock *D) {
    if (D == R.Entry)
      return nullptr;
    auto It = BlockPred.find(D);
    if (It != BlockPred.end())
      return It->second;
    Value *BP = nullptr;
    for (BasicBlock *S : predecessors(D)) {
      Value *EP = edgePred(S, D);
      BP = BP ? track(B.CreateOr(BP, EP)) : EP;
    }
    BlockPred[D] = BP;
    return BP;
  }

  // EP(S→D) = BP(S) ∧ lit(S→D), OR-folded over duplicate edges (a switch may
  // reach the same successor through several cases).
  Value *edgePred(BasicBlock *S, BasicBlock *D) {
    Instruction *Term = S->getTerminator();
    Value *Lit = nullptr;
    if (auto *BI = dyn_cast<BranchInst>(Term)) {
      if (!BI->isConditional())
        Lit = nullptr;  // unconditional edge: EP = BP(S)
      else if (BI->getSuccessor(0) == D && BI->getSuccessor(1) == D)
        Lit = ConstantInt::getTrue(BI->getContext());
      else
        Lit = literal(S, BI->getSuccessor(0) == D ? 0 : 1);
    } else {
      auto *SI = cast<SwitchInst>(Term);
      for (unsigned Idx = 0, N = SI->getNumSuccessors(); Idx != N; ++Idx) {
        if (SI->getSuccessor(Idx) != D)
          continue;
        Value *L = literal(S, Idx);
        Lit = Lit ? track(B.CreateOr(Lit, L)) : L;
      }
    }
    Value *BP = blockPred(S);
    if (!BP)
      return Lit ? Lit : ConstantInt::getTrue(S->getContext());
    if (!Lit)
      return BP;
    return track(B.CreateAnd(BP, Lit));
  }

  // Replace every phi of D with a chained select over its in-edge
  // predicates: sel(EP(e₁), v₁, sel(EP(e₂), v₂, … v_m)). The last incoming
  // is the fallback (its predicate is implied when the merge is reached; when
  // an INTERNAL merge is not on the taken path the chain yields garbage that
  // every downstream consumer excludes via its own ∧-with-block-predicate —
  // PRD §4.4/§6.1).
  void convertPhis(BasicBlock *D) {
    SmallVector<PHINode *, 4> Phis;
    for (PHINode &P : D->phis())
      Phis.push_back(&P);
    for (PHINode *P : Phis) {
      // Unique incoming blocks in order (duplicate blocks carry the same
      // value by LLVM's phi rules).
      SmallVector<std::pair<BasicBlock *, Value *>, 8> In;
      SmallPtrSet<BasicBlock *, 8> Seen;
      for (unsigned I = 0, N = P->getNumIncomingValues(); I != N; ++I)
        if (Seen.insert(P->getIncomingBlock(I)).second)
          In.emplace_back(P->getIncomingBlock(I), P->getIncomingValue(I));
      // undef/poison incomings freeze to zero (dead on every selecting path).
      for (auto &IV : In)
        if (isa<UndefValue>(IV.second))
          IV.second = Constant::getNullValue(P->getType());
      // Inc 2 — an i1 phi whose incomings all sit inside the substrate
      // condition-tree grammar converts to BOOLEAN ALGEBRA, ∨ᵢ (EP(eᵢ) ∧ vᵢ)
      // (the iw81.14 / Bennett `_compute_block_pred!` form), instead of a
      // select chain: a select-of-i1 feeding a downstream select CONDITION is
      // off the 3c6m.12 flag-mint grammar (the tanh s_expm1.c:168 decline),
      // while and/or-over-compare-leaves stays mintable. Exactly one EP is
      // true when the merge is on the taken path (acyclic single-visit), so
      // the ∨ picks that edge's value; off-path the result is `false` —
      // garbage excluded downstream by the same ∧-with-block-predicate
      // argument as the chain's fallback garbage (PRD §4.4/§6.1). ∧true/
      // ∧false fold away so i1 constants never reach the emitted tree; the
      // EP==v and Acc==Term guards keep the substrate's self-operand fence
      // unreachable (x∧x = x, x∨x = x). Off-grammar incomings (trunc/xor/…)
      // keep the Inc-1 select chain — the consuming select declines loudly
      // exactly as today.
      bool BoolAlg = P->getType()->isIntegerTy(1) && In.size() > 1;
      // bd q2wk (Inc 5) — a phi the E6 claim RECORDED is a path-predicated
      // BRANCH condition: `literal()`/`buildNegation` will read its converted
      // value as a cond tree, so the select-chain fallback is not available
      // (a general `select i1` there is a broken module, not a decline). The
      // claim proved the same grammar this loop re-checks — over the ORIGINAL
      // incomings, where a nested convertible phi is still a phi and this
      // scope-less grammar would reject it, and where a deeper already-
      // converted incoming may also exceed the depth budget. Trusting the
      // recorded decision is what removes both divergences; it is never
      // weaker, because `isConvertiblePhiCond` requires exactly this grammar
      // (extended only by the recursive phi case) plus i1 and >1 unique
      // incoming block. The algebra itself is total for any i1 incoming — the
      // grammar exists only to keep the RESULT flag-mintable.
      if (BoolAlg && !R.BoolAlgPhis.count(P))
        for (auto &IV : In)
          if (!isBooleanCondTree(IV.second, 0)) {
            BoolAlg = false;
            break;
          }
      Value *Acc = nullptr;
      if (BoolAlg) {
        for (auto &IV : In) {
          Value *EP = edgePred(IV.first, D);
          Value *Term = nullptr;
          if (auto *C = dyn_cast<ConstantInt>(IV.second))
            Term = C->isOne() ? EP : nullptr;  // ∧true = EP; ∧false drops.
          else if (EP == IV.second)
            Term = EP;  // x ∧ x = x (never mint a self-operand node).
          else
            Term = track(B.CreateAnd(EP, IV.second));
          if (!Term)
            continue;
          if (!Acc)
            Acc = Term;
          else if (Acc != Term)  // x ∨ x = x.
            Acc = track(B.CreateOr(Acc, Term));
        }
        if (!Acc)  // every incoming was constant-false/frozen-undef.
          Acc = ConstantInt::getFalse(P->getContext());
      } else {
        Acc = In.back().second;
        for (unsigned I = In.size() - 1; I-- > 0;) {
          // bd adia (3c6m.55 Lever C): select(EP, x, x) = x — never mint the degenerate
          // same-arm mux (the value-chain mirror of the BoolAlg x∨x guard).
          if (In[I].second == Acc)
            continue;
          Value *EP = edgePred(In[I].first, D);
          Acc = track(B.CreateSelect(EP, In[I].second, Acc));
        }
      }
      P->replaceAllUsesWith(Acc);
      P->eraseFromParent();
    }
  }

  // Move D's straight-line body before the entry terminator, dropping
  // poison-generating flags (nsw/nuw/exact/nneg/disjoint + fp poison FMF) —
  // the standard speculation discipline; bit-semantics and template
  // selection are unaffected (signedness lives in the opcode, Rule 15).
  void moveBody(BasicBlock *D) {
    Instruction *T = R.Entry->getTerminator();
    for (Instruction &I : llvm::make_early_inc_range(*D)) {
      if (I.isTerminator())
        continue;
      I.dropPoisonGeneratingFlags();
      I.moveBefore(T);
      track(&I);
    }
  }

  Value *track(Value *V) {
    MaybeDead.push_back(V);
    return V;
  }

  // Erase any moved/minted instruction that ended up unused (e.g. the unused
  // fallback edge-predicate) so no dead tainted producer reaches lowerOps.
  // All tracked values are pure, so this is a plain use_empty fixpoint.
  void sweepDead() {
    bool Changed = true;
    while (Changed) {
      Changed = false;
      for (WeakTrackingVH &H : MaybeDead) {
        auto *I = dyn_cast_or_null<Instruction>(H.operator Value *());
        if (I && I->use_empty()) {
          I->eraseFromParent();
          H = nullptr;
          Changed = true;
        }
      }
    }
  }
};

}  // namespace

// bd adia (3c6m.55 Lever C): exported wrapper — the pending-spec pure-callee proof
// (visible + non-vararg + acyclic CFG + br/ret terminators + every
// non-terminator speculatable dataflow; inner calls curated memory(none)
// intrinsics only). Shared with the Fp80Union seed walk (Rule 14).
bool isSpeculatablePureCallee(const Function *F) {
  return isSpeculatablePureCalleeBody(F);
}

// bd wve8 — THE STRICT TWIN, AND THE REASON IT HAD TO EXIST.
//
// `isSpeculatablePureCallee` is documented as "pure + total + terminating", and
// the TOTAL conjunct is not true unconditionally: two clauses of the walk carry
// an obligation that is discharged by a LATER stage rather than by the walk.
//   (1) THE QROM READ. `isSpeculatableDataflow` admits a const-global load and
//       its address gep via `qromReadShapeInScope`, whose own header states that
//       "the index-taint proof, the straight-line/loop gates AND the bounds proof
//       are DEFERRED — re-proven by the emitter under the clone's own cloneTaint".
//   (2) THE TERMINATOR SKIP. The walk `continue`s on terminators and never asks
//       whether a conditional branch's condition can be poison; `br i1 poison` is
//       immediate UB.
// For S1/S2 (the E4 CALL admission) and S3 (Fp80Union's seed cone) that deferral
// is real: the callee is about to be CLONED and LOWERED, and the clone's own
// flatten re-proves the bounds and keeps the branch. Those consumers are
// unchanged and must stay unchanged.
//
// The Phase-6.5 classical-call arm is the consumer for which the deferral is
// VOID, and it is void by construction, not by accident: 6.5 is
// clone-ORTHOGONAL — no clone is ever minted, the callee body is never lowered,
// stage 3 compiles it verbatim, and `ClassicalCallArmEmit` HOISTS the call to
// unconditional execution. Nothing downstream exists to discharge anything.
//
// *** THIS WAS NOT A THEORETICAL GAP. *** The first bd wve8 fix used
// `isSpeculatablePureCallee` here and a Rule-13 lens broke it in one probe of
// plain C at -O1, reproduced independently by the orchestrator:
//     static const int tab[4] = {11,22,33,44};
//     __attribute__((noinline)) static int lookup(int i) { return tab[i]; }
//     int q = cq_theta_si32(0, 0.0);  int y = q;      /* Ry(0) = identity   */
//     if (q > 3) y = lookup(idx);                     /* zero amplitude     */
// clang infers `memory(none)` on `lookup` (a read of CONSTANT memory is not a
// memory access to FunctionAttrs), so the purity gate passes on a function that
// really does load; the index is a classical parameter no quantum guard can
// constrain; the hoist executes the read. idx=1e8 -> SIGSEGV (run_exit=139).
// idx=9 -> NO crash and `cqrt_alloc_i32(539780133)` in the trace: a word read
// past the end of the table, route-merged on a run where the source never
// evaluated the call. `cq-opt` exit 0, verifier clean, `free_pairing_check.py`
// 2 verified / 0 violations / 0 unproven, every gate in the tree silent.
// Pinned by control_classical_call_arm_reject_qrom_callee.ll (arm-kill: flip the
// table's `constant` to `global` and it declines pre-fix too, which is how the
// QROM clause was isolated as the admitting one).
//
// So: same walk, same memo discipline, one flag. A consumer that will NOT
// discharge a deferred obligation must not be handed a proof that defers one.
bool isSpeculatableTotalCallee(const Function *F) {
  PureCalleeQuery Q;
  Q.AdmitDeferred = false;
  bool R = isSpeculatablePureCalleeBodyImpl(F, Q);
  // Same `CQ_PREDMUX_COUNT` line as the lax entry point, with `mode=strict` so the
  // two are distinguishable in one stream. Deliberate parity, not decoration: the
  // wve8 Rule-13 round noted that without it S6 — the ONE clone-orthogonal
  // consumer, i.e. the one whose verdict is load-bearing for a hoist nothing else
  // re-proves — would be the only consumer with no verdict/cost observability and
  // the only one that could not carry a call-count cost pin (the bd 3c6m.14.4
  // discipline: pin a COUNT, never a wall time).
  if (::getenv("CQ_PREDMUX_COUNT"))
    llvm::errs() << "CQ_PREDMUX_COUNT: pure-callee mode=strict root="
                 << (F ? F->getName() : "<null>") << " verdict=" << R
                 << " invocations=" << Q.Invocations
                 << " bodies=" << Q.BodiesWalked << " hits=" << Q.MemoHits
                 << "\n";
  return R;
}

// bd 20xt.5.1 blocker (e): fold the constant-fold RESIDUES the flatten's
// `foldConstantConeAndBranches` leaves behind. `ConstantFoldInstruction` is
// all-or-nothing — it RAUWs an all-constant operand to its value but cannot
// finish a PARTIAL-constant binop whose other operand is tainted, so a dead
// classical arm (e.g. atan2l's `x==1.0` special-case or its `2*sign(x)`
// quadrant term with x a positive classical constant) leaves `and i1 false,%t`
// / `or i32 0,%t` behind. Those wedge SelectClassify: `collectCondTree` hits
// the `false` ConstantInt leaf and declines "control flow under quantum
// control", even though the select is dead (`select false,a,b`) or a no-op
// (`select c,a,a`).
//
// SCOPE — ONLY the residue shapes that WEDGE SelectClassify, NEVER a general
// InstSimplify sweep:
//   * an i1 and/or with a ConstantInt operand — the CONDITION-CONE logic
//     residue (X∧false=false, X∧true=X, X∨true=true, X∨false=X). This is what
//     `collectCondTree` chokes on (the `false` ConstantInt leaf). The and/or
//     fold is deliberately restricted to i1: a WIDER `or i32/i64 0,X` fold is a
//     DATA residue that does NOT block detection (it is a compare operand /
//     select arm, not a tree node) — and the fp80-union promotion mints exactly
//     that shape (`or i64 0,%w` in the union reconstruction), so folding it
//     drifts the cbrtl/exp2l/erfl real-source goldens by one gate + a handle
//     renumber cascade for zero detection benefit. Leave it.
//   * select with a ConstantInt condition (const ? a : b) — collapses the dead
//     special-case arm the flatten straight-lined (atan2l's `select i1 false`).
//   * select with syntactically-equal arms (c ? a : a = a).
// A legit cond-tree node (`and/or i1` of two RUNTIME compares) and a genuine
// data select have NO constant operand and unequal arms, so they are never
// touched — that keeps every existing golden's toffoli/copy-gate emission
// byte-identical (a full `simplifyInstruction` sweep folds legit and/or-over-
// compares via deeper reasoning and drifts ~29 verified libm real-source
// goldens: it drops the very toffolis that realize the cond tree). InstSimplify
// is reused ONLY to COMPUTE the fold of a gated residue (Rule 14) — it returns
// an existing value or a Constant, never mints new IR, so no NOT/De-Morgan
// leaks into the no-NOT and/or-over-compare-leaves grammar. Sound: InstSimplify
// is value-preserving and the taint lowering faithfully emulates LLVM value
// semantics, so a folded residue lowers to the identical unitary (the dead arm
// carried zero amplitude / was source-UB — see
// quantum-ub-unreachable-sharp-edge-20xt5). Fixpoint: a fold exposes the next
// (`%27→false` ⇒ `and i1 %43,%27 → and i1 %43,false`).
static bool isFlattenResidue(const Instruction &I) {
  if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
    if ((BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or) &&
        BO->getType()->isIntegerTy(1))
      return isa<ConstantInt>(BO->getOperand(0)) ||
             isa<ConstantInt>(BO->getOperand(1));
    return false;
  }
  if (auto *Sel = dyn_cast<SelectInst>(&I))
    return isa<ConstantInt>(Sel->getCondition()) ||
           Sel->getTrueValue() == Sel->getFalseValue();
  return false;
}

static bool simplifyFlattenResiduesInFunction(Function &F) {
  const DataLayout &DL = F.getParent()->getDataLayout();
  SimplifyQuery SQ(DL);
  bool Any = false, Changed = true;
  while (Changed) {
    Changed = false;
    // TWO-PASS per round: COLLECT the residue instructions first (pure
    // analysis, no mutation), then fold + DCE over the worklist. The mutation
    // pass must NOT run inside a block iterator, because the recursive DCE below
    // can delete an instruction that FOLLOWS the fold site: a LOOP PHI's
    // back-edge incoming value need not dominate the phi (it dominates only the
    // incoming block terminator), so folding `and i1 %loopphi, false` can
    // orphan the phi and cascade to its back-edge operand `%J = getNextNode()`
    // — dangling a `make_early_inc_range` lookahead cursor (a UAF crash on valid
    // IR; the "operands dominate I" proof holds for straight-line SSA but not
    // across a loop back-edge). Iterating a WeakTrackingVH worklist instead is
    // deletion-safe: a cascade-deleted entry nulls out and is skipped.
    SmallVector<WeakTrackingVH, 16> Worklist;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (isFlattenResidue(I))
          Worklist.push_back(&I);
    for (WeakTrackingVH &H : Worklist) {
      auto *I = dyn_cast_or_null<Instruction>(H.operator Value *());
      if (!I || !isFlattenResidue(*I))
        continue;  // cascade-deleted, or no longer a residue after an RAUW.
      Value *V = simplifyInstruction(I, SQ);
      if (!V)
        continue;
      I->replaceAllUsesWith(V);
      // Erase I AND recursively any operand cone it just ORPHANED. Unlike
      // ConstantFold (which folds only ALL-constant ops, so an erased op's
      // operands are Constants), this fold collapses PARTIAL-constant residues
      // whose non-constant operand is TAINTED — e.g. folding `and i1 false, %t3`
      // drops the ONLY use of `%t3 = icmp eq %q,3`. Left un-DCE'd that dead
      // tainted compare would lower to a forward `cq_template_icmp_*` gate never
      // uncomputed / never freed — an entangled which-path flag left dangling on
      // a live rail (Rule 6/8 garbage; harmless to the measured answer but a
      // coherence hazard, and trivially avoidable since the op is DEAD).
      // RecursivelyDelete removes only pure, use-free instructions (never a
      // cq_theta/phi/measure call — those have side effects — nor a value with
      // other live uses).
      RecursivelyDeleteTriviallyDeadInstructions(I);
      Changed = Any = true;
    }
  }
  return Any;
}

bool flattenPredMuxRegions(Module &M, TaintSet &Taint, bool ClaimAll) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool HasTaintedCtrl = false;
    for (BasicBlock &BB : F)
      if (isTaintedCtrlTerm(BB.getTerminator(), Taint))
        HasTaintedCtrl = true;
    if (!HasTaintedCtrl)
      continue;

    // bd adia (3c6m.55 Lever C): collapse constant-fold residues FIRST (an all-constant
    // compare feeding a branch — materialized late by an earlier flatten's
    // select folding or a cross-function promotion round — reads as
    // "classical control inside a tainted region" and wedges E6). Taint-safe
    // (only all-constant instructions fold; a theta-derived value is never
    // Constant). A fold is a mutation: report it so the driver re-propagates
    // before the next claim reads the region.
    if (foldConstantConesInFunction(F))
      return true;

    PostDominatorTree PDT;
    PDT.recalculate(F);
    DominatorTree DT(F);
    LoopInfo LInfo(DT);  // for the Inc-3 QROM-read claim (shared carve predicate)
    SmallPtrSet<BasicBlock *, 16> OnCycle;
    collectCycleBlocks(F, OnCycle);

    for (BasicBlock &BB : F) {
      Instruction *T = BB.getTerminator();
      if (!isTaintedCtrlTerm(T, Taint))
        continue;
      PredMuxRegion R;
      if (!recoverRegion(T, PDT, DT, LInfo, OnCycle, Taint, R, ClaimAll))
        continue;  // leave: today's loud declines own it
      // bd 7udx — at CLAIM, before `RegionFlattener::run()` erases
      // `R.Topo \ {R.Entry}`. `BasicBlock::~BasicBlock()` replaces every
      // `BlockAddress` of a destroyed block with `inttoptr (i32 1 to ptr)`,
      // module-wide, silently rewriting a compared-against address to `i32 1` on
      // a WELL-DEFINED source (no UB, no refinement argument). Checked HERE and
      // not inside `run()` on purpose: `flattenPredMuxRegions` returns `true`
      // unconditionally after `run()`, so an early bail inside `run()` would spin
      // the caller's `while (flattenPredMuxRegions(...))` fixpoint on a host that
      // installs its own diagnostic handler instead of `opt`'s exiting one.
      // `R.Entry` survives the teardown and `R.Merge` is the branch target, so
      // neither is doomed — the doomed set is exactly the erase loop's.
      {
        SmallVector<BasicBlock *, 8> Doomed;
        for (BasicBlock *D : R.Topo)
          if (D != R.Entry)
            Doomed.push_back(D);
        if (declineAddressTakenBlocks(Doomed, T))
          continue;
      }
      IRBuilder<> Builder(T);
      Builder.SetCurrentDebugLocation(T->getDebugLoc());
      RegionFlattener(R, Builder).run();
      // bd adia (3c6m.55 Lever C): collapse fold residues the flatten materialized
      // (a select chain over constant incomings folds to a constant, leaving
      // a constant-operand compare feeding a "classical" branch that would
      // wedge the next claim's E6 walk). Taint-safe: only all-constant
      // instructions fold; the caller re-derives taint before the next claim.
      foldConstantConesInFunction(F);
      // bd 20xt.5.1(e): fold the partial-constant / degenerate-select residues
      // ConstantFold left in the flattened region so SelectClassify sees the
      // collapsed (dead-arm-free) select chain, not an `and i1 false` leaf.
      simplifyFlattenResiduesInFunction(F);
      return true;  // one region per call; caller re-propagates
    }
  }
  return false;
}

}  // namespace cq
