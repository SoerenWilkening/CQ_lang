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
// Set only while childContext constructs a context that adopts its parent's state.
thread_local std::shared_ptr<spine::Shared> tlsAdopt;
// The frozen header gives free functions no access to Impl; every constructor registers its state
// here (an address reused by a later context is overwritten by that context's constructor).
thread_local DenseMap<const LoweringContext *, std::weak_ptr<spine::Shared>> registry;

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}
} // namespace

namespace spine {

DominatorTree &Shared::dt(const Function &F) {
  auto &p = dts[&F];
  if (!p)
    p = std::make_unique<DominatorTree>(const_cast<Function &>(F));
  return *p;
}

bool Shared::dominatesCurrent(const Instruction *def) {
  if (!cur)
    return false;
  // Walk out through inlined call sites until def and the point are in one function.
  const Instruction *at = cur;
  size_t i = inlineStack.size();
  while (at->getFunction() != def->getFunction()) {
    if (i == 0)
      return false;
    at = inlineStack[--i];
  }
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

std::unique_ptr<LoweringContext> childContext(LoweringContext &parent, const Specialization &S) {
  auto it = registry.find(&parent);
  if (it == registry.end() || it->second.expired())
    internalError("spine: childContext of an unregistered context");
  tlsAdopt = it->second.lock();
  auto child = std::make_unique<LoweringContext>(parent.M, parent.T, S, tlsAdopt->KO);
  tlsAdopt.reset();
  return child;
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
  if (tlsAdopt) {
    impl->sh = tlsAdopt;
  } else {
    impl->sh = std::make_shared<spine::Shared>(M, KO);
    impl->sh->unc = std::make_unique<Uncompute>();
    impl->sh->preds = std::make_unique<PathPredicates>();
  }
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
  Operand op = it->second.front();
  if (op.handle) {
    // Rule 2: a use dominated by a measurement of this rail reads the classical outcome.
    auto m = sh.measured.find(op.v);
    if (m != sh.measured.end() && sh.dominatesCurrent(m->second.first))
      return Operand{m->second.second, false};
  }
  return op;
}

Value *LoweringContext::rail(const Value *orig) {
  Operand op = operand(orig);
  if (!op.handle)
    internalError("spine: rail() of a classical value " + describe(orig), orig);
  return op.v;
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

BasicBlock *LoweringContext::block(const BasicBlock *orig) {
  auto it = impl->sh->blocks.find(orig);
  if (it == impl->sh->blocks.end())
    internalError("spine: block() of an original block with no output block");
  return it->second;
}

Value *LoweringContext::emitTemplate(const abi::TemplateSpec &spec, ArrayRef<Operand> ops, const Value *orig) {
  FunctionCallee fc = abi::declare(M, spec, /*unc=*/false);
  FunctionType *ft = fc.getFunctionType();
  if (ft->getNumParams() != ops.size())
    internalError("spine: " + abi::name(spec, false) + " takes " + std::to_string(ft->getNumParams()) +
                      " arguments, got " + std::to_string(ops.size()),
                  orig);
  SmallVector<Value *, 4> args;
  for (unsigned i = 0; i < ops.size(); ++i) {
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
  if (orig)
    spine::bindOperand(*this, orig, Operand{call, true});
  return call;
}

CallInst *LoweringContext::emitCore(const abi::CoreSpec &spec, ArrayRef<Value *> args) {
  FunctionCallee fc = abi::declare(M, spec);
  FunctionType *ft = fc.getFunctionType();
  if (ft->getNumParams() != args.size())
    internalError("spine: " + abi::name(spec) + " takes " + std::to_string(ft->getNumParams()) +
                  " arguments, got " + std::to_string(args.size()));
  for (unsigned i = 0; i < args.size(); ++i)
    if (args[i]->getType() != ft->getParamType(i))
      internalError("spine: " + abi::name(spec) + " argument " + std::to_string(i) + " has the wrong type", args[i]);
  CallInst *call = B().CreateCall(fc, args);
  for (size_t t = 0; t < impl->sh->gateLogs.size(); ++t)
    if (impl->sh->gateLogOpen[t])
      impl->sh->gateLogs[t].push_back(call);
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
  if (p.isTop())
    return nullptr;
  return preds().flag(*this, p);
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

} // namespace cq
