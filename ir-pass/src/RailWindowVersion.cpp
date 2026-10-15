// RailWindowVersion.cpp — bd `test_C_libtooling-01po.19` S7: INDEX ALIAS
// VERSIONING (owner ruling `owner-ruling-01po19-rolled-design-2026-10-15` Q2
// (a): prove, else version; design §7.1, addendum note 4). Contract in
// RailWindow.h.
//
// THE QUESTION. Inside one window S3 forwards each cell class as one SSA name,
// which is memory-preserving only if two classes are never the same cell
// (`railWindowPairProven`). With runtime indices `q[i] ^= q[j]` SCEV cannot
// prove `&q[i] != &q[j]`, and at `i == j` the source means `x ^= x`: the cell
// becomes 0 and its old value is discarded.
//
// THE ANSWER: VERSION THE WINDOW on the classical test `&q[i] != &q[j]`.
//   * the DISTINCT copy is the original code; every access of the pair is
//     dominated by the `!=` edge, so `railWindowDistinct` (context form) proves
//     the pair there and S3 promotes it as two names;
//   * the ALIASED copy names both classes through ONE address, so S3 promotes
//     one name and `x ^= x` reads `v ^ v`, which InstSimplify folds to the
//     classical 0: the store is a REBIND (S4's `cqrt_alloc_<W>(0)`, Q3), the
//     old rail left allocated, never reset or measured (R5). POSTCONDITION
//     (coordinator, 2026-10-15): after the fold no quantum op of an aliased
//     copy may still read the merged cell through two operands (`x + x` at
//     i == j: an out-of-place value over one rail, r2j3.33's never-allowed
//     form); one that does is loud (`mergedResidue`).
//   Both copies are classical control on classical indices: nothing quantum
//   decides which copy runs.
//
// EACH COPY IS A WINDOW OF ITS OWN (the guard carries `!cq.railwindow.version`;
// `computeWindowRegions` starts a region at its successors, and the join is a
// region by the existing rule). Measured on the first build: with the copies
// left inside one window, a promoted class's seed sat above the guard and its
// write-back past the join, where `i != j` is unknown — the write-back of the
// other class's stale temp could clobber the merged cell (caught only by the
// S7 needs postcondition). Per-copy windows keep every seed and write-back
// where the guard holds, and a later pair is versioned only inside the copy
// where it is still unproven, so the copies are exactly the consistent alias
// partitions (3 classes: Bell(3) = 5 copies). The aliased copy keeps a
// CONSTANT cell as the survivor when it has one (`q[i]` vs `q[0]` -> `q[0]`).
//
// LOUD, NEVER GUESSED:
//   * CONTROL == TARGET. A quantum condition reading one class of the pair that
//     controls a store to the other is, in the aliased copy, a gate controlled
//     by its own target (`if (q[i]) Ry(q[j])` at i == j: "rotate if set", not
//     unitary). Loud before any cloning (owner Q2 ruling: stays loud). A
//     MEASURED condition is classical and never refused.
//   * COPY COUNT. At most 8 copies of one ORIGINAL window, counted across all
//     its copies including nested ones (`Origin`), i.e. at most `kMaxVersions`
//     = 7 performed versionings (ruling `ruling-01po19-s7-version-bound-
//     2026-10-15`, amended: AGENT-CHOSEN number, owner-confirmed). 4 fully
//     unproven classes (Bell(4) = 15) are loud.
//   * an address of the pair not computable at the version point (the
//     version point drops below an early access of A when B's address is
//     computed later; a branch-arm B with A after the join is still loud).
//
// WHY NOT `LoopVersioning`. LLVM's loop versioning hoists a loop-INVARIANT
// runtime check to the preheader and selects a whole loop copy. Here the
// predicate changes per trip (`i` vs `2 - i` aliases only at i == 1), so the
// unit is the window (a region of one trip), cloned with Cloning.h's
// `CloneBasicBlock`/`remapInstructionsInBlocks`, rejoined with `SSAUpdater`,
// and the loop put back in simplify form with `simplifyLoop`
// (RailWindowVersionPair.cpp).
//
// R12 ground truth: BennettVM.jl 23d28e6 `MemoryAssignment`
// (src/ir/memory_instructions.jl:84, "Aliasing edge case (forbidden by
// use-discipline)") does not detect address aliasing; Bennett.jl 824458d1
// `lower_add_cuccaro!` (src/adder.jl:79,:103) refuses aliased operand
// registers outright. Neither versions; CQ must, because a runtime index is a
// valid program.

#include "RailWindow.h"
#include "RailWindowAlias.h"

#include "TaintPropagation.h"

#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/Local.h"

#include <cstdlib>
#include <map>

using namespace llvm;

namespace cq {

namespace {

bool dbg() { return std::getenv("CQ_RAILWINDOW_DBG") != nullptr; }

// Agent-chosen, owner-confirmed (ruling-01po19-s7-version-bound-2026-10-15,
// amended): 7 performed versionings = at most 8 copies of one original window.
constexpr unsigned kMaxVersions = 7;
// Mirrored CHARACTER-FOR-CHARACTER by railwindow_reject_version_blowup.ll.
constexpr char kMsgBlowup[] =
    "cq rail window: index alias versioning would copy one window more than "
    "8 times";
// Mirrored by railwindow_reject_alias_self_control.ll.
constexpr char kMsgSelfControl[] =
    "cq rail window: aliased cell indices make a quantum control its own "
    "target (a self-controlled gate is not unitary)";
// Mirrored by railwindow_reject_alias_update.ll.
constexpr char kMsgUpdate[] =
    "cq rail window: aliased cell update does not reduce to a classical "
    "rebind or an in-place chain";

bool diagnose(Function &F, const char *Msg, const Instruction *At) {
  F.getContext().diagnose(
      DiagnosticInfoUnsupported(F, Msg, At ? At->getDebugLoc() : DebugLoc()));
  return false;
}

// The rail `V` spells in place: back through storage casts and in-place
// `cq_theta` gates (a phi or any other op is its own root).
Value *inPlaceRoot(Value *V) {
  for (;;) {
    if (auto *C = dyn_cast<CastInst>(V)) {
      V = C->getOperand(0);
      continue;
    }
    auto *CI = dyn_cast<CallInst>(V);
    Function *Fn = CI ? CI->getCalledFunction() : nullptr;
    if (Fn && Fn->getName().starts_with("cq_theta_") && CI->arg_size() >= 1) {
      V = CI->getArgOperand(0);
      continue;
    }
    return V;
  }
}

// THE ALIAS RESIDUE: a quantum op (not the in-place vocabulary) two of whose
// operands spell the same quantum rail — what the merged class leaves when the
// fold could not make it classical. Returns `I`, or null.
Instruction *mergedResidue(Instruction *I, const SmallPtrSetImpl<Value *> &QD) {
  if (!QD.count(I) || isa<CastInst>(I) || isa<PHINode>(I) ||
      isa<LoadInst>(I) || inPlaceRoot(I) != I)
    return nullptr;
  SmallPtrSet<Value *, 4> Roots;
  for (Value *Op : I->operands())
    if (QD.count(Op) && !Roots.insert(inPlaceRoot(Op)).second)
      return I;
  return nullptr;
}

}  // namespace

namespace {

struct Analyses {
  DominatorTree DT;
  LoopInfo LI;
  AssumptionCache AC;
  TargetLibraryInfoImpl TLII;
  TargetLibraryInfo TLI;
  ScalarEvolution SE;
  explicit Analyses(Function &F)
      : DT(F), LI(DT), AC(F),
        TLII(Triple(F.getParent()->getTargetTriple())), TLI(TLII),
        SE(F, TLI, AC, DT, LI) {}
};

// R11 S7 A-F2: inside an aliased copy the two cells ARE one, so a user's own
// test of them (`if (i != j)`, `railWindowCompareIsCellEquality` against a
// dominating version guard's aliased edge) is a known classical constant.
// Fold it, fold the branch, and drop the dead arm before any later stage sees
// it (the arm could gate a rail the copy has measured or rebound).
void foldAliasedUserTests(Function &F, SmallPtrSetImpl<BasicBlock *> &Alias) {
  Analyses A(F);
  SmallVector<std::pair<BasicBlockEdge, const SCEV *>, 8> Aliased;
  for (BasicBlock &B : F)
    if (auto *Br = dyn_cast<BranchInst>(B.getTerminator());
        Br && Br->getMetadata("cq.railwindow.version"))
      if (auto *G = dyn_cast<ICmpInst>(Br->getCondition())) {
        const SCEV *AB = A.SE.getMinusSCEV(A.SE.getSCEV(G->getOperand(0)),
                                           A.SE.getSCEV(G->getOperand(1)));
        if (!isa<SCEVCouldNotCompute>(AB))
          Aliased.push_back({BasicBlockEdge(&B, Br->getSuccessor(1)), AB});
      }
  SmallVector<ICmpInst *, 8> Known;
  for (BasicBlock *BB : Alias)
    for (Instruction &I : *BB)
      if (auto *C = dyn_cast<ICmpInst>(&I);
          C && C->isEquality() && C->getType()->isIntegerTy(1))
        for (auto &[E, AB] : Aliased)
          if (A.DT.dominates(E, BB) &&
              railWindowCompareIsCellEquality(A.SE, C, AB)) {
            Known.push_back(C);
            break;
          }
  if (Known.empty())
    return;
  for (ICmpInst *C : Known) {
    C->replaceAllUsesWith(ConstantInt::getBool(
        C->getType(), C->getPredicate() == ICmpInst::ICMP_EQ));
    C->eraseFromParent();
  }
  for (BasicBlock *BB : Alias)
    ConstantFoldTerminator(BB, /*DeleteDeadConditions=*/true);
  SmallPtrSet<BasicBlock *, 32> Live;
  for (BasicBlock *BB : depth_first(&F.getEntryBlock()))
    Live.insert(BB);
  for (BasicBlock &BB : F)
    if (!Live.count(&BB))
      Alias.erase(&BB);
  removeUnreachableBlocks(F);
}

}  // namespace

bool railWindowVersionPromoteCheck(Function &F, AllocaInst *W,
                                   const TaintSet &taint, unsigned &Promoted,
                                   std::string &Msg, Instruction *&Stale,
                                   Instruction *&Copy,
                                   RailWindowAccesses &AccW) {
  // `railWindowCollectAccesses` failing on `W` is unreachable (the redirect
  // emits only its vocabulary); if it ever fires, claim every pending step.
  Msg = railWindowAllNeeds();
  Promoted = 0;
  Stale = nullptr;
  Copy = nullptr;
  SmallPtrSet<BasicBlock *, 16> Alias;
  // S7: version until every pair of every window region is proven.
  std::map<BasicBlock *, unsigned> Count;
  // Every block a versioning creates or copies belongs to the window it was
  // cut from: the copy count is per ORIGINAL window.
  DenseMap<BasicBlock *, BasicBlock *> Origin;
  for (;;) {
    Analyses A(F);
    if (!railWindowCollectAccesses(W, taint, A.SE, AccW))
      return true;
    RailWindowPair P;
    if (!railWindowUnprovenPair(F, AccW, A.DT, A.LI, A.SE, P))
      break;
    if (dbg()) {
      errs() << "CQ_RAILWINDOW_DBG: version region ";
      P.E->printAsOperand(errs(), false);
      errs() << " on " << *P.A << " != " << *P.B << "\n";
    }
    BasicBlock *O = Origin.lookup(P.E) ? Origin.lookup(P.E) : P.E;
    if (++Count[O] > kMaxVersions && dbg())
      F.print(errs());
    if (Count[O] > kMaxVersions)
      return diagnose(F, kMsgBlowup, P.AccB.front());  // the window's access
    // The aliased copy keeps class A's address for both: prefer a CONSTANT
    // cell as the survivor (`q[i]` vs `q[0]` at i == 0 is `q[0]`), so the
    // copy's remaining pairs are constant offsets SCEV proves outright.
    auto ConstCell = [&](const SCEV *S) {
      return isa<SCEVConstant>(A.SE.getMinusSCEV(S, A.SE.getPointerBase(S)));
    };
    if (!ConstCell(P.A) && ConstCell(P.B)) {
      std::swap(P.A, P.B);
      std::swap(P.AccA, P.AccB);
    }
    SmallPtrSet<Value *, 32> QD;
    railWindowQuantum(F, AccW, taint, QD);
    PostDominatorTree PDT(F);
    if (Instruction *S = railWindowSelfControl(F, AccW, QD, P, A.SE, A.DT, PDT))
      return diagnose(F, kMsgSelfControl, S);
    if (!railWindowVersionPair(F, W, P, Alias, Origin, O))
      return false;
  }
  // S6 (bd 01po.19): the quantum-branch arms' cell classes, promoted per
  // window AFTER versioning (a copy's classes are proven only inside it) and
  // after the self-control fence above has asked its question of the shape
  // the program wrote (`promoteRailWindowArms`, RailWindowArms.cpp).
  promoteRailWindowArms(F, W, taint);
  {
    Analyses A(F);
    if (!railWindowCollectAccesses(W, taint, A.SE, AccW))
      return true;
    Promoted = promoteRailWindows(F, AccW);
  }
  foldAliasedUserTests(F, Alias);
  // The aliased copies: one name per merged cell now; fold `v ^ v`,
  // `icmp ne v, v` and their casts to the classical constants they are.
  for (bool Again = true; Again;) {
    Again = false;
    const SimplifyQuery SQ(F.getParent()->getDataLayout());
    SmallVector<WeakVH, 32> Work;
    for (BasicBlock *B : Alias)
      for (Instruction &I : *B)
        Work.push_back(&I);
    for (WeakVH &VH : Work)
      if (auto *I = dyn_cast_or_null<Instruction>(VH); I && !I->use_empty())
        if (Value *V = simplifyInstruction(I, SQ)) {
          I->replaceAllUsesWith(V);
          // A dead tainted op would still be lowered (and never uncomputed,
          // r2j3.7's class): erase it and its dead operands.
          RecursivelyDeleteTriviallyDeadInstructions(I);
          Again = true;
        }
  }
  Analyses A(F);
  if (!railWindowCollectAccesses(W, taint, A.SE, AccW))
    return true;
  SmallPtrSet<Value *, 32> QD;
  railWindowQuantum(F, AccW, taint, QD);
  // POSTCONDITION: no quantum op of an aliased copy still reads the merged
  // cell twice (`x + x` where the fold needed `x ^ x`).
  for (BasicBlock *B : Alias)
    for (Instruction &I : *B)
      if (Instruction *R = mergedResidue(&I, QD))
        return diagnose(F, kMsgUpdate, R);
  Msg = railWindowNeeds(F, AccW, taint, A.LI, A.SE);
  if (Msg.empty()) {
    Copy = railWindowCellCopy(F, AccW);
    Stale = railWindowStaleUse(F, AccW, QD, A.SE,
                               computeWindowRegions(F, A.LI));
  }
  return true;
}

}  // namespace cq
