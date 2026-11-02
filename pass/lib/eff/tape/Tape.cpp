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

#include "../../fatptr/FatPtrInternal.h"

#include "cq/Abi.h"
#include "cq/Aggregates.h"
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

#include <functional>
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

// The byte extent of the single object a classical pointer into a slot object points into, from the
// pointer (CR rule 16: one i8 field per byte up to the object's cell count).
std::optional<uint64_t> bytesToObjectEnd(LoweringContext &ctx, const Value *p) {
  const DataLayout &DL = ctx.M.getDataLayout();
  APInt off(DL.getIndexTypeSizeInBits(p->getType()), 0);
  const Value *base = p->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
  std::optional<uint64_t> size;
  if (auto *ai = dyn_cast<AllocaInst>(base)) {
    if (auto sz = ai->getAllocationSize(DL); sz && !sz->isScalable())
      size = sz->getFixedValue();
  } else if (auto *gv = dyn_cast<GlobalVariable>(base)) {
    size = DL.getTypeAllocSize(gv->getValueType());
  }
  if (!size || off.isNegative() || off.getZExtValue() > *size)
    return std::nullopt;
  return *size - off.getZExtValue();
}

// The byte size of a rule-21 root object (an alloca, a global, an allocation of constant size).
std::optional<uint64_t> rootBytes(LoweringContext &ctx, const Value *r) {
  const DataLayout &DL = ctx.M.getDataLayout();
  if (auto *ai = dyn_cast<AllocaInst>(r)) {
    if (auto sz = ai->getAllocationSize(DL); sz && !sz->isScalable())
      return sz->getFixedValue();
    return std::nullopt;
  }
  if (auto *gv = dyn_cast<GlobalVariable>(r))
    return DL.getTypeAllocSize(gv->getValueType()).getFixedValue();
  if (auto *CB = dyn_cast<CallBase>(r)) {
    Attribute as = CB->getFnAttr(Attribute::AllocSize);
    if (!as.isValid())
      if (const Function *F = CB->getCalledFunction())
        as = F->getFnAttribute(Attribute::AllocSize);
    if (as.isValid()) {
      auto [a, b] = as.getAllocSizeArgs();
      auto *n = dyn_cast<ConstantInt>(CB->getArgOperand(a));
      auto *m = b ? dyn_cast<ConstantInt>(CB->getArgOperand(*b)) : nullptr;
      if (n && (!b || m))
        return n->getZExtValue() * (m ? m->getZExtValue() : 1);
    }
  }
  return std::nullopt;
}

// The cells of a quantum pointer's bytes (rule 21: a load per candidate object, merged on the tag), up to
// `limit` bytes past it and each object's extent past it (fatptr::loadHostCells).
SmallVector<Operand, 8> fatBytes(LoweringContext &ctx, CallBase &CB, const Value *p, std::optional<uint64_t> limit) {
  std::optional<int64_t> off = fatptr::constantByteOffset(ctx, p);
  uint64_t n = 0;
  bool unknown = false;
  auto boundOf = [&](const Value *r) -> uint64_t {
    std::optional<uint64_t> sz = rootBytes(ctx, r);
    if (!sz) {
      unknown = true;
      return limit.value_or(0);
    }
    int64_t b = int64_t(*sz) - off.value_or(0);
    uint64_t u = b < 0 ? 0 : uint64_t(b);
    return limit ? std::min(u, *limit) : u;
  };
  // The largest bound over the candidate roots is the field count.
  for (const Value *r : fatptr::rootsOf(ctx, p))
    n = std::max(n, boundOf(r));
  if (unknown && !limit)
    unimplemented("eff-tape: the bytes of a quantum pointer one of whose objects has no static extent, with no "
                  "length bounding them",
                  &CB);
  return fatptr::loadHostCells(ctx, p, Type::getInt8Ty(ctx.M.getContext()), n, boundOf, CB);
}

// A %s whose bytes are handles (a classical pointer into a slot object, CR rule 16 fields):
// tape_str_begin(t), one i8 field per byte of the object from the pointer to its end (a slot cell's handle,
// or its classical value), tape_str_end(t). The backend prints up to the first byte that measures 0.
void slotStringField(LoweringContext &ctx, CallBase &CB, const Value *str, Value *tape, Value *flag);

// One field of an entry, argument a of CB. conv is printf's conversion character for it ('*' a width or
// precision; 0 for an effect entry). A conversion that does not match its argument's type is undefined
// behaviour (C17 7.21.6.1p9), outside the domain: the field is the argument as it is, and the backend's
// printf reads it as the host's would.
void emitField(LoweringContext &ctx, CallBase &CB, unsigned a, char conv, Value *tape, Value *flag) {
  Value *v = CB.getArgOperand(a);
  Type *ty = v->getType();
  if (ty->isPointerTy()) {
    if (conv == 's' && nonClassicalPointer(ctx, v)) {
      slotStringField(ctx, CB, v, tape, flag);
      return;
    }
    if (nonClassicalPointer(ctx, v) && (ctx.T.isFatPointer(v, ctx.S) || ctx.T.isQuantum(v, ctx.S))) {
      // A quantum pointer (rule 21) as a value field (%p, an effect's argument): its address, the i64 its
      // ptrtoint is (a rail when the tag or idx is one).
      scalarField(ctx, tape, flag, fatptr::addressOf(ctx, v), Type::getInt64Ty(ctx.M.getContext()));
      return;
    }
    Operand s = ctx.operand(v);
    if (conv == 's' || (!conv && constantCString(v) &&
                        (CB.paramHasAttr(a, Attribute::ReadOnly) || CB.paramHasAttr(a, Attribute::ReadNone)))) {
      ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteStrLit}, {tape, s.v});
      return;
    }
    // Any other classical host pointer (a FILE *, %p, %n's destination, a callback, a pointer of a run-time
    // format): its address, an i64 literal.
    emitPointerValue(ctx, s.v, tape);
    return;
  }
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
  SmallVector<std::pair<const LoadInst *, Type *>, 2> cellLoads;
  struct ObjectCells { const Value *base; Type *ty; uint64_t n; };
  SmallVector<ObjectCells, 2> objectCells;
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
    if (auto *ld = dyn_cast<LoadInst>(I)) {
      const Value *p = ld->getPointerOperand();
      bool slot = false;
      for (ObjectId o : ctx.T.provenance(p, ctx.S))
        slot |= ctx.T.classOf(o) == ObjClass::Slot;
      if (!slot)
        return;   // a QRAM or QROM load copies out into a fresh rail (§1.3)
      auto *pi = dyn_cast<Instruction>(p);
      if (!pi || DT.dominates(pi, &CB)) {
        cellLoads.push_back({ld, ld->getType()});
        return;
      }
      if (auto *gep = dyn_cast<GetElementPtrInst>(pi); gep && all_of(gep->operands(), [&](const Value *x) {
            auto *xi = dyn_cast<Instruction>(x);
            return !xi || DT.dominates(xi, &CB);
          })) {
        cellLoads.push_back({ld, ld->getType()});
        return;
      }
      // The address is computed after the arm: the rotated cell is one of the object's, unknown at the
      // abort, so every cell of each object it may name is snapshotted (each holds its rail at the abort).
      const DataLayout &DL = ctx.M.getDataLayout();
      SmallVector<const Value *, 4> bases;
      getUnderlyingObjects(p, bases);
      for (const Value *b : bases) {
        auto *bi = dyn_cast<Instruction>(b);
        if (bi && !DT.dominates(bi, &CB))
          internalError("eff-tape: a slot object allocated after the noreturn arm read by a later rotation", ld);
        std::optional<uint64_t> size;
        if (auto *ai = dyn_cast<AllocaInst>(b)) {
          if (auto sz = ai->getAllocationSize(DL); sz && !sz->isScalable())
            size = sz->getFixedValue();
        } else if (auto *gv = dyn_cast<GlobalVariable>(b)) {
          size = DL.getTypeAllocSize(gv->getValueType());
        }
        uint64_t cell = DL.getTypeStoreSize(ld->getType());
        if (!size || !cell)
          unimplemented("eff-tape: a rotation after a noreturn arm of a cell of a slot object of unknown extent "
                        "at an address computed after the arm",
                        ld);
        objectCells.push_back({b, ld->getType(), *size / cell});
      }
      return;
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
          for (const User *usr : a->users())
            if (auto *ld = dyn_cast<LoadInst>(usr); ld && ld->getPointerOperand() == a)
              target(ld);
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
  // A slot cell a later load reads: the rail it holds at the abort (mem::readSlotCells, M4).
  for (auto &cl : cellLoads) {
    if (!cl.second->isIntegerTy() && !cl.second->isFloatingPointTy())
      continue;
    SmallVector<Operand, 1> c = mem::readSlotCells(ctx, cl.first->getPointerOperand(),
                                                   cl.second, 1, CB);
    if (!c.empty() && c[0].handle && seenH.insert(c[0].v).second)
      out.push_back({c[0].v, cl.second});
  }
  for (auto &oc : objectCells) {
    if (!oc.ty->isIntegerTy() && !oc.ty->isFloatingPointTy())
      continue;
    SmallVector<Operand, 8> c = mem::readSlotCells(ctx, oc.base, oc.ty, oc.n, CB);
    for (const Operand &x : c)
      if (x.handle && seenH.insert(x.v).second)
        out.push_back({x.v, oc.ty});
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
      if (n == "sigaction")
        unimplemented("eff-tape: raise in a module that installs handlers through sigaction (102: the handler "
                      "read from a struct sigaction)",
                      &CB);
      // bsd_signal and sigset have signal's interface (POSIX): the same table entry.
      if ((n != "signal" && n != "bsd_signal" && n != "sigset") || C->arg_size() != 2)
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
          else if (ci->isOne() || ci->getZExtValue() == 5)
            ign = true;   // SIG_IGN; SIG_HOLD (5, sigset): the signal is held, nothing runs at the raise
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
  // A default action of stop suspends the process until SIGCONT, after which it continues: the delivery
  // entry alone, as for ignore (orchestrator decision under rule 16, owner may override).
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

// The quantum length of a buffer field (CR rule 16 fields): len > j as an i1 rail, `and`ed with the entry's
// flag (one control per field).
Value *byteGuard(LoweringContext &ctx, const Operand &len, unsigned lenBits, uint64_t j, Value *flag) {
  abi::TemplateSpec gt;
  gt.op = "icmp";
  gt.pred = "ugt";
  gt.w = RailType{Kind::Int, lenBits};
  gt.shape = "hl";
  Value *c = ctx.emitTemplate(gt, {len, Operand{ConstantInt::get(IntegerType::get(ctx.M.getContext(), lenBits), j), false}});
  if (!flag)
    return c;
  abi::TemplateSpec andT;
  andT.op = "and";
  andT.w = RailType{Kind::Int, 1};
  return ctx.emitTemplate(andT, {Operand{c, true}, Operand{flag, true}});
}

// One i8 field under a per-field control (a quantum length): a classical byte is first a seed rail (rule 7),
// since a literal field has no controlled form.
void guardedByteField(LoweringContext &ctx, Value *tape, Value *ctl, Operand c) {
  RailType w{Kind::Int, 8};
  if (!c.handle) {
    CallInst *sd = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {c.v});
    ctx.unc().recordSeed(sd);
    c = Operand{sd, true};
  }
  CallInst *h2 = ctx.emitCore(abi::CoreSpec{abi::Core::TapeWrite, w, /*ctl=*/true}, {ctl, tape, c.v});
  ctx.unc().recordExternal(h2, Role::Tape);
}

// The upper bound of a classical-or-quantum length (LLVM's range facts of the original value).
std::optional<uint64_t> lengthBound(const Value *v, const DataLayout &DL) {
  if (auto *ci = dyn_cast<ConstantInt>(v))
    return ci->getZExtValue();
  if (!v->getType()->isIntegerTy())
    return std::nullopt;
  ConstantRange R = computeConstantRange(v, /*ForSigned=*/false, /*UseInstrInfo=*/true);
  R = R.intersectWith(ConstantRange::fromKnownBits(computeKnownBits(v, DL), /*IsSigned=*/false),
                      ConstantRange::Unsigned);
  if (R.isFullSet() || R.isWrappedSet())
    return std::nullopt;
  APInt hi = R.getUnsignedMax();
  if (hi.getActiveBits() > 63)
    return std::nullopt;
  return hi.getZExtValue();
}

// A buffer argument (CR rule 16 fields: fwrite's, write's): its cells, one i8 field per byte up to the
// length's upper bound, each _controlled under len > j when the length is quantum; a run-time classical
// length is a classical loop of field writes. elemSize * count bytes (count the original call's operand;
// elemSize a constant, or 0 when the byte count is count itself).
void bufferFields(LoweringContext &ctx, CallBase &CB, const Value *buf, const Value *sizeV, const Value *countV,
                  Value *tape, Value *flag) {
  LLVMContext &C = ctx.M.getContext();
  const DataLayout &DL = ctx.M.getDataLayout();
  IRBuilder<> &B = ctx.B();
  Type *i8 = Type::getInt8Ty(C), *i64 = Type::getInt64Ty(C);
  bool fat = ctx.T.isFatPointer(buf, ctx.S) || ctx.T.isQuantum(buf, ctx.S);
  bool slot = false, classical = false, qram = false;
  for (ObjectId o : ctx.T.provenance(buf, ctx.S)) {
    ObjClass k = ctx.T.classOf(o);
    (k == ObjClass::Slot ? slot : k == ObjClass::Classical ? classical : qram) = true;
  }
  // A quantum pointer, or one into a QRAM or into several classes of object, reads its bytes by rule 21
  // (a load per candidate object, merged on the tag).
  fat = fat || qram || (slot && classical);
  // The byte count: sizeV * countV (sizeV null: countV alone).
  Operand cnt = ctx.operand(countV);
  Operand sz = sizeV ? ctx.operand(sizeV) : Operand{ConstantInt::get(countV->getType(), 1), false};
  unsigned bits = countV->getType()->getIntegerBitWidth();
  Operand len;
  if (!cnt.handle && !sz.handle) {
    len = Operand{B.CreateMul(sz.v, cnt.v), false};
  } else {
    abi::TemplateSpec mul;
    mul.op = "mul";
    mul.w = RailType{Kind::Int, bits};
    if (cnt.handle && sz.handle)
      len = Operand{ctx.emitTemplate(mul, {cnt, sz}), true};
    else if (cnt.handle && isa<ConstantInt>(sz.v) && cast<ConstantInt>(sz.v)->isOne())
      len = cnt;
    else if (sz.handle && isa<ConstantInt>(cnt.v) && cast<ConstantInt>(cnt.v)->isOne())
      len = sz;
    else {
      mul.shape = "hl";
      len = cnt.handle ? Operand{ctx.emitTemplate(mul, {cnt, sz}), true} : Operand{ctx.emitTemplate(mul, {sz, cnt}), true};
    }
  }
  auto *lenC = len.handle ? nullptr : dyn_cast<ConstantInt>(len.v);
  // The bound: the constant length, else the lengths' range product, capped by the object's extent.
  std::optional<uint64_t> bound;
  if (lenC)
    bound = lenC->getZExtValue();
  else {
    std::optional<uint64_t> a = lengthBound(countV, DL), b = sizeV ? lengthBound(sizeV, DL) : std::optional<uint64_t>(1);
    if (a && b && (!*b || *a <= UINT64_MAX / *b))
      bound = *a * *b;
    if (std::optional<uint64_t> e = bytesToObjectEnd(ctx, buf); e && (!bound || *e < *bound))
      bound = *e;
  }
  if (!slot && !fat && !len.handle && !lenC) {
    // A classical host buffer of a run-time classical length: a classical loop of literal fields.
    Function &out = ctx.out();
    Value *p = ctx.operand(buf).v;
    Value *n = B.CreateZExtOrTrunc(len.v, i64);
    BasicBlock *pre = B.GetInsertBlock();
    BasicBlock *head = BasicBlock::Create(C, "", &out);
    BasicBlock *body = BasicBlock::Create(C, "", &out);
    BasicBlock *done = BasicBlock::Create(C, "", &out);
    B.CreateBr(head);
    B.SetInsertPoint(head);
    PHINode *j = B.CreatePHI(i64, 2);
    j->addIncoming(ConstantInt::get(i64, 0), pre);
    B.CreateCondBr(B.CreateICmpULT(j, n), body, done);
    B.SetInsertPoint(body);
    Value *byte = B.CreateLoad(i8, B.CreateInBoundsGEP(i8, p, j));
    ctx.emitCore(abi::CoreSpec{abi::Core::TapeWriteLit, RailType{Kind::Int, 8}}, {tape, byte});
    j->addIncoming(B.CreateAdd(j, ConstantInt::get(i64, 1)), body);
    B.CreateBr(head);
    B.SetInsertPoint(done);
    return;
  }
  if (!bound && fat) {
    // The length's range is unknown: the bytes up to each candidate object's extent (fatBytes).
    std::optional<uint64_t> none;
    SmallVector<Operand, 8> c = fatBytes(ctx, CB, buf, none);
    bound = c.size();
  }
  if (!bound)
    unimplemented("eff-tape: a buffer field of a length with no upper bound over an object of unknown extent", &CB);
  SmallVector<Operand, 8> cells;
  if (fat) {
    cells = fatBytes(ctx, CB, buf, bound);
  } else if (slot) {
    cells = mem::readSlotCells(ctx, buf, i8, *bound, CB);
  } else {
    // A classical buffer: its bytes read at the call (copied at call time). Under a quantum length a byte
    // past the length is not read by the program; it is read here only within the object's extent.
    Value *p = ctx.operand(buf).v;
    for (uint64_t i = 0; i < *bound; ++i)
      cells.push_back(Operand{B.CreateLoad(i8, B.CreateConstInBoundsGEP1_64(i8, p, i)), false});
  }
  for (uint64_t i = 0; i < cells.size(); ++i) {
    if (len.handle) {
      guardedByteField(ctx, tape, byteGuard(ctx, len, bits, i, flag), cells[i]);
      continue;
    }
    if (lenC) {
      scalarField(ctx, tape, flag, cells[i], i8);
      continue;
    }
    // A slot buffer of a run-time classical length: each field under the classical guard j < len.
    Function &out = ctx.out();
    BasicBlock *arm = BasicBlock::Create(C, "", &out);
    BasicBlock *next = BasicBlock::Create(C, "", &out);
    B.CreateCondBr(B.CreateICmpULT(ConstantInt::get(len.v->getType(), i), len.v), arm, next);
    B.SetInsertPoint(arm);
    scalarField(ctx, tape, flag, cells[i], i8);
    B.CreateBr(next);
    B.SetInsertPoint(next);
  }
}

void slotStringField(LoweringContext &ctx, CallBase &CB, const Value *str, Value *tape, Value *flag) {
  bool fat = ctx.T.isFatPointer(str, ctx.S) || ctx.T.isQuantum(str, ctx.S);
  for (ObjectId o : ctx.T.provenance(str, ctx.S))
    fat |= ctx.T.classOf(o) != ObjClass::Slot;
  std::optional<uint64_t> n = fat ? std::nullopt : bytesToObjectEnd(ctx, str);
  // A quantum pointer, a pointer into a QRAM or several classes of object, or one at a run-time offset:
  // the bytes by rule 21 (a load per candidate object and byte, merged on the tag).
  SmallVector<Operand, 8> cells = n ? mem::readSlotCells(ctx, str, Type::getInt8Ty(ctx.M.getContext()), *n, CB)
                                    : fatBytes(ctx, CB, str, std::nullopt);
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeStrBegin}, {tape});
  for (const Operand &c : cells)
    scalarField(ctx, tape, flag, c, Type::getInt8Ty(ctx.M.getContext()));
  ctx.emitCore(abi::CoreSpec{abi::Core::TapeStrEnd}, {tape});
}

// A signal-table call (signal, sigaction, bsd_signal, sigset, kill, killpg, pthread_kill, sigqueue) that
// goes on the tape: an effect entry with its arguments as fields (rule 16). kill and its kin send a signal
// to a process or thread the call names at replay. A table installation under a quantum predicate makes the
// handler a merged value that a later raise of that signal dispatches over (rule 16 signal table); when the
// module raises no signal the installation may concern, nothing reads the table in the program and the
// entry is the whole construction.
void signalTableEntry(LoweringContext &ctx, CallBase &CB, const Function &F) {
  StringRef n = F.getName();
  bool installs = n == "signal" || n == "sigaction" || n == "bsd_signal" || n == "sigset";
  if (installs) {
    const Value *sigV = CB.arg_size() ? CB.getArgOperand(0) : nullptr;
    auto *sigC = sigV ? dyn_cast<ConstantInt>(sigV) : nullptr;
    for (const Function &G : ctx.M)
      for (const User *u : G.users()) {
        auto *C = dyn_cast<CallBase>(u);
        if (!C || C->getCalledOperand() != &G || G.getName() != "raise" || C->arg_size() != 1)
          continue;
        auto *r = dyn_cast<ConstantInt>(C->getArgOperand(0));
        if (!sigC || !r || r->getSExtValue() == sigC->getSExtValue())
          unimplemented("eff-tape: a signal handler installed under a quantum predicate for a signal the module "
                        "raises (rule 16 signal table: the merged handler tag the raise dispatches over)",
                        &CB);
      }
  }
  Value *flag = ctx.currentFlag();
  if (n == "raise")
    // A classical raise on the tape (tape order): with no handler the module installs, its delivery entry
    // replays the default action in order; a handler of the program would run at replay, out of order.
    for (const Function &G : ctx.M)
      if (G.isDeclaration() && !G.use_empty() &&
          (G.getName() == "signal" || G.getName() == "sigaction" || G.getName() == "bsd_signal" ||
           G.getName() == "sigset"))
        unimplemented("eff-tape: a classical raise after a tape point in a module that installs signal handlers "
                      "(rule 16 tape order: the handler runs in program order)",
                      &CB);
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
