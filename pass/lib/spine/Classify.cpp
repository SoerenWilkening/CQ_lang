// Module spine (cq-w0-construct): loops::classify (rule 14) and calls::classify (rules 16, 18, 19,
// 22, 27, and the intrinsic routes of rules 4 and 18).
//
// calls::classify recognizes by attributes and semantics, never by name alone (rule 16):
//  - the CQ.h surface is a declaration with the CQ.h name AND the CQ.h signature;
//  - allocation, reallocation and deallocation by the callee's allockind attribute;
//  - noreturn by the attribute; returns_twice (setjmp) by the attribute;
//  - host effects: a bodiless callee that may write memory or has unmodelled effects, reached under a
//    quantum predicate, or a library function LLVM knows (TargetLibraryInfo) with such effects
//    reached with a quantum argument (printf(x), 47);
//  - intrinsics by their ID.
// A call with no quantum involvement (no quantum argument or result, no quantum predicate in scope,
// not in a _ctl clone) is Classical whatever its callee, except the CQ.h surface.
#include "SpineInternal.h"

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

bool nonClassicalObject(const TaintInfo &T, const Specialization &S, const Value *ptr) {
  if (!ptr->getType()->isPointerTy())
    return false;
  if (T.isFatPointer(ptr, S))
    return true;
  for (ObjectId o : T.provenance(ptr, S))
    if (T.classOf(o) != ObjClass::Classical)
      return true;
  return false;
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

// A library function LLVM knows by semantics (cq::libFuncOf, Common.h).
bool knownLibFunc(const Function &F) {
  LibFunc lf;
  return libFuncOf(F, lf);
}

// The <fenv.h> functions (C17 7.6); taint's isFenvCall and eff-fenv's fenvFn name the same set. The
// trap-enable extensions (feenableexcept, fedisableexcept, fegetexcept) are not C17 and have no musl body:
// rule 27 like any bodiless callee (CR rule 23, cq-hzji).
bool isFenvFunction(StringRef n) {
  static const char *names[] = {"feclearexcept", "fegetexceptflag", "feraiseexcept", "fesetexceptflag",
                                "fetestexcept",  "fegetround",      "fesetround",    "fegetenv",
                                "feholdexcept",  "fesetenv",        "feupdateenv"};
  for (const char *x : names)
    if (n == x)
      return true;
  return false;
}

bool mayHaveHostEffect(const CallBase &CB) {
  return !CB.onlyReadsMemory() || CB.mayThrow() || !CB.willReturn();
}

// cq-wskg (rule 16): a function with a body that aborts on every path with nothing before: its CFG is
// acyclic, it has no return, every `unreachable` follows a terminal noreturn call (a bodiless noreturn
// callee other than longjmp/_longjmp/siglongjmp and setjmp, llvm.trap, llvm.ubsantrap, or a defined
// callee of this same class), and every other instruction is side-effect free (no other call but
// debug and lifetime intrinsics). Its call is the noreturn call it ends in: abort_i1(pred) (`static
// void die(void) { abort(); }`). `onStack` breaks recursion (a recursive callee is not of the class).
bool abortsOnEveryPath(const Function &G, SmallPtrSetImpl<const Function *> &onStack);

bool terminalNoreturn(const CallBase &CB, SmallPtrSetImpl<const Function *> &onStack) {
  const Function *F = dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
  if (!F || CB.isInlineAsm())
    return false;
  if (F->isIntrinsic())
    return F->getIntrinsicID() == Intrinsic::trap || F->getIntrinsicID() == Intrinsic::ubsantrap;
  if (CB.hasFnAttr(Attribute::ReturnsTwice) || F->hasFnAttribute(Attribute::ReturnsTwice))
    return false;
  if (!F->isDeclaration())
    return abortsOnEveryPath(*F, onStack);
  StringRef n = F->getName();
  if (n == "longjmp" || n == "_longjmp" || n == "siglongjmp")
    return false;
  return CB.doesNotReturn() || F->doesNotReturn();
}

bool abortsOnEveryPath(const Function &G, SmallPtrSetImpl<const Function *> &onStack) {
  if (G.isDeclaration() || !onStack.insert(&G).second)
    return false;
  // Acyclic: no back edge on a depth-first walk from the entry.
  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 4> backEdges;
  FindFunctionBackedges(G, backEdges);
  bool ok = backEdges.empty();
  for (const BasicBlock &BB : G) {
    for (const Instruction &I : BB) {
      if (!ok)
        break;
      if (isa<UnreachableInst>(I)) {
        auto *c = dyn_cast_or_null<CallBase>(I.getPrevNode());
        ok = c && terminalNoreturn(*c, onStack);
        continue;
      }
      if (I.isTerminator()) {
        ok = isa<BranchInst>(I) || isa<SwitchInst>(I);
        continue;
      }
      if (auto *c = dyn_cast<CallBase>(&I)) {
        if (isa<UnreachableInst>(c->getNextNode()))
          continue;   // checked at the unreachable
        if (auto *ii = dyn_cast<IntrinsicInst>(c))
          if (isa<DbgInfoIntrinsic>(ii) || ii->getIntrinsicID() == Intrinsic::lifetime_start ||
              ii->getIntrinsicID() == Intrinsic::lifetime_end)
            continue;
        ok = false;
        continue;
      }
      ok = !I.mayHaveSideEffects();
    }
  }
  onStack.erase(&G);
  return ok;
}

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

  if (!F) {
    if (qArg || qRes || qPred || quantumValue(T, S, CB.getCalledOperand()))
      return Class::Indirect;
    // cq-lyzw (rule 19 with rule 20, as cq-vnh9 for a direct call): a pointer argument into a slot or QRAM
    // object hands the candidates rails; the originals would read handles as data.
    for (const Use &u : CB.args())
      if (nonClassicalObject(T, S, u.get()))
        return Class::Indirect;
    return Class::Classical;
  }

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
    case Intrinsic::stackrestore: {
      // A VLA's lifetime ends here (rule 20, 192) when the scope holds a slot or QRAM object and the
      // restore runs under a quantum predicate (otherwise mem-slots keeps the scope's cells per run, 109).
      // A scope of classical objects only restores the host stack, under any predicate (the linearized
      // program runs it as C does).
      if (!qPred && !qArg)
        return Class::Classical;
      SmallVector<const AllocaInst *, 4> scope;
      spine::scopeAllocas(CB, scope);
      for (const AllocaInst *A : scope)
        if (nonClassicalObject(T, S, A))
          return Class::Dealloc;
      return Class::Classical;
    }
    case Intrinsic::ptrmask:
      // Rule 21 (105): the mask of a fat pointer's flat address, 89's round trip (fatptr::lower), a
      // sequence of integer templates over the address.
      return qArg || qRes ? Class::TemplateIntrinsic : Class::Classical;
    case Intrinsic::trap: case Intrinsic::ubsantrap: case Intrinsic::debugtrap:
      return qPred ? Class::Noreturn : Class::Classical;
    case Intrinsic::vastart: case Intrinsic::vaend: case Intrinsic::vacopy:
      // A variadic clone is specialised per call-site arity (CR §1.4); in an entry with nothing
      // quantum in the va_list the intrinsics stay classical.
      return qArg || qPred || !S.isEntry() ? Class::Varargs : Class::Classical;
    default:
      break;
    }
    if (!qArg && !qRes)
      return Class::Classical;
    if (isTemplateIntrinsic(id))
      return Class::TemplateIntrinsic;
    if (isLibmIntrinsic(id))
      return Class::LibmIntrinsic;
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
  if (F->isDeclaration() && isFenvFunction(F->getName()))
    return Class::Fenv;

  // Rule 24 (106): the thread primitives collapse to the sequential schedule (eff-conc).
  if (F->isDeclaration()) {
    StringRef n = F->getName();
    if (n.starts_with("\01_"))
      n = n.drop_front(2);
    if (n == "pthread_create" || n == "pthread_join" || n == "pthread_mutex_lock" || n == "pthread_mutex_unlock" ||
        n == "pthread_mutex_trylock")
      return Class::Thread;
  }

  if (CB.hasFnAttr(Attribute::ReturnsTwice) || F->hasFnAttribute(Attribute::ReturnsTwice))
    return qPred || qArg || qRes ? Class::Setjmp : Class::Classical;

  // Rule 16 by allockind: a QRAM or slot block is the memory modules', a classical block a host call.
  AllocFnKind ak = F->getAttributes().getFnAttrs().getAllocKind();
  if (ak != AllocFnKind::Unknown) {
    if ((ak & AllocFnKind::Free) != AllocFnKind::Unknown) {
      const Value *p = CB.arg_size() ? CB.getArgOperand(0) : nullptr;
      return p && (nonClassicalObject(T, S, p) || qArg) ? Class::Dealloc : Class::Classical;
    }
    bool block = nonClassicalObject(T, S, &CB);   // provenance: array-of-structs sites (cq-qj49)
    if ((ak & AllocFnKind::Realloc) != AllocFnKind::Unknown)
      return block || qArg ? Class::Realloc : Class::Classical;
    if ((ak & AllocFnKind::Alloc) != AllocFnKind::Unknown)
      return block || qArg ? Class::Alloc : Class::Classical;
  }

  if (!F->isDeclaration() && (CB.doesNotReturn() || F->doesNotReturn())) {
    // cq-wskg: a defined noreturn callee (rule 16) is never lifted (taint publishes no clone for it).
    // Built: under a quantum predicate, with no quantum or non-classical-object argument, a callee that
    // aborts on every path with nothing before is the noreturn call it ends in, abort_i1(pred)
    // (tape::lowerNoreturn). A classical call with classical arguments is the ordinary call (the
    // program ends there). Everything else is unimplemented, never the original call under the
    // predicate: a callee with effects before its exit (tape entries before abort_i1), one that may
    // longjmp (rule 24: the escaped flag through its frame), one handed quantum data.
    bool qMem = false;
    for (const Use &u : CB.args())
      qMem = qMem || nonClassicalObject(T, S, u.get());
    if (qArg || qMem)
      unimplemented("spine: calls::classify: a defined noreturn function called with a quantum or "
                    "non-classical-object argument (rule 16)",
                    &CB);
    if (!qPred)
      return Class::Classical;
    SmallPtrSet<const Function *, 8> onStack;
    if (abortsOnEveryPath(*F, onStack))
      return Class::Noreturn;
    unimplemented("spine: calls::classify: a defined noreturn function under a quantum predicate that does "
                  "not abort on every path with nothing before (rule 16: its effects would be tape entries "
                  "before abort_i1; rule 24: a longjmp in it escapes through its frame)",
                  &CB);
  }

  if (!F->isDeclaration()) {
    // A callee with a body: lifted (rule 18), called as it is (rule 19, no quantum argument, a body that
    // rotates: calls::lowerLifted), or a _ctl / merged callee under a predicate.
    if (qArg || qRes || qPred)
      return Class::Lift;
    // cq-vnh9: every quantum input behind a pointer argument (a slot object, 52's reduce(tx, ...)):
    // taint publishes a clone for the call, so it is lifted like any other.
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
    if (!qArg)
      return Class::Classical;
  }
  // cq-my17 (99): a pointer argument into a slot or QRAM object hands the callee rails to read
  // (fwrite(buf, ...)): the tape entry reads the cells, so the call is quantum-involved too.
  bool qMem = false;
  for (const Use &u : CB.args())
    qMem = qMem || nonClassicalObject(T, S, u.get());
  if ((qArg || qMem) && knownLibFunc(*F) && mayHaveHostEffect(CB))
    return Class::HostEffect;   // printf(x) and friends (47, 99, 138)
  if (qArg || qRes)
    return Class::Declared;     // rule 27
  // cq-r8-d (rule 27 Pointers, 190): a pointer argument into a slot object whose cells hold handles
  // hands the callee rails (a callee with no body and no host effect).
  if (qMem)
    return Class::Declared;
  if (qPred && mayHaveHostEffect(CB))
    return Class::HostEffect;   // signal, raise, remove under a quantum arm (102)
  return Class::Classical;
}


// ------------------------------------------------------------------ tape order (CR rule 16, §1.3)
//
// Owner ruling 2026-11-02 (cq-t8oo, cq-64lv): once a shot has a tape entry or an abort under a quantum
// predicate, every later host effect goes on the tape too, so the output keeps C's order (the tape is
// performed at the end of the shot) and an aborted shot drops it (§1.3: no entry after an abort flag
// reading 1 is performed). Orchestrator decision under rule 16 (owner may override), the narrow rule:
//  - A tape point of a function (one specialization) is a call of class HostEffect or Noreturn (a tape
//    entry, an abort arm, a raise), or a call of a callee specialization that has a tape point itself,
//    transitively (its entries precede what follows the call).
//  - A classical host effect (a bodiless callee with effects beyond its pointer arguments, as taint's
//    hostEffectBeyondArgs reads it: printf, puts, putchar, write, ...; not an allocation, fenv, thread,
//    setjmp or noreturn call, which keep their own classes) that a tape point of the same function may
//    precede on the original CFG (llvm::isPotentiallyReachable: the same block after it, a successor, a
//    later trip of a loop; for an abort arm, whose block ends in `unreachable` while the lowered program
//    goes on, every call that cannot reach it) is HostEffect: eff-tape records it as a tape entry with no predicate, and what
//    the tape cannot carry is unimplemented there. Reaching it from a tape point is an over-approximation
//    of "after one in the shot": an entry the tape records although no tape point preceded it on that
//    path is still performed in call order, so the output is unchanged.
//  - Across calls: what a callee does after a caller's tape point is checked at the caller. A call that a
//    tape point may precede, of a callee that may perform a host effect directly (one its own lowering
//    leaves a host call: not after a tape point of its own, or in a function that is never rewritten), or
//    an indirect classical call (callee unknown), is unimplemented. A host effect after the RETURN of a
//    callee with a tape point is covered by the first bullet (the call is a tape point of the caller).
//  - Unimplemented as well: an indirect call with a quantum part that may precede a classical host
//    effect (whether its target records a tape entry is not analysed).
namespace {

bool hostEffectBeyondArgs(const CallBase &CB) {
  MemoryEffects ME = CB.getMemoryEffects().getWithoutLoc(IRMemLocation::ArgMem);
  return !ME.onlyReadsMemory() || CB.mayThrow() || !CB.willReturn();
}

const Function *directCallee(const CallBase &CB) {
  return CB.isInlineAsm() ? nullptr : dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
}

// A host call this function's lowering may leave as a host call (classify's Classical) that the tape
// rule moves onto the tape when a tape point precedes it.
bool tapeCandidate(const CallBase &CB, Class base) {
  if (base != Class::Classical)
    return false;
  const Function *F = directCallee(CB);
  if (!F || !F->isDeclaration() || F->isIntrinsic())
    return false;
  if (CB.doesNotReturn() || F->doesNotReturn() || CB.hasFnAttr(Attribute::ReturnsTwice) ||
      F->hasFnAttribute(Attribute::ReturnsTwice))
    return false;
  if (F->getAttributes().getFnAttrs().getAllocKind() != AllocFnKind::Unknown)
    return false;
  StringRef n = F->getName();
  if (n.starts_with("\01_"))
    n = n.drop_front(2);
  if (isFenvFunction(n) || n.starts_with("pthread_"))
    return false;
  return hostEffectBeyondArgs(CB);
}

struct TapeOrder {
  const TaintInfo &T;
  DenseMap<const Specialization *, bool> specTapes, specHost;   // memo per root
  explicit TapeOrder(const TaintInfo &T) : T(T) {}

  // The callee specializations a call of C may run (C included), and the never-rewritten functions they
  // call (an ordinary call of the original), transitively.
  void reach(const Specialization &C, SmallVectorImpl<const Specialization *> &specs,
             SmallVectorImpl<const Function *> &fns) {
    SmallPtrSet<const Specialization *, 8> seenS;
    SmallPtrSet<const Function *, 8> seenF;
    specs.push_back(&C);
    seenS.insert(&C);
    for (size_t i = 0; i < specs.size(); ++i)
      for (const BasicBlock &BB : *specs[i]->F)
        for (const Instruction &I : BB) {
          auto *X = dyn_cast<CallBase>(&I);
          const Function *G = X ? directCallee(*X) : nullptr;
          if (!G || G->isDeclaration() || isa<DbgInfoIntrinsic>(X))
            continue;
          if (const Specialization *D = T.calleeSpecialization(*X, *specs[i])) {
            if (seenS.insert(D).second)
              specs.push_back(D);
          } else if (seenF.insert(G).second) {
            fns.push_back(G);
          }
        }
    for (size_t i = 0; i < fns.size(); ++i)
      for (const BasicBlock &BB : *fns[i])
        for (const Instruction &I : BB)
          if (auto *X = dyn_cast<CallBase>(&I))
            if (const Function *G = directCallee(*X); G && !G->isDeclaration() && seenF.insert(G).second)
              fns.push_back(G);
  }

  // Does a call of the callee specialization C record a tape entry or an abort flag?
  bool tapes(const Specialization &C) {
    if (auto it = specTapes.find(&C); it != specTapes.end())
      return it->second;
    SmallVector<const Specialization *, 8> specs;
    SmallVector<const Function *, 8> fns;
    reach(C, specs, fns);
    bool r = false;
    for (const Specialization *D : specs)
      for (const BasicBlock &BB : *D->F)
        for (const Instruction &I : BB)
          if (auto *X = dyn_cast<CallBase>(&I); X && !r && !isa<DbgInfoIntrinsic>(X)) {
            Class k = classifyBase(*X, T, *D);
            r = k == Class::HostEffect || k == Class::Noreturn;
          }
    return specTapes[&C] = r;
  }

  bool tapePoint(const CallBase &X, const Specialization &S) {
    if (isa<DbgInfoIntrinsic>(X))
      return false;
    Class k = classifyBase(X, T, S);
    if (k == Class::HostEffect || k == Class::Noreturn)
      return true;
    const Function *G = directCallee(X);
    if (!G || G->isDeclaration())
      return false;   // an indirect call is decided at the host effect it may precede (after)
    if (const Specialization *D = T.calleeSpecialization(X, S))
      return tapes(*D);
    return false;
  }

  // May a tape point of S.F precede CB (on the original CFG)?
  bool after(const CallBase &CB, const Specialization &S, bool hostEffect) {
    for (const BasicBlock &BB : *S.F)
      for (const Instruction &I : BB) {
        auto *X = dyn_cast<CallBase>(&I);
        if (!X || X == &CB || isa<DbgInfoIntrinsic>(X))
          continue;
        // An abort arm ends its block in `unreachable` on the original CFG, but the lowered program goes on
        // (rule 16): what cannot reach the noreturn call is after it.
        if (!isPotentiallyReachable(X, &CB) &&
            !(classifyBase(*X, T, S) == Class::Noreturn && !isPotentiallyReachable(&CB, X)))
          continue;
        if (hostEffect && !X->isInlineAsm() && !directCallee(*X) && classifyBase(*X, T, S) == Class::Indirect)
          unimplemented("spine: calls::classify: a classical host effect that an indirect call with a quantum "
                        "part may precede (whether its target records a tape entry is not analysed; CR rule 16, "
                        "owner ruling 2026-11-02)",
                        &CB);
        if (tapePoint(*X, S))
          return true;
      }
    return false;
  }

  // May a call of the callee specialization C (or of the never-rewritten function G, C null) perform a
  // host effect directly, not on the tape?
  bool hostDirect(const Specialization *C, const Function *G) {
    if (C)
      if (auto it = specHost.find(C); it != specHost.end())
        return it->second;
    SmallVector<const Specialization *, 8> specs;
    SmallVector<const Function *, 8> fns;
    if (C)
      reach(*C, specs, fns);
    else {
      fns.push_back(G);
      SmallPtrSet<const Function *, 8> seenF{G};
      for (size_t i = 0; i < fns.size(); ++i)
        for (const BasicBlock &BB : *fns[i])
          for (const Instruction &I : BB)
            if (auto *X = dyn_cast<CallBase>(&I))
              if (const Function *H = directCallee(*X); H && !H->isDeclaration() && seenF.insert(H).second)
                fns.push_back(H);
    }
    bool r = false;
    for (const Specialization *D : specs)
      for (const BasicBlock &BB : *D->F)
        for (const Instruction &I : BB) {
          auto *X = dyn_cast<CallBase>(&I);
          if (!X || r || isa<DbgInfoIntrinsic>(X))
            continue;
          Class k = classifyBase(*X, T, *D);
          if (tapeCandidate(*X, k))
            r = !after(*X, *D, true);   // promoted there when a tape point of its own precedes it
          else if (k == Class::Classical && !X->isInlineAsm() && !directCallee(*X))
            r = true;                   // an indirect classical call: unknown callee
        }
    for (const Function *H : fns)
      for (const BasicBlock &BB : *H)
        for (const Instruction &I : BB) {
          auto *X = dyn_cast<CallBase>(&I);
          if (!X || r || isa<DbgInfoIntrinsic>(X))
            continue;
          if (X->isInlineAsm())
            r = X->mayHaveSideEffects();
          else if (!directCallee(*X))
            r = true;
          else
            r = tapeCandidate(*X, Class::Classical);
        }
    if (C)
      specHost[C] = r;
    return r;
  }
};

} // namespace

Class classify(const CallBase &CB, const TaintInfo &T, const Specialization &S) {
  // cq-a63l (rule 16, a result the program reads): the formatting body on a null buffer that
  // tape::rewriteDeferredResults put in front of a deferred printf writes nothing on the host (size 0) but
  // through %n; it is lifted by rule 18 when it has a body, else a rule 27 declared clone when handed a
  // quantum argument, else the ordinary call. Never a tape entry.
  if (CB.getMetadata("cq.deferred.result")) {
    const Function *G = directCallee(CB);
    if (G && !G->isDeclaration())
      return classifyBase(CB, T, S);
    return anyQuantumArg(CB, T, S) ? Class::Declared : Class::Classical;
  }
  Class k = classifyBase(CB, T, S);
  if (k != Class::Classical && k != Class::Lift)
    return k;
  if (isa<DbgInfoIntrinsic>(CB) || CB.getFunction() != S.F)
    return k;
  if (tapeCandidate(CB, k)) {
    TapeOrder o(T);
    return o.after(CB, S, true) ? Class::HostEffect : k;
  }
  const Function *G = directCallee(CB);
  bool indirect = !G && !CB.isInlineAsm() && k == Class::Classical;
  if (!indirect && (!G || G->isDeclaration()))
    return k;
  TapeOrder o(T);
  bool host;
  if (indirect)
    host = true;
  else if (const Specialization *D = T.calleeSpecialization(CB, S))
    host = o.hostDirect(D, nullptr);
  else
    host = k == Class::Classical && o.hostDirect(nullptr, G);
  if (host && o.after(CB, S, false))
    unimplemented("spine: calls::classify: a call that a tape entry or a quantum-predicated abort may precede, "
                  "of a callee that may perform a host effect directly (CR rule 16, owner ruling 2026-11-02: "
                  "every host effect after a tape point goes on the tape)",
                  &CB);
  return k;
}

} // namespace calls

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
    // A computed goto or an asm goto chooses its successor by its address or its asm: quantum when
    // that operand is (rule 8's quantum branch, the address a fat pointer's tag), else classical.
    if (auto *ib = dyn_cast<IndirectBrInst>(t))
      return quantumValue(T, S, ib->getAddress());
    if (auto *cb = dyn_cast<CallBrInst>(t))
      return any_of(cb->args(), [&](const Use &u) { return quantumValue(T, S, u.get()); });
    return false;
  };

  // Control dependence inside the loop: X depends on a quantum terminator of Y in the loop when X
  // is reachable from a successor of Y without passing Y's in-loop post-dominator. Approximated
  // exactly on the loop body by the standard post-dominator definition over the function.
  Function &F = *L.getHeader()->getParent();
  PostDominatorTree PDT(F);
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
  auto postDomLive = [&](const BasicBlock *X, const BasicBlock *Y) {
    for (const BasicBlock *s : successors(Y))
      if (!deadEnd(s) && L.contains(s) && !(s == X || PDT.dominates(X, s)))
        return false;
    return true;
  };
  auto controlQuantum = [&](const BasicBlock *X) {
    for (const BasicBlock *Y : L.blocks()) {
      if (Y == X || !quantumTerm(Y))
        continue;
      for (const BasicBlock *s : successors(Y))
        if (L.contains(s) && (s == X || PDT.dominates(X, s)) && !postDomLive(X, Y))
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

  bool anyQuantum = false, classicalBound = false;
  for (BasicBlock *X : exiting) {
    const Instruction *t = X->getTerminator();
    // An exit only into dead ends is never taken (131's switch default): no exit of the loop.
    if (all_of(successors(X), [&](const BasicBlock *s) { return L.contains(s) || deadEnd(s); }))
      continue;
    bool internal = controlQuantum(X);
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional()) {
      bool exitOnTrue = !L.contains(br->getSuccessor(0));
      bool q = quantumValue(T, S, br->getCondition()) || internal;
      if (!q) {
        // cq-z6q1 (189): a classical exit is a bound only when LLVM computes its exit count; a test of data
        // read from memory (p->next == NULL) bounds nothing, and the loop is a K-loop.
        if (exitCountKnown(*L.getHeader(), *X))
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
        if (!quantumValue(T, S, d.first) && exitCondCountKnown(*L.getHeader(), *d.first, d.second))
          classicalBound = true;
    } else if (isa<SwitchInst>(t)) {
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
  if (!anyQuantum)
    return Case::ClassicalBound;
  return classicalBound ? Case::ClassicalBoundQuantumExit : Case::QuantumExit;
}

} // namespace loops
} // namespace cq
