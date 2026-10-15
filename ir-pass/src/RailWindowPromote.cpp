// RailWindowPromote.cpp — bd `test_C_libtooling-01po.19` S3: window regions,
// the per-window cell promotion, and the pending-step needs analysis (with the
// decline strings). Contract in RailWindow.h.

#include "RailWindow.h"

#include "TaintPropagation.h"

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"

#include <cstdlib>
#include <string>
#include <map>
#include <utility>

using namespace llvm;

namespace cq {

bool railWindowDistinct(ScalarEvolution &SE, const SCEV *A, const SCEV *B) {
  return SE.isKnownNonZero(SE.getMinusSCEV(A, B));
}

DenseMap<BasicBlock *, BasicBlock *> computeWindowRegions(Function &F,
                                                           LoopInfo &LI) {
  DenseMap<BasicBlock *, BasicBlock *> R;
  ReversePostOrderTraversal<Function *> RPOT(&F);
  for (BasicBlock *BB : RPOT) {
    Loop *L = LI.getLoopFor(BB);
    bool Entry = BB == &F.getEntryBlock() || (L && L->getHeader() == BB);
    BasicBlock *Reg = nullptr;
    if (!Entry)
      for (BasicBlock *P : predecessors(BB)) {
        auto It = R.find(P);
        // A predecessor in another loop body (a sub-loop exit, an outer
        // body), or not yet visited (an irreducible edge), starts a region.
        if (LI.getLoopFor(P) != L || It == R.end()) {
          Entry = true;
          break;
        }
        if (!Reg)
          Reg = It->second;
        else if (Reg != It->second) {
          Entry = true;  // a join of two regions starts its own.
          break;
        }
      }
    R[BB] = Entry ? BB : Reg;
  }
  return R;
}

namespace {

struct CellClass {
  BasicBlock *Entry = nullptr;
  SmallVector<LoadInst *, 4> Loads;
  SmallVector<StoreInst *, 4> Stores;
};

// Does `S` reach `L` inside region `E` (no back edge to the entry)?
bool storeReachesLoad(StoreInst *S, LoadInst *L, BasicBlock *E,
                      const DenseMap<BasicBlock *, BasicBlock *> &R) {
  if (S->getParent() == L->getParent())
    return S->comesBefore(L);
  SmallVector<BasicBlock *, 8> Work(succ_begin(S->getParent()),
                                    succ_end(S->getParent()));
  SmallPtrSet<BasicBlock *, 16> Seen;
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    if (B == E || R.lookup(B) != E || !Seen.insert(B).second)
      continue;
    if (B == L->getParent())
      return true;
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

bool needsPromotion(const CellClass &C,
                    const DenseMap<BasicBlock *, BasicBlock *> &R) {
  // Two loads, or (S4) two stores: one SSA name per cell per window, and ONE
  // write-back per written class at each window exit.
  if (C.Loads.size() >= 2 || C.Stores.size() >= 2)
    return true;
  for (StoreInst *S : C.Stores)
    for (LoadInst *L : C.Loads)
      if (storeReachesLoad(S, L, C.Entry, R))
        return true;
  return false;
}

}  // namespace

namespace {

// Mirrored CHARACTER-FOR-CHARACTER by the negative fixtures (Rule 12):
//   * railwindow_* / railbank_* window declines → kMsgWindowPending + needs
constexpr char kMsgWindowPending[] =
    "cq rail window: quantum array not lowered yet (bd 01po.19), needs";
constexpr char kNeedS5[] = "S5 in-place cell update";
constexpr char kNeedS6[] = "S6 quantum control on cells";
constexpr char kNeedS7[] = "S7 index alias versioning";

// Does `V` (a value stored into the cell at `S`) peel, through storage casts,
// phis and in-place `cq_theta` gates, back to a load of that same cell?
bool selfValue(Value *V, const SCEV *S, ScalarEvolution &SE,
               const RailWindowAccesses &Acc, SmallPtrSetImpl<Value *> &Seen) {
  if (!Seen.insert(V).second)
    return true;
  if (auto *C = dyn_cast<CastInst>(V))
    return selfValue(C->getOperand(0), S, SE, Acc, Seen);
  if (auto *L = dyn_cast<LoadInst>(V))
    return is_contained(Acc.Loads, L) &&
           SE.getSCEV(L->getPointerOperand()) == S;
  if (auto *P = dyn_cast<PHINode>(V)) {
    for (Value *In : P->incoming_values())
      if (!selfValue(In, S, SE, Acc, Seen))
        return false;
    return true;
  }
  if (auto *CI = dyn_cast<CallInst>(V))
    if (Function *Fn = CI->getCalledFunction())
      if (Fn->getName().starts_with("cq_theta_"))
        return selfValue(CI->getArgOperand(0), S, SE, Acc, Seen);
  // S5: an update with exactly one operand this cell's chain (`sub`: the
  // minuend only; `x ^= x` is none), `railWindowInPlaceUpdate`.
  Value *X, *Y;
  if (bool Sub; railWindowInPlaceUpdate(V, X, Y, Sub)) {
    SmallPtrSet<Value *, 8> SX(Seen.begin(), Seen.end()), SY(SX);
    bool TX = selfValue(X, S, SE, Acc, SX), TY = selfValue(Y, S, SE, Acc, SY);
    return Sub ? TX && !TY : TX != TY;
  }
  return false;
}

}  // namespace

std::string railWindowNeeds(Function &F, const RailWindowAccesses &Acc,
                            const TaintSet &taint, LoopInfo &LI,
                            ScalarEvolution &SE) {
  // Values quantum through the array or through taint.
  SmallPtrSet<Value *, 32> QD;
  railWindowQuantum(F, Acc, taint, QD);
  bool S5 = false, S6 = false, S7 = false;
  for (Instruction &I : instructions(F)) {
    Value *C = nullptr;
    if (auto *B = dyn_cast<BranchInst>(&I); B && B->isConditional())
      C = B->getCondition();
    else if (auto *Sw = dyn_cast<SwitchInst>(&I))
      C = Sw->getCondition();
    else if (auto *Se = dyn_cast<SelectInst>(&I))
      C = Se->getCondition();
    if (C && QD.count(C))
      S6 = true;
  }
  for (StoreInst *St : Acc.Stores) {
    if (!QD.count(St->getValueOperand()))
      continue;
    SmallPtrSet<Value *, 8> Seen;
    const SCEV *S = SE.getSCEV(St->getPointerOperand());
    // A fresh mint (a `cq_theta` of a classical seed) is a REBIND, not an
    // update: S2/S4 own it. Anything reading a cell that is not this cell's
    // own in-place chain is an update or a copy: S5.
    bool ReadsCell = false, Sub = false;
    SmallVector<Value *, 8> W{St->getValueOperand()};
    SmallPtrSet<Value *, 16> Vis;
    while (!W.empty()) {
      Value *V = W.pop_back_val();
      if (!Vis.insert(V).second)
        continue;
      if (auto *L = dyn_cast<LoadInst>(V); L && is_contained(Acc.Loads, L))
        ReadsCell = true;
      // THIS cell updated by a classical operand (`q[i] += 3`) is no S5
      // update (it would rebind beside its live old rail): still pending.
      SmallPtrSet<Value *, 8> SS;
      if (Value *X, *Y; railWindowInPlaceUpdate(V, X, Y, Sub) &&
                        QD.count(X) != QD.count(Y) &&
                        selfValue(QD.count(X) ? X : Y, S, SE, Acc, SS))
        S5 = true;
      if (auto *I = dyn_cast<Instruction>(V))
        for (Value *Op : I->operands())
          if (QD.count(Op))
            W.push_back(Op);
    }
    if (ReadsCell && !selfValue(St->getValueOperand(), S, SE, Acc, Seen))
      S5 = true;
  }
  DenseMap<BasicBlock *, BasicBlock *> R = computeWindowRegions(F, LI);
  DenseMap<BasicBlock *, SmallVector<const SCEV *, 4>> PerRegion;
  auto Add = [&](Instruction *I) {
    BasicBlock *E = R.lookup(I->getParent());
    if (!E)
      return;
    const SCEV *S = SE.getSCEV(getLoadStorePointerOperand(I));
    if (!is_contained(PerRegion[E], S))
      PerRegion[E].push_back(S);
  };
  for (LoadInst *L : Acc.Loads)
    Add(L);
  for (StoreInst *St : Acc.Stores)
    Add(St);
  for (auto &[E, Ss] : PerRegion)
    for (unsigned a = 0; a < Ss.size(); ++a)
      for (unsigned b = a + 1; b < Ss.size(); ++b)
        if (!railWindowDistinct(SE, Ss[a], Ss[b])) {
          S7 = true;
          if (std::getenv("CQ_RAILWINDOW_DBG"))
            errs() << "CQ_RAILWINDOW_DBG: alias unproven: " << *Ss[a]
                   << " vs " << *Ss[b] << "\n";
        }
  // S4 (borrowed-root cells) is built: an array with nothing else pending
  // gets the empty string and is lowered.
  std::string Out;
  for (auto [Need, Text] : {std::pair{S5, kNeedS5}, std::pair{S6, kNeedS6},
                            std::pair{S7, kNeedS7}})
    if (Need)
      Out += (Out.empty() ? std::string(kMsgWindowPending) + " "
                          : std::string(", ")) +
             Text;
  return Out;
}

// Review C-F1 (ruling Q2): mirrored CHARACTER-FOR-CHARACTER by
// railwindow_reject_cell_copy_other_array.ll. RETIRES when the copy-on-read
// lowering (bd 01po.19.2) lands.
std::string railWindowCopyNeeds() {
  return std::string(kMsgWindowPending) +
         " cell copy into another array (bd 01po.19.2 copy-on-read)";
}

std::string railWindowAllNeeds() {
  return std::string(kMsgWindowPending) + " " + kNeedS5 + ", " + kNeedS6 +
         ", " + kNeedS7;
}

unsigned promoteRailWindows(Function &F, RailWindowAccesses &Acc) {
  DominatorTree DT(F);
  LoopInfo LI(DT);
  AssumptionCache AC(F);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  DenseMap<BasicBlock *, BasicBlock *> R = computeWindowRegions(F, LI);

  // A lifetime marker or whole-object initializer inside a region pins that
  // region's memory order: leave the region alone.
  SmallPtrSet<BasicBlock *, 4> Pinned;
  for (Instruction *O : Acc.Others)
    if (BasicBlock *E = R.lookup(O->getParent()))
      Pinned.insert(E);

  // Classes keyed by (region entry, address SCEV), in program order.
  std::map<std::pair<BasicBlock *, const SCEV *>, CellClass> Classes;
  SmallVector<std::pair<BasicBlock *, const SCEV *>, 16> Order;
  auto Key = [&](Instruction *I, Value *Ptr) {
    BasicBlock *E = R.lookup(I->getParent());
    auto K = std::make_pair(E, SE.getSCEV(Ptr));
    if (!Classes.count(K))
      Order.push_back(K);
    Classes[K].Entry = E;
    return K;
  };
  // Walk the function in INSTRUCTION order (never use-list order, which is not
  // program order and differs between equivalent modules): class order, and
  // so every emitted name, is a function of the program alone.
  SmallPtrSet<Instruction *, 32> IsAcc;
  IsAcc.insert(Acc.Loads.begin(), Acc.Loads.end());
  IsAcc.insert(Acc.Stores.begin(), Acc.Stores.end());
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      if (!IsAcc.count(&I) || !R.lookup(&BB))
        continue;
      if (auto *L = dyn_cast<LoadInst>(&I))
        Classes[Key(L, L->getPointerOperand())].Loads.push_back(L);
      else if (auto *S = dyn_cast<StoreInst>(&I))
        Classes[Key(S, S->getPointerOperand())].Stores.push_back(S);
    }

  // F1 (review round 1): promotion forwards a cell across every other access
  // of its region, which is memory-preserving only if no other address in the
  // region can be the same cell. A region holding a pair SCEV cannot prove
  // distinct is NOT promoted (its memory order stays as written); S7's
  // versioning is what will split it.
  for (auto &K1 : Order)
    for (auto &K2 : Order)
      if (K1.first == K2.first && K1.second != K2.second &&
          !Pinned.count(K1.first) &&
          !railWindowDistinct(SE, K1.second, K2.second)) {
        Pinned.insert(K1.first);
        if (std::getenv("CQ_RAILWINDOW_DBG")) {
          errs() << "CQ_RAILWINDOW_DBG: region ";
          K1.first->printAsOperand(errs(), false);
          errs() << " not promoted: alias unproven\n";
        }
      }
  SmallVector<AllocaInst *, 8> Temps;
  for (auto &K : Order) {
    CellClass &C = Classes[K];
    if (Pinned.count(C.Entry) || !needsPromotion(C, R))
      continue;
    // One address that dominates every access of the class.
    Value *Addr = nullptr;
    SmallVector<Instruction *, 8> Uses(C.Loads.begin(), C.Loads.end());
    Uses.append(C.Stores.begin(), C.Stores.end());
    for (Instruction *U : Uses) {
      Value *P = getLoadStorePointerOperand(U);
      auto *PI = dyn_cast<Instruction>(P);
      bool Ok = true;
      if (PI)
        for (Instruction *V : Uses)
          Ok = Ok && DT.dominates(PI, V);
      if (Ok) {
        Addr = P;
        break;
      }
    }
    if (!Addr)
      continue;
    // The class's window is the part of the region its address dominates
    // (`Sub`): every access lies in it. Its exiting blocks — a successor outside
    // it, or the back edge to the region entry — get the write-back. Blocks are
    // walked in FUNCTION order so the emitted IR is deterministic.
    auto *AddrI = dyn_cast<Instruction>(Addr);
    BasicBlock *Sub = AddrI && R.lookup(AddrI->getParent()) == C.Entry
                          ? AddrI->getParent()
                          : C.Entry;
    SmallVector<BasicBlock *, 4> Exiting;
    for (BasicBlock &BB : F) {
      if (R.lookup(&BB) != C.Entry || !DT.dominates(Sub, &BB))
        continue;
      for (BasicBlock *S : successors(&BB))
        if (S == C.Entry || R.lookup(S) != C.Entry || !DT.dominates(Sub, S)) {
          Exiting.push_back(&BB);
          break;
        }
    }
    IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt());
    AllocaInst *T = EB.CreateAlloca(Acc.CellTy, nullptr, "cq.win");
    Instruction *At = nullptr;
    if (AddrI && R.lookup(AddrI->getParent()) == C.Entry)
      At = isa<PHINode>(AddrI) ? &*AddrI->getParent()->getFirstInsertionPt()
                               : AddrI->getNextNode();
    else
      At = &*C.Entry->getFirstInsertionPt();
    IRBuilder<> B(At);
    LoadInst *Seed = B.CreateLoad(Acc.CellTy, Addr, "cq.win.in");
    B.CreateStore(Seed, T);
    for (LoadInst *L : C.Loads)
      L->setOperand(0, T);
    for (StoreInst *S : C.Stores)
      S->setOperand(1, T);
    if (!C.Stores.empty())
      for (BasicBlock *X : Exiting) {
        IRBuilder<> XB(X->getTerminator());
        XB.CreateStore(XB.CreateLoad(Acc.CellTy, T, "cq.win.out"), Addr);
      }
    Temps.push_back(T);
    if (std::getenv("CQ_RAILWINDOW_DBG")) {
      errs() << "CQ_RAILWINDOW_DBG: promote cell " << *K.second << " in region ";
      C.Entry->printAsOperand(errs(), false);
      errs() << " loads=" << C.Loads.size() << " stores=" << C.Stores.size()
             << " exits=" << Exiting.size() << "\n";
    }
  }
  if (!Temps.empty())
    PromoteMemToReg(Temps, DT);
  return Temps.size();
}

}  // namespace cq
