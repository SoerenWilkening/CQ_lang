// GuardedClassicalRead.cpp — see the header for the shape, the two obligations
// and the residual. bd xdu2.8.

#include "GuardedClassicalRead.h"

#include "QramLowering.h"      // runtimeAllocaReadShape, unitCounterTrips, valueWillTaintAfterFlatten
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;
using namespace llvm::PatternMatch;

namespace cq {

namespace {

// One classical fact about the arm: `Cmp` evaluates to `Holds` on every
// execution of the load's block.
struct ArmFact {
  ICmpInst *Cmp;
  bool Holds;
};

// Split a branch condition known to evaluate to `Want` into the compare facts it
// implies. Only the implications that are EXACT are taken: a true `and` (or
// `select a, b, false`) makes both operands true; a false `or` (or
// `select a, true, b`) makes both false; `not` flips. Anything else — an `xor`
// of two compares, a phi, a call — contributes nothing, which can only lose an
// accept, never make one.
void collectFacts(Value *V, bool Want, unsigned Depth,
                  SmallVectorImpl<ArmFact> &Out) {
  if (Depth > 8)
    return;
  Value *A = nullptr, *B = nullptr;
  if (Want && match(V, m_LogicalAnd(m_Value(A), m_Value(B)))) {
    collectFacts(A, Want, Depth + 1, Out);
    collectFacts(B, Want, Depth + 1, Out);
    return;
  }
  if (!Want && match(V, m_LogicalOr(m_Value(A), m_Value(B)))) {
    collectFacts(A, Want, Depth + 1, Out);
    collectFacts(B, Want, Depth + 1, Out);
    return;
  }
  if (match(V, m_Not(m_Value(A)))) {
    collectFacts(A, !Want, Depth + 1, Out);
    return;
  }
  if (auto *C = dyn_cast<ICmpInst>(V))
    Out.push_back({C, Want});
}

// Do `G1`/`G2` equal `C(F1)`/`C(F2)` for ONE cast chain `C` applied to both?
// `Monotone` restricts `C` to zero-extensions. That is a CONSERVATIVE choice, not
// the exact set: sext preserves unsigned order too (Rule-13 round-1 P3-7; an
// earlier draft said zext was "the only" such cast) — only trunc does not.
// Without `Monotone` sext/trunc are admitted, which preserve EQUALITY (a function
// maps equal inputs to equal outputs). ⚠ RETIREMENT TRIGGER (round 1 P3-6): trunc
// is shadowed today only because E6's leaf grammar refuses the i128 order facts
// it would need; if E6 admits them, the `Monotone` fence becomes live.
bool sameCastChain(const SCEV *G1, const SCEV *G2, const SCEV *F1,
                   const SCEV *F2, bool Monotone, unsigned Depth = 0) {
  if (G1 == F1 && G2 == F2)
    return true;
  if (Depth == 4 || G1->getType() != G2->getType())
    return false;
  auto peel = [&](const auto *C1, const auto *C2) {
    return C1 && C2 &&
           C1->getOperand()->getType() == C2->getOperand()->getType() &&
           sameCastChain(C1->getOperand(), C2->getOperand(), F1, F2, Monotone,
                         Depth + 1);
  };
  if (peel(dyn_cast<SCEVZeroExtendExpr>(G1), dyn_cast<SCEVZeroExtendExpr>(G2)))
    return true;
  if (Monotone)
    return false;
  return peel(dyn_cast<SCEVSignExtendExpr>(G1),
              dyn_cast<SCEVSignExtendExpr>(G2)) ||
         peel(dyn_cast<SCEVTruncateExpr>(G1), dyn_cast<SCEVTruncateExpr>(G2));
}

bool knownNonNegativeAt(const SCEV *S, ScalarEvolution &SE,
                        const Instruction *Ctx) {
  return SE.isKnownNonNegative(S) ||
         SE.isKnownPredicateAt(ICmpInst::ICMP_SGE, S, SE.getZero(S->getType()),
                               Ctx);
}

// Does fact `F` alone put the read in bounds on every execution where it holds?
//   * `Trips` (may be null): the exact trip count of the unit counter the read
//     is indexed by, so the index is in [0, Trips) on every execution.
//   * `IdxS` / `ExtentS`: the index and the allocation's extent.
bool factBoundsRead(const ArmFact &F, const SCEV *Trips, const SCEV *IdxS,
                    const SCEV *ExtentS, ScalarEvolution &SE,
                    const Instruction *Ctx) {
  ICmpInst::Predicate P =
      F.Holds ? F.Cmp->getPredicate() : F.Cmp->getInversePredicate();
  const SCEV *SX = SE.getSCEV(F.Cmp->getOperand(0));
  const SCEV *SY = SE.getSCEV(F.Cmp->getOperand(1));
  if (P == ICmpInst::ICMP_EQ)
    // trips == extent, through any common cast chain.
    return Trips && Trips->getType() == ExtentS->getType() &&
           (sameCastChain(Trips, ExtentS, SX, SY, /*Monotone=*/false) ||
            sameCastChain(Trips, ExtentS, SY, SX, /*Monotone=*/false));
  // Canonicalise an ORDER fact to `Lo (<|<=) Hi`.
  if (ICmpInst::isGT(P) || ICmpInst::isGE(P)) {
    std::swap(SX, SY);
    P = ICmpInst::getSwappedPredicate(P);
  }
  if (!ICmpInst::isLT(P) && !ICmpInst::isLE(P))
    return false;  // ne, or anything else: bounds nothing.
  const bool Strict = ICmpInst::isLT(P);
  const bool Signed = ICmpInst::isSigned(P);
  const SCEV *Lo = SX, *Hi = SY;
  // A signed order is an unsigned one once the smaller side is non-negative.
  if (Signed && !knownNonNegativeAt(Lo, SE, Ctx))
    return false;
  // (T) trips <= extent: every index in [0, trips) is in [0, extent).
  if (Trips && Trips->getType() == ExtentS->getType() &&
      sameCastChain(Trips, ExtentS, Lo, Hi, /*Monotone=*/true))
    return true;
  // (I) index < extent, directly.
  return Strict && IdxS->getType() == ExtentS->getType() &&
         sameCastChain(IdxS, ExtentS, Lo, Hi, /*Monotone=*/true);
}

// ONE FRESH ZERO CELL PER GUARDED READ, NEVER A REUSED ONE (Rule-13 round 3).
// Two earlier spellings each trusted something the MODULE supplies: round 2's
// P3 found reuse keyed on the NAME prefix (a user's global reused, its alignment
// raised); round 3 found reuse keyed on a `!cq.guarded.read.zero` METADATA
// marker, which a module can forge on an `extern_weak`, a mutable, a
// `thread_local` or a written global — measured, an extern_weak forgery compiled
// and the out-of-bounds run SEGFAULTED where the oracle declined. The cure is to
// trust nothing: the cell is created here, by construction a `private constant`
// zero in address space 0 at exactly the load's alignment, and nothing in the
// pass ever LOOKS UP a cell. A module global of the same name, or carrying any
// metadata, is inert — LLVM uniques the new name — so a forged marker needs no
// reserved-name decline (the xdu2.4 forged-seed decline exists because that
// marker was READ; this one is never read). The cost is one small constant per
// guarded read.
GlobalVariable *zeroCellFor(Module &M, Type *T, Align A) {
  // ADDRESS SPACE 0, EXPLICITLY (Rule-13 round 2 sweep): the constructor's
  // default is the DataLayout's globals address space (`-G<n>`), and a zero cell
  // outside the load's address space makes the address `select` ill-typed — an
  // abort ("Invalid operands for select instruction!"). Admission refuses any
  // load whose pointer is not in address space 0, so 0 is the load's space.
  auto *G = new GlobalVariable(M, T, /*isConstant=*/true,
                               GlobalValue::PrivateLinkage,
                               Constant::getNullValue(T),
                               "cq.guarded.read.zero",
                               /*InsertBefore=*/nullptr,
                               GlobalValue::NotThreadLocal,
                               /*AddressSpace=*/0u);
  G->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  G->setAlignment(A);
  return G;
}

}  // namespace

bool classicalRuntimeAllocaReadIsInBoundsUnderGuard(
    LoadInst *LI, const TaintSet &Taint, DominatorTree &DT, LoopInfo &LInfo,
    ScalarEvolution &SE, const SmallPtrSetImpl<BasicBlock *> &Region,
    BasicBlock *Entry, Value **OutExtent) {
  if (!LI || !Entry || !Region.count(LI->getParent()) ||
      LI->getParent() == Entry)
    return false;
  // A zero off the arm must not violate anything the load's own metadata
  // promises downstream analyses (E4's speculatability verdicts were taken
  // under it).
  for (unsigned K : {LLVMContext::MD_range, LLVMContext::MD_nonnull,
                     LLVMContext::MD_align, LLVMContext::MD_dereferenceable,
                     LLVMContext::MD_dereferenceable_or_null})
    if (LI->hasMetadata(K))
      return false;
  // EVERY PROPERTY THE EMISSION'S `select` AND ZERO CELL MUST AGREE WITH, asked
  // HERE so a mismatch declines instead of producing an ill-typed select (two
  // aborts in this code so far: Rule-13 round 1 P2-1, round 2 P2). Enumerated:
  //   * pointer ADDRESS SPACE — the zero cell lives in space 0 (below);
  //   * load TYPE — a scalar int/fp equal to the allocated cell type (shape half),
  //     so `Constant::getNullValue` is a defined zero of it; no vector/pointer;
  //   * volatile / atomic — refused by `isSimple` (shape half);
  //   * ALIGNMENT — the zero cell is created fresh at exactly the load's own;
  //   * INDEX / EXTENT widths — address-width index (shape half), extent no wider
  //     (below), so `zext(freeze extent)` to the index type is well-formed.
  if (LI->getPointerAddressSpace() != 0)
    return false;
  std::optional<RuntimeAllocaRead> Shape =
      runtimeAllocaReadShape(LI, Taint, DT, Entry);
  if (!Shape)
    return false;
  // (B) rebuilds the address as `gep T, base, idx`, so only that exact form.
  auto *G = cast<GetElementPtrInst>(LI->getPointerOperand());
  if (G->getNumIndices() != 1 || G->getSourceElementType() != LI->getType() ||
      !Shape->Extent->getType()->isIntegerTy() ||
      Shape->Extent->getType()->getIntegerBitWidth() >
          Shape->RawIndex->getType()->getIntegerBitWidth())
    return false;
  const SCEV *ExtentS = SE.getSCEV(Shape->Extent);
  const SCEV *IdxS = SE.getSCEV(Shape->RawIndex);
  if (isa<SCEVCouldNotCompute>(ExtentS) || isa<SCEVCouldNotCompute>(IdxS))
    return false;
  const SCEV *Trips = unitCounterTrips(LI, Shape->RawIndex, LInfo, SE, Entry);
  const Instruction *Ctx = Entry->getTerminator();

  for (BasicBlock *D : Region) {
    auto *BI = dyn_cast<BranchInst>(D->getTerminator());
    if (!BI || !BI->isConditional() ||
        BI->getSuccessor(0) == BI->getSuccessor(1))
      continue;
    for (unsigned S = 0; S < 2; ++S) {
      // The taken edge must dominate the load: every path to the read crossed
      // it in THIS region activation (the region is acyclic), so the condition
      // had value `S == 0` there, and a compare it implies held.
      if (!DT.dominates(BasicBlockEdge(D, BI->getSuccessor(S)),
                        LI->getParent()))
        continue;
      SmallVector<ArmFact, 4> Facts;
      collectFacts(BI->getCondition(), S == 0, 0, Facts);
      for (const ArmFact &F : Facts) {
        // CLASSICAL, now and after the flatten: a quantum fact is not a
        // statement about every basis state.
        if (Taint.Tainted.count(F.Cmp) ||
            valueWillTaintAfterFlatten(F.Cmp, Taint, Region, Entry) ||
            !F.Cmp->getOperand(0)->getType()->isIntegerTy())
          continue;
        if (factBoundsRead(F, Trips, IdxS, ExtentS, SE, Ctx)) {
          *OutExtent = Shape->Extent;
          return true;
        }
      }
    }
  }
  return false;
}

Value *guardSpeculatedClassicalRead(LoadInst *LI, Value *Extent) {
  // Both conjuncts were proved at admission (the single-index form by (A)'s own
  // `getNumIndices() != 1` refusal, the extent by the shared shape half); this
  // is a consistency check on the record, not a second derivation.
  auto *G = dyn_cast<GetElementPtrInst>(LI->getPointerOperand());
  if (!G || G->getNumIndices() != 1 || !Extent)
    report_fatal_error("cq: guarded classical read lost its address shape");
  Value *Base = G->getPointerOperand();
  Value *Idx = G->getOperand(1);
  Type *T = LI->getType();
  IRBuilder<> B(LI);
  B.SetCurrentDebugLocation(LI->getDebugLoc());
  Value *FIdx = B.CreateFreeze(Idx, "cq.gr.idx");
  Value *FExt = B.CreateFreeze(Extent, "cq.gr.ext");
  FExt = B.CreateZExt(FExt, FIdx->getType());
  Value *InBounds = B.CreateICmpULT(FIdx, FExt, "cq.gr.inb");
  Value *Cell = B.CreateGEP(T, Base, FIdx, "cq.gr.cell");
  GlobalVariable *Zero = zeroCellFor(*LI->getModule(), T, LI->getAlign());
  Value *Addr = B.CreateSelect(InBounds, Cell, Zero, "cq.gr.addr");
  LI->setOperand(LI->getPointerOperandIndex(), Addr);
  return G;
}

}  // namespace cq
