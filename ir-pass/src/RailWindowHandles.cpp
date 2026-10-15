// RailWindowHandles.cpp — bd `test_C_libtooling-01po.19` S4, the handle half:
// the `!cq.railwindow` record and its predicates (borrowed root, kept-carrier
// sink), the reserved-name fence, and the retype to `i32` handle cells.
// Contract in RailWindow.h. Ground truth (R12): BennettVM.jl 23d28e6
// `MemoryAssignment` (src/ir/memory_instructions.jl:111, forward :146, inverse
// :181) updates a cell IN PLACE and never reverses the cell itself; the cell
// is the caller's storage, which is the borrowed-root reading here.

#include "RailWindow.h"

#include "OpcodeSupport.h"  // abiWidthFromType
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/Analysis/ValueTracking.h"  // getUnderlyingObject
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

// The record's name. ONE spelling, in one place.
constexpr char kRailWindowMD[] = "cq.railwindow";

// `kMsgForeignRecord` is mirrored CHARACTER-FOR-CHARACTER by
// railwindow_reject_foreign_record.ll. `kMsgRewrite` has NO fixture: every user
// of a handle array is one the materialization itself emitted (a single-index
// `gep <rail>` and its cell loads/stores), and the foreign-record fence refuses
// any input that could plant another. It is the loud backstop for a later
// stage that adds a user, never a silent skip.
constexpr char kMsgForeignRecord[] =
    "cq rail window: input carries the compiler-owned !cq.railwindow record";
constexpr char kMsgRewrite[] =
    "cq rail window: handle-cell retype met an unexpected user";

void diagnoseAt(Instruction *I, const char *Msg) {
  Function &F = *I->getFunction();
  F.getContext().diagnose(DiagnosticInfoUnsupported(F, Msg, I->getDebugLoc()));
}

}  // namespace

bool isRailWindowAlloca(const AllocaInst *AI) {
  return AI && AI->getMetadata(kRailWindowMD) != nullptr;
}

AllocaInst *railWindowOfPointer(const Value *P) {
  if (!P)
    return nullptr;
  auto *AI = dyn_cast<AllocaInst>(getUnderlyingObject(P));
  return isRailWindowAlloca(AI) ? const_cast<AllocaInst *>(AI) : nullptr;
}

Type *railWindowRailType(const AllocaInst *AI) {
  MDNode *N = AI ? AI->getMetadata(kRailWindowMD) : nullptr;
  if (!N || N->getNumOperands() != 1)
    return nullptr;
  auto *CI = mdconst::dyn_extract<ConstantInt>(N->getOperand(0));
  if (!CI)
    return nullptr;
  return IntegerType::get(AI->getContext(),
                          static_cast<unsigned>(CI->getZExtValue()));
}

bool isRailWindowCellRead(const Value *V) {
  const auto *LD = dyn_cast_or_null<LoadInst>(V);
  return LD && railWindowOfPointer(LD->getPointerOperand());
}

bool railStoredToRailWindow(const Value *H) {
  if (!H)
    return false;
  for (const User *U : H->users())
    if (const auto *SI = dyn_cast<StoreInst>(U))
      if (SI->getValueOperand() == H &&
          railWindowOfPointer(SI->getPointerOperand()))
        return true;
  return false;
}

bool railWindowFamily(const Value *V, SmallVectorImpl<Value *> &Out) {
  const AllocaInst *W = nullptr;
  if (const auto *LD = dyn_cast_or_null<LoadInst>(V))
    W = railWindowOfPointer(LD->getPointerOperand());
  if (!W && V)
    for (const User *U : V->users())
      if (const auto *SI = dyn_cast<StoreInst>(U))
        if (SI->getValueOperand() == V)
          if ((W = railWindowOfPointer(SI->getPointerOperand())))
            break;
  if (!W)
    return false;
  // The handle array's address tree is `W` and its single-index geps (the
  // retype's own vocabulary, checked there); every cell memop hangs off it.
  SmallVector<const Value *, 16> Ptrs{W};
  for (const User *U : W->users())
    if (isa<GetElementPtrInst>(U))
      Ptrs.push_back(U);
  for (const Value *P : Ptrs)
    for (const User *U : P->users()) {
      if (const auto *L = dyn_cast<LoadInst>(U); L && L->getPointerOperand() == P)
        Out.push_back(const_cast<LoadInst *>(L));
      else if (const auto *S = dyn_cast<StoreInst>(U);
               S && S->getPointerOperand() == P &&
               !isa<Constant>(S->getValueOperand()))
        Out.push_back(const_cast<Value *>(S->getValueOperand()));
    }
  return true;
}

void markRailWindowAlloca(AllocaInst *W, Type *RailTy) {
  LLVMContext &Ctx = W->getContext();
  W->setMetadata(kRailWindowMD,
                 MDNode::get(Ctx, {ConstantAsMetadata::get(ConstantInt::get(
                                      Type::getInt32Ty(Ctx),
                                      RailTy->getIntegerBitWidth()))}));
}

bool declineForeignRailWindowRecords(Module &M) {
  unsigned Kind = M.getContext().getMDKindID(kRailWindowMD);
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (I.getMetadata(Kind)) {
        diagnoseAt(&I, kMsgForeignRecord);
        return true;
      }
  return false;
}

void rewriteRailWindowCellTypes(Module &M, WidthDispatch &wd,
                                TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallVector<AllocaInst *, 2> Ws;
    for (Instruction &I : instructions(F))
      if (auto *A = dyn_cast<AllocaInst>(&I); A && isRailWindowAlloca(A))
        Ws.push_back(A);
    for (AllocaInst *W : Ws) {
      LLVMContext &Ctx = W->getContext();
      const DataLayout &DL = M.getDataLayout();
      Type *I32 = Type::getInt32Ty(Ctx);
      Type *RT = railWindowRailType(W);
      StringRef Abi = RT ? abiWidthFromType(RT) : StringRef();
      FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
      if (!Alloc) {
        diagnoseAt(W, kMsgRewrite);
        return;
      }
      // Every user is a `gep <rail>, W, idx` whose users are cell loads and
      // stores, or such a load/store directly (cell 0). Collected first, so
      // the retype below never walks a half-rewritten tree.
      SmallVector<GetElementPtrInst *, 16> Geps;
      SmallVector<LoadInst *, 16> Loads;
      SmallVector<StoreInst *, 16> Stores;
      SmallVector<Value *, 16> Ptrs{W};
      for (User *U : W->users())
        if (auto *G = dyn_cast<GetElementPtrInst>(U);
            G && G->getPointerOperand() == W &&
            G->getSourceElementType() == RT && G->getNumIndices() == 1) {
          Geps.push_back(G);
          Ptrs.push_back(G);
        }
      for (Value *P : Ptrs)
        for (User *U : P->users()) {
          if (P == W && is_contained(Geps, U))
            continue;
          if (auto *L = dyn_cast<LoadInst>(U);
              L && L->getPointerOperand() == P && L->getType() == RT)
            Loads.push_back(L);
          else if (auto *S = dyn_cast<StoreInst>(U);
                   S && S->getPointerOperand() == P)
            Stores.push_back(S);
          else {
            diagnoseAt(cast<Instruction>(U), kMsgRewrite);
            return;
          }
        }
      W->setAllocatedType(I32);
      if (W->getAlign() < DL.getABITypeAlign(I32))
        W->setAlignment(DL.getABITypeAlign(I32));
      for (GetElementPtrInst *G : Geps) {
        G->setSourceElementType(I32);
        G->setResultElementType(I32);
      }
      // A load IS the rail's name: retyped in place to the `i32` handle, its
      // logical width recorded (a cast reading it recovers its source width
      // there, `OpcodeLowering`'s capture), and a birth slot so a Q+Q operand
      // order is a function of the program.
      for (LoadInst *L : Loads) {
        L->mutateType(I32);
        L->setAlignment(DL.getABITypeAlign(I32));
        L->setMetadata(LLVMContext::MD_range, nullptr);
        L->setMetadata(LLVMContext::MD_tbaa, nullptr);
        L->setMetadata(LLVMContext::MD_noundef, nullptr);
        taint.HandleWidth[L] = Abi;
        if (!taint.BirthOrder.count(L))
          taint.BirthOrder[L] = taint.NextBirth++;
      }
      // A store of a rail keeps it (the value is a handle by now, or a
      // pre-`lowerOps` value that stage RAUWs to one). A CLASSICAL value is a
      // REBIND (Q3): a fresh basis rail holding it; the old one is abandoned.
      for (StoreInst *S : Stores) {
        S->setAlignment(DL.getABITypeAlign(I32));
        S->setMetadata(LLVMContext::MD_tbaa, nullptr);
        Value *V = S->getValueOperand();
        if (taint.Tainted.count(V))
          continue;
        if (V->getType() != RT) {
          diagnoseAt(S, kMsgRewrite);
          return;
        }
        IRBuilder<> B(S);
        CallInst *H = B.CreateCall(Alloc, {V}, "h");
        H->setDebugLoc(S->getDebugLoc());
        taint.Tainted.insert(H);
        taint.BirthOrder[H] = taint.NextBirth++;
        taint.HandleWidth[H] = Abi;
        S->setOperand(0, H);
      }
    }
  }
}

}  // namespace cq
