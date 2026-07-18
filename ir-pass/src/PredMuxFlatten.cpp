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
//        (nested tainted terminators; multi-phi / >2-incoming br merges). A
//        flat sole-2-incoming-phi diamond, a straight-line-arm switch, and the
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
#include "OpcodeSupport.h"  // abiWidthFromType, binaryStem, castInScope, i80BinaryInScope
#include "QramLowering.h"
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/ScopeExit.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"

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
  Type *OpTy = Cmp->getOperand(0)->getType();
  if (OpTy->isPointerTy() || OpTy->isVectorTy())
    return false;
  if (auto *IT = dyn_cast<IntegerType>(OpTy))
    return IT->getBitWidth() <= 64;
  return OpTy->isHalfTy() || OpTy->isFloatTy() || OpTy->isDoubleTy() ||
         OpTy->isX86_FP80Ty();
}

// bd adia (fwd decl — defined with the E4 pure-callee machinery below).
bool isSpeculatablePureCalleeBody(const Function *F);

// bd adia: is every instruction in `V`'s backward cone TOTAL (defined on all
// inputs) once its poison-generating flags/metadata are dropped? The
// admissibility proof for canonicalizing a poison-shielded short-circuit
// select-form into a plain and/or (which observes the shielded operand on
// basis states the original never did). Whitelist, mirroring the
// isSpeculatableDataflow families but STRICTER — definedness, not just
// speculation safety:
//   * icmp/fcmp (FMF dropped), add/sub/mul/and/or/xor (nsw/nuw dropped),
//     udiv/sdiv/urem/srem by the isSpeculatableDataflow-safe CONSTANT only;
//   * shl/lshr/ashr ONLY by an in-range ConstantInt amount (a runtime
//     amount >= bit width is INHERENT poison — no flag to drop);
//   * the defined casts zext/sext/trunc/fpext/fptrunc/sitofp/uitofp/bitcast
//     (fptosi/fptoui are inherent poison on out-of-range inputs — fail);
//   * select/phi/freeze, curated memory(none) intrinsics (total fns);
//   * Constant/Argument leaves (arguments are assumed runtime-defined — the
//     same leaf assumption every existing flatten makes; undef phi
//     incomings are zero-frozen by convertPhis).
// Anything else fails and the select-form stays unclaimed (accept-only).
bool coneDefinedAfterFlagDrop(const Value *Root) {
  SmallPtrSet<const Value *, 16> Seen;
  SmallVector<const Value *, 16> WL;
  WL.push_back(Root);
  while (!WL.empty()) {
    const Value *V = WL.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    const auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // Constant / Argument leaf — defined.
    bool Ok = false;
    if (isa<CmpInst>(I) || isa<SelectInst>(I) || isa<PHINode>(I) ||
        isa<FreezeInst>(I)) {
      Ok = true;
    } else if (const auto *BO = dyn_cast<BinaryOperator>(I)) {
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
        Ok = true;
        break;
      case Instruction::Shl:
      case Instruction::LShr:
      case Instruction::AShr:
        if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
          Ok = C->getZExtValue() <
               BO->getType()->getScalarSizeInBits();
        break;
      case Instruction::UDiv:
      case Instruction::SDiv:
      case Instruction::URem:
      case Instruction::SRem: {
        const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1));
        Ok = C && !C->isZero() &&
             !((BO->getOpcode() == Instruction::SDiv ||
                BO->getOpcode() == Instruction::SRem) &&
               C->isMinusOne());
        break;
      }
      default:
        break;
      }
    } else if (const auto *CI = dyn_cast<CastInst>(I)) {
      switch (CI->getOpcode()) {
      case Instruction::ZExt:
      case Instruction::SExt:
      case Instruction::Trunc:
      case Instruction::FPExt:
      case Instruction::FPTrunc:
      case Instruction::SIToFP:
      case Instruction::UIToFP:
      case Instruction::BitCast:
        Ok = true;
        break;
      default:  // fptosi/fptoui/ptr casts — inherent poison / out of scope.
        break;
      }
    } else if (const auto *Call = dyn_cast<CallInst>(I)) {
      // A cq_theta/cq_phi rotation result is RUNTIME DATA minted by the
      // runtime ABI — a defined leaf, never poison (do not recurse into the
      // classical seed/angle operands: the result's definedness does not
      // depend on them being poison-free in this proof's sense — the
      // rotation call itself would be the UB-observing consumer, which the
      // original program already executed unconditionally here).
      const Function *CF = Call->getCalledFunction();
      if (CF && (CF->getName().starts_with("cq_theta_") ||
                 CF->getName().starts_with("cq_phi_"))) {
        continue;  // defined leaf — skip operand recursion.
      }
      // A curated memory(none) intrinsic and a proven pure/total pending-spec
      // callee are total functions of their operands.
      Ok = (isCuratedReversibleIntrinsic(Call) &&
            Call->doesNotAccessMemory()) ||
           isSpeculatablePureCalleeBody(CF);
    }
    if (!Ok)
      return false;
    for (const Value *Op : I->operands())
      WL.push_back(Op);
  }
  return true;
}

// E6 — a branch condition PredMux can take BOTH polarities of: a supported
// compare, an and/or tree over such conditions, an xor-true (not), or an i1
// constant. The false-edge literal is built by pushing the negation to the
// leaves (De Morgan), so every emitted predicate tree stays inside the
// 3c6m.12-cleared and/or-over-compare-leaves shape (the no-NOT invariant).
bool isSupportedCondTree(const Value *V, unsigned Depth) {
  if (Depth > 8)
    return false;
  if (isa<ConstantInt>(V))
    return true;
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp);
  if (const auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::And ||
        BO->getOpcode() == Instruction::Or)
      return isSupportedCondTree(BO->getOperand(0), Depth + 1) &&
             isSupportedCondTree(BO->getOperand(1), Depth + 1);
    if (BO->getOpcode() == Instruction::Xor)
      if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
        if (C->isOne())
          return isSupportedCondTree(BO->getOperand(0), Depth + 1);
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
  if (const auto *Sel = dyn_cast<SelectInst>(V)) {
    if (!Sel->getType()->isIntegerTy(1))
      return false;
    if (const auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue()))
      if (FC->isZero())
        return coneDefinedAfterFlagDrop(Sel->getTrueValue()) &&
               isSupportedCondTree(Sel->getCondition(), Depth + 1) &&
               isSupportedCondTree(Sel->getTrueValue(), Depth + 1);
    if (const auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue()))
      if (TC->isOne())
        return coneDefinedAfterFlagDrop(Sel->getFalseValue()) &&
               isSupportedCondTree(Sel->getCondition(), Depth + 1) &&
               isSupportedCondTree(Sel->getFalseValue(), Depth + 1);
  }
  return false;
}

// Inc 2 — the SUBSTRATE-grammar condition tree (a strict subset of
// isSupportedCondTree): compare leaves and distinct-operand `and i1`/`or i1`
// nodes only — no xor-true, no trunc/freeze/select/phi, no compares OVER i1
// operands. This mirrors `collectCondTree` (SelectClassify.cpp) plus its
// self-operand and i1-operand-leaf fences, because an i1 phi converted to
// boolean algebra composes its incomings INTO a select condition the 3c6m.12
// flag-mint must accept verbatim. i1 constants are additionally admitted —
// they never reach the tree (the composer folds ∧true/∧false away). Anything
// off-grammar falls back to the Inc-1 select chain (same loud decline at the
// consuming select as today — posture unchanged).
bool isBooleanCondTree(const Value *V, unsigned Depth) {
  if (Depth > 16)
    return false;
  if (const auto *C = dyn_cast<ConstantInt>(V))
    return C->getType()->isIntegerTy(1);
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp) &&
           !Cmp->getOperand(0)->getType()->isIntegerTy(1);
  if (const auto *BO = dyn_cast<BinaryOperator>(V))
    if (BO->getType()->isIntegerTy(1) &&
        (BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or))
      return BO->getOperand(0) != BO->getOperand(1) &&
             isBooleanCondTree(BO->getOperand(0), Depth + 1) &&
             isBooleanCondTree(BO->getOperand(1), Depth + 1);
  return false;
}

// E4 — one instruction of pure speculatable dataflow at template-supported
// widths. Loads are excluded in v1 (the Inc-3 QROM/volatile-fold proofs land
// separately); ANY other call — including every @cq_* front-end intrinsic, so
// phase/value-rotation arms and 6.5 classical-call arms structurally stay
// with their shipped owners — and any store/atomic excludes the region.
bool isSpeculatableDataflow(const Instruction &I) {
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
    return !OpTy->isPointerTy() && isTemplateWidthType(OpTy);
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
    // one-directional by design elsewhere: icmp/select/freeze at i80 stay
    // conservatively UNCLAIMED here (isTemplateWidthType excludes i80) even
    // though CompareLowering could lower a straight-line icmp i80 — an
    // over-decline, always safe; the canonical promotion never puts those
    // inside an arm.
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
bool isSpeculatablePureCalleeBodyImpl(
    const Function *F, SmallPtrSetImpl<const Function *> &OnStack) {
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
  if (!F || !F->hasExactDefinition() || F->isVarArg())
    return false;
  if (!OnStack.insert(F).second)
    return false;  // call-graph cycle: termination unprovable
  auto pop = llvm::make_scope_exit([&] { OnStack.erase(F); });
  for (scc_iterator<const Function *> It = scc_begin(F); !It.isAtEnd(); ++It)
    if (It->size() > 1 || It.hasCycle())
      return false;  // a CFG cycle: termination unprovable
  for (const BasicBlock &BB : *F) {
    const Instruction *Term = BB.getTerminator();
    if (!isa<BranchInst>(Term) && !isa<ReturnInst>(Term))
      return false;
    for (const Instruction &I : BB) {
      if (I.isTerminator())
        continue;
      if (const auto *CI2 = dyn_cast<CallInst>(&I)) {
        if (isCuratedReversibleIntrinsic(CI2) && CI2->doesNotAccessMemory())
          continue;
        if (isSpeculatablePureCalleeBodyImpl(CI2->getCalledFunction(), OnStack))
          continue;
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at call: " << I << "\n";
        return false;
      }
      if (!isSpeculatableDataflow(I)) {
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
  SmallPtrSet<const Function *, 8> OnStack;
  return isSpeculatablePureCalleeBodyImpl(F, OnStack);
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

// The full E-ladder. Pure analysis; returns false to LEAVE (never diagnoses).
bool recoverRegion(Instruction *T, PostDominatorTree &PDT, DominatorTree &DT,
                   LoopInfo &LInfo, const SmallPtrSetImpl<BasicBlock *> &OnCycle,
                   const TaintSet &Taint, PredMuxRegion &R, bool ClaimAll) {
  BasicBlock *E = T->getParent();
  auto *Node = PDT.getNode(E);
  if (!Node || !Node->getIDom() || !Node->getIDom()->getBlock())
    return false;
  BasicBlock *Mg = Node->getIDom()->getBlock();
  // bd adia debug lever (env-gated, byte-neutral)
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
  for (const PHINode &P : Mg->phis()) {
    ++NumMergePhis;
    SolePhiIncomings = P.getNumIncomingValues();
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
    Claim = NestedTainted || ClaimableRead || NumMergePhis >= 2 ||
            (NumMergePhis == 1 && SolePhiIncomings > 2);
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
    if (!isa<BranchInst>(Term) && !isa<SwitchInst>(Term))
      return leave("E3-multiexit", Term);  // ret/unreachable/invoke/… inside: multi-exit
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
  for (BasicBlock *B : R.InRegion) {
    // E6: every conditional terminator tainted, with an invertible condition.
    const Instruction *Term = B->getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(Term)) {
      if (BI->isConditional()) {
        // bd adia (3c6m.55 Lever C): a CONSTANT-condition br (a fold residue the fp80
        // promotion or an earlier flatten materialized late) is degenerate —
        // no runtime classical/quantum mixing; the literal machinery folds
        // ∧true/∧false natively (isSupportedCondTree admits ConstantInt).
        if (!Taint.Tainted.count(BI->getCondition()) &&
            !isa<ConstantInt>(BI->getCondition()))
          return leave("E6-classicalbr", BI);  // classical control inside a tainted region: mixed
        if (!isSupportedCondTree(BI->getCondition(), 0))
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
        QromClaim QC = classifyQromReadUnderControl(LI2, Taint, DT, LInfo,
                                                    &Count, &R.InRegion);
        if (QC == QromClaim::No)
          return leave("E4-load", &I);
        if (QC == QromClaim::NeedsMask)
          R.MaskLoads.push_back({LI2, Count});
        continue;
      }
      if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        if (GEP->hasOneUse())
          if (auto *LU = dyn_cast<LoadInst>(GEP->user_back()))
            if (LU->getPointerOperand() == GEP &&
                classifyQromReadUnderControl(LU, Taint, DT, LInfo,
                                             /*OutCount=*/nullptr,
                                             &R.InRegion) != QromClaim::No)
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
        if (TaintedArg && isTemplateWidthType(CI->getType()) &&
            isSpeculatablePureCalleeBody(CI->getCalledFunction()))
          continue;
        return leave("E4-dataflow", &I);
      }
      if (!isSpeculatableDataflow(I))
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

  // bd adia (Lever C): strip poison-generating flags AND metadata over the
  // full backward cone of a select-form's SHIELDED operand. The rewrite below
  // turns `select(a,b,false)` into `and(a,b)`: in the ORIGINAL program `b` is
  // never observed when `a` is false (the clang short-circuit shield), so a
  // poison `b` on an a=false basis state was harmless there but would poison
  // the rewritten `and`. The claim-time proof `coneDefinedAfterFlagDrop`
  // already restricted the cone to ops that are TOTAL once flags are gone
  // (inherent-poison ops — variable-amount shifts, fp->int casts — never
  // reach here); this strip performs the drop, so the cone is then defined
  // on every basis state. Flag/metadata-stripping only widens definedness,
  // so every other user of a cone value is unaffected.
  void stripPoisonCone(Value *V) {
    SmallPtrSet<Instruction *, 16> Seen;
    SmallVector<Instruction *, 16> WL;
    if (auto *I = dyn_cast<Instruction>(V)) {
      Seen.insert(I);
      WL.push_back(I);
    }
    while (!WL.empty()) {
      Instruction *I = WL.pop_back_val();
      I->dropPoisonGeneratingFlags();
      I->dropPoisonGeneratingMetadata();
      for (Value *Op : I->operands())
        if (auto *OI = dyn_cast<Instruction>(Op))
          if (Seen.insert(OI).second)
            WL.push_back(OI);
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
      if (BoolAlg)
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
      IRBuilder<> Builder(T);
      Builder.SetCurrentDebugLocation(T->getDebugLoc());
      RegionFlattener(R, Builder).run();
      // bd adia (3c6m.55 Lever C): collapse fold residues the flatten materialized
      // (a select chain over constant incomings folds to a constant, leaving
      // a constant-operand compare feeding a "classical" branch that would
      // wedge the next claim's E6 walk). Taint-safe: only all-constant
      // instructions fold; the caller re-derives taint before the next claim.
      foldConstantConesInFunction(F);
      return true;  // one region per call; caller re-propagates
    }
  }
  return false;
}

}  // namespace cq
