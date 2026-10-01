// PredMuxFlatten.cpp — 3c6m.14 (L6): general acyclic tainted control via
// block-predicate MUX flattening ("PredMux"). See PredMuxFlatten.h and the
// PRD (docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/) for
// the design of record; the correctness argument is PRD §6 (per-basis-state
// classical IR equivalence + reduction to the Rule-13-cleared select
// substrate).
//
// The one non-negotiable here is the ACCEPT-ONLY discipline: every check
// below LEAVES the region untouched on failure — the existing detection
// declines it loudly exactly as today. PredMux never replaces a decline with
// silence.
//
// ⚠ "OVER-DECLINING STAYS SAFE; PredMux CAN ONLY WIDEN THE ACCEPT SURFACE"
// STOOD HERE AND THE SECOND HALF IS NOW MEASURABLY FALSE — Rule-13 rounds A and
// B on bd `test_C_libtooling-woa0`, INDEPENDENTLY, `F-RA-1` / `F-RB-1`, four
// hand-built exhibits between them. `declineConvertedRailPhiLeaves` can NARROW
// the accept surface: the cross-claim record is committed at the E6 ADMISSION
// while `run()` builds edge predicates LAZILY, so a region can record a rail φ
// its emission never reads, and a later claim's VACUOUS RAUW then declines a
// module the pre-woa0 oracle compiled correctly. The CLAIM path is still
// accept-only; the POSTCONDITION is not. ⚠ AND NOTE WHICH HEADER THIS IS:
// `357f2528` corrected the sibling sentence in `PredMuxFlatten.h` precisely
// because "a correction not applied to the source is not a correction", and
// left this one standing (CLAUDE.md L7-with-a-twist, one file, two headers).
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

#include "CompareLowering.h"  // logicalOperandWidth (bd 01po.2 — the mask's width)
#include "CondLiteral.h"    // markPredictedTaintCone (bd xdu2.13 — the rule-(B) record)
#include "Fp80Union.h"      // foldConstantConesInFunction (adia fold residue)
#include "IntrinsicLowering.h"
#include "PoisonFacts.h"  // curatedIntrinsicCanBePoison (lifted, bd s6ao)
#include "LiteralIntegrity.h"  // valueCarriesUndef (lifted); declineAddressTakenBlocks
#include "OpcodeSupport.h"  // abiWidthFromType, binaryStem, castInScope, i80BinaryInScope
#include "GuardedClassicalRead.h"  // bd xdu2.8 — the arm-guarded runtime-VLA read
#include "QramLowering.h"
#include "SelectClassify.h"  // isCondRailLeaf (bd fn1q inc 2 — the ONE spelling, Rule 14)
#include "TaintPropagation.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/AssumptionCache.h"   // bd fn1q inc 4 (E4 classical read)
#include "llvm/Analysis/Loads.h"             // isDereferenceableAndAligned*
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"   // bd fn1q inc 4
#include "llvm/Analysis/TargetLibraryInfo.h" // bd fn1q inc 4
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Argument.h"    // bd 615s — the poison-generating param attrs
#include "llvm/IR/Attributes.h"  // bd 615s
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"  // bd woa0 — the post-fixpoint re-ask
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/MathExtras.h"  // isPowerOf2_64 (bd 20xt.7 Provable-pow2 mask)
#include "llvm/Transforms/Utils/Local.h"  // isInstructionTriviallyDead (bd cfmv)

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

}  // namespace

// E7 — a type the select substrate can mux: integer ≤ 64 bits or the scalar
// fp widths of the kjd1 controlled-copy family. (Mirrors copyControlledFn /
// copyControlledFpFn envelopes so a claimed region cannot half-lower —
// detect-before-mutate.)
//
// bd b6ap — DE-ANONYMIZED (linkage only, definition byte-unchanged) so the
// MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`, P5) asks THIS predicate rather than
// growing a second spelling of "a type the 4.4/kjd1 merge can copy" (Rule 14).
// Declared in `PredMuxFlatten.h`.
bool isMuxableType(Type *Ty) {
  if (auto *IT = dyn_cast<IntegerType>(Ty))
    return IT->getBitWidth() <= 64;
  return Ty->isHalfTy() || Ty->isFloatTy() || Ty->isDoubleTy() ||
         Ty->isX86_FP80Ty();
}

namespace {

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
    // *** THE RULING (bd hg8s, owner 2026-08-17): TWO KINDS SIT ON THIS LINE UNDER
    // TWO DIFFERENT STANDARDS, AND THAT IS CORRECT. *** A `Constant` is admitted on
    // bd bu96's PAIRING axis; a `noundef` `Argument` on DEFINEDNESS. They are two
    // different SUFFICIENT GROUNDS for ONE obligation, and each kind can supply only
    // the one it is checked against. Do NOT tidy them into a single standard — both
    // candidate unifications were measured and both lose.
    //
    // THE OBLIGATION IS `ONE VALUE AT EVERY USE` — not "pairing", not "definedness".
    // The lowering copies a cone leaf's operands into MORE slots than the source
    // had: `canonicalizePred`'s forward tree, `buildNegation`'s leaf-inverted tree,
    // and one `_unc` per forward gate. Nothing re-derives the value at those sites;
    // each is a fresh copy of the same `Value *`.
    //
    // A CONSTANT SUPPLIES THE PAIRING GROUND AND CANNOT SUPPLY A DEFINEDNESS ONE.
    // Uniqued, hence ONE link-time relocation: the forward gate, its adjoint and the
    // inverted polarity read the same bits, whatever those bits are. MEASURED at the
    // pinned stage-3 `-O0` (5 runs, paired) and — the load-bearing half — ALSO ABOVE
    // THE PIN: `opt -passes='default<O1>'`, internal linkage, linked and run,
    // 8507392 == 8507392. Uniquing is a property of the VALUE.
    //   *** AND NOT BECAUSE "NOTHING POISON-CONDITIONAL ATTACHES TO A CONSTANT" —
    //   THAT IS FALSE AND AN EARLIER DRAFT OF THIS COMMENT SAID IT. *** A
    //   `ConstantExpr` carries `inbounds` (the bu96 witness has FOUR of them, and the
    //   `inbounds` is precisely what makes it poison). The right statement is
    //   narrower: a Constant's annotations are part of the UNIQUED VALUE, so they are
    //   the same at every use — there is no PER-USE fact to diverge, which is the
    //   only thing the obligation asks. An Instruction's `nneg`/`disjoint`/`exact`
    //   are also per-value, but an Instruction is not what reaches this line.
    // A poison-GENERATING constant expression (`ptrtoint (gep inbounds ...)` out of
    // range) is therefore admissible here and bd bu96's decline-to-fix is RIGHT.
    // *** WHAT IT IS NOT IS `DEFINED`.
    // Do not re-describe it that way, and do not "fix" it by demanding definedness:
    // that declines a cell whose obligation is already discharged, and trades the
    // correct ground for a symmetry. ***
    //
    // AN ARGUMENT SUPPLIES THE DEFINEDNESS GROUND AND CANNOT SUPPLY THE PAIRING ONE.
    // An `Argument` is a REGISTER in the emitted IR, not a value. Its one-value
    // property holds only while no later pass rewrites the parameter's uses into the
    // CALLER's value — and argument forwarding is a routine, LEGAL transform on a
    // WELL-DEFINED module. MEASURED both ways: a bare `Argument` leaf pairs at `-O0`
    // (5/5, and the value MOVES run-to-run, so the parameter really was undefined —
    // that is the row's own power check), while at `default<O1>` with internal
    // linkage the four slots become INDEPENDENT `undef` tokens and diverge, fwd 73896
    // vs `_unc` 1401299752 — byte-identical to bd bu96's recorded literal-token
    // break, reached by a legal transform. Attribute the mechanism precisely, because
    // it changes what a fix would have to fence: the flip was measured under
    // `default<O1>`, i.e. INLINING; `-passes=ipsccp` ALONE did NOT flip it even with
    // internal linkage, and external linkage blocks it at every pipeline tried
    // (ipsccp / O1 / O2). Internal linkage suffices, and CQ's own Phase-6 clones are
    // `InternalLinkage` (`Specialization.cpp:611`). So for an Argument, pairing is a
    // property of the LINK.
    //
    // WHICH IS WHY PAIRING CANNOT BE THIS CLAUSE'S STANDARD: IT FAILS ON BOTH SIDES
    // OF THE FENCE. Feed a `noundef` parameter `undef` and the same divergence
    // appears in the ACCEPT set with the same two constants. What separates the
    // halves is not WHETHER they diverge but WHICH EXECUTIONS do. Decline half: the
    // module is legal IR, well-defined exactly on the shielded states — which are
    // exactly the states the rewrite newly evaluates — so the break lands on a
    // well-defined execution. Accept half: the caller violated `noundef`, so by the
    // LangRef clause quoted above no execution validly reaches the rewritten code at
    // all. `noundef` buys that, and only that.
    //
    // THE RULING IS ROBUST TO HOW YOU READ THE `-O0` PIN, which is what makes it
    // safe to carry. If the pin (`tests/e2e/run_slice.sh`, bd szpr) is inviolable,
    // pairing is SILENT for an Argument in both halves and definedness is this
    // clause's only content; if the pin is removable, pairing FAILS in both halves
    // and again only definedness separates them. Same answer. *** THAT PIN IS
    // LOAD-BEARING HERE AND IS WRITTEN DOWN NOWHERE NEAR IT — filed as bd mfae. ***
    //
    // AND bd 615s's OWN STATED HARM IS IMPRECISE — DO NOT QUOTE IT AS THE HARM. "The
    // rewrite OBSERVES `b` on the basis states the shield excluded" names the right
    // LOCATION (the flattened block does fire `b`'s cone on the states the short
    // circuit skipped) and the WRONG harm, because for any ONE value of `b`,
    // `select(a,b,false)` and `and(a,b)` agree on every input. MEASURED across all
    // four guard forms — AND/OR by arm-TRUE/arm-FALSE, the negated rows demonstrably
    // routing through `buildNegation` since they emit the INVERSE predicate at the
    // leaves — every form ACCEPTS a poison `ConstantExpr` leaf and every emitted
    // circuit is BYTE-IDENTICAL to its defined control. What actually goes wrong on
    // those states is a rail written and then freed against a non-matching `_unc`.
    // So "wrong flag" is discharged, but CONDITIONALLY on the leaf denoting one
    // value: it collapses INTO this obligation rather than standing beside it.
    //
    // WHY THE FENCE IS SPELLING-SPECIFIC, AND WHY THAT IS NOT A HOLE.
    // `select i1 %a, i1 %b, i1 false` is clang DECLINING to require that `%b` be
    // defined when `%a` is false — the shield is what makes speculating `%b` legal.
    // `canonicalizePred` rewrites it to `and i1 %a, %b`, which DOES require it,
    // because `and` propagates poison. In the plain `and` spelling the SOURCE
    // already imposes that requirement and CQ inherits the fact for free; in the
    // shielded spelling the source withholds it and the REWRITE manufactures it, so
    // the rewriter owes the proof. Consequence to keep: the plain `and` spelling of
    // the same cone is accepted with a BARE Argument and can carry the identical
    // divergence off the pin. That is NOT a hole for this clause to close, and NOT
    // evidence that this clause buys nothing — it is the same guarantee reached by a
    // different prover.
    //
    // AND WHY `ArmClassify`'s STRICTER STANDARD DOES NOT TRANSFER HERE. There
    // (`paramHasAttr(NoUndef) && !isGuaranteedNotToBeUndefOrPoison` -> decline, bd
    // wve8) CQ HOISTS a call whose `noundef` parameter would make poison IMMEDIATE UB
    // in the EMITTED program — CQ would be CREATING UB. Here the canonicalized tree
    // feeds the flag MINT and never a branch. Verified to that extent and no further:
    // the pass emits `CreateCondBr` in exactly TWO places, both in
    // `BreakReversePlay.cpp` (:823 over a `GuardCond`/`CreateNot`, :835 over a fresh
    // `CreateICmpNE`) — neither is a canonicalized predicate tree — and
    // `canonicalizePred` never RAUWs the original branch condition. Nothing in the
    // emitted program is UB-sensitive to this leaf. Two `noundef` gates, two
    // different obligations — do not unify them.
    //
    // WHOEVER PROPOSES TO RE-GROUND OR REMOVE EITHER HALF must say WHICH ground they
    // are removing and what supplies it instead. Blast radius of the loosening,
    // measured exactly: 3 of 1059 fixtures flip decline -> accept, and they are
    // precisely the three rows this comment already names as its cost.
    if (const auto *A = dyn_cast<Argument>(V))
      if (!A->hasAttribute(Attribute::NoUndef))
        return ConeNode::Fail;
    // A `Constant` (admissible on PAIRING — uniqued, NOT necessarily defined) or a
    // `noundef` `Argument` (admissible on DEFINEDNESS). See the bd hg8s ruling above
    // for why those are two different grounds and why that is correct.
    return ConeNode::Leaf;
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
               // ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 — the `@cq_phi_<sfx>` family is
               // RETIRED and `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE, so the
               // register-free `void @cq_phi(double)` never reaches here. Kept, not deleted
               // (PRD §6.2 row P6); see the note at `ArmClassify.cpp`'s `isPhiCall` for why
               // widening it would read the wrong operand.
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
// ⚠ `RailLeaves` is bd `test_C_libtooling-woa0`'s HALF of the record and it is
// NOT `Recorded`. `Recorded` names the φs the flatten will convert BY BOOLEAN
// ALGEBRA (so claim and emit share one decision); `RailLeaves` names the φs the
// flatten will NOT convert and therefore READS AS A LEAF of the predicate tree it
// emits — the ones a LATER claim can pull out from under it. Two sets, two
// questions, and the second one only became askable when M4 gave the first a
// placement conjunct. Null for every non-claim scope (the two W6 witnesses), so a
// witness walk records nothing.
struct PhiCondScope {
  const SmallPtrSetImpl<BasicBlock *> *InRegion = nullptr;
  const BasicBlock *Entry = nullptr;
  SmallPtrSetImpl<PHINode *> *Recorded = nullptr;
  SmallPtrSetImpl<PHINode *> *RailLeaves = nullptr;
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
// compare, an and/or tree over such conditions, an xor-true (not), a TWO-OPERAND
// `xor i1` of two in-grammar conditions (bd 3c6m.67), an i1 constant, or (Inc 5)
// a path-predicated i1 phi the flatten will convert. The false-edge literal is
// built by pushing the negation to the leaves (De Morgan for and/or, the
// single-leaf identity ¬(a⊕b) = a ⊕ ¬b for xor), so every emitted predicate tree
// stays inside the 3c6m.12-cleared and/or(/xor)-over-compare-leaves shape and no
// leaf is ever duplicated (the no-NOT invariant).
//
// `Strict` (bd 3c6m.67) — THE SUB-GRAMMAR UNDER AN XOR NODE, and it is a
// MEASURED over-accept fix, not caution for its own sake. Set only by the
// two-operand xor clause below and inherited by everything beneath it, it drops
// the three arms that are PERMISSIVE relative to `collectCondTree`: the i1
// ConstantInt, the convertible i1 PHI, and clang's poison-shielded
// short-circuit SELECT spellings. Under `Strict` the NODE grammar is
// `collectCondTree`'s — compare leaves and distinct-operand and/or/xor over
// them, self-operand fence included — so an xor admitted here is admissible at
// every downstream consumer. (Read that as the NODE grammar precisely: the
// per-LEAF taint and predicate checks still live where they always did, in
// `classifySelectRegion` gate 2, and are unaffected either way.)
//
// WHY, MEASURED (the Rule-13 round on this very increment, four independent
// reviewers). Without it, `xor(select(a,b,false), cmp)` was admitted, because
// the select arm below accepts the shield. `buildNegation`'s xor arm then had to
// route the KEPT operand through `canonicalizePred` to rewrite that shield into
// `and` — and `canonicalizePred` did not `track()` what it replaced, so the
// original SelectInst was STRANDED (the bd `kqqv` orphan class, newly reachable).
// The stranded select was then lowered by the 4.4 select path into a WHOLE DEAD
// controlled-copy merge: an `%out` written by two `cqrt_copy_i1_controlled` and
// never read, `%out`/`%selop` never freed, and a `cq_template_icmp_slt_i32_hl`
// flag never uncomputed and never freed — a dangling ENTANGLED rail (Rules 6/8).
// MEASURED decline (HEAD, 34b7995) -> accept-with-orphans, i.e. exactly the
// direction the Prime Directive polices. NEITHER SHIPPED GATE SEES IT:
// `opt -verify` is clean and `free_pairing_check.py` reports "0 violations"
// because it counts `cqrt_alloc_*` mints and an orphan flag is TEMPLATE-minted
// (bd `1739`).
//
// *** THE STRANDING HALF OF THAT REASONING IS NOW OBSOLETE, AND `Strict` STAYS
// ANYWAY — DO NOT READ THE FIX AS AN INVITATION TO RELAX IT. *** bd `kqqv` made
// `canonicalizePred` open with `trackCondCone(V)`, so it no longer strands what
// it rewrites at any depth; the orphan CLASS this clause was routed around is
// closed. What that changes is the ARGUMENT, not the grammar. Relaxing `Strict`
// would be an accept WIDENING on the single surface five consecutive Rule-13
// rounds have concentrated on, and it owes its own increment: its own decline
// fixtures, its own probe family, its own round, and — the part the orphan fix
// says nothing about — a fresh proof that the ¬(a⊕b) = a ⊕ ¬b identity is still
// safe when the kept operand needs rewriting rather than passing through. Nobody
// has measured that anything WANTS the widening: the four census cells this
// increment exists for (`src/s_nextafterl.c:55` and siblings) carry plain compare
// leaves, and `clang -O1` does not emit a shielded short-circuit under an xor for
// the obvious C (measured, below). Rule 17's carve-out applies verbatim — an
// over-safe decline of a shape we were NOT trying to support is still correct.
//
// One thing that fell out of `Strict` remains true and is worth keeping straight:
// the xor arm of `buildNegation` does not CALL `canonicalizePred` (it is provably
// the identity on a Strict operand) and `canonicalizePred` has no xor recursion.
// Both are now merely unnecessary rather than unsafe.
// Pinned by control_predmux_reject_xor_shielded_select_operand.ll.
//
// AND THE COST IS MEASURED AT ZERO ON REAL C, not merely argued. The obvious
// worry is `if ((a && b) ^ c)` — a short-circuit `&&` directly under an xor,
// which is exactly what Strict refuses in its SHIELDED spelling. Compiled at the
// -O1 ship floor, clang emits
//     %5 = and i1 %3, %4          <- a PLAIN and, NOT select(a, b, false)
//     %7 = xor i1 %6, %5
// and it lowers at exit 0 (8 cnots / 2 toffolis, free_pairing_check strict
// clean), because clang only reaches for the poison-shielded select when it
// cannot speculate the RHS — and a compare leaf is always speculatable. So the
// refused spelling is not what the C shape produces. HEAD declines that same
// module, so this is a decline -> accept even for the compound case.
bool isSupportedCondTree(const Value *V, unsigned Depth,
                         const PhiCondScope *S = nullptr, bool Strict = false) {
  if (Depth > 8)
    return false;
  // *** bd `test_C_libtooling-fn1q` INCREMENT 2 — THE BARE RAIL LEAF. ***
  //
  // The user's own `_Bool` REGISTER as the condition, with no compare anywhere:
  // `bool b = cq_theta(b, .5); if (b) { … }`. Until this increment E6 was the last
  // consumer in the tree that had not been told about the shape — the phase
  // kickback, the depth-2 nest, the Rz-stem angle select, the 4.4 data select, the
  // in-place Ry arm and the state prep have all admitted it since bd `3qlq.4` /
  // `r9e5` / `l4x4`.b — so a multi-phi diamond on a rail condition left at
  // `E6-condtree`, `MergePhiPeel` then peeled every (pred-available) phi, and the
  // EMPTY zero-phi diamond that remained declined `control flow`. That is
  // bd `test_C_libtooling-s9xi`, and it is the bookkeeping the hcrg bullet warns
  // about, not a unitary.
  //
  // ⚠ RULE 14: `isCondRailLeaf` (SelectClassify.h) is THE spelling of this
  // question — a `cq_theta_i1` CALL returning `i1`. It is CALLED here, never
  // re-derived, because a second spelling of a predicate the tree already owns is
  // the drbq Inc-3 (b') defect. Two properties come with it for free and both are
  // load-bearing: such a value is ALWAYS TAINTED (Rule 3 — `cq_theta` is the sole
  // taint source), so this leaf can never smuggle a classical value into a tainted
  // cond tree the way an opaque-`i1` test would; and it is ALREADY an `i1`, so the
  // edge predicate needs no flag mint at all — `collectCondTree` carries it into
  // the 4.4 substrate as a `RailLeaves` entry read only as a CONTROL.
  //
  // ⚠ IT IS REFUSED UNDER `Strict`, DELIBERATELY. `Strict` is the xor sub-tree's
  // forced descent into `collectCondTree`'s grammar, and relaxing it is the
  // separate accept widening the head of this function refuses in writing. A rail
  // leaf under an xor therefore keeps declining — the safe direction, and nothing
  // measured wants it.
  //
  // ⚠ AND IT IS NOT A ONE-LINE WIDENING: `buildNegation` ends in an UNCHECKED
  // `cast<BinaryOperator>(V)`, which a rail leaf reaches on the false edge. Its
  // arm lands in the SAME change (see the `¬rail` note there) — the standing
  // lesson that a grammar widening owes an audit of everything that CONSUMES the
  // grammar, paid here rather than by the next round.
  //
  if (!Strict && isCondRailLeaf(V))
    return true;
  // bd `fn1q` increment 5a — THE RAIL PHI: the `_Bool` bank cell `%cq.bank1` that
  // `promoteRailBankCells` leaves behind for `if (b0[i])`. This is the owner's
  // program's LAST wall; with it admitted the program compiles (measured: exit 0,
  // stage 2b STRICT `3 verified, 0 violation(s), 0 unproven`).
  //
  // ⚠ `isStructuralRailPhi`, NOT `isCondRailPhiShape`. The latter is any
  // 2-incoming `i1` φ and is weak BY DESIGN, because its other consumers finish
  // the proof with `preppedRailPhiRegionIdx` — which THIS GATE CANNOT ASK, PredMux
  // running before `detectControlRegions`. The refinement asks the strongest thing
  // provable here: every incoming is a rail CALL or an `i1` CONSTANT. See its
  // definition for why the obvious taint fallback is refuted by measurement.
  //
  // ⚠ WHAT THIS ADMITS THAT THE DOWNSTREAM STILL REFUSES, stated because it is a
  // real cost and not a gap: a prep under a CLASSICAL condition is not a REGION,
  // so it has no prep index and the 4.4 select declines it. The VERDICT is
  // preserved and no decline becomes silence.
  // ⚠⚠ AND THAT SENTENCE WAS ITSELF MEASURED FALSE — Rule-13 ROUND 2 (R5aR2-1, P1).
  // A DECLINE DID BECOME SILENCE: for a rail φ in a NON-ENTRY region block the flatten
  // CONVERTS it by the select chain, `buildNegation`'s assertion-only
  // `cast<ConstantInt>` returns a constant-FALSE predicate, the arm's cone is
  // dead-swept, and the module compiled at exit 0 with 0 BYTES of stderr and a WRONG
  // unitary where the oracle declined loudly. The placement conjunct at E6 is what
  // makes the claim true again, and it was true only WITHIN ONE PASS until bd
  // `test_C_libtooling-woa0` added the cross-claim RE-ASK
  // (`declineConvertedRailPhiLeaves`). ⚠ THE CONJUNCT IS STILL POINT-IN-TIME —
  // nothing here re-asks it — so do not read the re-ask as making this line
  // total: what is total is the OUTCOME. Either this flatten does not convert
  // the φ, or a later one does and the module declines LOUDLY at the re-ask
  // instead of by `collectCondTree`'s accident. Say "the verdict is preserved",
  // and if you need the mechanism say "because a conversion by a later flatten
  // is OBSERVED and declined", never "because no later flatten converts it".
  // ⚠⚠ "SAME VERDICT, SAME STRING, SAME DIAGNOSTIC" IS WHAT THIS PARAGRAPH FIRST
  // CLAIMED, AND IT IS FALSE (Rule-13 round 1 F2). It was measured on ONE module at
  // ONE polarity. Two counterexamples, both measured:
  //   * the FALSE-successor polarity did not decline at all — it SIGSEGV'd
  //     (`…_reject_rail_phi_false_edge.ll`, the round's P1, fixed in the same
  //     change but only because the round found it);
  //   * a classical-prep rail φ followed by a SECOND independent tainted region
  //     moves the decline STRING: ORACLE `nested control flow under quantum
  //     control`, SUBJECT `control flow under quantum control` — because the
  //     flatten claims and mutates the first region, so the decline lands with a
  //     different owner.
  // THE CORRECT CLAIM IS NARROWER: the verdict (decline) is preserved, and no
  // decline becomes silence. The STRING can move, and Rule 12 pins strings
  // character-for-character, so a decline fixture in this class may change owner.
  // What it costs is DETECT-BEFORE-MUTATE for that one shape: the
  // region is flattened before the decline. That is exactly the cost bd `cfmv`'s
  // round 2 filed as R4R2-1, and it is accepted here KNOWINGLY, under the owner's
  // ruling that a construct with no PHYSICS reason to decline must compile — the
  // classical-prep φ is a classical branch choosing between two circuits, which is
  // realizable, so its decline is compiler structure and is bd `fn1q` increment 5b,
  // not a wall.
  // ⚠⚠ THE PLACEMENT CONJUNCT IS A P1 FIX, NOT A REFINEMENT (bd `fn1q` increment
  // 5a, Rule-13 ROUND 2 finding R5aR2-1). WITHOUT IT THIS ARM ADMITS A φ THE
  // FLATTEN WILL **CONVERT**, AND THE RESULT IS A SILENT WRONG UNITARY.
  //
  // THE MECHANISM, end to end. Admitting here happens BEFORE the
  // `dyn_cast<PHINode>` arm below, so the φ is never inserted into `S->Recorded`.
  // `run()` converts every region block's phis EXCEPT the entry's — so for a φ in
  // a NON-ENTRY region block `convertPhis` DOES run, re-checks the BoolAlg grammar
  // SCOPE-LESSLY, and a `cq_theta_i1` CALL incoming fails `isBooleanCondTree`. The
  // φ therefore falls to the Inc-1 SELECT CHAIN, handing `buildNegation`
  // `select(EP, %rail, true)` — and its select arm's `cast<ConstantInt>` is
  // ASSERTION-ONLY (`(void)TC`), so Release does not crash: it returns
  // `and(¬EP, ¬true)` = **false**. The arm's edge predicate goes CONSTANT-FALSE,
  // its value is dropped from the merge, and its whole cone is dead-swept, so
  // nothing off-grammar survives for a downstream owner to object to. ⚠ THE
  // SILENCE IS STRUCTURAL, NOT LUCKY.
  //
  // MEASURED, from ordinary `CQ.h` C at the `-O1` floor with no `volatile` and no
  // attribute `CQ.h` cannot emit: ORACLE declines loudly at `gate=E6-condtree`;
  // the unfixed SUBJECT exits **0 with 0 BYTES of stderr** and emits a 29-line
  // trace that links and runs, in which the inner `q > 5` compare is ABSENT, both
  // table reads are gone, and the rail is allocated, rotated and measured but
  // NEVER USED AS A CONTROL. `opt -verify` clean; `free_pairing_check.py`
  // `0 violation(s), 0 unproven`. The Prime Directive's named failure mode
  // verbatim, and NEITHER SHIPPED GATE SEES IT.
  //
  // ⚠ FALL THROUGH, DO NOT `return false`. The reviewer's FIRST spelling returned
  // the conjunct and thereby DECLINED an all-constant 2-incoming `i1` φ at a
  // region-interior block — a shape ORACLE and SUBJECT accept BYTE-IDENTICALLY —
  // because such a φ also satisfies `isStructuralRailPhi`, and returning stopped
  // it reaching `isConvertiblePhiCond`, which legitimately admits it (an `i1`
  // `ConstantInt` IS in the strict grammar). Two A→D cells, in neither the corpus
  // nor round 1's probes. A FIX IS A CHANGE.
  //
  // ⚠ THIS IS A NARROWING OF AN ACCEPT PREDICATE (L3). The interior rail φ it now
  // refuses is REALIZABLE — it is an over-decline by the 2026-09-11 owner ruling,
  // filed as such, NOT a physics wall. Making it lower means RECORDING the φ so
  // `convertPhis` does not select-chain it, which is its own increment.
  //
  // ⚠⚠ AND THE CONJUNCT IS A **POINT-IN-TIME** PROPERTY — bd
  // `test_C_libtooling-woa0`, Rule-13 ROUND 3 on this very fix (F-R3-1),
  // MEASURED FIRING on the shipped M4 binary. It says "a φ THIS flatten will not
  // convert", which is true of the region being claimed and FALSE of the
  // PIPELINE: one region is claimed per `flattenPredMuxRegions` call inside a
  // `while (...)` fixpoint, and nothing re-asks E6 about a region already
  // emitted. An inner claim can flatten the φ's own block, making its terminator
  // UNCONDITIONAL, after which an OUTER region's E6 loop (conditional
  // terminators only) no longer sees the φ, claims, and `convertPhis`
  // select-chains it out from under the inner region's already-emitted predicate
  // tree. Before the record below that landed on a loud decline ONLY as a
  // downstream accident — round 2's "a downstream accident, not a fence",
  // verbatim. ⚠ THE MECHANISM NAMED HERE USED TO BE "`collectCondTree` refuses
  // the resulting `xor`-of-`select`" AND THAT IS MEASURABLY FALSE (Rule-13
  // round B, `F-RB-3`, measured on the committed decline fixture's own module
  // on both binaries): there is NO `xor` in the post-flatten module at all —
  // `convertPhis`' "¬c IS AN ARM SWAP, NOT AN `xor` NODE" fold sees to that —
  // and the owner is `SelectClassify`'s DATA-SELECT grammar refusing a
  // `select i1` condition, which it does because that grammar does not carry
  // `AllowLogicalSelect`. The six sites that said `xor` inherited it from round
  // 3's F-R3-1, which describes a different module.
  //
  // SO THE ADMISSION IS RECORDED HERE AND RE-ASKED AFTER THE FIXPOINT (CLAUDE.md
  // L1's standing cure, in both entry points, declining loudly). The record is
  // COMMITTED at CLAIM, not here: a later gate's `leave` discards the whole
  // `PredMuxRegion`, exactly as it does for `BoolAlgPhis`, so an admission that
  // never became an emission cannot make a later claim decline.
  //
  // *** bd `test_C_libtooling-0fly` — WHY THE `!InRegion` DISJUNCT IS SAFE, and
  // *** EXACTLY HOW FAR THAT ARGUMENT REACHES. Written here because it was
  // *** LOAD-BEARING AND UNWRITTEN, which is CLAUDE.md L7's shape, and because
  // *** `isConvertiblePhiCond` reads the SAME test three arms down and fails
  // *** CLOSED on the cell this one fails OPEN on.
  //
  // (1) THE OVER-ADMITTED SET IS EXACTLY `{φ : parent == R.Merge}`, and that is
  //     derived, not estimated. `R.InRegion` is `{E}` plus everything reachable
  //     from `E` WITHOUT CROSSING `Mg` (the collect loop `continue`s on
  //     `B == Mg`), so `R.Merge ∉ R.InRegion`; `topoOrderRegion` returns only
  //     when `R.Topo.size() == R.InRegion.size()`, so `Topo` and `InRegion` are
  //     the same SET; and `run()` converts `(R.Topo \ {R.Entry}) ∪ {R.Merge}`.
  //     Subtract: the test below admits `{R.Entry} ∪ ¬InRegion` where the
  //     intended set is `¬((InRegion \ {Entry}) ∪ {Merge})`, and the difference
  //     is the single block `R.Merge`.
  //
  // (2) THE CONJUNCT HAS EXACTLY ONE CONSUMER THAT CAN RECORD. The claim
  //     `PhiCondScope` is built once and consulted once — at E6's
  //     `isSupportedCondTree(BI->getCondition(), 0, &Scope)`, inside
  //     `for (BasicBlock *B : R.InRegion)` over `B->getTerminator()`. So the
  //     cell is reachable only if a φ parented at `R.Merge` appears in the
  //     condition cone of a CONDITIONAL TERMINATOR OF AN IN-REGION BLOCK, which
  //     by SSA availability requires `R.Merge` to DOMINATE that block.
  //
  // (3) LOOP-FREE, THAT IS REFUSED. Every `B ∈ R.InRegion` is reachable from
  //     `R.Entry` by a path avoiding `R.Merge` (again, by construction in (1)),
  //     so `R.Merge` dominates `B` only if it dominates `R.Entry`. `Mg` is
  //     `E`'s IMMEDIATE POST-DOMINATOR, so it also post-dominates `R.Entry`;
  //     distinct blocks that both dominate and post-dominate each other lie on
  //     a cycle, and with no region block on a cycle E2 leaves at `E2-cycle`
  //     before E6 ever runs.
  //
  // ⚠ (4) IN-LOOP, I COULD NOT CLOSE IT, AND SAYING SO IS THE POINT. Since bd
  //     `fn1q` increment 3, E2 admits a region whose blocks ARE on a cycle when
  //     `regionStrictlyInsideLoopBody` holds. That predicate refuses
  //     `R.Merge == H` (`E2-loopbackedge`) and `getLoopFor(R.Merge) != L`
  //     (`E2-loopstraddle`), which is what makes the first-iteration path
  //     `preheader → H → … → R.Entry` reach `R.Entry` before `R.Merge` in the
  //     ordinary reducible case. Closing the remaining case needs the
  //     back-edge structure of an IRREDUCIBLE cycle through `R.Merge` — and
  //     `topoOrderRegion` cannot see that one, because it orders `R.InRegion`,
  //     which excludes `R.Merge`. **This is an ARGUED gap, not a proven
  //     closure.** Do not upgrade this paragraph to a proof without building
  //     the module.
  //
  // (5) THE W6 WITNESS SCOPES CANNOT BE FOOLED BY IT EITHER, derived the same
  //     way: they pass `InRegion = {Mg}` with `Entry = nullptr` (Convertible)
  //     and `Entry = Mg` (Downstream), and `StrandedCondPhi` is
  //     `Convertible && !Downstream`. For a rail φ at `Mg`, Convertible is
  //     FALSE and Downstream TRUE; for one elsewhere, both are TRUE. Either way
  //     the conjunction is FALSE, so a rail φ can only ever SUPPRESS that
  //     witness, never manufacture it — the safe direction. (Both scopes leave
  //     `RailLeaves` null, so a witness walk records nothing regardless.)
  //
  // (6) MEASURED, FOUR TIMES, BY THREE INSTRUMENTS: round 3 found 22 firings in
  //     18 modules with exactly ONE taking the `!InRegion` branch, in a W6
  //     scope; bd `woa0`'s instrumented commit census found every commit in all
  //     2157 fixtures plus the owner's program to be the ENTRY-φ cell; and the
  //     two Rule-13 rounds of 2026-09-27 reproduced that zero independently.
  //     ⚠ **NO CUSTOMER IN THE CORPUS IS NOT UNREACHABLE** — this file's own
  //     standing caveat, and the reason (4) is written rather than waved away.
  //
  // (7) THE OUTCOME IS COVERED EVEN WHERE (4) IS OPEN. Since bd `woa0`, a
  //     recorded φ that `convertPhis` SELECT-CHAINS — `R.Merge`'s included, and
  //     `convertPhis(R.Merge)` runs inside this very region's `run()` — is
  //     OBSERVED and declined loudly by `declineConvertedRailPhiLeaves`. So the
  //     cell cannot be a silent wrong unitary; it can only be a decline.
  //     COVERED IS NOT CLOSED: that is an argument about the OUTCOME, not about
  //     this conjunct, which is unchanged.
  //
  // ⚠ RETIREMENT TRIGGER (L8): bd `test_C_libtooling-707a`'s route (b) — commit
  // the leaves AFTER `run()`, filtered to the φs the emission actually read —
  // REMOVES the coverage in (7) for this cell, because a φ at `R.Merge` is
  // converted BY THIS REGION and would no longer be in the record at re-ask
  // time. Whoever lands it owes (4) as a PROOF or a FENCE, in the same change.
  // That is also why this is written and not fenced: a fence here would have to
  // be undone by the very increment that makes it matter.
  if (!Strict && isStructuralRailPhi(V)) {
    const auto *RP = cast<PHINode>(V);
    BasicBlock *RPB = const_cast<BasicBlock *>(RP->getParent());
    if (S && S->InRegion && (RPB == S->Entry || !S->InRegion->count(RPB))) {
      if (S->RailLeaves)
        S->RailLeaves->insert(const_cast<PHINode *>(RP));
      return true;
    }
  }
  if (const auto *P = dyn_cast<PHINode>(V))
    return !Strict && isConvertiblePhiCond(P, S, Depth);  // Inc 5 (bd q2wk)
  if (isa<ConstantInt>(V))
    return !Strict;
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp);
  if (const auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::And ||
        BO->getOpcode() == Instruction::Or)
      return isSupportedCondTree(BO->getOperand(0), Depth + 1, S, Strict) &&
             isSupportedCondTree(BO->getOperand(1), Depth + 1, S, Strict);
    if (BO->getOpcode() == Instruction::Xor) {
      if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
        if (C->isOne())
          // The xor-true NOT keeps its PERMISSIVE recursion, unchanged — it is
          // the no-NOT invariant's own negation spelling and `buildNegation`
          // consumes it as ¬¬x = x. Under `Strict` it is unreachable: a
          // ConstantInt operand fails the two-non-constant test below, so no
          // NOT node can sit beneath an xor.
          return !Strict &&
                 isSupportedCondTree(BO->getOperand(0), Depth + 1, S);
      // *** TWO-OPERAND XOR — ADMITTED 2026-08-23 (bd 3c6m.67). ***
      // The construct is the ulp-direction test `if((x>0.0) ^ (x<y))` at
      // `src/s_nextafterl.c:55` / `s_nexttoward.c:54` / `s_nexttowardf.c:45` —
      // the SOLE blocker on four census cells, measured (Phase-0 gate: rewriting
      // only this node into an in-grammar and/or tree takes all four from a loud
      // decline to census COMPILES).
      //
      // THE NO-NOT INVARIANT SURVIVES, which is the only thing that made this a
      // question. E6's contract is that BOTH polarities stay inside the
      // 3c6m.12-cleared and/or-over-compare-leaves shape, built by pushing
      // negation to the leaves; XOR famously does NOT De Morgan-distribute
      // without duplicating leaves, and that is presumably why it was excluded.
      // But the cheap identity avoids the duplication entirely:
      //     ¬(a ⊕ b) = a ⊕ ¬b
      // — negate ONE leaf, keep a SINGLE xor node. The negation still lands at a
      // leaf, no leaf is duplicated, and the emitted tree is still nothing but
      // compare leaves and and/or/xor nodes. `buildNegation` implements exactly
      // that, and DO NOT read this admission without reading that change: its
      // pre-existing `Instruction::Xor` arm returned `operand(0)` unconditionally
      // (correct only while `xor X, 1` was the sole admitted xor), so widening
      // here ALONE would have made ¬(a⊕b) evaluate to `a` — verify-clean,
      // free-pairing-clean, silently wrong. Pinned by
      // control_predmux_accept_xor_negation.ll.
      //
      // Constant operands are excluded so this clause cannot swallow the
      // `xor X, 1` NOT above (which has its own ¬¬x = x rule) — and, separately,
      // so E6 does not admit a shape `collectCondTree` refuses outright.
      // `Strict=true` on BOTH children is the over-accept fix documented at the
      // head of this function: it forces the whole sub-tree into
      // `collectCondTree`'s grammar, which is what makes the negation identity
      // safe to apply without `canonicalizePred` and closes the stranded-shield
      // orphan. It is inherited downward, so a shield nested three `and`s deep
      // under an xor is refused too.
      if (!isa<Constant>(BO->getOperand(0)) &&
          !isa<Constant>(BO->getOperand(1)) &&
          // …and `collectCondTree`'s SELF-OPERAND node fence, mirrored here so
          // the "matches collectCondTree" claim above is literally true rather
          // than nearly true (bd 3c6m.67, Rule-13 round 2). Without it
          // `xor i1 %c, %c` passed the E6 CLAIM, the region was FLATTENED, and
          // the decline then landed downstream in the 4.4 select path under a
          // different diagnostic than HEAD's — a mutate-then-decline where HEAD
          // declined pre-claim. Never a miscompile (both exit non-zero, nothing
          // is consumed), and unreachable from -O1 C because InstCombine folds
          // `x ^ x` to false — but a claim this file makes about its own grammar
          // should hold exactly, and a pre-claim decline is strictly cleaner.
          BO->getOperand(0) != BO->getOperand(1))
        return isSupportedCondTree(BO->getOperand(0), Depth + 1, S,
                                   /*Strict=*/true) &&
               isSupportedCondTree(BO->getOperand(1), Depth + 1, S,
                                   /*Strict=*/true);
    }
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
    // bd 3c6m.67 — refused UNDER AN XOR. This is the arm whose admission
    // stranded a shield in `buildNegation` and emitted a dead select merge with
    // an un-freed entangled flag; see the `Strict` note at the head of this
    // function for the measurement, and read its bd `kqqv` paragraph before
    // touching this line — `canonicalizePred` now tracks, so the refusal survives
    // on GRAMMAR-CONSERVATISM grounds alone and lifting it is a separate accept
    // widening, never a follow-on. Outside an xor this arm is completely
    // unchanged.
    if (Strict)
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
  // bd 3c6m.67 — XOR IS DELIBERATELY *NOT* ADMITTED HERE, and this note exists
  // so the absence reads as a decision rather than as the oversight that started
  // 3c6m.67 in the first place (the `collectCondTree` xor bail carried no
  // rationale for a year and hardened into a de-facto rule by repetition — the
  // failure mode bd [[bennett-grounding-asymmetry-2026-07-28]] warns about).
  // THE REASON: this is the STRICT substrate grammar gating i1-phi convertibility
  // (Inc 5 / bd q2wk), deliberately narrower than the permissive
  // `isSupportedCondTree` — it already refuses the xor-true that E6 admits, and
  // control_predmux_reject_i1phi_offgrammar_xor.ll pins exactly that gap for a
  // stated soundness reason (a permissive claim here would drop `convertPhis`
  // into the Inc-1 select-chain fallback and hand `buildNegation` a general
  // select whose arms are not the 0/1 constants its `cast<ConstantInt>` assumes
  // — a BROKEN MODULE, not a decline). NOTHING MEASURED WANTS IT: the four
  // 3c6m.67 census cells carry their xor as a plain branch condition, not as a
  // phi incoming. So an xor under a phi keeps declining loudly, which is the
  // safe direction. Widening it would owe its own red-green pair and its own
  // Rule-13 round — do that, or leave it; do not do it in passing.
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
// *** bd ziuw MOVED THESE NUMBERS AND THE GREP NO LONGER FINDS THE DESCENT.
// READ THIS BEFORE TRUSTING A RE-COUNT. *** The walk used to descend into an
// inner call by CALLING ITSELF (`...BodyImpl` -> `...BodyWalk` ->
// `...BodyImpl`), so the descent was one of the textual call expressions the
// grep returned. It is now an explicit worklist: `...BodyWalk` no longer exists
// and the descent is the `enter(CI2->getCalledFunction())` PUSH inside
// `...BodyImpl`, which the grep above CANNOT see. The surface it implements —
// S5 below — is unchanged and still has its fixture; only its spelling moved.
// Keep the `Walk` alternative in the grep anyway: it costs nothing and it is how
// a reader confirms the name is really gone rather than assuming it.
//
// *** THE GREP RETURNS 11 LINES AND SIX OF THEM ARE NOT CALL EXPRESSIONS. ***
// The block used to name only one discard rule and a Rule-13 lens re-counted to
// the PRE-ziuw number off the noise, so all six are listed: the grep STRING
// itself (it self-matches), the three definitions, the header declaration in
// `PredMuxFlatten.h`, and the prose quote in the resume-arm comment inside
// `...BodyImpl` — which describes the old call in the past tense and is
// deliberately written WITHOUT parentheses so it no longer looks like one.
//
//   textual call EXPRESSIONS of any of the three names ........... 5
//     ... minus the two pure forwarders ........................... 3
//   distinct CONSUMERS that make an accept decision ............... 3
//   distinct CONTEXTS those 3 consumers run in .................... 4
//   self-recursion ................................................ 0
//   the descent, now un-greppable, spelled `enter(...)` ........... 1
//
// *** THE COUNTING UNIT, SPELLED OUT, because re-deriving it cost ten minutes and
// the block above only implies it. *** "the three names" means
// `isSpeculatablePureCallee` / `...Body` / `...BodyImpl`. THREE TABLES RATHER
// THAN A DELTA RECIPE — the deltas do not compose, because ziuw did not
// decrement the old row 2, it DELETED it and promoted row 3:
//   pre-wve8  5 / 4 / 2 / 2 / 3 / 1   rows: exprs / minus-recursion /
//                                     minus-both / consumers / contexts /
//                                     self-recursion
//   pre-ziuw  6 / 5 / 3 / 3 / 4 / 1   same rows (wve8 added one consumer whose
//                                     entry point calls `Impl` directly; the
//                                     self-recursion row was 1 before and after)
//   now       5 / 3 / 3 / 4 / 0 / 1   rows: exprs / minus-FORWARDERS /
//                                     consumers / contexts / self-recursion /
//                                     descent
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
//   S5 the proof's own DESCENT into an inner call — a clean outer callee over a
//      compare-bearing inner one. (bd ziuw: a worklist push, no longer a C++
//      recursion. Same surface, same fixture, different spelling.)
//      *** DO NOT READ A GREEN 1069 AS COVERAGE OF S5. *** Re-derive rather than
//      inherit — `CQ_PREDMUX_COUNT=1` over every committed fixture, parsing the
//      COUNT line. WITH the three ziuw fixtures landed:
//        91 fixtures print >=1 pure-callee COUNT line; 98 (fixture,root) pairs
//        5 roots reach `bodies>=2`, i.e. can observe the descent AT ALL, across
//          FOUR fixtures: `..._transitive` (2), `..._memo_cost` (9 and 25),
//          `..._multiblock_resume` (5), `..._cycle_under_memo` (5)
//        4 roots have `hits>0`; 2 have a cycle return (`inv-bodies-hits>0`)
//      BEFORE they landed it was 89 / 3 / 3 / 1. *** STATE WHICH SIDE OF ITS OWN
//      COMMIT A CENSUS IS ON. *** The first draft of this note gave the BEFORE
//      numbers in the present tense, so a Rule-11 re-count got a mismatch and read
//      it as drift — the same trap this block spends thirty lines correcting for
//      the call-expression count, re-laid one paragraph down.
//      `..._deep_chain.ll` prints NOTHING here: its committed module is empty and
//      its 60001 is measured on the GENERATED input, not on a committed fixture.
//      Everything else walks a single body — which is why the ziuw no-regression
//      claim rests on generated call-graph populations, not on the corpus.
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
// both contexts (S1/S2) and S3 `Fp80Union`'s seed cone — plus the DESCENT
// below (S5; a worklist push since bd ziuw, not a recursion); each has a
// fixture.
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
  // flag lives in the QUERY, so the descent inherits it and the per-query memo
  // can never serve a lax verdict to a strict query (each top-level entry mints
  // a fresh `PureCalleeQuery`).
  bool AdmitDeferred = true;
};

// bd ziuw — ONE SUSPENDED ACTIVATION OF THE BODY WALK. The walk used to be a
// C++ mutual recursion (`...BodyImpl` <-> `...BodyWalk`) which SIGILLed with
// ZERO stderr on a ~37.4k-node pure call chain, i.e. A CRASH PRE-EMPTED THE
// LOUD DECLINE (Prime Directive). It is now an explicit worklist over these
// frames; the descent below is a `push`, so the only bound is heap.
//
// THE SHAPE OF THE OLD FAILURE, MEASURED, AND IT IS BUILD-CONFIGURATION
// DEPENDENT — do not restate it as structure. A mutual recursion between two
// functions is NOMINALLY two frames per node; in the shipped Release build it
// was ONE, because the compiler inlines `Walk` into `Impl` (`nm -a` on a
// pre-change `cq-opt` shows no `...BodyWalk` symbol at all). `otool -tvV` puts
// that frame at 224 bytes, and the crash bisects to between D=37300 (rc=0) and
// D=37400 (rc=132): 37350 x 224 = 7.98 MB against an 8 MB main-thread stack — a
// one-frame-per-node fit, where two frames would have broken near 18.7k.
//
// *** THIS REMOVES ONE OF FOUR ONE-FRAME-PER-NODE RECURSIONS, AND THE OTHER
// THREE PRODUCE THE IDENTICAL SIGNATURE — rc=132, ZERO stderr, no diagnostic.
// DO NOT QUOTE THIS REWRITE AS HAVING REMOVED THE PREEMPTION GENERALLY. *** All
// three are PRE-EXISTING and byte-identical on the pre-change binary, so ziuw
// neither caused nor cured any of them; all were MEASURED by its Rule-13 round:
//   `SpecializeReject::scanBody` .... ~4000 nodes, the cheapest to trigger. On
//      the LAX S1/S2 path, which mints a Phase-6 clone. A 4000-node chain under
//      the shipped E4 driver exits rc=132 with THIS walk's own successful
//      `invocations=4001 verdict=1` COUNT line as the only stderr (bracket
//      D=3500 rc=0 / D=4000 rc=132). bd 3c4i, which is also where the SECOND,
//      independent `scanBody` exponential noted ~40 lines ABOVE belongs (the
//      per-candidate `OnStack` re-walk — same function, a different cost axis).
//   `ByRefInline::cloneExpr` ........ ~65k, one frame per operand-cone node.
//   `RegionFlattener::edgePred` ..... ~42k — *** IN THIS FILE ***, and on a path
//      that never queries the pure-callee walk at all, so "lax vs strict
//      consumer" does not even describe it. The trigger is the merge phi's
//      INCOMING ORDER alone: the byte-identical module with the two incomings
//      swapped survives D=400000. bd t2fw, together with the separate finding
//      that the region flatten is roughly CUBIC — that one needs no adversarial
//      depth at all (a 1603-line file of flat `if`s costs 9.6s of CPU today).
// WHAT IS GENUINELY FIXED: the STRICT/S6 entry, at any depth, because 6.5 is
// clone-ORTHOGONAL and nothing recurses behind it.
//
// *** A DEPTH BUDGET IS STILL FORBIDDEN — BUT NOT FOR THE REASON THE TICKET AND
// THE FIRST DRAFT OF THIS COMMENT GAVE, AND THE WRONG REASON IS WORSE THAN NONE
// BECAUSE IT NAMES A MECHANISM A READER CAN CHECK AND FIND ABSENT. ***
//
// The draft said a cut-off FALSE "would be written into the memo and later
// served to a SHALLOWER query in the same walk". `PureCalleeQuery::Memo` really
// is keyed on `const Function *` with no depth component — but that particular
// mechanism CANNOT FIRE HERE. Any FALSE returned to a caller aborts that caller
// through the very same `if (!Ret) { … leave(F, false); }` arm, so one FALSE
// unwinds every ancestor to the root and ENDS the query; no frame survives to
// consult the entry that was just written. MEASURED by the ziuw Rule-13 round on
// an instrumented build over 685 modules / 779 queries (600 of them cycle-dense):
// 77 memo hits served TRUE, ZERO served FALSE.
//
// THE REASON THAT SURVIVES INSPECTION: a budget-induced FALSE propagates through
// that same arm, so it poisons the WHOLE query up to the root — the verdict of a
// perfectly provable callee becomes an artefact of how deep its call graph
// happens to be, and the pinned `Invocations`/`BodiesWalked`/`MemoHits` triple
// becomes depth-dependent. Say the direction plainly rather than inflating it:
// that is an over-DECLINE, so it is safe under the Prime Directive and is a
// capability + determinism defect, NOT a silent miscompile. It is still the shape
// bd xzdx forbids (bd memory
// [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]]: "ANY cut-off inside a
// memoised function is part of its answer" — and a gate whose answer depends on
// entry order is a gate people learn to bypass), and it is why bd s6ao's QROM
// walk took the same iterative rewrite rather than a cap.
struct PureCalleeFrame {
  const Function *F = nullptr;
  Function::const_iterator BBIt{};   // block cursor; `== F->end()` ⇒ body passed
  BasicBlock::const_iterator IIt{};  // instruction cursor inside `*BBIt`
  bool CycleChecked = false;         // the CFG-SCC test has run for `F`
  bool BlockEntered = false;         // the terminator prologue has run for `*BBIt`
  // A callee verdict for the call at `IIt` is PENDING IN `Ret` — either a child
  // frame was pushed, OR `enter` settled the callee outright (guard reject, memo
  // hit, OnStack cycle). Both cases resume through the same arm, which is why
  // the descent sets this UNCONDITIONALLY; "tightening" it to
  // `if (!enter(...)) AwaitingCall = true;` would spin the driver forever on
  // that instruction (and read `Fr` after a possible reallocation).
  bool AwaitingCall = false;
};

bool isSpeculatablePureCalleeBodyImpl(const Function *Root, PureCalleeQuery &Q) {
  SmallVector<PureCalleeFrame, 16> Stack;
  bool Ret = false;  // verdict of the most recently SETTLED node

  // Everything the recursive `...BodyImpl` did BEFORE the body walk, unchanged
  // and in the same order — which is what keeps `Invocations` / `BodiesWalked` /
  // `MemoHits` identical to the recursive version, those three being the pinned
  // cost observable (bd 3c6m.14.4). Either settles the node outright (returns
  // true, verdict in `Ret`) or pushes its frame (returns false).
  //
  // *** SCOPE THAT EQUALITY, DO NOT UNIVERSALLY QUANTIFY IT. *** It holds on
  // every input THE RECURSIVE VERSION COULD COMPLETE — above ~37.3k nodes that
  // version emitted no counters and no stream at all, which is the whole reason
  // this rewrite exists, so there is nothing to be equal to up there.
  //
  // *** IT MAY REALLOCATE `Stack`. NEVER HOLD A FRAME REFERENCE ACROSS IT. ***
  auto enter = [&](const Function *F) -> bool {
    // hasExactDefinition: a body this proof reads must be the body that LINKS —
    // an INTERPOSABLE definition (weak_any/linkonce_any/common/extern_weak) may
    // be replaced by the linker, so a purity/termination proof over the
    // module-local body would be baked into the speculated hoist and the Bennett
    // clone while a different function runs at stage 3 (the adia Rule-13 board's
    // confirmed fence gap; the ByRefInline hasLocalLinkage precedent). NOTE (bd
    // gxhi, empirically verified against LLVM 19): `hasExactDefinition()` is
    // `!isDeclaration() && !mayBeDerefined()`, and `mayBeDerefined()` is TRUE for
    // weak_odr/linkonce_odr/available_externally — so this predicate ALSO
    // declines those ODR variants, NOT only the arbitrary-replacement
    // interposable set. That is a SAFE over-decline (Prime Directive) with zero
    // corpus cost (openlibm has no weak symbols); admitting the ODR variants
    // would be a deliberate `!isInterposable()` widening, a separate ticket.
    // Declarations fail here too.
    //
    // F-local and cheap; deliberately NOT memoised. It is also counted BEFORE
    // `Invocations` is bumped, so that `Invocations - BodiesWalked` really is the
    // memo-hit count: counting guard rejects and cycle returns as "hits" made the
    // number a mislabel (a module with one `declare`d callee and no memo activity
    // at all reported `hits=1`), found by the bd u1rp Rule-13 round.
    if (!F || !F->hasExactDefinition() || F->isVarArg()) {
      Ret = false;
      return true;
    }
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
      Ret = It->second;
      return true;
    }
    if (!Q.OnStack.insert(F).second) {
      Ret = false;  // call-graph cycle: termination unprovable. NOT memoised.
      return true;
    }
    ++Q.BodiesWalked;
    PureCalleeFrame Fr;
    Fr.F = F;
    Stack.push_back(Fr);
    return false;
  };

  // Everything the recursive `...BodyImpl` did AFTER the body walk: the
  // `make_scope_exit` OnStack pop and the memo write. It is called at exactly
  // the points the old `...BodyWalk` `return`ed from — which is what preserves
  // "only a COMPLETED walk is recorded" now that the two functions are one.
  //
  // *** THE `make_scope_exit` SAFETY NET IS GONE, SO THE PAIRING IS SPELLED OUT
  // RATHER THAN LEFT CONVENTIONAL. *** The recursive version could not leak an
  // OnStack entry: the scope guard fired on every return path, including ones a
  // future editor added. Here the erase lives in this lambda, so the invariant
  // would otherwise rest on two unwritten rules — that the driver has no early
  // exit, and that nothing calls `leave` after `enter` has pushed. Both hold
  // today (the driver's only `return` is after the loop and its only `break` is
  // inside the SCC loop), but the natural future edits break them SILENTLY: a
  // `return false;` for a new bail-out clause strands frames and OnStack entries,
  // and writing the descent as `if (enter(C)) { if (!Ret) leave(…); }` would
  // settle the CHILD with the PARENT's verdict whenever `enter` pushed.
  //
  // So `leave` NAMES the frame it settles and asserts the pairing, and the driver
  // asserts it drained. TWO RULES for anyone editing the loop below:
  //   (1) `leave` must be the last statement before a `continue`, and must never
  //       follow `enter` in the same step;
  //   (2) the loop must have no `return`/`break` of its own.
  // NB the plugin ships `-DNDEBUG`, so these asserts are documentation plus a
  // Debug-build net — NOT a runtime guard in the shipped build. They were still
  // turned into EVIDENCE rather than left as decoration: an assertions-enabled
  // `cq-opt` (a second build dir with `-DCMAKE_CXX_FLAGS_RELEASE=-O2` — NOT
  // `-UNDEBUG` in `CMAKE_CXX_FLAGS`, which CMake overrides by appending
  // `..._RELEASE`'s own `-DNDEBUG` after it, silently producing a binary with no
  // asserts at all) swept the whole corpus and both generated populations, and a
  // MUTANT built in a `git worktree` — one call site handed `Root` instead of the
  // top frame — fires this exact assert on
  // `lowering_predmux_purecallee_multiblock_resume.ll` while the clean binary
  // passes it at rc=0. A checker nobody has tried to fool is a checker nobody
  // should trust.
  auto leave = [&](const Function *LF, bool R) {
    assert(!Stack.empty() && Stack.back().F == LF &&
           "leave() must settle the frame on top of the stack");
    assert(Q.OnStack.count(LF) && "leave() without an OnStack entry");
    Q.OnStack.erase(LF);
    Q.Memo[LF] = R;
    Stack.pop_back();
    Ret = R;
  };

  if (enter(Root))
    return Ret;

  // The driver. One SMALL STEP per iteration, and every step that pushes or pops
  // `continue`s immediately, because `Fr` is a reference INTO `Stack`. The order
  // of steps below is the order of the recursive walk's statements, so the
  // CQ_PREDMUX_DBG stream and the CQ_PREDMUX_COUNT triple come out byte-
  // identical — including the interleaving where a child prints its own failure
  // line before its caller prints "fails at call".
  //
  // THE EVIDENCE, WITH ITS POPULATIONS NAMED, because the corpus alone has
  // almost no power here (only three committed fixtures reach `bodies>=2` — see
  // the S5 note above). Against a `cq-opt` pinned at the pre-change commit,
  // comparing stdout + stderr + EXIT CODE with both debug streams on:
  //   * all 1069 committed fixtures ............................ 0 mismatches
  //   * 2000 generated call-graph modules (DAG fan-out, memo hits, call-graph
  //     cycles, vararg/declare/weak callees, every reject clause, both the lax
  //     and strict drivers) .................................... 0 mismatches
  //   * (Rule-13 lens 1, independently) 510 targeted + generated modules, 300
  //     multi-block deep DAGs, and 18 chains of 3000..35000 nodes with the
  //     reject planted at leaf / mid-depth ..................... 0 mismatches
  //   * (lens 2) 690 cycle-dense modules, plus an instrumented comparison of the
  //     MEMO SET itself rather than only the verdict ........... 0 mismatches
  //   * (lens 3) 1060 modules incl. D=3000 and D=30000 ......... 0 mismatches
  // Chains deeper than that CANNOT be differentially compared: one side crashes.
  // One of the 1069 is a vacuous row — `..._deep_chain.ll`'s committed module is
  // empty by construction; see its header.
  //
  // *** ONLY THE CHAIN BULLETS REACH THE REALLOC HAZARD THE NOTE ABOVE SINGLES
  // OUT IN CAPITALS, AND A REPLACEMENT POPULATION THAT LOSES THAT LOSES THE ONLY
  // EVIDENCE FOR IT. *** `SmallVector<PureCalleeFrame, 16>` holds 16 frames
  // INLINE, so nothing reallocates below depth 17 — and the first two bullets are
  // structurally under that line. MEASURED, and bodies-walked is an upper bound
  // on simultaneous frame depth: the generated call-graph population maxes out at
  // 8 (its modules are 2..9 functions with only forward edges), and the deepest
  // committed fixture is `..._purecallee_memo_cost.ll`'s D=12 doubling chain at
  // 13 — higher than the population, still under 16. Measured
  // the other way too: the exact reorder the note forbids is byte-identical to
  // the pre-change binary at every depth <= 16 and only corrupts the counter
  // triple at depth 41. Any future population must exceed depth 16 or this
  // hazard goes untested while the evidence block still reads as three
  // independent confirmations.
  while (!Stack.empty()) {
    PureCalleeFrame &Fr = Stack.back();
    const Function *F = Fr.F;

    if (!Fr.CycleChecked) {
      Fr.CycleChecked = true;
      bool Cyclic = false;
      for (scc_iterator<const Function *> It = scc_begin(F); !It.isAtEnd(); ++It)
        if (It->size() > 1 || It.hasCycle()) {
          Cyclic = true;  // a CFG cycle: termination unprovable
          break;
        }
      if (Cyclic) {
        leave(F, false);
        continue;
      }
      Fr.BBIt = F->begin();
      continue;
    }

    // Resume point: the callee at `Fr.IIt` has settled into `Ret`. This is the
    // old `if isSpeculatablePureCalleeBodyImpl-returned-true then continue`,
    // split across the descent. (Spelled without parentheses on purpose: the
    // census grep above returns this line, and a reader discarding only
    // definitions would count it as a call expression.)
    if (Fr.AwaitingCall) {
      Fr.AwaitingCall = false;
      if (!Ret) {
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at call: " << *Fr.IIt << "\n";
        leave(F, false);
        continue;
      }
      ++Fr.IIt;
      continue;
    }

    if (Fr.BBIt == F->end()) {  // every block passed: the old trailing `return true`
      leave(F, true);
      continue;
    }

    if (!Fr.BlockEntered) {
      const Instruction *Term = Fr.BBIt->getTerminator();
      if (!isa<BranchInst>(Term) && !isa<ReturnInst>(Term)) {
        leave(F, false);
        continue;
      }
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
            leave(F, false);
            continue;
          }
      Fr.BlockEntered = true;
      Fr.IIt = Fr.BBIt->begin();
      continue;
    }

    if (Fr.IIt == Fr.BBIt->end()) {  // next block
      ++Fr.BBIt;
      Fr.BlockEntered = false;
      continue;
    }

    const Instruction &I = *Fr.IIt;
    if (I.isTerminator()) {
      ++Fr.IIt;
      continue;
    }
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
      leave(F, false);
      continue;
    }
    if (const auto *CI2 = dyn_cast<CallInst>(&I)) {
      if (isCuratedReversibleIntrinsic(CI2) && CI2->doesNotAccessMemory()) {
        ++Fr.IIt;
        continue;
      }
      // THE DESCENT (surface S5). Formerly the mutual recursion; now a push.
      // Set the resume flag BEFORE calling `enter`, which may reallocate `Stack`
      // and leave `Fr` dangling. Whether `enter` pushes a child frame or settles
      // the callee outright, the `AwaitingCall` arm above consumes `Ret`.
      Fr.AwaitingCall = true;
      enter(CI2->getCalledFunction());
      continue;
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
      leave(F, false);
      continue;
    }
    ++Fr.IIt;
  }
  // *** THE FIRST VERSION OF THIS WAS `assert(Stack.empty())` ALONE, WHICH IS
  // TAUTOLOGICAL HERE — it sits directly after `while (!Stack.empty())` — AND
  // MEASURED POWERLESS AGAINST THE LEAK IT WAS ADDED FOR. *** A Rule-13 mutant
  // that removed `Q.OnStack.erase(LF)` from `leave` (stranding one entry per
  // settled node) drains the frame stack perfectly normally: the `Stack` check
  // passed and only the OnStack one fired. A `leave` handed the WRONG `F` also
  // drains `Stack` cleanly — it erases the wrong entry and strands the right
  // one — so the `Stack` check misses that too while the OnStack check catches
  // it (in a Debug build `leave`'s own pairing assert fires first; this is the
  // backstop for the day someone edits the erase). The OnStack check is
  // therefore the load-bearing one —
  // it is not implied by the loop condition, and a stranded entry is nasty
  // precisely because `enter`'s memo lookup PRECEDES its OnStack test, so it is
  // invisible on the memo path and only surfaces later as a spurious cycle-FALSE.
  // Keep both: `Stack` names the `break`-with-live-frames case separately.
  //
  // NOTE WHAT NEITHER CATCHES, so rule (2) above is not over-read: a `return`
  // added INSIDE the loop bypasses both asserts entirely. They enforce the
  // `break` half of that rule and nothing enforces the `return` half.
  assert(Q.OnStack.empty() && "driver exited with a stranded OnStack entry");
  assert(Stack.empty() && "driver exited with a live frame");
  return Ret;
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
  // Its own env var, so the fixtures that FileCheck the CQ_PREDMUX_DBG stream
  // do not drift. STATE THE UNIT — the number that used to stand here ("ten")
  // matched nothing in the tree and never had: 27 fixtures set
  // `CQ_PREDMUX_DBG=1` in a RUN line, 27 use a DBG check-prefix, and 5 assert a
  // `pure-callee` line specifically
  //   grep -rlE '^; *[A-Za-z0-9_-]+(-NOT)?:.*pure-callee' ir-pass/test/*.ll
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

// bd `test_C_libtooling-woa0` — "is this φ one that an ALREADY-EMITTED region's
// predicate tree reads as a rail leaf?", asked by linear scan over `WeakVH`.
//
// ⚠ THE HANDLE IS THE POINT, NOT THE CONTAINER. A recorded φ can be erased by a
// path that is not `convertPhis` (its consuming cone dead-swept), and LLVM reuses
// freed `Instruction` memory — a raw `PHINode *` set would then match a FRESH φ
// allocated at the same address and manufacture a decline from nothing, which is
// the worst kind of false red because it is not reproducible. A `WeakVH` nulls on
// deletion, and (unlike `WeakTrackingVH`) does NOT follow RAUW, so it keeps
// naming the φ right through `convertPhis`' `replaceAllUsesWith` and stops naming
// anything the instant the φ dies. Linear is right: the set is a handful.
bool recordHoldsRailPhiLeaf(const PredMuxRailPhiRecord &Rec, const PHINode *P) {
  const Value *Needle = P;
  for (const WeakVH &H : Rec.Leaves)
    if (static_cast<const Value *>(H) == Needle)
      return true;
  return false;
}

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
  // bd `test_C_libtooling-woa0` — the rail φs E6 admitted as condition-tree
  // LEAVES, i.e. the ones this flatten proved it will NOT convert. ⚠ THIS SAID
  // "and will therefore READ" AND THAT INFERENCE IS FALSE (`F-RA-1`/`F-RB-1`):
  // `run()` mints edge predicates LAZILY, so an admitted φ may never be read. Populated during E6 beside `BoolAlgPhis` and discarded with
  // `R` on any later `leave`; COMMITTED into the caller's cross-claim
  // `PredMuxRailPhiRecord` only once the claim is final, immediately before
  // `RegionFlattener::run()`. Disjoint from `BoolAlgPhis` in practice but not by
  // construction — the two answer different questions and nothing needs them to
  // partition.
  SmallPtrSet<PHINode *, 4> RailPhiLeaves;
  // bd xdu2.8 — classical runtime-VLA reads E4 admitted ONLY because a classical
  // conjunct of the arm's own path condition bounds the index
  // (`classicalRuntimeAllocaReadIsInBoundsUnderGuard`). The flatten must rewrite
  // each one's address to the bounds-checked select before the speculation is
  // final (`guardSpeculatedClassicalRead`); an unrewritten entry would be an
  // introduced out-of-bounds read. Captured at E4 time, discarded with `R` on any
  // later `leave` (the `MaskLoads` precedent: analysis decides, flatten executes).
  SmallVector<std::pair<LoadInst *, Value *>, 4> GuardedLoads;  // (load, proved extent)
  // bd `test_C_libtooling-xdu2.13` — branch conditions E6 admitted by rule (B)
  // (untainted now, predicted tainted by the flatten). Marked at the claim and
  // at every `literal()` built from them; see `CondLiteral.h` conjunct (c).
  // `WeakVH`: a condition φ that `convertPhis` RAUWs and erases nulls here — its
  // replacement is the tainted boolean-algebra value, which needs no mark.
  SmallVector<WeakVH, 2> PredictedConds;
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
//
// bd fn1q inc 3 — IDEMPOTENT (`R.Topo.clear()`), because E2's in-loop admission
// calls it as its REGION-ACYCLICITY proof and the tail of `recoverRegion` calls
// it again for the order itself. Rule 14: one spelling of "is this region a
// DAG, and in what order", two callers — not a second hand-rolled walk. (It is
// pure: `R.Topo` is per-candidate and every `leave` discards the whole `R`.)
bool topoOrderRegion(PredMuxRegion &R) {
  R.Topo.clear();
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

// bd fn1q increment 3 — E2's IN-LOOP admission: is `R` an acyclic region lying
// STRICTLY INSIDE one natural loop's body?
//
// ⚠ WHAT THE OLD STRUCTURE WAS HOLDING. The gate this replaces was the single
// clause `for (B : R.InRegion) if (OnCycle.count(B)) leave("E2-cycle")`, and
// increments 1 and 2 of this bead each paid for replacing a STRUCTURAL
// containment with predicates without enumerating what the structure held (a
// `cq_phi` hoisted and deleted; a `cq_theta_i1` swept and deleted). So, by
// name, `OnCycle` was refusing FIVE distinct things:
//
//   (a) a region that CONTAINS a whole loop — entry outside it, an arm being
//       the loop. `lowering_ctlz_idiom_guarded_no_preshift.ll` is that shape.
//       Refused below because `L` is taken from `R.Entry`: an entry outside
//       every loop gives `L == nullptr`.
//   (b) a region containing the loop HEADER as a NON-ENTRY block — the header
//       then has a reaching edge (the preheader's, or the latch's) that the
//       flatten does not predicate. `E2-loopheader`.
//       ⚠ THIS CLAUSE IS REACHED, AND THE FIRST VERSION OF THIS PARAGRAPH SAID
//       IT WAS NOT. It claimed "no probe reaches this clause AS THE SOLE
//       REFUSAL, and the argument says none can", on a single-latch construction
//       that lands on (c). Rule-13 round 1 falsified it with a MULTI-LATCH loop
//       (`control_predmux_reject_inloop_header_nonentry.ll`): entry `%A` is a
//       non-header block, `%L1a`/`%L1b` branch back to the header `%H`, so `%H`
//       enters the region as a NON-ENTRY block and this clause fires by name.
//       ⚠ It is still not the SOLE refusal — with clause (b) deleted and the
//       tree rebuilt, that module declines at `E2-regioncycle` instead and NO
//       shipped fixture changes verdict (measured on a mutant binary). So the
//       honest statement is: REACHED, FIRST-FIRING, and BACKSTOPPED — not
//       unreachable, and not load-bearing. Keep it for the gate name; do not
//       cite it as the thing that makes a header-in-region region safe.
//       ⚠ THE ENTRY ITSELF MAY BE THE HEADER, and refusing that was this
//       increment's own first draft — measured wrong on its own subject, where
//       `-O1` puts the `cq_theta` and the `br` in the header block, so the
//       shape this increment exists for IS a header-entry region. It is safe
//       for the same reason every other entry is: the flatten appends to the
//       entry's body and rewrites only its TERMINATOR, so the header keeps its
//       phis, its incoming edges and its position. What a header entry could
//       additionally reach — a region that swallows the latch, hence the back
//       edge — is refused by the acyclicity proof below (the back edge makes
//       `InDeg[Entry] != 0`), and a header entry whose branch is the loop's own
//       tainted EXIT is refused by (d) on the merge.
//   (c) a region whose MERGE is a loop HEADER — then the entry->merge edge the
//       flatten makes UNCONDITIONAL is a BACK EDGE, so a loop that exited
//       through an arm would stop exiting. `E2-loopbackedge`.
//   (d) a region that STRADDLES a loop boundary: a block in an inner loop, a
//       block outside `L`, or a MERGE outside `L`. ⚠ The merge half is the one
//       that matters most — it is how a TAINTED LOOP-EXIT branch presents
//       (the exit target is outside `L`), and flattening one would delete a
//       quantum-bounded exit that `LoopLowering`'s Q1 decline exists to refuse,
//       BEFORE Q1 ever runs. `E2-loopstraddle`. ⚠ MEASURED on BOTH halves,
//       because this paragraph's first draft asserted the loop-exit half with
//       no probe behind it and the first probe written for it never reached the
//       clause at all (it left at `W-witness`):
//       `control_predmux_reject_inloop_tainted_exit.ll` pins the merge half and
//       `control_predmux_reject_inloop_inner_loop.ll` the block half.
//   (e) an IRREDUCIBLE cycle, which `LoopInfo` does not model at all: one lying
//       wholly inside `L` reports `L` for EVERY one of its blocks, so every
//       `getLoopFor` test above PASSES on it and only an acyclicity proof sees
//       it. Reachable and pinned by TWO fixtures that are not the same shape:
//       `control_predmux_reject_inloop_irreducible.ll` (cycle entered from
//       outside the region) and `…_reject_inloop_irreducible_inregion.ll` (BOTH
//       entries in-region and every terminator tainted, so E3 and E6 are blind
//       to it — the shape this clause actually exists for).
//       ⚠ WHAT THE `topoOrderRegion` CALL HERE BUYS IS A GATE NAME, NOT A FENCE,
//       and an earlier version of this paragraph said the opposite ("THE CLAUSE
//       THAT MUST NOT BE DROPPED AS REDUNDANT") two lines above a sentence that
//       said the right thing — two comments in one change contradicting each
//       other, which is a defect this bead's Rule-13 rounds have now caught
//       twice. MEASURED on a mutant with this call deleted: BOTH fixtures still
//       decline, from the unconditional `return topoOrderRegion(R)` at the tail
//       of `recoverRegion`. The call is here so the refusal is a NAMED gate a
//       fixture can pin instead of a silent `return false`. That is a real but
//       MODEST benefit — weigh it as that if you ever move this line.
//
// WHAT SURVIVES, and why it is the SAME transformation the acyclic path makes.
// With this predicate true AND E3 (SESE) true, the region is entered only at
// `R.Entry`, left only at `R.Merge`, and both lie in `L`'s body with no back
// edge and no exit edge inside it (a back edge targets `H`, which is neither in
// the region nor the merge, so E3-escape owns it; an exit edge targets a block
// outside `L`, which E3-escape owns for the same reason). So the region runs
// exactly once per trip and the flatten is the per-trip identity of the acyclic
// case. ⚠ That is a STRUCTURAL argument about the region, not a claim about
// what the loop layer downstream does with the result — the witness for that is
// the `?:` twin, which `-O1` writes into exactly this post-flatten shape and
// which the shipped select substrate already lowers (bd fn1q inc 3 records).
//
// ⚠⚠ READ THIS BEFORE YOU QUOTE ANY CLAUSE ABOVE AS A FENCE. Rule-13 round 2
// deleted THE WHOLE CALL to this predicate (keeping only the `topoOrderRegion`
// acyclicity proof) and swept all 2140 fixtures: **`A->D=0 D->A=0
// decline-string-moves=0 stream-moves=0`**. Deleting clause (a) alone: the same
// four zeros. Every module anyone has constructed that this predicate refuses is
// ALSO refused, with the identical diagnostic, by `E3-mergepred`,
// `E3-sideentry` or `E2-regioncycle`. Per-clause, measured on single-clause
// mutants: (c)'s own fixture falls to `E3-mergepred`; (b)'s, (d)'s and both
// irreducible fixtures fall to `E2-regioncycle` or `E3-sideentry`.
//
// So the (a)-(e) paragraphs above describe WHAT EACH CLAUSE IS ABOUT — the
// hazard it is written to refuse — and NOT what is holding that hazard shut
// today. In particular the sentences "(c) … a loop that exited through an arm
// would stop exiting" and "(d) … flattening one would delete a quantum-bounded
// exit that Q1 exists to refuse, BEFORE Q1 ever runs" are the RATIONALE, and on
// every module in the tree the refusal is E3's or Kahn's. The three
// `lowering_reject_loop_quantum_bound*` fixtures that (d) names by class decline
// identically without (d).
//
// THE PREDICATE IS THEREFORE DEFENCE IN DEPTH, AND IT IS KEPT FOR TWO REASONS,
// neither of which is "it is the fence": it fails CLOSED (an in-loop region it
// cannot classify is left for an existing loud owner), and it gives each hazard
// a NAMED gate a fixture can pin, where the backstops give one shared name.
// ⚠ That is a MODEST benefit — weigh it as that, and do not let a green fixture
// here be read as evidence that the clause it names is load-bearing. CLAUDE.md
// L3 is the reason it is not deleted for being redundant: a closure table is
// worth its most-missing row, and E3/Kahn are not written to answer this
// question. ⚠ RETIREMENT TRIGGER: if E3's merge-pred or side-entry rule, or the
// acyclicity proof, is ever relaxed, this predicate stops being redundant and
// every clause above needs a real fixture — bd `e1gr`'s class exactly.
bool regionStrictlyInsideLoopBody(const PredMuxRegion &R, LoopInfo &LInfo,
                                  const char **Why) {
  const Loop *L = LInfo.getLoopFor(R.Entry);
  if (!L) {
    *Why = "E2-cycle";  // (a) / (e): on a cycle that is no natural loop of E's
    return false;
  }
  const BasicBlock *H = L->getHeader();
  if (R.Merge == H) {
    *Why = "E2-loopbackedge";  // (c)
    return false;
  }
  if (LInfo.getLoopFor(R.Merge) != L) {
    *Why = "E2-loopstraddle";  // (d) — incl. the tainted loop-EXIT branch
    return false;
  }
  for (const BasicBlock *B : R.InRegion) {
    if (B == H && B != R.Entry) {
      *Why = "E2-loopheader";  // (b) — the header as a NON-ENTRY region block
      return false;
    }
    if (LInfo.getLoopFor(B) != L) {
      *Why = "E2-loopstraddle";  // (d) — an inner loop, or outside L
      return false;
    }
  }
  return true;
}

// bd fn1q increment 4 — E4's CLASSICAL CONST-TABLE READ.
//
// THE SHAPE, and it is NOT QROM. `if (cond) { Z -= z[i]; P += p[i]; }` where `z`
// and `p` are ordinary arrays and `i` is the CLASSICAL loop counter.
//
// ⚠ THE TWO-ASSIGNMENT FORM IS NOT AN ILLUSTRATION, IT IS THE ACCEPT SURFACE, and
// the first draft of this line wrote the ONE-assignment form as "THE SHAPE" while
// the build declines it (Rule-13 round 2, R4R2-6). Measured, identically on both
// binaries: `if (q > 2) { Z -= z[i]; }` leaves at `gate=W-witness` and declines
// `value-arm swap-route under quantum control`. This increment widened **E4**; it
// did not widen the **claim witness**, and with one merge phi of two incomings no
// witness fires, so E4 is never consulted.
//
// That residual is an OVER-DECLINE by the owner's 2026-09-11 ruling and it is a
// real follow-on, not a note: W4 already makes a claimable QROM read its own
// witness on the argument that no shipped owner accepts a load-bearing arm
// (`ArmClassify`'s `walkValueChain` breaks on a `LoadInst` — measured: the flat
// one-accumulator form declines `impure value arm under quantum control`), and
// the identical argument holds for a classical table read. ⚠ Widening W is a
// change to the claim witness with its own accept surface — a mutant measured
// `D->A=35, stream-moves=11` for bypassing it — so it is NOT a side edit here.
// ⚠ Every fixture and the e2e slice use the TWO-assignment form, so nothing in
// the tree can see this residual. That is why it is written down. `classifyQromReadUnderControl`
// is deliberately not the way in and must not be widened to cover it: QROM is a
// QUANTUM-indexed table read that lowers to `cqrt_qram_load_<W>`, and its
// index-TAINT gate is load-bearing, not incidental (measured at the 2026-09-23
// bisection: a power-of-two table still declines, so the refusal is the taint
// gate and not the table size). Here the index is classical, the loaded value is
// classical, and it stays classical all the way down — in a mixed Q+C op it
// occupies the sanctioned `_hl` LITERAL slot and is not promoted to a qubit
// handle (`quantum-classical-handling.md` §5.2, non-negotiable).//
// ⚠ AND THE PRECISE FORM OF THAT CLAIM MATTERS, BECAUSE ITS FIRST DRAFT WAS
// MEASURABLY FALSE (Rule-13 round 1, R4-P2-2). "The loaded value is NEVER
// promoted to a qubit handle" is true of the OPERAND SLOT OF A MIXED Q+C OP,
// which is what §5.2 governs — `cq_template_sub_i32_hl(%Z, %z)` passes `%z`
// through as the literal. It is FALSE as an unconditional statement: when the
// loaded value is an ARM OF THE MERGE (`c ? tbl[i] : 7`), the 4.4 data mux
// materialises it on a rail — measured, `cqrt_alloc_i32(i32 %z)` — because a
// controlled copy has to have something to copy FROM. That is the ordinary merge
// idiom, identical to what happens to a literal arm (`cqrt_alloc_i32(i32 5)`) and
// to a classical function ARGUMENT on the pre-increment ORACLE. Sound, and NOT
// the §5.2 hazard; say "in the `_hl` slot of a mixed op", never "never".
//
// SO THE ONLY QUESTION IS WHETHER SPECULATING THE LOAD IS SAFE, and the owner
// ruled it on 2026-09-23: admit **only with a PROOF** of in-bounds-ness; failure
// to prove keeps today's loud decline. That makes an undersized bound
// UNREACHABLE rather than UNDETECTED, which is the same asymmetry Rule 18's
// narrowing rests on.
// ⚠ bd xdu2.8 — ARMS (1a)-(1c) ANSWER IT FOR THE HOIST POINT; ARM (1d) DOES NOT,
// AND DOES NOT NEED TO. (1d) proves the SOURCE's read in bounds only under a
// classical conjunct of the arm's own path condition, and the flatten then makes
// the SPECULATED read safe BY CONSTRUCTION (a bounds-checked address select,
// `guardSpeculatedClassicalRead`). Obligation (1) below is still met — by the
// rewrite, not by a proof at the hoist point — and the ruling's "failure to prove
// declines" still holds: (1d) without its proof leaves exactly as before.
//
// TWO OBLIGATIONS, AND ONLY THE FIRST NEEDS A PROOF HERE:
//   (1) THE LOAD MUST NOT FAULT where the source did not perform it. That is
//       what `isDereferenceableAndAligned*` answers. In a loop the flatten makes
//       the arm body run EVERY TRIP, so the question is per-iteration and
//       `isDereferenceableAndAlignedInLoop` is exactly the predicate for it
//       ("would access only dereferenceable memory … on every iteration
//       regardless of its placement within the loop"). Outside a loop the hoist
//       point is the entry terminator and the context-sensitive pointer form
//       answers it.
//   (2) NO INTERVENING STORE may change the value between the hoist point and
//       the load's original position. ⚠ THIS NEEDS NO PROOF AND THAT IS NOT AN
//       OVERSIGHT: E4 already refuses any `StoreInst` in the region
//       (`isSpeculatableDataflow` is false for one -> `E4-dataflow`), the hoist
//       target is before `R.Entry`'s terminator so nothing already in `R.Entry`
//       is crossed, and E3 makes the region single-entry/single-exit so no
//       out-of-region block lies between. A store elsewhere in the loop body runs
//       either wholly before or wholly after the region in each trip. ⚠ RETIREMENT
//       TRIGGER: the day E4 admits a store, obligation (2) becomes real and this
//       predicate must grow a memory-dependence proof.
//
// ⚠ IMMUTABILITY IS NOT REQUIRED BY ARM (1a) AND IS REQUIRED BY ARM (1b), AND
// THE FIRST DRAFT OF THIS PARAGRAPH CLAIMED IT WAS REQUIRED BY NEITHER. Measured,
// per arm, because the difference is not visible from this file:
//   * (1a), SCEV-in-loop, calls LLVM directly and asks only about
//     dereferenceability, so a MUTABLE global is fine — `loop2phi_cmp.c` reads
//     `int g_z[3]` (`@g_z = global`, no `constant`) and ACCEPTS.
//   * (1b), known-bits, goes through `classicalTableIndexKnownInBounds` ->
//     `matchQramAccess`, which requires `Origin.GV->isConstant()` because it is
//     QROM's matcher. So (1b) proves a VARIABLE index only for a CONSTANT global.
// ⚠ "THE LOOP-FREE ARM ADMITS A CONSTANT GLOBAL ONLY" IS WHAT THIS PARAGRAPH USED
// TO SAY AND IT IS FALSE (Rule-13 round 1, R4-P3-1): arm (1c) admits plenty that
// (1b) cannot, and it does not care about mutability — measured accepts include a
// MUTABLE `[4 x i32]` at a CONSTANT index, a bare `load i32, ptr @m` on a mutable
// global with no gep at all, and an UNINITIALISED alloca (dereferenceable, so no
// fault; the value is as undefined as the source's own read of it). What the
// constant-global requirement really bounds is (1b)'s VARIABLE-index case.
// The asymmetry is inherited, not designed, and it is in the SAFE direction. ⚠ If
// you widen it, do it by giving `matchQramAccess` the option — NOT by growing a
// second bounds proof here (Rule 14; the drbq Inc-3 (b') defect).
bool classicalTableReadIsSpeculatable(
    LoadInst *LI, const TaintSet &Taint, DominatorTree &DT, LoopInfo &LInfo,
    ScalarEvolution &SE, AssumptionCache &AC,
    const SmallPtrSetImpl<BasicBlock *> &Region, BasicBlock *Entry,
    Value **GuardExtent) {
  *GuardExtent = nullptr;
  // Simple = not volatile, not atomic. A volatile read is an observable event the
  // flatten may not duplicate or move; an atomic one carries ordering.
  if (!LI->isSimple())
    return false;
  // CLASSICAL, on both wires, NOW.
  if (Taint.Tainted.count(LI) || Taint.Tainted.count(LI->getPointerOperand()))
    return false;
  // ⚠ AND CLASSICAL AFTER THE FLATTEN. THE SENTENCE THAT USED TO STAND HERE —
  // "the taint test keeps the two admissions disjoint by construction rather than
  // by call order" — WAS FALSE AND IT WAS A P1 (Rule-13 round 1).
  //
  // This predicate is reached EXACTLY when `classifyQromReadUnderControl`
  // returned `No`, and QROM says `No` for SIX reasons — not only "the index is
  // classical". One of them is the `coherentlyEscapesToReturn` NO-CLONING fence,
  // where the load IS a genuine QROM read whose value escapes coherently to a
  // `ret`. Such a read's index is frequently UNTAINTED at round-1 taint and
  // becomes tainted only once the flatten rewrites a region-internal phi into a
  // select — so the test above passed and the read was laundered through this arm.
  // Measured witness: a plain-`CQ.h` C program, ORACLE exit 1 `nested control flow
  // under quantum control`, SUBJECT exit 0 with 0 BYTES of stderr, emitting
  // `cqrt_qram_load_i32` on a superposed index rail built by two
  // `cqrt_copy_i64_controlled` and NEVER freed. `free_pairing_check.py` is
  // structurally blind to it.
  //
  // The fix is to ask QROM's OWN question instead of a proxy for it (Rule 14) —
  // and to ask it at the FLATTEN's taint, not round 1 (CLAUDE.md L1, the
  // "PREDICATE species": a fence keyed on round-1 taint while the lowering decides
  // at final taint). Refusing here is always safe: if the index will taint, the
  // read belongs to QROM, and QROM has already declined it for a reason of its own.
  //
  // ⚠ TWO QUESTIONS, AND THE FIRST ONE IS VACUOUS INSIDE A LOOP. Rule-13 round 2
  // measured this: `qromShapedReadTaintsIndexAfterFlatten` goes through
  // `matchQramAccess`, which returns `nullopt` UNCONDITIONALLY for any memop in a
  // loop ("a QRAM access in a loop needs 7.3 unroll"). So for every IN-LOOP load —
  // i.e. exactly the half of this accept surface increment 3 opened — that call
  // answers `false` at its first `if` and fences nothing. The in-loop family was
  // closed only by OTHER owners (`kMsgQramLoop`, and `unrollConstTripLoops`' U2b),
  // which is a CONTINGENT closure and not the stated reason — CLAUDE.md's bd
  // `xt20` class.
  //
  // So ask the will-taint question DIRECTLY as well, on the pointer operand, with
  // no QROM matcher and therefore no loop gate. `valueWillTaintAfterFlatten` is
  // the exported spelling of the SAME predicate QROM's index gate uses (Rule 14),
  // and a pointer that will taint after the flatten is, by construction, not the
  // classical read this arm exists for.
  if (valueWillTaintAfterFlatten(LI->getPointerOperand(), Taint, Region, Entry))
    return false;
  if (qromShapedReadTaintsIndexAfterFlatten(LI, Taint, DT, LInfo, Region, Entry))
    return false;
  // A width the templates can carry, so a claimed region can never half-lower
  // (the same detect-before-mutate discipline E7 applies to merges).
  // ⚠ `abiWidthFromType` NON-EMPTY IS THE RIGHT TEST *HERE* AND IS THE WRONG ONE
  // ONE LINE OVER. CLAUDE.md L9 records "never key DATA-MUX lowering on
  // `abiWidthFromType()` being non-empty — f64 has a valid width yet is an ANGLE;
  // that was the f64 silent miscompile". Do not copy this line into a merge or
  // condition test.
  //
  // ⚠ THE JUSTIFICATION THAT USED TO STAND HERE — "this value is never muxed and
  // never an angle" — IS FALSE ON BOTH HALVES, and it was the SIXTH copy of a
  // claim the previous round corrected in five other places while missing this,
  // the load-bearing, one (Rule-13 round 2, R4R2-2; two comments in one function
  // contradicting each other, 92 lines apart — the same class §4i records from one
  // increment ago).
  //   * "never muxed": measured FALSE. A table value used as an arm of the merge
  //     IS muxed, at f64, emitting `cqrt_alloc_f64(double %z)` +
  //     `cqrt_copy_f64_controlled`. That is the shipped, Rule-13-cleared 4.4 fp
  //     data select, so it is sound — but it is a mux.
  //   * "never an angle": not established by the cited ground. A loaded `double`
  //     CAN reach `cq_theta`'s arg-1; what saves it is a DIFFERENT fence
  //     (`rotation angle under quantum control`), not the taint test above.
  // The width gate is still correct — it keeps a claimed region from half-lowering
  // — but its reason is "the templates must be able to carry this width", full
  // stop. Do not restore a reason that names muxing or angles.
  if (abiWidthFromType(LI->getType()).empty())
    return false;
  const DataLayout &DL = LI->getModule()->getDataLayout();
  // (1a), in a loop: per-iteration, placement-independent. This is the arm that
  // fires on the shape this increment exists for — a table indexed by the loop
  // COUNTER, where the bound is the trip count and only SCEV can see it.
  if (const Loop *L = LInfo.getLoopFor(Entry))
    if (isDereferenceableAndAlignedInLoop(LI, const_cast<Loop *>(L), SE, DT, &AC))
      return true;
  // (1b), the KNOWN-BITS proof — the same one QROM's `Provable` verdict uses,
  // asked through the exported wrapper so there is ONE spelling of "is this index
  // in bounds" (Rule 14). It catches the masked index (`i & 3` into `[4 x i32]`)
  // that has no loop to bound it.
  if (classicalTableIndexKnownInBounds(LI, Taint, DT, LInfo))
    return true;
  // bd xdu2.4 — the exact Grover runtime-bank customer keeps its companion
  // classical `p[n]` table dynamic too.  That is still increment 4's classical
  // load, not QROM and not fn1q increment 5b: the index and extent remain
  // classical, while the shared provenance proof relates the VLA extent to this
  // loop's exact 0..n-1 walk.  This fallback cannot claim heap storage or any
  // unproved/mismatched bound.
  if (classicalRuntimeAllocaReadIsInBounds(LI, Taint, DT, LInfo, SE, Entry))
    return true;
  // (1c), the pointer-level fallback: is the address dereferenceable AT THE HOIST
  // POINT? `CtxI` is the entry terminator because that is exactly where
  // `moveBody` will put the load.
  //
  // ⚠ THIS ARM IS WEAKER THAN IT LOOKS AND MUST NOT BE READ AS THE GENERAL CASE.
  // LLVM's `isDereferenceableAndAlignedPointer` walks a gep by ACCUMULATING A
  // CONSTANT OFFSET, so a VARIABLE index defeats it outright — measured: a masked
  // `i & 3` into a 4-element table returns false here and is admitted by (1b)
  // instead. What this arm adds is the constant-index and whole-object cases.
  APInt Size(DL.getIndexTypeSizeInBits(LI->getPointerOperand()->getType()),
             DL.getTypeStoreSize(LI->getType()).getFixedValue());
  if (isDereferenceableAndAlignedPointer(LI->getPointerOperand(),
                                         LI->getAlign(), Size, DL,
                                         Entry->getTerminator(), &AC, &DT))
    return true;
  // bd xdu2.8 — (1d), the LAST resort and the only arm that does NOT make the
  // read safe at the hoist point: the index is proven in bounds only under a
  // CLASSICAL conjunct of the arm's own path condition, so the load is admitted
  // on the condition that the flatten rewrites its address to a bounds-checked
  // select (the caller records it; `guardSpeculatedClassicalRead`). Every fence
  // above — simple, classical now and after the flatten, not QROM-shaped, a
  // template width — has already been asked of it. See GuardedClassicalRead.h.
  // ⚠ L1 — ROUND-2 TAINT GROWTH IS CLOSED CONTINGENTLY, NOT BY A FENCE (Rule-13
  // round 2 P3). This admission runs before round 1 and nothing re-asks it. An
  // index that becomes tainted only in round 2 (e.g. the merge `%out` of a 6.5
  // classical-call arm) taints the flatten's own `%cq.gr.addr` select, and today
  // that module declines LOUDLY only because `SelectClassify` has no data-select
  // shape for a tainted POINTER select (`control flow`). ⚠ RETIREMENT TRIGGER:
  // the day any consumer admits a tainted pointer select (or a round-2 QROM
  // carve reads through one), this read needs a named post-fixpoint re-ask — the
  // index must still be classical at FINAL taint.
  if (classicalRuntimeAllocaReadIsInBoundsUnderGuard(LI, Taint, DT, LInfo, SE,
                                                     Region, Entry, GuardExtent))
    return true;
  return false;
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
// bd fn1q increment 4 — the E4 classical-read proof needs SCEV and an assumption
// cache, and BOTH are expensive to build. They are constructed LAZILY, on the
// first load a candidate region actually reaches, and then reused for the rest of
// the function: the PredMux fixpoint calls `recoverRegion` once per tainted
// terminator per round, and the overwhelming majority of regions contain no load
// at all, so building them eagerly would put a SCEV construction on every
// iteration of a fixpoint that runs three times per module.
struct LazyLoadAnalyses {
  Function &F;
  DominatorTree &DT;
  LoopInfo &LInfo;
  std::unique_ptr<AssumptionCache> AC;
  std::unique_ptr<TargetLibraryInfoImpl> TLII;
  std::unique_ptr<TargetLibraryInfo> TLI;
  std::unique_ptr<ScalarEvolution> SE;

  LazyLoadAnalyses(Function &F, DominatorTree &DT, LoopInfo &LInfo)
      : F(F), DT(DT), LInfo(LInfo) {}

  // ⚠ Built once per FUNCTION and handed out by reference. The safety argument is
  // that NOTHING QUERIES THE BUNDLE AFTER A MUTATION — `recoverRegion` is pure
  // analysis (detect-before-mutate, Rule 9) and every use is inside it.
  //
  // ⚠ IT IS *NOT* "the caller discards the bundle before `RegionFlattener::run()`
  // touches a block", which is what this comment used to say and is false
  // (Rule-13 round 2, R4R2-8): the bundle is declared in the per-function loop
  // body and stays ALIVE through `RegionFlattener::run()`,
  // `foldConstantConesInFunction` and `simplifyFlattenResiduesInFunction`, all of
  // which erase instructions and blocks. Benign — SCEV's `SCEVUnknown` are
  // `CallbackVH`s that absorb erasure, and nothing asks it anything by then — but
  // the correct ground is "nothing queries it", and a future caller that DOES
  // query it after a flatten would be reading a stale SCEV.
  void ensure() {
    if (SE)
      return;
    AC = std::make_unique<AssumptionCache>(F);
    TLII = std::make_unique<TargetLibraryInfoImpl>(
        Triple(F.getParent()->getTargetTriple()));
    TLI = std::make_unique<TargetLibraryInfo>(*TLII, &F);
    SE = std::make_unique<ScalarEvolution>(F, *TLI, *AC, DT, LInfo);
  }
};

bool recoverRegion(Instruction *T, PostDominatorTree &PDT, DominatorTree &DT,
                   LoopInfo &LInfo, const SmallPtrSetImpl<BasicBlock *> &OnCycle,
                   const TaintSet &Taint, PredMuxRegion &R, bool ClaimAll,
                   LazyLoadAnalyses *Loads = nullptr) {
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
    // virtual roots — infinite loops, disjoint multi-ret — and
    // `mergeIgnoringUnreachable` returns nullptr for the latter.)
    // ⚠ CORRECTED (bd fn1q increment 3, Rule-13 round 1 F-2): this used to say
    // "but E2 declines the former". It no longer does. In a function with NO
    // reachable `ret` the post-dominator sets never receive an exit seed, so the
    // "merge" this returns is an arbitrary block (measured `merge=arm`), and such
    // a region now travels past E2 to `W-witness` or, when phis sit on every
    // candidate merge, all the way to `E2-regioncycle`. MEASURED: four
    // infinite-loop spellings decline. ⚠ AND A FIFTH ONE CLAIMS: Rule-13 round 2
    // built `control_predmux_accept_noreturn_degenerate_merge.ll` — no reachable
    // `ret` anywhere — where this path picks the merge by the degenerate
    // first-discovered rule, the region is CLAIMED and flattened, and stage 2b is
    // STRICT-clean. The sentence that stood here, "NOBODY HAS CONSTRUCTED ONE
    // THAT CLAIMS", is retracted.
    //
    // IT IS SOUND, AND THE ARGUMENT DOES NOT DEPEND ON THE MERGE BEING THE REAL
    // JOIN: whatever block the degenerate post-dominance names, E3 then requires
    // successors ⊆ region ∪ {Mg}, every non-entry pred in region, and
    // `preds(Mg)` ⊆ region, and the Kahn proof requires acyclicity — which
    // together force a genuinely SESE acyclic region. The `select` spelling of
    // that same program already compiles on the ORACLE with the same gate
    // stream. ⚠ What is NOT established is the converse: nobody has tried to
    // build a non-returning function where the arbitrary merge is not the real
    // join AND E3 still passes. The SESE argument says it cannot exist; it has
    // not been attacked.
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
    // Switch owners are unreachable from this `br` arm of the witness.
    // ⚠ CORRECTED (bd fn1q increment 3, Rule-13 round 1 F-1): this sentence used
    // to continue "and E2 excludes every loop owner", which E2's in-loop
    // admission FALSIFIES. The clause was load-bearing for the anti-overlap
    // argument and it is now simply wrong — E2 admits a region lying strictly
    // inside a loop body.
    //
    // ⚠ WHAT ACTUALLY HOLDS THE LINE IS **`W-witness`**, AND THE FIRST ATTEMPT
    // AT THIS CORRECTION SAID **E4**, WHICH IS ALSO WRONG. Rule-13 round 2
    // measured it: over every `*loop*` fixture that ACCEPTS and produces a
    // PredMux leave, **100 leave at `W-witness` and 0 at E4**. The W witness
    // claims only shapes today's detection DECLINES, so a shipped in-loop owner
    // is never claimed in the first place and E4 is never consulted for it.
    //
    // E4 is the COUNTERFACTUAL fence, not the live one: on a mutant with the W
    // witness bypassed, 8 of 10 sampled in-loop owners are then refused by
    // `E4-dataflow` (they hold a `cq_phi`/`cq_theta` CALL in the arm) — but the
    // 7.4 BREAK owners (`lowering_loop_break_{add,value}`) have no `cq_*` call in
    // the arm at all and are refused by E2's own clause (d). So there is no
    // single fence behind W; there are two, and neither is E4 alone.
    //
    // ⚠ RETIREMENT TRIGGER — AND IT POINTS AT W, NOT AT E4. The direction that
    // actually matters is a **`W-witness` widening**: measured on that same
    // mutant, bypassing W moves **35 fixtures DECLINE->ACCEPT and 11 emitted
    // streams**. Anyone widening the claim witness must rebuild this anti-overlap
    // argument from scratch rather than patch it. A future E4 widening, by
    // itself, changes nothing here.
    // So W7, like every other witness, claims only
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

  // --- E2: acyclic; in-loop only STRICTLY INSIDE one loop body --------------
  // bd fn1q increment 3. `OnCycle` still decides whether the question is even
  // asked, so a region with no block on any cycle is byte-identical to today
  // (the predicate is not consulted). See `regionStrictlyInsideLoopBody` above
  // for the enumeration of what the old single clause was holding.
  bool AnyOnCycle = false;
  for (BasicBlock *B : R.InRegion)
    if (OnCycle.count(B)) {
      AnyOnCycle = true;
      break;
    }
  if (AnyOnCycle) {
    const char *Why = "E2-cycle";
    if (!regionStrictlyInsideLoopBody(R, LInfo, &Why))
      return leave(Why);
    // (e): an irreducible cycle wholly inside `L` reports `L` for every block,
    // so `LoopInfo` cannot see it. Kahn can. Asked HERE — not left to the tail
    // call — so the refusal is a NAMED gate and not a silent `return false`.
    if (!topoOrderRegion(R))
      return leave("E2-regioncycle");
  }

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
  const PhiCondScope Scope{&R.InRegion, R.Entry, &R.BoolAlgPhis,
                           &R.RailPhiLeaves};
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
        // check, which declined `control flow under quantum control`. That gate
        // WAS staged for a "hybrid classical∧quantum conjunction" widening, and
        // bd `test_C_libtooling-xdu2.13` is that widening — see the RECORD block
        // below for how the argument was re-derived. And the decline is not universal: a region that mints no
        // select (an i1 merge phi takes the boolean-algebra path) compiles
        // silently, which is SOUND only because a classical runtime operand
        // occupies the sanctioned `_hl` literal slot and is never promoted to a
        // qubit handle (the §5.2 non-negotiable). The SWITCH scrutinee gate
        // below is deliberately NOT widened: no measured cell needs it and
        // over-declining is safe.
        //
        // bd `test_C_libtooling-xdu2.13` — THAT BACKSTOP IS NOW A RECORD. The
        // 4.4 data select accepts a classical `and`/`or` child as a `_hl`
        // LITERAL, so an untainted residue would no longer reach the per-leaf
        // decline on its own. A rule-(B) admission is RECORDED here
        // (`PredictedConds`, discarded with `R` on any later `leave`), its i1
        // cone and every edge literal built from it are MARKED at the claim
        // (`markPredictedTaintCone`), and `condLiteralAdmissible` refuses a
        // marked cone — so a residue keeps its `control flow` decline.
        // ⚠ THE RE-DERIVATION FOUND NO RESIDUE TO FENCE, AND THE RECORD IS KEPT
        // ANYWAY. Every construction tried keeps the prediction EXACT: an edge
        // literal that folds to a constant needs a constant branch, and
        // `foldConstantConeAndBranches` folds those at the top of every call,
        // before E6; a MEASURE sink between the φ and the condition is refused
        // at E4-dataflow; the ENTRY-φ and all-equal-incoming φ are q2wk's own
        // fences. So the mark is defence in depth with NO constructed subject
        // (Rule 12 cannot pin an unreachable shape — the bd `e1gr` precedent);
        // what IS pinned is that a mark neither leaks into the output nor
        // refuses an unrelated genuine literal in the same tree
        // (`condtree_classical_leaf_accept_predmux_ruleb.ll`). RETIREMENT
        // TRIGGER: the day any stage can make an edge literal constant AFTER E6
        // (a late fold inside `run()`, or E6 admitting a non-folded constant
        // branch), this record gains a subject and owes a decline fixture.
        // Not in clone mode (`ClaimAll`): no data-select classifier runs in a
        // clone body.
        if (!Taint.Tainted.count(BI->getCondition()) &&
            !isa<ConstantInt>(BI->getCondition()) &&
            !valueWillTaintAfterFlatten(BI->getCondition(), Taint, R.InRegion,
                                        R.Entry))
          return leave("E6-classicalbr", BI);  // classical control inside a tainted region: mixed
        if (!ClaimAll && !Taint.Tainted.count(BI->getCondition()) &&
            !isa<ConstantInt>(BI->getCondition()))
          R.PredictedConds.emplace_back(BI->getCondition());
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
        if (QC == QromClaim::No) {
          // bd fn1q increment 4 — QROM said No. Before declining, ask the
          // SECOND, DISJOINT question: is this a CLASSICAL table read whose
          // speculation is PROVED safe? QROM owns the quantum-indexed read and
          // is asked first; this owns the classical-indexed one and can only be
          // reached after QROM declined, so the two can never both claim a load.
          // Failure to PROVE keeps today's decline verbatim — the owner's
          // 2026-09-23 ruling, and increment 1's `flat_qc_load` ruling stands
          // unchanged because an unprovable index still lands on this `leave`.
          // bd xdu2.8: a read proved only under an arm-local CLASSICAL guard
          // (arm (1d)) is admitted too, and RECORDED — the flatten owes it the
          // bounds-checked address, so the record is not optional.
          if (!Loads)
            return leave("E4-load", &I);
          Loads->ensure();
          Value *GuardExtent = nullptr;
          if (!classicalTableReadIsSpeculatable(LI2, Taint, DT, LInfo, *Loads->SE,
                                                *Loads->AC, R.InRegion, R.Entry,
                                                &GuardExtent))
            return leave("E4-load", &I);
          if (GuardExtent)
            R.GuardedLoads.push_back({LI2, GuardExtent});  // bd xdu2.8 — the flatten owes the select
          continue;  // a proved classical read: pure speculatable dataflow.
        }
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
            if (LU->getPointerOperand() == GEP) {
              if (classifyQromReadUnderControl(LU, Taint, DT, LInfo,
                                               /*OutCount=*/nullptr, &R.InRegion,
                                               /*inBennettClone=*/ClaimAll) !=
                  QromClaim::No)
                continue;  // the claimable read's address gep (load re-checked).
              // bd fn1q increment 4 — the address gep of a PROVED CLASSICAL
              // read. `hasOneUse` + the pointer-operand identity are what make
              // this safe to wave through: the gep has exactly one consumer and
              // it is the load the predicate just proved, so admitting the
              // address can never admit a second, unproven access. The load is
              // re-checked on its own iteration (it is a separate instruction in
              // this same walk), which is why this arm does not need to record
              // anything.
              // ⚠ THE LOAD MUST BE IN THE REGION — AND THIS CLAUSE IS PROVABLY
              // DEAD, WHICH IS RECORDED RATHER THAN HIDDEN. Round 1 added it
              // (P3-4) against "a gep in the region whose sole user is a load in
              // the MERGE (or below)". Round 2 showed E3 makes that shape
              // unreachable: E3 runs BEFORE this walk and forces every region
              // block's successors into region ∪ {Mg} and every `Mg` predecessor
              // into the region, and `Mg` is never dominated by a non-entry region
              // block — so a single-use gep's load cannot sit outside. Measured:
              // dropping the guard moves 0 of 2149 fixtures.
              // Kept as defence in depth (it costs one set lookup and it fails
              // closed), NOT because it is holding anything. ⚠ It becomes live the
              // day E3's successor or merge-predecessor rule is relaxed.
              if (Loads && R.InRegion.count(LU->getParent())) {
                Loads->ensure();
                // The load is re-asked (and, if guarded, RECORDED) on its own
                // iteration of this walk; the gep only needs the verdict.
                Value *GepLoadGuardExtent = nullptr;
                if (classicalTableReadIsSpeculatable(LU, Taint, DT, LInfo,
                                                     *Loads->SE, *Loads->AC,
                                                     R.InRegion, R.Entry,
                                                     &GepLoadGuardExtent))
                  continue;
              }
            }
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
  // `Rec` (bd `test_C_libtooling-woa0`) is the CALLER's cross-claim record, not
  // this region's: `convertPhis` reports into it when it select-chains a φ that
  // an EARLIER claim (or this one, at `R.Merge` — bd `test_C_libtooling-0fly`)
  // recorded as a condition-tree rail leaf. Null when the driver does not police
  // the property; the flattener's behaviour is otherwise identical either way —
  // it only ever WRITES a bool, never reads one back.
  // `Taint` is read only by `maskQromIndex` (a logical-width query).
  RegionFlattener(PredMuxRegion &R, IRBuilder<> &B, PredMuxRailPhiRecord *Rec,
                  TaintSet &Taint)
      : R(R), B(B), Rec(Rec), Taint(Taint) {}

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
    // keeps the index at the pointer-index width, so the mask (N ≤ 2^63) yields
    // a non-negative in-range offset for every bit pattern; WHERE it is built
    // (the narrow source of the -O1 widening, or the i64 index) is
    // `maskQromIndex`'s. Inserted AT the (already-moved) gep so the index
    // dominates textually; the And is tainted by the caller's re-propagate and
    // lowers as an ordinary hl template.
    for (auto &ML : R.MaskLoads) {
      auto *GEP = cast<GetElementPtrInst>(ML.first->getPointerOperand());
      unsigned IdxNo = GEP->getNumOperands() - 1;
      Value *Idx = GEP->getOperand(IdxNo);
      IRBuilder<> MB(GEP);
      MB.SetCurrentDebugLocation(GEP->getDebugLoc());
      GEP->setOperand(IdxNo, maskQromIndex(MB, Idx, ML.second));
      track(Idx);  // a widening cast only this gep read is dead now: swept.
    }
    // bd xdu2.8 — every read E4 admitted only under an arm-local classical
    // guard gets its bounds-checked address NOW, after `moveBody` put it at the
    // hoist point and before anything can observe the speculation. The replaced
    // gep is swept if nothing else reads it.
    for (auto &GL : R.GuardedLoads)
      track(guardSpeculatedClassicalRead(GL.first, GL.second));
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
  PredMuxRailPhiRecord *Rec = nullptr;  // bd woa0 — write-only, may be null
  TaintSet &Taint;
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
      // bd `test_C_libtooling-xdu2.13` — an edge literal built from a rule-(B)
      // condition inherits its mark (the negation is a CLONE, not the value).
      for (const WeakVH &PC : R.PredictedConds)
        if (static_cast<Value *>(PC) == BI->getCondition())
          markPredictedTaintCone(L);
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
    // bd kqqv — TRACK EVERY NODE THIS FUNCTION VISITS. The symmetric twin of
    // `buildNegation`'s bd `qesi` line, and it is owed for the same reason even
    // though this function REPLACES far less than that one does.
    //
    // *** THE "CAPITALIZED DIRECTIVE" THIS CHANGE ONCE CLAIMED TO SUPERSEDE WAS
    // NEVER SHIPPED. An earlier draft of THIS comment said it was; the Rule-13
    // round caught it (bd `drln` B2). *** Get the provenance right, because the
    // wrong version defames the one commit in this family that behaved correctly.
    // What `qesi` (2d51f23) shipped was the RETRACTION, already in capitals: "AND
    // THAT IS NOT A CLEAN BILL OF HEALTH FOR `canonicalizePred` — AN EARLIER DRAFT
    // OF THIS COMMENT SAID IT ORPHANS 'NOTHING, measured 0 at both polarities' AND
    // TOLD YOU NOT TO FIX IT. BOTH WERE WRONG." The directive itself lived only in
    // qesi's own unshipped draft — `git log --all -S 'canonicalizePred to match'
    // -- ir-pass/src/PredMuxFlatten.cpp` returns nothing before this commit. qesi
    // FILED bd `kqqv` with its reach and left the fix to its own round; this is
    // that round. The lesson survives the correction intact, and it is the SCOPE
    // CLAUSE, not a villain: a "measured 0" that does not say what it ranged over
    // reads as a proof and acts as a prohibition.
    //
    // The underlying measurement was real and is still true — it was taken ONLY on
    // shields that ARE the branch condition, where `run()`'s
    // `track(BI->getCondition())` happens to cover the shield, i.e. a statement
    // about DEPTH 0. Re-measured at 3319975 — orphan controlled COPIES, gate arm
    // on the TRUE successor (the polarity that routes through here; `clang -O1`
    // picks it half the time, Rule 9):
    //     ROOT shield   `%sc = select i1 %b, i1 %c, i1 false`            0
    //     under `and`   `%sc = and i1 %a, %inner`                        2
    //     under `or`    `%sc = or  i1 %a, %inner` (or-form shield)       2
    //     under a shield `%sc = select i1 %inner, i1 %d, i1 false`       2
    //     two `and`s deep                                               2
    // THE UNIT IS COPIES, and it is stated because an earlier draft labelled this
    // same column "merges" (bd `drln` S1 — one number under two units inside one
    // commit). Every leaking row emits exactly ONE dead 4.4 merge — one `%out` —
    // written by TWO `cqrt_copy_i1_controlled`; the sibling fixture
    // `control_predmux_accept_nonroot_shield_armkill.ll` uses the same unit.
    //
    // Depth, not spelling. What leaked, on the `and` row: the rewritten shield's
    // original `SelectInst` kept zero uses and was absent from `MaybeDead`, so the
    // 4.4 select path lowered it into a WHOLE DEAD controlled-copy merge — an
    // `%out = cqrt_alloc_i1(false)` written by two `cqrt_copy_i1_controlled` and
    // NEVER READ, a never-freed `%selop`, and a `cq_template_icmp_ne_i32_hl` with
    // no `_unc` and no `cqrt_free`. Three dangling ENTANGLED rails (Rules 6/8),
    // while the condition was ALSO lowered a second time as a plain compare tree,
    // so the entire merge was dead weight. `opt` exited 0, the verifier was clean,
    // and `free_pairing_check.py` printed "0 violation(s), 0 unproven" — it counts
    // `cqrt_alloc_*` mints and an orphan flag is TEMPLATE-minted (bd `1739`).
    //
    // WHY ONE LINE AT THE TOP AND NOT A TRACKER PER REBUILD SITE. This function
    // RE-ENTERS ITSELF on every child it can rewrite — both `and`/`or` operands,
    // and a shield's condition and its live arm — so tracking on entry tracks the
    // whole cone for free, exactly as `buildNegation`'s recursion does. Tracking
    // only at the three rebuild sites would still cover this ticket's shapes, but
    // it would leave the nodes this function KEEPS untracked, and a kept node is
    // stranded too whenever the literal itself is dropped (the BoolAlg `∧ false`
    // rule computes an edge predicate and then discards it — that is precisely the
    // bd 3c6m.67 round-2 leak, one function over). Entry-tracking closes both.
    //
    // INERT ON EVERYTHING STILL LIVE, which is what makes the wider set free:
    // `sweepDead` is a `use_empty` fixpoint, so a compare shared with another
    // region, or read by the arm body, is untouched. Every value that reaches here
    // is pure by construction — `isSupportedCondTree` admits only ConstantInt /
    // CmpInst / and / or / xor / short-circuit SelectInst, and a convertible i1
    // phi is already boolean algebra by the time `literal()` runs (`run()` skips
    // only `R.Entry`, and E6 refuses a phi condition there).
    //
    // *** WHY `trackCondCone` AND NOT A BARE `track` — A MEASUREMENT KILLED THE
    // CHEAPER ANSWER. *** This function re-enters itself on `and`/`or` operands
    // and on a shield's condition and live arm, but it has NO xor arm (deliberate
    // — see the `Strict` note on `isSupportedCondTree`), so a bare entry-`track`
    // would track a two-operand `xor` node and STOP, leaving its operand cone
    // untracked. The tempting argument for leaving it there is that
    // `buildNegation` covers that cone anyway (its xor arm calls `trackCondCone`
    // on the kept side and re-enters on the other), and that both polarities of a
    // conditional branch are always demanded together.
    //
    // THAT SECOND CLAUSE IS FALSE, and it was written into an earlier draft of
    // this comment before being measured. `convertPhis`' select-chain arm treats
    // the LAST incoming as the fallback and never asks for its edge predicate, so
    // a plain triangle demands exactly ONE polarity. Instrumented over all 1112
    // fixtures: 166 distinct conditional-branch terminators reached `literal()`,
    // and only 65 of them were asked for both polarities — 86 got `Idx=0`
    // (this function) alone and 15 got `Idx=1` alone. So `canonicalizePred` is
    // routinely the ONLY function that sees a condition tree, and an invariant
    // resting on its neighbour being called is not an invariant. Reusing the
    // walk bd 3c6m.67 already built for the identical obligation (Rule 14) makes
    // this function no longer DEPENDENT on its neighbour being called.
    //
    // *** AND THAT IS THE WHOLE CLAIM — IT IS NOT "EVERY NODE OF THE CONE IS
    // TRACKED, WHATEVER THE SHAPE". An earlier draft said exactly that and it is
    // FALSE; the Rule-13 round found it with a probe (bd `drln` B1, two lenses
    // independently). *** The walk stops at a `CmpInst` (its operands are DATA —
    // the theta rail — not tree) and does not descend a `SelectInst`. For a shield
    // this function REWRITES, the children are covered by its own re-entry, which
    // tracks them on ITS entry. THE HOLE IS THE ONE SHAPE IT NEVER RE-ENTERS: a
    // shield under an xor-TRUE NOT. `isSupportedCondTree`'s xor-true arm recurses
    // NON-Strict (`return !Strict && isSupportedCondTree(op0, Depth+1, S)` — the
    // four-argument call, defaulting `Strict` back to false), so `xor(shield,
    // true)` IS admitted; this function has no xor arm, so `trackCondCone` tracks
    // the xor and the shield and STOPS, leaving the shield's compare children
    // untracked. Measured at HEAD WITH this fix: two use-free
    // `cq_template_icmp_{sgt,slt}_i32_hl` on the theta rail, no `_unc`, no
    // `cqrt_free` — two dangling ENTANGLED flags (Rules 6/8), `opt` exit 0,
    // verify-clean, and `free_pairing_check.py` "0 violation(s)" rc=0.
    //
    // *** THAT LEAK IS PRE-EXISTING, NOT INTRODUCED HERE — the shape is
    // BYTE-IDENTICAL on the 3319975 baseline. *** It is filed, not fixed under
    // cover of this one. The fix is a DESIGN CALL, not a one-liner: descending
    // `SelectInst` in `trackCondCone` would close more of the class but touches
    // the fence bd `j5i7` guards, so read `j5i7` first. What this commit owed and
    // pays is the CLAIM, narrowed to the shapes it holds for.
    //
    // *** BLAST RADIUS, AND QUOTE IT WITH ITS REACH RATHER THAN ITS DENOMINATOR
    // (the discipline this file already carries for bd 2qvr). *** A/B of the
    // shipped binary against this one: 1112 committed lit fixtures — 0 exit-code
    // flips, 0 stderr diffs, emitted IR differing in exactly the 2 new arm=TRUE
    // fixtures; and 239 REAL-C stage-1 e2e modules — 0 flips, 0 stderr diffs, 0 IR
    // diffs. THE SECOND ZERO IS A REACHED ZERO, which is the only thing that makes
    // it worth quoting: an instrumented build shows this function entered 3680
    // times across 109 of those 239 modules, and 16 of those entries are ON A
    // SHIELD — 4 in `coshl`, 3 in `sinhl`, and one each in `acoshl`, `tanhl`,
    // `pow`, `nextafterl` and `nexttoward` (ld80 and src spellings). So the rewrite
    // path this fix guards runs on real openlibm code; every one of those 16
    // shields is at DEPTH 0, which is exactly why nothing shipping leaked and why
    // the root-level measurement that missed this looked complete.
    trackCondCone(V);
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
      // bd 3c6m.67 — NO XOR ARM HERE, DELIBERATELY. An earlier draft recursed
      // through the two-operand xor so a shield nested under it would be
      // rewritten. E6's `Strict` sub-grammar refuses a shield (and a phi, and a
      // constant) ANYWHERE under an xor, so there is nothing beneath an xor for
      // this function to rewrite and the recursion would be dead code that
      // implies otherwise.
      //
      // *** THE DRAFT'S SECOND FAULT IS NOW FIXED, AND THAT CHANGES WHAT A FUTURE
      // WIDENING OWES — read this before reviving the recursion. *** It used to be
      // that every rebuild here STRANDED the node it replaced, because this
      // function tracked nothing; that was bd `kqqv`, and the `trackCondCone(V)`
      // at the top of this function closes it. So the stranding objection no
      // longer applies to a recursion here, and the ONLY remaining reason this arm
      // is absent is that `Strict` makes it unreachable. If `Strict` is ever
      // relaxed to admit a shield under an xor — an accept WIDENING, owing its own
      // scoped increment, its own decline fixtures and its own Rule-13 round, NOT
      // a side effect of this one — then this arm and `buildNegation`'s
      // kept-operand `canonicalizePred` call both become live again and both are
      // safe. Nothing in this commit widens anything: `Strict` is untouched and
      // `control_predmux_reject_xor_shielded_select_operand.ll` still declines.
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
    // bd qesi — TRACK THE NODE WE ARE ABOUT TO REPLACE, or it is STRANDED.
    //
    // Every non-constant path below consumes `V` and returns something ELSE: a
    // fresh inverse-predicate compare for a leaf, a fresh `or`/`and` for a node,
    // `operand(0)` for xor-true. So `V` loses its last use as soon as the entry
    // terminator is erased — and `sweepDead` erases only what is in `MaybeDead`.
    // Before this line the ONLY tracked member of the original tree was its ROOT
    // (`track(BI->getCondition())` in `run()`), so the leaves and every inner node
    // survived with zero uses and `lowerOps` lowered them to forward
    // `cq_template_*` gates never uncomputed and never freed — verbatim the hazard
    // the sibling residue cleanup names ("an entangled which-path flag left
    // dangling on a live rail ... trivially avoidable since the op is DEAD").
    //
    // MEASURED, FROM ORDINARY C: `if (q > 3 && q < 100)` at `clang -O1` puts the
    // gate arm on the FALSE successor (Rule 9), which is what routes the condition
    // through here instead of through `canonicalizePred`. Pre-fix that leaked 2
    // dead gates; the nested `a && (b && c)` leaked 4 (three original compares
    // plus the inner `and i1`). `opt` exited 0, the verifier was clean, and
    // `free_pairing_check.py` reported "0 violation(s), 0 unproven" — it counts
    // only `cqrt_alloc_*` mints and an orphan rail is TEMPLATE-minted (bd 1739).
    //
    // THE CAUSE HERE IS REPLACEMENT, NOT REBUILDING — but read the next paragraph
    // before concluding anything about `canonicalizePred`. This function REPLACES
    // each leaf, so the original is stranded. `canonicalizePred` also rebuilds (on a
    // shield) yet REUSES the original compare leaves, so only the shield node itself
    // dies. Pinned by `control_predmux_accept_positive_tree_orphan_armkill.ll`.
    //
    // *** AND THAT WAS NOT A CLEAN BILL OF HEALTH FOR `canonicalizePred`. AN EARLIER
    // DRAFT OF THIS COMMENT SAID IT ORPHANS "NOTHING, measured 0 at both
    // polarities" AND TOLD YOU NOT TO FIX IT; the measurement was real, the
    // directive was wrong, and bd `kqqv` has since FIXED the function. *** The
    // measurement had been taken only on shields that ARE the branch condition,
    // where `run()`'s `track(BI->getCondition())` happens to cover the shield — a
    // statement about DEPTH 0 that shipped without its scope clause. One level down
    // nothing tracked it: for `%inner = select i1 %b, i1 %c, i1 false` feeding
    // `%sc = and i1 %a, %inner`, the arm=TRUE route emitted an ENTIRE DEAD 4.4
    // controlled-copy select merge — an `%out = cqrt_alloc_i1(false)` written by two
    // `cqrt_copy_i1_controlled` and NEVER READ, plus a never-freed `%selop` and a
    // never-uncomputed `icmp_ne` — while arm=FALSE (this function) emitted zero
    // orphans. 9 rail mints / 5 left allocated versus 7 / 3.
    // `canonicalizePred` now opens with `trackCondCone(V)`; the pair
    // `control_predmux_accept_nonroot_shield_{no_orphan,armkill}.ll` and
    // `control_predmux_accept_shield_under_shield_no_orphan.ll` pin it, and the
    // depth table that replaced the unscoped claim lives in the first of those.
    //
    // THE LESSON IS THE SCOPE CLAUSE, NOT THE BUG. A "measured 0" that does not say
    // what it ranged over reads as a proof and acts as a prohibition. Both defects
    // in this family were found only because someone re-measured a shape the
    // original run had not covered — a census of all 1062 fixtures at the time
    // found ZERO carrying a non-root shielded select, accept or reject, so nothing
    // in the tree would ever have told us.
    //
    // *** IT ALSO RESTORES A CAPABILITY, WHICH IS WORTH KNOWING BECAUSE IT IS A
    // DECLINE -> ACCEPT FLIP AND THAT IS THE DIRECTION THE PRIME DIRECTIVE POLICES.
    // *** The orphans were not merely inert garbage: the uncompute spine WALKED them.
    // `int q = cq_theta(...); if (q > 3 && q < 100) { ... } cq_measure(q);` — ordinary
    // C — DECLINED before this fix with
    //     "cq uncompute: dead chain would free a measured register"
    // and lowers at exit 0 after it (measured, pre-fix plugin vs post-fix plugin on
    // the identical module). The decline was a FALSE POSITIVE the defect caused: the
    // "dead chain" was the compiler's own stranded tree, and reversing it would have
    // freed `q`, which the user measures. Removing the garbage removes the decline.
    // The resulting accept is sound — `q` is measured and never freed, and
    // `free_pairing_check` is clean on the output. A second measured cell moves a
    // `declineStaleRecordOps` decline to a control-flow decline; both are loud, both
    // exit non-zero, and no accept leaks. Blast radius on committed material is ZERO
    // (0 stderr diffs byte-for-byte across the corpus), but Rule 12 mirrors
    // diagnostic text character-for-character, so a future decline fixture in this
    // shape class must expect the NEW owner.
    //
    // ONE LINE SUFFICES AND NO NEW MACHINERY IS OWED (Rule 14): `sweepDead` is
    // already a `use_empty` FIXPOINT over `MaybeDead`, so tracking a parent and its
    // children in any order converges — erasing the parent is what makes the
    // children `use_empty`, and the next iteration takes them. `track` is inert on
    // a node still live elsewhere (a compare shared with another region, or read by
    // the arm body), because the sweep tests `use_empty` first. Safe against side
    // effects by construction: `isSupportedCondTree` admits only ConstantInt /
    // CmpInst / short-circuit SelectInst / and / or / xor-true here, all pure — a
    // phi is converted to boolean algebra BEFORE this runs.
    //
    // *** READ "ONE LINE SUFFICES" WITH ITS CLAUSE: it means no recursive tracker is
    // owed INSIDE THIS FUNCTION. It is NOT a class-wide closure, and the orphan class
    // is NOT closed module-wide. *** Of the FOUR producers of use-free emitted gates
    // this family has found, two are now fixed here in the flatten — this line and
    // bd kqqv's `trackCondCone` in `canonicalizePred` — and TWO ARE STILL OPEN:
    //
    //   * bd iwr7, STILL SHIPPING: 14 use-free `cq_template_zext_i32_to_i64` in TEN
    //     committed real-openlibm goldens, beside a `cqrt_qram_load` of the
    //     un-widened index; root-caused to `if (CI->hasOneUse()) DeadCast = CI;` in
    //     `lowerQramReads`, a multi-use clang `zext nneg` whose geps are all erased.
    //   * `run()`'s own `track(BI->getCondition())` on the entry terminator — a
    //     SINGLE track on the tree ROOT, verbatim the pattern the `trackCondCone`
    //     comment two functions down calls insufficient. When NO converted phi
    //     demands either edge predicate, neither `canonicalizePred` nor
    //     `buildNegation` runs and that one track is all the tree ever gets, so its
    //     inner nodes are untracked by exactly the argument used against per-site
    //     tracking here. Found by the bd `kqqv` Rule-13 round (bd `drln` B3), which
    //     is also why this ledger says four and an earlier draft said three.
    //
    // The durable fix is eventually a SWEEP-LEVEL INVARIANT — "no emitted gate may
    // have a use-free result" — which would subsume all four and would have caught
    // both of the fixed ones without anyone re-measuring a shape. Any such detector
    // MUST exempt `cqrt_alloc_*`, because Rule 6 legitimately leaves a
    // not-provably-|0> rail allocated and four committed fixtures declare their leak
    // CORRECT.
    //
    // AND QUOTE THIS FIX'S 0-FLIP RESULT WITH ITS REACH, never its denominator — the
    // same discipline this file already carries for bd 2qvr. Three independent
    // pre-fix/post-fix censuses over ~1282-2001 module-pairs found 0 exit-code flips
    // and 0 stderr diffs, but the fix DELETES something in only 3 real modules (12
    // counting synthetic polarity swaps). The honest sentence is "0 flips, and the
    // deletion reached 3 modules". Code-path reach is separately large — this function
    // visits ~3752 nodes across 147 modules — which is what makes the `use_empty`
    // inertness argument load-bearing rather than untested.
    if (isa<Instruction>(V))
      track(V);
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
    // *** bd `test_C_libtooling-fn1q` INCREMENT 2 — ¬rail. ***
    //
    // THIS ARM IS THE OTHER HALF OF THE E6 RAIL-LEAF ADMISSION, not a defensive
    // extra. Every line below this point assumes `V` is a `BinaryOperator`, and
    // the `cast<>` on the next line is UNCHECKED — an assert in a `+Asserts`
    // build and a bad cast in the RELEASE build every gate in this tree runs
    // (verbatim the hazard `isConvertiblePhiCond`'s condition 2 exists to prevent
    // for a `PHINode`). A rail-conditioned region reaches it the moment `-O1` puts
    // the gate arm on the FALSE successor, which is half the time (Rule 9).
    //
    // A rail is an OPAQUE `i1`, so there is no leaf compare to invert and no
    // De Morgan step to take: its negation is the one-node `xor %rail, true`,
    // which is the grammar's own NOT spelling (`isSupportedCondTree`'s xor-true
    // arm admits it, and `buildNegation` consumes it above as ¬¬x = x). Nothing is
    // duplicated and the negation stays at a leaf, so the no-NOT invariant is
    // untouched.
    //
    // ⚠ AND `collectCondTree` DOES **NOT** ACCEPT THE RESULT — an earlier draft of
    // this comment said it reads it "as an `xor` node over one `RailLeaves` entry
    // and one i1 constant, the shape it has carried since bd `3qlq.4`", and that
    // is FALSE (Rule-13 round 2, P2-2). `SelectClassify.cpp`'s node walk refuses
    // an `xor` with a CONSTANT operand outright, and says so beside the code; bd
    // `3qlq.4`'s rail-in-xor shape is `xor i1 %b, %c`, TWO NON-CONSTANT operands,
    // a different node.
    //
    // What makes this arm safe is therefore NOT a downstream consumer — it is the
    // ARM-SWAP FOLD at the flatten's select site, which removes the `xor` before
    // `collectCondTree` ever sees it. **The fold is load-bearing, not cosmetic**,
    // and a reader who believed the old sentence would conclude it is removable —
    // which round 1 measured turns the negated polarity into a claim-then-decline.
    //
    // ⚠ `track(V)` above IS reached for a rail, and an earlier draft of this
    // comment gave a FALSE reason for why that is safe — "the rail is the USER'S
    // register, it is live at their `cq_measure`, so tracking it is inert". That
    // is an assumption about the PROGRAM, not a property of the code: a user need
    // not measure `b`. Rule-13 round 1 (P1-1) measured the consequence — the
    // user's Ry DELETED, `opt` exit 0, stderr empty, where the oracle declined
    // loudly. It was also not the only tracking site; `run()`'s
    // `track(BI->getCondition())` reaches it at the polarity this function never
    // sees. The real fix is the exclusion in `sweepDead` (read its comment), and
    // the track here is genuinely inert ONLY because of that exclusion.
    // ⚠ THE RAIL PHI IS HERE FOR THE SAME REASON THE RAIL LEAF IS, AND LEAVING IT
    // OUT WAS A P1 (bd fn1q increment 5a, Rule-13 round 1 F1). E6 admits a rail φ
    // via `isStructuralRailPhi`, and that admission is checked BEFORE the
    // `dyn_cast<PHINode>` arm — so the φ never reaches `isConvertiblePhiCond` and
    // is never RECORDED, so `convertPhis` never converts it, so `literal()` hands
    // a raw `PHINode` to the `cast<BinaryOperator>` below. MEASURED: **exit 139,
    // SIGSEGV**, from ORDINARY C at the `-O1` floor — the owner's own program with
    // one operator changed (`if (!b0[i] && Z > 1)`) — where the oracle declines
    // loudly. Rule 1's "no third path" postcondition violated: no diagnostic, no
    // `!dbg`, an LLVM crash report instead of a decline. 12 of a 32-cell polarity
    // matrix crashed; the trigger is simply "the false-edge literal is demanded",
    // which `-O1` makes true about half the time (Rule 9).
    //
    // ⚠ `isConvertiblePhiCond` IS NOT THE ROUTE FOR THIS φ AND CANNOT BE MADE ONE.
    // Its condition 3 names this crash in writing; but a rail φ fails its
    // conditions by CONSTRUCTION, not by accident — the φ sits at the region
    // ENTRY (it fails `PB != S->Entry`) and a `cq_theta_i1` CALL incoming is not
    // in the STRICT `isBooleanCondTree` grammar (condition 4). A rail φ is not a
    // path-predicate φ the flatten converts; it is an OPAQUE i1 REGISTER read as a
    // CONTROL — the same kind of thing as a rail LEAF — so it takes the rail
    // leaf's route.
    if (isCondRailLeaf(V) || isStructuralRailPhi(V))
      return track(B.CreateXor(V, ConstantInt::getTrue(V->getContext())));
    auto *BO = cast<BinaryOperator>(V);
    if (BO->getOpcode() == Instruction::Xor) {
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)); C && C->isOne())
        return BO->getOperand(0);  // xor-true: ¬¬x = x
      // *** bd 3c6m.67 — ¬(a ⊕ b) = a ⊕ ¬b. NEGATE EXACTLY ONE OPERAND. ***
      //
      // READ THE GUARD ABOVE AS PART OF THIS FIX. Until 2026-08-23 this whole
      // arm was an UNCONDITIONAL `return BO->getOperand(0)`, sound only because
      // E6 admitted no xor but `xor X, 1`. The moment E6 admits a two-operand
      // xor, that line makes the false-edge literal `a` instead of `¬(a⊕b)`:
      // `opt` exits 0, the verifier is clean, `free_pairing_check.py` reports
      // zero violations (the network is structurally perfect — only its VALUE is
      // wrong), and the trace reads plausibly. The Prime Directive's exact
      // failure mode, reachable by a one-line widening two functions away.
      //
      // TWO WAYS TO GET THIS WRONG, both of which look reasonable:
      //   * negate BOTH operands — ¬a ⊕ ¬b = a ⊕ b, i.e. the IDENTITY. The false
      //     edge would be predicated on the TRUE condition. Not a near-miss.
      //   * expand to or(and(a,¬b), and(¬a,b)) — correct, but it DUPLICATES both
      //     leaves, which is the very thing the no-NOT invariant's De Morgan
      //     normal form exists to avoid, and doubles the flag mints.
      // The single-negation form keeps one xor node, duplicates nothing, and
      // leaves the negation at a leaf where the invariant wants it.
      //
      // THE KEPT OPERAND IS PASSED THROUGH VERBATIM. An earlier draft routed it
      // through `canonicalizePred` to rewrite a poison-shielded short-circuit
      // select on the kept side. That was a MEASURED silent defect AT THE TIME:
      // `canonicalizePred` did not `track()` what it replaced, so the shield was
      // STRANDED and lowered into a whole dead 4.4 select merge carrying an
      // entangled flag that was never uncomputed and never freed (decline ->
      // accept, invisible to `opt -verify` AND to `free_pairing_check.py`; found
      // by the Rule-13 round on that increment).
      //
      // *** THE STRAND IS FIXED (bd `kqqv` — `trackCondCone` at the top of
      // `canonicalizePred`), SO THIS PASS-THROUGH IS NO LONGER LOAD-BEARING FOR
      // SAFETY. *** It stays because E6's `Strict` makes the call pointless, not
      // because the call would be dangerous: a Strict operand is a compare leaf or
      // an and/or/xor tree over compare leaves — shapes `canonicalizePred` is the
      // IDENTITY on. Restoring the call is only ever part of relaxing `Strict`,
      // which is its own increment; read the `Strict` note on
      // `isSupportedCondTree` before touching either side of this.
      //
      // *** BUT KEEPING IT VERBATIM STILL OWES THE bd `qesi` TRACKING. *** This
      // arm is the only path in this function that does NOT re-enter
      // `buildNegation` on an operand, and re-entering is what tracks every
      // other cone for free. Without `trackCondCone` the kept sub-tree is
      // stranded whenever both literals die, and `lowerOps` lowers it into a
      // forward gate that is never uncomputed and never freed — the round-2
      // finding, measured, HEAD-declines. See `trackCondCone` for the full
      // account and for why one `track()` would not have been enough.
      trackCondCone(BO->getOperand(0));
      return track(B.CreateXor(BO->getOperand(0),
                               buildNegation(BO->getOperand(1))));
    }
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
      // *** bd `test_C_libtooling-woa0` — THE OBSERVATION. ***
      //
      // This is the first point at which "a φ an EMITTED predicate tree reads as
      // a rail leaf is being SELECT-CHAINED" is a FACT rather than a forecast,
      // and it is the only place IN THIS FILE where that conversion happens (⚠
      // NOT pass-wide: `MergePhiPeel.cpp` and `SwapRouteEmit.cpp` also mint a
      // `select` from a φ and RAUW it — both AFTER the re-ask, hence outside
      // this window BY CONSTRUCTION, which is a fact about the SLOT and not
      // about this call. Rounds A/B `F-RA-3`/`F-RB-7`). E6's
      // placement conjunct predicted it would not; the prediction is
      // POINT-IN-TIME (see `isSupportedCondTree`) and a later claim can falsify
      // it, so the fact is recorded here and the CALLER re-asks after the
      // fixpoint.
      //
      // ⚠ IT IS DELIBERATELY GATED ON `!BoolAlg`, AND THAT IS NOT A
      // CONSERVATISM — IT IS THE DIFFERENCE BETWEEN A FENCE AND A 2-CELL
      // REGRESSION. `isStructuralRailPhi` also matches an ALL-CONSTANT 2-incoming
      // `i1` φ, and for that shape `isBooleanCondTree` passes on every incoming,
      // so the boolean-algebra path runs and yields an in-grammar and/or tree
      // that every downstream consumer already accepts. Flagging it would decline
      // exactly the cells the M4 reviewer's first spelling broke (A→D in neither
      // the corpus nor round 1's probes, found only by a φ-incoming variant
      // matrix). The hazard is the SELECT CHAIN and nothing else.
      //
      // ⚠ NOTHING IS ABANDONED HERE. `run()` must not bail mid-mutation — see the
      // `declineAddressTakenBlocks` note in `flattenPredMuxRegions` for why an
      // early return inside `run()` spins the caller's fixpoint on a host with a
      // non-exiting diagnostic handler. Record and carry on; the module is
      // declined by the re-ask.
      if (!BoolAlg && Rec && recordHoldsRailPhiLeaf(*Rec, P)) {
        if (!Rec->Converted) {
          Rec->Converted = true;
          Rec->AtFn = D->getParent();
          Rec->AtLoc = P->getDebugLoc();
        }
        if (::getenv("CQ_PREDMUX_DBG"))
          errs() << "CQ_PREDMUX_DBG: converted recorded rail phi @"
                 << D->getParent()->getName() << " blk=" << D->getName()
                 << " phi=%" << P->getName() << "\n";
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
          // *** bd `test_C_libtooling-fn1q` INCREMENT 2 — ¬c IS AN ARM SWAP, NOT
          // AN `xor` NODE, AND THIS IS WHERE THE RAIL-LEAF ADMISSION IS PAID FOR.
          // ***
          //
          // `select(¬c, T, F) == select(c, F, T)`, unconditionally. The fold looks
          // cosmetic and is not: it is what keeps the E6 rail-leaf widening a
          // PRE-CLAIM decline AT THIS SITE instead of a claim-then-decline.
          //
          // ⚠ READ "AT THIS SITE" LITERALLY — an earlier draft said "everywhere it
          // is not supported" and that was FALSE (Rule-13 round 1, P2-2a). Three
          // claim-then-decline shapes survive and are known: a ¬rail nested inside
          // an and/or tree (`buildNegation` returns `or(xor(%rail,true), ¬cmp)` and
          // only a TOP-LEVEL xor is folded here), the BoolAlg composer's
          // `and(¬rail, X)`, and a region whose downstream owner declines for an
          // unrelated reason (measured: `control flow` -> `condition predates a
          // non-diagonal gate`). All are loud, non-zero and consume nothing.
          //
          // MEASURED, and it is the reason this exists. A rail-conditioned region
          // whose arm sits on the FALSE successor (Rule 9 — `clang -O1` picks that
          // polarity about half the time) takes its arm's edge predicate through
          // `buildNegation`, whose rail arm has no leaf compare to invert and so
          // spells ¬ the only way an opaque `i1` can be spelled: `xor %rail, true`.
          // `collectCondTree` then walks that node and hits the `i1` CONSTANT
          // child, which is off-grammar — so the module was FLATTENED and only
          // then declined `control flow` at `SelectClassify`, where before this
          // increment it declined at `E6-condtree` before anything was touched.
          // Same verdict, worse owner: this file's own bd `3c6m.67` self-operand
          // lesson says a claim it makes about its own grammar should hold
          // exactly, and a pre-claim decline is strictly cleaner.
          //
          // The swap removes the node entirely rather than teaching a second
          // consumer to parse it (Rule 14): `SelectMergeEmit` already spells ¬ for
          // a bare rail condition with its `cqrt_x` BRACKET on the CNOT-copied
          // ancilla — never on the user's register — so the swapped select is the
          // substrate's own negation spelling, and the emitted stream for the two
          // polarities is the same one with its two controlled copies exchanged.
          //
          // ⚠ SCOPE, AND IT IS A FILTER BECAUSE AN EARLIER DRAFT'S "BY
          // CONSTRUCTION" WAS MEASURED FALSE (Rule-13 round 1, P2-1). That draft
          // enumerated `buildNegation`'s four behaviours and concluded `xor X,
          // true` could reach this site from nothing else. It omitted the OTHER
          // producer of the value here: `literal()` is `canonicalizePred(cond)`,
          // and `canonicalizePred` has NO xor arm — it returns such a condition
          // unchanged. E6 admits `xor X, 1` in its own right (the no-NOT
          // invariant's negation spelling), so a region whose entry condition IS a
          // surviving `xor %cmp, true`, arm on successor(0), delivers a bare xor
          // here with NO RAIL IN THE MODULE AT ALL. Unfiltered, the fold took that
          // module from the ORACLE's loud `control flow` decline to an ACCEPT —
          // semantically correct, and still an accept-direction widening outside
          // this increment's scope, with no fixture, no probe family and no round.
          // The corpus could not see it: of 2126 fixtures, exactly ONE carries an
          // `xor i1 …, true` feeding a `br` and none on a claimable region (L10 —
          // an instrument is blind in the shape nobody pointed it at).
          //
          // So the operand is REQUIRED to be a rail leaf. That keeps the fold
          // exactly as wide as the `buildNegation` arm it exists to pay for. A
          // deliberate widening to a general `xor X, true` is a separate
          // increment and owes its own red-green pair.
          //
          // ⚠ The dead `xor` is already tracked by `buildNegation`'s own `track()`
          // (bd `qesi`), so `sweepDead`'s `use_empty` fixpoint collects it. It must
          // not be left untracked here — an orphan i1 op lowers to a forward
          // `cq_template_*` gate that is never uncomputed and never freed, and
          // `free_pairing_check.py` is structurally blind to a TEMPLATE-minted rail
          // (bd `1739`).
          Value *SwapT = In[I].second;
          Value *SwapF = Acc;
          if (auto *NotBO = dyn_cast<BinaryOperator>(EP))
            if (NotBO->getOpcode() == Instruction::Xor)
              if (auto *C1 = dyn_cast<ConstantInt>(NotBO->getOperand(1)))
                // ⚠ BOTH HALVES OR NEITHER. This fold is what REMOVES the `xor`
                // before `collectCondTree` sees it — `SelectClassify`'s node walk
                // refuses an `xor` with a CONSTANT operand outright — so the
                // `buildNegation` arm above is UNSOUND WITHOUT IT. Increment 2
                // landed both halves for the rail LEAF and said so; increment 5a
                // added the φ to the leaf's arm, and this operand test is the
                // second half it owes (Rule-13 round 1 F4 named it before the
                // fix was written). Widening the arm without widening this test
                // turns the negated polarity into a claim-then-decline.
                if (C1->isOne() && (isCondRailLeaf(NotBO->getOperand(0)) ||
                                    isStructuralRailPhi(NotBO->getOperand(0)))) {
                  EP = NotBO->getOperand(0);
                  std::swap(SwapT, SwapF);
                }
          Acc = track(B.CreateSelect(EP, SwapT, SwapF));
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

  // bd 01po.2 — the NeedsMask index `and idx, N-1` for a pow2 table of N cells.
  // -O1 widens a narrow gep index as `E iW src to i64`, E ∈ {sext, zext}.
  // Masking that i64 costs a W→64 widening template, an `and_i64_hl` and a
  // `trunc_i64_to_i32` bracket around EVERY QRAM call, forward and `_unc` (the
  // index rail has logical width 32, QramIndexWidth.h). So mask the source:
  //     gep index := zext iW (and iW src, N-1) to i64
  // EXACT, equal for every bit pattern of `src`, iff N-1 < 2^W:
  //   * E = zext: zext(src) & M == zext(src & M) for any M that fits in W bits
  //     (bits ≥ W are 0 on both sides);
  //   * E = sext: sext(src) equals src on bits [0,W) and M has no bit ≥ W, so
  //     sext(src) & M == zext(src & M). Up to N = 2^W only because the re-
  //     widening is ZEXT; a sext (or the gep's implicit sext of a narrow index)
  //     would need M below the sign bit, N ≤ 2^(W-1).
  // Always `zext`, never the source's kind, for two more reasons: the index
  // stays at the pointer-index width that any re-classification of this read
  // requires (`classifyQromReadUnderControlImpl`); and the shared bounds proof
  // (`qromIndexKnownInBounds`, re-asked by the Bennett-clone read fence and by an
  // enclosing claim) reads `zext` as value-preserving and `and` as ≤ M but
  // `sext` at full range (PoisonFacts `unconditionalMax`), so a sext would make
  // a masked clone read decline and an enclosing claim mask it again.
  // The QRAM emitter (`resolveQramIndex`) strips the zext and takes the masked
  // W-bit rail: at W = 32 it IS the index (no bracket); below, it is bracketed
  // by `zext_iW_to_i32`. Either way the rail the call reads equals the old
  // `trunc_i64_to_i32(E(src) & M)` bit for bit. An i1 mask is a flatten residue
  // that `simplifyFlattenResiduesInFunction` folds: N = 2 leaves the flag itself,
  // N = 1 the constant index 0 (a classical tbl[0] read, no QRAM call).
  // SCOPE: W ≤ 32 (a wider source would still need a trunc), N ≤ 2^31 (the
  // QRAM count is an i32), and W is the source's LOGICAL width (no laundered
  // `HandleWidth` record says otherwise: the argument above is about the
  // register's bits). Any other index (not a sext/zext: an i64 phi, a
  // `cttz.i64`, a `long`; a wider source; a larger table) keeps the i64 mask.
  Value *maskQromIndex(IRBuilder<> &MB, Value *Idx, uint64_t Count) {
    const uint64_t Mask = Count - 1;
    if (auto *Ext = dyn_cast<CastInst>(Idx))
      if ((isa<SExtInst>(Ext) || isa<ZExtInst>(Ext)) &&
          Count <= (uint64_t(1) << 31)) {
        Value *Src = Ext->getOperand(0);
        unsigned W = Src->getType()->getScalarSizeInBits();
        if (Src->getType()->isIntegerTy() && W <= 32 && (Mask >> W) == 0 &&
            logicalOperandWidth(Src, Taint) == abiWidthFromType(Src->getType())) {
          Value *Narrow =
              track(MB.CreateAnd(Src, ConstantInt::get(Src->getType(), Mask)));
          return track(MB.CreateZExt(Narrow, Idx->getType()));
        }
      }
    return track(MB.CreateAnd(Idx, ConstantInt::get(Idx->getType(), Mask)));
  }

  Value *track(Value *V) {
    MaybeDead.push_back(V);
    return V;
  }

  // bd 3c6m.67 (Rule-13 round 2) — track a KEPT condition sub-tree, node AND
  // every descendant, without rebuilding it.
  //
  // TWO CALLERS, ONE OBLIGATION. `buildNegation`'s two-operand xor arm (below,
  // the original customer) and `canonicalizePred`'s entry (bd `kqqv`). Both need
  // it for the same reason and neither is the "replacement" case: a node this
  // pass KEEPS is stranded just as surely as one it replaces, whenever the
  // literal that was going to consume it is itself dropped.
  //
  // *** BUT ONE CALLER'S WITNESS STOPPED WITNESSING WHEN THE OTHER LANDED, AND
  // THE FIXTURE THAT SHOULD CATCH THAT DOES NOT EXIST YET (bd `drln` C2). ***
  // MEASURED at this commit: delete the `trackCondCone(BO->getOperand(0));` in
  // the xor arm below and ALL ELEVEN xor fixtures stay green — including
  // 3c6m.67's own `control_predmux_accept_xor_kept_cone_no_orphan.ll`, because
  // bd `kqqv`'s entry call now covers that fixture's tree through the OTHER
  // polarity. The line is still LOAD-BEARING in general: a module whose arm value
  // is LAST in both merge phis demands only `literal(entry, 1)`, so
  // `canonicalizePred` is never called and this arm is the only tracker. That
  // witness has no fixture, so DO NOT read the eleven greens as evidence the line
  // is removable — they are evidence the SUITE cannot currently tell. Restoring
  // the pin is owed and is tracked on bd `drln`.
  //
  // WHY IT EXISTS. `buildNegation`'s contract is "TRACK THE NODE WE ARE ABOUT TO
  // REPLACE, or it is STRANDED" (bd `qesi`), and every pre-existing arm honours
  // it for free by RE-ENTERING `buildNegation` on each operand, which tracks on
  // entry. The two-operand xor arm is the first path that keeps an operand
  // VERBATIM — that is the whole point of ¬(a⊕b) = a ⊕ ¬b, since re-entering on
  // the kept side would negate it. So the kept cone needs tracking explicitly.
  // `canonicalizePred` is the same story one function over: it re-enters on
  // `and`/`or` operands and on a shield's condition and live arm, but has no xor
  // arm, so entry-walking is what makes ITS contract shape-independent instead of
  // resting on `buildNegation` also being called (measured: often it is NOT — of
  // 166 conditional-branch terminators across the fixture corpus, 86 are asked
  // for `Idx=0` ONLY, which is precisely the set where `canonicalizePred` runs
  // and `buildNegation` never does. State it as that 86 and not as "86 asked for
  // one polarity only": one-polarity-only is 101, the 86 plus the 15 `Idx=1`-only
  // — a different set, and the 86 is the one the argument needs. bd `drln` S3
  // caught the two figures for one measurement inside one diff.)
  //
  // MEASURED CONSEQUENCE OF NOT DOING IT (the round-2 finding, reproduced): when
  // BOTH literals die — the original xor, tracked on entry, and the rebuilt xor
  // — `sweepDead` erases both, the kept operand drops to zero uses, and being
  // absent from `MaybeDead` it survives. `lowerOps` then lowers that stranded
  // TAINTED compare into a forward `cq_template_icmp_*` with no `_unc` and no
  // `cqrt_free`: a dangling ENTANGLED which-path flag on a rail the user goes on
  // to measure (Rules 6/8). Measured on an all-`false` i1 merge phi (the BoolAlg
  // ∧false rule computes each edge predicate and then DROPS it): HEAD declines,
  // the un-tracked version accepted and leaked. The `or`/`and` twins of the same
  // module emit NO compare at all — the leak was specific to this arm.
  //
  // A SINGLE `track(operand(0))` IS NOT ENOUGH, which is why this is a walk:
  // `sweepDead` is a `use_empty` fixpoint over `MaybeDead` ONLY, so erasing a
  // tracked parent makes its children `use_empty` but never erases them unless
  // they are tracked too. Measured: a kept operand of `and i1 %ca, %cb` leaked
  // THREE gates (both compares and the `and`), not one.
  //
  // It stops at the CmpInst leaf on purpose — the compare's OPERANDS are DATA
  // (the theta rail), not condition-tree nodes, and `buildNegation`'s own leaf
  // arm does not track them either. `track` is inert on anything still live
  // (the sweep tests `use_empty` first), so a shared leaf or a node the arm body
  // also reads is unaffected.
  void trackCondCone(Value *V) {
    SmallVector<Value *, 8> WL{V};
    SmallPtrSet<Value *, 8> Seen;
    while (!WL.empty()) {
      Value *X = WL.pop_back_val();
      if (!Seen.insert(X).second)
        continue;
      auto *I = dyn_cast<Instruction>(X);
      if (!I)
        continue;
      track(I);
      if (isa<CmpInst>(I))
        continue;  // leaf — its operands are data, not tree.
      if (auto *BO = dyn_cast<BinaryOperator>(I)) {
        WL.push_back(BO->getOperand(0));
        WL.push_back(BO->getOperand(1));
      }
    }
  }

  // Erase any moved/minted instruction that ended up unused (e.g. the unused
  // fallback edge-predicate) so no dead tainted producer reaches lowerOps.
  // All tracked values are pure, so this is a plain use_empty fixpoint.
  //
  // *** bd `test_C_libtooling-fn1q` INCREMENT 2, Rule-13 ROUND 1 (P1-1) — THIS
  // SWEEP MUST NEVER ERASE THE USER'S RAIL, AND THE PROJECT HAD ALREADY RULED SO
  // IN THE SIBLING STAGE. ***
  //
  // `RegionFlatten.cpp`'s teardown carries the identical conjunct with the
  // decision written out (bd `3qlq.4`): *"a RAIL-LEAF condition is the USER'S
  // `cq_theta_i1` — never this stage's to erase, WHATEVER ITS USE COUNT."* This
  // stage had no such conjunct, and until increment 2 it did not need one: the
  // E6 grammar admitted `ConstantInt`/`CmpInst`/`and`/`or`/`xor`/short-circuit
  // `select`/convertible `PHINode` and **no `CallInst` at all**, so no CQ
  // front-end intrinsic could ever become a CONDITION-TREE NODE and reach
  // `track()`. The rail leaf makes one. THREE sites then put it in `MaybeDead`:
  // `run()`'s `track(BI->getCondition())` (both polarities), `buildNegation`'s
  // `track(V)` (false polarity), and `canonicalizePred`'s `trackCondCone` (true
  // polarity).
  //
  // ⚠ "CONDITION-TREE NODE" IS LOAD-BEARING IN THAT SENTENCE AND AN EARLIER DRAFT
  // BLURRED IT (Rule-13 round 2, P3-2). `run()` ALSO does
  // `track(SI->getCondition())` for a SWITCH SCRUTINEE, with NO grammar check at
  // all — E6 asks a switch only `Taint.Tainted.count` + `isMuxableType` — so a
  // `@cq_theta_si32` CALL can reach `track()` without ever being a cond-tree node,
  // and `isCondRailLeaf` is `cq_theta_i1`-ONLY, so this clause would not protect
  // it. Whether such a scrutinee can actually end up `use_empty()` here is
  // **UNPROVEN IN BOTH DIRECTIONS** — round 2 could not construct a module where
  // it dies. Say "unproven"; do not upgrade it to "safe", do not downgrade it to
  // "a hole".
  //
  // MEASURED before the fix, on a rail-conditioned diamond whose merge phis the
  // BoolAlg composer drops and whose rail is read nowhere else: the ORACLE
  // declined loudly (exit 1, `control flow`) and the subject exited **0 with 0
  // bytes of stderr and NO `cqrt_alloc_i1` and NO `cqrt_ry_i1` in the stream** —
  // the user's Ry deleted outright. `opt -verify` clean; `free_pairing_check.py`
  // reports `0 violation(s), 0 unproven` because it is structurally blind to a
  // rail that no longer exists. A VANISHING USER GATE (Rule 5), and the exact
  // failure increment 1's (K5) closed one stage over.
  //
  // ⚠ THE CONTROL IS WHAT MAKES IT A DEFECT RATHER THAN A POLICY: the SAME dead
  // `cq_theta_i1` with no region at all lowers on BOTH binaries (forward Ry +
  // `_unc`). The deletion is not a general dead-code rule the pass applies; it is
  // this sweep reaching a value it was never meant to own.
  //
  // ⚠ GUARDED HERE, AT THIS ERASER, RATHER THAN AT THE THREE `track()` SITES —
  // deliberately, and it is the `markBranchPhaseGate` lesson inverted. A per-site
  // fence is only as complete as its most-forgotten site, and a fourth tracker
  // added later would re-open this with no diagnostic anywhere.
  //
  // ⚠ AN EARLIER DRAFT JUSTIFIED THAT CHOICE WITH "THERE IS EXACTLY ONE PLACE THIS
  // PASS ERASES", AND THAT SENTENCE IS FALSE (Rule-13 round 2, P2-1). It is the
  // only place THIS SWEEP erases. The pass has at least three more instruction
  // erasers downstream of a flatten — `simplifyFlattenResiduesInFunction`'s
  // `RecursivelyDeleteTriviallyDeadInstructions`, `foldConstantConeAndBranches`'
  // own `eraseFromParent`, and `removeUnreachableBlocksChecked` — and the FIRST of
  // them was MEASURED to reproduce the round-1 P1 verbatim: a rail whose only
  // surviving use after the flatten is a folded residue is deleted there, `opt`
  // exit 0, 0 bytes of stderr, no `cqrt_alloc_i1`, no `cqrt_ry_i1`. THIS CLAUSE
  // DOES NOT REACH IT.
  //
  // Two measurements cap that at a filed follow-on rather than a blocker, and both
  // belong in the same breath as the hole: it needs an attributed
  // `declare i1 @cq_theta_i1(…) memory(none)`, which `CQ.h` CANNOT produce (with
  // the shipped bare declaration the rail survives); and it is **PRE-EXISTING** —
  // the same probe with a COMPARE-conditioned region, a shape the oracle already
  // claims, deletes the rail ON THE ORACLE TOO. ⚠ But "pre-existing" is true of
  // the DEFECT and FALSE of its POPULATION: the rail leaf adds customers. Filed
  // with its probes; do not read this paragraph as a clearance.
  //
  // ⚠ And note what the pre-existing comment at that site gives as its safety
  // ground — "never a cq_theta/phi/measure call — those have side effects". That
  // is a property of the DECLARATION, not of the code, which is increment 1's own
  // (K5) lesson: the question was never the name or the attribute, it is *does a
  // CQ stage OWN this call?*
  //
  // ⚠ `isCondRailPhiShape` is excluded TOO, ahead of its own increment, for the
  // reason `RegionFlatten`'s comment gives: the first widening that hands a
  // φ-conditioned region a flatten must not re-open this in silence. It has no
  // subject at E6 today (the rail-φ leaf is deliberately not admitted).
  void sweepDead() {
    bool Changed = true;
    while (Changed) {
      Changed = false;
      for (WeakTrackingVH &H : MaybeDead) {
        auto *I = dyn_cast_or_null<Instruction>(H.operator Value *());
        if (I && (isCondRailLeaf(I) || isCondRailPhiShape(I)))
          continue;  // the USER'S register — never this stage's to erase.
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

// bd `cfmv` — THE SECOND ERASER, GUARDED.
//
// ⚠ WHY THIS EXISTS. `PredMuxFlatten` has at least FOUR instruction erasers, and
// bd `fn1q` increment 2 guarded exactly one of them (`sweepDead`). Rule-13 round 2
// of that increment MEASURED this one reproducing the same P1 verbatim: a user's
// `cq_theta` rail whose only surviving use after the flatten is a folded residue
// (`and i1 %rail, false`) is deleted here, so the user's Ry VANISHES — `opt` exit
// 0, 0 BYTES of stderr, no `cqrt_alloc_i1`, no `cqrt_ry_i1`. That is Rule 5 (the
// compiler never removes a gate the user wrote) and the verify-clean
// silent-miscompile class. `free_pairing_check.py` is structurally blind: there is
// no rail left to count.
//
// ⚠ THE PRE-EXISTING SAFETY GROUND AT THIS SITE WAS WRONG, and it is the whole
// lesson. It said `RecursivelyDelete` removes "never a cq_theta/phi/measure call —
// those have side effects". That is a property of the DECLARATION, not of the
// code: an attributed `declare i1 @cq_theta_i1(…) memory(none) nounwind
// willreturn` IS trivially dead by LLVM's rules and IS deleted. Increment 1's (K5)
// lesson, third instance — **the question was never the name or the attribute, it
// is: DOES A CQ STAGE OWN THIS CALL?**
//
// LLVM's `RecursivelyDeleteTriviallyDeadInstructions` cannot be vetoed (its
// callback only observes), so the walk is spelled out here. It is deliberately the
// SAME SHAPE as LLVM's — `isInstructionTriviallyDead` + an operand worklist — with
// exactly one added question, asked by CALLING the shipped predicates rather than
// re-deriving them (Rule 14).
//
// ⚠ SCOPE, STATED SO IT IS NOT MISREAD AS A CLEARANCE OF THE OTHER TWO: this
// guards eraser (2). `foldConstantConeAndBranches`' own `eraseFromParent` and
// `removeUnreachableBlocksChecked` are erasers (3) and (4) and are NOT guarded
// here. Neither has a measured subject; that is an absence of a probe, not a proof.
void deleteDeadPreservingCqOwned(Instruction *Root) {
  SmallVector<Instruction *, 16> Work{Root};
  SmallPtrSet<Instruction *, 16> Seen{Root};
  while (!Work.empty()) {
    Instruction *I = Work.pop_back_val();
    // THE ONE ADDED QUESTION. A register the USER wrote is never this stage's to
    // erase, WHATEVER ITS USE COUNT and whatever attributes its declaration
    // carries — the ruling `RegionFlatten.cpp` has carried since bd `3qlq.4`, and
    // which did not propagate here by being true.
    if (isCondRailLeaf(I) || isCondRailPhiShape(I))
      continue;
    if (!isInstructionTriviallyDead(I))
      continue;
    SmallVector<Instruction *, 4> Ops;
    for (Value *O : I->operands())
      if (auto *OI = dyn_cast<Instruction>(O))
        Ops.push_back(OI);
    I->eraseFromParent();
    for (Instruction *OI : Ops)
      if (Seen.insert(OI).second)
        Work.push_back(OI);
  }
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
      // ⚠ NOT `RecursivelyDeleteTriviallyDeadInstructions`. Its guarantee is
      // "pure, use-free instructions only", and the sentence that used to stand
      // here — "never a cq_theta/phi/measure call, those have side effects" — is a
      // claim about the DECLARATION, which bd `cfmv` measured false. See
      // `deleteDeadPreservingCqOwned` above for the witness and the ruling.
      deleteDeadPreservingCqOwned(I);
      Changed = Any = true;
    }
  }
  return Any;
}

bool flattenPredMuxRegions(Module &M, TaintSet &Taint, bool ClaimAll,
                           PredMuxRailPhiRecord *Rec) {
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
    LazyLoadAnalyses Loads(F, DT, LInfo);  // bd fn1q inc 4 — built on first load
    SmallPtrSet<BasicBlock *, 16> OnCycle;
    collectCycleBlocks(F, OnCycle);

    for (BasicBlock &BB : F) {
      Instruction *T = BB.getTerminator();
      if (!isTaintedCtrlTerm(T, Taint))
        continue;
      PredMuxRegion R;
      if (!recoverRegion(T, PDT, DT, LInfo, OnCycle, Taint, R, ClaimAll, &Loads))
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
      // bd `test_C_libtooling-woa0` — COMMIT the rail-φ leaves E6 admitted, and
      // commit them HERE: the claim is final (every `leave` above discarded the
      // whole `R`, the `BoolAlgPhis` precedent) and `run()` has not started, so
      // the record is live before this region's OWN `convertPhis(R.Merge)` — which
      // is the one cell M4's conjunct over-admits (bd `test_C_libtooling-0fly`).
      // Committing at the E6 ADMISSION instead would record φs for regions that
      // never emitted and turn a later, unrelated claim into a decline.
      if (Rec)
        for (PHINode *P : R.RailPhiLeaves)
          if (!recordHoldsRailPhiLeaf(*Rec, P))
            Rec->Leaves.emplace_back(P);
      // bd `test_C_libtooling-xdu2.13` — COMMIT the rule-(B) marks at the same
      // point and for the same reason (claim final, `run()` not started).
      for (const WeakVH &PC : R.PredictedConds)
        markPredictedTaintCone(PC);
      IRBuilder<> Builder(T);
      Builder.SetCurrentDebugLocation(T->getDebugLoc());
      RegionFlattener(R, Builder, Rec, Taint).run();
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

// bd `test_C_libtooling-woa0` — THE RE-ASK. Contract in `PredMuxFlatten.h`.
//
// CLAUDE.md L1's standing cure, applied one stage over from where it was written:
// the question E6 asked ("will this flatten convert the rail φ I am about to read
// as a leaf?") is RECORDED at the claim and re-asked here, after the fixpoint, in
// BOTH entry points, declining loudly. What makes it a fence rather than an
// argument is that it reports an OBSERVED conversion, not a re-derived placement
// — so it cannot MISS a conversion of a φ the record holds.
//
// ⚠ THAT IS ONE-SIDED AND THE OTHER SIDE IS A MEASURED DEFECT. "It cannot
// over-decline a φ that was never converted" is literally true and answers the
// wrong question: the exhibits in Rule-13 rounds A and B (`F-RA-1`/`F-RB-1`) are
// φs that WERE converted, having been RECORDED at the E6 admission and never
// READ by the lazily-built edge predicates, so their RAUW was vacuous and the
// decline spurious. See `PredMuxFlatten.h`.
//
// ⚠ THIS IS WHY THE FILE'S "PredMux NEVER DIAGNOSES" HEADLINE IS NOW QUALIFIED
// RATHER THAN TRUE. The claim path is still accept-only: `recoverRegion` returns
// a `leave` for every shape it refuses, and this function is not on it. What
// speaks here is a POSTCONDITION on a mutation that already happened, which is
// the `declineSurvivingIntrinsicCalls` shape (Rule 1: make a postcondition a
// CHECKED, LOUD property rather than a comment) and not a new claim gate.
//
// ⚠ LOUD, NOT AN `assert`. Release builds have assertions off and Release is what
// every gate in this tree runs — and this whole finding family exists because an
// assertion-only `cast<>` in this same file was a silent wrong unitary in
// Release and a clean abort under `+Asserts`, a build the tree has never had.
bool declineConvertedRailPhiLeaves(const PredMuxRailPhiRecord &Rec) {
  if (!Rec.Converted || !Rec.AtFn)
    return false;
  auto *At = const_cast<Function *>(Rec.AtFn);
  At->getContext().diagnose(DiagnosticInfoUnsupported(
      *At,
      "cq controlled lowering: emitted predicate tree's rail phi converted by a "
      "later flatten",
      Rec.AtLoc));
  return true;
}

}  // namespace cq
