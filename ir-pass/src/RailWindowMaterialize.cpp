// RailWindowMaterialize.cpp — bd `test_C_libtooling-01po.19` S4, the
// value-domain half: the handle array, the access redirect and the
// materialization walk at Q (the post-Q initializers, addendum notes 1–2, are
// RailWindowInit.cpp). Contract
// in RailWindow.h. Ground truth (R12): BennettVM.jl 23d28e6 `StackAlloca`
// (src/ir/stack_alloca.jl:1, :119 — a static array is a cell RANGE) and
// `VarGEP` (src/ir/array_index.jl:1, forward :148 — a runtime index is a
// classical address computation): here a classical index selects a HANDLE,
// so the cell range is a range of handles and no value moves through a mux.

#include "RailWindow.h"

#include "QramLowering.h"  // railBankInstReaches

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"

using namespace llvm;

namespace cq {

namespace {

// Mirrored CHARACTER-FOR-CHARACTER by the negative fixtures (R10):
// (the initializer and store-width strings live in RailWindowInit.cpp).
// `kMsgWindowIndex` has NO fixture and none can be built from LLVM IR the claim
// admits: `collectAccesses` follows only GEPs into an integer-cell array, so
// every node has an index (`CellIndexer`'s byte remainder covers any scale).
// It is the loud backstop for a widened claim, never a silent fall-through.
constexpr char kMsgWindowIndex[] =
    "cq rail window: cell address is not a whole-cell index";

void diagnose(Instruction *At, const char *Msg) {
  Function &F = *At->getFunction();
  F.getContext().diagnose(DiagnosticInfoUnsupported(F, Msg, At->getDebugLoc()));
}

// The first point after `I` where a non-phi may be inserted.
Instruction *afterDef(Instruction *I) {
  return isa<PHINode>(I) ? &*I->getParent()->getFirstInsertionPt()
                         : I->getNextNode();
}

bool isPostQ(const Instruction *Q, const Instruction *A, DominatorTree &DT) {
  return A == Q || DT.dominates(Q, A);
}

// The C storage of a `_Bool` array is `i8` and its rail `i1` (the rail-bank
// record's distinction, `railBankRailType`). Only post-Q accesses are asked,
// and either witness suffices: clang -O1 tags every `_Bool` load `!range [0,
// 2)`, and a cell that is only ever read through a `trunc` to `i1` and
// written with a `zext` of an `i1` holds a one-bit value whatever its storage
// type. A load with neither, or no evidence at all, keeps the cell type.
bool isBoolRange(const LoadInst *L) {
  MDNode *R = L->getMetadata(LLVMContext::MD_range);
  if (!R || R->getNumOperands() != 2)
    return false;
  auto *Lo = mdconst::dyn_extract<ConstantInt>(R->getOperand(0));
  auto *Hi = mdconst::dyn_extract<ConstantInt>(R->getOperand(1));
  return Lo && Hi && Lo->isZero() && Hi->equalsInt(2);
}

bool readOnlyAsBit(const LoadInst *L) {
  for (const User *U : L->users()) {
    auto *T = dyn_cast<TruncInst>(U);
    if (!T || !T->getType()->isIntegerTy(1))
      return false;
  }
  return true;
}

Type *railTypeFor(const RailWindowAccesses &Acc,
                  ArrayRef<LoadInst *> PostLoads,
                  ArrayRef<StoreInst *> PostStores) {
  if (!Acc.CellTy->isIntegerTy(8))
    return Acc.CellTy;
  bool Ranged = true, BitView = true, BitStores = false;
  for (LoadInst *L : PostLoads) {
    Ranged &= isBoolRange(L);
    BitView &= readOnlyAsBit(L);
  }
  for (StoreInst *S : PostStores)
    if (auto *Z = dyn_cast<ZExtInst>(S->getValueOperand()))
      BitStores |= Z->getSrcTy()->isIntegerTy(1);
  bool Bool = (!PostLoads.empty() && (Ranged || BitView)) ||
              (PostLoads.empty() && BitStores);
  return Bool ? Type::getInt1Ty(Acc.CellTy->getContext()) : Acc.CellTy;
}

// The cell index of every node of the address tree (`AI` itself is cell 0),
// emitted right after the node so every access below it can use it. A GEP
// step whose scale is a multiple of the cell size contributes `idx *
// (scale/cell)` cells (SCEV-transparent); any other step is carried as a BYTE
// remainder, divided exactly at the access (collectAccesses proved every LEAF
// offset a whole number of cells: SCEV trailing zeros), with `lshr exact`,
// which SCEV reads as an exact `udiv`.
class CellIndexer {
public:
  CellIndexer(AllocaInst *AI, uint64_t CellBytes, const DataLayout &DL)
      : CellBytes(CellBytes), DL(DL),
        I64(Type::getInt64Ty(AI->getContext())) {
    Memo[AI] = {ConstantInt::get(I64, 0), nullptr};
  }

  // The cell index of leaf address `P` (a GEP of the tree), its division
  // emitted after the last offset instruction of `P`; null if `P` is not in
  // the tree.
  Value *cellIndex(GetElementPtrInst *P) {
    Off O = offsetOf(P);
    if (!O.Cells)
      return nullptr;
    if (!O.Bytes)
      return O.Cells;
    Instruction *Last = P;
    for (Value *V : {O.Cells, O.Bytes})
      if (auto *I = dyn_cast<Instruction>(V);
          I && I->getParent() == P->getParent() && Last->comesBefore(I))
        Last = I;
    IRBuilder<> B(Last->getNextNode());
    Value *C = B.CreateLShr(O.Bytes, Log2_64(CellBytes), "", /*isExact=*/true);
    return add(B, O.Cells, C);
  }

private:
  struct Off {
    Value *Cells = nullptr;  // whole cells
    Value *Bytes = nullptr;  // a byte remainder, or null
  };

  Value *add(IRBuilder<> &B, Value *X, Value *Y) {
    if (!X)
      return Y;
    if (auto *Z = dyn_cast<ConstantInt>(X); Z && Z->isZero())
      return Y;
    return B.CreateAdd(X, Y);
  }

  Off offsetOf(Value *P) {
    if (auto It = Memo.find(P); It != Memo.end())
      return It->second;
    auto *G = dyn_cast<GetElementPtrInst>(P);
    if (!G)
      return {};
    Off O = offsetOf(G->getPointerOperand());
    if (!O.Cells)
      return {};
    IRBuilder<> B(G->getNextNode());
    for (gep_type_iterator GTI = gep_type_begin(G), E = gep_type_end(G);
         GTI != E; ++GTI) {
      if (GTI.isStruct())
        return {};
      uint64_t Scale = GTI.getSequentialElementStride(DL).getFixedValue();
      Value *X = B.CreateSExtOrTrunc(GTI.getOperand(), I64);
      if (Scale % CellBytes == 0) {
        if (Scale != CellBytes)
          X = B.CreateMul(X, ConstantInt::get(I64, Scale / CellBytes));
        O.Cells = add(B, O.Cells, X);
      } else {
        if (Scale != 1)
          X = B.CreateMul(X, ConstantInt::get(I64, Scale));
        O.Bytes = add(B, O.Bytes, X);
      }
    }
    Memo[P] = O;
    return O;
  }

  uint64_t CellBytes;
  const DataLayout &DL;
  Type *I64;
  DenseMap<Value *, Off> Memo;
};

// A `zext <rail> to <cell>` standing in for a redirected `_Bool` load: fold the
// storage views clang wrote over it (`trunc` back to the rail, `icmp ne 0`).
void foldBoolView(ZExtInst *Z) {
  Value *X = Z->getOperand(0);
  for (User *U : make_early_inc_range(Z->users())) {
    auto *I = cast<Instruction>(U);
    bool Fold = false;
    if (auto *T = dyn_cast<TruncInst>(I))
      Fold = T->getType() == X->getType();
    else if (auto *C = dyn_cast<ICmpInst>(I))
      Fold = C->getPredicate() == ICmpInst::ICMP_NE &&
             match(C->getOperand(1), PatternMatch::m_Zero()) &&
             C->getOperand(0) == Z;
    if (Fold) {
      I->replaceAllUsesWith(X);
      I->eraseFromParent();
    }
  }
  if (Z->use_empty())
    Z->eraseFromParent();
}

}  // namespace

AllocaInst *materializeRailWindow(Function &F, RailWindowAccesses &Acc,
                                  Instruction *Q) {
  AllocaInst *AI = Acc.AI;
  const DataLayout &DL = F.getParent()->getDataLayout();
  LLVMContext &Ctx = F.getContext();
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *C = Acc.CellTy;
  const uint64_t CellBytes = DL.getTypeStoreSize(C).getFixedValue();
  DominatorTree DT(F);

  SmallVector<LoadInst *, 16> PostLoads;
  SmallVector<StoreInst *, 16> PostStores;
  for (LoadInst *L : Acc.Loads)
    if (isPostQ(Q, L, DT))
      PostLoads.push_back(L);
  for (StoreInst *S : Acc.Stores)
    if (isPostQ(Q, S, DT))
      PostStores.push_back(S);
  Type *RT = railTypeFor(Acc, PostLoads, PostStores);

  // The extent, in cells.
  Value *N = nullptr;
  if (auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
      AT && !AI->isArrayAllocation())
    N = ConstantInt::get(I64, AT->getNumElements());
  else
    N = AI->getArraySize();

  // The handle array: static in the entry block, or (runtime extent) right
  // after the original allocation, whose extent dominates it.
  AllocaInst *W;
  if (AI->isStaticAlloca() && isa<ConstantInt>(N)) {
    IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt());
    W = EB.CreateAlloca(RT, N, AI->getName() + ".rails");
  } else {
    IRBuilder<> AB(AI->getNextNode());
    W = AB.CreateAlloca(RT, N, AI->getName() + ".rails");
  }

  // Redirect every post-Q access.
  CellIndexer Ix(AI, CellBytes, DL);
  auto CellAddr = [&](Instruction *Acc0, Value *Ptr) -> Value * {
    auto *PG = dyn_cast<GetElementPtrInst>(Ptr);
    Value *Idx = PG ? Ix.cellIndex(PG) : nullptr;
    if (!Idx) {
      diagnose(Acc0, kMsgWindowIndex);
      return nullptr;
    }
    // After the later of the index and the original address: both dominate
    // every access through `Ptr`, and one dominates the other.
    auto *IdxI = dyn_cast<Instruction>(Idx);
    auto *PtrI = cast<Instruction>(Ptr);
    Instruction *Later = PtrI;
    if (IdxI && DT.dominates(PtrI, IdxI))
      Later = IdxI;
    IRBuilder<> B(afterDef(Later));
    return B.CreateGEP(RT, W, Idx, "cq.rail.addr");
  };
  // Memoize the new address per original pointer, so the cells of one class
  // share one address (S3's promotion wants a dominating address).
  DenseMap<Value *, Value *> NewAddr;
  auto Addr = [&](Instruction *At, Value *Ptr) -> Value * {
    if (Value *V = NewAddr.lookup(Ptr))
      return V;
    Value *V = Ptr == AI ? W : CellAddr(At, Ptr);
    if (V)
      NewAddr[Ptr] = V;
    return V;
  };
  for (StoreInst *S : PostStores) {
    IRBuilder<> B(S);
    Value *V = railWindowNarrow(S->getValueOperand(), RT, B, DL);
    if (!V) {
      diagnose(S, railWindowStoreWidthMsg());
      return nullptr;
    }
    Value *P = Addr(S, S->getPointerOperand());
    if (!P)
      return nullptr;
    StoreInst *NS = B.CreateStore(V, P);
    NS->setDebugLoc(S->getDebugLoc());
    Value *Old = S->getValueOperand();
    // Q is often this very store (a straight-line first tainted write): the
    // replacement takes its place, or the walk below would be inserted at a
    // freed instruction (measured: a straight-line Q put the walk AFTER the
    // first write and overwrote it with a fresh rail).
    if (Q == S)
      Q = NS;
    S->eraseFromParent();
    // The storage extension the narrowing looked through, now without a user
    // (left standing it would lower to a dead `zext` template rail).
    if (auto *OI = dyn_cast<CastInst>(Old); OI && OI != V && OI->use_empty())
      OI->eraseFromParent();
  }
  for (LoadInst *L : PostLoads) {
    Value *P = Addr(L, L->getPointerOperand());
    if (!P)
      return nullptr;
    IRBuilder<> B(L);
    LoadInst *NL = B.CreateLoad(RT, P, L->getName() + ".rail");
    NL->setDebugLoc(L->getDebugLoc());
    if (RT == C) {
      L->replaceAllUsesWith(NL);
      L->eraseFromParent();
      continue;
    }
    auto *Z = cast<ZExtInst>(B.CreateZExt(NL, C));
    L->replaceAllUsesWith(Z);
    L->eraseFromParent();
    foldBoolView(Z);
  }

  // Post-Q whole-object initializers become per-cell rebinds (notes 1–2); a
  // pre-Q one stays classical and the walk below reads its effect.
  auto IsLifetime = [](const Instruction *I) {
    auto *II = dyn_cast<IntrinsicInst>(I);
    return II && (II->getIntrinsicID() == Intrinsic::lifetime_start ||
                  II->getIntrinsicID() == Intrinsic::lifetime_end);
  };
  Instruction *MatAt = Q;
  bool FromOrig = true;
  Instruction *ScopeInit = nullptr;
  if (Acc.ScopeStart == Q) {
    // A per-iteration object: its contents at the start are indeterminate.
    // When the scope's whole-object initializer follows the start directly,
    // the walk runs after it and copies it; otherwise every cell gets |0>.
    MatAt = Q->getNextNode();
    FromOrig = false;
    while (isa<DbgInfoIntrinsic>(MatAt))
      MatAt = MatAt->getNextNode();
    if (is_contained(Acc.Others, MatAt) && !IsLifetime(MatAt)) {
      ScopeInit = MatAt;
      MatAt = MatAt->getNextNode();
      FromOrig = true;
    }
  }
  if (!railWindowSplitInits(Acc, Q, ScopeInit, W, RT, DT))
    return nullptr;  // diagnosed.

  // The materialization walk at Q (Q1, array-granular): every cell's rail is
  // minted from its classical value (a classical store into the handle array
  // IS that mint, at the retype slot).
  IRBuilder<> B(MatAt);
  Value *Count = B.CreateZExtOrTrunc(N, I64);
  Instruction *At = MatAt;
  if (!isa<ConstantInt>(Count))
    At = SplitBlockAndInsertIfThen(
        B.CreateICmpNE(Count, ConstantInt::get(I64, 0)), MatAt, false);
  auto [Body, Iv] = SplitBlockAndInsertSimpleForLoop(Count, At);
  IRBuilder<> LB(Body);
  Value *V = ConstantInt::get(RT, 0);
  if (FromOrig) {
    Value *Cell = LB.CreateLoad(C, LB.CreateGEP(C, AI, Iv), "cq.rail.init");
    // The low bit: exact for a `_Bool` cell (0 or 1) and for a cell only
    // ever read as its low bit (`railTypeFor`).
    V = RT == C ? Cell : LB.CreateTrunc(Cell, RT);
  }
  LB.CreateStore(V, LB.CreateGEP(RT, W, Iv));

  // The original address arithmetic the redirect left without a user (never
  // the object itself: its pre-Q accesses and markers stay).
  for (bool Again = true; Again;) {
    Again = false;
    SmallVector<GetElementPtrInst *, 16> Gs;
    SmallVector<Value *, 8> Wk{AI};
    while (!Wk.empty())
      for (User *U : Wk.pop_back_val()->users())
        if (auto *G = dyn_cast<GetElementPtrInst>(U)) {
          Gs.push_back(G);
          Wk.push_back(G);
        }
    for (GetElementPtrInst *G : Gs)
      if (G->use_empty()) {
        G->eraseFromParent();
        Again = true;
        break;
      }
  }
  return W;
}

}  // namespace cq
