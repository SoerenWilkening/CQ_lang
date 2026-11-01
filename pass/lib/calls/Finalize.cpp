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
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Transforms/Utils/Cloning.h"

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
  CallInst *copy = nullptr;
  for (User *U : f->users()) {
    if (U == SI)
      continue;
    auto *cp = dyn_cast<CallInst>(U);
    std::optional<abi::CoreSpec> c =
        cp && cp->getCalledFunction() ? abi::parseCore(cp->getCalledFunction()->getName()) : std::nullopt;
    if (!c || c->op != abi::Core::Copy || c->ctl || cp->getArgOperand(1) != f || cp->getArgOperand(0) == f || copy)
      return std::nullopt;
    copy = cp;
  }
  if (!copy || f->getNumUses() != 2)
    return std::nullopt;
  return CellCopyOut{SI, f, copy, A, off.getSExtValue()};
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

// Does replaying F (and the forward clones it calls) recompute its value and nothing else?
void checkReplayable(Function &F, Function &twin, SmallPtrSetImpl<Function *> &seen) {
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
      if (!inFrame(SI->getPointerOperand()) && !cellCopyOut(SI))
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
  bool handleRet = src.getReturnType() == h || srt;
  if ((!handleRet && nCells == 0) || twin.arg_size() < src.arg_size() + nCells + (handleRet ? 1 : 0))
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (an i32 handle result or a struct of fields, its arguments after the outs)",
                  &twin);
  unsigned nOuts = twin.arg_size() - src.arg_size() - nCells;
  if (!srt && nOuts != (handleRet ? 1u : 0u))
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " of a one-handle clone with several outs",
                  &twin);
  if (!srt && !handleRet && !src.getReturnType()->isVoidTy())
    unimplemented("calls: calls::finalize: a twin of a clone with a classical result and cell copy-outs", &twin);
  for (unsigned i = 0; i < src.arg_size(); ++i)
    if (twin.getArg(i + nOuts)->getType() != src.getArg(i)->getType())
      internalError("calls: calls::finalize: twin @" + twin.getName().str() + " argument types differ from @" +
                        src.getName().str(),
                    &twin);
  SmallPtrSet<Function *, 8> seen;
  checkReplayable(src, twin, seen);

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
    for (Instruction &I : instructions(src))
      if (auto *ld = dyn_cast<LoadInst>(&I)) {
        APInt o(64, 0);
        const DataLayout &DL = M.getDataLayout();
        const Value *b = ld->getPointerOperand()->stripAndAccumulateConstantOffsets(DL, o, true);
        if (b == co.formal)
          unimplemented("calls: calls::finalize: a clone reading through a pointer formal it copies a rail out to",
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

} // namespace

void finalize(Module &M) {
  SmallVector<Function *, 8> clones;
  for (Function &F : M) {
    if (!isClone(F))
      continue;
    if (!abi::parseClone(F.getName()))
      unimplemented("calls: calls::finalize: a symbol in the clone namespace that is not a canonical "
                    "clone name (a uniquified clone; CR §1.4)",
                    &F);
    clones.push_back(&F);
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
