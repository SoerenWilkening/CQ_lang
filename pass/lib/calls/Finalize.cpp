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
// abort or QRAM store (one into a bus of the replayed frame, which that frame pops and frees, is part of
// the computation: frameBus), no host call that may write memory (unimplemented otherwise: a clone with
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
#include <set>
#include <vector>

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


// The host <fenv.h> flag calls of eff-fenv's BRACKET and PROBE (hostFn: i32 name(i32), no body in the module):
// they read or write the host flags only. A program body of that name is replayed as any body.
bool hostFlagCall(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  return G && G->isDeclaration() && (G->getName() == "fetestexcept" || G->getName() == "feclearexcept" || G->getName() == "feraiseexcept") &&
         CB.arg_size() == 1 && CB.getType()->isIntegerTy(32) && CB.getArgOperand(0)->getType()->isIntegerTy(32);
}

// hostFlags: set when the replay touches the host flags (a strict constrained host op, a host flag call): the
// twin then restores them around its body (defineTwin).
void scanHostFlags(Function &F, SmallPtrSetImpl<Function *> &seen, bool &hostFlags) {
  if (!seen.insert(&F).second)
    return;
  for (Instruction &I : instructions(F)) {
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB)
      continue;
    if (isa<ConstrainedFPIntrinsic>(CB) || hostFlagCall(*CB)) {
      hostFlags = true;
      continue;
    }
    Function *G = CB->getCalledFunction();
    if (!G || G->isDeclaration())
      continue;
    if (std::optional<abi::CloneSpec> c = abi::parseClone(G->getName()); c && c->unc)
      continue;   // a twin is scanned when it is defined
    scanHostFlags(*G, seen, hostFlags);
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
  auto *srt = dyn_cast<StructType>(src.getReturnType());
  // An i32 result is a handle when the twin has an out for it; with none it is a classical result, which the twin
  // drops.
  if (twin.arg_size() < src.arg_size())
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (its outs, then the clone's arguments)",
                  &twin);
  unsigned nOuts = twin.arg_size() - src.arg_size();
  bool handleRet = srt || (src.getReturnType() == h && nOuts == 1);
  if (!handleRet && nOuts != 0)
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (an i32 handle result or a struct of fields, its arguments after)",
                  &twin);
  for (unsigned i = 0; i < src.arg_size(); ++i)
    if (twin.getArg(i + nOuts)->getType() != src.getArg(i)->getType())
      internalError("calls: calls::finalize: twin @" + twin.getName().str() + " argument types differ from @" +
                        src.getName().str(),
                    &twin);
  SmallPtrSet<Function *, 8> seen;
  bool hostFlags = false;
  scanHostFlags(src, seen, hostFlags);

  ValueToValueMapTy VM;
  for (unsigned j = 0; j < nOuts; ++j)
    twin.getArg(j)->setName(nOuts == 1 ? "out" : "out" + std::to_string(j));
  for (unsigned i = 0; i < src.arg_size(); ++i) {
    VM[src.getArg(i)] = twin.getArg(i + nOuts);
    twin.getArg(i + nOuts)->setName(src.getArg(i)->getName());
  }
  SmallVector<ReturnInst *, 4> rets;
  CloneFunctionInto(&twin, &src, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
  twin.setAttributes(AttributeList());
  twin.setCallingConv(CallingConv::C);
  twin.setLinkage(GlobalValue::InternalLinkage);

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
    SmallVector<PHINode *, 2> fieldPhis;
    if (srt) {
      // A field-wise result: the insertvalue chain of the return; its handle fields (the copy-outs, in
      // field order) are the outs.
      SmallVector<Value *, 4> fields(srt->getNumElements(), nullptr);
      unsigned nFields = srt->getNumElements();
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
      auto isAlloc = [](Value *x) {
        auto *ci = dyn_cast_or_null<CallInst>(x);
        std::optional<abi::CoreSpec> a =
            ci && ci->getCalledFunction() ? abi::parseCore(ci->getCalledFunction()->getName()) : std::nullopt;
        return a && a->op == abi::Core::Alloc;
      };
      for (unsigned k = 0; k < nFields; ++k) {
        // A handle field is a copy-out f, or a phi chosen classically of one copy-out per incoming edge
        // (Walker::returnCopyOut) followed by an appended field (cq-ew5z: a level's overflow predicate): each
        // copy targets the field's out, the phi goes with the chain.
        SmallSetVector<Value *, 2> results;
        auto *fp = dyn_cast_or_null<PHINode>(fields[k]);
        if (fp && fp->hasOneUse() && all_of(fp->incoming_values(), [&](Value *x) { return isAlloc(x); }))
          results.insert(fp->incoming_values().begin(), fp->incoming_values().end());
        else if (isAlloc(fields[k]))
          results.insert(fields[k]);
        else
          continue;   // a classical field
        if (j >= nOuts)
          internalError("calls: calls::finalize: a field-wise clone return with more handle fields than its twin's outs",
                        R);
        for (Value *rv : results)
          retarget(rv, twin.getArg(j), R);
        ++j;
        if (results.front() != fields[k])
          fieldPhis.push_back(fp);
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
    for (PHINode *fp : fieldPhis)
      fp->eraseFromParent();
  }
  for (Instruction *f : dead)
    if (f->use_empty())
      f->eraseFromParent();
    else
      internalError("calls: calls::finalize: a clone's result rail still used after its twin rewrite", f);

  // Rule 14's kept overflow predicate a_K = alloc_i1(0); and_i1(a_n, test, a_K), never freed, read by
  // nothing: the forward keeps it (one per activation); the twin, which only uncomputes the forward's
  // outs, does not compute it (169: "__cq_q_ilogb_1_unc itself keeps nothing"). Its test is the twin's
  // garbage as in the forward, uncomputed there. A recursion's overflow predicate kept by its first outside
  // caller (cq-ew5z: alloc_i1(0); and_i1(p, ovf, k), or copy_i1(ovf, k) with no predicate) is the same.
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
    else if (g && g->getCalledFunction() && g->getCalledFunction()->getName() == "cqrt_copy_i1" &&
             g->arg_size() == 2 && g->getArgOperand(1) == a && g->getArgOperand(0) != a)
      keptK.push_back(a);
  }
  for (CallInst *a : keptK) {
    cast<Instruction>(a->user_back())->eraseFromParent();
    a->eraseFromParent();
  }

  // cq-il07 (rules 19, 23): a replay that raises into the host flags (see checkReplayable) runs between
  // h = fetestexcept(FE_ALL_EXCEPT) on entry and feclearexcept(FE_ALL_EXCEPT); feraiseexcept(h) before
  // each return, eff-fenv's BRACKET around the whole twin: the twin changes no host flag.
  if (hostFlags) {
    Type *i32 = Type::getInt32Ty(C);
    FunctionType *fty = FunctionType::get(i32, {i32}, false);
    FunctionCallee test = M.getOrInsertFunction("fetestexcept", fty), clear = M.getOrInsertFunction("feclearexcept", fty),
                   raise = M.getOrInsertFunction("feraiseexcept", fty);
    Constant *all = ConstantInt::get(i32, 63);   // FE_ALL_EXCEPT on x86-64 (eff-fenv kAllExcept)
    BasicBlock::iterator at = twin.getEntryBlock().getFirstInsertionPt();
    while (isa<AllocaInst>(*at))
      ++at;
    IRBuilder<> EB(&*at);
    Value *h = EB.CreateCall(test, {all}, "cq.hostflags");
    for (BasicBlock &BB : twin)
      if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator())) {
        IRBuilder<> RB(R);
        RB.CreateCall(clear, {all});
        RB.CreateCall(raise, {h});
      }
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







} // namespace

void finalize(Module &M) {
  SmallVector<Function *, 8> clones;
  for (Function &F : M) {
    if (!isClone(F))
      continue;
    std::optional<abi::CloneSpec> spec = abi::parseClone(F.getName());
    if (!spec)
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
