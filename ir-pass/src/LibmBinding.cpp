// LibmBinding.cpp — see LibmBinding.h (bd test_C_libtooling-3c6m.72).

#include "LibmBinding.h"

#include "IntrinsicLowering.h"
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"

#include <string>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

constexpr const char *kBundlePrefix = "__cq_libm_";

// The libm width suffix of a floating-point type: float `f`, double none,
// x86 long double `l`. Any other type has no math.h spelling.
bool libmSuffix(const Type *T, std::string &Suffix) {
  if (T->isFloatTy())
    Suffix = "f";
  else if (T->isDoubleTy())
    Suffix = "";
  else if (T->isX86_FP80Ty())
    Suffix = "l";
  else
    return false;
  return true;
}

// The math.h spelling this call reaches, or empty. A declared function is its
// own name. An intrinsic is the libm function LangRef defines it equal to: its
// base name without `llvm.`, suffixed by the width of its first floating-point
// operand (`llvm.lround.i64.f64` takes a double, so `lround`).
std::string libmSpelling(const CallInst &CI) {
  const Function *Callee = CI.getCalledFunction();
  if (!Callee || !Callee->isDeclaration())
    return {};
  if (!Callee->isIntrinsic())
    return Callee->getName().str();
  StringRef Base = Intrinsic::getBaseName(Callee->getIntrinsicID());
  if (!Base.consume_front("llvm."))
    return {};
  for (const Value *Arg : CI.args()) {
    std::string Suffix;
    if (libmSuffix(Arg->getType(), Suffix))
      return (Base + Suffix).str();
  }
  return {};
}

bool callableAs(const Function *Body, const CallInst &CI) {
  return Body && !Body->isDeclaration() &&
         Body->getFunctionType() == CI.getFunctionType() &&
         Body->getCallingConv() == CI.getCallingConv();
}

// The body this call binds to when an operand is tainted, or null: the ONE
// spelling of the binding question (R12), asked by the binder (with taint) and
// by the early sweep (whatever the taint).
//  * A program's own EXTERNAL definition of the spelling wins: under C linkage
//    it IS the function the call names, so the quantum call lifts that source
//    (CLAUDE R14). An external alias binds its aliasee; an ifunc (resolved at
//    load time) has no body to lift, so the call binds nothing and fails
//    loudly (review round 3). A definition with local linkage is some TU's
//    private helper (`static double sin(double)` in a file that does not
//    include math.h is valid C), never the math.h function: review round 2
//    measured a quantum `sin` lifting such a helper (x+1), verify-clean.
//    (cqc's one-module build lets such a helper capture other TUs' classical
//    libcalls; that pre-existing driver defect is bd 3c6m.76.)
//  * Otherwise only a PUBLIC bundle body binds. tools/libm_bundle.py keeps
//    exactly the math.h entry points external; a helper openlibm declared
//    `static` (or that the bundle internalized) never binds. Measured, review
//    round 1: `llvm.powi.f80.i32` spelled `powil`, openlibm's private
//    `static long double powil(long double, int)` helper of `powl`, which
//    returns LDBL_MAX where llvm.powi returns inf, and is `fastcc`.
Function *libmBodyFor(const CallInst &CI, Module &M) {
  // The hardware route keeps priority (CLAUDE R14).
  if (isa<IntrinsicInst>(CI) && isCuratedReversibleIntrinsic(&CI))
    return nullptr;
  const std::string Name = libmSpelling(CI);
  if (Name.empty())
    return nullptr;
  if (const Function *Callee = CI.getCalledFunction();
      Callee && Callee->isIntrinsic())
    if (GlobalValue *GV = M.getNamedValue(Name);
        GV && !GV->isDeclaration() && !GV->hasLocalLinkage()) {
      Function *Own = dyn_cast<Function>(GV);
      if (auto *GA = dyn_cast<GlobalAlias>(GV))
        Own = dyn_cast_or_null<Function>(GA->getAliaseeObject());
      return callableAs(Own, CI) ? Own : nullptr;  // an ifunc: nullptr, loud.
    }
  Function *Body = M.getFunction(kBundlePrefix + Name);
  if (!callableAs(Body, CI) || Body->hasLocalLinkage())
    return nullptr;
  return Body;
}

bool hasTaintedOperand(const CallInst &CI, const TaintSet &taint) {
  for (const Value *Arg : CI.args())
    if (taint.Tainted.count(Arg))
      return true;
  return false;
}

// Retarget every tainted math.h call to its bundle body. The specializer then
// lifts the body like any visible classical callee: no inlining (owner ruling
// 2026-10-06 — a called body must lower exactly as an inlined one would, so a
// body that declines when called is a lifting gap, bd p3kd).
bool bindRound(Module &M, const TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I); CI && hasTaintedOperand(*CI, taint))
        if (Function *Body = libmBodyFor(*CI, M)) {
          CI->setCalledFunction(Body);
          // A libcall's call-site facts (`memory(none)`, …) describe the
          // library contract, not this body, which may write its own memory.
          CI->setAttributes(
              CI->getAttributes().removeFnAttributes(CI->getContext()));
          Changed = true;
        }
  return Changed;
}

// The global objects whose code or initializer uses V (through constants).
void ownersOf(const Value *V, SmallVectorImpl<const GlobalValue *> &Out,
              SmallPtrSetImpl<const Value *> &Seen) {
  for (const User *U : V->users()) {
    if (const auto *I = dyn_cast<Instruction>(U))
      Out.push_back(I->getFunction());
    else if (const auto *GV = dyn_cast<GlobalValue>(U))
      Out.push_back(GV);
    else if (Seen.insert(U).second)
      ownersOf(U, Out, Seen);
  }
}

bool isBundle(const GlobalValue *GV) {
  return GV && GV->getName().starts_with(kBundlePrefix);
}

// A bundle body or a specializer clone of one (`__cq_q___cq_libm_<name>_<mask>`):
// its classical sub-calls are the library's own and stay on injected source.
bool isBundleDerived(const Function &F) {
  StringRef N = F.getName();
  return N.starts_with(kBundlePrefix) ||
         (N.consume_front("__cq_q_") && N.starts_with(kBundlePrefix));
}

}  // namespace

bool bindLibmCalls(Module &M, TaintSet &taint, WidthDispatch &wd) {
  if (!bindRound(M, taint))
    return false;
  taint = propagate(M, wd);
  return true;
}

bool eraseUnusedLibmBodies(Module &M, bool KeepBindable) {
  bool Restored = false;
  // At the end, a call outside the bundle that still targets a PUBLIC bundle
  // body was bound but ended classical (its operand's taint was folded away):
  // it goes back to the system libm, so classical code never runs injected
  // source (owner ruling 2026-10-06). A lifted call targets a clone instead.
  if (!KeepBindable)
    for (Function &F : M) {
      if (isBundleDerived(F))
        continue;
      for (Instruction &I : instructions(F)) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!Callee || !isBundle(Callee) || Callee->hasLocalLinkage() ||
            Callee->isDeclaration())
          continue;
        const std::string Name =
            Callee->getName().drop_front(StringRef(kBundlePrefix).size()).str();
        // A TU's private function already owning the name keeps it: renaming
        // it would re-target the module's OTHER classical libcalls it captures
        // (review round 3, bd 3c6m.76), and a declaration cannot share the
        // name. The call then stays on the injected body (internalized below),
        // the conservative side of an edge no C program reaches today.
        if (GlobalValue *Taken = M.getNamedValue(Name); Taken && Taken->hasLocalLinkage())
          continue;
        CI->setCalledFunction(M.getOrInsertFunction(Name, CI->getFunctionType()));
        Restored = true;
      }
    }
  // Mark: a bundle object is live when code outside the bundle uses it, or a
  // live bundle object does. A use-count sweep cannot free the bundle's
  // reference cycles (tgamma -> sin -> ... -> tgamma).
  SmallVector<GlobalObject *, 64> Bundle;
  for (GlobalObject &GO : M.global_objects())
    if (isBundle(&GO))
      Bundle.push_back(&GO);
  DenseMap<const GlobalValue *, SmallVector<const GlobalValue *, 4>> Owners;
  for (GlobalObject *GO : Bundle) {
    SmallPtrSet<const Value *, 8> Seen;
    ownersOf(GO, Owners[GO], Seen);
  }
  SmallPtrSet<const GlobalValue *, 32> Live;
  // Early in the pass, a body a program call could still bind to is a root
  // too: taint may reach that call only after a later pre-pass (L1).
  if (KeepBindable)
    for (Function &F : M)
      if (!isBundle(&F))
        for (Instruction &I : instructions(F))
          if (auto *CI = dyn_cast<CallInst>(&I))
            if (Function *Body = libmBodyFor(*CI, M))
              Live.insert(Body);
  for (bool Again = true; Again;) {
    Again = false;
    for (GlobalObject *GO : Bundle) {
      if (Live.count(GO))
        continue;
      for (const GlobalValue *Owner : Owners[GO])
        if ((!isBundle(Owner) || Live.count(Owner)) && Owner != GO) {
          Live.insert(GO);
          Again = true;
          break;
        }
    }
  }
  // Sweep: drop every dead object's references first, so dead cycles unlink.
  // `Function::dropAllReferences` deletes the body; it HIDES (does not
  // override) `User::dropAllReferences`, which a `GlobalObject *` call would
  // bind to statically, leaving dead bodies referencing each other while they
  // are freed one by one (measured: a use-after-free in debug-record RAUW,
  // 29 of 483 census probes, deterministic under CQ_OPT_DEBUG_ALLOC=lifo).
  SmallVector<GlobalObject *, 64> Dead;
  for (GlobalObject *GO : Bundle)
    if (!Live.count(GO))
      Dead.push_back(GO);
  for (GlobalObject *GO : Dead) {
    if (auto *F = dyn_cast<Function>(GO))
      F->dropAllReferences();
    else
      GO->dropAllReferences();
  }
  for (GlobalObject *GO : Dead) {
    GO->removeDeadConstantUsers();
    GO->eraseFromParent();
  }
  bool Changed = Restored || !Dead.empty();
  // Internalize only at the end: an early internal body could no longer bind
  // (`libmBodyFor` binds public bodies only) or be restored above.
  for (GlobalObject *GO : Bundle)
    if (!KeepBindable && Live.count(GO) && !GO->isDeclaration() &&
        !GO->hasLocalLinkage()) {
      GO->setLinkage(GlobalValue::InternalLinkage);
      Changed = true;
    }
  return Changed;
}

}  // namespace cq
