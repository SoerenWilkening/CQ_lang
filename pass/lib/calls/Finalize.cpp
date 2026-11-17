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
//   Live.       An externally visible original (cq-ntvv, CR §1.4: only an internal function is
//               dropped), an original with a use anywhere but inside an original's body (a call or any other
//               use: classical call sites, address-taken function pointers, global initializers,
//               @llvm.used) is live, and so is every original a live original's body uses. The
//               rest have no classical caller left: every call was retargeted to a clone, or comes
//               from another dropped original (mutual recursion, call chains: 33, 119).
//   Dropped.    Every original that is not live. What a dropped body alone referenced and that now
//               has no use is dropped with it when it carries no symbol of its own: declarations
//               and local-linkage functions and variables.
//
// Shapes not lowered here (cq::unimplemented): a "__cq_q_" symbol that is not a canonical clone
// name (a uniquified clone, CR §1.4 ruling 2026-10-27: the clone table belongs to materialize, which
// finalize cannot see through Calls.h). An original whose body was rewritten in place (it calls an ABI
// symbol) is the lowered entry and stays live (cq-i9wk).
#include "cq/Abi.h"
#include "cq/Calls.h"
#include "CallsInternal.h"
#include "LibCalls.h"
#include "cq/Common.h"
#include "../spine/SpineInternal.h"
#include "../loops/cutoff/Exits.h"

#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

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
// it was made from (the clone names are built from the fields), so that reading is the clone's fn.
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

// A classical value computed from a measurement's outcome in this function (rule 2's collapsed value).
bool fromMeasurement(Value *v) {
  SmallPtrSet<Value *, 8> seen;
  SmallVector<Value *, 8> work{v};
  while (!work.empty()) {
    auto *I = dyn_cast<Instruction>(work.pop_back_val());
    if (!I || !seen.insert(I).second)
      continue;
    if (auto *CB = dyn_cast<CallBase>(I)) {
      const Function *G = CB->getCalledFunction();
      std::optional<abi::CoreSpec> c = G ? abi::parseCore(G->getName()) : std::nullopt;
      if (c && c->op == abi::Core::Measure)
        return true;
      continue;
    }
    work.append(I->op_begin(), I->op_end());
  }
  return false;
}


// The host <fenv.h> flag calls of eff-fenv's BRACKET and PROBE (hostFn: i32 name(i32), no body in the module):
// they read or write the host flags only, a body the bundle has for one included (rule 16, cq-rrc52).
bool hostFlagCall(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  return G && hostCallee(*G) && (G->getName() == "fetestexcept" || G->getName() == "feclearexcept" || G->getName() == "feraiseexcept") &&
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
    if (!G || hostCallee(*G))
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

// The width of field k of a clone's result: its copy-out's alloc (a phi of them on classical paths).
std::optional<abi::CoreSpec> resultAlloc(Function &g, unsigned k) {
  auto allocOf = [](Value *v) -> std::optional<abi::CoreSpec> {
    if (auto *p = dyn_cast<PHINode>(v))
      v = p->getIncomingValue(0);
    auto *c = dyn_cast<CallInst>(v);
    std::optional<abi::CoreSpec> a = c && c->getCalledFunction() ? abi::parseCore(c->getCalledFunction()->getName()) : std::nullopt;
    return a && a->op == abi::Core::Alloc ? a : std::nullopt;
  };
  for (BasicBlock &BB : g)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator())) {
      for (Value *v = R->getReturnValue(); auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
        if (iv->getIndices()[0] == k)
          return allocOf(iv->getInsertedValueOperand());
    }
  return std::nullopt;
}

// Rule 19: in a twin, the call of a callee that rotates. Its own symbol's rail is one of the registers handed over. A by-name
// clone is not called again: its twin XORs its results into fresh |0> rails from the registers it minted, which is the
// recompute with no rotation repeated; the twin's zeroing of them, replayed from the forward, follows as there.
void replayRegisterCall(Module &M, CallInst &c, ArrayRef<Value *> handed) {
  MDNode *md = c.getMetadata("cq.mint.call");
  unsigned base = unsigned(mdconst::extract<ConstantInt>(md->getOperand(0))->getZExtValue());
  bool own = !mdconst::extract<ConstantInt>(md->getOperand(1))->isZero();
  Function &g = *c.getCalledFunction();
  IRBuilder<> B(&c);
  LLVMContext &C = M.getContext();
  Type *i32 = Type::getInt32Ty(C);
  if (own) {
    Value *h = handed[base];
    c.replaceAllUsesWith(c.getType() == i32 ? h : B.CreateZExt(h, c.getType()));
    c.eraseFromParent();
    return;
  }
  unsigned n = mintCount(g);
  auto *st = cast<StructType>(c.getType());
  unsigned nFields = st->getNumElements() - n;
  std::optional<abi::CloneSpec> spec = abi::parseClone(g.getName());
  unsigned first = spec->ctl ? 1 : 0;
  SmallVector<Value *, 4> outs(nFields, nullptr);
  SmallVector<Value *, 8> args;
  SmallVector<Type *, 8> ps;
  for (unsigned i = 0; i < first; ++i)
    args.push_back(c.getArgOperand(i));
  for (unsigned k = 0; k < nFields; ++k) {
    std::optional<abi::CoreSpec> a = resultAlloc(g, k);
    if (!a) {
      noteUnbuilt("calls: a twin's recompute through a callee that rotates, a result that is no copy-out", &c);
      return;
    }
    outs[k] = B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, a->w}), {Constant::getNullValue(irTypeOf(C, a->w))});
    args.push_back(outs[k]);
  }
  for (unsigned j = 0; j < n; ++j)
    args.push_back(handed[base + j]);
  for (unsigned i = first; i < c.arg_size(); ++i)
    args.push_back(c.getArgOperand(i));
  for (Value *v : args)
    ps.push_back(v->getType());
  std::string name = (g.getName() + "_unc").str();
  Function *tw = M.getFunction(name);
  if (!tw)
    tw = Function::Create(FunctionType::get(Type::getVoidTy(C), ps, false), GlobalValue::InternalLinkage, name, &M);
  // §1.4: the twin is defined with its forward's calling convention (defineTwin), and its calls carry it (cq-5yuk9).
  B.CreateCall(tw, args)->setCallingConv(g.getCallingConv());
  SmallVector<ExtractValueInst *, 4> exts;
  for (User *U : c.users())
    exts.push_back(cast<ExtractValueInst>(U));
  for (ExtractValueInst *e : exts) {
    unsigned k = e->getIndices()[0];
    e->replaceAllUsesWith(k < nFields ? outs[k] : handed[base + k - nFields]);
    e->eraseFromParent();
  }
  c.eraseFromParent();
}

// Rule 19, on a clone just lowered, before its twin is made: what the forward hands over at a return. A register's handle where
// the register was made on one path only is 0 on the others (§1.1); a register rule 6 freed from its image is no more.
void settleRegisters(Function &F, unsigned mints) {
  LLVMContext &C = F.getContext();
  Constant *zero = ConstantInt::get(Type::getInt32Ty(C), 0);
  DominatorTree DT(F);
  auto settle = [&](Instruction *at, Use &u) {
    auto *h = dyn_cast<Instruction>(u.get());
    if (!h)
      return;
    if (any_of(h->users(), [](User *U) {
          auto *c = dyn_cast<CallInst>(U);
          return c && c->getCalledFunction() && c->getCalledFunction()->getName() == "cqrt_free";
        })) {
      u.set(zero);
      return;
    }
    if (DT.dominates(h, at))
      return;
    SSAUpdater SU;
    SU.Initialize(h->getType(), "cq.reg");
    SU.AddAvailableValue(&F.getEntryBlock(), zero);
    SU.AddAvailableValue(h->getParent(), h);
    u.set(SU.GetValueInMiddleOfBlock(at->getParent()));
  };
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      if (I.getMetadata("cq.mint.push"))
        settle(&I, cast<CallInst>(I).getArgOperandUse(0));
      auto *R = dyn_cast<ReturnInst>(&I);
      if (!R || !mints || !R->getReturnValue() || !R->getReturnValue()->getType()->isStructTy())
        continue;
      unsigned n = cast<StructType>(R->getReturnValue()->getType())->getNumElements();
      for (Value *v = R->getReturnValue(); auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
        if (iv->getIndices()[0] >= n - mints)
          settle(iv, iv->getOperandUse(InsertValueInst::getInsertedValueOperandIndex()));
    }
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
  // CR §1.4: a _ctl clone's twin is _ctl_unc(pred, outs..., args...). Rule 19: the handles of the registers the clone
  // returned after its results come after the outs and before the arguments (Uncompute's recordCall extra); a table twin pops them.
  std::optional<abi::CloneSpec> tspec = abi::parseClone(twin.getName());
  bool table = tspec && tspec->table;
  unsigned mints = mintCount(src);
  unsigned nOuts = twin.arg_size() - src.arg_size() - (table ? 0 : mints);
  unsigned first = tspec && tspec->ctl ? 1 : 0;   // the first out
  unsigned nExtra = table ? 0 : mints;
  auto twinFormal = [&](unsigned i) { return i < first ? twin.getArg(i) : twin.getArg(i + nOuts + nExtra); };
  bool handleRet = srt || (src.getReturnType() == h && nOuts == 1);
  if (!handleRet && nOuts != 0)
    internalError("calls: calls::finalize: twin @" + twin.getName().str() + " does not match the clone @" +
                      src.getName().str() + " (an i32 handle result or a struct of fields, its arguments after)",
                  &twin);
  for (unsigned i = 0; i < src.arg_size(); ++i)
    if (twinFormal(i)->getType() != src.getArg(i)->getType())
      internalError("calls: calls::finalize: twin @" + twin.getName().str() + " argument types differ from @" +
                        src.getName().str(),
                    &twin);
  SmallPtrSet<Function *, 8> seen;
  bool hostFlags = false;
  scanHostFlags(src, seen, hostFlags);

  ValueToValueMapTy VM;
  for (unsigned j = 0; j < nOuts; ++j)
    twin.getArg(first + j)->setName(nOuts == 1 ? "out" : "out" + std::to_string(j));
  for (unsigned i = 0; i < src.arg_size(); ++i) {
    VM[src.getArg(i)] = twinFormal(i);
    twinFormal(i)->setName(src.getArg(i)->getName());
  }
  SmallVector<ReturnInst *, 4> rets;
  CloneFunctionInto(&twin, &src, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
  twin.setAttributes(AttributeList());
  // §1.4: a twin is a clone: it keeps the original's calling convention and unnamed_addr; internal to its module.
  twin.setCallingConv(src.getCallingConv());
  twin.setLinkage(GlobalValue::InternalLinkage);

  SmallVector<Instruction *, 4> dead;
  // The copy-out of rule 18: f = cqrt_alloc_<W>(0), cqrt_copy_<W>(r, f), ..., ret f: the copy is made
  // to target `out` instead and f goes.
  // §1.4, rule 2, rulings3 E: a table twin leaves the seed of a measurement's outcome allocated and frees the results it
  // zeroes. freeResult frees `out` before R's replacement; where only some paths zeroed it, under a classical phi.
  auto outcomeSeed = [&](Value *rv) {
    auto *f = dyn_cast_or_null<CallInst>(rv);
    std::optional<abi::CoreSpec> a =
        f && f->getCalledFunction() ? abi::parseCore(f->getCalledFunction()->getName()) : std::nullopt;
    return table && a && a->op == abi::Core::Alloc && fromMeasurement(f->getArgOperand(0));
  };
  auto freeResult = [&](Argument *out, PHINode *phi, ReturnInst *ret) {
    FunctionCallee fr = abi::declare(M, abi::CoreSpec{abi::Core::Free});
    if (!phi || none_of(phi->incoming_values(), outcomeSeed)) {
      IRBuilder<>(ret).CreateCall(fr, {out});
      return;
    }
    if (all_of(phi->incoming_values(), outcomeSeed))
      return;
    PHINode *zeroed = PHINode::Create(Type::getInt1Ty(C), phi->getNumIncomingValues(), "", phi->getIterator());
    for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
      zeroed->addIncoming(ConstantInt::getBool(C, !outcomeSeed(phi->getIncomingValue(i))), phi->getIncomingBlock(i));
    IRBuilder<>(SplitBlockAndInsertIfThen(zeroed, ret, false)).CreateCall(fr, {out});
  };
  auto retarget = [&](Value *rv, Argument *out) {
    auto *f = dyn_cast_or_null<CallInst>(rv);
    std::optional<abi::CoreSpec> a =
        f && f->getCalledFunction() ? abi::parseCore(f->getCalledFunction()->getName()) : std::nullopt;
    auto *zero = f ? dyn_cast<Constant>(f->getArgOperand(0)) : nullptr;
    if (outcomeSeed(f)) {
      if (!is_contained(dead, f))
        dead.push_back(f);
      return;
    }
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
      copies.push_back(dyn_cast<CallInst>(U));
    }
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
    struct TableOut {
      Argument *out;
      PHINode *phi;
      Value *result;
    };
    SmallVector<TableOut, 2> tableOuts;
    if (srt) {
      // A field-wise result: the insertvalue chain of the return; its handle fields (the copy-outs, in
      // field order) are the outs.
      SmallVector<Value *, 4> fields(srt->getNumElements(), nullptr);
      unsigned nFields = srt->getNumElements() - (table ? 0 : mints);
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
          retarget(rv, twin.getArg(first + j));
        tableOuts.push_back({twin.getArg(first + j), results.front() != fields[k] ? fp : nullptr, results.front()});
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
        retarget(rv, twin.getArg(first));
      tableOuts.push_back({twin.getArg(first), rp, results.front()});
    }
    ReturnInst *newRet = ReturnInst::Create(C, nullptr, R->getIterator());
    R->eraseFromParent();
    if (table)
      for (const TableOut &o : tableOuts)
        if (o.phi || !outcomeSeed(o.result))
          freeResult(o.out, o.phi, newRet);
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

  // Rule 19: the rotations are not repeated: each register is the handle the forward handed over.
  {
    SmallVector<Value *, 2> handed(mints);
    IRBuilder<> PB(&twin.getEntryBlock(), twin.getEntryBlock().getFirstInsertionPt());
    for (unsigned k = 0; k < mints; ++k)
      handed[k] = table ? nullptr : twin.getArg(first + nOuts + k);
    if (table)
      for (unsigned k = mints; k-- > 0;)
        handed[k] = PB.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Pop}));
    SmallVector<CallInst *, 4> tagged, regCalls, drops;
    SmallVector<Instruction *, 2> pushes;
    for (Instruction &I : instructions(twin)) {
      if (I.getMetadata("cq.mint.push"))
        pushes.push_back(&I);
      if (I.getMetadata("cq.mint"))
        tagged.push_back(cast<CallInst>(&I));
      if (I.getMetadata("cq.mint.call"))
        regCalls.push_back(cast<CallInst>(&I));
      if (I.getMetadata("cq.mint.drop"))
        drops.push_back(cast<CallInst>(&I));
    }
    for (Instruction *I : pushes)
      I->eraseFromParent();
    for (CallInst *c : drops)
      c->eraseFromParent();   // no result: what it did stands, and nothing here reads it
    for (CallInst *c : regCalls)
      replayRegisterCall(M, *c, handed);
    SmallVector<PHINode *, 2> phis;
    for (CallInst *c : tagged)
      if (!c->getType()->isVoidTy())
        c->replaceAllUsesWith(handed[mdconst::extract<ConstantInt>(c->getMetadata("cq.mint")->getOperand(0))->getZExtValue()]);
    for (CallInst *c : tagged)
      c->eraseFromParent();
    // Rule 6 freed a register from its image in the forward: the twin does not do it again.
    for (Value *h : handed) {
      if (!h)
        continue;
      SmallVector<CallInst *, 2> writes;
      for (User *U : h->users()) {
        auto *c = dyn_cast<CallInst>(U);
        std::optional<abi::CoreSpec> cs = c && c->getCalledFunction() ? abi::parseCore(c->getCalledFunction()->getName()) : std::nullopt;
        if (cs && (cs->op == abi::Core::Free || (cs->op == abi::Core::Copy && !cs->ctl && c->getArgOperand(1) == h)))
          writes.push_back(c);
      }
      for (CallInst *c : writes)
        c->eraseFromParent();
    }
    // A merge of handed registers is the register; a result nobody reads now need not be made again.
    for (bool changed = true; changed;) {
      changed = false;
      SmallVector<Instruction *, 8> gone;
      for (Instruction &I : instructions(twin)) {
        auto *c = dyn_cast<CallInst>(&I);
        std::optional<abi::CloneSpec> cl = c && c->getCalledFunction() ? abi::parseClone(c->getCalledFunction()->getName()) : std::nullopt;
        if (I.use_empty() && (isa<PHINode, ExtractValueInst>(I) || (cl && !cl->unc && !I.getType()->isVoidTy())))
          gone.push_back(&I);
      }
      for (Instruction *I : gone) {
        I->eraseFromParent();
        changed = true;
      }
    }
  }

  // Rule 14's kept overflow predicate a_K = alloc_i1(0); and_i1(a_n, test, a_K), never freed, read by
  // nothing: the forward keeps it (one per activation); the twin, which only uncomputes the forward's
  // outs, does not compute it (169: "__cq_q_ilogb_1_unc itself keeps nothing"). Its test is the twin's
  // garbage as in the forward, uncomputed there. A recursion's overflow predicate kept by its first outside
  // caller (cq-ew5z: alloc_i1(0); and_i1(p, ovf, k), or copy_i1(ovf, k) with no predicate) is the same.
  // A K-loop's chain end merged at a classical exit of the chain (CR rule 14, Q10's tests; rule 27 "Cutoff", a received-K
  // cut, cq-wkzu9) is a phi of the arms' a_K that nothing reads: gone first, so that each arm's a_K is the form above.
  for (bool changed = true; changed;) {
    changed = false;
    SmallVector<PHINode *, 8> unread;
    for (Instruction &I : instructions(twin))
      if (auto *ph = dyn_cast<PHINode>(&I); ph && ph->use_empty() && ph->getType()->isIntegerTy(32))
        unread.push_back(ph);
    for (PHINode *ph : unread) {
      ph->eraseFromParent();
      changed = true;
    }
  }
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

// The table twins of the module that leave the results allocated, by symbol (defineTableClones).
std::set<std::string> keepsResults, popsMints;
// Rule 27, library build: the table clones and twins of the roots this module defines (exportRootClones).
std::vector<std::string> exportedClones;

// §1.4: a table twin. For a function rule 18 gives no twin it does nothing but count its activation and pop; otherwise it
// is rule 18's twin that frees the results it zeroes.
void defineTableTwin(Module &M, Function &twin, Function &fwd) {
  std::optional<abi::CloneSpec> ts = abi::parseClone(twin.getName());
  bool keeps = keepsResults.count(twin.getName().str()) != 0;
  LLVMContext &C = M.getContext();
  if (keeps) {
    IRBuilder<> B(BasicBlock::Create(C, "", &twin));
    if (ts->ctl) {
      Type *i32 = Type::getInt32Ty(C);
      GlobalVariable *act = activationCounter(M, ts->fn);
      Value *d = B.CreateLoad(i32, act);
      B.CreateStore(B.CreateAdd(d, ConstantInt::get(i32, 1)), act);
      Value *n = B.CreateLoad(i32, act);
      B.CreateStore(B.CreateAdd(n, ConstantInt::get(i32, -1, true)), act);
    }
    if (popsMints.count(twin.getName().str())) {
      // The count of registers the clone pushed, then the handles (§1.4, rulings3 F).
      Type *i32 = Type::getInt32Ty(C);
      FunctionCallee pop = abi::declare(M, abi::CoreSpec{abi::Core::Pop});
      BasicBlock *entry = B.GetInsertBlock(), *head = BasicBlock::Create(C, "", &twin), *body = BasicBlock::Create(C, "", &twin),
                 *done = BasicBlock::Create(C, "", &twin);
      Value *count = B.CreateCall(pop);
      B.CreateBr(head);
      B.SetInsertPoint(head);
      PHINode *n = B.CreatePHI(i32, 2);
      n->addIncoming(count, entry);
      B.CreateCondBr(B.CreateICmpEQ(n, ConstantInt::get(i32, 0)), done, body);
      B.SetInsertPoint(body);
      B.CreateCall(pop);
      n->addIncoming(B.CreateSub(n, ConstantInt::get(i32, 1)), body);
      B.CreateBr(head);
      B.SetInsertPoint(done);
    }
    B.CreateRetVoid();
    twin.setLinkage(GlobalValue::InternalLinkage);
    return;
  }
  defineTwin(M, twin, *twinSource(M, fwd));
  // Rule 2: what the twin replays of a measurement only to zero a rail it left alone goes: a re-read has no effect (211).
  for (bool changed = true; changed;) {
    changed = false;
    SmallVector<Instruction *, 8> gone;
    for (Instruction &I : instructions(twin)) {
      auto *CB = dyn_cast<CallBase>(&I);
      const Function *G = CB ? CB->getCalledFunction() : nullptr;
      std::optional<abi::CoreSpec> c = G ? abi::parseCore(G->getName()) : std::nullopt;
      if (I.use_empty() && ((c && c->op == abi::Core::Measure) || isInstructionTriviallyDead(&I)))
        gone.push_back(&I);
    }
    for (Instruction *I : gone) {
      I->eraseFromParent();
      changed = true;
    }
  }
}

// §1.3, rule 19: every table clone's twins declared and `internal void @__cq_register()` in llvm.global_ctors at 65535,
// one row per function: fn, its C function type as a string, _t, _t_ctl, _t_unc, _t_ctl_unc.
void defineTableClones(Module &M) {
  std::vector<TableRow> rows = takeTableRows(M);
  keepsResults.clear();
  popsMints.clear();
  exportedClones.clear();
  if (rows.empty())
    return;
  LLVMContext &C = M.getContext();
  Function *reg = Function::Create(FunctionType::get(Type::getVoidTy(C), false), GlobalValue::InternalLinkage, "__cq_register", &M);
  IRBuilder<> B(BasicBlock::Create(C, "", reg));
  FunctionCallee add = abi::declareHost(M, abi::Host::CloneRegister);
  auto twinOf = [&](Function *fwd, bool ctl) {
    std::string name = (fwd->getName() + "_unc").str();
    SmallVector<Type *, 8> ps;
    ArrayRef<Type *> params = fwd->getFunctionType()->params();
    if (ctl) {
      ps.push_back(params.front());
      params = params.drop_front();
    }
    Type *rt = fwd->getReturnType();
    if (auto *st = dyn_cast<StructType>(rt))
      ps.append(st->getNumElements(), Type::getInt32Ty(C));
    else if (!rt->isVoidTy())
      ps.push_back(Type::getInt32Ty(C));
    ps.append(params.begin(), params.end());
    return Function::Create(FunctionType::get(Type::getVoidTy(C), ps, false), GlobalValue::InternalLinkage, name, &M);
  };
  for (const TableRow &r : rows) {
    Function *fn = M.getFunction(r.fn), *t = M.getFunction(r.forward), *tc = M.getFunction(r.ctl);
    if (!fn || !t || !tc)
      internalError("calls: calls::finalize: a clone-table row without its function or table clones: @" + r.fn);
    Function *tu = twinOf(t, false), *tcu = twinOf(tc, true);
    if (r.forwardKeepsResults)
      keepsResults.insert(tu->getName().str());
    if (r.ctlKeepsResults)
      keepsResults.insert(tcu->getName().str());
    if (r.forwardPopsMints)
      popsMints.insert(tu->getName().str());
    if (r.ctlPopsMints)
      popsMints.insert(tcu->getName().str());
    Constant *key = fn;
    if (r.exported && r.hostOwn) {
      // The C function is the host library's: this body goes under a module-internal name (it stays for the calls
      // this module makes to it), and the row is keyed by the host's address, the one a program's &fn denotes.
      std::string name = fn->getName().str();
      fn->setName("__cq_own_" + name);
      fn->setLinkage(GlobalValue::InternalLinkage);
      Function *host = Function::Create(r.type, GlobalValue::ExternalLinkage, name, &M);
      // Uses that are not calls denote the function's address (llvm.compiler.used, a pointer table): the host's.
      SmallVector<Use *, 8> addr;
      for (Use &U : fn->uses())
        if (auto *CB = dyn_cast<CallBase>(U.getUser()); !CB || !CB->isCallee(&U))
          addr.push_back(&U);
      for (Use *U : addr) {
        if (auto *C2 = dyn_cast<Constant>(U->getUser()); C2 && !isa<GlobalValue>(C2))
          C2->handleOperandChange(fn, host);
        else
          U->set(host);
      }
      key = host;
      if (fn->use_empty())
        fn->eraseFromParent();   // no call of this module reaches the lowered body
    }
    B.CreateCall(add, {key, sigString(M, r.type), t, tc, tu, tcu});
    if (r.exported)
      for (Function *f : {t, tc, tu, tcu})
        exportedClones.push_back(f->getName().str());
  }
  B.CreateRetVoid();
  appendToGlobalCtors(M, reg, 65535);
}

// Rule 27, "Library build" (BACKEND_ABI §3): a root this module defines exports its table clone, the _ctl form and
// their twins, the four symbols a declared clone's caller names. Every other table clone stays module-internal, reached
// through its row. Runs after defineTwins: a twin is created internal and defined there.
void exportRootClones(Module &M) {
  for (const std::string &name : exportedClones) {
    Function *F = M.getFunction(name);
    if (!F || F->isDeclaration())
      internalError("calls: calls::finalize: a root's table clone without a body: @" + name);
    F->setLinkage(GlobalValue::ExternalLinkage);
    F->setDSOLocal(false);
  }
  exportedClones.clear();
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
      std::optional<abi::CloneSpec> ts = abi::parseClone(T->getName());
      if (!fwd && ts->mask.find('1') == std::string::npos && !ts->table) {
        // The all-zero mask's twin: the own symbol returns its rail as it stands, so the twin recomputes through the
        // _pure clone, the clone form.
        abi::CloneSpec p = *ts;
        p.unc = false;
        p.pure = true;
        fwd = M.getFunction(abi::name(p));
      }
      if (!fwd || fwd->isDeclaration())
        continue;   // rule 27: whatever is linked defines it
      if (ts->table)
        defineTableTwin(M, *T, *fwd);
      else
        defineTwin(M, *T, *twinSource(M, *fwd));
      changed = true;
    }
  }
}







// Owner ruling Q2 of 2026-11-14 (cq-9kcq; CR 1.4 "Received K", rule 27 "Cutoff"): in a module that defines a table clone,
// `@__cq_k = internal global i32 -1`; each table clone, its _ctl form and their twins (every defined clone whose §1.4
// reading is a table one) store their K actual (the trailing classical i32) on entry and store the value they found back
// at every return. A function a table clone reaches by name loads it (loops-cutoff). Plain loads and stores, like
// @__cq_act_<fn>: no bus access, no memory version change.
void storeReceivedK(Module &M) {
  SmallVector<Function *, 8> tables;
  for (Function &F : M)
    if (!F.isDeclaration() && isClone(F))
      if (std::optional<abi::CloneSpec> s = abi::parseClone(F.getName()); s && s->table)
        tables.push_back(&F);
  if (tables.empty())
    return;
  GlobalVariable *g = loops::exits::receivedKGlobal(M);
  Type *i32 = Type::getInt32Ty(M.getContext());
  for (Function *F : tables) {
    Argument *K = F->arg_empty() ? nullptr : F->getArg(F->arg_size() - 1);
    if (!K || K->getType() != i32) {
      noteUnbuilt("calls: calls::finalize: a table clone whose last parameter is no i32 K: @__cq_k not set", F);
      continue;
    }
    BasicBlock &E = F->getEntryBlock();
    BasicBlock::iterator at = E.getFirstInsertionPt();
    while (at != E.end() && isa<AllocaInst>(*at))
      ++at;
    IRBuilder<> EB(&E, at);
    Value *old = EB.CreateLoad(i32, g);
    EB.CreateStore(K, g);
    for (BasicBlock &BB : *F)
      if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
        IRBuilder<>(R).CreateStore(old, g);
  }
}

} // namespace

// §1.4: every function, parameter and return attribute that states a memory, capture, nullness, range or purity fact is
// dropped from the definition of every clone and lowered own symbol and from every call of one; `noundef` stays.
static void dropFacts(Function &F) {
  static const Attribute::AttrKind kinds[] = {
      Attribute::Memory,    Attribute::ReadNone,  Attribute::ReadOnly, Attribute::WriteOnly,  Attribute::NoCapture,
      Attribute::NonNull,   Attribute::Dereferenceable, Attribute::DereferenceableOrNull, Attribute::NoAlias,
      Attribute::NoFree,    Attribute::NoSync,    Attribute::WillReturn, Attribute::Speculatable, Attribute::Range,
      Attribute::Writable,  Attribute::DeadOnUnwind, Attribute::Initializes, Attribute::NoRecurse, Attribute::MustProgress};
  for (Attribute::AttrKind k : kinds) {
    F.removeFnAttr(k);
    F.removeRetAttr(k);
    for (unsigned p = 0; p < F.arg_size(); ++p)
      F.removeParamAttr(p, k);
  }
  for (User *U : F.users())
    if (auto *CB = dyn_cast<CallBase>(U); CB && CB->getCalledOperand() == &F)
      for (Attribute::AttrKind k : kinds) {
        CB->removeFnAttr(k);
        CB->removeRetAttr(k);
        for (unsigned p = 0; p < CB->arg_size(); ++p)
          CB->removeParamAttr(p, k);
      }
}

void finalize(Module &M) {
  restoreHostPatterns(M);
  auto lowered = [](Function &F) {
    for (Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *callee = CB->getCalledFunction();
            callee && (isAbiSymbol(callee->getName()) || callee->getName().starts_with("__cq_")))
          return true;
    return false;
  };
  for (Function &F : M)
    if (!F.isDeclaration() && (isClone(F) || lowered(F)))
      dropFacts(F);
  SmallVector<Function *, 8> clones;
  for (Function &F : M) {
    if (!isClone(F))
      continue;
    clones.push_back(&F);
  }
  if (clones.empty())
    return;
  for (Function *F : clones)
    if (!F->isDeclaration() && mintCount(*F))
      settleRegisters(*F, std::optional<abi::CloneSpec>(abi::parseClone(F->getName()))->table ? 0 : mintCount(*F));
  defineTableClones(M);
  defineTwins(M);
  exportRootClones(M);
  storeReceivedK(M);
  for (Function &F : M)
    for (Instruction &I : instructions(F)) {
      I.setMetadata("cq.mint", nullptr);
      I.setMetadata("cq.mint.push", nullptr);
      I.setMetadata("cq.mint.call", nullptr);
      I.setMetadata("cq.mint.drop", nullptr);
    }

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
  // cq-ntvv (CR §1.4: "An internal function with no remaining use is dropped"): only an internal one. An externally
  // visible original is the program's exported symbol whatever its in-module callers became.
  for (Function *O : originals)
    if (!O->hasLocalLinkage() && live.insert(O).second)
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
