// CloneRailSelect.cpp — bd p3kd.7.2. See CloneRailSelect.h for the argument.

#include "CloneRailSelect.h"

#include "OpcodeSupport.h"     // abiWidthFromType
#include "SelectMergeEmit.h"   // materializeCopySource (Rule 14: the one materializer)
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

constexpr char kMsgRailSelect[] =
    "cq specialization: classical select over a quantum value has no rail "
    "handle under quantum lift";

}  // namespace

bool isRecordedRailSelect(ArrayRef<RailSelectRecord> Recs,
                          const SelectInst *SI) {
  for (const RailSelectRecord &R : Recs)
    if (static_cast<Value *>(R.Sel) == SI)
      return true;
  return false;
}

bool rewriteRailSelects(ArrayRef<RailSelectRecord> Recs, TaintSet &ct,
                        WidthDispatch &wd) {
  for (const RailSelectRecord &R : Recs) {
    auto *SI = dyn_cast_or_null<SelectInst>(static_cast<Value *>(R.Sel));
    if (!SI)
      continue;  // erased since the record (no user left to route).
    // The select's own type is still the source type: `lowerOps` rewrites the
    // quantum PRODUCERS, never a select, so this is the logical width the
    // materialized classical arm must carry.
    const StringRef Abi = abiWidthFromType(SI->getType());
    FunctionCallee Alloc = wd.allocFn(Abi);
    Type *I32 = Type::getInt32Ty(SI->getContext());
    auto quantumArmOk = [&](Value *Arm) { return Arm->getType() == I32; };
    if (!Alloc || (R.TrueQuantum && !quantumArmOk(SI->getTrueValue())) ||
        (R.FalseQuantum && !quantumArmOk(SI->getFalseValue()))) {
      Function &F = *SI->getFunction();
      F.getContext().diagnose(
          DiagnosticInfoUnsupported(F, kMsgRailSelect, SI->getDebugLoc()));
      return false;
    }
    IRBuilder<> B(SI);
    const DebugLoc DL = SI->getDebugLoc();
    B.SetCurrentDebugLocation(DL);
    // A quantum arm is threaded as its handle; a classical arm (constant or
    // runtime) becomes its own |v> rail. The taint bit is the one RECORDED before
    // `lowerOps`: the quantum operand is now a template call, and asking `ct` about
    // it would make the verdict depend on how `lowerOps` migrates taint.
    auto railOf = [&](Value *Arm, bool Quantum) -> Value * {
      if (Quantum)
        return Arm;
      return materializeCopySource(Arm, Alloc, ct, B, DL, "cqq.rsel.arm");
    };
    Value *T = railOf(SI->getTrueValue(), R.TrueQuantum);
    Value *Fv = railOf(SI->getFalseValue(), R.FalseQuantum);
    // A classical condition the flatten speculated may be poison on a basis
    // state that never reaches its block; freezing it keeps the choice to one of
    // the two rails (never an arbitrary handle). The edge literals the condition
    // is built from are already frozen (PredMuxFlatten `literal`), so this fires
    // only for a condition with another poison source.
    Value *C = SI->getCondition();
    if (!isGuaranteedNotToBePoison(C))
      C = B.CreateFreeze(C, "cqq.rsel.c");
    Value *H = B.CreateSelect(C, T, Fv, "cqq.rsel");
    ct.Tainted.insert(H);
    ct.BirthOrder[H] = ct.NextBirth++;
    ct.HandleWidth[H] = Abi;
    SI->replaceAllUsesWith(H);  // cross-type: the source-typed select → i32 handle.
    ct.Tainted.erase(SI);
    ct.BirthOrder.erase(SI);
    ct.StaleDeclined.erase(SI);
    ct.HandleWidth.erase(SI);
    SI->eraseFromParent();
  }
  return true;
}

}  // namespace cq
