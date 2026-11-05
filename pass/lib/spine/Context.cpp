// Module spine (cq-w0-construct): LoweringContext (Lowering.h). The contract is in SpineInternal.h.
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq {

struct LoweringContext::Impl {
  std::shared_ptr<spine::Shared> sh;
};

namespace {
// The frozen header gives free functions no access to Impl; every constructor registers its state
// here (an address reused by a later context is overwritten by that context's constructor).
thread_local DenseMap<const LoweringContext *, std::weak_ptr<spine::Shared>> registry;

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

// cq-ylrk: a runtime call's literal undef or poison argument (or such an element of a constant vector
// or aggregate) is pinned to 0, a refinement LLVM itself may make. Uncompute spells a _unc from its
// forward call's arguments, and two uses of one undef may differ (each use of undef is free), so a
// select template on an undef arm and its _unc would read different values: the rail freed dirty.
Constant *pinUndef(Constant *C) {
  if (isa<UndefValue>(C))
    return Constant::getNullValue(C->getType());
  if (!isa<ConstantAggregate>(C))
    return C;
  SmallVector<Constant *, 8> elts;
  bool changed = false;
  for (unsigned i = 0; i < C->getNumOperands(); ++i) {
    Constant *e = cast<Constant>(C->getOperand(i)), *pe = pinUndef(e);
    changed |= pe != e;
    elts.push_back(pe);
  }
  if (!changed)
    return C;
  if (auto *VT = dyn_cast<VectorType>(C->getType()); VT && isa<ConstantVector>(C))
    return ConstantVector::get(elts);
  if (auto *ST = dyn_cast<StructType>(C->getType()))
    return ConstantStruct::get(ST, elts);
  return ConstantArray::get(cast<ArrayType>(C->getType()), elts);
}

Value *pinned(Value *v) {
  auto *C = dyn_cast<Constant>(v);
  return C && !isa<GlobalValue>(C) ? pinUndef(C) : v;
}

// cq-8un4: the loop units running now, innermost last, per spine state (a child context shares its
// parent's). Pushed and popped by the walker around its loops:: call (pushLoopUnit / popLoopUnit).
thread_local DenseMap<const spine::Shared *, std::vector<const Loop *>> loopUnits;
} // namespace

namespace spine {

void pushLoopUnit(LoweringContext &ctx, const Loop &L) { loopUnits[&shared(ctx)].push_back(&L); }

void popLoopUnit(LoweringContext &ctx, const Loop &L) {
  auto it = loopUnits.find(&shared(ctx));
  if (it == loopUnits.end() || it->second.empty() || it->second.back() != &L)
    internalError("spine: popLoopUnit of a loop unit that is not the innermost running one");
  it->second.pop_back();
}

DominatorTree &Shared::dt(const Function &F) {
  auto &p = dts[&F];
  if (!p)
    p = std::make_unique<DominatorTree>(const_cast<Function &>(F));
  return *p;
}

bool Shared::dominatesCurrent(const Instruction *def) {
  if (!cur)
    return false;
  const Instruction *at = cur;
  if (at->getFunction() != def->getFunction())
    return false;
  if (at == def)
    return false;
  return dt(*def->getFunction()).dominates(def, at);
}

Shared &shared(LoweringContext &ctx) {
  auto it = registry.find(&ctx);
  std::shared_ptr<Shared> sh = it == registry.end() ? nullptr : it->second.lock();
  if (!sh)
    internalError("spine: a LoweringContext with no registered state");
  return *sh;
}

// Rule 3: a pointer is an integer of pointer width: where the ABI takes an i64 (a seed, a literal operand), a
// classical pointer of the new IR is read as ptrtoint.
Value *codeAddressAsInt(IRBuilder<> &B, Value *v, Type *want) {
  if (!v->getType()->isPointerTy() || !want->isIntegerTy(64))
    return v;
  if (auto *c = dyn_cast<Constant>(v))
    return ConstantExpr::getPtrToInt(c, want);
  return B.CreatePtrToInt(v, want);
}

bool isQ(LoweringContext &ctx, const Value *v) {
  if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<InlineAsm>(v))
    return false;
  return ctx.T.isQuantum(v, ctx.S);
}

bool anyQuantumOperand(LoweringContext &ctx, const Instruction &I) {
  for (const Use &u : I.operands())
    if (isQ(ctx, u.get()))
      return true;
  return false;
}

void bindOperand(LoweringContext &ctx, const Value *orig, Operand op) {
  Shared &sh = shared(ctx);
  auto &slot = sh.binds[orig];
  if (!slot.empty())
    internalError("spine: " + describe(orig) + " bound twice", orig);
  slot.push_back(op);
}

} // namespace spine

LoweringContext::LoweringContext(Module &M, const TaintInfo &T, const Specialization &S,
                                 const loops::KOptions &KO)
    : M(M), T(T), S(S), impl(std::make_shared<Impl>()) {
  impl->sh = std::make_shared<spine::Shared>(M, KO);
  impl->sh->unc = std::make_unique<Uncompute>();
  impl->sh->preds = std::make_unique<PathPredicates>();
  registry[this] = impl->sh;
}

Function &LoweringContext::out() {
  if (!impl->sh->out)
    internalError("spine: out() before the output function exists");
  return *impl->sh->out;
}

IRBuilder<> &LoweringContext::B() { return impl->sh->B; }

Operand LoweringContext::operand(const Value *orig) {
  if (!orig)
    internalError("spine: operand(nullptr)");
  if (auto *C = dyn_cast<Constant>(orig))
    return Operand{const_cast<Constant *>(C), false};
  spine::Shared &sh = *impl->sh;
  auto it = sh.binds.find(orig);
  if (it == sh.binds.end()) {
    if (isa<Argument>(orig) || isa<Instruction>(orig))
      internalError("spine: " + describe(orig) + " has no value in the new IR (not lowered yet)", orig);
    if (isa<InlineAsm>(orig))
      return Operand{const_cast<Value *>(orig), false};
    internalError("spine: operand of an unexpected kind", orig);
  }
  if (it->second.size() != 1)
    internalError("spine: operand() of a value with " + std::to_string(it->second.size()) +
                      " fields (use fields())",
                  orig);
  Operand op = spine::atPhiEdge(sh, orig, it->second.front());
  if (op.handle) {
    // Rule 2: a use after a measurement of this rail reads the classical outcome, and a rail that
    // depends only on measured rails and classical values collapses to its classical recomputation.
    if (Value *c = spine::collapse(*this, op.v))
      return Operand{c, false};
  }
  return op;
}

// rail() asks for the rail itself (a flag atom, a control, an in-place target): no classical
// collapse of a derived rail. The rail of a measured value read after its measurement is still the
// outcome (rule 2), so rail() of it is an error as before.
Value *LoweringContext::rail(const Value *orig) {
  if (!orig)
    internalError("spine: rail(nullptr)");
  spine::Shared &sh = *impl->sh;
  auto it = sh.binds.find(orig);
  if (isa<Constant>(orig) || it == sh.binds.end() || it->second.size() != 1 || !it->second.front().handle ||
      spine::outcomeAt(sh, it->second.front().v)) {
    Operand op = operand(orig);
    if (!op.handle)
      internalError("spine: rail() of a classical value " + describe(orig), orig);
    return op.v;
  }
  return spine::atPhiEdge(sh, orig, it->second.front()).v;
}

Value *LoweringContext::switchRail(const Value *scrutinee) {
  auto it = impl->sh->switchSnap.find(scrutinee);
  return it != impl->sh->switchSnap.end() ? it->second : rail(scrutinee);
}

SmallVector<Operand, 4> LoweringContext::fields(const Value *orig) {
  spine::Shared &sh = *impl->sh;
  auto it = sh.binds.find(orig);
  if (it == sh.binds.end()) {
    if (isa<Constant>(orig))
      return {Operand{const_cast<Value *>(orig), false}};
    internalError("spine: fields() of " + describe(orig) + ": not lowered yet", orig);
  }
  return it->second;
}

void LoweringContext::bind(const Value *orig, Value *v) {
  spine::bindOperand(*this, orig, Operand{v, spine::isQ(*this, orig)});
}

void LoweringContext::bindFields(const Value *orig, ArrayRef<Operand> ops) {
  auto &slot = impl->sh->binds[orig];
  if (!slot.empty())
    internalError("spine: " + describe(orig) + " bound twice", orig);
  slot.append(ops.begin(), ops.end());
}

void LoweringContext::addJoinArm(const PHINode *P, const Pred &edge, const Value *v) {
  impl->sh->joinArms[P].push_back({edge, v});
}

std::vector<std::pair<Pred, const Value *>> LoweringContext::takeJoinArms(const PHINode *P) {
  std::vector<std::pair<Pred, const Value *>> r;
  if (auto it = impl->sh->joinArms.find(P); it != impl->sh->joinArms.end()) {
    r = std::move(it->second);
    impl->sh->joinArms.erase(it);
  }
  return r;
}

bool LoweringContext::bound(const Value *orig) const {
  if (isa<Constant>(orig))
    return true;
  auto it = impl->sh->binds.find(orig);
  return it != impl->sh->binds.end() && !it->second.empty();
}

void LoweringContext::rebind(const Value *orig, ArrayRef<Operand> ops) {
  if (!orig)
    internalError("spine: rebind(nullptr)");
  if (ops.empty())
    internalError("spine: rebind of " + describe(orig) + " to no fields", orig);
  auto it = impl->sh->binds.find(orig);
  if (it == impl->sh->binds.end() || it->second.empty())
    internalError("spine: rebind of " + describe(orig) + ", which is not bound", orig);
  it->second.assign(ops.begin(), ops.end());
}

BasicBlock *LoweringContext::block(const BasicBlock *orig) {
  auto it = impl->sh->blocks.find(orig);
  if (it == impl->sh->blocks.end())
    internalError("spine: block() of an original block with no output block");
  return it->second;
}

Value *LoweringContext::emitTemplate(const abi::TemplateSpec &spec, ArrayRef<Operand> opsIn, const Value *orig) {
  SmallVector<Operand, 4> ops(opsIn.begin(), opsIn.end());
  for (Operand &o : ops)
    if (!o.handle)
      o.v = pinned(o.v);   // cq-ylrk
  FunctionCallee fc = abi::declare(M, spec, /*unc=*/false);
  FunctionType *ft = fc.getFunctionType();
  if (ft->getNumParams() != ops.size())
    internalError("spine: " + abi::name(spec, false) + " takes " + std::to_string(ft->getNumParams()) +
                      " arguments, got " + std::to_string(ops.size()),
                  orig);
  SmallVector<Value *, 4> args;
  for (unsigned i = 0; i < ops.size(); ++i) {
    if (!ops[i].handle)
      ops[i].v = spine::codeAddressAsInt(B(), ops[i].v, ft->getParamType(i));
    if (ops[i].v->getType() != ft->getParamType(i))
      internalError("spine: " + abi::name(spec, false) + " argument " + std::to_string(i) + " has the wrong type",
                    ops[i].v);
    args.push_back(ops[i].v);
  }
  CallInst *call = B().CreateCall(fc, args);
  for (size_t t = 0; t < impl->sh->gateLogs.size(); ++t)
    if (impl->sh->gateLogOpen[t])
      impl->sh->gateLogs[t].push_back(call);
  unc().recordTemplate(call, spec, ops);
  spine::noteTemplate(*impl->sh, call, spec, ops, orig);
  if (orig)
    spine::bindOperand(*this, orig, Operand{call, true});
  return call;
}

CallInst *LoweringContext::emitCore(const abi::CoreSpec &spec, ArrayRef<Value *> argsIn) {
  SmallVector<Value *, 4> args;
  for (Value *a : argsIn)
    args.push_back(pinned(a));   // cq-ylrk
  FunctionCallee fc = abi::declare(M, spec);
  FunctionType *ft = fc.getFunctionType();
  if (ft->getNumParams() != args.size())
    internalError("spine: " + abi::name(spec) + " takes " + std::to_string(ft->getNumParams()) +
                  " arguments, got " + std::to_string(args.size()));
  for (unsigned i = 0; i < args.size(); ++i) {
    args[i] = spine::codeAddressAsInt(B(), args[i], ft->getParamType(i));
    if (args[i]->getType() != ft->getParamType(i))
      internalError("spine: " + abi::name(spec) + " argument " + std::to_string(i) + " has the wrong type", args[i]);
  }
  CallInst *call = B().CreateCall(fc, args);
  for (size_t t = 0; t < impl->sh->gateLogs.size(); ++t)
    if (impl->sh->gateLogOpen[t])
      impl->sh->gateLogs[t].push_back(call);
  spine::noteCore(*impl->sh, call, spec, args);
  return call;
}

PathPredicates &LoweringContext::preds() { return *impl->sh->preds; }
Uncompute &LoweringContext::unc() { return *impl->sh->unc; }

const Pred &LoweringContext::currentPredicate() const {
  if (!impl->sh->curPred)
    internalError("spine: currentPredicate() outside a block walk");
  return *impl->sh->curPred;
}

Value *LoweringContext::currentFlag() {
  const Pred &p = currentPredicate();
  spine::Shared &sh = *impl->sh;
  if (!sh.tripFlag) {
    if (p.isTop())
      return nullptr;
    return preds().flag(*this, p);
  }
  // cq-99f7: under a rule-14 trip the control is the trip rail, conjoined with the block's quantum
  // part when there is one (a fresh i1 rail, recorded, torn down by Uncompute like any pred flag).
  if (p.isTop())
    return sh.tripFlag;
  if (sh.tripConj)
    return sh.tripConj;
  Value *f = preds().flag(*this, p);
  if (!f)
    internalError("spine: the flag of a non-top predicate under a trip is constant true");
  RailType i1{Kind::Int, 1};
  CallInst *c = emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(M.getContext())});
  RailId cid = unc().recordSeed(c);
  abi::CoreSpec andSpec{abi::Core::AndI1, i1};
  CallInst *g = emitCore(andSpec, {sh.tripFlag, f, c});
  unc().recordCore(g, andSpec, {Operand{sh.tripFlag, true}, Operand{f, true}, Operand{c, true}}, cid);
  sh.tripConj = c;
  return c;
}

const Loop *LoweringContext::loopUnit() const {
  auto it = loopUnits.find(impl->sh.get());
  return it == loopUnits.end() || it->second.empty() ? nullptr : it->second.back();
}

unsigned LoweringContext::beginGateLog() {
  impl->sh->gateLogs.emplace_back();
  impl->sh->gateLogOpen.push_back(true);
  return impl->sh->gateLogs.size() - 1;
}

std::vector<CallInst *> LoweringContext::endGateLog(unsigned token) {
  spine::Shared &sh = *impl->sh;
  if (token >= sh.gateLogs.size() || !sh.gateLogOpen[token])
    internalError("spine: endGateLog of a log that is not open");
  sh.gateLogOpen[token] = false;
  return std::move(sh.gateLogs[token]);
}



unsigned LoweringContext::K(const llvm::Loop *L) const {
  if (!L)
    internalError("spine: K() of no loop");
  return loops::resolveK(*L->getHeader()->getParent(), impl->sh->KO);
}

// The same resolution as K(const Loop *) (CLAUDE.md "K per loop": per-function flag, CQ_K, global flag,
// default 4), for a function that may have no body: a rule 27 declared clone's trailing K is the callee's.
unsigned LoweringContext::K(const llvm::Function &F) const {
  return loops::resolveK(F, impl->sh->KO);
}

} // namespace cq
