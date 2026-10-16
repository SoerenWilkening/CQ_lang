// InPlaceQQGate.cpp — WHAT an in-place quantum-source gate is, and which of its
// slots it writes (bd r2j3.33; bd r2j3.37.1 the consuming clone). Split out of
// InPlaceQQ.cpp so the gate's membership lives in one small file.

#include "InPlaceQQ.h"

#include "EmitInverse.h"  // inPlaceQQAdjointName

#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool isInPlaceQQSymbol(StringRef N) {
  for (StringRef Stem : {"cqrt_xor_", "cqrt_add_", "cqrt_sub_"})
    if (N.consume_front(Stem))
      return N == "i8" || N == "i16" || N == "i32" || N == "i64";
  return false;
}

int consumingCloneDestSlot(const Function *F) {
  if (!F || !F->hasFnAttribute(kConsumeDstAttr))
    return -1;
  unsigned K = 0;
  if (F->getFnAttribute(kConsumeDstAttr).getValueAsString().getAsInteger(10, K) ||
      K >= F->arg_size() || !F->getArg(K)->getType()->isIntegerTy(32))
    return -1;
  return static_cast<int>(K);
}

bool isConsumingCloneCall(const CallInst *G) {
  if (!G || !G->getMetadata(kInPlaceQQTag) || !G->getType()->isVoidTy())
    return false;
  const Function *Callee = G->getCalledFunction();
  const int K = consumingCloneDestSlot(Callee);
  if (K < 0 || Callee->getFunctionType() != G->getFunctionType())
    return false;
  // The destination is passed exactly once: a source slot naming the same
  // register would be read after it is overwritten.
  const Value *Dst = G->getArgOperand(K);
  for (unsigned I = 0; I < G->arg_size(); ++I)
    if (I != unsigned(K) && G->getArgOperand(I) == Dst)
      return false;
  return true;
}

bool isInPlaceQQGate(const CallInst *G) {
  if (isConsumingCloneCall(G))
    return true;
  if (!G || !G->getMetadata(kInPlaceQQTag))
    return false;
  const Function *Callee = G->getCalledFunction();
  if (!Callee || !G->getType()->isVoidTy() || G->arg_size() != 2)
    return false;
  StringRef N = Callee->getName();
  if (N != "cqrt_cnot" && !isInPlaceQQSymbol(N))
    return false;
  for (const Use &A : G->args())
    if (!A.get()->getType()->isIntegerTy(32))
      return false;
  return G->getArgOperand(0) != G->getArgOperand(1);
}

unsigned inPlaceQQDestSlot(const CallInst *G) {
  if (isConsumingCloneCall(G))
    return static_cast<unsigned>(consumingCloneDestSlot(G->getCalledFunction()));
  return 1;
}

const Value *inPlaceQQDest(const CallInst *G) {
  return G->getArgOperand(inPlaceQQDestSlot(G));
}

bool inPlaceQQReadsSource(const CallInst *G, const Value *V) {
  const unsigned D = inPlaceQQDestSlot(G);
  for (unsigned I = 0; I < G->arg_size(); ++I)
    if (I != D && G->getArgOperand(I) == V)
      return true;
  return false;
}

std::string consumingCloneAdjointName(StringRef Name) {
  if (Name.ends_with("_unc"))
    return Name.drop_back(4).str();
  return (Name + "_unc").str();
}

// Is `I` an adjoint of `G` on the same operands? The symbol is EmitInverse's
// (`inPlaceQQAdjointName`, the one spelling) or, for a consuming clone, its
// twin's (`consumingCloneAdjointName`); never re-derived at a caller.
bool isInPlaceQQAdjointOf(const CallInst *I, const CallInst *G) {
  if (I == G || !isInPlaceQQGate(I) || !isInPlaceQQGate(G) ||
      I->arg_size() != G->arg_size())
    return false;
  for (unsigned A = 0; A < G->arg_size(); ++A)
    if (I->getArgOperand(A) != G->getArgOperand(A))
      return false;
  StringRef GN = G->getCalledFunction()->getName();
  return I->getCalledFunction()->getName() ==
         (isConsumingCloneCall(G) ? consumingCloneAdjointName(GN)
                                  : inPlaceQQAdjointName(GN));
}

}  // namespace cq
