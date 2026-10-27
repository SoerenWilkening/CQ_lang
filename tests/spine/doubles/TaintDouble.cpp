// TEST DOUBLE (tests/spine, cq-w0-construct). NOT the taint module. Stands in for pass/lib/taint
// while it is a stub, so the spine's straight-line lowering can be exercised end to end. Linked
// only into the test plugin libCQLowerSpineTest.so, never into libCQLower.so.
//
// Model (enough for straight-line entry functions, nothing more): forward SSA taint from cq_theta_*
// results; a cq_measure_* result is classical; the result of a call to an in-module function whose
// return value is quantum is quantum (fixed point over the module). No memory, no pointers, no
// control dependence, no clones: every tainted defined function is one entry specialization.
#include "cq/Taint.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

struct TaintInfo::Impl {
  DenseSet<const Value *> q;
  DenseSet<const Function *> tainted;
  std::vector<Specialization> specs;
};

bool Specialization::isEntry() const { return true; }

namespace {
bool isTheta(const Function *F) { return F && F->getName().starts_with("cq_theta_"); }
bool isMeasure(const Function *F) { return F && F->getName().starts_with("cq_measure_"); }
bool isSurface(const Function *F) {
  return F && (isTheta(F) || isMeasure(F) || F->getName() == "cq_phi" || F->getName().starts_with("__cq_invert_"));
}
} // namespace

TaintInfo computeTaint(Module &M, const TaintOptions &) {
  TaintInfo T;
  T.impl = std::make_shared<TaintInfo::Impl>();
  auto &q = T.impl->q;
  DenseSet<const Function *> qret;
  for (bool changed = true; changed;) {
    changed = false;
    for (Function &F : M)
      for (Instruction &I : instructions(F)) {
        if (q.count(&I))
          continue;
        bool isQ = false;
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          const Function *c = CB->getCalledFunction();
          if (isTheta(c))
            isQ = true;
          else if (isMeasure(c))
            isQ = false;
          else if (c && qret.count(c))
            isQ = true;
          else
            for (const Use &u : CB->args())
              isQ |= q.count(u.get()) != 0;
          if (CB->getType()->isVoidTy())
            isQ = false;
        } else {
          for (const Use &u : I.operands())
            isQ |= q.count(u.get()) != 0;
          if (I.getType()->isVoidTy())
            isQ = false;
        }
        if (isQ) {
          q.insert(&I);
          changed = true;
        }
        if (auto *R = dyn_cast<ReturnInst>(&I))
          if (R->getReturnValue() && q.count(R->getReturnValue()) && qret.insert(&F).second)
            changed = true;
      }
  }
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool t = false;
    for (Instruction &I : instructions(F)) {
      t |= q.count(&I) != 0;
      if (auto *CB = dyn_cast<CallBase>(&I))
        t |= isSurface(CB->getCalledFunction());
    }
    if (t) {
      T.impl->tainted.insert(&F);
      Specialization s; s.F = &F; s.mask = std::string(F.arg_size(), '0'); T.impl->specs.push_back(s);
    }
  }
  return T;
}

bool TaintInfo::isQuantum(const Value *v, const Specialization &) const { return impl->q.count(v) != 0; }
SmallVector<bool, 4> TaintInfo::fieldMask(const Value *v, const Specialization &S) const { return {isQuantum(v, S)}; }
bool TaintInfo::isTainted(const Function &F) const { return impl->tainted.count(&F) != 0; }
bool TaintInfo::controlTainted(const BasicBlock *, const Specialization &) const { return false; }
ArrayRef<Specialization> TaintInfo::specializations() const { return impl->specs; }
const Specialization *TaintInfo::calleeSpecialization(const CallBase &CB, const Specialization &) const {
  for (const Specialization &s : impl->specs)
    if (s.F == CB.getCalledFunction())
      return &s;
  return nullptr;
}
bool TaintInfo::resultQuantum(const Specialization &, unsigned) const { return false; }
ObjectId TaintInfo::objectOf(const Value *) const { return 0; }
ObjClass TaintInfo::classOf(ObjectId) const { return ObjClass::Classical; }
bool TaintInfo::mayHoldHandle(ObjectId) const { return false; }
OffsetKind TaintInfo::offsetKind(const Instruction *, const Specialization &) const { return OffsetKind::Classical; }
ArrayRef<ObjectId> TaintInfo::provenance(const Value *, const Specialization &) const { return {}; }
bool TaintInfo::isFatPointer(const Value *, const Specialization &) const { return false; }
void TaintInfo::print(raw_ostream &os) const { os << "taint double\n"; }

} // namespace cq
