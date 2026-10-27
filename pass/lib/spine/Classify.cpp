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
  case Intrinsic::cttz: case Intrinsic::ctpop: case Intrinsic::bswap: case Intrinsic::smax:
  case Intrinsic::smin: case Intrinsic::umax: case Intrinsic::umin: case Intrinsic::uadd_sat:
  case Intrinsic::usub_sat: case Intrinsic::uadd_with_overflow: case Intrinsic::sadd_with_overflow:
  case Intrinsic::umul_with_overflow: case Intrinsic::smul_with_overflow:
  case Intrinsic::usub_with_overflow: case Intrinsic::ssub_with_overflow: case Intrinsic::is_fpclass:
    return true;
  default:
    return false;
  }
}

// LLVM math intrinsics that stand for a libm call (rule 18: lifted as that libm function).
bool isLibmIntrinsic(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::exp: case Intrinsic::exp2: case Intrinsic::exp10: case Intrinsic::log:
  case Intrinsic::log2: case Intrinsic::log10: case Intrinsic::sin: case Intrinsic::cos:
  case Intrinsic::tan: case Intrinsic::pow: case Intrinsic::powi: case Intrinsic::ldexp:
  case Intrinsic::frexp: case Intrinsic::nearbyint: case Intrinsic::roundeven: case Intrinsic::lround:
  case Intrinsic::llround: case Intrinsic::lrint: case Intrinsic::llrint: case Intrinsic::minimum:
  case Intrinsic::maximum:
    return true;
  default:
    return false;
  }
}

// A library function LLVM knows by semantics (TargetLibraryInfo for the module's triple).
bool knownLibFunc(const Function &F) {
  static thread_local std::unique_ptr<TargetLibraryInfoImpl> impl;
  static thread_local std::string triple;
  const Module *M = F.getParent();
  if (!impl || triple != M->getTargetTriple()) {
    triple = M->getTargetTriple();
    impl = std::make_unique<TargetLibraryInfoImpl>(Triple(triple));
  }
  TargetLibraryInfo TLI(*impl, &F);
  LibFunc lf;
  return TLI.getLibFunc(F, lf);
}

bool mayHaveHostEffect(const CallBase &CB) {
  return !CB.onlyReadsMemory() || CB.mayThrow() || !CB.willReturn();
}

} // namespace

namespace calls {

Class classify(const CallBase &CB, const TaintInfo &T, const Specialization &S) {
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
    return Class::Classical;
  }

  if (F->isIntrinsic()) {
    Intrinsic::ID id = F->getIntrinsicID();
    if (isa<ConstrainedFPIntrinsic>(CB))
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
      // A VLA's lifetime ends here (rule 20, 192) when the scope holds a slot or QRAM object.
      return qPred || qArg ? Class::Dealloc : Class::Classical;
    }
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
    unimplemented("spine: calls::classify: an intrinsic with a quantum operand that no rule routes", &CB);
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
    bool block = T.classOf(T.objectOf(&CB)) != ObjClass::Classical;
    if ((ak & AllocFnKind::Realloc) != AllocFnKind::Unknown)
      return block || qArg ? Class::Realloc : Class::Classical;
    if ((ak & AllocFnKind::Alloc) != AllocFnKind::Unknown)
      return block || qArg ? Class::Alloc : Class::Classical;
  }

  if (!F->isDeclaration()) {
    // A callee with a body: lifted (rule 18), inlined (rule 19, an entry returning an unmeasured
    // quantum value; the spine's dispatch decides), or a _ctl / merged callee under a predicate.
    if (qArg || qRes || qPred)
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
  if (qArg && knownLibFunc(*F) && mayHaveHostEffect(CB))
    return Class::HostEffect;   // printf(x) and friends (47, 99, 138)
  if (qArg || qRes)
    return Class::Declared;     // rule 27
  if (qPred && mayHaveHostEffect(CB))
    return Class::HostEffect;   // signal, raise, remove under a quantum arm (102)
  return Class::Classical;
}

} // namespace calls

namespace loops {

// Rule 14. An exit is quantum when its condition is, or when its exiting block is control dependent
// on a quantum terminator inside the loop. A loop with a quantum exit has a classical bound when
// some exit is classical or a quantum exit condition has a classical disjunct of its exit test
// (`c || q`, 26, 121, 130, 139).
Case classify(const Loop &L, const TaintInfo &T, const Specialization &S) {
  SmallVector<BasicBlock *, 4> exiting;
  L.getExitingBlocks(exiting);

  auto quantumTerm = [&](const BasicBlock *B) {
    const Instruction *t = B->getTerminator();
    if (auto *br = dyn_cast<BranchInst>(t))
      return br->isConditional() && quantumValue(T, S, br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return quantumValue(T, S, sw->getCondition());
    if (isa<IndirectBrInst>(t) || isa<CallBrInst>(t))
      unimplemented("spine: loops::classify: indirectbr/callbr in a loop", t);
    return false;
  };

  // Control dependence inside the loop: X depends on a quantum terminator of Y in the loop when X
  // is reachable from a successor of Y without passing Y's in-loop post-dominator. Approximated
  // exactly on the loop body by the standard post-dominator definition over the function.
  Function &F = *L.getHeader()->getParent();
  PostDominatorTree PDT(F);
  auto controlQuantum = [&](const BasicBlock *X) {
    for (const BasicBlock *Y : L.blocks()) {
      if (Y == X || !quantumTerm(Y))
        continue;
      for (const BasicBlock *s : successors(Y))
        if (L.contains(s) && (s == X || PDT.dominates(X, s)) && !PDT.properlyDominates(X, Y))
          return true;
    }
    return false;
  };

  // Disjuncts of "exit taken": cond (exit on true) or !cond (exit on false), through and/or/select.
  std::function<void(const Value *, bool, SmallVectorImpl<std::pair<const Value *, bool>> &)> disjuncts;
  disjuncts = [&](const Value *c, bool positive, SmallVectorImpl<std::pair<const Value *, bool>> &out) {
    const Value *a = nullptr, *b = nullptr;
    bool isOr = false, isAnd = false;
    if (auto *bo = dyn_cast<BinaryOperator>(c); bo && bo->getType()->isIntegerTy(1)) {
      if (bo->getOpcode() == Instruction::Or) { isOr = true; a = bo->getOperand(0); b = bo->getOperand(1); }
      if (bo->getOpcode() == Instruction::And) { isAnd = true; a = bo->getOperand(0); b = bo->getOperand(1); }
    } else if (auto *sel = dyn_cast<SelectInst>(c); sel && sel->getType()->isIntegerTy(1)) {
      if (auto *k = dyn_cast<ConstantInt>(sel->getTrueValue()); k && k->isOne()) {
        isOr = true; a = sel->getCondition(); b = sel->getFalseValue();
      } else if (auto *k2 = dyn_cast<ConstantInt>(sel->getFalseValue()); k2 && k2->isZero()) {
        isAnd = true; a = sel->getCondition(); b = sel->getTrueValue();
      }
    }
    if ((isOr && positive) || (isAnd && !positive)) {
      disjuncts(a, positive, out);
      disjuncts(b, positive, out);
      return;
    }
    out.push_back({c, positive});
  };

  bool anyQuantum = false, classicalBound = false;
  for (BasicBlock *X : exiting) {
    const Instruction *t = X->getTerminator();
    bool internal = controlQuantum(X);
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional()) {
      bool exitOnTrue = !L.contains(br->getSuccessor(0));
      bool q = quantumValue(T, S, br->getCondition()) || internal;
      if (!q) {
        classicalBound = true;
        continue;
      }
      anyQuantum = true;
      if (internal)
        continue;
      SmallVector<std::pair<const Value *, bool>, 4> ds;
      disjuncts(br->getCondition(), exitOnTrue, ds);
      for (auto &d : ds)
        if (!quantumValue(T, S, d.first))
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
