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
//  - An unobservable access is the plain access (rule 24): with nothing quantum (classical pointer,
//    classical value, classical memory) it is copied without `volatile` (48's reference: "a plain
//    classical load"); otherwise it is routed as the plain access is (rule 20): a slot object to
//    mem::lowerSlotLoad/Store, a QRAM object to mem::lowerQramLoad/Store, a quantum offset into
//    classical memory to mem::lowerQromLoad.
//  - An observable access with nothing quantum is copied unchanged, `volatile` kept: the host performs
//    it. An observable access with anything quantum has no single-thread meaning the rules give (the
//    outside observer would see a quantum value): unimplemented.
//  - A volatile access through a fat pointer (a quantum tag, rule 21) is unimplemented: the routing of
//    fat pointers is the spine's (its quantumTag), not reproduced here.
//
// lowerAtomic: an atomic load/store is the plain access (rule 24, 94): classical ones are copied
// unchanged (the host performs the atomic op, which is the plain op single-threaded); quantum ones are
// routed as lowerVolatile routes an unobservable access. atomicrmw and cmpxchg on a slot object are
// mem::lowerSlotAtomic (M4, 94: load + op + store, cmpxchg's icmp eq + select + store); in QRAM or
// classical memory with quantum data, and a call classified Atomic, they are unimplemented.
//
// lowerThreadCall (rule 24, 106): pthread_create(t, attr, f, p) is the direct call f(p) (a quantum job:
// calls::lowerLiftedVia with argMap {3}; a classical one: the original), status 0; pthread_join with a null
// result pointer and the mutex locks are no-ops, status 0.
// lowerSetjmp, lowerLongjmp: unimplemented. The setjmp diamond with an escaped flag
// (101) needs the taint/pred DeadEnd fix (cq-jwdf: `call @longjmp; unreachable` is taken as a dead end,
// so code after `if (q) longjmp(...)` would get the top predicate and a wrong circuit).
#include "cq/Calls.h"
#include "cq/Effects.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"

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

bool involvesQuantum(LoweringContext &ctx, Instruction &I, const Value *ptr) {
  if (!I.getType()->isVoidTy() && ctx.T.isQuantum(&I, ctx.S))
    return true;
  for (const Use &u : I.operands())
    if (ctx.T.isQuantum(u.get(), ctx.S))
      return true;
  if (ctx.T.isFatPointer(ptr, ctx.S))
    return true;
  for (ObjectId o : ctx.T.provenance(ptr, ctx.S))
    if (ctx.T.classOf(o) != ObjClass::Classical)
      return true;
  if (isa<LoadInst>(I) && ctx.T.offsetKind(&I, ctx.S) == OffsetKind::Quantum)
    return true;
  return false;
}

// The classical instruction in the new IR, its operands remapped; `volatile` dropped when asked. A store
// runs unconditionally, so one under a quantum predicate is unimplemented (taint makes memory written
// under a quantum arm non-classical; reaching here with one is a shape this module does not lower).
void copyClassical(LoweringContext &ctx, Instruction &I, bool dropVolatile) {
  if (isa<StoreInst>(I) && !ctx.currentPredicate().isTop())
    unimplemented("eff-conc: a classical volatile or atomic store under a quantum predicate", &I);
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
void routePlain(LoweringContext &ctx, Instruction &I, const Value *ptr, StringRef what) {
  if (ctx.T.isFatPointer(ptr, ctx.S) || ctx.T.isQuantum(ptr, ctx.S))
    unimplemented(("eff-conc: " + what + " through a fat pointer (rule 21; the routing is the spine's)").str(),
                  &I);
  bool qram = false, slot = false;
  for (ObjectId o : ctx.T.provenance(ptr, ctx.S)) {
    qram |= ctx.T.classOf(o) == ObjClass::Qram;
    slot |= ctx.T.classOf(o) == ObjClass::Slot;
  }
  if (auto *ld = dyn_cast<LoadInst>(&I)) {
    if (qram)
      return mem::lowerQramLoad(ctx, *ld);
    if (slot)
      return mem::lowerSlotLoad(ctx, *ld);
    if (ctx.T.offsetKind(&I, ctx.S) == OffsetKind::Quantum)
      return mem::lowerQromLoad(ctx, *ld);
    internalError("eff-conc: a load from classical memory at a classical offset that taint calls quantum", &I);
  }
  auto *st = cast<StoreInst>(&I);
  if (qram)
    return mem::lowerQramStore(ctx, *st);
  if (slot)
    return mem::lowerSlotStore(ctx, *st);
  internalError("eff-conc: a quantum value stored into memory taint classified Classical", &I);
}

} // namespace

void lowerVolatile(LoweringContext &ctx, Instruction &I) {
  const Value *ptr = getLoadStorePointerOperand(&I);
  if (!ptr || !(isa<LoadInst>(I) ? cast<LoadInst>(I).isVolatile() : cast<StoreInst>(I).isVolatile()))
    internalError("eff-conc: lowerVolatile of an instruction that is not a volatile load or store", &I);
  if (cast<Instruction>(I).isAtomic())
    unimplemented("eff-conc: a volatile atomic access", &I);
  bool q = involvesQuantum(ctx, I, ptr);
  if (unobservable(ptr)) {
    if (!q)
      return copyClassical(ctx, I, /*dropVolatile=*/true);
    return routePlain(ctx, I, ptr, "an unobservable volatile access");
  }
  if (q)
    unimplemented("eff-conc: a volatile access to observable memory involving quantum data (rule 24 makes "
                  "only an unobservable volatile access plain)",
                  &I);
  copyClassical(ctx, I, /*dropVolatile=*/false);
}

void lowerAtomic(LoweringContext &ctx, Instruction &I) {
  if (isa<CallBase>(I))
    unimplemented("eff-conc: an atomic library call (rule 24)", &I);
  if (isa<LoadInst>(I) || isa<StoreInst>(I)) {
    if (!I.isAtomic())
      internalError("eff-conc: lowerAtomic of a non-atomic load or store", &I);
    const Value *ptr = getLoadStorePointerOperand(&I);
    if (isa<LoadInst>(I) ? cast<LoadInst>(I).isVolatile() : cast<StoreInst>(I).isVolatile())
      unimplemented("eff-conc: a volatile atomic access", &I);
    if (!involvesQuantum(ctx, I, ptr))
      return copyClassical(ctx, I, /*dropVolatile=*/false);
    return routePlain(ctx, I, ptr, "an atomic access");
  }
  if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) {
    // Rule 24 (94): the plain read-modify-write. Classical: the host performs it.
    const Value *ptr = isa<AtomicRMWInst>(I) ? cast<AtomicRMWInst>(I).getPointerOperand()
                                             : cast<AtomicCmpXchgInst>(I).getPointerOperand();
    if (!involvesQuantum(ctx, I, ptr))
      return copyClassical(ctx, I, /*dropVolatile=*/false);
    if (ctx.T.isFatPointer(ptr, ctx.S) || ctx.T.isQuantum(ptr, ctx.S))
      unimplemented("eff-conc: an atomic read-modify-write through a fat pointer (rule 21)", &I);
    bool slot = false, other = false;
    for (ObjectId o : ctx.T.provenance(ptr, ctx.S))
      (ctx.T.classOf(o) == ObjClass::Slot ? slot : other) = true;
    if (slot && !other)
      return mem::lowerSlotAtomic(ctx, I);
    unimplemented(std::string("eff-conc: ") + (isa<AtomicRMWInst>(I) ? "atomicrmw" : "cmpxchg") +
                      " on quantum data in memory other than one slot object (QRAM or classical memory, rule 24)",
                  &I);
  }
  internalError("eff-conc: lowerAtomic of an instruction that is not atomic", &I);
}

void lowerThreadCall(LoweringContext &ctx, CallBase &CB) {
  const Function *g = CB.getCalledFunction();
  StringRef n = g ? g->getName() : StringRef();
  if (n.starts_with("\01_"))
    n = n.drop_front(2);   // Darwin's spelling of some libc symbols (106: "\01_pthread_join")
  auto bindZero = [&] {
    if (!CB.getType()->isIntegerTy())
      internalError("eff-conc: a thread call whose result is not an int status", &CB);
    ctx.bind(&CB, ConstantInt::get(CB.getType(), 0));
  };
  if (n == "pthread_create" && CB.arg_size() == 4) {
    // Rule 24 (106): the sequential schedule runs the start routine here: a direct call f(p), no host
    // thread; the pthread_t is never written. A quantum job is the call of its clone (C1), a classical
    // one the original's call. The status is 0.
    auto *f = dyn_cast<Function>(CB.getArgOperand(2)->stripPointerCasts());
    if (!f || f->isDeclaration() || f->arg_size() != 1)
      unimplemented("eff-conc: pthread_create of a start routine that is not a defined function of one formal "
                    "(rule 24)",
                    &CB);
    const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
    if (cs && !cs->isEntry()) {
      unsigned argMap[1] = {3};
      calls::lowerLiftedVia(ctx, CB, argMap);
    } else {
      Operand p = ctx.operand(CB.getArgOperand(3));
      if (p.handle)
        internalError("eff-conc: a classical thread job handed a rail", &CB);
      ctx.B().CreateCall(const_cast<Function *>(f), {p.v});
    }
    return bindZero();
  }
  if (n == "pthread_join" && CB.arg_size() == 2) {
    // Rule 24: the job ran at its create site; nothing joins. A requested exit value is not built.
    auto *rv = dyn_cast<Constant>(CB.getArgOperand(1));
    if (!rv || !rv->isNullValue())
      unimplemented("eff-conc: pthread_join asking for the start routine's result (rule 24)", &CB);
    return bindZero();
  }
  if (n == "pthread_mutex_lock" || n == "pthread_mutex_unlock" || n == "pthread_mutex_trylock")
    return bindZero();   // rule 24: one thread, no contention: no-ops
  unimplemented("eff-conc: a thread call other than pthread_create, pthread_join or a mutex lock (rule 24)", &CB);
}

void lowerSetjmp(LoweringContext &, CallBase &CB) {
  unimplemented("eff-conc: setjmp in a lowered function (rule 24, 101: the escaped-flag diamond; blocked "
                "on cq-jwdf, longjmp is not a dead end)",
                &CB);
}

void lowerLongjmp(LoweringContext &, CallBase &CB) {
  unimplemented("eff-conc: longjmp under a quantum predicate (rule 24, 101: an escaped-flag result; blocked "
                "on cq-jwdf, longjmp is not a dead end)",
                &CB);
}

} // namespace cq::conc
