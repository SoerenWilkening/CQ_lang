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

#include "IntrinsicLowering.h"
#include "OpcodeSupport.h"  // abiWidthFromType, binaryStem, castInScope, i80BinaryInScope
#include "QramLowering.h"
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SCCIterator.h"
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
    // is required so nothing observable moves.
    return isCuratedReversibleIntrinsic(Call) && Call->doesNotAccessMemory();
  return false;
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
                   const TaintSet &Taint, PredMuxRegion &R) {
  BasicBlock *E = T->getParent();
  auto *Node = PDT.getNode(E);
  if (!Node || !Node->getIDom() || !Node->getIDom()->getBlock())
    return false;
  BasicBlock *Mg = Node->getIDom()->getBlock();

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
  if (!Claim)
    return false;

  // --- E2: acyclic, not in/around a loop ------------------------------------
  for (BasicBlock *B : R.InRegion)
    if (OnCycle.count(B))
      return false;

  // --- E3: single-entry / single-exit ---------------------------------------
  for (BasicBlock *B : R.InRegion) {
    const Instruction *Term = B->getTerminator();
    if (!isa<BranchInst>(Term) && !isa<SwitchInst>(Term))
      return false;  // ret/unreachable/invoke/… inside: multi-exit
    for (const BasicBlock *S : successors(B))
      if (S != Mg && !R.InRegion.count(S))
        return false;  // escapes the region without reconverging
    if (B == E)
      continue;
    for (const BasicBlock *P : predecessors(B))
      if (!R.InRegion.count(P))
        return false;  // side entry
  }
  for (const BasicBlock *P : predecessors(Mg))
    if (!R.InRegion.count(P))
      return false;  // a reaching edge PredMux does not predicate

  // --- E4 + E6 + E7 over the region body ------------------------------------
  for (BasicBlock *B : R.InRegion) {
    // E6: every conditional terminator tainted, with an invertible condition.
    const Instruction *Term = B->getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(Term)) {
      if (BI->isConditional()) {
        if (!Taint.Tainted.count(BI->getCondition()))
          return false;  // classical control inside a tainted region: mixed
        if (!isSupportedCondTree(BI->getCondition(), 0))
          return false;
      }
    } else if (const auto *SI = dyn_cast<SwitchInst>(Term)) {
      if (!Taint.Tainted.count(SI->getCondition()))
        return false;
      Type *ScrTy = SI->getCondition()->getType();
      if (!isMuxableType(ScrTy))
        return false;  // eq/ne flags must be mintable at this width
    }
    if (B == E)
      continue;  // E's own instructions are not moved
    for (Instruction &I : *B) {
      if (isa<PHINode>(I)) {
        if (!isMuxableType(I.getType()))
          return false;  // E7
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
          return false;
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
        return false;
      }
      if (!isSpeculatableDataflow(I))
        return false;  // E4
    }
  }
  // E7 for the merge phis (they all convert: preds(Mg) ⊆ region).
  for (const PHINode &P : Mg->phis())
    if (!isMuxableType(P.getType()))
      return false;

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
      L = Idx == 0 ? BI->getCondition() : buildNegation(BI->getCondition());
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

  // ¬V with the negation pushed to the leaves (PRD §4.3, the no-NOT
  // invariant). Shapes are pre-checked by isSupportedCondTree.
  Value *buildNegation(Value *V) {
    if (auto *C = dyn_cast<ConstantInt>(V))
      return C->isZero() ? ConstantInt::getTrue(C->getContext())
                         : ConstantInt::getFalse(C->getContext());
    if (auto *Cmp = dyn_cast<CmpInst>(V))
      return track(B.CreateCmp(Cmp->getInversePredicate(), Cmp->getOperand(0),
                               Cmp->getOperand(1)));
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

bool flattenPredMuxRegions(Module &M, TaintSet &Taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool HasTaintedCtrl = false;
    for (BasicBlock &BB : F)
      if (isTaintedCtrlTerm(BB.getTerminator(), Taint))
        HasTaintedCtrl = true;
    if (!HasTaintedCtrl)
      continue;

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
      if (!recoverRegion(T, PDT, DT, LInfo, OnCycle, Taint, R))
        continue;  // leave: today's loud declines own it
      IRBuilder<> Builder(T);
      Builder.SetCurrentDebugLocation(T->getDebugLoc());
      RegionFlattener(R, Builder).run();
      return true;  // one region per call; caller re-propagates
    }
  }
  return false;
}

}  // namespace cq
