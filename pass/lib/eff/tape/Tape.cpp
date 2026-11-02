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
//    entry, then the module's handler as a _ctl clone call, or the abort arm, lowerRaise, 102); an entry inside a _ctl or _adj clone. An entry inside a plain clone is
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
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
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
  if (ctx.T.isFatPointer(p, ctx.S))
    return true;
  for (ObjectId o : ctx.T.provenance(p, ctx.S))
    if (ctx.T.classOf(o) != ObjClass::Classical)
      return true;
  return false;
}

bool qramPointer(LoweringContext &ctx, const Value *p) {
  if (ctx.T.isFatPointer(p, ctx.S))
    return true;
  for (ObjectId o : ctx.T.provenance(p, ctx.S))
    if (ctx.T.classOf(o) == ObjClass::Qram)
      return true;
  return false;
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

// The SPEC_ISSUES entry a tape argument §1.11 cannot record waits on (cq-py5f): a field is a scalar
// (a rail or a literal) or a string copied at call time, nothing else.
[[noreturn]] void awaitingFieldRuling(const std::string &what, const Instruction *at) {
  unimplemented("eff-tape: awaiting owner ruling: SPEC_ISSUES Tape fields BACKEND_ABI 1.11 has no form for (" +
                    what + ")",
                at);
}

// A classical pointer value as an i64 literal field (printf's %p, rule 25: a pointer is a 64-bit word).
void emitPointerValue(LoweringContext &ctx, Value *p, Value *tape) {
  Value *w = ctx.B().CreatePtrToInt(p, Type::getInt64Ty(ctx.M.getContext()));
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, RailType{Kind::Int, 64}}, {tape, w});
}

// One field of an entry, argument a of CB. conv is printf's conversion character for it ('*' a width or
// precision; 0 for an effect entry, whose string arguments must be constant C strings of readonly
// parameters). A conversion that does not match its argument's type is undefined behaviour (C17
// 7.21.6.1p9), outside the domain: the field is the argument as it is, and the backend's printf reads it
// as the host's would.
void emitField(LoweringContext &ctx, CallBase &CB, unsigned a, char conv, Value *tape, Value *flag) {
  Value *v = CB.getArgOperand(a);
  Type *ty = v->getType();
  if (ty->isPointerTy()) {
    if (nonClassicalPointer(ctx, v))
      awaitingFieldRuling("a quantum pointer or a pointer into quantum memory", &CB);
    if (conv == 'n')
      awaitingFieldRuling("printf's %n, a store the deferred entry cannot make at call time", &CB);
    Operand s = ctx.operand(v);
    if (conv == 's' || (!conv && constantCString(v) &&
                        (CB.paramHasAttr(a, Attribute::ReadOnly) || CB.paramHasAttr(a, Attribute::ReadNone)))) {
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteStrLit}, {tape, s.v});
      return;
    }
    if (!conv)
      awaitingFieldRuling("a pointer argument of an effect entry that is not a constant C string", &CB);
    emitPointerValue(ctx, s.v, tape);
    return;
  }
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    awaitingFieldRuling("an argument of a vector or aggregate type", &CB);
  RailType w = railTypeOf(ty);
  Operand op = ctx.operand(v);
  if (!op.handle) {
    ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, w}, {tape, op.v});
    return;
  }
  CallInst *h2;
  if (flag)
    h2 = ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w, /*ctl=*/true}, {flag, tape, op.v});
  else
    h2 = ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w}, {tape, op.v});
  ctx.unc().recordExternal(h2, Role::Tape);   // write-only tape rail: kept, never freed or uncomputed
}

Constant *effectName(Module &M, StringRef name) {
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
SmallVector<std::pair<Value *, const Value *>, 4> laterInPlaceTargets(LoweringContext &ctx, CallBase &CB) {
  Function &F = *CB.getFunction();
  BasicBlock *Ba = CB.getParent();
  DominatorTree DT(F);
  LoopInfo LI(DT);
  for (BasicBlock *p : predecessors(Ba))
    if (LI.getLoopFor(p))
      unimplemented("eff-tape: a noreturn arm inside a loop (later iterations would need the snapshot)", &CB);

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

  SetVector<const Value *> roots;
  auto target = [&](const Value *v, const Instruction &at) {
    // Representation changes keep the rail (rule 3).
    while (true) {
      if (auto *fr = dyn_cast<FreezeInst>(v)) { v = fr->getOperand(0); continue; }
      if (auto *bc = dyn_cast<BitCastInst>(v)) { v = bc->getOperand(0); continue; }
      break;
    }
    if (isa<Constant>(v) || !ctx.T.isQuantum(v, ctx.S))
      return;
    if (isa<Argument>(v) || DT.dominates(cast<Instruction>(v), &CB)) {
      roots.insert(v);
      return;
    }
    auto *I = cast<Instruction>(v);
    if (isa<PHINode>(I) || isa<SelectInst>(I) || isa<LoadInst>(I) || isa<ExtractValueInst>(I) ||
        isa<ExtractElementInst>(I) || isa<CallBase>(I) || isa<IntToPtrInst>(I))
      unimplemented("eff-tape: a rotation after a noreturn arm whose target may alias a rail live at the "
                    "abort (the snapshot cannot be decided)", &at);
    // Any other instruction is a template into a fresh rail (rule 4): nothing to snapshot.
  };

  for (BasicBlock &X : F) {
    if (before.count(&X) || !DT.isReachableFromEntry(&X))
      continue;
    if ((ctx.preds().block(&X) & pa).isBottom())
      continue;   // never runs on the abort branch
    for (Instruction &I : X) {
      if (auto *st = dyn_cast<StoreInst>(&I)) {
        if (qramPointer(ctx, st->getPointerOperand()))
          unimplemented("eff-tape: a QRAM store after a noreturn arm (in place on the object)", &I);
        continue;
      }
      if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) {
        if (qramPointer(ctx, I.getOperand(0)) || nonClassicalPointer(ctx, I.getOperand(0)))
          unimplemented("eff-tape: an atomic on quantum memory after a noreturn arm", &I);
        continue;
      }
      auto *C = dyn_cast<CallBase>(&I);
      if (!C)
        continue;
      using calls::Class;
      Class k = calls::classify(*C, ctx.T, ctx.S);
      switch (k) {
      case Class::Theta:
        target(C->getArgOperand(0), I);
        break;
      case Class::Classical: case Class::Measure: case Class::Phi: case Class::HostEffect:
      case Class::Noreturn: case Class::TemplateIntrinsic: case Class::Alloc: case Class::Fenv:
      case Class::InvertBegin: case Class::InvertEnd:
        break;
      case Class::MemIntrinsic:
        for (const Use &u : C->args())
          if (qramPointer(ctx, u.get()))
            unimplemented("eff-tape: a memory intrinsic on a QRAM object after a noreturn arm", &I);
        break;
      case Class::Dealloc: {
        const Value *p = isa<IntrinsicInst>(C) ? C->getArgOperand(isa<LifetimeIntrinsic>(C) ? 1 : 0)
                                               : C->getArgOperand(0);
        if (qramPointer(ctx, p))
          unimplemented("eff-tape: a QRAM lifetime end after a noreturn arm (its pops write the cells)", &I);
        break;
      }
      case Class::LibmIntrinsic:
        break;   // a math intrinsic takes and returns values (rule 18): it writes no caller rail
      case Class::Lift: {
        SmallPtrSet<const Function *, 8> seen;
        if (bodyMayModifyInPlace(calleeOf(*C), seen))
          unimplemented("eff-tape: a call after a noreturn arm whose callee may modify a caller rail in place",
                        &I);
        break;
      }
      default:
        unimplemented("eff-tape: a call after a noreturn arm whose in-place effect on live rails is unknown",
                      &I);
      }
    }
  }

  SmallVector<std::pair<Value *, const Value *>, 4> out;
  SmallPtrSet<Value *, 8> seenH;
  for (const Value *v : roots) {
    Operand op = ctx.operand(v);
    if (!op.handle)
      continue;   // measured before the abort: a classical outcome, nothing to snapshot
    if (seenH.insert(op.v).second)
      out.push_back({op.v, v});
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
    RailType w = railTypeOf(t.second->getType());
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
enum class SigDefault { Terminate, Ignore, Stop, Unknown };
SigDefault signalDefault(const Module &M, int64_t sig) {
  // A number that names no signal makes raise fail with EINVAL and deliver nothing (POSIX raise).
  Triple t(M.getTargetTriple());
  if (t.isOSLinux() && sig >= 32 && sig <= 64)
    return SigDefault::Terminate;   // the real-time signals (SIGRTMIN..SIGRTMAX)
  if ((t.isOSDarwin() || t.isOSLinux()) && (sig < 1 || sig > 31))
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
  if (t.isOSLinux()) {
    switch (sig) {
    case 17: case 18: case 23: case 28:                     // CHLD, CONT, URG, WINCH
      return SigDefault::Ignore;
    case 19: case 20: case 21: case 22:                     // STOP, TSTP, TTIN, TTOU
      return SigDefault::Stop;
    default:
      return SigDefault::Terminate;
    }
  }
  return SigDefault::Unknown;
}

// CR rule 16 (102): raise(sig) under a quantum predicate, read against the module's signal table (the
// signal(sig, h) calls of the module: closed world, as taint reads it). The delivery is an effect entry
// (cqrt_tape_effect_controlled(flag, tape, "raise"), the signal number its field). Then: a handler h the
// module installs for sig runs as h(sig) under the predicate (taint's _ctl clone of h, calls::lowerLiftedVia);
// SIG_IGN installed (or no handler and a default action of ignore) has nothing more; SIG_DFL installed or no
// handler, with a default action of terminate, is the abort arm (abort_i1(flag), 45).
void lowerRaise(LoweringContext &ctx, CallBase &CB, Value *flag) {
  auto *sigC = dyn_cast<ConstantInt>(CB.getArgOperand(0));
  if (!sigC)
    unimplemented("eff-tape: raise of a signal number that is not a constant", &CB);
  int64_t sig = sigC->getSExtValue();
  // What the module installs for sig: handler functions, SIG_IGN (1), SIG_DFL (0).
  SmallPtrSet<const Function *, 2> handlers;
  bool ign = false, dfl = false;
  for (const Function &G : ctx.M)
    for (const User *u : G.users()) {
      auto *C = dyn_cast<CallBase>(u);
      if (!C || C->getCalledOperand() != &G || !G.isDeclaration())
        continue;
      StringRef n = G.getName();
      if (n == "sigaction" || n == "bsd_signal" || n == "sigset")
        unimplemented("eff-tape: raise in a module that installs handlers through " + n.str() + " (102)", &CB);
      if (n != "signal" || C->arg_size() != 2)
        continue;
      auto *s = dyn_cast<ConstantInt>(C->getArgOperand(0));
      if (!s)
        unimplemented("eff-tape: raise in a module with a signal() call of a run-time signal number", &CB);
      if (s->getSExtValue() != sig)
        continue;
      const Value *h = C->getArgOperand(1)->stripPointerCasts();
      if (auto *H = dyn_cast<Function>(h); H && !H->isDeclaration()) {
        handlers.insert(H);
        continue;
      }
      if (isa<ConstantPointerNull>(h)) {
        dfl = true;
        continue;
      }
      if (auto *ce = dyn_cast<ConstantExpr>(h); ce && ce->getOpcode() == Instruction::IntToPtr)
        if (auto *ci = dyn_cast<ConstantInt>(ce->getOperand(0))) {
          if (ci->isZero())
            dfl = true;
          else if (ci->isOne())
            ign = true;
          else
            unimplemented("eff-tape: raise of a signal installed with a constant handler other than SIG_DFL or "
                          "SIG_IGN",
                          &CB);
          continue;
        }
      unimplemented("eff-tape: raise of a signal whose installed handler is a run-time value or a function the "
                    "module does not define",
                    &CB);
    }
  if (handlers.size() + ign + dfl > 1)
    unimplemented("eff-tape: raise of a signal the module installs several handlers for", &CB);
  SigDefault dflt = signalDefault(ctx.M, sig);
  bool byDefault = handlers.empty() && !ign;
  if (byDefault && dflt == SigDefault::Stop)
    unimplemented("eff-tape: awaiting owner ruling: SPEC_ISSUES raise of a signal whose default action stops the "
                  "process",
                  &CB);
  if (byDefault && dflt == SigDefault::Unknown)
    unimplemented("eff-tape: raise of a signal number the target defines no default action for", &CB);
  bool terminate = byDefault && dflt == SigDefault::Terminate;
  if (terminate)
    requireEntry(ctx, CB, "a terminating raise");
  const Specialization *cs = handlers.empty() ? nullptr : ctx.T.calleeSpecialization(CB, ctx.S);
  if (!handlers.empty() && (!cs || cs->F != *handlers.begin() || !cs->ctl))
    internalError("eff-tape: raise of a handled signal under a quantum predicate whose callee taint does not "
                  "name as the handler's _ctl clone",
                  &CB);

  Value *tape = tapeOf(ctx);
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffect, {}, /*ctl=*/true}, {flag, tape, effectName(ctx.M, "raise")});
  emitField(ctx, CB, 0, 0, tape, flag);
  if (cs) {
    unsigned argMap[1] = {0};
    calls::lowerLiftedVia(ctx, CB, argMap);
    return;
  }
  if (terminate)
    abortArm(ctx, CB, flag);
}

} // namespace

void lowerHostEffect(LoweringContext &ctx, CallBase &CB) {
  if (!CB.getType()->isVoidTy() && !CB.use_empty())
    unimplemented("eff-tape: awaiting owner ruling: SPEC_ISSUES A deferred host call whose result is used", &CB);
  // A clone appends its entries to its own tape each time it runs (67: "one tape per function"). Its
  // _unc twin recomputes through the _pure clone (CR §1.4, 119), which is the clone without its effects:
  // tape entries are write-once and never replayed, so the _pure clone emits none. In a _ctl clone every
  // block's predicate holds the clone's control (the _ctl entry flag), so the entry's flag is the caller's
  // predicate and the clone's own; an _adj clone's body is eff-invert's region (rule 17), which reads the
  // entry as one of its gates. A host effect of a callee rule 19 inlines is an entry of the caller's tape
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
  auto byteField = [&](Value *tape, const Operand &c) {
    RailType w{Kind::Int, 8};
    if (!c.handle) {
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, w}, {tape, c.v});
      return;
    }
    CallInst *h2 = flag ? ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w, /*ctl=*/true}, {flag, tape, c.v})
                        : ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w}, {tape, c.v});
    ctx.unc().recordExternal(h2, Role::Tape);
  };

  // fwrite(buf, size, n, stdout) (99): one entry of size * n raw %c bytes, one i8 field per byte (C17
  // 7.21.8.2: fputc of each byte). A slot buffer's cells (mem::readSlotCells, M4) are rails or literals;
  // a classical buffer's bytes are read at the call (literal fields: copied at call time, as a string).
  if (libFunc(*F, LibFunc_fwrite) && isStdout(CB.getArgOperand(3))) {
    auto *sz = dyn_cast<ConstantInt>(CB.getArgOperand(1));
    auto *cnt = dyn_cast<ConstantInt>(CB.getArgOperand(2));
    if (!sz || !cnt)
      awaitingFieldRuling("an fwrite of a run-time number of bytes (raw bytes, not a string)", &CB);
    Value *buf = CB.getArgOperand(0);
    if (ctx.T.isFatPointer(buf, ctx.S) || ctx.T.isQuantum(buf, ctx.S))
      awaitingFieldRuling("a quantum pointer or a pointer into quantum memory", &CB);
    bool slot = false, classical = false, other = false;
    for (ObjectId o : ctx.T.provenance(buf, ctx.S)) {
      ObjClass k = ctx.T.classOf(o);
      (k == ObjClass::Slot ? slot : k == ObjClass::Classical ? classical : other) = true;
    }
    uint64_t n = sz->getZExtValue() * cnt->getZExtValue();
    SmallVector<Operand, 8> cells;
    if (slot && !classical && !other) {
      cells = mem::readSlotCells(ctx, buf, Type::getInt8Ty(C), n, CB);
    } else if (!slot && !other) {
      Value *p = ctx.operand(buf).v;
      for (uint64_t i = 0; i < n; ++i) {
        Value *q = ctx.B().CreateConstInBoundsGEP1_64(Type::getInt8Ty(C), p, i);
        cells.push_back(Operand{ctx.B().CreateLoad(Type::getInt8Ty(C), q), false});
      }
    } else {
      awaitingFieldRuling("a quantum pointer or a pointer into quantum memory", &CB);
    }
    Value *tape = tapeOf(ctx);
    openFmt(tape, fwriteFormat(ctx.M, n));
    for (const Operand &c : cells)
      byteField(tape, c);
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
      awaitingFieldRuling("a quantum pointer or a pointer into quantum memory", &CB);
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
    for (unsigned a = 1; a < CB.arg_size(); ++a) {
      if (CB.getArgOperand(a)->getType()->isPointerTy())
        awaitingFieldRuling("a pointer argument of printf with a run-time format (string or address)", &CB);
      emitField(ctx, CB, a, 'd', tape, flag);
    }
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
  if (signalFamily(F->getName()))
    unimplemented("eff-tape: awaiting owner ruling: SPEC_ISSUES A signal-table host call on the tape", &CB);
  for (unsigned a = 0; a < CB.arg_size(); ++a)
    if (isa<Function>(CB.getArgOperand(a)->stripPointerCasts()))
      awaitingFieldRuling("a function pointer argument (a callback the deferred call would run at the end of the "
                          "shot)",
                          &CB);
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
  for (unsigned a = 0; a < CB.arg_size(); ++a)
    emitField(ctx, CB, a, 0, tape, flag);
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
