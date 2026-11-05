// Module eff-conc (cq-w1-eff-conc): CR rule 24, threads, atomics, volatile, setjmp/longjmp.
//
// Single-thread collapse (rule 24; 94, 106 headers; Bennett.jl's stance, owner 2026-10-20): a reversible
// program is a function of its inputs, so the sequential schedule is taken and every concurrency
// primitive keeps only its single-thread meaning.
//
// lowerVolatile: a volatile load or store reaching this module (the spine sends every volatile access of
// a lowered function here).
//  - The accessed object is UNOBSERVABLE when the pointer's underlying object is an alloca or a global
//    with local linkage that is not externally initialized, and every transitive use of its address is
//    an access through it (load, store to it), address arithmetic (GEP, cast, phi, select, as instruction
//    or constant expression) or a lifetime marker: nothing outside the program can see it (48: the
//    internal never-written @tiny; 32: the non-escaping volatile local). LLVM's CaptureTracking is not
//    used, because it counts every volatile access as a capture.
//  - An unobservable access is the plain access (rule 24); a store into an unobservable object nothing
//    loads from is dead and emits nothing (169). Otherwise, with nothing quantum (classical pointer,
//    classical value, classical memory) it is copied without `volatile` (48's reference: "a plain
//    classical load"); otherwise it is routed as the plain access is (rule 20): a slot object to
//    mem::lowerSlotLoad/Store, a QRAM object to mem::lowerQramLoad/Store, a quantum offset into
//    classical memory to mem::lowerQromLoad.
//  - An observable access with nothing quantum is copied unchanged, `volatile` kept: the host performs
//    it. An observable access with quantum data (rule 24 at f684858, cq-py5f) is a host effect: a store
//    is the rule-16 effect entry `volatile_store` (tape::lowerVolatileStore: the address an i64, the value
//    its fields, under the predicate); a load is the host read at its program point, unguarded, merged as
//    any value (a seed rail where taint reads a quantum value; at a quantum address the plain read of
//    every candidate, rule 21).
//
// lowerAtomic: an atomic load/store is the plain access (rule 24, 94): classical ones are copied
// unchanged (the host performs the atomic op, which is the plain op single-threaded); quantum ones are
// routed as lowerVolatile routes an unobservable access. atomicrmw and cmpxchg on a slot object are
// mem::lowerSlotAtomic (M4, 94: load + op + store, cmpxchg's icmp eq + select + store); in QRAM or
// classical memory with quantum data, and a call classified Atomic, they are unimplemented.
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

// Every transitive use of the object's address stays inside the program as an access through it.
bool addressStaysInside(const Value *obj) {
  SmallVector<const Value *, 8> work{obj};
  SmallPtrSet<const Value *, 16> seen{obj};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const Use &u : v->uses()) {
      const User *usr = u.getUser();
      if (isa<LoadInst>(usr))
        continue;
      if (auto *st = dyn_cast<StoreInst>(usr)) {
        if (u.getOperandNo() == StoreInst::getPointerOperandIndex())
          continue;
        return false;   // the address itself is stored
      }
      if (auto *II = dyn_cast<IntrinsicInst>(usr)) {
        Intrinsic::ID id = II->getIntrinsicID();
        if (id == Intrinsic::lifetime_start || id == Intrinsic::lifetime_end)
          continue;
        return false;
      }
      if (isa<GEPOperator>(usr) || isa<BitCastOperator>(usr) || isa<AddrSpaceCastOperator>(usr) ||
          isa<PHINode>(usr) || isa<SelectInst>(usr)) {
        if (isa<SelectInst>(usr) && u.getOperandNo() == 0)
          return false;
        if (seen.insert(usr).second)
          work.push_back(usr);
        continue;
      }
      return false;   // a call, ptrtoint, compare, return, aggregate, ... : the address escapes
    }
  }
  return true;
}

bool unobservable(const Value *ptr) {
  const Value *obj = getUnderlyingObject(ptr, /*MaxLookup=*/0);
  if (auto *gv = dyn_cast<GlobalVariable>(obj)) {
    if (!gv->hasLocalLinkage() || gv->isExternallyInitialized())
      return false;
  } else if (!isa<AllocaInst>(obj)) {
    return false;
  }
  return addressStaysInside(obj);
}

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

bool involvesQuantum(LoweringContext &ctx, Instruction &I, const Value *ptr) {
  if (!I.getType()->isVoidTy() && ctx.T.isQuantum(&I, ctx.S))
    return true;
  for (const Use &u : I.operands())
    if (ctx.T.isQuantum(u.get(), ctx.S))
      return true;
  return false;
}

// The classical instruction in the new IR, its operands remapped; `volatile` dropped when asked. A store
// runs unconditionally: rule 20 makes an object stored under a quantum predicate hold a handle (the
// select into a fresh rail), so a store into classical memory under one is a broken taint invariant. A load
// writes nothing: LLVM's mayWriteToMemory counts a volatile or ordered atomic load (cq-il07: musl exp10l's
// FORCE_EVAL read of the constant twom10000 under a quantum predicate), which rule 24 makes the plain read.
// A rule-14 trip rail is a quantum predicate too (cq-ro82: currentPredicate() does not see it); a host call
// there is rule 19's, executed unguarded.
void copyClassical(LoweringContext &ctx, Instruction &I, bool dropVolatile) {
  if (!isa<LoadInst>(I) && I.mayWriteToMemory() &&
      (!ctx.currentPredicate().isTop() || (spine::shared(ctx).tripFlag && !isa<CallBase>(I))))
    internalError("eff-conc: a store into memory taint classified Classical under a quantum predicate (rule 20: "
                  "the object holds a handle)",
                  &I);
  Instruction *n = I.clone();
  for (unsigned i = 0; i < n->getNumOperands(); ++i) {
    Value *v = I.getOperand(i);
    if (isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      continue;
    Operand op = ctx.operand(v);
    if (op.handle)
      internalError("eff-conc: a rail handle reaching a classical access", &I);
    n->setOperand(i, op.v);
  }
  if (dropVolatile) {
    if (auto *ld = dyn_cast<LoadInst>(n))
      ld->setVolatile(false);
    else if (auto *st = dyn_cast<StoreInst>(n))
      st->setVolatile(false);
  }
  if (!I.getName().empty())
    n->setName(I.getName());
  ctx.B().Insert(n);
  if (!I.getType()->isVoidTy())
    ctx.bind(&I, n);
}

// The plain access (rule 20/21 routing) of an access with something quantum in it.
void routePlain(LoweringContext &ctx, Instruction &I) {
  if (auto *ld = dyn_cast<LoadInst>(&I))
    return bus::lowerLoad(ctx, *ld);
  bus::lowerStore(ctx, cast<StoreInst>(I));
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

// Rule 24 (94) on a QRAM cell: the plain read-modify-write, the old value read and the new one stored by

} // namespace

void lowerVolatile(LoweringContext &ctx, Instruction &I) {
  const Value *ptr = getLoadStorePointerOperand(&I);
  if (!ptr || !(isa<LoadInst>(I) ? cast<LoadInst>(I).isVolatile() : cast<StoreInst>(I).isVolatile()))
    internalError("eff-conc: lowerVolatile of an instruction that is not a volatile load or store", &I);
  // A volatile atomic access is both (rule 24): atomic is the plain op single-threaded, so it is read as
  // the volatile access it is; a copied access keeps its atomic ordering.
  bool q = involvesQuantum(ctx, I, ptr);
  if (unobservable(ptr)) {
    // The plain access (rule 24). A store into an object nothing reads and nothing outside sees is dead:
    // nothing (169's FORCE_EVAL in ilogb, stored volatile under a quantum predicate: "the volatile store
    // stays nothing").
    if (isa<StoreInst>(I) && !everRead(ptr))
      return;
    if (!q)
      return copyClassical(ctx, I, /*dropVolatile=*/true);
    return routePlain(ctx, I);
  }
  if (!q)
    return copyClassical(ctx, I, /*dropVolatile=*/false);
  // Rule 24 at f684858 (cq-py5f): an observable access with quantum data is a host effect; the object is
  // the host's, not the program's (its content is what the outside makes it).
  bool qAddr = ctx.T.isQuantum(ptr, ctx.S);
  if (auto *st = dyn_cast<StoreInst>(&I)) {
    // A store: the rule-16 effect entry `volatile_store` under the predicate, the address an i64 (rule 21's
    // address of a quantum pointer, a rail).
    Operand addr;
    if (qAddr) {
      addr = bus::address(ctx, ptr);
    } else {
      Operand p = ctx.operand(ptr);
      if (p.handle)
        internalError("eff-conc: a pointer with a handle that carries no quantum tag", &I);
      addr = Operand{ctx.B().CreatePtrToInt(p.v, Type::getInt64Ty(ctx.M.getContext())), false};
    }
    return tape::lowerVolatileStore(ctx, *st, addr);
  }
  // A load: the host read at its program point, unguarded (rule 19's classical call under a predicate),
  // merged as any value: the volatile load itself, a seed rail (rule 7) where taint reads a quantum value.
  // At a quantum address (rule 21) the read of every candidate cell, merged on the tag: the plain read.
  if (qAddr)
    return routePlain(ctx, I);
  Instruction *n = I.clone();
  for (unsigned i = 0; i < n->getNumOperands(); ++i) {
    Operand op = ctx.operand(I.getOperand(i));
    if (op.handle)
      internalError("eff-conc: a rail handle as the address of a host read", &I);
    n->setOperand(i, op.v);
  }
  n->setName(I.getName());
  ctx.B().Insert(n);
  if (ctx.T.isQuantum(&I, ctx.S) && (I.getType()->isIntegerTy() || I.getType()->isFloatingPointTy())) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(I.getType())}, {n});
    ctx.unc().recordSeed(seed);
    return ctx.bind(&I, seed);
  }
  ctx.bind(&I, n);
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
