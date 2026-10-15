// MergeArmWrite.cpp — see MergeArmWrite.h (bd dm7f.81). Also home of the shared
// rail materializer and the bd r2j3.14 classical-source ledger, declared in
// SelectMergeEmit.h (moved here from SelectMergeEmit.cpp with dm7f.81).

#include "MergeArmWrite.h"

#include "ControlPlan.h"         // diagnoseUnderControl
#include "ControlledSymbols.h"   // xFn / isControlledXorc
#include "SelectMergeEmit.h"     // materializeCopySource / declineQuantumCopySources
#include "TaintPropagation.h"    // TaintSet

#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/ValueHandle.h"

#include <vector>

using namespace llvm;

namespace cq {

namespace {
// bd r2j3.14 — the classical values read so far (a rail load, or since dm7f.81 a
// controlled xor-immediate's slot 2), for the final-taint re-ask. A
// function-local static, the pattern of `exitDischargeObligations` (no new
// `TaintSet` field). `WeakVH`: a call erased since is nothing to re-ask, and the
// handle must NOT follow a RAUW (it names the call, whose operand is read).
std::vector<WeakVH> &copySourceLedger() {
  static std::vector<WeakVH> Ledger;
  return Ledger;
}
}  // namespace

Value *materializeCopySource(Value *V, FunctionCallee Alloc,
                             const TaintSet &taint, IRBuilder<> &B,
                             const DebugLoc &DL, const Twine &Name) {
  if (taint.Tainted.count(V))
    return V;  // already an i32 quantum handle.
  CallInst *H = B.CreateCall(Alloc, {V}, Name);
  if (DL)
    H->setDebugLoc(DL);
  if (!isa<Constant>(V))
    copySourceLedger().emplace_back(H);  // re-asked at final taint (r2j3.14).
  return H;
}

bool declineQuantumCopySources(Module &M, TaintSet &taint) {
  (void)M;  // module-wide record; each call names its own function.
  std::vector<WeakVH> Ledger;
  Ledger.swap(copySourceLedger());  // read once: the next module starts empty.
  for (const WeakVH &H : Ledger) {
    auto *C = dyn_cast_or_null<CallInst>(static_cast<Value *>(H));
    if (!C || !C->getFunction())
      continue;  // erased or detached: nothing left to read.
    // The classical slot: a rail load's seed (arg 0), or a controlled
    // xor-immediate's immediate (arg 2).
    Value *Src = isControlledXorc(C) ? C->getArgOperand(2)
                 : C->arg_size() == 1 ? C->getArgOperand(0)
                                      : nullptr;
    if (Src && taint.Tainted.count(Src)) {
      diagnoseUnderControl(C, "classical copy source became quantum-derived");
      return true;
    }
  }
  return false;
}

bool armWriteIsNoop(Value *Arm, const TaintSet &taint) {
  auto *K = dyn_cast<Constant>(Arm);
  // An `undef`/`poison` arm (clang -O1's dead-edge `select i1 %c, double undef,
  // double %v`) is REFINED to the all-zero pattern, a value LangRef permits: no
  // gate. Emitting the literal would put it in two slots once the merge
  // discharge replays the write (LiteralIntegrity.h guard 1: per-use
  // materialization, two different values), and a `freeze` would print a
  // codegen-chosen value into the trace.
  return K && !taint.Tainted.count(Arm) &&
         (K->isNullValue() || isa<UndefValue>(K));
}

CallInst *emitArmWrite(IRBuilder<> &B, Value *Flag, Value *Arm, Value *Out,
                       FunctionCallee CopyC, FunctionCallee XorcC,
                       const TaintSet &taint, const DebugLoc &DL) {
  CallInst *G = nullptr;
  if (taint.Tainted.count(Arm)) {
    G = B.CreateCall(CopyC, {Flag, Arm, Out});
  } else if (armWriteIsNoop(Arm, taint)) {
    return nullptr;
  } else {
    G = B.CreateCall(XorcC, {Flag, Out, Arm});
    if (!isa<Constant>(Arm))
      copySourceLedger().emplace_back(G);  // re-asked at final taint (r2j3.14).
  }
  if (DL)
    G->setDebugLoc(DL);
  return G;
}

void emitArmMux(IRBuilder<> &B, ControlledSymbols &csyms, Value *Flag,
                Value *True, Value *False, Value *Out, FunctionCallee CopyC,
                FunctionCallee XorcC, const TaintSet &taint,
                const DebugLoc &DL) {
  emitArmWrite(B, Flag, True, Out, CopyC, XorcC, taint, DL);
  if (armWriteIsNoop(False, taint))
    return;  // nothing on ¬flag: no bracket either.
  auto bracket = [&] {
    CallInst *X = B.CreateCall(csyms.xFn(), {Flag});
    if (DL)
      X->setDebugLoc(DL);
  };
  bracket();
  emitArmWrite(B, Flag, False, Out, CopyC, XorcC, taint, DL);
  bracket();
}

}  // namespace cq
