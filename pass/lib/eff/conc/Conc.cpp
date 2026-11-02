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
// lowerSetjmp, lowerLongjmp: Setjmp.cpp (101's escaped-flag construction, contract at its top).
#include "../../spine/SpineInternal.h"
#include "cq/Calls.h"
#include "cq/Effects.h"
#include "cq/FatPtr.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/TargetParser/Triple.h"

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
// runs unconditionally: rule 20 makes an object stored under a quantum predicate hold a handle (the
// select into a fresh rail), so a store into classical memory under one is a broken taint invariant.
void copyClassical(LoweringContext &ctx, Instruction &I, bool dropVolatile) {
  if (I.mayWriteToMemory() && !ctx.currentPredicate().isTop())
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
void routePlain(LoweringContext &ctx, Instruction &I, const Value *ptr, StringRef what) {
  // Rule 21: a quantum tag is a fat pointer, whose accesses are rule 20's per object (fatptr).
  if (spine::accessHasQuantumTag(ctx, ptr)) {
    if (auto *ld = dyn_cast<LoadInst>(&I))
      return fatptr::lowerLoad(ctx, *ld);
    return fatptr::lowerStore(ctx, cast<StoreInst>(I));
  }
  (void)what;
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
// mem-qram (rmwQramCell). atomicrmw yields the old value; cmpxchg yields {old, old == cmp} and stores
// select(old == cmp, new, old).
void lowerQramRmw(LoweringContext &ctx, Instruction &I, const Value *ptr) {
  auto *rmw = dyn_cast<AtomicRMWInst>(&I);
  auto *cx = dyn_cast<AtomicCmpXchgInst>(&I);
  Type *ty = rmw ? rmw->getValOperand()->getType() : cx->getNewValOperand()->getType();
  RailType w = railTypeOf(ty);
  auto shape2 = [](const Operand &a, const Operand &b) -> std::string {
    return a.handle && b.handle ? "" : a.handle ? "hl" : "lh";
  };
  auto bin = [&](const char *op, Operand a, Operand b) {
    abi::TemplateSpec sp;
    sp.op = op;
    sp.w = w;
    sp.shape = shape2(a, b);
    return Operand{ctx.emitTemplate(sp, {a, b}), true};
  };
  auto cmp = [&](const char *pred, Operand a, Operand b) {
    abi::TemplateSpec sp;
    sp.op = "icmp";
    sp.pred = pred;
    sp.w = w;
    sp.shape = shape2(a, b);
    return Operand{ctx.emitTemplate(sp, {a, b}), true};
  };
  auto sel = [&](Operand c, Operand t, Operand f) {
    abi::TemplateSpec sp;
    sp.op = "select";
    sp.w = w;
    sp.shape = t.handle && f.handle ? "" : std::string(t.handle ? "h" : "l") + (f.handle ? "h" : "l");
    return Operand{ctx.emitTemplate(sp, {c, t, f}), true};
  };
  auto lit = [&](uint64_t v) { return Operand{ConstantInt::get(ty, v), false}; };
  Operand eqFlag;
  auto combine = [&](Value *oldV) -> Value * {
    Operand old{oldV, true};
    if (cx) {
      Operand c = ctx.operand(cx->getCompareOperand()), v = ctx.operand(cx->getNewValOperand());
      eqFlag = cmp("eq", old, c);
      Operand r = sel(eqFlag, v, old);
      return r.v;
    }
    Operand v = ctx.operand(rmw->getValOperand());
    Operand r;
    switch (rmw->getOperation()) {
    case AtomicRMWInst::Xchg:
      // The cell takes v (a store copies it in, v unchanged); a classical v is first a seed (rule 7).
      if (v.handle) {
        r = v;
      } else {
        CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {v.v});
        ctx.unc().recordSeed(seed);
        r = Operand{seed, true};
      }
      break;
    case AtomicRMWInst::Add: r = bin("add", old, v); break;
    case AtomicRMWInst::Sub: r = bin("sub", old, v); break;
    case AtomicRMWInst::And: r = bin("and", old, v); break;
    case AtomicRMWInst::Or: r = bin("or", old, v); break;
    case AtomicRMWInst::Xor: r = bin("xor", old, v); break;
    case AtomicRMWInst::Nand: r = bin("xor", bin("and", old, v), lit(~uint64_t(0))); break;
    case AtomicRMWInst::Max: r = bin("smax", old, v); break;
    case AtomicRMWInst::Min: r = bin("smin", old, v); break;
    case AtomicRMWInst::UMax: r = bin("umax", old, v); break;
    case AtomicRMWInst::UMin: r = bin("umin", old, v); break;
    case AtomicRMWInst::FAdd: r = bin("fadd", old, v); break;
    case AtomicRMWInst::FSub: r = bin("fsub", old, v); break;
    case AtomicRMWInst::FMax: r = bin("fmax", old, v); break;
    case AtomicRMWInst::FMin: r = bin("fmin", old, v); break;
    case AtomicRMWInst::UIncWrap:   // old >= v ? 0 : old + 1
      r = sel(cmp("uge", old, v), lit(0), bin("add", old, lit(1)));
      break;
    case AtomicRMWInst::UDecWrap: {  // old == 0 || old > v ? v : old - 1
      Operand z = cmp("eq", old, lit(0)), g = cmp("ugt", old, v);
      abi::TemplateSpec orS;
      orS.op = "or";
      orS.w = RailType{Kind::Int, 1};
      Operand zg{ctx.emitTemplate(orS, {z, g}), true};
      r = sel(zg, v, bin("sub", old, lit(1)));
      break;
    }
    default:
      internalError("eff-conc: an atomicrmw operation LLVM 19 does not define", &I);
    }
    return r.v;
  };
  Value *old = mem::rmwQramCell(ctx, I, ptr, ty, combine);
  if (cx)
    ctx.bindFields(&I, {Operand{old, true}, eqFlag});
  else
    ctx.bind(&I, old);
}

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
    return routePlain(ctx, I, ptr, "an unobservable volatile access");
  }
  if (q)
    unimplemented("eff-conc: awaiting owner ruling: SPEC_ISSUES An observable volatile access involving quantum "
                  "data",
                  &I);
  copyClassical(ctx, I, /*dropVolatile=*/false);
}

void lowerAtomic(LoweringContext &ctx, Instruction &I) {
  if (isa<CallBase>(I))
    internalError("eff-conc: lowerAtomic of a call (calls::classify has no atomic call class: a bodiless "
                  "__atomic_* callee is rule 27's or rule 16's)",
                  &I);
  if (isa<LoadInst>(I) || isa<StoreInst>(I)) {
    if (!I.isAtomic())
      internalError("eff-conc: lowerAtomic of a non-atomic load or store", &I);
    const Value *ptr = getLoadStorePointerOperand(&I);
    if (isa<LoadInst>(I) ? cast<LoadInst>(I).isVolatile() : cast<StoreInst>(I).isVolatile())
      return lowerVolatile(ctx, I);
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
    if (spine::accessHasQuantumTag(ctx, ptr))
      unimplemented("eff-conc: an atomic read-modify-write through a fat pointer (rule 24's load + op + store "
                    "over rule 21's per-object accesses; fatptr exposes no read-modify-write, cq-z28j)",
                    &I);
    bool slot = false, qram = false, classical = false;
    for (ObjectId o : ctx.T.provenance(ptr, ctx.S)) {
      ObjClass k = ctx.T.classOf(o);
      (k == ObjClass::Slot ? slot : k == ObjClass::Qram ? qram : classical) = true;
    }
    if (slot && !qram && !classical)
      return mem::lowerSlotAtomic(ctx, I);
    if (!slot && !qram)
      internalError("eff-conc: a read-modify-write with quantum data on memory taint classified Classical (rule "
                    "20: a quantum value or offset stored makes it a slot or a QRAM)",
                    &I);
    if (!qram || slot || classical)
      internalError("eff-conc: a read-modify-write on a pointer to several objects that is not a fat pointer "
                    "(rule 21: a pointer chosen among objects by quantum data carries a quantum tag)",
                    &I);
    return lowerQramRmw(ctx, I, ptr);
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
  LLVMContext &C = ctx.M.getContext();
  if (n == "pthread_create" && CB.arg_size() == 4) {
    // Rule 24 (106): the sequential schedule runs the start routine here: a direct call f(p), no host
    // thread. A quantum job is the call of its clone (C1), a classical one the original's call. The status
    // is 0. The thread id *t carries the start routine's result to pthread_join (a classical job; the
    // pthread_t is a pointer on Darwin, an integer on Linux).
    const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
    if (cs && !cs->isEntry()) {
      // Its result is the clone's (C1 binds none): a join asking for it is not built.
      if (const CallBase *J = joinAskingResult(ctx.M))
        unimplemented("eff-conc: pthread_join asking for the result of a quantum job (rule 24; C1 binds no result "
                      "of the clone call)",
                      J);
      unsigned argMap[1] = {3};
      calls::lowerLiftedVia(ctx, CB, argMap);
      return bindZero();
    }
    Value *fn = CB.getArgOperand(2)->stripPointerCasts();
    auto *fnF = dyn_cast<Function>(fn);
    Operand fnOp = ctx.operand(CB.getArgOperand(2));
    Operand p = ctx.operand(CB.getArgOperand(3));
    bool quantumJob = fnOp.handle || p.handle || ctx.T.isFatPointer(CB.getArgOperand(3), ctx.S);
    for (ObjectId o : ctx.T.provenance(CB.getArgOperand(3), ctx.S))
      quantumJob |= ctx.T.classOf(o) != ObjClass::Classical;
    if (quantumJob && fnF && !fnF->isDeclaration())
      internalError("eff-conc: a defined start routine handed quantum data with no clone from taint", &CB);
    if (quantumJob && !fnF)
      unimplemented("eff-conc: pthread_create of a start routine chosen at run time handed quantum data (rule 24 "
                    "with rule 19's indirect call; calls exposes no indirect call through a site, cq-20fz)",
                    &CB);
    if (quantumJob)
      unimplemented("eff-conc: pthread_create of a start routine with no body handed quantum memory (rule 24 "
                    "with rule 27's declared clone; calls exposes no declared call through a site, cq-20fz)",
                    &CB);
    // The start routine's type is void *(void *) (C17 7.26.5.1 thrd_start_t, POSIX); a call through
    // another type is undefined behaviour, outside the domain.
    Type *ptrTy = PointerType::getUnqual(C);
    FunctionType *ft = FunctionType::get(ptrTy, {ptrTy}, false);
    Value *rv = ctx.B().CreateCall(ft, fnF ? static_cast<Value *>(fnF) : fnOp.v, {p.v});
    Operand t = ctx.operand(CB.getArgOperand(0));
    if (joinAskingResult(ctx.M) && !t.handle && !isa<ConstantPointerNull>(t.v)) {
      Type *tidTy = ctx.M.getDataLayout().getIntPtrType(C);
      if (Triple(ctx.M.getTargetTriple()).isOSDarwin())
        ctx.B().CreateStore(rv, t.v);
      else
        ctx.B().CreateStore(ctx.B().CreatePtrToInt(rv, tidTy), t.v);
    }
    return bindZero();
  }
  if (n == "pthread_join" && CB.arg_size() == 2) {
    // Rule 24: the job ran at its create site; nothing joins. A requested exit value is the start
    // routine's result, which pthread_create left in the thread id.
    auto *rv = dyn_cast<Constant>(CB.getArgOperand(1));
    if (!rv || !rv->isNullValue()) {
      Operand tid = ctx.operand(CB.getArgOperand(0));
      Operand out = ctx.operand(CB.getArgOperand(1));
      if (tid.handle || out.handle)
        unimplemented("eff-conc: pthread_join of a thread id or result pointer that is quantum (rule 24)", &CB);
      Value *res = tid.v->getType()->isPointerTy() ? tid.v
                                                   : ctx.B().CreateIntToPtr(tid.v, PointerType::getUnqual(C));
      ctx.B().CreateStore(res, out.v);
    }
    return bindZero();
  }
  if (n == "pthread_mutex_lock" || n == "pthread_mutex_unlock" || n == "pthread_mutex_trylock")
    return bindZero();   // rule 24: one thread, no contention: no-ops
  internalError("eff-conc: lowerThreadCall of a call calls::classify does not class as Thread", &CB);
}

} // namespace cq::conc
