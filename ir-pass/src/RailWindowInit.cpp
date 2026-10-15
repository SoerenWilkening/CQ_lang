// RailWindowInit.cpp — bd `test_C_libtooling-01po.19` S4: the cell RAIL TYPE
// (`railWindowRailTypeFor`) and addendum notes 1–2, a whole-object
// initializer of a window array. Before the quantization point
// it is ordinary classical memory (the materialization walk reads its effect).
// After it, it is a REBIND of every cell it covers (Q3): split into per-cell
// classical stores into the handle array, each of which the retype turns into
// a fresh basis rail. What cannot be split exactly is refused loudly. Contract
// in RailWindow.h.

#include "RailWindow.h"

#include "QramLowering.h"  // railBankInstReaches

#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

using namespace llvm;

namespace cq {

namespace {

// Mirrored CHARACTER-FOR-CHARACTER by the negative fixtures (R10):
//   * railwindow_reject_init_vector / _runtime_fill → kMsgWindowInit
//   * railwindow_reject_store_width                 → kMsgWindowStoreWidth
//   * railwindow_reject_init_order                  → kMsgWindowInitOrder
constexpr char kMsgWindowInit[] =
    "cq rail window: quantum-array initializer is not a per-cell classical "
    "value";
constexpr char kMsgWindowStoreWidth[] =
    "cq rail window: stored value does not fit the cell's rail";
constexpr char kMsgWindowInitOrder[] =
    "cq rail window: initializer reachable from the quantization point is not "
    "dominated by it";

void diagnose(Instruction *At, const char *Msg) {
  Function &F = *At->getFunction();
  F.getContext().diagnose(DiagnosticInfoUnsupported(F, Msg, At->getDebugLoc()));
}

bool isLifetime(const Instruction *I) {
  auto *II = dyn_cast<IntrinsicInst>(I);
  return II && (II->getIntrinsicID() == Intrinsic::lifetime_start ||
                II->getIntrinsicID() == Intrinsic::lifetime_end);
}

// The value stored into a rail cell: the cell value narrowed to the rail.
// Null when it provably does not fit (the caller diagnoses).
Value *narrowToRailImpl(Value *V, Type *RailTy, IRBuilder<> &B,
                    const DataLayout &DL) {
  if (V->getType() == RailTy)
    return V;
  if (auto *Z = dyn_cast<ZExtInst>(V); Z && Z->getSrcTy() == RailTy)
    return Z->getOperand(0);
  KnownBits KB = computeKnownBits(V, DL);
  if (KB.countMinLeadingZeros() <
      V->getType()->getIntegerBitWidth() - RailTy->getIntegerBitWidth())
    return nullptr;
  return B.CreateTrunc(V, RailTy);
}

// Cell `k`'s value in a constant whole-object store (little- or big-endian per
// the data layout), or null.
Constant *cellOfConstant(Constant *C, uint64_t K, Type *CellTy,
                         const DataLayout &DL) {
  if (C->isNullValue())
    return ConstantInt::get(CellTy, 0);
  auto *CI = dyn_cast<ConstantInt>(C);
  if (!CI)
    return nullptr;
  unsigned CellBits = CellTy->getIntegerBitWidth();
  unsigned Total = CI->getBitWidth();
  uint64_t Shift = DL.isLittleEndian() ? K * CellBits
                                       : Total - (K + 1) * CellBits;
  if ((K + 1) * CellBits > Total)
    return nullptr;
  return ConstantInt::get(CellTy, CI->getValue().lshr(Shift).trunc(CellBits));
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

Type *railTypeForImpl(const RailWindowAccesses &Acc,
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

}  // namespace

const char *railWindowStoreWidthMsg() { return kMsgWindowStoreWidth; }

Type *railWindowRailTypeFor(const RailWindowAccesses &Acc,
                            ArrayRef<LoadInst *> PostLoads,
                            ArrayRef<StoreInst *> PostStores) {
  return railTypeForImpl(Acc, PostLoads, PostStores);
}

Value *railWindowNarrow(Value *V, Type *RailTy, IRBuilder<> &B,
                        const DataLayout &DL) {
  return narrowToRailImpl(V, RailTy, B, DL);
}

bool railWindowSplitInits(RailWindowAccesses &Acc, Instruction *Q,
                          Instruction *ScopeInit, AllocaInst *W, Type *RT,
                          DominatorTree &DT) {
  const DataLayout &DL = W->getModule()->getDataLayout();
  Type *I64 = Type::getInt64Ty(W->getContext());
  Type *C = Acc.CellTy;
  const uint64_t CellBytes = DL.getTypeStoreSize(C).getFixedValue();
  // Decide every initializer BEFORE any CFG edit: the memset split below
  // invalidates `DT` (R9: no analysis read across a mutation).
  SmallVector<Instruction *, 4> Post;
  for (Instruction *O : Acc.Others) {
    if (isLifetime(O) || O == ScopeInit)
      continue;  // markers stay on the original; the scope's own
                 // initializer is copied by the walk.
    const bool Read = isa<LoadInst>(O);
    // Review C-F1: a multi-cell READ of the object after Q copies cell rails
    // out (`r = q` as one wide load + store). Not lowered until copy-on-read
    // (bd 01po.19.2): the window-scoped decline, never a bank-stage one.
    if (Read && (O == Q || DT.dominates(Q, O) || railBankInstReaches(Q, O))) {
      Function &F = *O->getFunction();
      F.getContext().diagnose(DiagnosticInfoUnsupported(
          F, railWindowCopyNeeds(), O->getDebugLoc()));
      return false;
    }
    if (Read)
      continue;  // a classical read of classical memory, before Q.
    if (O == Q || DT.dominates(Q, O)) {
      Post.push_back(O);
      continue;
    }
    if (railBankInstReaches(Q, O)) {
      diagnose(O, kMsgWindowInitOrder);
      return false;
    }
  }
  for (Instruction *O : Post) {
    IRBuilder<> B(O);
    if (auto *S = dyn_cast<StoreInst>(O)) {
      auto *K = cast<Constant>(S->getValueOperand());
      uint64_t Bytes = DL.getTypeStoreSize(K->getType()).getFixedValue();
      if (Bytes % CellBytes) {
        diagnose(O, kMsgWindowInit);
        return false;
      }
      for (uint64_t k = 0; k < Bytes / CellBytes; ++k) {
        Constant *Cell = cellOfConstant(K, k, C, DL);
        Value *V = Cell ? narrowToRailImpl(Cell, RT, B, DL) : nullptr;
        if (!V) {
          diagnose(O, Cell ? kMsgWindowStoreWidth : kMsgWindowInit);
          return false;
        }
        B.CreateStore(V, B.CreateGEP(RT, W, ConstantInt::get(I64, k)));
      }
      O->eraseFromParent();
      continue;
    }
    // A copy from a constant global (an aggregate initializer) after Q: not
    // split yet — loud (filed under bd 01po.19 S4 follow-ups).
    if (isa<MemCpyInst>(O)) {
      diagnose(O, kMsgWindowInit);
      return false;
    }
    // A memset: a constant fill byte over a whole number of cells.
    auto *II = cast<IntrinsicInst>(O);
    auto *Fill = dyn_cast<ConstantInt>(II->getArgOperand(1));
    Value *Len = II->getArgOperand(2);
    unsigned Shift = Log2_64(CellBytes);
    if (!Fill || computeKnownBits(Len, DL).countMinTrailingZeros() < Shift) {
      diagnose(O, kMsgWindowInit);
      return false;
    }
    APInt Splat = APInt::getSplat(C->getIntegerBitWidth(),
                                  Fill->getValue().trunc(8));
    Value *V = narrowToRailImpl(ConstantInt::get(C, Splat), RT, B, DL);
    if (!V) {
      diagnose(O, kMsgWindowStoreWidth);
      return false;
    }
    Value *Count = B.CreateLShr(B.CreateZExtOrTrunc(Len, I64), Shift);
    Instruction *Then = SplitBlockAndInsertIfThen(
        B.CreateICmpNE(Count, ConstantInt::get(I64, 0)), O, false);
    auto [Body, Iv] = SplitBlockAndInsertSimpleForLoop(Count, Then);
    IRBuilder<> LB(Body);
    LB.CreateStore(V, LB.CreateGEP(RT, W, Iv));
    O->eraseFromParent();
  }
  return true;
}

}  // namespace cq
