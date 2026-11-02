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
// finalize cannot see through Calls.h); a dead original whose body was rewritten in place (it calls
// an ABI symbol: a tainted entry function that also has clones and no in-module caller).
#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"

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

// The defined, non-clone function C was made from, or nullptr when its fn has no body here.
Function *originalOf(Module &M, Function &C) {
  StringRef rest = C.getName().drop_front(kClonePrefix.size());
  SmallVector<Function *, 2> cands;
  for (size_t i = rest.find('_'); i != StringRef::npos; i = rest.find('_', i + 1)) {
    Function *G = M.getFunction(rest.take_front(i));
    if (!G || G->isDeclaration() || isClone(*G))
      continue;
    // fn = G iff the rest of the symbol reads as the suffix of a clone of some one-token fn.
    std::optional<abi::CloneSpec> s = abi::parseClone((Twine(kClonePrefix) + "x_" + rest.drop_front(i + 1)).str());
    if (s && s->fn == "x")
      cands.push_back(G);
  }
  if (cands.size() > 1)
    unimplemented("calls: calls::finalize: a clone name that reads as a clone of more than one in-module "
                  "function (@" + cands[0]->getName().str() + ", @" + cands[1]->getName().str() +
                      ") (CR §1.4)",
                  &C);
  return cands.empty() ? nullptr : cands[0];
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
  case Core::AbortI1:
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
};
std::optional<CellCopyOut> cellCopyOut(StoreInst *SI) {
  const DataLayout &DL = SI->getModule()->getDataLayout();
  APInt off(64, 0);
  const Value *base = SI->getPointerOperand()->stripAndAccumulateConstantOffsets(DL, off, true);
  auto *A = dyn_cast<Argument>(const_cast<Value *>(base));
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
  return CellCopyOut{SI, f, copies.front(), A, off.getSExtValue()};
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
  for (size_t k = 1; k < out.size(); ++k)
    if (out[k].formal == out[k - 1].formal && out[k].off == out[k - 1].off)
      unimplemented("calls: calls::finalize: a clone storing into one caller cell more than once (the twin "
                    "restores each cell once)",
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
// uncompute: a non-ctl cqrt_qram_store on a formal bus followed, up to the return, only by such stores
// and the return value's insertvalues. The twin drops it (the caller pops it, U3).
bool trailingQramStore(const Instruction &I) {
  auto isStore = [](const Instruction *J) {
    auto *c = dyn_cast<CallInst>(J);
    std::optional<abi::CoreSpec> cs =
        c && c->getCalledFunction() ? abi::parseCore(c->getCalledFunction()->getName()) : std::nullopt;
    return cs && cs->op == abi::Core::QramStore && !cs->ctl && !cs->unc && isa<Argument>(c->getArgOperand(0));
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
void checkReplayable(Function &F, Function &twin, SmallPtrSetImpl<Function *> &seen, bool top = false) {
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

void defineTwin(Module &M, Function &twin, Function &src) {
  LLVMContext &C = M.getContext();
  Type *h = Type::getInt32Ty(C);
  // Outs: one for an i32 handle result, one per handle field of a field-wise result (CR §1.4).
  // Phase 2: the trailing old cells, one per cell copy-out of src (formal order, ascending offset).
  SmallVector<CellCopyOut, 4> cells = cellCopyOuts(src);
  unsigned nCells = cells.size();
  auto *srt = dyn_cast<StructType>(src.getReturnType());
  // An i32 result is a handle when the twin has an out for it; with none (52's reduce: int n + 1 and
  // two cell copy-outs) it is a classical result, which the twin drops.
  if (twin.arg_size() < src.arg_size() + nCells)
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (its outs, the clone's arguments, then the old cells)",
                  &twin);
  unsigned nOuts = twin.arg_size() - src.arg_size() - nCells;
  bool handleRet = srt || (src.getReturnType() == h && nOuts == 1);
  if ((!handleRet && nCells == 0) || (!srt && nOuts > 1) || (!handleRet && nOuts != 0))
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (an i32 handle result or a struct of fields, its arguments after the outs)",
                  &twin);
  for (unsigned i = 0; i < src.arg_size(); ++i)
    if (twin.getArg(i + nOuts)->getType() != src.getArg(i)->getType())
      internalError("calls: calls::finalize: twin @" + twin.getName().str() + " argument types differ from @" +
                        src.getName().str(),
                    &twin);
  SmallPtrSet<Function *, 8> seen;
  checkReplayable(src, twin, seen, true);

  ValueToValueMapTy VM;
  for (unsigned j = 0; j < nOuts; ++j)
    twin.getArg(j)->setName(nOuts == 1 ? "out" : "out" + std::to_string(j));
  for (unsigned i = 0; i < src.arg_size(); ++i) {
    VM[src.getArg(i)] = twin.getArg(i + nOuts);
    twin.getArg(i + nOuts)->setName(src.getArg(i)->getName());
  }
  for (unsigned k = 0; k < nCells; ++k)
    twin.getArg(nOuts + src.arg_size() + k)->setName("old" + std::to_string(k));
  SmallVector<ReturnInst *, 4> rets;
  CloneFunctionInto(&twin, &src, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
  twin.setAttributes(AttributeList());
  twin.setCallingConv(CallingConv::C);
  twin.setLinkage(GlobalValue::InternalLinkage);

  // Phase 2: each cell copy-out f = alloc(0); copy(r, f); store f, cell becomes c = load cell (the handle
  // the forward left there, the caller's reloaded rail); copy(r, c) (XORs it out); store old_k, cell (the
  // cell's content before the call). Nothing in src reads a cell it copied out to.
  for (unsigned k = 0; k < nCells; ++k) {
    const CellCopyOut &co = cells[k];
    auto *st = cast<StoreInst>(VM[co.st]);
    auto *f = cast<CallInst>(VM[co.f]);
    Argument *old = twin.getArg(nOuts + src.arg_size() + k);
    if (old->getType() != st->getValueOperand()->getType())
      unimplemented("calls: calls::finalize: a twin's old cell of another type than the cell's handle", st);
    // A load of the cell before the copy-out (122's read-modify-write, p->c += d) read the cell's content
    // before the call; in the twin the cell holds the forward's copy instead, so it reads old_k. Any
    // other load through the formal that may overlap the cell is unimplemented.
    const DataLayout &DL = M.getDataLayout();
    uint64_t cellSize = DL.getTypeStoreSize(st->getValueOperand()->getType());
    for (Instruction &I : instructions(src))
      if (auto *ld = dyn_cast<LoadInst>(&I)) {
        APInt o(64, 0);
        const Value *b = ld->getPointerOperand()->stripAndAccumulateConstantOffsets(DL, o, true);
        if (b != co.formal)
          continue;
        int64_t lo = o.getSExtValue();
        uint64_t ls = DL.getTypeStoreSize(ld->getType());
        if (lo + int64_t(ls) <= co.off || co.off + int64_t(cellSize) <= lo)
          continue; // another cell
        if (lo == co.off && ld->getType() == old->getType() && !isPotentiallyReachable(co.st, ld)) {
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
    Value *at = twin.getArg(nOuts + co.formal->getArgNo());
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
    // A classical arm seeds its result rail with its value (cq-mjwb); its twin would XOR that
    // constant into out, which is not built yet.
    if (a && a->op == abi::Core::Alloc && zero && !zero->isNullValue())
      unimplemented("calls: calls::finalize: a clone return seeded with a classical value (its twin would "
                    "XOR the constant into out)",
                    R);
    if (!a || a->op != abi::Core::Alloc || !zero || !zero->isNullValue())
      unimplemented("calls: calls::finalize: a clone return that is not the rule 18 copy-out (a fresh |0> "
                    "rail returned)",
                    R);
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
    if (copies.size() != 1)
      unimplemented("calls: calls::finalize: a clone's result rail written by other than one copy", f);
    copies.front()->setArgOperand(1, out);
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
      Value *v = ret;
      while (auto *iv = dyn_cast<InsertValueInst>(v)) {
        if (iv->getNumIndices() != 1 || !iv->hasOneUse())
          unimplemented("calls: calls::finalize: a field-wise clone return that is not one insertvalue chain", R);
        if (!fields[iv->getIndices()[0]])
          fields[iv->getIndices()[0]] = iv->getInsertedValueOperand();
        chain.push_back(iv);
        v = iv->getAggregateOperand();
      }
      if (!isa<PoisonValue>(v) && !isa<UndefValue>(v))
        unimplemented("calls: calls::finalize: a field-wise clone return that is not built from poison", R);
      unsigned j = 0;
      for (unsigned k = 0; k < fields.size(); ++k) {
        auto *f = dyn_cast_or_null<CallInst>(fields[k]);
        std::optional<abi::CoreSpec> a =
            f && f->getCalledFunction() ? abi::parseCore(f->getCalledFunction()->getName()) : std::nullopt;
        if (!a || a->op != abi::Core::Alloc)
          continue;   // a classical field
        if (j >= nOuts)
          internalError("calls: calls::finalize: a field-wise clone return with more handle fields than its twin's outs",
                        R);
        retarget(f, twin.getArg(j++), R);
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
        retarget(rv, twin.getArg(0), R);
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

  SetVector<Function *> originals;
  for (Function *C : clones)
    if (Function *G = originalOf(M, *C))
      originals.insert(G);

  // Liveness. Seeds: a use outside every original's body.
  SmallPtrSet<Function *, 16> live;
  SmallVector<Function *, 16> work;
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
  for (Function *D : dead) {
    // A local function no live code reaches is dead code whatever its body became (cq-57ju: musl exp's
    // static specialcase, rewritten in place because its volatile local is a slot object, rule 20, and
    // reached only from exp's dropped original). An externally visible one rewritten in place is an
    // entry the program exports: never dropped silently.
    if (D->hasLocalLinkage() && !D->hasAddressTaken()) {
      collectReferences(*D, refs);
      continue;
    }
    for (Instruction &I : instructions(*D))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *callee = CB->getCalledFunction(); callee && isAbiSymbol(callee->getName()))
          unimplemented("calls: calls::finalize: an original with no classical caller whose body was "
                        "rewritten in place (a tainted entry function that also has clones)",
                        D);
    collectReferences(*D, refs);
  }

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
