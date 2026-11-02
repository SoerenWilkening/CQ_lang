// calls::finalize (cq-by8, owner ruling 2026-10-27 option (a)): CR §1.4 and rule 18, "the
// original (unlifted) body is kept only while a classical call site still uses it; a callee whose
// every call was retargeted is dropped."
//
// Runs once per module after every construct() and before verifyLowered.
//
//   Clones.     A function in the clone namespace (CR §1.4, "__cq_q_") whose symbol abi::parseClone
//               accepts, defined or declared, twins included. A module with none is left untouched:
//               finalize returns before reading anything else.
//   Originals.  The defined, non-clone function a clone was made from: the fn of the clone's §1.4
//               reading. The reading is checked against every defined function of the module, not
//               only the right-to-left parse, so a name that reads as a clone of two in-module
//               functions (CR §1.4: a fn ending in _<binary>_b<N>) is an internal error, not a
//               guess. A clone whose fn has no body here (rule 27 declared clones, libm names of
//               intrinsics with no injected body) has no original.
//   Live.       An original with a use anywhere but inside an original's body (a call or any other
//               use: classical call sites, address-taken function pointers, global initializers,
//               @llvm.used) is live, and so is every original a live original's body uses. The
//               rest have no classical caller left: every call was retargeted to a clone, or comes
//               from another dropped original (mutual recursion, call chains: 33, 119).
//   Dropped.    Every original that is not live. What a dropped body alone referenced and that now
//               has no use is dropped with it when it carries no symbol of its own: declarations
//               and local-linkage functions and variables.
//
// Twins (rule 18, CR §1.4 "a twin nobody calls is not defined"). Before the originals are read, every
// declared `<clone>_unc` with a use whose forward clone has a body here is defined: the twin
// recomputes, XORs the result out of `out`, uncomputes. Its body is the lowered forward clone's (the
// _pure clone's when one exists: what the twins recompute through, 119) with the copy-out
// `f = cqrt_alloc_<W>(0); cqrt_copy_<W>(r, f); ...; ret f` of every return (Walker::emitCloneReturn)
// turned into `cqrt_copy_<W>(r, out); ...; ret void` (a return phi chosen classically has one such f
// per incoming edge, Walker::returnCopyOut: each copy targets out, the phi goes; an arm seeded with a
// classical value is unimplemented): the clone computes, copies out, uncomputes,
// so the twin computes, XORs out, uncomputes. A twin body that calls another twin defines it in turn.
// The body is checked to replay nothing but the pure value: no rotation, phase, measurement, tape,
// abort or QRAM store, no host call that may write memory (unimplemented otherwise: a clone with
// effects and no _pure clone). Twins use the C calling convention (Uncompute spells their calls) and
// internal linkage. A twin of a clone with no body here (rule 27) stays a declaration.
//
// Shapes not lowered here (cq::unimplemented): a "__cq_q_" symbol that is not a canonical clone
// name (a uniquified clone, CR §1.4 ruling 2026-10-27: the clone table belongs to materialize, which
// finalize cannot see through Calls.h). An original whose body was rewritten in place (it calls an ABI
// symbol) is the lowered entry and stays live (cq-i9wk).
#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "../spine/SpineInternal.h"

#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <optional>

#include <string>

using namespace llvm;

namespace cq::calls {
namespace {

constexpr StringLiteral kClonePrefix = "__cq_q_";

bool isClone(const Function &F) { return F.getName().starts_with(kClonePrefix); }

// True iff the symbol is in one of the ABI namespaces the lowering emits (CR §1.1 to §1.4).
bool isAbiSymbol(StringRef name) {
  bool unc = false;
  return abi::parseCore(name).has_value() || abi::parseTemplate(name, &unc).has_value() ||
         abi::parseClone(name).has_value();
}

// The defined, non-clone function C was made from, or nullptr when its fn has no body here. The normative
// right-to-left reading of CR §1.4 names it: every clone symbol of the module reads back to exactly the fields
// it was made from (calls' checkedName refuses any other), so that reading is the clone's fn.
Function *originalOf(Module &M, Function &C) {
  std::optional<abi::CloneSpec> s = abi::parseClone(C.getName());
  if (!s)
    internalError("calls: calls::finalize: originalOf of a symbol that is not a canonical clone name", &C);
  Function *G = M.getFunction(s->fn);
  if (!G || G->isDeclaration() || isClone(*G))
    return nullptr;
  return G;
}

// Every global reachable from the constants in `work`, through constant expressions and aggregates.
void collectGlobals(SmallVector<const Constant *, 8> work, SetVector<GlobalValue *> &out) {
  SmallPtrSet<const Constant *, 16> seen;
  while (!work.empty()) {
    const Constant *c = work.pop_back_val();
    if (!seen.insert(c).second)
      continue;
    if (auto *gv = dyn_cast<GlobalValue>(c)) {
      out.insert(const_cast<GlobalValue *>(gv));
      continue;
    }
    for (const Value *op : c->operands())
      if (auto *oc = dyn_cast<Constant>(op))
        work.push_back(oc);
  }
}

// Every global a function body references.
void collectReferences(Function &F, SetVector<GlobalValue *> &out) {
  SmallVector<const Constant *, 8> work;
  for (Instruction &I : instructions(F))
    for (Value *op : I.operands())
      if (auto *c = dyn_cast<Constant>(op))
        work.push_back(c);
  collectGlobals(std::move(work), out);
}

// ---- twins ----------------------------------------------------------------------------------------

bool nonPureCore(abi::Core op) {
  using abi::Core;
  switch (op) {
  case Core::Measure: case Core::Ry: case Core::RyQAngle: case Core::RzI1: case Core::RzQAngle:
  case Core::QramStore: case Core::QramRealloc: case Core::TapeAlloc: case Core::TapeFmt:
  case Core::TapeEffect: case Core::TapeWrite: case Core::TapeWriteLit: case Core::TapeWriteStrLit:
  case Core::TapeStrBegin: case Core::TapeStrEnd: case Core::AbortI1:
    return true;
  default:
    return false;
  }
}

// Phase 2 (CR rules 18, 20, §1.4; cq-arch T2 + M1): a clone's store of a computed rail into a caller's
// slot cell is the rule 18 copy-out through a pointer formal: f = cqrt_alloc_<W>(0), cqrt_copy_<W>(r, f),
// store f at a constant offset of a (non-byval) pointer formal; f has no other use.
struct CellCopyOut {
  StoreInst *st;
  CallInst *f, *copy;
  Argument *formal;
  int64_t off;
  // cq-1c5j (CR rule 21): a slot triple formal's cell: formal is the object parameter and idx the classical
  // i32 cell index parameter; the cell is at handle idx of the object, then off bytes (spine binds the formal
  // to that address at the clone's entry). base: the address the clone's accesses of the cell strip to.
  Argument *idx = nullptr;
  const Value *base = nullptr;
};
// The object and index parameters of `gep inbounds i32, obj, sext(idx)` (a slot triple formal's address).
std::optional<std::pair<Argument *, Argument *>> tripleCellBase(const Value *v) {
  auto *g = dyn_cast<GetElementPtrInst>(v);
  if (!g || g->getNumIndices() != 1 || !g->getSourceElementType()->isIntegerTy(32))
    return std::nullopt;
  auto *obj = dyn_cast<Argument>(g->getPointerOperand());
  const Value *i = g->getOperand(1);
  if (auto *se = dyn_cast<SExtInst>(i))
    i = se->getOperand(0);
  auto *idx = dyn_cast<Argument>(const_cast<Value *>(i));
  if (!obj || !idx || !obj->getType()->isPointerTy() || !idx->getType()->isIntegerTy(32))
    return std::nullopt;
  return std::make_pair(const_cast<Argument *>(obj), idx);
}
std::optional<CellCopyOut> cellCopyOut(StoreInst *SI) {
  const DataLayout &DL = SI->getModule()->getDataLayout();
  APInt off(64, 0);
  const Value *base = SI->getPointerOperand()->stripAndAccumulateConstantOffsets(DL, off, true);
  auto *A = dyn_cast<Argument>(const_cast<Value *>(base));
  Argument *idxArg = nullptr;
  if (auto t = tripleCellBase(base))
    std::tie(A, idxArg) = *t;
  if (!A || A->hasByValAttr() || !A->getType()->isPointerTy())
    return std::nullopt;
  auto *f = dyn_cast<CallInst>(SI->getValueOperand());
  std::optional<abi::CoreSpec> a =
      f && f->getCalledFunction() ? abi::parseCore(f->getCalledFunction()->getName()) : std::nullopt;
  auto *zero = f ? dyn_cast<Constant>(f->getArgOperand(0)) : nullptr;
  if (!a || a->op != abi::Core::Alloc || !zero || !zero->isNullValue())
    return std::nullopt;
  // One copy-out rail, possibly written by several copies (a clone storing into the cell on some paths:
  // the entry copies the old content in, each arm store copies the old out and its value in; cq-vxgm).
  SmallVector<CallInst *, 2> copies;
  for (User *U : f->users()) {
    if (U == SI)
      continue;
    auto *cp = dyn_cast<CallInst>(U);
    std::optional<abi::CoreSpec> c =
        cp && cp->getCalledFunction() ? abi::parseCore(cp->getCalledFunction()->getName()) : std::nullopt;
    if (!c || c->op != abi::Core::Copy || c->ctl || cp->getArgOperand(1) != f || cp->getArgOperand(0) == f)
      return std::nullopt;
    copies.push_back(cp);
  }
  if (copies.empty() || f->getNumUses() != copies.size() + 1)
    return std::nullopt;
  return CellCopyOut{SI, f, copies.front(), A, off.getSExtValue(), idxArg, base};
}

// The cell copy-outs of F, in formal order then ascending offset (the twin's trailing old cells).
SmallVector<CellCopyOut, 4> cellCopyOuts(Function &F) {
  SmallVector<CellCopyOut, 4> out;
  for (Instruction &I : instructions(F))
    if (auto *SI = dyn_cast<StoreInst>(&I))
      if (auto c = cellCopyOut(SI))
        out.push_back(*c);
  llvm::stable_sort(out, [](const CellCopyOut &a, const CellCopyOut &b) {
    return a.formal->getArgNo() != b.formal->getArgNo() ? a.formal->getArgNo() < b.formal->getArgNo()
                                                          : a.off < b.off;
  });
  // Copy-outs into one cell on exclusive paths (a classical branch whose arms each store their own result):
  // one old cell for the twin, restored by whichever copy-out its replay reaches. Two that one path runs in
  // sequence would leave the cell holding the later one's rail when the earlier one's replay reads it.
  for (size_t k = 1; k < out.size(); ++k)
    if (out[k].formal == out[k - 1].formal && out[k].off == out[k - 1].off)
      for (size_t j = k; j-- > 0 && out[j].formal == out[k].formal && out[j].off == out[k].off;)
        if (isPotentiallyReachable(out[j].st, out[k].st) || isPotentiallyReachable(out[k].st, out[j].st))
          unimplemented("calls: calls::finalize: a clone storing into one caller cell twice on one path (the twin "
                        "restores the cell once, from the first store's replay)",
                        out[k].st);
  return out;
}

// A classical value computed from the clone's arguments and constants alone (no memory read, no call,
// no phi): the twin's replay computes the same value the forward did.
bool argumentsOnly(const Value *v, unsigned depth = 0) {
  if (isa<Argument>(v) || isa<Constant>(v))
    return true;
  auto *I = dyn_cast<Instruction>(v);
  if (!I || depth > 32 || I->mayReadFromMemory() || isa<CallBase>(I) || isa<PHINode>(I))
    return false;
  return all_of(I->operands(), [&](const Use &u) { return argumentsOnly(u.get(), depth + 1); });
}

// cq-99z6 (ent_a1, ent_a2): may F read the memory SI writes before SI runs (a load, or a call reading
// through a pointer, from which SI is reachable)? Then a replay of SI in the twin would make that read
// see the stored value instead of the caller's. In F two formals may point into one object, and a
// formal may point into a global; only distinct allocas of F, or an alloca against a formal or a
// global, provably differ.
bool readBefore(Function &F, StoreInst *SI) {
  const Value *sb = getUnderlyingObject(SI->getPointerOperand());
  auto mayAliasStore = [&](const Value *p) {
    SmallVector<const Value *, 4> objs;
    getUnderlyingObjects(p, objs);
    for (const Value *u : objs) {
      if (u == sb)
        return true;
      if (isa<AllocaInst>(u) || isa<AllocaInst>(sb))
        continue;   // F's frame is not the caller's object, nor another alloca of F
      if (auto *A = dyn_cast<Argument>(u); A && A->hasByValAttr())
        continue;   // F's own copy
      if (isa<GlobalVariable>(u) && isa<GlobalVariable>(sb))
        continue;   // two distinct globals
      if (isa<ConstantPointerNull>(u) || (isa<GlobalVariable>(u) && cast<GlobalVariable>(u)->isConstant()))
        continue;
      return true;
    }
    return false;
  };
  for (Instruction &I : instructions(F)) {
    if (&I == SI || !I.mayReadFromMemory())
      continue;
    bool reads = false;
    if (auto *L = dyn_cast<LoadInst>(&I))
      reads = mayAliasStore(L->getPointerOperand());
    else if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (auto *ii = dyn_cast<IntrinsicInst>(CB); ii && (ii->isLifetimeStartOrEnd() || ii->isAssumeLikeIntrinsic()))
        continue;
      if (Function *G = CB->getCalledFunction(); G && (G->getName().starts_with("cq_template_") ||
                                                       G->getName().starts_with("cqrt_")))
        continue;
      reads = !CB->onlyAccessesArgMemory() ||
              any_of(CB->args(), [&](const Use &a) { return a->getType()->isPointerTy() && mayAliasStore(a); });
    } else {
      reads = true;   // an atomic, va_arg, ...
    }
    if (reads && isPotentiallyReachable(&I, SI))
      return true;
  }
  return false;
}

// M2b (191): a store a clone makes through a triple formal onto a QRAM object, after its body's
// uncompute: a cqrt_qram_store[_hl][_controlled] on a formal bus followed, up to the return, only by such stores
// and the return value's insertvalues. The twin drops it (the caller pops it, U3).
bool trailingQramStore(const Instruction &I) {
  auto isStore = [](const Instruction *J) {
    auto *c = dyn_cast<CallInst>(J);
    std::optional<abi::CoreSpec> cs =
        c && c->getCalledFunction() ? abi::parseCore(c->getCalledFunction()->getName()) : std::nullopt;
    return cs && cs->op == abi::Core::QramStore && !cs->unc && isa<Argument>(c->getArgOperand(cs->ctl ? 1 : 0));
  };
  if (!isStore(&I))
    return false;
  for (const Instruction *J = I.getNextNode(); J; J = J->getNextNode()) {
    if (isa<ReturnInst>(J))
      return true;
    if (!isa<InsertValueInst>(J) && !isStore(J))
      return false;
  }
  return false;
}

// Does replaying F (and the forward clones it calls) recompute its value and nothing else? top: F is
// the twin's own source, whose trailing QRAM stores the twin drops (M2b).
void checkReplayable(Function &F, Function &twin, SmallPtrSetImpl<Function *> &seen, bool top = false,
                     const SmallPtrSetImpl<const Instruction *> *exempt = nullptr) {
  if (!seen.insert(&F).second)
    return;
  auto refuse = [&](const Twine &why, const Value *at) {
    unimplemented(("calls: calls::finalize: the twin @" + twin.getName() + " would replay " + why +
                   " (a clone with effects and no _pure clone)")
                      .str(),
                  at);
  };
  auto inFrame = [&](const Value *p) {
    const Value *u = getUnderlyingObject(p);
    auto *A = dyn_cast<Argument>(u);
    return isa<AllocaInst>(u) || (A && A->getParent() == &F && A->hasByValAttr());
  };
  for (Instruction &I : instructions(F)) {
    if (exempt && exempt->count(&I))
      continue;   // cq-i9wk: the making of a kept clone's register, which its twin takes as a parameter
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      // The clone's frame: its allocas and its byval formals (the callee's own copy, cq-09xh; the twin
      // gets the caller's snapshot, which nothing reads after the twin).
      // A cell copy-out (phase 2): the twin of F restores the cell; a forward clone F calls is undone
      // by its own twin call in F's body.
      // A classical store into a caller's object through a pointer formal of F itself, of a value of the
      // arguments alone (163's sret field c): the twin writes the value the cell already holds (the
      // object is not written between the call and its twin: an uncompute barrier, cq-fwto).
      const Value *base = getUnderlyingObject(SI->getPointerOperand());
      bool idempotent = isa<Argument>(base) && cast<Argument>(base)->getParent() == &F &&
                        argumentsOnly(SI->getValueOperand()) && SI->isSimple() && !readBefore(F, SI);
      if (!inFrame(SI->getPointerOperand()) && !cellCopyOut(SI) && !idempotent)
        refuse("a store to memory outside the clone's frame", &I);
      continue;
    }
    if (auto *MI = dyn_cast<MemIntrinsic>(&I)) {
      if (!inFrame(MI->getRawDest()))
        refuse("a memory intrinsic writing outside the clone's frame", &I);
      continue;   // a byval snapshot (cq-09xh) or another write of the frame
    }
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      // Rule 24: a volatile (or atomic, single-thread collapse) read of the frame is a plain read; the
      // replay reads the same cell. One of memory outside the frame is the host's.
      if (LI->isUnordered() || inFrame(LI->getPointerOperand()))
        continue;
      refuse("a volatile read of memory outside the clone's frame", &I);
    }
    if (I.mayWriteToMemory() && !isa<CallBase>(I))
      refuse("a memory write", &I);
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB)
      continue;
    if (CB->isInlineAsm())
      refuse("inline asm", &I);
    Function *G = CB->getCalledFunction();
    if (!G)
      refuse("an indirect call", &I);
    if (isa<DbgInfoIntrinsic>(CB) || G->getIntrinsicID() == Intrinsic::lifetime_start ||
        G->getIntrinsicID() == Intrinsic::lifetime_end)
      continue;
    bool unc = false;
    if (abi::parseTemplate(G->getName(), &unc))
      continue;
    // Rule 23: a constrained op under fpexcept.ignore or fpexcept.maytrap raises nothing observable and
    // rounds in the environment's mode, which the call and its twin share: a plain op, replayed like any
    // classical computation. Only fpexcept.strict writes the flags.
    if (auto *CFP = dyn_cast<ConstrainedFPIntrinsic>(CB)) {
      std::optional<fp::ExceptionBehavior> eb = CFP->getExceptionBehavior();
      if (!eb || *eb != fp::ebStrict)
        continue;
    }
    if (std::optional<abi::CoreSpec> c = abi::parseCore(G->getName())) {
      if (top && trailingQramStore(I))
        continue;   // dropped from the twin below (M2b)
      if (nonPureCore(c->op))
        refuse("the core gate @" + G->getName(), &I);
      continue;
    }
    if (std::optional<abi::CloneSpec> c = abi::parseClone(G->getName())) {
      if (!c->unc && !G->isDeclaration())
        checkReplayable(*G, twin, seen);
      continue;   // a twin is checked when it is defined; a declared clone is rule 27's
    }
    if (CB->onlyReadsMemory() && CB->willReturn())
      continue;
    // Rule 19 (cq-fl4n): an ordinary call of a body (a host call with classical arguments that taint did
    // not lift, musl's __math_oflowf(0)) replays what that body does: it is replayable when the body is,
    // its volatile accesses to its own dead locals being nothing (rule 24).
    if (!G->isDeclaration()) {
      checkReplayable(*G, twin, seen);
      continue;
    }
    refuse("the host call @" + G->getName(), &I);
  }
}

// The body the twin of `fwd` recomputes through: fwd's _pure clone when one is defined, else fwd.
Function *twinSource(Module &M, Function &fwd) {
  std::optional<abi::CloneSpec> s = abi::parseClone(fwd.getName());
  if (!s->pure) {
    abi::CloneSpec p = *s;
    p.pure = true;
    if (Function *P = M.getFunction(abi::name(p)); P && !P->isDeclaration())
      return P;
  }
  return &fwd;
}

// cq-i9wk (CR rule 19): a kept clone's registers. Its returns end with the handle of each register it minted
// that is still allocated (nRegs fields); its twin takes them first and recomputes against them. regs[k]: the
// k-th register value of each return; made: the instructions that make a register (its cqrt_alloc, the
// classical merges naming it, the non-diagonal gates and copies that write it), which the twin does not
// replay: it reads its parameter instead.
struct KeptRegisters {
  unsigned n = 0;
  SmallVector<SmallVector<Value *, 2>, 4> regs;
  SmallPtrSet<const Instruction *, 8> made;
  SmallVector<Instruction *, 8> defs;     // allocs and merges, replaced by the parameter
};
KeptRegisters keptRegisters(Function &src) {
  KeptRegisters kr;
  Attribute a = src.getFnAttribute(spine::kKeptRegistersAttr);
  if (!a.isValid())
    return kr;
  kr.n = unsigned(std::stoul(a.getValueAsString().str()));
  auto *srt = dyn_cast<StructType>(src.getReturnType());
  if (!srt || srt->getNumElements() < kr.n)
    internalError("calls: calls::finalize: a kept clone whose return type does not end with its registers", &src);
  kr.regs.resize(kr.n);
  unsigned first = srt->getNumElements() - kr.n;
  for (BasicBlock &BB : src)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      for (Value *v = R->getReturnValue(); auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
        if (iv->getNumIndices() == 1 && iv->getIndices()[0] >= first)
          kr.regs[iv->getIndices()[0] - first].push_back(iv->getInsertedValueOperand());
  SmallVector<Value *, 8> work;
  for (auto &vs : kr.regs) {
    if (vs.empty())
      internalError("calls: calls::finalize: a kept clone return that does not name one of its registers", &src);
    work.append(vs.begin(), vs.end());
  }
  SmallPtrSet<Value *, 8> seen;
  while (!work.empty()) {
    Value *d = work.pop_back_val();
    if (!seen.insert(d).second)
      continue;
    if (auto *z = dyn_cast<ConstantInt>(d); z && z->isZero())
      continue;   // handle 0: a return path that did not mint this register (§1.1, rule 19)
    auto *di = dyn_cast<Instruction>(d);
    if (!di)
      internalError("calls: calls::finalize: a kept clone register that is not an instruction", &src);
    if (auto *pn = dyn_cast<PHINode>(di)) {
      work.append(pn->incoming_values().begin(), pn->incoming_values().end());
    } else if (auto *sel = dyn_cast<SelectInst>(di)) {
      work.push_back(sel->getTrueValue());
      work.push_back(sel->getFalseValue());
    } else {
      auto *ci = dyn_cast<CallInst>(di);
      std::optional<abi::CoreSpec> c =
          ci && ci->getCalledFunction() ? abi::parseCore(ci->getCalledFunction()->getName()) : std::nullopt;
      if (!c || c->op != abi::Core::Alloc)
        unimplemented("calls: calls::finalize: a kept clone register that is not minted by cqrt_alloc or a classical "
                      "merge of such rails (rule 19)",
                      di);
    }
    kr.defs.push_back(di);
    kr.made.insert(di);
    for (User *U : di->users()) {
      auto *g = dyn_cast<CallInst>(U);
      std::optional<abi::CoreSpec> c =
          g && g->getCalledFunction() ? abi::parseCore(g->getCalledFunction()->getName()) : std::nullopt;
      if (!c)
        continue;
      unsigned target = c->ctl ? 1 : 0;
      bool writes = (nonPureCore(c->op) && c->op != abi::Core::Measure && g->arg_size() > target &&
                     g->getArgOperand(target) == di) ||
                    (c->op == abi::Core::Copy && g->arg_size() > 1 && g->getArgOperand(g->arg_size() - 1) == di);
      if (writes)
        kr.made.insert(g);
    }
  }
  return kr;
}

void defineTwin(Module &M, Function &twin, Function &src) {
  LLVMContext &C = M.getContext();
  Type *h = Type::getInt32Ty(C);
  KeptRegisters kr = keptRegisters(src);
  unsigned nRegs = kr.n;
  // Outs: one for an i32 handle result, one per handle field of a field-wise result (CR §1.4).
  // Phase 2: the trailing old cells, one per cell copy-out of src (formal order, ascending offset).
  SmallVector<CellCopyOut, 4> cells = cellCopyOuts(src);
  // One old cell per distinct cell (copy-outs into one cell lie on exclusive paths: cellCopyOuts).
  SmallVector<unsigned, 4> cellOf;
  unsigned nCells = 0;
  for (size_t k = 0; k < cells.size(); ++k) {
    if (k == 0 || cells[k].formal != cells[k - 1].formal || cells[k].off != cells[k - 1].off)
      ++nCells;
    cellOf.push_back(nCells - 1);
  }
  auto *srt = dyn_cast<StructType>(src.getReturnType());
  // An i32 result is a handle when the twin has an out for it; with none (52's reduce: int n + 1 and
  // two cell copy-outs) it is a classical result, which the twin drops.
  if (twin.arg_size() < src.arg_size() + nCells + nRegs)
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (its outs, the clone's arguments, then the old cells)",
                  &twin);
  unsigned nOuts = twin.arg_size() - src.arg_size() - nCells - nRegs;
  bool handleRet = srt || (src.getReturnType() == h && nOuts == 1);
  if ((!handleRet && nCells == 0) || (!srt && nOuts > 1) || (!handleRet && nOuts != 0))
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (an i32 handle result or a struct of fields, its arguments after the outs)",
                  &twin);
  for (unsigned i = 0; i < src.arg_size(); ++i)
    if (twin.getArg(i + nRegs + nOuts)->getType() != src.getArg(i)->getType())
      internalError("calls: calls::finalize: twin @" + twin.getName().str() + " argument types differ from @" +
                        src.getName().str(),
                    &twin);
  SmallPtrSet<Function *, 8> seen;
  checkReplayable(src, twin, seen, true, &kr.made);

  ValueToValueMapTy VM;
  for (unsigned k = 0; k < nRegs; ++k)
    twin.getArg(k)->setName("reg" + std::to_string(k));
  for (unsigned j = 0; j < nOuts; ++j)
    twin.getArg(nRegs + j)->setName(nOuts == 1 ? "out" : "out" + std::to_string(j));
  for (unsigned i = 0; i < src.arg_size(); ++i) {
    VM[src.getArg(i)] = twin.getArg(i + nRegs + nOuts);
    twin.getArg(i + nRegs + nOuts)->setName(src.getArg(i)->getName());
  }
  for (unsigned k = 0; k < nCells; ++k)
    twin.getArg(nRegs + nOuts + src.arg_size() + k)->setName("old" + std::to_string(k));
  SmallVector<ReturnInst *, 4> rets;
  CloneFunctionInto(&twin, &src, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
  twin.setAttributes(AttributeList());
  twin.setCallingConv(CallingConv::C);
  twin.setLinkage(GlobalValue::InternalLinkage);

  // cq-i9wk (rule 19): the twin reads each kept register from its parameter instead of making it again. The
  // twin's copies are taken first: VM's handles follow replaceAllUsesWith.
  if (nRegs) {
    SmallPtrSet<const Instruction *, 8> isDef(kr.defs.begin(), kr.defs.end());
    SmallVector<Instruction *, 8> gates;
    for (const Instruction *m : kr.made)
      if (!isDef.count(m))
        gates.push_back(cast<Instruction>(VM[m]));
    SmallVector<std::pair<Instruction *, unsigned>, 8> defs;   // twin copy, register index
    for (unsigned k = 0; k < nRegs; ++k) {
      SmallVector<Value *, 8> work(kr.regs[k].begin(), kr.regs[k].end());
      SmallPtrSet<Value *, 8> done;
      while (!work.empty()) {
        Value *d = work.pop_back_val();
        if (!done.insert(d).second || isa<ConstantInt>(d))
          continue;   // handle 0 (rule 19): nothing to replace
        if (auto *pn = dyn_cast<PHINode>(d))
          work.append(pn->incoming_values().begin(), pn->incoming_values().end());
        else if (auto *sel = dyn_cast<SelectInst>(d)) {
          work.push_back(sel->getTrueValue());
          work.push_back(sel->getFalseValue());
        }
        defs.push_back({cast<Instruction>(VM[d]), k});
      }
    }
    for (Instruction *g : gates)
      g->eraseFromParent();
    for (auto &[td, k] : defs)
      td->replaceAllUsesWith(twin.getArg(k));
    for (auto &[td, k] : defs)
      td->eraseFromParent();
  }

  // Phase 2: each cell copy-out f = alloc(0); copy(r, f); store f, cell becomes c = load cell (the handle
  // the forward left there, the caller's reloaded rail); copy(r, c) (XORs it out); store old_k, cell (the
  // cell's content before the call). Nothing in src reads a cell it copied out to.
  SmallPtrSet<LoadInst *, 4> replaced;
  for (unsigned k = 0; k < cells.size(); ++k) {
    const CellCopyOut &co = cells[k];
    auto *st = cast<StoreInst>(VM[co.st]);
    auto *f = cast<CallInst>(VM[co.f]);
    Argument *old = twin.getArg(nRegs + nOuts + src.arg_size() + cellOf[k]);
    // A slot cell is physically an i32 handle cell (rule 20): the caller passes its content before the call
    // (mem-slots slotCellsBeforeCall), the clone stores a handle there.
    if (old->getType() != st->getValueOperand()->getType())
      internalError("calls: calls::finalize: a twin's old cell of another type than the cell's handle", st);
    // A load of the cell before the copy-out (122's read-modify-write, p->c += d) read the cell's content
    // before the call; in the twin the cell holds the forward's copy instead, so it reads old_k. Any
    // other load through the formal that may overlap the cell is unimplemented.
    const DataLayout &DL = M.getDataLayout();
    uint64_t cellSize = DL.getTypeStoreSize(st->getValueOperand()->getType());
    for (Instruction &I : instructions(src))
      if (auto *ld = dyn_cast<LoadInst>(&I)) {
        APInt o(64, 0);
        const Value *b = ld->getPointerOperand()->stripAndAccumulateConstantOffsets(DL, o, true);
        if (b != co.base) {
          // cq-u9oy: a load through the same formal at a run-time cell (fatptr's cell-count checked load of a
          // TripleCount formal, 190) may read this cell before its copy-out: the twin would read the forward's
          // copy instead of the old content.
          const Value *ub = getUnderlyingObject(b), *uc = getUnderlyingObject(co.base);
          if (ub == uc && isa<Argument>(ub) && !isPotentiallyReachable(co.st, ld))
            unimplemented("calls: calls::finalize: a clone reading a caller cell through a pointer formal at a run-time "
                          "cell before its copy-out to that object (the twin reads the old cell)",
                          ld);
          continue;
        }
        int64_t lo = o.getSExtValue();
        uint64_t ls = DL.getTypeStoreSize(ld->getType());
        if (lo + int64_t(ls) <= co.off || co.off + int64_t(cellSize) <= lo)
          continue; // another cell
        if (lo == co.off && ld->getType() == old->getType() && !isPotentiallyReachable(co.st, ld)) {
          if (!replaced.insert(ld).second)
            continue;   // another copy-out into this cell (an exclusive path) replaced it already
          auto *tl = cast<LoadInst>(VM[ld]);
          tl->replaceAllUsesWith(old);
          tl->eraseFromParent();
          continue;
        }
        unimplemented("calls: calls::finalize: a clone reading a caller cell through a pointer formal after (or "
                      "beside) its copy-out to that cell",
                      ld);
      }
    IRBuilder<> B(f);
    Value *at = twin.getArg(nRegs + nOuts + co.formal->getArgNo());
    if (co.idx)
      at = B.CreateInBoundsGEP(B.getInt32Ty(), at,
                               B.CreateSExt(twin.getArg(nRegs + nOuts + co.idx->getArgNo()), B.getInt64Ty()));
    if (co.off)
      at = B.CreateConstInBoundsGEP1_64(B.getInt8Ty(), at, uint64_t(co.off));
    Value *c = B.CreateAlignedLoad(st->getValueOperand()->getType(), at, st->getAlign(), "cell");
    f->replaceAllUsesWith(c);
    f->eraseFromParent();
    st->setOperand(0, old);
  }

  // M2b (191): the stores a clone makes through triple formals onto a QRAM object sit after its body's
  // uncompute, right before the return (after them only the return value's insertvalues). They are the
  // caller's to pop (U3) before it calls the twin, so the twin does not repeat them: dropped here, and
  // their copied-out rails are XORed into the twin's outs like any result field.
  for (ReturnInst *R : rets) {
    SmallVector<Instruction *, 2> stores;
    for (Instruction *I = R->getPrevNode(); I; I = I->getPrevNode()) {
      if (isa<InsertValueInst>(I))
        continue;
      if (!trailingQramStore(*I))
        break;
      stores.push_back(I);
    }
    for (Instruction *I : stores)
      I->eraseFromParent();
  }

  SmallVector<Instruction *, 4> dead;
  // The copy-out of rule 18: f = cqrt_alloc_<W>(0), cqrt_copy_<W>(r, f), ..., ret f: the copy is made
  // to target `out` instead and f goes.
  auto retarget = [&](Value *rv, Argument *out, ReturnInst *R) {
    auto *f = dyn_cast_or_null<CallInst>(rv);
    std::optional<abi::CoreSpec> a =
        f && f->getCalledFunction() ? abi::parseCore(f->getCalledFunction()->getName()) : std::nullopt;
    auto *zero = f ? dyn_cast<Constant>(f->getArgOperand(0)) : nullptr;
    if (!a || a->op != abi::Core::Alloc)
      unimplemented("calls: calls::finalize: a clone return that is not the rule 18 copy-out (a fresh |0> "
                    "rail returned)",
                    R);
    if (!zero || !zero->isNullValue()) {
      // A classical arm seeds its result rail with its value v (cq-mjwb): the forward's out holds v there,
      // so the twin XORs v out of it (cqrt_xorc_<W>(out, v)) where the forward minted the seed.
      IRBuilder<> XB(f);
      XB.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Xorc, a->w}), {out, f->getArgOperand(0)});
    }
    SmallVector<CallInst *, 2> copies;
    for (User *U : f->users()) {
      if (isa<ReturnInst>(U) || isa<PHINode>(U) || isa<InsertValueInst>(U))
        continue;
      auto *cp = dyn_cast<CallInst>(U);
      std::optional<abi::CoreSpec> c =
          cp && cp->getCalledFunction() ? abi::parseCore(cp->getCalledFunction()->getName()) : std::nullopt;
      if (!c || c->op != abi::Core::Copy || c->ctl || cp->getArgOperand(1) != f || cp->getArgOperand(0) == f)
        unimplemented("calls: calls::finalize: a clone's result rail used other than by its copy-out", U);
      copies.push_back(cp);
    }
    bool seeded = !zero || !zero->isNullValue();
    if (copies.size() != 1 && !(seeded && copies.empty()))
      unimplemented("calls: calls::finalize: a clone's result rail written by other than one copy", f);
    for (CallInst *cp : copies)
      cp->setArgOperand(1, out);
    if (!is_contained(dead, f))
      dead.push_back(f);
  };
  for (ReturnInst *R : rets) {
    Value *ret = R->getReturnValue();
    PHINode *rp = nullptr;
    SmallVector<Instruction *, 4> chain;
    if (srt) {
      // A field-wise result: the insertvalue chain of the return; its handle fields (the copy-outs, in
      // field order) are the outs.
      SmallVector<Value *, 4> fields(srt->getNumElements(), nullptr);
      unsigned nFields = srt->getNumElements() - nRegs;   // cq-i9wk: the registers are no outs
      Value *v = ret;
      while (auto *iv = dyn_cast<InsertValueInst>(v)) {
        // The spine builds every field-wise return as one insertvalue chain from poison (emitCloneReturn).
        if (iv->getNumIndices() != 1 || !iv->hasOneUse())
          internalError("calls: calls::finalize: a field-wise clone return that is not one insertvalue chain", R);
        if (!fields[iv->getIndices()[0]])
          fields[iv->getIndices()[0]] = iv->getInsertedValueOperand();
        chain.push_back(iv);
        v = iv->getAggregateOperand();
      }
      // IRBuilder folds the chain's leading insertions of constants (a classical constant result) into the
      // base: a constant aggregate, whose fields are classical.
      if (!isa<PoisonValue>(v) && !isa<UndefValue>(v) && !isa<ConstantAggregate>(v))
        internalError("calls: calls::finalize: a field-wise clone return that is not built from poison", R);
      unsigned j = 0;
      for (unsigned k = 0; k < nFields; ++k) {
        auto *f = dyn_cast_or_null<CallInst>(fields[k]);
        std::optional<abi::CoreSpec> a =
            f && f->getCalledFunction() ? abi::parseCore(f->getCalledFunction()->getName()) : std::nullopt;
        if (!a || a->op != abi::Core::Alloc)
          continue;   // a classical field
        if (j >= nOuts)
          internalError("calls: calls::finalize: a field-wise clone return with more handle fields than its twin's outs",
                        R);
        retarget(f, twin.getArg(nRegs + j++), R);
      }
      if (j != nOuts)
        internalError("calls: calls::finalize: a field-wise clone return with fewer handle fields than its twin's outs",
                      R);
    } else if (handleRet) {
      // The same f on several incoming edges (a switch's duplicate edges) is rewritten once; a return
      // phi chosen classically has one f per incoming edge (cq-mjwb, 119).
      SmallSetVector<Value *, 2> results;
      rp = dyn_cast_or_null<PHINode>(ret);
      if (rp && rp->hasOneUse())
        results.insert(rp->incoming_values().begin(), rp->incoming_values().end());
      else {
        rp = nullptr;
        results.insert(ret);
      }
      for (Value *rv : results)
        retarget(rv, twin.getArg(nRegs), R);
    }
    ReturnInst::Create(C, nullptr, R->getIterator());
    R->eraseFromParent();
    for (Instruction *iv : chain)
      iv->eraseFromParent();
    if (rp)
      rp->eraseFromParent();
  }
  for (Instruction *f : dead)
    if (f->use_empty())
      f->eraseFromParent();
    else
      internalError("calls: calls::finalize: a clone's result rail still used after its twin rewrite", f);

  // Rule 14's kept overflow predicate a_K = alloc_i1(0); and_i1(a_n, test, a_K), never freed, read by
  // nothing: the forward keeps it (one per activation); the twin, which only uncomputes the forward's
  // outs, does not compute it (169: "__cq_q_ilogb_1_unc itself keeps nothing"). Its test is the twin's
  // garbage as in the forward, uncomputed there.
  SmallVector<CallInst *, 2> keptK;
  for (Instruction &I : instructions(twin)) {
    auto *a = dyn_cast<CallInst>(&I);
    std::optional<abi::CoreSpec> c =
        a && a->getCalledFunction() ? abi::parseCore(a->getCalledFunction()->getName()) : std::nullopt;
    if (!c || c->op != abi::Core::Alloc || !a->getType()->isIntegerTy(32) || a->getNumUses() != 1)
      continue;
    auto *g = dyn_cast<CallInst>(a->user_back());
    if (g && g->getCalledFunction() && g->getCalledFunction()->getName() == "cqrt_and_i1" &&
        g->arg_size() == 3 && g->getArgOperand(2) == a && g->getArgOperand(0) != a && g->getArgOperand(1) != a)
      keptK.push_back(a);
  }
  for (CallInst *a : keptK) {
    cast<Instruction>(a->user_back())->eraseFromParent();
    a->eraseFromParent();
  }
}

// Defines every called, undefined twin whose forward clone has a body (see the header).
void defineTwins(Module &M) {
  for (bool changed = true; changed;) {
    changed = false;
    SmallVector<Function *, 8> todo;
    for (Function &F : M) {
      if (!isClone(F) || !F.isDeclaration() || F.use_empty())
        continue;
      std::optional<abi::CloneSpec> s = abi::parseClone(F.getName());
      if (!s || !s->unc)
        continue;
      todo.push_back(&F);
    }
    for (Function *T : todo) {
      Function *fwd = M.getFunction(T->getName().drop_back(4));   // "_unc"
      if (!fwd || fwd->isDeclaration())
        continue;   // rule 27: whatever is linked defines it
      defineTwin(M, *T, *twinSource(M, *fwd));
      changed = true;
    }
  }
}

// cq-nqa6: the _ctl entry-flag invariant (kCtlDistinctAttr) at every call site of a marked clone. The
// flag's handle leaves (through phis and selects) must each be one of: the caller's own entry flag (the
// caller is then marked in turn); a rail made by a gate call whose handle, or a merge of it, reaches
// only gate calls and the entry flag of _ctl clone calls (a predicate flag); a load of a cell of a local
// slot array (an alloca reached through GEPs) whose address reaches only GEPs, loads, stores of a
// handle into it and lifetime markers (the clone cannot reach its cells), when no other actual of the
// call has a leaf that is a load of that array or a value stored into it (a slot cell holds a rail no
// other cell holds, so no other cell names it either). Anything else is cq::unimplemented.
void handleLeaves(Value *v, SmallVectorImpl<Value *> &out, SmallPtrSetImpl<Value *> &seen) {
  if (!seen.insert(v).second)
    return;
  if (auto *P = dyn_cast<PHINode>(v)) {
    for (Value *u : P->incoming_values())
      handleLeaves(u, out, seen);
    return;
  }
  if (auto *S = dyn_cast<SelectInst>(v)) {
    handleLeaves(S->getTrueValue(), out, seen);
    handleLeaves(S->getFalseValue(), out, seen);
    return;
  }
  out.push_back(v);
}

bool gateCallee(const Function *G) {
  return G && ((G->getName().starts_with("cqrt_") && !G->getName().starts_with("cqrt_qram") &&
                !G->getName().starts_with("cqrt_push") && !G->getName().starts_with("cqrt_tape")) ||
               G->getName().starts_with("cq_template_"));
}

bool isCtlCall(const CallInst *CI, unsigned opNo) {
  const Function *G = CI->getCalledFunction();
  if (!G || opNo != 0 || !isClone(*G))
    return false;
  std::optional<abi::CloneSpec> n = abi::parseClone(G->getName());
  return n && n->ctl;
}

bool flagOnly(Value *h) {
  SmallVector<Value *, 8> work{h};
  SmallPtrSet<Value *, 8> seen;
  while (!work.empty()) {
    Value *v = work.pop_back_val();
    if (!seen.insert(v).second)
      continue;
    for (Use &U : v->uses()) {
      User *u = U.getUser();
      if (isa<PHINode>(u) || isa<SelectInst>(u)) {
        work.push_back(u);
        continue;
      }
      auto *CI = dyn_cast<CallInst>(u);
      if (CI && (gateCallee(CI->getCalledFunction()) || isCtlCall(CI, U.getOperandNo())))
        continue;
      return false;
    }
  }
  return true;
}

// The local slot array a load reads a cell of, when its address does not escape; nullptr otherwise.
AllocaInst *privateArray(LoadInst *L) {
  auto *A = dyn_cast<AllocaInst>(getUnderlyingObject(L->getPointerOperand()));
  if (!A)
    return nullptr;
  SmallVector<Value *, 8> work{A};
  SmallPtrSet<Value *, 8> seen;
  while (!work.empty()) {
    Value *v = work.pop_back_val();
    if (!seen.insert(v).second)
      continue;
    for (Use &U : v->uses()) {
      User *u = U.getUser();
      if (isa<GetElementPtrInst>(u)) {
        work.push_back(u);
        continue;
      }
      if (isa<LoadInst>(u))
        continue;
      if (auto *St = dyn_cast<StoreInst>(u); St && U.getOperandNo() == St->getPointerOperandIndex() &&
                                             !St->getValueOperand()->getType()->isPointerTy())
        continue;
      if (auto *II = dyn_cast<IntrinsicInst>(u); II && II->isLifetimeStartOrEnd())
        continue;
      return nullptr;
    }
  }
  return A;
}

void checkCtlDistinct(Module &M) {
  SmallVector<Function *, 8> work;
  SmallPtrSet<Function *, 8> marked;
  for (Function &F : M)
    if (F.hasFnAttribute(kCtlDistinctAttr) && marked.insert(&F).second)
      work.push_back(&F);
  while (!work.empty()) {
    Function *C = work.pop_back_val();
    for (User *U : C->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || CI->getCalledOperand() != C || CI->arg_size() == 0)
        unimplemented("calls: a use of a _ctl clone that relies on its entry flag naming no other rail, other "
                      "than a direct call (cq-nqa6)",
                      U);
      Function *F = CI->getFunction();
      SmallVector<Value *, 4> leaves;
      SmallPtrSet<Value *, 8> seen;
      handleLeaves(CI->getArgOperand(0), leaves, seen);
      for (Value *l : leaves) {
        if (auto *A = dyn_cast<Argument>(l); A && A->getParent() == F && A->getArgNo() == 0 && isClone(*F)) {
          std::optional<abi::CloneSpec> n = abi::parseClone(F->getName());
          if (n && n->ctl) {
            if (marked.insert(F).second)
              work.push_back(F);
            continue;
          }
        }
        if (auto *G = dyn_cast<CallInst>(l); G && gateCallee(G->getCalledFunction()) && flagOnly(G))
          continue;
        if (auto *L = dyn_cast<LoadInst>(l))
          if (AllocaInst *A = privateArray(L)) {
            // The rails A's cells may hold: its loads and the values stored into it.
            SmallPtrSet<Value *, 16> held;
            SmallVector<Value *, 8> ptrs{A};
            SmallPtrSet<Value *, 8> pseen;
            while (!ptrs.empty()) {
              Value *p = ptrs.pop_back_val();
              if (!pseen.insert(p).second)
                continue;
              for (User *u : p->users()) {
                if (isa<GetElementPtrInst>(u))
                  ptrs.push_back(u);
                else if (isa<LoadInst>(u))
                  held.insert(u);
                else if (auto *St = dyn_cast<StoreInst>(u)) {
                  SmallVector<Value *, 4> sl;
                  SmallPtrSet<Value *, 8> ss;
                  handleLeaves(St->getValueOperand(), sl, ss);
                  held.insert(sl.begin(), sl.end());
                }
              }
            }
            bool clash = false;
            for (unsigned i = 1; i < CI->arg_size() && !clash; ++i) {
              SmallVector<Value *, 4> al;
              SmallPtrSet<Value *, 8> as;
              handleLeaves(CI->getArgOperand(i), al, as);
              clash = any_of(al, [&](Value *x) { return held.count(x); });
            }
            if (!clash)
              continue;
          }
        unimplemented("calls: a _ctl call whose entry flag may name a rail the clone reaches otherwise (the "
                      "clone's controlled Ry relies on it, cq-nqa6)",
                      l);
      }
    }
  }
  for (Function *C : marked)
    C->removeFnAttr(kCtlDistinctAttr);
}

} // namespace

void finalize(Module &M) {
  checkCtlDistinct(M);
  SmallVector<Function *, 8> clones, unusedInv;
  for (Function &F : M) {
    if (!isClone(F))
      continue;
    std::optional<abi::CloneSpec> spec = abi::parseClone(F.getName());
    if (!spec)
      unimplemented("calls: calls::finalize: a symbol in the clone namespace that is not a canonical "
                    "clone name (a uniquified clone; CR §1.4)",
                    &F);
    // cq-necw (CR §1.4, rule 18): an _inv<c> clone is defined only when a call site uses it. A call site's
    // clean-up registered with it is pruned when the call's twin restores the cell (the old content is then
    // not dead), leaving it unused.
    if (!spec->inv.empty() && F.use_empty()) {
      unusedInv.push_back(&F);
      continue;
    }
    clones.push_back(&F);
  }
  for (Function *F : unusedInv) {
    SmallPtrSet<Function *, 8> callees;
    for (Instruction &I : instructions(*F))
      if (auto *CB = dyn_cast<CallBase>(&I); CB && CB->getCalledFunction())
        callees.insert(CB->getCalledFunction());
    F->eraseFromParent();
    for (Function *D : callees)
      if (D->isDeclaration() && D->use_empty())
        D->eraseFromParent();
  }
  if (clones.empty())
    return;
  defineTwins(M);
  for (Function &F : M)
    F.removeFnAttr(spine::kKeptRegistersAttr);   // cq-i9wk: read by the twins only

  SetVector<Function *> originals;
  for (Function *C : clones)
    if (Function *G = originalOf(M, *C))
      originals.insert(G);

  // Liveness. Seeds: a use outside every original's body, and an externally visible original whose body was
  // rewritten in place (it calls an ABI symbol): that body is an entry the program exports, not an unlifted
  // original (CR §1.4 drops only the latter).
  SmallPtrSet<Function *, 16> live;
  SmallVector<Function *, 16> work;
  auto rewrittenInPlace = [](Function &F) {
    for (Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *callee = CB->getCalledFunction(); callee && isAbiSymbol(callee->getName()))
          return true;
    return false;
  };
  // A local one rewritten in place that no live code reaches is dead code whatever its body became (cq-57ju:
  // musl exp's static specialcase, reached only from exp's dropped original): it follows the liveness below.
  for (Function *O : originals)
    if ((!O->hasLocalLinkage() || O->hasAddressTaken()) && rewrittenInPlace(*O) && live.insert(O).second)
      work.push_back(O);
  for (Function *O : originals)
    for (User *U : O->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !originals.count(I->getFunction())) {
        live.insert(O);
        work.push_back(O);
        break;
      }
    }
  while (!work.empty()) {
    Function *L = work.pop_back_val();
    for (Instruction &I : instructions(*L))
      for (Value *op : I.operands())
        if (auto *G = dyn_cast<Function>(op); G && originals.count(G) && live.insert(G).second)
          work.push_back(G);
  }

  SmallVector<Function *, 8> dead;
  for (Function *O : originals)
    if (!live.count(O))
      dead.push_back(O);
  if (dead.empty())
    return;

  SetVector<GlobalValue *> refs;
  for (Function *D : dead)
    collectReferences(*D, refs);

  SmallPtrSet<GlobalValue *, 16> erased;
  for (Function *D : dead)
    D->dropAllReferences();
  for (Function *D : dead) {
    erased.insert(D);
    D->eraseFromParent();
  }

  // What only the dropped bodies referenced, transitively, when it now has no use and no symbol of
  // its own (declarations, local linkage).
  bool changed = true;
  while (changed) {
    changed = false;
    for (size_t i = 0; i < refs.size(); ++i) {
      GlobalValue *G = refs[i];
      if (erased.count(G))
        continue;
      G->removeDeadConstantUsers();
      if (!G->use_empty() || !(G->isDeclaration() || G->hasLocalLinkage()))
        continue;
      if (auto *F = dyn_cast<Function>(G)) {
        collectReferences(*F, refs);
        F->dropAllReferences();
      } else if (auto *V = dyn_cast<GlobalVariable>(G)) {
        if (V->hasInitializer())
          collectGlobals({V->getInitializer()}, refs);
        V->dropAllReferences();
      } else {
        continue;   // aliases and ifuncs are left alone
      }
      erased.insert(G);
      G->eraseFromParent();
      changed = true;
    }
  }
}

} // namespace cq::calls
