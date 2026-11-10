// Module eff-tape (cq-w1-eff-tape): CR rule 16, host effects and noreturn arms; BACKEND_ABI §1.11.
//
// lowerHostEffect (rule 16): a host call taint made an entry is one call sequence on the function's tape t (one
// cqrt_tape_alloc at the entry of each function that records an entry; 47): the fields, then
// cqrt_tape_effect[_<W>]_controlled(c, t, name, n), n the number of fields. c is the predicate in scope or an alloc_i1(true) seed freed right after
// the effect call. The _<W> form is used when the program reads the result, the rail it returns: KEPT. name is the C
// identifier as @.cq.effect.<name>. The fields are the arguments in order: a classical one a tape_write_<W>_lit, a rail a
// tape_write_<W> field (Role::Tape, kept), a pointer its address (i64), a vector its lanes; a buffer or string is never
// expanded. printf is the format entry tape_fmt[_controlled]([c,] t, fmt) with its variadic arguments as fields by
// promoted IR type (47, 138; rulings2 C: all of them, excess ones too). A _pure clone records nothing. The effect call
// is the memory version change (rule 5; a format entry is none).
#include "cq/Effects.h"


#include "cq/Abi.h"
#include "cq/Aggregates.h"
#include "../../bus/BusInternal.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/TargetParser/Triple.h"

#include <functional>
#include <map>
#include <vector>
#include <memory>
#include <string>

using namespace llvm;

namespace cq::tape {

namespace {

// ------------------------------------------------------------------ recognition

bool libFunc(const Function &F, LibFunc want) {
  LibFunc lf;
  return libFuncOf(F, lf) && lf == want;
}

const Function *calleeOf(const CallBase &CB) {
  return dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
}

bool isThetaSurface(const Function *F) {
  return F && F->isDeclaration() && F->getName().starts_with("cq_theta_") && F->arg_size() == 2;
}

// ------------------------------------------------------------------ the tape

// One tape per output function, at the start of its entry block. A WeakVH drops out with the function.
Value *tapeOf(LoweringContext &ctx) {
  static DenseMap<const Function *, WeakVH> tapes;
  Function &out = ctx.out();
  auto it = tapes.find(&out);
  if (it != tapes.end() && it->second) {
    auto *I = dyn_cast<Instruction>(&*it->second);
    if (I && I->getFunction() == &out)
      return I;
  }
  FunctionCallee alloc = abi::declare(ctx.M, abi::CoreSpec{abi::Core::TapeAlloc});
  BasicBlock &entry = out.getEntryBlock();
  IRBuilder<> B(&entry, entry.getFirstInsertionPt());
  CallInst *t = B.CreateCall(alloc);
  tapes[&out] = WeakVH(t);
  return t;
}

// ------------------------------------------------------------------ fields

// One argument printf consumes: its index among the variadic arguments (0 = the first after the
// format) and its conversion character ('*' for a width or precision).
struct Consume {
  unsigned arg;
  char conv;
};

// printf's consumption plan of a constant format, in the order printf reads its arguments, and the
// format the tape entry carries. A positional format (C17 7.21.6.1 has none; POSIX `%n$`, `*m$`)
// names its arguments by number: the entry carries the same format with the positions removed and its
// fields in the order the conversions read them (an argument read twice is two fields), which prints
// the same characters. Returns false when the format is not a constant string.
bool printfPlan(const Value *fmt, SmallVectorImpl<Consume> &plan, std::string &plain, bool &positional) {
  StringRef s;
  if (!getConstantStringInfo(fmt, s))
    return false;
  positional = false;
  plain.clear();
  unsigned next = 0;
  // A run of digits followed by '$' at i: its value - 1, i moved past the '$'.
  auto position = [&](size_t &i) -> std::optional<unsigned> {
    size_t j = i;
    while (j < s.size() && isdigit((unsigned char)s[j]))
      ++j;
    if (j == i || j >= s.size() || s[j] != '$')
      return std::nullopt;
    unsigned n = 0;
    s.substr(i, j - i).getAsInteger(10, n);
    i = j + 1;
    positional = true;
    return n ? n - 1 : 0;
  };
  for (size_t i = 0; i < s.size();) {
    if (s[i] != '%') {
      plain += s[i++];
      continue;
    }
    plain += s[i++];
    if (i < s.size() && s[i] == '%') {
      plain += s[i++];
      continue;
    }
    std::optional<unsigned> pos = position(i);
    while (i < s.size() && StringRef("-+ #0'").contains(s[i]))
      plain += s[i++];
    SmallVector<Consume, 2> stars;
    for (int part = 0; part < 2; ++part) {   // width, then precision
      if (part == 1) {
        if (i >= s.size() || s[i] != '.')
          break;
        plain += s[i++];
      }
      if (i < s.size() && s[i] == '*') {
        plain += s[i++];
        std::optional<unsigned> m = position(i);
        stars.push_back({m ? *m : next++, '*'});
      } else {
        while (i < s.size() && isdigit((unsigned char)s[i]))
          plain += s[i++];
      }
    }
    while (i < s.size() && StringRef("hlLqjzt").contains(s[i]))
      plain += s[i++];
    if (i >= s.size())
      break;
    char c = s[i];
    plain += s[i++];
    plan.append(stars.begin(), stars.end());
    plan.push_back({pos ? *pos : next++, c});
  }
  return true;
}


// One scalar field: a rail is cqrt_tape_write_<W>[_controlled] -> a fresh write-only tape rail (kept, never
// freed or uncomputed: Role::Tape); a classical value is cqrt_tape_write_<W>_lit (the entry's predicate
// covers it).
void scalarField(LoweringContext &ctx, Value *tape, Value *flag, const Operand &op, Type *ty) {
  RailType w = railTypeOf(ty);
  if (!op.handle) {
    ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, w}, {tape, op.v});
    return;
  }
  CallInst *h2 = flag ? ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w, /*ctl=*/true}, {flag, tape, op.v})
                      : ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w}, {tape, op.v});
  ctx.unc().recordExternal(h2, Role::Tape);
}

// The scalar leaves of a composite (rule 26: struct fields in order; rule 25: vector lanes).
void leafTypes(Type *t, SmallVectorImpl<Type *> &out) {
  if (auto *st = dyn_cast<StructType>(t)) {
    for (Type *e : st->elements())
      leafTypes(e, out);
  } else if (auto *at = dyn_cast<ArrayType>(t)) {
    for (uint64_t i = 0; i < at->getNumElements(); ++i)
      leafTypes(at->getElementType(), out);
  } else if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    for (unsigned i = 0; i < vt->getNumElements(); ++i)
      leafTypes(vt->getElementType(), out);
  } else {
    out.push_back(t);
  }
}





// One field of an entry: the scalar argument, a pointer its address (rule 21: an i64 literal or address rail), a vector
// its lanes, an aggregate its scalar fields.
// Returns the number of fields written.
unsigned emitField(LoweringContext &ctx, CallBase &CB, unsigned a, Value *tape, Value *flag) {
  Value *v = CB.getArgOperand(a);
  Type *ty = v->getType();
  Type *I64 = Type::getInt64Ty(ctx.M.getContext());
  if (ty->isPointerTy()) {
    scalarField(ctx, tape, flag, bus::address(ctx, v), I64);
    return 1;
  }
  if (ty->isIntegerTy() || ty->isFloatingPointTy()) {
    scalarField(ctx, tape, flag, ctx.operand(v), ty);
    return 1;
  }
  SmallVector<Type *, 4> tys;
  leafTypes(ty, tys);
  SmallVector<Operand, 4> ops = aggr::flattenResult(ctx, v);
  if (ops.size() != tys.size())
    internalError("eff-tape: a composite field whose leaves do not match its type", &CB);
  for (unsigned k = 0; k < ops.size(); ++k) {
    if (tys[k]->isPointerTy() && !ops[k].handle)
      scalarField(ctx, tape, flag, Operand{ctx.B().CreatePtrToInt(ops[k].v, I64), false}, I64);
    else
      scalarField(ctx, tape, flag, ops[k], tys[k]->isPointerTy() ? I64 : tys[k]);
  }
  return ops.size();
}

// The effect call of an entry of n fields: the _<W> form when the program reads the result, of type rt.
CallInst *effectCall(LoweringContext &ctx, Value *ctl, Value *tape, Constant *name, unsigned n, Type *rt, bool reads) {
  Value *count = ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), n);
  return reads ? ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffectW, railTypeOf(rt), /*ctl=*/true}, {ctl, tape, name, count})
               : ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffect, {}, /*ctl=*/true}, {ctl, tape, name, count});
}

Constant *effectName(Module &M, StringRef name) {
  // A Mach-O asm label "\01_n" names the C function n (Common.h libFuncOf): the entry names n.
  if (name.starts_with("\01_"))
    name = name.drop_front(2);
  std::string g = (".cq.effect." + name).str();
  if (GlobalVariable *gv = M.getNamedGlobal(g))
    return gv;
  Constant *init = ConstantDataArray::getString(M.getContext(), name, /*AddNull=*/true);
  auto *gv = new GlobalVariable(M, init->getType(), /*isConstant=*/true, GlobalValue::PrivateLinkage, init, g);
  gv->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  gv->setAlignment(Align(1));
  return gv;
}

// ------------------------------------------------------------------ noreturn look-ahead

// May a call to F (with a quantum or non-classical pointer argument) modify a caller's rail in place?
bool bodyMayModifyInPlace(const Function *F, SmallPtrSetImpl<const Function *> &seen) {
  if (!F || hostCallee(*F))
    return true;   // opaque (rule 27; a rule-16 stream call)
  if (!seen.insert(F).second)
    return false;
  for (const BasicBlock &bb : *F)
    for (const Instruction &I : bb) {
      if (isa<StoreInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I))
        return true;
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      if (CB->isInlineAsm())
        return true;
      const Function *G = calleeOf(*CB);
      if (!G)
        return true;
      if (isThetaSurface(G))
        return true;
      if (G->isIntrinsic()) {
        if (isa<MemIntrinsic>(CB))
          return true;
        continue;
      }
      if (hostCallee(*G)) {
        StringRef n = G->getName();
        if (n.starts_with("cq_measure_") || n == "cq_phi")
          continue;
        return true;
      }
      if (bodyMayModifyInPlace(G, seen))
        return true;
    }
  return false;
}

// The rails a later operation may modify in place on the abort branch, as handles of the new IR, in
// first-modification order.
SmallVector<std::pair<Value *, Type *>, 4> laterInPlaceTargets(LoweringContext &ctx, CallBase &CB) {
  Function &F = *CB.getFunction();
  BasicBlock *Ba = CB.getParent();
  DominatorTree DT(F);
  LoopInfo LI(DT);
  // An arm inside a loop (cq-py5f): later trips run every block of the outermost loop around it again,
  // under predicates of their own trip, so every block of that loop is later and no predicate excludes it.
  const Loop *outer = nullptr;
  for (BasicBlock *p : predecessors(Ba))
    for (const Loop *L = LI.getLoopFor(p); L; L = L->getParentLoop())
      if (!outer || L->contains(outer->getHeader()))
        outer = L;

  // Blocks that may run before the abort: those that reach it.
  SmallPtrSet<const BasicBlock *, 32> before;
  SmallVector<const BasicBlock *, 16> work{Ba};
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (!before.insert(b).second)
      continue;
    for (const BasicBlock *p : predecessors(b))
      work.push_back(p);
  }
  const Pred &pa = ctx.preds().block(Ba);

  // A rotation target's rails live at the abort (rule 3: representation changes keep the rail). A value
  // available at the abort (an argument, an instruction dominating it) is one; a merge (phi, select) or
  // an aggregate access names one of its operands; a call's result and any other template are fresh rails
  // (rules 4, 18, 27, U2); a load's cell content is mem's: the rail the cell holds at the abort when its
  // address is available there.
  SetVector<const Value *> roots;
  SmallPtrSet<const Value *, 32> visited;
  std::function<void(const Value *)> target = [&](const Value *v) {
    if (!visited.insert(v).second)
      return;
    if (auto *fr = dyn_cast<FreezeInst>(v))
      return target(fr->getOperand(0));
    if (auto *bc = dyn_cast<BitCastInst>(v))
      return target(bc->getOperand(0));
    if (isa<Constant>(v) || !ctx.T.isQuantum(v, ctx.S))
      return;
    if (isa<Argument>(v) || DT.dominates(cast<Instruction>(v), &CB)) {
      roots.insert(v);
      return;
    }
    auto *I = cast<Instruction>(v);
    if (auto *phi = dyn_cast<PHINode>(I)) {
      for (const Value *in : phi->incoming_values())
        target(in);
      return;
    }
    if (auto *sel = dyn_cast<SelectInst>(I)) {
      target(sel->getTrueValue());
      target(sel->getFalseValue());
      return;
    }
    if (auto *ev = dyn_cast<ExtractValueInst>(I))
      return target(ev->getAggregateOperand());
    if (auto *iv = dyn_cast<InsertValueInst>(I)) {
      target(iv->getAggregateOperand());
      target(iv->getInsertedValueOperand());
      return;
    }
    if (auto *ee = dyn_cast<ExtractElementInst>(I))
      return target(ee->getVectorOperand());
    if (auto *ie = dyn_cast<InsertElementInst>(I)) {
      target(ie->getOperand(0));
      target(ie->getOperand(1));
      return;
    }
    if (isa<LoadInst>(I)) {
      return;   // a bus load copies out into a fresh rail (§1.3)
    }
    // Any other instruction (a template, a call's result) is a fresh rail made after the abort (rule 4).
  };

  for (BasicBlock &X : F) {
    if (!DT.isReachableFromEntry(&X))
      continue;
    bool inLoop = outer && outer->contains(&X);
    if (before.count(&X) && !inLoop)
      continue;
    if (!inLoop && (ctx.preds().block(&X) & pa).isBottom())
      continue;   // never runs on the abort branch
    for (Instruction &I : X) {
      auto *C = dyn_cast<CallBase>(&I);
      if (!C)
        continue;
      using calls::Class;
      Class k = calls::classify(*C, ctx.T, ctx.S);
      if (k == Class::Theta) {
        target(C->getArgOperand(0));
        continue;
      }
      if (k == Class::Lift || k == Class::Declared || k == Class::Indirect || k == Class::Asm ||
          k == Class::Thread || k == Class::Varargs) {
        SmallPtrSet<const Function *, 8> seen;
        if (k == Class::Lift && !bodyMayModifyInPlace(calleeOf(*C), seen))
          continue;
        for (const Use &u : C->args()) {
          const Value *a = u.get();
          if (!a->getType()->isPointerTy()) {
            target(a);
            continue;
          }
        }
      }
    }
  }

  SmallVector<std::pair<Value *, Type *>, 4> out;
  SmallPtrSet<Value *, 8> seenH;
  for (const Value *v : roots) {
    Operand op = ctx.operand(v);
    if (!op.handle)
      continue;   // measured before the abort: a classical outcome, nothing to snapshot
    if (seenH.insert(op.v).second)
      out.push_back({op.v, v->getType()});
  }
  return out;
}

// The abort arm (rule 16): snapshots of the rails later modified in place, then abort_i1(flag), the flag kept.
void abortArm(LoweringContext &ctx, CallBase &CB, Value *flag) {
  auto targets = laterInPlaceTargets(ctx, CB);

  // A merged handle (a select/phi of rails, rule 9) cannot be kept itself: copy it out (Uncompute's
  // contract). A rail minted by a call (template, seed, gate) is kept as it is (45).
  // The flag itself rotated later (a register used as the arm's condition) is copied out as well: the copy
  // is the kept abort flag, and the register is snapshotted under it like any other target.
  bool flagModified = false;
  for (auto &t : targets)
    flagModified |= t.first == flag;
  RailType i1{Kind::Int, 1};
  if (!isa<CallInst>(flag) || flagModified) {
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, i1};
    CallInst *c = ctx.emitCore(cp, {flag, f});
    ctx.unc().recordCore(c, cp, {Operand{flag, true}, Operand{f, true}}, fid);
    flag = f;
  }

  for (auto &t : targets) {
    Value *h = t.first;
    RailType w = railTypeOf(t.second);
    CallInst *s = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                               {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
    RailId sid = ctx.unc().recordSeed(s);
    abi::CoreSpec cp{abi::Core::Copy, w, /*ctl=*/true};
    CallInst *c = ctx.emitCore(cp, {flag, h, s});
    ctx.unc().recordCore(c, cp, {Operand{flag, true}, Operand{h, true}, Operand{s, true}}, sid);
    ctx.unc().setRole(sid, Role::Abort);   // the abort branch's value of h: kept, never freed
  }

  ctx.emitCore(abi::CoreSpec{abi::Core::AbortI1, i1}, {flag});
  ctx.unc().setRole(ctx.unc().idOf(flag), Role::Abort);
}

} // namespace

void lowerHostEffect(LoweringContext &ctx, CallBase &CB) {
  if (ctx.S.pure)
    return;
  const Function *F = calleeOf(CB);
  if (!F)
    internalError("eff-tape: a host effect with no direct callee", &CB);
  Value *flag = bus::accessControl(ctx);
  LLVMContext &C = ctx.M.getContext();

  // A format at an address rail has no ptr for tape_fmt: it falls to the effect entry printf with its address a field.
  if (libFunc(*F, LibFunc_printf) && !bus::address(ctx, CB.getArgOperand(0)).handle) {
    Operand f = ctx.operand(CB.getArgOperand(0));
    Value *tape = tapeOf(ctx);
    if (flag)
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt, {}, /*ctl=*/true}, {flag, tape, f.v});
    else
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt}, {tape, f.v});
    for (unsigned a = 1; a < CB.arg_size(); ++a)
      emitField(ctx, CB, a, tape, flag);
    return;
  }

  Value *ctl = flag;
  if (!ctl) {
    CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {ConstantInt::getTrue(C)});
    ctx.unc().recordSeed(one);
    ctl = one;
  }
  Value *tape = tapeOf(ctx);
  unsigned fields = 0;
  for (unsigned a = 0; a < CB.arg_size(); ++a)
    fields += emitField(ctx, CB, a, tape, flag);
  Constant *name = effectName(ctx.M, calleeName(*F, &CB));
  Type *rt = CB.getType();
  bool reads = !rt->isVoidTy() && !CB.use_empty();
  bool wide = reads && (rt->isAggregateType() || rt->isVectorTy());
  reads = reads && !wide;
  CallInst *eff = effectCall(ctx, ctl, tape, name, fields, rt, reads);
  ctx.unc().noteVersionChange(eff);
  if (reads) {
    ctx.unc().recordExternal(eff, Role::Kept);   // the entry's result rail: never freed
    ctx.bind(&CB, eff);
  }
  if (wide) {
    // No _<W> form for a composite: rule 16's deferred result, |0> rails.
    SmallVector<Type *, 4> tys;
    leafTypes(rt, tys);
    SmallVector<Operand, 4> ops;
    for (Type *t : tys) {
      RailType w = railTypeOf(t);
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
      ctx.unc().recordExternal(z, Role::Kept);
      ops.push_back(Operand{z, true});
    }
    ctx.bindFields(&CB, ops);
  }
  // Rule 16: a noreturn callee with a rail argument and no predicate: abort_i1 of the seed.
  if (!flag && CB.doesNotReturn())
    abortArm(ctx, CB, ctl);
}

namespace {
// One entry under flag or an alloc_i1(true) seed freed right after it (rule 7): the optional first field, the actuals, the
// effect at `name`. A result the program reads is the _<W> rail; a composite's are |0> rails.
SmallVector<Value *, 2> entryOnTape(LoweringContext &ctx, CallBase &CB, const Operand *first, Constant *name, Value *flag) {
  LLVMContext &C = ctx.M.getContext();
  CallInst *one = flag ? nullptr
                       : ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {ConstantInt::getTrue(C)});
  Value *ctl = flag ? flag : one;
  Value *tape = tapeOf(ctx);
  unsigned fields = 0;
  if (first) {
    scalarField(ctx, tape, flag, *first, Type::getInt64Ty(C));
    ++fields;
  }
  for (unsigned a = 0; a < CB.arg_size(); ++a)
    fields += emitField(ctx, CB, a, tape, flag);
  Type *rt = CB.getType();
  bool reads = !rt->isVoidTy() && !CB.use_empty();
  bool wide = reads && (rt->isAggregateType() || rt->isVectorTy());
  reads = reads && !wide;
  CallInst *eff = effectCall(ctx, ctl, tape, name, fields, rt, reads);
  ctx.unc().noteVersionChange(eff);
  SmallVector<Value *, 2> out;
  if (reads) {
    ctx.unc().recordExternal(eff, Role::Kept);
    out.push_back(eff);
  }
  if (wide) {
    SmallVector<Type *, 4> tys;
    leafTypes(rt, tys);
    for (Type *t : tys) {
      RailType w = railTypeOf(t);
      CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(C, w))});
      ctx.unc().recordExternal(z, Role::Kept);
      out.push_back(z);
    }
  }
  if (one)
    ctx.emitCore(abi::CoreSpec{abi::Core::Free}, {one});
  return out;
}
} // namespace

SmallVector<Value *, 2> lowerTableEffect(LoweringContext &ctx, CallBase &CB, Operand callee, Value *flag) {
  return entryOnTape(ctx, CB, &callee, ConstantPointerNull::get(PointerType::getUnqual(ctx.M.getContext())), flag);
}

SmallVector<Value *, 2> lowerRaiseEffect(LoweringContext &ctx, CallBase &CB, Value *flag) {
  return entryOnTape(ctx, CB, nullptr, effectName(ctx.M, "raise"), flag);
}

void lowerMainExit(LoweringContext &ctx, Operand r, Type *ty) {
  if (ctx.S.pure)
    return;
  CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}},
                               {ConstantInt::getTrue(ctx.M.getContext())});
  ctx.unc().recordSeed(one);
  Value *tape = tapeOf(ctx);
  scalarField(ctx, tape, nullptr, r, ty);
  CallInst *eff = effectCall(ctx, one, tape, effectName(ctx.M, "exit"), 1, nullptr, false);
  ctx.unc().noteVersionChange(eff);
}

bool rewriteDeferredResults(Module &M, const TaintInfo &T) {
  // The printf-family calls some specialization defers (rule 16) whose count is read or whose format may
  // write through %n (a format that is not a constant string may hold one).
  SetVector<CallBase *> sites;
  for (const Specialization &S : T.specializations()) {
    if (S.F->isDeclaration() || S.pure)
      continue;
    for (BasicBlock &bb : *S.F)
      for (Instruction &I : bb) {
        auto *CB = dyn_cast<CallBase>(&I);
        const Function *F = CB ? calleeOf(*CB) : nullptr;
        if (!F || !(libFunc(*F, LibFunc_printf) || libFunc(*F, LibFunc_fprintf)))
          continue;
        if (calls::classify(*CB, T, S) != calls::Class::HostEffect)
          continue;
        unsigned fmtArg = libFunc(*F, LibFunc_fprintf) ? 1 : 0;
        StringRef fmt;
        bool percentN = !getConstantStringInfo(CB->getArgOperand(fmtArg), fmt);
        if (!percentN) {
          SmallVector<Consume, 8> plan;
          std::string plain;
          bool positional = false;
          printfPlan(CB->getArgOperand(fmtArg), plan, plain, positional);
          percentN = any_of(plan, [](const Consume &k) { return k.conv == 'n'; });
        }
        if (!CB->use_empty() || percentN)
          sites.insert(CB);
      }
  }
  if (sites.empty())
    return false;
  LLVMContext &C = M.getContext();
  Type *ptr = PointerType::get(C, 0), *i32 = Type::getInt32Ty(C);
  Type *sizeT = M.getDataLayout().getIntPtrType(C);
  FunctionCallee snp = M.getOrInsertFunction("snprintf", FunctionType::get(i32, {ptr, sizeT, ptr}, /*isVarArg=*/true));
  for (CallBase *CB : sites) {
    unsigned fmtArg = libFunc(*calleeOf(*CB), LibFunc_fprintf) ? 1 : 0;
    SmallVector<Value *, 8> args{ConstantPointerNull::get(cast<PointerType>(ptr)), ConstantInt::get(sizeT, 0)};
    for (unsigned a = fmtArg; a < CB->arg_size(); ++a)
      args.push_back(CB->getArgOperand(a));
    IRBuilder<> B(CB);
    CallInst *n = B.CreateCall(snp, args);
    n->setMetadata("cq.deferred.result", MDNode::get(C, {}));
    if (!CB->use_empty() && CB->getType() == n->getType())
      CB->replaceAllUsesWith(n);
  }
  return true;
}

void lowerNoreturn(LoweringContext &ctx, CallBase &CB) {
  if (ctx.S.pure)
    return;
  // Rule 16 lowers the call to abort_i1(pred) alone: its arguments (exit's status, __assert_fail's
  // strings), classical or quantum, are dropped, as the program they would end continues uncontrolled.
  Value *flag = bus::accessControl(ctx);
  if (!flag) {
    // The quantum predicate in scope is top (the arm is reached on every branch): the abort flag is a
    // seed rail |1>, kept like any abort flag.
    RailType i1{Kind::Int, 1};
    CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getTrue(ctx.M.getContext())});
    ctx.unc().recordSeed(one);
    flag = one;
  }
  abortArm(ctx, CB, flag);
}

} // namespace cq::tape
