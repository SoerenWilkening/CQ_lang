// MergeStreamGates.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeStreamGates.h"

#include "ChainWalk.h"         // isInPlaceGateOn / isInteriorConsumer / ...
#include "InPlaceQQ.h"         // isInPlaceQQGate (bd r2j3.33)
#include "RailBankPromote.h"   // railBankParkedRails / railBankCellReadsOf
#include "RailWindow.h"        // railWindowFamily (bd 01po.19 S5)
#include "TaintPropagation.h"  // TaintSet
#include "TemplateName.h"      // isUncHandleSlot

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

StringRef calleeName(const CallInst *C) {
  const Function *F = C ? C->getCalledFunction() : nullptr;
  return F ? F->getName() : StringRef();
}

// `cqrt_copy_<W>_controlled(ctrl, src, dst)`, int or fp: void, arity 3. A
// transversal-CNOT basis copy of src into dst under ctrl (runtime/cq_runtime.h),
// an involution with no `_inv` twin.
bool isControlledCopy(const CallInst *C) {
  StringRef N = calleeName(C);
  return N.starts_with("cqrt_copy_") && N.ends_with("_controlled") &&
         C->getType()->isVoidTy() && C->arg_size() == 3;
}

// The uncontrolled `cqrt_copy_<W>(src, dst)` (the 4.5 switch-value PRELOAD of
// the default base into the |0> rail): an XOR of src's label into dst, an
// involution. `_inv`/`_unc`/`_controlled` spellings are other families.
bool isPlainCopy(const CallInst *C) {
  StringRef N = calleeName(C);
  return N.starts_with("cqrt_copy_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc") &&
         C->getType()->isVoidTy() && C->arg_size() == 2;
}

bool isMergeWrite(const CallInst *C, const Value *Out) {
  if (isControlledCopy(C))
    return C->getArgOperand(2) == Out && C->getArgOperand(0) != Out &&
           C->getArgOperand(1) != Out;
  if (isPlainCopy(C))
    return C->getArgOperand(1) == Out && C->getArgOperand(0) != Out;
  return false;
}

// The merge-stream ALLOWLIST and, per gate, the argument slots it WRITES.
// Every slot not listed is a pure read. Fails closed: anything not named is
// not stream traffic, and a stream containing it is not replayed.
//   cqrt_alloc_<W>(seed)            mints, writes nothing
//   cq_template_* (forward producer) mints, reads every operand
//   cq_template_*_unc(rail, ...)    writes slot 0 (a strip / the spine's adjoint)
//   cqrt_cnot(c, t)                 writes 1
//   cqrt_toffoli(c1, c2, t)         writes 2
//   cqrt_x(t)                       writes 0
//   cqrt_copy_<W>_controlled(f,s,d) writes 2
//   cqrt_copy_<W>(s,d)              writes 1
//   cqrt_free(r)                    writes 0
bool streamGateWrites(const CallInst *C, SmallVectorImpl<unsigned> &W) {
  W.clear();
  StringRef N = calleeName(C);
  if (N.empty())
    return false;
  // bd r2j3.33: a TAGGED in-place quantum-source gate (the i1 form is a
  // `cqrt_cnot`) is the user's own `x ^= y`, never merge-stream traffic: a
  // replay must not re-emit it. Asked before the `cqrt_cnot` row by membership.
  if (isInPlaceQQGate(C))
    return false;
  bool Void = C->getType()->isVoidTy();
  unsigned A = C->arg_size();
  if (N.starts_with("cqrt_alloc_"))
    return !Void && A == 1;
  if (N == "cqrt_cnot" && Void && A == 2)
    return W.push_back(1), true;
  if (N == "cqrt_toffoli" && Void && A == 3)
    return W.push_back(2), true;
  if (N == "cqrt_x" && Void && A == 1)
    return W.push_back(0), true;
  if (N == "cqrt_free" && Void && A == 1)
    return W.push_back(0), true;
  if (isControlledCopy(C))
    return W.push_back(2), true;
  if (isPlainCopy(C))
    return W.push_back(1), true;
  if (N.starts_with("cq_template_") && !N.contains("_controlled")) {
    if (N.ends_with("_unc"))
      return Void && A >= 1 ? (W.push_back(0), true) : false;
    return !Void && isTemplateProducer(C);
  }
  return false;
}

// The CONTROL slots of the stream's controlled gates.
SmallVector<unsigned, 2> controlSlots(const CallInst *C) {
  StringRef N = calleeName(C);
  if (N == "cqrt_cnot" || isControlledCopy(C))
    return {0};
  if (N == "cqrt_toffoli")
    return {0, 1};
  // bd dm7f.77 (R11 round 1 C-F4): a controlled rotation's control, for
  // ChainWalk's row (c′). Not merge-stream traffic (`streamGateWrites` refuses
  // it), so the stream planner never reaches this case.
  if ((N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
      N.ends_with("_controlled") && C->arg_size() == 3)
    return {0};
  return {};
}

// Does `C` only READ the register `X` (never write, measure, record or escape
// it)? Asked of every reader of a merge rail and of every gate that touches a
// register the stream reads between the stream and its replay.
bool onlyReads(const CallInst *C, const Value *X, const TaintSet &taint) {
  StringRef N = calleeName(C);
  if (N.empty())
    return false;
  // A forward template producer reading X in a handle slot, a forward QRAM
  // store reading X as its index/value, or an emitter-recorded flag strip:
  // ChainWalk's interior-consumer rows (b)/(b″)/(c), asked, not re-spelled
  // (R12). Its row (a), an in-place gate ON X, is a write and is refused first.
  if (isInPlaceGateOn(C, X))
    return false;
  if (isInteriorConsumer(C, X, taint, /*AdmitCloneCalls=*/false))
    return true;
  // The spine's void out-first adjoint `cq_template_*_unc(rail, operands…)`:
  // slot 0 is the rail it zeroes, every other handle slot a read.
  if (N.starts_with("cq_template_") && N.ends_with("_unc")) {
    bool Any = false;
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == X) {
        if (!isUncHandleSlot(N, I))
          return false;
        Any = true;
      }
    return Any;
  }
  // A CONTROL slot: slot 0 of every `_controlled` gate (a controlled rotation,
  // a controlled template, a guarded store, a controlled copy). A control is
  // read in the computational basis and keeps its label, so a CNOT-class
  // record of it, and a strip recomputing from it, are unaffected: X held ONLY
  // in slot 0 is a pure read whatever the gate writes elsewhere (the written
  // register is some other value, which its own check owns).
  if (N.contains("_controlled") && !N.ends_with("_unc") &&
      !N.ends_with("_inv") && C->arg_size() >= 2) {
    bool OnlyCtl = C->getArgOperand(0) == X;
    for (unsigned I = 1, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == X)
        OnlyCtl = false;  // another slot too: the rows below decide.
    if (OnlyCtl)
      return true;
  }
  // The read-only CONTROL / SOURCE slots of the stream's own permutation gates
  // (`streamGateWrites` names the one written slot of each).
  SmallVector<unsigned, 2> W;
  if (!N.starts_with("cqrt_alloc_") && streamGateWrites(C, W) &&
      !N.starts_with("cq_template_") && N != "cqrt_free") {
    bool Any = false;
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == X) {
        if (is_contained(W, I))
          return false;
        Any = true;
      }
    return Any;
  }
  return false;
}

bool readsState(const CallInst *C, unsigned I) {
  StringRef N = calleeName(C);
  if (N.starts_with("cqrt_alloc_"))
    return false;  // the seed is a classical immediate.
  if (N.starts_with("cq_template_") && !N.contains("_controlled")) {
    if (N.ends_with("_unc"))
      return I == 0 || isUncHandleSlot(N, I);
    if (!N.ends_with("_inv") && C->arg_size() <= 3)
      return isHandleSlot(N, I);  // exact for the forward uncontrolled grammar.
  }
  return true;  // every other slot of the stream allowlist is a handle.
}

bool isRegister(const Value *V, const TaintSet &taint) {
  if (isa<Constant>(V))
    return false;
  if (const auto *A = dyn_cast<Argument>(V))
    return taint.Tainted.count(const_cast<Argument *>(A)) ||
           A->getParent()->getName().starts_with("__cq_q_");
  return true;  // φ, select, load, cast, call, … — fail closed.
}

bool handleAliases(Value *X, const TaintSet &taint, const DominatorTree &DT,
                   SmallPtrSetImpl<Value *> &Out) {
  auto freshNotDominating = [&](const PHINode *P, const Value *Op) {
    const auto *C = dyn_cast<CallInst>(Op);
    StringRef N = calleeName(C);
    bool Fresh = N.starts_with("cqrt_alloc_") ||
                 (N.starts_with("cq_template_") && !C->getType()->isVoidTy() &&
                  !N.contains("_controlled"));
    return Fresh && !DT.dominates(C, P);
  };
  SmallVector<Value *, 8> Work{X};
  auto carries = [](const Value *U) {
    return isa<PHINode>(U) || isa<SelectInst>(U) || isa<CastInst>(U) ||
           isa<FreezeInst>(U);
  };
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!isRegister(V, taint) || !Out.insert(V).second)
      continue;
    // THE MEMORY HOP, through a proven RAIL BANK only (RailBankPromote.h: every
    // user of a `!cq.railbank` object is a canonical cell access, so its cell
    // loads and its stored rails are an exact alias set — the cell index may be
    // dynamic, so EVERY cell of the bank is in the class). Any other memory
    // round trip has unknown writers: refuse.
    // bd 01po.19 S5: or through a `!cq.railwindow` handle array, whose every
    // user is the materialization's own cell access — the class is the whole
    // array family (`railWindowFamily`: every cell read and every stored rail;
    // array-granular, a superset of any one cell).
    if (auto *Ld = dyn_cast<LoadInst>(V)) {
      SmallVector<Value *, 4> Parked;
      if (!railBankParkedRails(Ld, Parked) && !railWindowFamily(Ld, Parked))
        return false;
      Work.append(Parked.begin(), Parked.end());
    }
    for (User *U : V->users()) {
      if (auto *SI = dyn_cast<StoreInst>(U)) {
        SmallVector<LoadInst *, 4> Cells;
        SmallVector<Value *, 8> Family;
        if (SI->getValueOperand() == V && railStoredToRailWindow(V) &&
            railWindowFamily(V, Family)) {
          Work.append(Family.begin(), Family.end());
          continue;
        }
        if (SI->getValueOperand() != V || !railBankCellReadsOf(V, Cells))
          return false;  // parked in memory: a call can move it unnamed.
        Work.append(Cells.begin(), Cells.end());
        continue;
      }
      if (carries(U))
        Work.push_back(U);
    }
    if (auto *S = dyn_cast<SelectInst>(V)) {
      Work.push_back(S->getTrueValue());  // the condition is not a carrier.
      Work.push_back(S->getFalseValue());
    } else if (auto *P = dyn_cast<PHINode>(V)) {
      for (Value *Op : P->incoming_values())
        if (!freshNotDominating(P, Op))
          Work.push_back(Op);
    } else if (auto *I = dyn_cast<Instruction>(V); I && carries(I)) {
      for (Value *Op : I->operands())
        Work.push_back(Op);
    }
  }
  return true;
}

}  // namespace cq
