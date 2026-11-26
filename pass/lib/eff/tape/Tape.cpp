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
#include "../../calls/CallsInternal.h"
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

#include <cstring>
#include <functional>
#include <optional>
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
// the same characters.
void printfPlanOf(StringRef s, SmallVectorImpl<Consume> &plan, std::string &plain, bool &positional) {
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
    scalarField(ctx, tape, flag, bus::address(ctx, v, /*access=*/false), I64);
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

// May a call to F modify a caller's rail it reads by value in place? Memory writes do not (cq-e1ebs): a store leaves its
// value rail unchanged (ABI qram_store), and the pointer arguments are no snapshot targets (laterInPlaceTargets).
bool bodyMayModifyInPlace(const Function *F, SmallPtrSetImpl<const Function *> &seen) {
  if (!F || hostCallee(*F))
    return true;   // opaque (rule 27; a rule-16 stream call)
  if (!seen.insert(F).second)
    return false;
  for (const BasicBlock &bb : *F)
    for (const Instruction &I : bb) {
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
      if (G->isIntrinsic())
        continue;
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
        // A step of a rule-5 in-place form rotates the cell's content (swapped in), not its operand's rail; a store
        // into that cell after the abort displaced the content it had there into a kept tape slot (ABI qram_store).
        if (bus::inPlaceOnCell(ctx, *C))
          continue;
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
  // A flag minted in another block (cq-58yqb: the arm's quantum predicate, the abort behind a classical branch) is
  // still uncomputed on the paths that skip the arm: the kept flag is a copy made here (as Cutoff's trip flag).
  RailType i1{Kind::Int, 1};
  if (!isa<CallInst>(flag) || flagModified || cast<CallInst>(flag)->getParent() != ctx.B().GetInsertBlock()) {
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

  // Rule 16 noreturn: under a quantum predicate it is abort_i1(pred) alone, never an entry. Taint makes a noreturn call
  // an entry only where its control dependence sees no quantum predicate (a rail argument, or an event before it, ruling
  // 2026-11-11 Q7); a K-loop's trip exit flag is one it does not see (CR rule 14 "No live exit": the arm may post-dominate
  // the loop), and there the call is the abort arm on that flag.
  if (flag && CB.doesNotReturn()) {
    abortArm(ctx, CB, flag);
    return;
  }

  // A format at an address rail has no ptr for tape_fmt: it falls to the effect entry printf with its address a field.
  if (libFunc(*F, LibFunc_printf) && !bus::address(ctx, CB.getArgOperand(0), /*access=*/false).handle) {
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
  // CR rule 16's noreturn bullet names llvm.trap by its C name: the entry __builtin_trap.
  Constant *name =
      effectName(ctx.M, F->getIntrinsicID() == Intrinsic::trap ? std::string("__builtin_trap") : calleeName(*F, &CB));
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
  storeFailureErrno(ctx, CB);
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

namespace {

// ------------------------------------------------------------------ deferred output calls (rule 16, 2026-11-12)

// The C library output calls whose result the circuit computes (owner ruling 2026-11-12, DECISIONS.md): an output
// call is a pure part (formatting, counting, encoding) plus a write; only the write is a tape effect. The result is
// the value musl b1efda5's body returns when every write succeeds, computed by ordinary lowered code: a format's
// count is the bundle's result entry (bundle/recipe.json "entries", bundle/src/cq_count.c) lifted (rule 18), the
// rest a template over the arguments. A failed write is never produced (the ruling's stated deviation).
enum class OutKind : uint8_t {
  Fmt,     // printf, fprintf, dprintf: __cq_count_snprintf(0, 0, fmt, args...)
  VFmt,    // vprintf, vfprintf, vdprintf: __cq_count_vsnprintf(0, 0, fmt, ap); musl's vfprintf copies ap (675)
  WFmt,    // wprintf, fwprintf: __cq_count_wprintf(fmt, args...)
  VWFmt,   // vwprintf, vfwprintf: __cq_count_vwprintf(fmt, ap)
  Zero,    // puts, fputs, fflush, putw (and _unlocked): 0
  UChar,   // fputc, putc, putchar (and _unlocked): (unsigned char)c
  Fwrite,  // fwrite (and _unlocked): size ? nmemb : 0
  Wc,      // fputwc, putwc, putwchar (and _unlocked): wctomb(buf, c) < 0 ? WEOF : c
  Ws,      // fputws (and _unlocked): wcsrtombs(0, &ws, 0, 0) == -1 ? -1 : 0
  // The other C library calls rule 16 names that are effect entries and no input calls (owner ruling 2026-11-12 on
  // cq-dbtpi, CR rule 16 Results): musl's value when the host operation succeeds.
  Status,  // fclose, remove, rename, fsetpos, close: 0
  Range,   // fseek, fseeko (whence), setvbuf (type): (unsigned)arg > 2 ? -1 : 0; raise (sig): (unsigned)sig > 64 ? -1 : 0
  Length,  // write: its length
};

struct OutFn {
  OutKind kind;
  unsigned first;   // the format (Fmt..VWFmt) or the value argument (UChar, Wc, Ws, Range, Length)
  unsigned max = 0; // Range: the largest valid value
  // Range: musl sets errno to EINVAL with the -1 (owner ruling 2026-11-13, CR rule 16 Results): fseek.c
  // __fseeko_unlocked (`errno = EINVAL; return -1;`), raise.c (tkill's -EINVAL through __syscall_ret); setvbuf.c
  // returns -1 with no store.
  bool einval = false;
};

// By C name (a Mach-O asm label "\01_n" names n). Decisions by the ruling's criterion and musl's source, beyond the
// named list: dprintf/vdprintf are vfprintf on an fd FILE (vdprintf.c), the count on success; putw is
// fwrite(&x, sizeof x, 1, f) - 1 (putw.c), 0; fflush is 0 (fflush.c); an _unlocked form is its locked form.
// perror and psignal return nothing.
// cq-dbtpi (owner 2026-11-12; CR rule 16 Results), checked against musl b1efda5's source: fclose.c (fflush and the
// close: 0), remove.c, rename.c (the syscall: 0), fsetpos.c (__fseeko with SEEK_SET: 0), close.c (0); fseek.c
// __fseeko_unlocked (-1 for a whence other than SEEK_SET 0, SEEK_CUR 1, SEEK_END 2, else 0 when the seek succeeds),
// setvbuf.c (-1 for a type other than _IOFBF 0, _IOLBF 1, _IONBF 2, else 0); raise.c (tkill: 0 for 0 <= sig <= 64,
// else EINVAL, -1; rule 16's complement branch, and 0 under every candidate flag, where sig is a valid number since
// signal registers nothing at an invalid one: so the one value for the whole call); write.c (the syscall: count).
// A failed host operation is never produced (the ruling's stated deviation). Host-state results (fopen, tmpfile,
// ftell, fileno, fwide, open, lseek) and every other callee keep the entry's rail (ABI 1.11, Q2).
std::optional<OutFn> outputFunction(const Function &F) {
  // The status calls: recognised by name and signature as rule 16's stream calls (streamCallee), raise by protoOf.
  {
    StringRef c = F.getName();
    if (c.starts_with("\01_"))
      c = c.drop_front(2);
    static const std::map<std::string, OutFn, std::less<>> status = {
        {"fclose", {OutKind::Status, 0}},     {"remove", {OutKind::Status, 0}}, {"rename", {OutKind::Status, 0}},
        {"fsetpos", {OutKind::Status, 0}},    {"close", {OutKind::Status, 0}},
        {"fseek", {OutKind::Range, 2, 2, true}}, {"fseeko", {OutKind::Range, 2, 2, true}},
        {"setvbuf", {OutKind::Range, 2, 2}},  {"write", {OutKind::Length, 2}},
    };
    if (auto it = status.find(c); it != status.end()) {
      FunctionType *ft = F.getFunctionType();
      const OutFn &o = it->second;
      if (!streamCallee(F) || !ft->getReturnType()->isIntegerTy() ||
          (o.kind != OutKind::Status && (o.first >= ft->getNumParams() || !ft->getParamType(o.first)->isIntegerTy())))
        return std::nullopt;
      return o;
    }
    if (c == "raise") {
      FunctionType *ft = F.getFunctionType();
      if (!hostCallee(F) || ft->isVarArg() || ft->getNumParams() != 1 || !ft->getReturnType()->isIntegerTy(32) ||
          !ft->getParamType(0)->isIntegerTy(32))
        return std::nullopt;
      return OutFn{OutKind::Range, 0, 64, true};
    }
  }
  StringRef n = F.getName();
  if (n.starts_with("\01_"))
    n = n.drop_front(2);
  if (n.ends_with("_unlocked"))
    n = n.drop_back(strlen("_unlocked"));
  static const std::map<std::string, OutFn, std::less<>> table = {
      {"printf", {OutKind::Fmt, 0}},     {"fprintf", {OutKind::Fmt, 1}},    {"dprintf", {OutKind::Fmt, 1}},
      {"vprintf", {OutKind::VFmt, 0}},   {"vfprintf", {OutKind::VFmt, 1}},  {"vdprintf", {OutKind::VFmt, 1}},
      {"wprintf", {OutKind::WFmt, 0}},   {"fwprintf", {OutKind::WFmt, 1}},
      {"vwprintf", {OutKind::VWFmt, 0}}, {"vfwprintf", {OutKind::VWFmt, 1}},
      {"puts", {OutKind::Zero, 0}},      {"fputs", {OutKind::Zero, 0}},     {"fflush", {OutKind::Zero, 0}},
      {"putw", {OutKind::Zero, 0}},
      {"fputc", {OutKind::UChar, 0}},    {"putc", {OutKind::UChar, 0}},     {"putchar", {OutKind::UChar, 0}},
      {"fwrite", {OutKind::Fwrite, 0}},
      {"fputwc", {OutKind::Wc, 0}},      {"putwc", {OutKind::Wc, 0}},       {"putwchar", {OutKind::Wc, 0}},
      {"fputws", {OutKind::Ws, 0}},
  };
  auto it = table.find(n);
  if (it == table.end())
    return std::nullopt;
  // The prototype (a program's own function of that name with another one is not the library's).
  FunctionType *ft = F.getFunctionType();
  OutFn o = it->second;
  auto argIs = [&](unsigned i, bool ptr) {
    return i < ft->getNumParams() && (ptr ? ft->getParamType(i)->isPointerTy() : ft->getParamType(i)->isIntegerTy());
  };
  if (!ft->getReturnType()->isIntegerTy())
    return std::nullopt;
  switch (o.kind) {
  case OutKind::Fmt: case OutKind::WFmt:
    return ft->isVarArg() && ft->getNumParams() == o.first + 1 && argIs(o.first, true) ? std::optional(o) : std::nullopt;
  case OutKind::VFmt: case OutKind::VWFmt:
    return !ft->isVarArg() && ft->getNumParams() == o.first + 2 && argIs(o.first, true) && argIs(o.first + 1, true)
               ? std::optional(o) : std::nullopt;
  case OutKind::Zero:
    return !ft->isVarArg() ? std::optional(o) : std::nullopt;
  case OutKind::UChar: case OutKind::Wc:
    return !ft->isVarArg() && argIs(0, false) ? std::optional(o) : std::nullopt;
  case OutKind::Fwrite:
    return !ft->isVarArg() && ft->getNumParams() == 4 && argIs(0, true) && argIs(1, false) && argIs(2, false)
               ? std::optional(o) : std::nullopt;
  case OutKind::Ws:
    return !ft->isVarArg() && argIs(0, true) ? std::optional(o) : std::nullopt;
  }
  return std::nullopt;
}

bool isFormat(OutKind k) { return k == OutKind::Fmt || k == OutKind::VFmt || k == OutKind::WFmt || k == OutKind::VWFmt; }

// May the format at fmt write through %n? True unless it is a constant string (narrow, or wide: an array of i32 code
// units, a unit above 0x7f read as a plain character) with no n conversion.
bool formatMayHoldN(const Value *fmt, bool wide) {
  std::string text;
  if (!wide) {
    StringRef s;
    if (!getConstantStringInfo(fmt, s))
      return true;
    text = s.str();
  } else {
    auto *gv = dyn_cast<GlobalVariable>(getUnderlyingObject(fmt));
    if (!gv || !gv->isConstant() || !gv->hasDefinitiveInitializer() || fmt != gv)
      return true;
    auto *cds = dyn_cast<ConstantDataSequential>(gv->getInitializer());
    if (!cds || !cds->getElementType()->isIntegerTy(32))
      return !isa<ConstantAggregateZero>(gv->getInitializer());
    for (unsigned i = 0; i < cds->getNumElements(); ++i) {
      uint64_t u = cds->getElementAsInteger(i);
      if (!u)
        break;
      text += u < 0x80 ? char(u) : '?';
    }
  }
  SmallVector<Consume, 8> plan;
  std::string plain;
  bool positional = false;
  printfPlanOf(text, plan, plain, positional);
  return any_of(plan, [](const Consume &k) { return k.conv == 'n'; });
}

// An alloca at the entry of F's entry block.
AllocaInst *entryAlloca(Function &F, Type *ty, uint64_t n, const Twine &name) {
  IRBuilder<> B(&F.getEntryBlock(), F.getEntryBlock().getFirstInsertionPt());
  Type *i64 = Type::getInt64Ty(F.getContext());
  return B.CreateAlloca(ty, n == 1 ? nullptr : ConstantInt::get(i64, n), name);
}

} // namespace

// Owner ruling 2026-11-13 (errno of a computed failure value): where outputFunction says musl stores EINVAL with its -1
// (a function of the arguments alone), the store under the same test, through the accessor signal uses
// (calls::storeEinvalAbove), whether the program reads the result or not. The errno of a failed host operation is never
// produced.
void storeFailureErrno(LoweringContext &ctx, CallBase &CB) {
  if (ctx.S.pure)
    return;
  const Function *F = calleeOf(CB);
  std::optional<OutFn> o = F && hostCallee(*F) && CB.getFunctionType() == F->getFunctionType() ? outputFunction(*F)
                                                                                                  : std::nullopt;
  if (!o || o->kind != OutKind::Range || !o->einval)
    return;
  calls::storeEinvalAbove(ctx, CB.getArgOperand(o->first), o->max);
}

bool rewriteDeferredResults(Module &M, const TaintInfo &T) {
  // The C library calls outputFunction names that some specialization makes effect entries (rule 16; raise: its
  // complement branch) whose result is read, or (a format) whose format may write through %n.
  SetVector<CallBase *> sites;
  for (const Specialization &S : T.specializations()) {
    if (S.F->isDeclaration() || S.pure)
      continue;
    for (BasicBlock &bb : *S.F)
      for (Instruction &I : bb) {
        auto *CB = dyn_cast<CallBase>(&I);
        const Function *F = CB ? calleeOf(*CB) : nullptr;
        // hostCallee: a body the bundle has for one of them is never lifted (rule 16; musl rows keep remove, raise).
        std::optional<OutFn> o = F && hostCallee(*F) ? outputFunction(*F) : std::nullopt;
        if (!o || CB->getFunctionType() != F->getFunctionType())
          continue;
        // raise is always rule 16's signal-table call (calls::lowerRaise): its complement branch is the effect entry.
        calls::Class k = calls::classify(*CB, T, S);
        if (k != calls::Class::HostEffect && !(k == calls::Class::Raise && o->kind == OutKind::Range))
          continue;
        bool percentN = isFormat(o->kind) &&
                        formatMayHoldN(CB->getArgOperand(o->first), o->kind == OutKind::WFmt || o->kind == OutKind::VWFmt);
        if (!CB->use_empty() || percentN)
          sites.insert(CB);
      }
  }
  if (sites.empty())
    return false;
  LLVMContext &C = M.getContext();
  PointerType *ptr = PointerType::get(C, 0);
  Type *i32 = Type::getInt32Ty(C), *i8 = Type::getInt8Ty(C);
  Type *sizeT = M.getDataLayout().getIntPtrType(C);
  Constant *null = ConstantPointerNull::get(ptr);
  // The entries (bundle/recipe.json "entries"): their bodies are in the module when the link followed the contract
  // there (driver/cq_entries.py); a bodiless one is a call the checker judges, with one note.
  std::map<std::string, FunctionCallee> entries;
  auto entry = [&](StringRef name, FunctionType *ft) {
    auto it = entries.find(name.str());
    if (it != entries.end())
      return it->second;
    FunctionCallee fc = M.getOrInsertFunction(name, ft);
    if (auto *f = dyn_cast<Function>(fc.getCallee()); f && f->isDeclaration())
      noteUnbuilt(("eff-tape: the result entry " + name + " has no body: the link did not follow bundle/recipe.json "
                   "\"entries\" (driver/cq_entries.py)").str());
    return entries[name.str()] = fc;
  };
  for (CallBase *CB : sites) {
    OutFn o = *outputFunction(*calleeOf(*CB));
    Function &fn = *CB->getFunction();
    IRBuilder<> B(CB);
    Type *rt = CB->getType();
    Value *v = nullptr;
    auto forward = [&](SmallVectorImpl<Value *> &args, unsigned from) {
      for (unsigned a = from; a < CB->arg_size(); ++a)
        args.push_back(CB->getArgOperand(a));
    };
    switch (o.kind) {
    case OutKind::Fmt: case OutKind::VFmt: {
      bool va = o.kind == OutKind::VFmt;
      FunctionCallee e = va ? entry("__cq_count_vsnprintf", FunctionType::get(i32, {ptr, sizeT, ptr, ptr}, false))
                            : entry("__cq_count_snprintf", FunctionType::get(i32, {ptr, sizeT, ptr}, true));
      SmallVector<Value *, 8> args{null, ConstantInt::get(sizeT, 0)};
      forward(args, o.first);
      v = B.CreateCall(e, args);
      break;
    }
    case OutKind::WFmt: case OutKind::VWFmt: {
      bool va = o.kind == OutKind::VWFmt;
      FunctionCallee e = va ? entry("__cq_count_vwprintf", FunctionType::get(i32, {ptr, ptr}, false))
                            : entry("__cq_count_wprintf", FunctionType::get(i32, {ptr}, true));
      SmallVector<Value *, 8> args;
      forward(args, o.first);
      v = B.CreateCall(e, args);
      break;
    }
    case OutKind::Zero: case OutKind::Status:
      v = ConstantInt::get(rt, 0);
      break;
    case OutKind::Range: {
      // A rail argument: icmp and select by the ordinary templates once lowered.
      Value *a = CB->getArgOperand(o.first);
      v = B.CreateSelect(B.CreateICmpUGT(a, ConstantInt::get(a->getType(), o.max)), ConstantInt::get(rt, -1, true),
                         ConstantInt::get(rt, 0));
      break;
    }
    case OutKind::Length:
      v = B.CreateZExtOrTrunc(CB->getArgOperand(o.first), rt);
      break;
    case OutKind::UChar:
      v = B.CreateZExt(B.CreateTrunc(CB->getArgOperand(0), i8), rt);
      break;
    case OutKind::Fwrite: {
      Value *size = CB->getArgOperand(1), *nmemb = CB->getArgOperand(2);
      v = B.CreateSelect(B.CreateICmpEQ(size, ConstantInt::get(size->getType(), 0)), ConstantInt::get(rt, 0),
                         B.CreateZExtOrTrunc(nmemb, rt));
      break;
    }
    case OutKind::Wc: {
      // musl __fputwc_unlocked: an ASCII c is putc_unlocked's (unsigned char)c == c, any other is WEOF where wctomb
      // fails; wctomb of an ASCII c is 1, so the one test covers both. The buffer is MB_LEN_MAX (4) bytes.
      Value *c = CB->getArgOperand(0);
      AllocaInst *buf = entryAlloca(fn, i8, 4, "cq.wctomb.buf");
      FunctionCallee e = entry("__cq_count_wctomb", FunctionType::get(i32, {ptr, i32}, false));
      Value *r = B.CreateCall(e, {buf, B.CreateSExtOrTrunc(c, i32)});
      v = B.CreateSelect(B.CreateICmpSLT(r, ConstantInt::get(i32, 0)), ConstantInt::get(rt, -1, /*signed=*/true),
                         B.CreateZExtOrTrunc(c, rt));
      break;
    }
    case OutKind::Ws: {
      // musl fputws: l = wcsrtombs(buf, &ws, BUFSIZ, 0) until 0 or (size_t)-1; returns l. ws a null pointer is
      // outside the domain (C17 7.29.3.4: a wide string).
      AllocaInst *slot = entryAlloca(fn, ptr, 1, "cq.wcsrtombs.ws");
      B.CreateStore(CB->getArgOperand(0), slot);
      FunctionCallee e = entry("__cq_count_wcsrtombs", FunctionType::get(sizeT, {ptr, ptr, sizeT, ptr}, false));
      Value *r = B.CreateCall(e, {null, slot, ConstantInt::get(sizeT, 0), null});
      v = B.CreateSelect(B.CreateICmpEQ(r, ConstantInt::getAllOnesValue(sizeT)), ConstantInt::get(rt, -1, true),
                         ConstantInt::get(rt, 0));
      break;
    }
    }
    if (auto *I = dyn_cast<Instruction>(v))
      I->setMetadata("cq.deferred.result", MDNode::get(C, {}));
    if (!CB->use_empty() && v->getType() == rt)
      CB->replaceAllUsesWith(v);
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
