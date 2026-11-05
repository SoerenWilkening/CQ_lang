// Module eff-conc (cq-w1-eff-conc): CR rule 24, threads, atomics, volatile, setjmp/longjmp.
//
// Single-thread collapse (rule 24; 94, 106 headers; Bennett.jl's stance, owner 2026-10-20): a reversible
// program is a function of its inputs, so the sequential schedule is taken and every concurrency
// primitive keeps only its single-thread meaning.
//
// lowerVolatile: a volatile load or store reaching this module (the spine sends every volatile access of
// a lowered function here), read off the access and its pointer operand (TaintInfo::observableVolatile, rule 24).
//  - UNOBSERVABLE: the qualifier is dropped and the access is rule 20's: the plain one on a host-resident object, else
//    the bus (32). Such a store into an object nothing reads is dead and is nothing (169's FORCE_EVAL in ilogb, stored
//    volatile under a quantum predicate).
//  - OBSERVABLE, on the host, never on the bus. With a classical address, an untainted value and no quantum predicate
//    it is the instruction as it stands. A store of a rail, or under a quantum predicate, is the rule-16 effect entry
//    `volatile_store` (tape::lowerVolatileStore); a load under a quantum predicate is the host read unguarded, merged
//    as any classical arm value (taint: classical). At an address rail the store is the same entry and the load the
//    effect entry `volatile_load`, whose result rail is the value.
//
// collapseThreads (rule 24, 106): before the final taint, pthread_create(t, attr, f, p) is the call f(p)
// in the IR, pthread_join stores its result, the mutex calls are status 0 (contract at the definition);
// lowerThreadCall then never runs (an internal error).
// lowerSetjmp, lowerLongjmp: Setjmp.cpp (101's escaped-flag construction, contract at its top).
#include "Setjmp.h"
#include "../../spine/SpineInternal.h"
#include "cq/Calls.h"
#include "cq/Effects.h"
#include "cq/Bus.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Transforms/Utils/LowerAtomic.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/ADT/SetVector.h"

using namespace llvm;

namespace cq::conc {
namespace {

// Does anything read the unobservable object ptr points into (a load through any derived address)?
bool everRead(const Value *ptr) {
  const Value *obj = getUnderlyingObject(ptr, /*MaxLookup=*/0);
  SmallVector<const Value *, 8> work{obj};
  SmallPtrSet<const Value *, 16> seen{obj};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const User *usr : v->users()) {
      if (isa<LoadInst>(usr))
        return true;
      if ((isa<GEPOperator>(usr) || isa<BitCastOperator>(usr) || isa<AddrSpaceCastOperator>(usr) ||
           isa<PHINode>(usr) || isa<SelectInst>(usr)) &&
          seen.insert(usr).second)
        work.push_back(usr);
    }
  }
  return false;
}

// A pthread_join of the module that asks for the start routine's result (a non-null second argument).
const CallBase *joinAskingResult(const Module &M) {
  for (const Function &G : M)
    if (G.isDeclaration() && (G.getName() == "pthread_join" || G.getName() == "\01_pthread_join"))
      for (const User *u : G.users())
        if (auto *J = dyn_cast<CallBase>(u); J && J->arg_size() == 2 &&
                                             !(isa<Constant>(J->getArgOperand(1)) &&
                                               cast<Constant>(J->getArgOperand(1))->isNullValue()))
          return J;
  return nullptr;
}


} // namespace

void lowerVolatile(LoweringContext &ctx, Instruction &I) {
  auto *ld = dyn_cast<LoadInst>(&I);
  auto *st = dyn_cast<StoreInst>(&I);
  const Value *ptr = getLoadStorePointerOperand(&I);
  if (!ptr || !(ld ? ld->isVolatile() : st && st->isVolatile()))
    internalError("eff-conc: lowerVolatile of an instruction that is not a volatile load or store", &I);
  auto tainted = [&](const Value *v) { return ctx.T.isQuantum(v, ctx.S); };
  bool qValue = st && tainted(st->getValueOperand());
  if (!ctx.T.observableVolatile(I, ctx.S)) {
    if (st && !everRead(ptr))
      return;
    if (!bus::hostAccess(ctx, I) || qValue || (ld && tainted(ld)))
      return ld ? bus::lowerLoad(ctx, *ld) : bus::lowerStore(ctx, *st);
    Instruction *n = spine::copyClassical(ctx, I);
    if (auto *nl = dyn_cast<LoadInst>(n))
      nl->setVolatile(false);
    else
      cast<StoreInst>(n)->setVolatile(false);
    if (ld)
      ctx.bind(ld, n);
    return;
  }
  bool qAddr = tainted(ptr);
  auto address = [&]() -> Operand {
    if (qAddr)
      return bus::address(ctx, ptr);
    return Operand{ctx.B().CreatePtrToInt(ctx.operand(ptr).v, Type::getInt64Ty(ctx.M.getContext())), false};
  };
  if (st) {
    if (qValue || qAddr || ctx.S.ctl || ctx.T.controlTainted(st->getParent(), ctx.S))
      return tape::lowerVolatileStore(ctx, *st, address());
    spine::copyClassical(ctx, I);
    return;
  }
  if (qAddr)
    return tape::lowerVolatileLoad(ctx, *ld, address());
  ctx.bind(ld, spine::copyClassical(ctx, I));
}

// Rule 24 (106): the thread primitives of a tainted function, collapsed to the sequential schedule in the
// IR before the final taint. pthread_create(t, attr, f, p) is the call f(p) at its place (a direct call when
// f is a function of the type void *(void *), else an indirect one: rules 18, 19 and 27 lower it as any
// call), its result left in the thread id *t when some pthread_join of the module asks for it (the
// pthread_t a pointer on Darwin, an integer on Linux), the status 0; pthread_join(t, r) stores that result
// through r when r is not null, status 0; the mutex calls are no-ops, status 0. A call through another
// type than void *(void *) is undefined behaviour (C17 7.26.5.1 thrd_start_t, POSIX), outside the domain.
SmallVector<Function *, 8> collapseThreads(Module &M, const TaintInfo &T) {
  SmallVector<Function *, 8> out;
  auto nameOf = [](const CallBase &CB) -> StringRef {
    const Function *g = CB.getCalledFunction();
    if (!g || !g->isDeclaration())
      return "";
    StringRef n = g->getName();
    return n.starts_with("\01_") ? n.drop_front(2) : n;
  };
  const CallBase *asks = joinAskingResult(M);
  Type *tidTy = asks ? asks->getArgOperand(0)->getType() : nullptr;   // read now: the join is erased below
  LLVMContext &C = M.getContext();
  Type *ptrTy = PointerType::getUnqual(C);
  for (Function &F : M) {
    if (F.isDeclaration() || !T.isTainted(F))
      continue;
    SmallVector<CallBase *, 4> todo;
    for (Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        StringRef n = nameOf(*CB);
        if ((n == "pthread_create" && CB->arg_size() == 4) || (n == "pthread_join" && CB->arg_size() == 2) ||
            n == "pthread_mutex_lock" || n == "pthread_mutex_unlock" || n == "pthread_mutex_trylock")
          todo.push_back(CB);
      }
    for (CallBase *CB : todo) {
      StringRef n = nameOf(*CB);
      IRBuilder<> B(CB);
      if (n == "pthread_create") {
        FunctionType *ft = FunctionType::get(ptrTy, {ptrTy}, false);
        Value *fn = CB->getArgOperand(2);
        CallInst *r = B.CreateCall(ft, fn, {CB->getArgOperand(3)});
        // A start routine chosen at run time among known functions (selects and phis of them): its
        // candidates as clang records them for an indirect call (!callees), for rule 19's dispatch.
        if (!r->getCalledFunction()) {
          SmallSetVector<Function *, 4> cands;
          SmallVector<Value *, 4> work{fn};
          SmallPtrSet<Value *, 8> seen;
          bool known = true;
          while (!work.empty() && known) {
            Value *v = work.pop_back_val()->stripPointerCasts();
            if (!seen.insert(v).second)
              continue;
            if (auto *g = dyn_cast<Function>(v))
              cands.insert(g);
            else if (auto *sel = dyn_cast<SelectInst>(v))
              work.append({sel->getTrueValue(), sel->getFalseValue()});
            else if (auto *phi = dyn_cast<PHINode>(v))
              work.append(phi->incoming_values().begin(), phi->incoming_values().end());
            else
              known = false;
          }
          if (known && !cands.empty())
            r->setMetadata(LLVMContext::MD_callees, MDBuilder(C).createCallees(cands.getArrayRef()));
        }
        if (tidTy)
          B.CreateStore(tidTy->isPointerTy() ? static_cast<Value *>(r) : B.CreatePtrToInt(r, tidTy),
                        CB->getArgOperand(0));
      } else if (n == "pthread_join") {
        Value *res = CB->getArgOperand(1);
        if (!(isa<Constant>(res) && cast<Constant>(res)->isNullValue())) {
          Value *tid = CB->getArgOperand(0);
          B.CreateStore(tid->getType()->isPointerTy() ? tid : B.CreateIntToPtr(tid, ptrTy), res);
        }
      }
      if (!CB->getType()->isVoidTy())
        CB->replaceAllUsesWith(ConstantInt::get(CB->getType(), 0));
      Value *tidLoad = n == "pthread_join" ? CB->getArgOperand(0) : nullptr;
      CB->eraseFromParent();
      if (auto *ld = dyn_cast_or_null<Instruction>(tidLoad))
        RecursivelyDeleteTriviallyDeadInstructions(ld);
    }
    if (!todo.empty())
      out.push_back(&F);
  }
  return out;
}

void lowerThreadCall(LoweringContext &, CallBase &CB) {
  internalError("eff-conc: a thread call in a lowered function (rule 24: collapseThreads makes the sequential "
                "schedule before the final taint)",
                &CB);
}

} // namespace cq::conc
