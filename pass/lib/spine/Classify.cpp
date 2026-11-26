// Module spine (cq-w0-construct): loops::classify (rule 14) and calls::classify (rules 16, 18, 19,
// 22, 27, and the intrinsic routes of rules 4 and 18).
//
// calls::classify recognizes by attributes and semantics, never by name alone (rule 16):
//  - the CQ.h surface is a declaration with the CQ.h name AND the CQ.h signature;
//  - allocation, reallocation and deallocation by the callee's allockind attribute;
//  - noreturn by the attribute; returns_twice (setjmp) by the attribute;
//  - rule 16's classes of a bodiless callee: the effect entries are taint's (TaintInfo::isEffectEntry, it reads their
//    results), the rest stays the ordinary host call;
//  - intrinsics by their ID.
// A call with no quantum involvement (no quantum argument or result, no quantum predicate in scope,
// not in a _ctl clone) is Classical whatever its callee, except the CQ.h surface.
#include "SpineInternal.h"
#include "../bus/BusInternal.h"
#include "../taint/DeadEnd.h"
#include "../taint/FenvName.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace cq {

namespace {

bool quantumValue(const TaintInfo &T, const Specialization &S, const Value *v) {
  if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<InlineAsm>(v))
    return false;
  return T.isQuantum(v, S);
}

bool anyQuantumArg(const CallBase &CB, const TaintInfo &T, const Specialization &S) {
  for (const Use &u : CB.args())
    if (quantumValue(T, S, u.get()))
      return true;
  return false;
}

bool underQuantumPredicate(const CallBase &CB, const TaintInfo &T, const Specialization &S) {
  return S.ctl || T.controlTainted(CB.getParent(), S);
}

// Rule 20: a pointer that reaches no host-resident object through getelementptrs with untainted indices.
bool nonClassicalObject(const TaintInfo &T, const Specialization &S, const Value *ptr) {
  return ptr->getType()->isPointerTy() && !isa<ConstantPointerNull>(ptr) && !T.hostObjectOf(ptr, S);
}

// Rule 16: llvm.stackrestore in a scope of bus-resident objects only (one at least) is dropped; with a host-resident
// alloca in scope it restores the host stack as it stands.
bool busScope(const TaintInfo &T, const Specialization &S, const CallBase &restore) {
  SmallVector<const AllocaInst *, 4> scope;
  spine::scopeAllocas(restore, scope);
  bool any = false;
  for (const AllocaInst *A : scope) {
    if (!nonClassicalObject(T, S, A))
      return false;
    any = true;
  }
  return any;
}

// The CQ.h surface (CQ.h at the pinned spec): name and signature.
std::optional<calls::Class> surface(const Function &F) {
  if (!F.isDeclaration())
    return std::nullopt;
  StringRef n = F.getName();
  FunctionType *ft = F.getFunctionType();
  Type *dbl = Type::getDoubleTy(F.getContext());
  auto scalar = [](Type *t) { return t->isIntegerTy() || t->isFloatingPointTy(); };
  if (n.starts_with("cq_theta_") && ft->getNumParams() == 2 && !ft->isVarArg() && scalar(ft->getParamType(0)) &&
      ft->getParamType(0) == ft->getReturnType() && ft->getParamType(1) == dbl)
    return calls::Class::Theta;
  if (n.starts_with("cq_measure_") && ft->getNumParams() == 1 && !ft->isVarArg() &&
      scalar(ft->getParamType(0)) && ft->getParamType(0) == ft->getReturnType())
    return calls::Class::Measure;
  if (n == "cq_phi" && ft->getNumParams() == 1 && ft->getParamType(0) == dbl && ft->getReturnType()->isVoidTy())
    return calls::Class::Phi;
  if (n == "__cq_invert_begin" && ft->getNumParams() == 0 && ft->getReturnType()->isVoidTy())
    return calls::Class::InvertBegin;
  if (n == "__cq_invert_end" && ft->getNumParams() == 0 && ft->getReturnType()->isVoidTy())
    return calls::Class::InvertEnd;
  if (n.starts_with("cq_theta_") || n.starts_with("cq_measure_") || n == "cq_phi" ||
      n.starts_with("__cq_invert_"))
    internalError("spine: a CQ.h name with a signature CQ.h does not declare", &F);
  return std::nullopt;
}

bool isTemplateIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::fabs: case Intrinsic::copysign: case Intrinsic::sqrt: case Intrinsic::floor:
  case Intrinsic::ceil: case Intrinsic::trunc: case Intrinsic::rint: case Intrinsic::round:
  case Intrinsic::maxnum: case Intrinsic::minnum: case Intrinsic::fma: case Intrinsic::fmuladd:
  case Intrinsic::fshl: case Intrinsic::fshr: case Intrinsic::abs: case Intrinsic::ctlz:
  case Intrinsic::cttz: case Intrinsic::ctpop: case Intrinsic::bswap: case Intrinsic::bitreverse: case Intrinsic::smax:
  case Intrinsic::smin: case Intrinsic::umax: case Intrinsic::umin: case Intrinsic::uadd_sat:
  case Intrinsic::usub_sat: case Intrinsic::sadd_sat: case Intrinsic::ssub_sat: case Intrinsic::uadd_with_overflow: case Intrinsic::sadd_with_overflow:
  case Intrinsic::umul_with_overflow: case Intrinsic::smul_with_overflow:
  case Intrinsic::usub_with_overflow: case Intrinsic::ssub_with_overflow: case Intrinsic::is_fpclass:
    return true;
  default:
    return false;
  }
}

// Intrinsics with no operation of their own, or a composition of rule 4 templates (spine's
// lowerHintIntrinsic in Opcode.cpp).
bool isHintIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::expect: case Intrinsic::expect_with_probability: case Intrinsic::ssa_copy:
  case Intrinsic::annotation: case Intrinsic::assume: case Intrinsic::prefetch: case Intrinsic::var_annotation:
  case Intrinsic::sideeffect: case Intrinsic::donothing: case Intrinsic::is_constant: case Intrinsic::objectsize:
  case Intrinsic::canonicalize: case Intrinsic::scmp: case Intrinsic::ucmp:
    return true;
  default:
    return false;
  }
}

// LLVM math intrinsics that stand for a libm call (rule 18: lifted as that libm function, from its body
// whenever the module defines it, cq-57ju/cq-odjk; taint's libmNameOf names the same set).
bool isLibmIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::exp: case Intrinsic::exp2: case Intrinsic::exp10: case Intrinsic::log:
  case Intrinsic::log2: case Intrinsic::log10: case Intrinsic::sin: case Intrinsic::cos:
  case Intrinsic::tan: case Intrinsic::asin: case Intrinsic::acos: case Intrinsic::atan: case Intrinsic::sinh:
  case Intrinsic::cosh: case Intrinsic::tanh: case Intrinsic::pow: case Intrinsic::powi: case Intrinsic::ldexp:
  case Intrinsic::frexp: case Intrinsic::nearbyint: case Intrinsic::roundeven: case Intrinsic::lround:
  case Intrinsic::llround: case Intrinsic::lrint: case Intrinsic::llrint: case Intrinsic::minimum:
  case Intrinsic::maximum:
    return true;
  default:
    return false;
  }
}

// The <fenv.h> functions (C17 7.6); taint's isFenvCall and eff-fenv's fenvFn name the same set. The
// trap-enable extensions (feenableexcept, fedisableexcept, fegetexcept) are not C17 and have no musl body:
// rule 27 like any bodiless callee (CR rule 23, cq-hzji).
bool isFenvFunction(StringRef n) { return taint_detail::isFenvName(n); }   // an asm label "\01_n" too (cq-ten4)

} // namespace

namespace calls {

// The classification before the tape-order rule below (classify).
static Class classifyBase(const CallBase &CB, const TaintInfo &T, const Specialization &S) {
  if (CB.isInlineAsm())
    return Class::Asm;   // the cq_invert fences included (cq-arch note); rule 27 decides on operands

  const Function *F = dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
  bool qArg = anyQuantumArg(CB, T, S);
  bool qRes = !CB.getType()->isVoidTy() && quantumValue(T, S, &CB);
  bool qPred = underQuantumPredicate(CB, T, S);

  if (F) {
    if (auto c = surface(*F))
      return *c;
  }

  // Rule 19: a call through a function pointer is always a call of a table clone, resolved at run time.
  if (!F)
    return Class::Indirect;

  if (F->isIntrinsic()) {
    Intrinsic::ID id = F->getIntrinsicID();
    // Rule 23: the constrained ops and LLVM's rounding-mode intrinsics read or write the
    // floating-point environment, classical ones included.
    // Ruling 2026-11-02 (cq-75n4): an fpexcept.ignore / maytrap op raises nothing; it is the plain template
    // (in the mode its chain gives it), an op like any other, not an effect (rule 14 loops take it as one;
    // dispatch still hands it to eff-fenv, which picks the mode). Only a strict op is the environment's.
    if (auto *CI = dyn_cast<ConstrainedFPIntrinsic>(&CB)) {
      std::optional<fp::ExceptionBehavior> eb = CI->getExceptionBehavior();
      return eb && *eb == fp::ebStrict ? Class::Fenv : Class::TemplateIntrinsic;
    }
    if (id == Intrinsic::get_rounding || id == Intrinsic::set_rounding)
      return Class::Fenv;
    switch (id) {
    case Intrinsic::memcpy: case Intrinsic::memmove: case Intrinsic::memset:
    case Intrinsic::memcpy_inline: case Intrinsic::memset_inline: {
      bool q = qArg;
      for (const Use &u : CB.args())
        q |= nonClassicalObject(T, S, u.get());
      return q ? Class::MemIntrinsic : Class::Classical;
    }
    case Intrinsic::lifetime_start:
      return nonClassicalObject(T, S, CB.getArgOperand(1)) ? Class::Alloc : Class::Classical;
    case Intrinsic::lifetime_end:
      return nonClassicalObject(T, S, CB.getArgOperand(1)) ? Class::Dealloc : Class::Classical;
    case Intrinsic::stackrestore:
      return busScope(T, S, CB) ? Class::Dealloc : Class::Classical;
    case Intrinsic::stacksave:
      // Rule 16: dropped with the stackrestores that read it.
      for (const User *u : CB.users())
        if (auto *R = dyn_cast<CallBase>(u); !R || !busScope(T, S, *R))
          return Class::Classical;
      return CB.use_empty() ? Class::Classical : Class::Dealloc;
    case Intrinsic::assume:
      // Rule 21: a hint is never consulted; one naming a rail (`"align"(p, r)` after aligned_alloc(r, n)) is nothing.
      for (const Use &u : CB.data_ops())
        if (quantumValue(T, S, u.get()))
          return Class::TemplateIntrinsic;
      return Class::Classical;
    case Intrinsic::ptrmask:
      // Rule 21 (105): the mask of an address rail: integer templates over the address.
      return qArg || qRes ? Class::TemplateIntrinsic : Class::Classical;
    case Intrinsic::trap: case Intrinsic::ubsantrap: case Intrinsic::debugtrap:
      // Rule 16 noreturn (__builtin_trap), ruling Q7: where an event can precede it, the effect entry __builtin_trap.
      if (qPred)
        return Class::Noreturn;
      return T.isEffectEntry(CB, S) ? Class::HostEffect : Class::Classical;
    case Intrinsic::vacopy:
      // Rule 16 (109): va_copy(d, s) is memcpy(d, s, 24), so rule 22 decides as for memcpy: classical only when both
      // va_lists are host-resident objects, in the own symbol too (cq-f0rb6: musl vfprintf's va_copy of the caller's
      // bus-resident va_list into its bus-resident ap2; a host copy of host bytes the bus never sees).
      if (nonClassicalObject(T, S, CB.getArgOperand(0)) || nonClassicalObject(T, S, CB.getArgOperand(1)))
        return Class::Varargs;
      [[fallthrough]];
    case Intrinsic::vastart: case Intrinsic::vaend:
      // A variadic clone is specialised per call-site arity (CR §1.4). In the own symbol va_start stays the
      // intrinsic (it fills ap with host bytes, rule 16) and va_end is nothing.
      return qArg || qPred || !S.isEntry() ? Class::Varargs : Class::Classical;
    default:
      break;
    }
    if (!qArg && !qRes)
      return Class::Classical;
    if (isTemplateIntrinsic(id))
      return Class::TemplateIntrinsic;
    if (isLibmIntrinsic(id))
      return T.isEffectEntry(CB, S) ? Class::HostEffect : Class::LibmIntrinsic;   // Q5: no body after injection: rule 16
    if (isHintIntrinsic(id))
      return Class::TemplateIntrinsic;   // spine's lowerOpcode: a representation change, nothing or a composition
    if (CB.getType()->isVectorTy() || any_of(CB.args(), [](const Use &u) { return u->getType()->isVectorTy(); }))
      return Class::TemplateIntrinsic;   // lanes (rule 25): dispatch hands it to aggr::lowerVectorOp
    // Every intrinsic clang 19 -O1 emits for C is routed above (templates, libm, hints, memory, fenv,
    // varargs, lifetime, trap): the rest (gc, coroutine, EH, target-specific, saturating fp conversions,
    // fixed point) never reaches the pass from the pipeline (CLAUDE.md Pipeline: C through clang -O1).
    internalError("spine: calls::classify: an intrinsic the C pipeline does not emit, with a quantum operand", &CB);
  }

  // Rule 23: every <fenv.h> call (C17 7.6, a callee with no body) of a lowered function is the fenv
  // module's, classical ones included: the host part stays, and the quantum part (the mode and flags
  // rails) changes with it (a classical fesetround drops a quantum mode rail, feclearexcept clears
  // flag rails). eff-fenv copies the call to the host when the quantum part is not involved.
  if (hostCallee(*F) && isFenvFunction(F->getName()))
    return Class::Fenv;

  // Rule 24 (106): the thread primitives collapse to the sequential schedule (eff-conc).
  if (hostCallee(*F)) {
    StringRef n = F->getName();
    if (n.starts_with("\01_"))
      n = n.drop_front(2);
    if (n == "pthread_create" || n == "pthread_join" || rule24Mutex(n))
      return Class::Thread;
  }

  if (CB.hasFnAttr(Attribute::ReturnsTwice) || F->hasFnAttribute(Attribute::ReturnsTwice))
    return qPred || qArg || qRes ? Class::Setjmp : Class::Classical;

  // Rule 16: an allocation is always __cq_alloc, `free` is nothing, under any predicate.
  AllocFnKind ak = bus::hostAllocKind(*F);
  if ((ak & AllocFnKind::Free) != AllocFnKind::Unknown)
    return Class::Dealloc;
  if ((ak & AllocFnKind::Realloc) != AllocFnKind::Unknown)
    return Class::Realloc;
  if ((ak & AllocFnKind::Alloc) != AllocFnKind::Unknown)
    return Class::Alloc;

  if (!hostCallee(*F) && (CB.doesNotReturn() || F->doesNotReturn())) {
    // cq-wskg, cq-gk1ki: a defined noreturn callee. A classical call with classical arguments is the ordinary call (the
    // program ends there). Under a quantum predicate, with no quantum argument, a callee that aborts on every path with
    // nothing before is the noreturn call it ends in, abort_i1(pred) (tape::lowerNoreturn). Any other call with a quantum
    // argument or under a quantum predicate is rule 18's: lifted like any callee with a body (taint lifts it), its clone
    // (_ctl under the predicate) carrying the abort form inside (rule 16; owner rulings 2026-11-14 Q1, Q7).
    if (!qArg && !qPred) {
      bool qMem = false;
      for (const Use &u : CB.args())
        qMem = qMem || nonClassicalObject(T, S, u.get());
      if (qMem)
        unimplemented("spine: calls::classify: a defined noreturn function called with a non-classical-object "
                      "argument (rule 16)",
                      &CB);
      return Class::Classical;
    }
    if (!qArg && taint_detail::abortsOnEveryPath(*F))
      return Class::Noreturn;
    return Class::Lift;
  }

  if (!hostCallee(*F)) {
    // A callee with a body: lifted (rule 18), called as it is (rule 19, no quantum argument, a body that
    // rotates: calls::lowerLifted), or a _ctl / merged callee under a predicate.
    if (qArg || qRes || qPred)
      return Class::Lift;
    if (const Specialization *C = T.calleeSpecialization(CB, S); C && !C->isEntry())
      return Class::Lift;
    return Class::Classical;
  }

  // No body.
  if (CB.doesNotReturn() || F->doesNotReturn()) {
    if (qPred)
      return F->getName() == "longjmp" || F->getName() == "_longjmp" || F->getName() == "siglongjmp"
                 ? Class::Longjmp
                 : Class::Noreturn;
    // Rule 16: with a rail argument, or where a tape or abort event can precede it (owner ruling 2026-11-11 Q7, cq-edr1f:
    // taint's eventPrecedes, read through its effect-entry set), the effect entry of its name, then abort_i1 of its seed.
    // Otherwise the ordinary host call, made as it stands.
    if (!qArg && !T.isEffectEntry(CB, S))
      return Class::Classical;
    return Class::HostEffect;
  }
  // Rule 16 Signal table: no handler is tracked at compile time.
  if (F->getName() == "signal" && CB.arg_size() == 2)
    return Class::Signal;
  if (F->getName() == "raise" && CB.arg_size() == 1)
    return Class::Raise;
  // Rule 27: a listed function called with a rail is its declared clone (owner ruling 2026-11-20: with every actual
  // classical it is the C symbol's call, a host call). Rule 16: every other call the entry test of taint made an effect
  // entry (a format entry for printf); the rest is the ordinary host call or pure.
  if (T.declaredCall(CB, S))
    return Class::Declared;
  return T.isEffectEntry(CB, S) ? Class::HostEffect : Class::Classical;
}

Class classify(const CallBase &CB, const TaintInfo &T, const Specialization &S) { return classifyBase(CB, T, S); }

} // namespace calls

namespace bus {

// Rule 16 Allocation and Deallocation: the one recognition of an allocation call, shared by the taint (whose result
// lanes it decides) and the lowering (bus::lowerAlloc, lowerRealloc). Defined here, not in bus/Alloc.cpp, because the
// checker's oracle plugin compiles Taint.cpp and this file but not the bus.
AllocFnKind hostAllocKind(const Function &F) {
  AllocFnKind k = F.getAttributes().getFnAttrs().getAllocKind();
  if (k != AllocFnKind::Unknown || !hostCallee(F))
    return k;
  StringRef n = F.getName();
  if (n == "malloc" || n == "calloc" || n == "aligned_alloc")
    return AllocFnKind::Alloc;
  if (n == "realloc")
    return AllocFnKind::Realloc;
  if (n == "free")
    return AllocFnKind::Free;
  return AllocFnKind::Unknown;
}

} // namespace bus

namespace spine {

void scopeAllocas(const CallBase &restore, SmallVectorImpl<const AllocaInst *> &out) {
  auto isSave = [](const Value *v) {
    auto *II = dyn_cast<IntrinsicInst>(v);
    return II && II->getIntrinsicID() == Intrinsic::stacksave;
  };
  const Value *save = restore.getArgOperand(0)->stripPointerCasts();
  if (!isSave(save))
    internalError("spine: a stackrestore whose operand is no llvm.stacksave (clang pairs them per scope)", &restore);
  const Function &F = *restore.getFunction();
  DominatorTree DT(const_cast<Function &>(F));
  auto *S = cast<Instruction>(save);
  SmallVector<const Instruction *, 4> inner;   // nested scopes' saves: their allocas end at their own restores
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB)
      if (isSave(&I) && &I != S && DT.dominates(S, &I) &&
          any_of(I.users(), [](const User *u) {
            auto *r = dyn_cast<IntrinsicInst>(u);
            return r && r->getIntrinsicID() == Intrinsic::stackrestore;
          }))
        inner.push_back(&I);
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB) {
      auto *A = dyn_cast<AllocaInst>(&I);
      if (!A || !DT.dominates(S, A) || !isPotentiallyReachable(A, &restore, nullptr, &DT))
        continue;
      if (any_of(inner, [&](const Instruction *X) { return DT.dominates(X, A); }))
        continue;
      out.push_back(A);
    }
}

} // namespace spine

namespace loops {

// Rule 14. An exit is quantum when its condition is, or when its exiting block is control dependent
// on a quantum terminator inside the loop. A loop with a quantum exit has a classical bound when
// some exit is classical or a quantum exit condition has a classical disjunct of its exit test
// (`c || q`, 26, 121, 130, 139), each bounding the trip count (SCEV computes its count).
Case classify(const Loop &L, const TaintInfo &T, const Specialization &S) {
  SmallVector<BasicBlock *, 4> exiting;
  L.getExitingBlocks(exiting);

  auto quantumTerm = [&](const BasicBlock *B) {
    const Instruction *t = B->getTerminator();
    if (auto *br = dyn_cast<BranchInst>(t))
      return br->isConditional() && quantumValue(T, S, br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return quantumValue(T, S, sw->getCondition());
    if (auto *ib = dyn_cast<IndirectBrInst>(t))
      return quantumValue(T, S, ib->getAddress());
    if (auto *cb = dyn_cast<CallBrInst>(t))
      return any_of(cb->args(), [&](const Use &u) { return quantumValue(T, S, u.get()); });
    return false;
  };

  // Control dependence inside the loop: X depends on a quantum terminator of Y in the loop when X
  // is reachable from a successor of Y without passing Y's in-loop post-dominator, post-dominance
  // taken inside one trip (below).
  // A block that is only `unreachable` (no call before it, so not a noreturn exit) is never
  // taken: LLVM assumes so, and so do we (owner ruling, CLAUDE.md Domain; cq-s0pv, 131's switch
  // default). Such a successor is no path out of Y for control dependence.
  auto deadEnd = [](const BasicBlock *b) {
    if (!isa<UnreachableInst>(b->getTerminator()))
      return false;
    for (const Instruction &I : *b)
      if (isa<CallBase>(I))
        return false;
    return true;
  };
  // Control dependence of X on Y inside the loop: an edge of Y that leaves the loop is Y's own exit,
  // classified on its own, and does not make X's exit quantum (cq-hggf, 121: the classical exit
  // n + 1 == cap is reached only when the quantum exit s[n] == 0 is not taken).
  // cq-rb96s: post-dominance inside one trip (a back edge ends the trip), not the function's: a block on every path out
  // of the loop still runs only in the trips that reach it (GMP block_resieve).
  // cq-6ce8r: so is an exit edge of a block between Y and X: a path that leaves the loop ends the loop, never skips X's
  // test in a trip that goes on (a switch case that tests and falls through into the next, which tests and exits).
  // cq-i61ms: the loop's blocks with a quantum terminator, read once (not per exiting block).
  std::optional<SmallVector<const BasicBlock *, 8>> quantumYs;
  auto controlQuantum = [&](const BasicBlock *X) {
    if (!quantumYs) {
      quantumYs.emplace();
      for (const BasicBlock *Y : L.blocks())
        if (quantumTerm(Y))
          quantumYs->push_back(Y);
    }
    if (quantumYs->empty() || (quantumYs->size() == 1 && quantumYs->front() == X))
      return false;
    auto pdt = taint_detail::tripPostDominated(L, X, [&](const BasicBlock *s) { return !L.contains(s) || deadEnd(s); });
    auto pd = [&](const BasicBlock *s) { return s == X || (s != L.getHeader() && pdt.count(s)); };
    auto postDomLive = [&](const BasicBlock *Y) {
      for (const BasicBlock *s : successors(Y))
        if (!deadEnd(s) && L.contains(s) && !pd(s))
          return false;
      return true;
    };
    for (const BasicBlock *Y : *quantumYs) {
      if (Y == X)
        continue;
      for (const BasicBlock *s : successors(Y))
        if (L.contains(s) && pd(s) && !postDomLive(Y))
          return true;
    }
    return false;
  };

  // Disjuncts of "exit taken": cond (exit on true) or !cond (exit on false), through and/or/select
  // and negation. cq-dtvp: select c, t, true is !c | t and select c, false, f is !c & f (the
  // condition enters negated), and xor x, true is !x; -O1 writes `i + 1 >= n || q` as
  // select(i + 1 < n, q, true).
  std::function<void(const Value *, bool, SmallVectorImpl<std::pair<const Value *, bool>> &)> disjuncts;
  disjuncts = [&](const Value *c, bool positive, SmallVectorImpl<std::pair<const Value *, bool>> &out) {
    const Value *a = nullptr, *b = nullptr;
    bool isOr = false, isAnd = false, negA = false;
    auto isTrue = [](const Value *v) {
      auto *k = dyn_cast<ConstantInt>(v);
      return k && k->isOne();
    };
    auto isFalse = [](const Value *v) {
      auto *k = dyn_cast<ConstantInt>(v);
      return k && k->isZero();
    };
    if (auto *bo = dyn_cast<BinaryOperator>(c); bo && bo->getType()->isIntegerTy(1)) {
      if (bo->getOpcode() == Instruction::Or) { isOr = true; a = bo->getOperand(0); b = bo->getOperand(1); }
      if (bo->getOpcode() == Instruction::And) { isAnd = true; a = bo->getOperand(0); b = bo->getOperand(1); }
      if (bo->getOpcode() == Instruction::Xor) {
        for (unsigned i = 0; i < 2; ++i)
          if (isTrue(bo->getOperand(i)))
            return disjuncts(bo->getOperand(1 - i), !positive, out);
      }
    } else if (auto *sel = dyn_cast<SelectInst>(c); sel && sel->getType()->isIntegerTy(1)) {
      const Value *t = sel->getTrueValue(), *f = sel->getFalseValue();
      if (isTrue(t)) {
        isOr = true; a = sel->getCondition(); b = f;
      } else if (isFalse(f)) {
        isAnd = true; a = sel->getCondition(); b = t;
      } else if (isTrue(f)) {
        isOr = true; negA = true; a = sel->getCondition(); b = t;
      } else if (isFalse(t)) {
        isAnd = true; negA = true; a = sel->getCondition(); b = f;
      }
    }
    if ((isOr && positive) || (isAnd && !positive)) {
      disjuncts(a, negA ? !positive : positive, out);
      disjuncts(b, positive, out);
      return;
    }
    out.push_back({c, positive});
  };

  // Owner 2026-11-15, cq-amtcn (CR rule 14): a classical exit test that reads a trip's outcome of a loop-carried rail (a
  // quantum header phi, read after its measurement) bounds nothing beside a quantum exit: where the quantum exit was
  // taken the carried rail keeps its value, and so would the test. It is a classical conjunct of the K-loop.
  std::function<bool(const Value *, SmallPtrSetImpl<const Value *> &)> readsOutcome =
      [&](const Value *v, SmallPtrSetImpl<const Value *> &seen) -> bool {
    auto *I = dyn_cast<Instruction>(v);
    if (!I || !L.contains(I) || !seen.insert(I).second)
      return false;
    if (isa<PHINode>(I))
      return I->getParent() == L.getHeader() && quantumValue(T, S, I);
    return any_of(I->operands(), [&](const Use &u) { return readsOutcome(u.get(), seen); });
  };
  auto bounds = [&](const Value *c) {
    SmallPtrSet<const Value *, 16> seen;
    return !readsOutcome(c, seen);
  };

  bool anyQuantum = false, classicalBound = false, anyExit = false;
  for (BasicBlock *X : exiting) {
    const Instruction *t = X->getTerminator();
    // An exit only into dead ends is never taken (131's switch default): no exit of the loop.
    if (all_of(successors(X), [&](const BasicBlock *s) { return L.contains(s) || deadEnd(s); }))
      continue;
    anyExit = true;
    bool internal = controlQuantum(X);
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional()) {
      bool exitOnTrue = !L.contains(br->getSuccessor(0));
      bool q = quantumValue(T, S, br->getCondition()) || internal;
      if (!q) {
        // cq-z6q1 (189): a classical exit is a bound only when LLVM computes its exit count; a test of data
        // read from memory (p->next == NULL) bounds nothing, and the loop is a K-loop.
        if (exitCountKnown(*L.getHeader(), *X) && bounds(br->getCondition()))
          classicalBound = true;
        continue;
      }
      anyQuantum = true;
      if (internal)
        continue;
      SmallVector<std::pair<const Value *, bool>, 4> ds;
      disjuncts(br->getCondition(), exitOnTrue, ds);
      // cq-s7c4: a classical disjunct is a bound only when it bounds the trip count on its own, as a
      // classical exit must (cq-z6q1): `stop || q` with `stop` loop-invariant is a K-loop (case 2).
      for (auto &d : ds)
        if (!quantumValue(T, S, d.first) && exitCondCountKnown(*L.getHeader(), *d.first, d.second) && bounds(d.first))
          classicalBound = true;
    } else if (isa<SwitchInst>(t) || isa<IndirectBrInst>(t)) {   // rule 13: a computed goto is a switch
      if (quantumTerm(X) || internal)
        anyQuantum = true;
      else
        classicalBound = true;
    } else {
      // An exit through a return or noreturn call inside the loop body.
      if (internal)
        anyQuantum = true;
      else
        classicalBound = true;
    }
  }
  // cq-hmxd5, CR rule 14 "No live exit": a loop with no exit edge at all (a quantum body; a pure classical one is no unit)
  // runs K trips and then abort_i1 on its seed: the K-loop's frozen chain (loops-cutoff).
  if (!anyExit)
    return Case::QuantumExit;
  if (!anyQuantum)
    return Case::ClassicalBound;
  return classicalBound ? Case::ClassicalBoundQuantumExit : Case::QuantumExit;
}

} // namespace loops
} // namespace cq
