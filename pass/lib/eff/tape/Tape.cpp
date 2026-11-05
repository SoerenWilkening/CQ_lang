// Module eff-tape (cq-w1-eff-tape): CR rule 16, host effects and noreturn arms; BACKEND_ABI §1.11.
//
// lowerHostEffect: a side-effecting host call the compiler does not lift becomes one tape entry with
// its predicate (the current block's flag, none when the quantum part is top). The host call itself
// is never executed by the lowered program; the backend performs the entries at the end of the shot.
//  - The tape: one cqrt_tape_alloc() per output function, at the start of its entry block, made by the
//    first entry the function records (47: "the function's output tape").
//  - printf (recognized by TargetLibraryInfo, name and signature, never by name alone): a format entry
//    cqrt_tape_fmt[_controlled]([c,] t, fmt), then one field per variadic argument in order (47, 138):
//    a quantum scalar is cqrt_tape_write_<W>[_controlled]([c,] t, h) -> h', a fresh write-only tape rail
//    (kept, never freed or uncomputed: Role::Tape); a classical scalar is cqrt_tape_write_<W>_lit(t,
//    lit); a classical pointer converted by %s is cqrt_tape_write_str_lit(t, s) (the backend copies the
//    string at call time). The fields of a controlled entry are controlled by the same flag; literal
//    fields have no controlled form (the entry's predicate covers them).
//  - fwrite(buf, size, n, stdout) with constant size and n, buf one slot object of byte cells (99): one
//    entry with the format "%c" repeated size * n times, then one i8 field per cell (mem::readSlotCells,
//    M4): a handle cell is cqrt_tape_write_i8[_controlled] -> a fresh tape rail, a classical cell a
//    literal. fputs(s, stdout) of a constant string without '%': an entry with format s, no fields.
//    stdout is the function's tape; another stream is unimplemented.
//  - A classical host effect that a tape point precedes (owner ruling 2026-11-02, cq-t8oo / cq-64lv; the
//    tape-order rule of calls::classify) arrives here with no predicate: printf, fputs and fwrite as above,
//    puts(s) as the format entry "%s\n" with s a string field, putchar(c) as "%c" with c a field; any
//    other is unimplemented below (an effect entry has only the controlled form).
//  - Any other host effect under a quantum predicate is an effect entry (102):
//    cqrt_tape_effect_controlled(c, t, name), name the callee as a string constant @.cq.effect.<name>,
//    then the same fields for its arguments. Only the controlled form exists (an unconditional effect is
//    the real host call), so an effect entry with a quantum predicate of top is unimplemented.
//  - Unimplemented (an internal error, nothing emitted): a used result (the call never runs, so its
//    value is unknown); a quantum or non-classical pointer argument; a classical pointer that is not a
//    %s conversion of printf or a constant C string of a readonly parameter of an effect; a function
//    pointer argument (a callback); kill/signal-family callees other than raise (raise(sig): the delivery
//    entry, then the module's handler as a _ctl clone call, or the abort arm, lowerRaise, 102); an entry inside a _ctl clone. An entry inside a plain clone is
//    the clone's own tape entry (67); inside a _pure clone (what a twin recomputes through) it is dropped.
//
// lowerNoreturn: a noreturn call under a quantum predicate (45, 102, 108) is cqrt_abort_i1(f), f the
// current block's flag, kept (Role::Abort: never _unc'd, never freed) and measured by the backend at the
// end of the shot. The program continues uncontrolled. Before the call, every rail that a later
// operation may modify IN PLACE on the abort branch is snapshotted under the flag:
// s = cqrt_alloc_<W>(0); cqrt_copy_<W>_controlled(f, h, s), s kept (45 abort_then_rotate). In place is
// what CR rule 4 reserves: a rotation of an existing rail (rule 2, rule 10's controlled Ry, rule 15's
// quantum-angle Ry). "Later on the abort branch" is read on the original CFG: an instruction in a block X
// that cannot reach the abort block and whose path predicate is compatible with the abort block's
// (block(X) & block(abort) is not false). A rotation target is snapshotted when it is a value available
// at the abort (an argument or an instruction dominating it); a target defined later is a fresh rail
// unless it may alias an earlier one (phi, select, load, extractvalue, ...), which is unimplemented, as
// is any later operation that may modify a rail in place without being a visible rotation: a QRAM store
// or memory intrinsic into a QRAM object, a QRAM lifetime end, a call with a quantum or non-classical
// pointer argument whose callee is opaque or may rotate (transitively) or store. Also unimplemented: a
// noreturn inside an inlined callee or a clone (the later code is the caller's), an abort block whose
// predecessors lie in a loop (later iterations), a quantum argument of the noreturn call. Classical
// arguments of the noreturn call (exit's status, __assert_fail's strings) are dropped: rule 16 lowers
// the call to abort_i1(pred) alone.
//
// Orchestrator decisions under CR rule 16 / §1.3 (owner may override) are recorded on the bead.
#include "cq/Effects.h"


#include "cq/Abi.h"
#include "cq/Aggregates.h"
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

bool nonClassicalPointer(LoweringContext &ctx, const Value *p) {
  if (!p->getType()->isPointerTy())
    return false;
  if (!isa<Constant>(p) && ctx.T.isQuantum(p, ctx.S))
    return true;
  return !isa<ConstantPointerNull>(p) && !ctx.T.hostObjectOf(p, ctx.S);
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

// A constant C string with its NUL inside the object.
bool constantCString(const Value *p) {
  StringRef s;
  if (!getConstantStringInfo(p, s, /*TrimAtNul=*/false))
    return false;
  return s.contains('\0');
}

// A classical pointer value as an i64 literal field (rule 16 fields: a FILE * or any other classical host
// pointer is its ptrtoint, rule 25: a pointer is a 64-bit word).
void emitPointerValue(LoweringContext &ctx, Value *p, Value *tape) {
  Value *w = ctx.B().CreatePtrToInt(p, Type::getInt64Ty(ctx.M.getContext()));
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, RailType{Kind::Int, 64}}, {tape, w});
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





// One field of an entry, argument a of CB. conv is printf's conversion character for it ('*' a width or
// precision; 0 for an effect entry). A conversion that does not match its argument's type is undefined
// behaviour (C17 7.21.6.1p9), outside the domain: the field is the argument as it is, and the backend's
// printf reads it as the host's would.
void emitField(LoweringContext &ctx, CallBase &CB, unsigned a, char conv, Value *tape, Value *flag) {
  Value *v = CB.getArgOperand(a);
  Type *ty = v->getType();
  if (ty->isPointerTy())
    report_fatal_error("cq: unimplemented: bus: a pointer field of an effect entry (rule 16)", /*gen_crash_diag=*/false);
  if (ty->isIntegerTy() || ty->isFloatingPointTy()) {
    scalarField(ctx, tape, flag, ctx.operand(v), ty);
    return;
  }
  // A vector is its lanes (rule 25), an aggregate its scalar fields (rule 26).
  SmallVector<Type *, 4> tys;
  leafTypes(ty, tys);
  SmallVector<Operand, 4> ops = aggr::flattenResult(ctx, v);
  if (ops.size() != tys.size())
    internalError("eff-tape: a composite field whose leaves do not match its type", &CB);
  for (unsigned k = 0; k < ops.size(); ++k) {
    if (tys[k]->isPointerTy()) {
      if (ops[k].handle)
        internalError("eff-tape: a pointer leaf of a composite field bound to a rail", &CB);
      emitPointerValue(ctx, ops[k].v, tape);
      continue;
    }
    scalarField(ctx, tape, flag, ops[k], tys[k]);
  }
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

// The C stream stdout (the function's tape, 99): a load of the C library's stdout object. Orchestrator
// decision under CR rule 16 (owner may override): the stream object is recognised by its C library
// symbol (Darwin's __stdoutp, the ISO name stdout), as TargetLibraryInfo recognises the callee; any
// other stream is unimplemented.
bool isStdout(const Value *v) {
  auto *ld = dyn_cast<LoadInst>(v);
  auto *gv = ld ? dyn_cast<GlobalVariable>(ld->getPointerOperand()) : nullptr;
  return gv && gv->isDeclaration() && (gv->getName() == "__stdoutp" || gv->getName() == "stdout");
}

// A private constant C string g holding f (a format the pass makes).
Constant *formatGlobal(Module &M, StringRef g, StringRef f) {
  if (GlobalVariable *gv = M.getNamedGlobal(g))
    return gv;
  Constant *init = ConstantDataArray::getString(M.getContext(), f, /*AddNull=*/true);
  auto *gv = new GlobalVariable(M, init->getType(), /*isConstant=*/true, GlobalValue::PrivateLinkage, init, g);
  gv->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  gv->setAlignment(Align(1));
  return gv;
}

Constant *formatConstant(Module &M, StringRef f) {
  return formatGlobal(M, f == "%c" ? ".cqfmt.putchar" : ".cqfmt.puts", f);
}

Constant *fwriteFormat(Module &M, uint64_t n) {
  std::string g = ".cqfmt.fwrite" + std::to_string(n);
  if (GlobalVariable *gv = M.getNamedGlobal(g))
    return gv;
  std::string f;
  for (uint64_t i = 0; i < n; ++i)
    f += "%c";
  Constant *init = ConstantDataArray::getString(M.getContext(), f, /*AddNull=*/true);
  auto *gv = new GlobalVariable(M, init->getType(), /*isConstant=*/true, GlobalValue::PrivateLinkage, init, g);
  gv->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  gv->setAlignment(Align(1));
  return gv;
}

bool signalFamily(StringRef n) {
  return n == "raise" || n == "kill" || n == "signal" || n == "sigaction" || n == "pthread_kill" ||
         n == "killpg" || n == "sigqueue";
}

// ------------------------------------------------------------------ noreturn look-ahead

// May a call to F (with a quantum or non-classical pointer argument) modify a caller's rail in place?
bool bodyMayModifyInPlace(const Function *F, SmallPtrSetImpl<const Function *> &seen) {
  if (!F || F->isDeclaration())
    return true;   // opaque (rule 27)
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
      if (G->isDeclaration()) {
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
      // CR rule 4: in place is a rotation of an existing rail (rules 2, 10, 15) and nothing else. A QRAM
      // store, pop or memory intrinsic swaps and copies cells (§1.3), an atomic is a plain access (rule 24).
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
        // A callee may rotate what it is handed (rule 18): its quantum scalar arguments, and the cells of
        // slot objects behind its pointer arguments.
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

void requireEntry(LoweringContext &ctx, CallBase &CB, const char *what) {
  if (CB.getFunction() != ctx.S.F)
    internalError(std::string("eff-tape: ") + what + " inside an inlined callee (rule 19 inlines one-block "
                  "callees under a top predicate only, where no call is under a quantum predicate)", &CB);
  if (!ctx.S.isEntry())
    unimplemented(std::string("eff-tape: ") + what + " inside a clone (its _unc twin would replay it)", &CB);
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

// The default action of a signal on the target (x86-64: Darwin's <sys/signal.h>, Linux's <asm/signal.h>).
enum class SigDefault { Terminate, Ignore, Stop };
SigDefault signalDefault(const Module &M, int64_t sig) {
  // A number that names no signal makes raise fail with EINVAL and deliver nothing (POSIX raise).
  Triple t(M.getTargetTriple());
  if (!t.isOSDarwin() && sig >= 32 && sig <= 64)
    return SigDefault::Terminate;   // the real-time signals (SIGRTMIN..SIGRTMAX)
  if (sig < 1 || sig > 31)
    return SigDefault::Ignore;
  if (t.isOSDarwin()) {
    switch (sig) {
    case 16: case 19: case 20: case 23: case 28: case 29:   // URG, CONT, CHLD, IO, WINCH, INFO
      return SigDefault::Ignore;
    case 17: case 18: case 21: case 22:                     // STOP, TSTP, TTIN, TTOU
      return SigDefault::Stop;
    default:
      return SigDefault::Terminate;
    }
  }
  {   // Linux, and any other x86-64 OS: the generic (asm-generic) numbering
    switch (sig) {
    case 17: case 18: case 23: case 28:                     // CHLD, CONT, URG, WINCH
      return SigDefault::Ignore;
    case 19: case 20: case 21: case 22:                     // STOP, TSTP, TTIN, TTOU
      return SigDefault::Stop;
    default:
      return SigDefault::Terminate;
    }
  }
}

// CR rule 16 (102): raise(sig) under a quantum predicate, read against the module's signal table (the
// signal(sig, h) calls of the module: closed world, as taint reads it). The delivery is an effect entry
// (cqrt_tape_effect_controlled(flag, tape, "raise"), the signal number its field). Then: a handler h the
// module installs for sig runs as h(sig) under the predicate (taint's _ctl clone of h, calls::lowerLiftedVia);
// SIG_IGN installed (or no handler and a default action of ignore) has nothing more; SIG_DFL installed or no
// handler, with a default action of terminate, is the abort arm (abort_i1(flag), 45).
// Installations on the tape (rule 16 signal table): a signal/bsd_signal/sigset/sigaction call under a quantum
// predicate (or after a tape point) is never performed on the host, so a later raise reads the handler as a
// merged value: the installed one where the installation's predicate held, the earlier one elsewhere.
struct TapedInstall {
  const CallBase *call;   // the original call
  std::optional<Pred> q;  // its quantum predicate (none: after a tape point, it always installs)
  Value *sig;             // its signal number (new IR, classical)
  Value *handler;         // the handler it installs (new IR, classical pointer)
  Value *applies;         // classical i1: the call installs at all (sigaction with a non-null act), or nullptr
};
std::map<const Function *, std::pair<WeakVH, std::vector<TapedInstall>>> &tapedInstalls() {
  static std::map<const Function *, std::pair<WeakVH, std::vector<TapedInstall>>> m;
  return m;
}

bool isInstall(StringRef n) { return n == "signal" || n == "sigaction" || n == "bsd_signal" || n == "sigset"; }





// CR rule 16 (102): raise(sig) under a quantum predicate. The delivery is an effect entry
// (cqrt_tape_effect_controlled(flag, tape, "raise"), the signal number its field). Then the handler runs:
//  - The classical-table case (102): a constant sig whose only installation in the module is one signal()
//    call of a defined handler, SIG_IGN or SIG_DFL: the handler's _ctl clone under the predicate, nothing, or
//    (a terminating default) the abort arm.
//  - Otherwise (several installations, a run-time signal number, sigaction, a handler the module does not
//    define) the handler is read from the host's table at run time and dispatched as rule 19 dispatches a
//    function pointer over taint's candidates (TaintInfo::calleeCandidates): each candidate's _ctl clone in
//    its own classical arm; SIG_DFL with a terminating default is the abort arm; SIG_IGN, a stop default and a
//    host handler the module does not define have the delivery entry alone (the host handler runs when the
//    backend performs it). A quantum signal number (taint: every handler is a candidate) enumerates the
//    signal numbers: each one's handler is read at run time and dispatched under flag & (sig == s), the
//    abort arm under flag & OR of the (sig == s) whose default terminates and whose table holds SIG_DFL.
// Handlers installed under a quantum predicate are tape entries (signalTableEntry): the host table holds
// the classical installations.
void lowerRaise(LoweringContext &, CallBase &, Value *, bool = false) {
  report_fatal_error("cq: unimplemented: bus: raise through the signal table (rule 16)", /*gen_crash_diag=*/false);
}




// A buffer argument (CR rule 16 fields: fwrite's, write's): its cells, one i8 field per byte up to the
// length's upper bound, each _controlled under len > j when the length is quantum; a run-time classical
// length is a classical loop of field writes. elemSize * count bytes (count the original call's operand;
// elemSize a constant, or 0 when the byte count is count itself).
void bufferFields(LoweringContext &, CallBase &, const Value *, const Value *, const Value *, Value *, Value *) {
  report_fatal_error("cq: unimplemented: bus: a buffer field of an effect entry (rule 16)", /*gen_crash_diag=*/false);
}


// A signal-table call (signal, sigaction, bsd_signal, sigset, kill, killpg, pthread_kill, sigqueue) that
// goes on the tape: an effect entry with its arguments as fields (rule 16). kill and its kin send a signal
// to a process or thread the call names at replay. A table installation under a quantum predicate makes the
// handler a merged value that a later raise of that signal dispatches over (rule 16 signal table); when the
// module raises no signal the installation may concern, nothing reads the table in the program and the
// entry is the whole construction.
void signalTableEntry(LoweringContext &ctx, CallBase &CB, const Function &F) {
  StringRef n = F.getName();
  bool installs = isInstall(n);
  Value *flag = ctx.currentFlag();
  if (n == "raise" && !flag && CB.arg_size() == 1) {
    // A classical raise on the tape (tape order): its delivery entry under the |1> seed, the handler the host
    // table holds dispatched in program order (lowerRaise's run-time table).
    CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}},
                                 {ConstantInt::getTrue(ctx.M.getContext())});
    ctx.unc().recordSeed(one);
    lowerRaise(ctx, CB, one, /*classicalRaise=*/true);
    return;
  }
  Value *ctl = flag;
  if (!ctl) {
    CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}},
                                 {ConstantInt::getTrue(ctx.M.getContext())});
    ctx.unc().recordSeed(one);
    ctl = one;
  }
  Value *tape = tapeOf(ctx);
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffect, {}, /*ctl=*/true}, {ctl, tape, effectName(ctx.M, n)});
  for (unsigned a = 0; a < CB.arg_size(); ++a)
    emitField(ctx, CB, a, 0, tape, flag);
  if (installs && CB.arg_size() >= 2)
    report_fatal_error("cq: unimplemented: bus: a handler installation in the signal table (rule 16)",
                       /*gen_crash_diag=*/false);
}

} // namespace

void lowerHostEffect(LoweringContext &ctx, CallBase &CB) {
  if (!CB.getType()->isVoidTy() && !CB.use_empty())
    unimplemented("eff-tape: awaiting owner ruling: SPEC_ISSUES A deferred host call whose result is used", &CB);
  // A clone appends its entries to its own tape each time it runs (67: "one tape per function"). Its
  // _unc twin recomputes through the _pure clone (CR §1.4, 119), which is the clone without its effects:
  // tape entries are write-once and never replayed, so the _pure clone emits none. In a _ctl clone every
  // block's predicate holds the clone's control (the _ctl entry flag), so the entry's flag is the caller's
  // predicate and the clone's own; inside a cq_invert region the entry is lowered as anywhere else and the
  // backend treats its writes as gates (rule 17, BACKEND_ABI 1.13). A host effect of a callee rule 19 inlines is an entry of the caller's tape
  // under the caller's predicate in scope.
  if (ctx.S.pure)
    return;
  const Function *F = calleeOf(CB);
  if (!F)
    internalError("eff-tape: a host effect with no direct callee", &CB);
  Value *flag = ctx.currentFlag();
  LLVMContext &C = ctx.M.getContext();
  auto openFmt = [&](Value *tape, Value *fmt) {
    if (flag)
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt, {}, /*ctl=*/true}, {flag, tape, fmt});
    else
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt}, {tape, fmt});
  };

  // fwrite(buf, size, n, stdout) with a constant size * n (99): one entry of size * n raw %c bytes, one i8
  // field per byte (C17 7.21.8.2: fputc of each byte). A slot buffer's cells (mem::readSlotCells, M4) are
  // rails or literals; a classical buffer's bytes are read at the call (literal fields: copied at call time).
  // Any other fwrite (another stream, a run-time or quantum length) is an effect entry below, its buffer
  // its cells (rule 16 fields).
  if (libFunc(*F, LibFunc_fwrite) && isStdout(CB.getArgOperand(3)) && isa<ConstantInt>(CB.getArgOperand(1)) &&
      isa<ConstantInt>(CB.getArgOperand(2))) {
    uint64_t n = cast<ConstantInt>(CB.getArgOperand(1))->getZExtValue() *
                 cast<ConstantInt>(CB.getArgOperand(2))->getZExtValue();
    Value *tape = tapeOf(ctx);
    openFmt(tape, fwriteFormat(ctx.M, n));
    bufferFields(ctx, CB, CB.getArgOperand(0), CB.getArgOperand(1), CB.getArgOperand(2), tape, flag);
    return;
  }
  // fputs(s, stdout): printf("%s", s) (C17 7.21.7.4); a constant s without '%' is its own format with no
  // fields (99).
  if (libFunc(*F, LibFunc_fputs) && isStdout(CB.getArgOperand(1))) {
    Value *str = CB.getArgOperand(0);
    StringRef text;
    Value *tape = tapeOf(ctx);
    if (!nonClassicalPointer(ctx, str) && constantCString(str) && getConstantStringInfo(str, text) &&
        !text.contains('%')) {
      openFmt(tape, ctx.operand(str).v);
      return;
    }
    openFmt(tape, formatGlobal(ctx.M, ".cqfmt.fputs", "%s"));
    emitField(ctx, CB, 0, 's', tape, flag);
    return;
  }

  if (libFunc(*F, LibFunc_printf)) {
    Value *fmt = CB.getArgOperand(0);
    if (nonClassicalPointer(ctx, fmt))
      unimplemented("eff-tape: a printf format string whose bytes or address are quantum", &CB);
    SmallVector<Consume, 8> plan;
    std::string plain;
    bool positional = false;
    bool known = printfPlan(fmt, plan, plain, positional);
    Value *tape = tapeOf(ctx);
    Value *f = positional ? formatGlobal(ctx.M, ".cqfmt.p." + plain, plain) : ctx.operand(fmt).v;
    openFmt(tape, f);
    if (known) {
      // The fields in the order printf reads them; an argument the format never reads is not printed,
      // one it reads but the call lacks is undefined behaviour (C17 7.21.6.1p2), outside the domain.
      for (const Consume &k : plan)
        if (k.arg + 1 < CB.arg_size())
          emitField(ctx, CB, k.arg + 1, k.conv, tape, flag);
      return;
    }
    // A run-time classical format (rule 16 fields): the format a _lit like any pointer, the variadic
    // arguments fields by their promoted IR type (a pointer its address; a format read at replay that does
    // not match them is the program's own undefined behaviour, C17 7.21.6.1p9).
    for (unsigned a = 1; a < CB.arg_size(); ++a)
      emitField(ctx, CB, a, CB.getArgOperand(a)->getType()->isPointerTy() ? 'p' : 'd', tape, flag);
    return;
  }

  // puts(s) and putchar(c) with no quantum predicate (a classical call after a tape point, the tape-order
  // rule of calls::classify): the format entries "%s\n" and "%c" with s / c as their field (C17 7.21.7.9,
  // 7.21.7.8: the same characters on stdout). Under a quantum predicate they stay effect entries (102).
  if (!flag && (libFunc(*F, LibFunc_puts) || libFunc(*F, LibFunc_putchar))) {
    bool puts = libFunc(*F, LibFunc_puts);
    Value *tape = tapeOf(ctx);
    ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt}, {tape, formatConstant(ctx.M, puts ? "%s\n" : "%c")});
    emitField(ctx, CB, 0, puts ? 's' : 'c', tape, nullptr);
    return;
  }

  if (flag && F->getName() == "raise" && CB.arg_size() == 1) {
    lowerRaise(ctx, CB, flag);
    return;
  }
  if (signalFamily(F->getName()) || F->getName() == "bsd_signal" || F->getName() == "sigset") {
    signalTableEntry(ctx, CB, *F);
    return;
  }
  // A function pointer argument (a callback of the bodiless host call) is a classical host pointer: its
  // address, an i64 literal; the host calls it back at replay through clone_resolve (rule 16 callback,
  // rule 27).
  // Any other host effect is an effect entry (102): the host call `name` recorded with its arguments. An
  // effect with no quantum predicate in scope (a classical host effect after a tape point, the tape-order
  // rule, or one with a quantum argument) is recorded under a constant-true predicate, a seed rail |1>
  // (§1.11 has only the controlled form; the entry's predicate is read at call time, the seed then freed).
  Value *ctl = flag;
  if (!ctl) {
    RailType i1{Kind::Int, 1};
    CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getTrue(C)});
    ctx.unc().recordSeed(one);
    ctl = one;
  }
  Value *tape = tapeOf(ctx);
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffect, {}, /*ctl=*/true}, {ctl, tape, effectName(ctx.M, F->getName())});
  // The fields: the call's arguments in order; fwrite's and write's buffer is its cells (rule 16 fields).
  int bufArg = -1;
  const Value *sizeV = nullptr, *countV = nullptr;
  if (libFunc(*F, LibFunc_fwrite)) {
    bufArg = 0;
    sizeV = CB.getArgOperand(1);
    countV = CB.getArgOperand(2);
  } else if (libFunc(*F, LibFunc_write)) {
    bufArg = 1;
    countV = CB.getArgOperand(2);
  }
  for (unsigned a = 0; a < CB.arg_size(); ++a) {
    if (int(a) == bufArg)
      bufferFields(ctx, CB, CB.getArgOperand(a), sizeV, countV, tape, flag);
    else
      emitField(ctx, CB, a, 0, tape, flag);
  }
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

// CR rule 24 at f684858 (cq-py5f): an observable volatile store with quantum data is a host effect, the
// rule-16 effect entry `volatile_store` under the predicate (a seed |1> when it is top, as any effect
// entry): the address as an i64 field (a literal when classical; a quantum address, rule 21, a written rail
// under the predicate), then the stored value, one field per scalar leaf (a vector's lanes, rule 25; a
// pointer value its address as an i64 literal). As every entry, none in a _pure clone.
void lowerVolatileStore(LoweringContext &ctx, StoreInst &SI, Operand address) {
  if (ctx.S.pure)
    return;
  LLVMContext &C = ctx.M.getContext();
  Value *flag = ctx.currentFlag();
  Value *ctl = flag;
  if (!ctl) {
    RailType i1{Kind::Int, 1};
    CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getTrue(C)});
    ctx.unc().recordSeed(one);
    ctl = one;
  }
  Value *tape = tapeOf(ctx);
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffect, {}, /*ctl=*/true}, {ctl, tape, effectName(ctx.M, "volatile_store")});
  auto write = [&](Operand op, RailType w) {
    if (!op.handle) {
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, w}, {tape, op.v});
      return;
    }
    CallInst *h2 = flag ? ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w, /*ctl=*/true}, {flag, tape, op.v})
                        : ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w}, {tape, op.v});
    ctx.unc().recordExternal(h2, Role::Tape);
  };
  RailType i64{Kind::Int, 64};
  write(address, i64);
  Value *v = SI.getValueOperand();
  Type *ty = v->getType();
  if (ty->isPointerTy()) {
    Operand p = ctx.operand(v);
    if (p.handle)
      internalError("eff-tape: a pointer value with a handle of its own (rule 21 binds a quantum pointer's fields)", &SI);
    write(Operand{ctx.B().CreatePtrToInt(p.v, Type::getInt64Ty(C)), false}, i64);
    return;
  }
  if (ty->isIntegerTy() || ty->isFloatingPointTy()) {
    write(ctx.operand(v), railTypeOf(ty));
    return;
  }
  // A vector or aggregate: its scalar leaves in order (rule 25 lanes, rule 26 fields).
  SmallVector<Type *, 8> leaves;
  std::function<void(Type *)> flat = [&](Type *t) {
    if (auto *st = dyn_cast<StructType>(t))
      for (Type *e : st->elements())
        flat(e);
    else if (auto *at = dyn_cast<ArrayType>(t))
      for (uint64_t i = 0; i < at->getNumElements(); ++i)
        flat(at->getElementType());
    else if (auto *vt = dyn_cast<FixedVectorType>(t))
      for (unsigned i = 0; i < vt->getNumElements(); ++i)
        flat(vt->getElementType());
    else
      leaves.push_back(t);
  };
  flat(ty);
  SmallVector<Operand, 4> fs = ctx.fields(v);
  if (fs.size() != leaves.size())
    internalError("eff-tape: a stored composite whose fields are not its scalar leaves", &SI);
  for (unsigned i = 0; i < fs.size(); ++i) {
    if (leaves[i]->isPointerTy()) {
      if (fs[i].handle)
        internalError("eff-tape: a pointer leaf with a handle of its own", &SI);
      write(Operand{ctx.B().CreatePtrToInt(fs[i].v, Type::getInt64Ty(C)), false}, i64);
    } else {
      write(fs[i], railTypeOf(leaves[i]));
    }
  }
}

void lowerNoreturn(LoweringContext &ctx, CallBase &CB) {
  requireEntry(ctx, CB, "a noreturn arm");
  // Rule 16 lowers the call to abort_i1(pred) alone: its arguments (exit's status, __assert_fail's
  // strings), classical or quantum, are dropped, as the program they would end continues uncontrolled.
  Value *flag = ctx.currentFlag();
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
