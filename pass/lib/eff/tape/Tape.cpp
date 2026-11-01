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
  static thread_local std::unique_ptr<TargetLibraryInfoImpl> impl;
  static thread_local std::string triple;
  const Module *M = F.getParent();
  if (!impl || triple != M->getTargetTriple()) {
    triple = M->getTargetTriple();
    impl = std::make_unique<TargetLibraryInfoImpl>(Triple(triple));
  }
  TargetLibraryInfo TLI(*impl, &F);
  LibFunc lf;
  return TLI.getLibFunc(F, lf) && lf == want;
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

// printf's conversion characters, one per consumed argument ('*' width/precision consume an int).
// Returns false when the format is not a constant string.
bool printfConversions(const Value *fmt, SmallVectorImpl<char> &conv) {
  StringRef s;
  if (!getConstantStringInfo(fmt, s))
    return false;
  for (size_t i = 0; i < s.size(); ++i) {
    if (s[i] != '%')
      continue;
    ++i;
    if (i < s.size() && s[i] == '%')
      continue;
    // A positional argument (%n$) reorders the fields: not modelled here.
    size_t j = i;
    while (j < s.size() && isdigit((unsigned char)s[j]))
      ++j;
    if (j < s.size() && j > i && s[j] == '$')
      unimplemented("eff-tape: a printf format with positional arguments (%n$)", fmt);
    while (i < s.size() && StringRef("-+ #0'").contains(s[i]))
      ++i;
    if (i < s.size() && s[i] == '*') {
      conv.push_back('*');
      ++i;
    }
    while (i < s.size() && isdigit((unsigned char)s[i]))
      ++i;
    if (i < s.size() && s[i] == '.') {
      ++i;
      if (i < s.size() && s[i] == '*') {
        conv.push_back('*');
        ++i;
      }
      while (i < s.size() && isdigit((unsigned char)s[i]))
        ++i;
    }
    while (i < s.size() && StringRef("hlLqjzt").contains(s[i]))
      ++i;
    if (i >= s.size())
      break;
    conv.push_back(s[i]);
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

// One field of an entry, argument a of CB. conv is printf's conversion character for it (0 for an
// effect entry, whose string arguments must be constant C strings of readonly parameters).
void emitField(LoweringContext &ctx, CallBase &CB, unsigned a, char conv, Value *tape, Value *flag) {
  Value *v = CB.getArgOperand(a);
  Type *ty = v->getType();
  if (ty->isPointerTy()) {
    if (nonClassicalPointer(ctx, v))
      unimplemented("eff-tape: a quantum or non-classical pointer argument of a host effect", &CB);
    bool str = conv ? conv == 's'
                    : constantCString(v) && (CB.paramHasAttr(a, Attribute::ReadOnly) ||
                                             CB.paramHasAttr(a, Attribute::ReadNone));
    if (!str)
      unimplemented("eff-tape: a classical pointer argument of a host effect that is not a string", &CB);
    Operand s = ctx.operand(v);
    ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteStrLit}, {tape, s.v});
    return;
  }
  if (!ty->isIntegerTy() && !ty->isFloatingPointTy())
    unimplemented("eff-tape: a host effect argument that is not a scalar or a string", &CB);
  if (conv == 's' || conv == 'n' || conv == 'p')
    unimplemented("eff-tape: a printf conversion that does not match its scalar argument", &CB);
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
    unimplemented(std::string("eff-tape: ") + what + " inside an inlined callee (rule 19)", &CB);
  if (!ctx.S.isEntry())
    unimplemented(std::string("eff-tape: ") + what + " inside a clone (its _unc twin would replay it)", &CB);
}

// The abort arm (rule 16): snapshots of the rails later modified in place, then abort_i1(flag), the flag kept.
void abortArm(LoweringContext &ctx, CallBase &CB, Value *flag) {
  auto targets = laterInPlaceTargets(ctx, CB);

  // A merged handle (a select/phi of rails, rule 9) cannot be kept itself: copy it out (Uncompute's
  // contract). A rail minted by a call (template, seed, gate) is kept as it is (45).
  RailType i1{Kind::Int, 1};
  if (!isa<CallInst>(flag)) {
    CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
    RailId fid = ctx.unc().recordSeed(f);
    abi::CoreSpec cp{abi::Core::Copy, i1};
    CallInst *c = ctx.emitCore(cp, {flag, f});
    ctx.unc().recordCore(c, cp, {Operand{flag, true}, Operand{f, true}}, fid);
    flag = f;
  }

  for (auto &t : targets) {
    Value *h = t.first;
    if (h == flag)
      unimplemented("eff-tape: the abort flag itself is modified in place after the noreturn arm", &CB);
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

// The default action of a signal on the target (Darwin's <sys/signal.h> numbering).
enum class SigDefault { Terminate, Ignore, Stop, Unknown };
SigDefault signalDefault(const Module &M, int64_t sig) {
  if (!Triple(M.getTargetTriple()).isOSDarwin() || sig < 1 || sig > 31)
    return SigDefault::Unknown;
  switch (sig) {
  case 16: case 19: case 20: case 23: case 28: case 29:   // URG, CONT, CHLD, IO, WINCH, INFO
    return SigDefault::Ignore;
  case 17: case 18: case 21: case 22:                     // STOP, TSTP, TTIN, TTOU
    return SigDefault::Stop;
  default:
    return SigDefault::Terminate;
  }
}

// CR rule 16 (102): raise(sig) under a quantum predicate, read against the module's signal table (the
// signal(sig, h) calls of the module: closed world, as taint reads it). The delivery is an effect entry
// (cqrt_tape_effect_controlled(flag, tape, "raise"), the signal number its field). Then: a handler h the
// module installs for sig runs as h(sig) under the predicate (taint's _ctl clone of h, calls::lowerLiftedVia);
// with no handler, a signal whose default action terminates is the abort arm (abort_i1(flag), 45); one whose
// default action is to ignore it has nothing more. Unimplemented: a run-time signal number, a sigaction in
// the module, a signal() of sig whose handler is not a function the module defines (SIG_IGN, SIG_DFL, a
// declaration, a run-time value), several handlers, a stop signal, a non-Darwin target.
void lowerRaise(LoweringContext &ctx, CallBase &CB, Value *flag) {
  auto *sigC = dyn_cast<ConstantInt>(CB.getArgOperand(0));
  if (!sigC)
    unimplemented("eff-tape: raise of a signal number that is not a constant", &CB);
  int64_t sig = sigC->getSExtValue();
  SmallPtrSet<const Function *, 2> handlers;
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
      auto *H = dyn_cast<Function>(C->getArgOperand(1)->stripPointerCasts());
      if (!H || H->isDeclaration())
        unimplemented("eff-tape: raise of a signal whose installed handler is not a function the module defines "
                      "(SIG_IGN, SIG_DFL or a run-time handler)",
                      &CB);
      handlers.insert(H);
    }
  if (handlers.size() > 1)
    unimplemented("eff-tape: raise of a signal the module installs several handlers for", &CB);
  SigDefault dflt = signalDefault(ctx.M, sig);
  if (handlers.empty() && (dflt == SigDefault::Stop || dflt == SigDefault::Unknown))
    unimplemented("eff-tape: raise of a signal with no handler whose default action is not terminate or ignore",
                  &CB);
  if (handlers.empty() && dflt == SigDefault::Terminate)
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
  if (dflt == SigDefault::Terminate)
    abortArm(ctx, CB, flag);
}

} // namespace

void lowerHostEffect(LoweringContext &ctx, CallBase &CB) {
  if (CB.getFunction() != ctx.S.F)
    unimplemented("eff-tape: a tape entry inside an inlined callee (rule 19)", &CB);
  if (!CB.getType()->isVoidTy() && !CB.use_empty())
    unimplemented("eff-tape: the result of a host effect is used (the call is never executed)", &CB);
  // A clone appends its entries to its own tape each time it runs (67: "one tape per function"). Its
  // _unc twin recomputes through the _pure clone (CR §1.4, 119), which is the clone without its effects:
  // tape entries are write-once and never replayed, so the _pure clone emits none.
  if (ctx.S.pure)
    return;
  if (!ctx.S.isEntry() && (ctx.S.ctl || ctx.S.adj))
    unimplemented("eff-tape: a tape entry inside a _ctl or _adj clone (its predicate includes the caller's "
                  "control)",
                  &CB);
  const Function *F = calleeOf(CB);
  if (!F)
    internalError("eff-tape: a host effect with no direct callee", &CB);
  Value *flag = ctx.currentFlag();

  // fwrite(buf, size, n, stdout) of a slot buffer (99): one entry of size * n raw %c bytes, one i8 field
  // per byte cell (a handle: a fresh tape rail; a classical cell: a literal).
  if (libFunc(*F, LibFunc_fwrite)) {
    auto *sz = dyn_cast<ConstantInt>(CB.getArgOperand(1));
    auto *cnt = dyn_cast<ConstantInt>(CB.getArgOperand(2));
    if (!sz || !cnt)
      unimplemented("eff-tape: fwrite with a size or count that is not a constant", &CB);
    if (!isStdout(CB.getArgOperand(3)))
      unimplemented("eff-tape: fwrite to a stream other than stdout", &CB);
    Value *buf = CB.getArgOperand(0);
    if (ctx.T.isFatPointer(buf, ctx.S) || ctx.T.isQuantum(buf, ctx.S))
      unimplemented("eff-tape: fwrite through a fat pointer (rule 21)", &CB);
    bool slot = false, other = false;
    for (ObjectId o : ctx.T.provenance(buf, ctx.S))
      (ctx.T.classOf(o) == ObjClass::Slot ? slot : other) = true;
    if (!slot || other)
      unimplemented("eff-tape: fwrite of a buffer that is not one slot object", &CB);
    uint64_t n = sz->getZExtValue() * cnt->getZExtValue();
    LLVMContext &C = ctx.M.getContext();
    SmallVector<Operand, 8> cells = mem::readSlotCells(ctx, buf, Type::getInt8Ty(C), n, CB);
    Value *tape = tapeOf(ctx);
    Constant *fmt = fwriteFormat(ctx.M, n);
    if (flag)
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt, {}, /*ctl=*/true}, {flag, tape, fmt});
    else
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt}, {tape, fmt});
    RailType w{Kind::Int, 8};
    for (const Operand &c : cells) {
      if (!c.handle) {
        ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, w}, {tape, c.v});
        continue;
      }
      CallInst *h2 = flag ? ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w, /*ctl=*/true}, {flag, tape, c.v})
                          : ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w}, {tape, c.v});
      ctx.unc().recordExternal(h2, Role::Tape);
    }
    return;
  }
  // fputs(s, stdout) of a constant string: an entry with format s and no fields (99). A '%' in s would
  // be read as a conversion by the printf entry: unimplemented.
  if (libFunc(*F, LibFunc_fputs)) {
    Value *str = CB.getArgOperand(0);
    StringRef text;
    if (nonClassicalPointer(ctx, str) || !constantCString(str) || !getConstantStringInfo(str, text) ||
        text.contains('%'))
      unimplemented("eff-tape: fputs of a string that is not a constant without '%'", &CB);
    if (!isStdout(CB.getArgOperand(1)))
      unimplemented("eff-tape: fputs to a stream other than stdout", &CB);
    Value *tape = tapeOf(ctx);
    Value *sv = ctx.operand(str).v;
    if (flag)
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt, {}, /*ctl=*/true}, {flag, tape, sv});
    else
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt}, {tape, sv});
    return;
  }

  if (libFunc(*F, LibFunc_printf)) {
    Value *fmt = CB.getArgOperand(0);
    if (nonClassicalPointer(ctx, fmt))
      unimplemented("eff-tape: a printf format that is not a classical string", &CB);
    SmallVector<char, 8> conv;
    bool known = printfConversions(fmt, conv);
    Value *tape = tapeOf(ctx);
    Value *f = ctx.operand(fmt).v;
    if (flag)
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt, {}, /*ctl=*/true}, {flag, tape, f});
    else
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeFmt}, {tape, f});
    for (unsigned a = 1; a < CB.arg_size(); ++a) {
      char c = 0;
      if (known) {
        if (a - 1 >= conv.size())
          break;   // an argument the format never reads is not printed
        c = conv[a - 1];
      } else if (CB.getArgOperand(a)->getType()->isPointerTy()) {
        unimplemented("eff-tape: a pointer argument of printf with a format that is not a constant", &CB);
      }
      emitField(ctx, CB, a, c, tape, flag);
    }
    return;
  }

  if (!flag)
    unimplemented("eff-tape: a host effect with a quantum argument under no quantum predicate is neither a "
                  "printf entry nor a controlled effect entry (§1.11 has no uncontrolled effect)", &CB);
  if (F->getName() == "raise" && CB.arg_size() == 1) {
    lowerRaise(ctx, CB, flag);
    return;
  }
  if (signalFamily(F->getName()))
    unimplemented("eff-tape: a signal-family host call (its meaning depends on the module's signal table, 102)",
                  &CB);
  for (unsigned a = 0; a < CB.arg_size(); ++a) {
    Type *t = CB.getArgOperand(a)->getType();
    if (t->isPointerTy() && isa<Function>(CB.getArgOperand(a)->stripPointerCasts()))
      unimplemented("eff-tape: a host effect with a function pointer argument (a callback)", &CB);
  }
  // Every pointer argument must be a string the entry can copy; checked per field below, but before
  // anything is emitted.
  for (unsigned a = 0; a < CB.arg_size(); ++a) {
    Value *v = CB.getArgOperand(a);
    if (!v->getType()->isPointerTy())
      continue;
    if (nonClassicalPointer(ctx, v) || !constantCString(v) ||
        !(CB.paramHasAttr(a, Attribute::ReadOnly) || CB.paramHasAttr(a, Attribute::ReadNone)))
      unimplemented("eff-tape: a pointer argument of a host effect that is not a constant string", &CB);
  }
  Value *tape = tapeOf(ctx);
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeEffect, {}, /*ctl=*/true},
               {flag, tape, effectName(ctx.M, F->getName())});
  for (unsigned a = 0; a < CB.arg_size(); ++a)
    emitField(ctx, CB, a, 0, tape, flag);
}

void lowerNoreturn(LoweringContext &ctx, CallBase &CB) {
  requireEntry(ctx, CB, "a noreturn arm");
  for (const Use &u : CB.args())
    if (!isa<Constant>(u.get()) && ctx.T.isQuantum(u.get(), ctx.S))
      unimplemented("eff-tape: a noreturn call with a quantum argument", &CB);
  Value *flag = ctx.currentFlag();
  if (!flag)
    unimplemented("eff-tape: a noreturn call whose quantum predicate is top (an unconditional abort)", &CB);

  abortArm(ctx, CB, flag);
}

} // namespace cq::tape
