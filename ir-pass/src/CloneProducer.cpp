// CloneProducer.cpp — see the header (bd test_C_libtooling-p3kd.13).

#include "CloneProducer.h"

#include "CalleeBody.h"        // calleeBodyTrusted — the one trust predicate
#include "ChainWalk.h"         // preservesBasisUnderRecord / railOf
#include "DagTraversal.h"      // DataDag
#include "LiteralIntegrity.h"  // findUndefOperandInBody / slotCarriesUndef
#include "Specialization.h"    // synthesizeCloneUncTwin — the one twin recipe
#include "TaintPropagation.h"  // TaintSet::SpecHandleArgMask / Tainted

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// (P1) + (P2): the clone `G` calls, or null.
Function *recordedClone(const CallInst *G, const TaintSet &taint) {
  auto *F = dyn_cast<Function>(G->getCalledOperand());
  if (!F || F->isVarArg() ||
      !calleeBodyTrusted(F, CalleeBodyUse::AssumeOfLinkedCall))
    return nullptr;
  // Called at its own type: the twin is minted from the CALL's operand types
  // (`EmitInverse`), synthesized from the FUNCTION's; they must be one type.
  if (G->getFunctionType() != F->getFunctionType())
    return nullptr;
  // An operand bundle would carry a value the minted twin call drops.
  if (G->getNumOperandBundles() != 0)
    return nullptr;
  if (taint.SpecHandleArgMask.find(F) == taint.SpecHandleArgMask.end())
    return nullptr;  // not something the specializer recorded building (bd l3oi).
  if (!G->getType()->isIntegerTy(32) || !taint.Tainted.count(G))
    return nullptr;  // a classical-return clone, or a void call (a twin).
  return F;
}

std::string twinName(const Function &Clone) {
  return (Clone.getName() + "_unc").str();
}

// The type `EmitInverse`'s clone recipe mints and `synthUncomputeTwin` builds:
// `void(out, <clone params…>)`.
FunctionType *twinType(const Function &Clone) {
  SmallVector<Type *, 8> Params;
  Params.push_back(Clone.getReturnType());
  for (const Argument &A : Clone.args())
    Params.push_back(A.getType());
  return FunctionType::get(Type::getVoidTy(Clone.getContext()), Params,
                           /*isVarArg=*/false);
}

// (P3). An existing symbol is trusted only as a recorded, typed definition.
bool twinAvailable(const Function &Clone, const TaintSet &taint) {
  if (const GlobalValue *GV = Clone.getParent()->getNamedValue(twinName(Clone))) {
    const auto *Twin = dyn_cast<Function>(GV);
    return Twin && !Twin->isDeclaration() &&
           taint.SpecHandleArgMask.find(Twin) != taint.SpecHandleArgMask.end() &&
           Twin->getFunctionType() == twinType(Clone);
  }
  // No symbol: synthesizable unless the body would be DUPLICATED around an
  // undef/poison operand (bd xy9n — two independent reads, a different f).
  return findUndefOperandInBody(Clone) == nullptr;
}

}  // namespace

bool isCloneProducer(const CallInst *G, const TaintSet &taint) {
  const Function *F = recordedClone(G, taint);
  if (!F || !twinAvailable(*F, taint))
    return false;
  // (P4) — `slotCarriesUndef`, the literal-integrity slot predicate (it skips a
  // global ADDRESS, which is one value however often it is read).
  for (const Value *A : G->args())
    if (slotCarriesUndef(A))
      return false;
  return true;
}

bool isUnownableCloneCall(const CallInst *G, const TaintSet &taint) {
  // The dispatch test of `EmitInverse`'s clone recipe (`isInverseEmittable`: a
  // `__cq_q_` name that is not a `_unc` twin), asked of the called OPERAND so a
  // `GlobalAlias` cannot hide it (the bd xy9n lesson).
  const auto *GV = dyn_cast<GlobalValue>(G->getCalledOperand());
  if (!GV || G->getType()->isVoidTy())
    return false;
  const StringRef N = GV->getName();
  if (!N.starts_with("__cq_q_") || N.ends_with("_unc"))
    return false;
  return !isCloneProducer(G, taint);
}

bool cloneGatePreservesBasis(const CallInst *G, const TaintSet &taint) {
  return isCloneProducer(G, taint) || preservesBasisUnderRecord(G);
}

bool cloneTerminalReversalDisjoint(const DataDag &D,
                                   const SmallPtrSetImpl<const CallInst *> &RG,
                                   const SmallPtrSetImpl<Value *> &RR,
                                   const TaintSet &taint) {
  // Does an already-emitted adjoint (a template group's reversal, possibly reading
  // `V` as a BORROWED parent it never recorded as reversed) still read `V`?
  auto emittedAdjointReads = [&](Value *V) {
    for (User *U : V->users())
      if (const auto *C = dyn_cast<CallInst>(U); C && taint.SpineOps.count(C))
        return true;
    return false;
  };
  auto writtenHere = [&](Value *V) { return RR.count(V) || emittedAdjointReads(V); };
  for (CallInst *G : D.Calls) {
    if (RG.count(G))
      return false;  // one owner per gate (Rule 8)
    for (Value *Op : G->args())
      if (RR.count(Op))
        return false;  // a rail an earlier group reversed or freed
    if (Value *R = railOf(G); R && writtenHere(R))
      return false;
  }
  for (Value *R : D.Rails)
    if (writtenHere(R))
      return false;
  return true;
}

void materializeCloneTwins(ArrayRef<CallInst *> Gates, TaintSet &taint) {
  for (CallInst *G : Gates) {
    if (!isCloneProducer(G, taint))
      continue;
    Function *F = cast<Function>(G->getCalledOperand());
    if (F->getParent()->getNamedValue(twinName(*F)))
      continue;  // (P3) proved it is the recorded twin.
    Function *Twin = synthesizeCloneUncTwin(*F);
    // The inner drain's record for a twin: arg 0 is the `out` handle, then the
    // clone's own handle slots (Specialization.cpp, after `ensureTwin`).
    taint.SpecHandleArgMask[Twin] = (taint.SpecHandleArgMask.lookup(F) << 1) | 1;
  }
}

}  // namespace cq
