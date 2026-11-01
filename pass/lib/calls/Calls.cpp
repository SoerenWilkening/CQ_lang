// Module calls (cq-w1-calls): function lifting (rule 18), indirect callees (rule 19) and declared
// clones (rule 27). calls::classify is the spine's; calls::finalize (Finalize.cpp) drops dead
// originals and defines the twins the lowering called.
//
// CONTRACT (Calls.h is frozen, so what its callers may rely on is stated here)
//
//  - materialize(M, S) returns the clone of S: an internal function named by CR §1.4 (abi::name of
//    S's fields), created on the first request and returned again on every later one (the module's
//    symbol table is the clone table: a name is accepted only when abi::parseClone reads it back to
//    exactly S's fields, so two distinct clones can never share it; a name that does not read back
//    is a uniquified clone, unimplemented as in finalize). Signature: the _ctl flag first (an i32
//    handle), then one parameter per formal, an i32 handle where S's mask digit is 1, the formal's C
//    type where it is 0; the result is an i32 handle when taint records it quantum (rule 18: "result
//    taint is recorded per clone"), else the C type, void for void. The clone keeps the original's
//    calling convention and carries no attributes. Its body is the spine's (construct()).
//    Aggregate and pointer formals and results (rules 21, 25, 26: field digits, fat-pointer triples,
//    flattened results) and packed integer results are unimplemented here.
//  - materialize has no TaintInfo in its signature, but the result kind is taint's record. It is
//    read from the TaintInfo of the run, which this module holds from the first LoweringContext it
//    sees (a TaintInfo is a shared handle, so the copy keeps that run's analysis alive). S must be
//    one of that TaintInfo's specializations (checked by address); a clone requested before any
//    call site of its run was lowered is an internal error. Construct order guarantees it: taint
//    publishes every clone after a specialization that calls it.
//  - lowerLifted(ctx, call): a direct call of a callee with a body under rule 18/19. The callee's
//    specialization is taint's (calleeSpecialization). No specialization, or the in-place one,
//    is the ordinary call (the operands are classical). Otherwise the call of materialize(S) with
//    the block flag first when S is _ctl. A quantum result is a fresh rail the caller owns: it is
//    recorded with Uncompute::recordTemplate, because the twin's ABI is exactly a template's
//    _unc (CR §1.4: `_unc(outs…, args…)`, void): Uncompute emits `<clone>_unc(out, args…)` and
//    cqrt_free after the result's last use when the rail is garbage, and nothing when the rail is
//    kept (measured, escaped, rule 6 cleaned it). The recorded TemplateSpec is a placeholder (op is
//    empty, w the result's rail type); no consumer may spell a symbol from it. A classical result
//    (a measuring callee, rule 18) is bound as it is and has no twin. A void call records nothing.
//  - lowerDeclared(ctx, call): rule 27. Every result a handle, the _ctl form under a quantum
//    predicate, the trailing K argument, the C calling convention; the result is recorded as above,
//    so the twin `<clone>_unc(out, args…, K)` runs after its last use. Pointer arguments
//    (fat-pointer triple, object-table count, snapshots) are unimplemented here.
//  - lowerIndirect(ctx, call): rule 19, a call through a classical function pointer: a classical
//    chain of pointer-equality tests over the static callee set (!callees, else every address-taken
//    function of the call's type, as taint reads it), each arm calling its candidate's clone; the
//    last test's false edge is unreachable (a pointer outside the set is the program's UB). A
//    result is merged by a classical phi of handles (Uncompute::recordMerge). The builder is left
//    in the join block.
//  - emitTwin(ctx, lowered): emits, at the builder, the twin call of a lowered clone call whose
//    result rail the caller did NOT record (`<clone>_unc(out, args…)`). The twins of recorded
//    results are Uncompute's to emit. Twin bodies are defined by finalize.
//  - lowerVarargs and lowerAsm are unimplemented (variadic clones; inline asm is cq-w3-asm).
#include "cq/Calls.h"

#include "cq/Abi.h"
#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PatternMatch.h"

#include <optional>
#include <string>

using namespace llvm;

namespace cq::calls {
namespace {

// The TaintInfo of the current run (see the contract).
std::optional<TaintInfo> runTaint;

void capture(LoweringContext &ctx) { runTaint = ctx.T; }

const TaintInfo &taintOf(const Specialization &S) {
  if (!runTaint)
    internalError("calls: materialize of a clone before any call site of the run was lowered (no TaintInfo)", S.F);
  ArrayRef<Specialization> all = runTaint->specializations();
  if (all.empty() || &S < all.begin() || &S >= all.end())
    internalError("calls: materialize of a specialization that is not one of the run's TaintInfo", S.F);
  return *runTaint;
}

abi::CloneSpec cloneSpecOf(const Specialization &S) {
  return abi::CloneSpec{S.F->getName().str(), S.mask, S.bounds, S.ctl, S.pure, S.adj, S.depth, false};
}

bool sameFields(const abi::CloneSpec &a, const abi::CloneSpec &b) {
  return a.fn == b.fn && a.mask == b.mask && a.bounds == b.bounds && a.ctl == b.ctl && a.pure == b.pure &&
         a.adj == b.adj && a.depth == b.depth && a.unc == b.unc;
}

// The CR §1.4 name of cs; unimplemented when the right-to-left reading does not give cs back.
std::string checkedName(const abi::CloneSpec &cs, const Value *at) {
  std::string n = abi::name(cs);
  std::optional<abi::CloneSpec> back = abi::parseClone(n);
  if (!back || !sameFields(*back, cs))
    unimplemented("calls: a clone whose CR §1.4 name reads back as another clone (a uniquified clone)", at);
  return n;
}

// A scalar C type a rail can hold (CR §1.1); everything else is a field-wise ABI of another module.
bool scalarRailType(Type *t) {
  return t->isIntegerTy() || t->isHalfTy() || t->isBFloatTy() || t->isFloatTy() || t->isDoubleTy() ||
         t->isX86_FP80Ty();
}

// An integer result packed from narrower fields (taint's resultQuantum reads it as several fields, 159).
bool packedIntegerResult(const Function &F) {
  if (!F.getReturnType()->isIntegerTy())
    return false;
  using namespace PatternMatch;
  for (const BasicBlock &BB : F)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *V = RI->getReturnValue()) {
        Value *X, *Y;
        const APInt *C;
        if (match(V, m_DisjointOr(m_Shl(m_ZExt(m_Value(X)), m_APInt(C)), m_ZExt(m_Value(Y)))) ||
            match(V, m_DisjointOr(m_ZExt(m_Value(Y)), m_Shl(m_ZExt(m_Value(X)), m_APInt(C)))))
          if (C->getZExtValue() % 8 == 0)
            return true;
        return false;
      }
  return false;
}

// Is the result of a clone of S an i32 handle? (void: no result.)
bool resultIsHandle(const TaintInfo &T, const Specialization &S, const Value *at) {
  Type *rt = S.F->getReturnType();
  if (rt->isVoidTy())
    return false;
  if (!scalarRailType(rt))
    unimplemented("calls: a clone with an aggregate, vector or pointer result (rules 18, 21, 25: field-wise "
                  "result, aggr/fatptr)",
                  at);
  if (packedIntegerResult(*S.F))
    unimplemented("calls: a clone whose integer result is packed from several fields (159, aggr)", at);
  return T.resultQuantum(S, 0);
}

// The placeholder spec of a clone-call record (see the contract).
abi::TemplateSpec callRecordSpec(Type *origResult) {
  abi::TemplateSpec spec;
  spec.w = railTypeOf(origResult);
  return spec;
}

// The block flag a _ctl call takes as its first argument.
Value *ctlFlag(LoweringContext &ctx, const CallBase &CB) {
  Value *f = ctx.currentFlag();
  if (!f && ctx.S.ctl)
    f = ctx.out().getArg(0);   // the clone's own entry flag (CR §1.4 _ctl: the first parameter)
  if (!f)
    internalError("calls: a _ctl call with no quantum predicate in scope", &CB);
  return f;
}

// Remapped actual arguments of CB for a callee whose mask digits are `mask` (one per formal).
void appendActuals(LoweringContext &ctx, const CallBase &CB, StringRef mask, SmallVectorImpl<Value *> &args,
                   SmallVectorImpl<Operand> &ops) {
  if (mask.size() != CB.arg_size())
    unimplemented("calls: a call whose mask is not one digit per argument (aggregate or pointer fields: "
                  "aggr/fatptr)",
                  &CB);
  for (unsigned i = 0; i < CB.arg_size(); ++i) {
    const Value *a = CB.getArgOperand(i);
    if (!scalarRailType(a->getType()))
      unimplemented("calls: a pointer, aggregate or vector argument of a quantum call (rules 21, 25, 26)", &CB);
    Operand o = ctx.operand(a);
    if (mask[i] == '1' && !o.handle)
      unimplemented("calls: a measured (collapsed, rule 2) value passed where the clone's mask is quantum", &CB);
    if (mask[i] == '0' && o.handle)
      internalError("calls: a rail passed where the clone's mask is classical", &CB);
    args.push_back(o.v);
    ops.push_back(o);
  }
}

// Binds CB's result to the lowered call's result and records a quantum result (see the contract).
void bindResult(LoweringContext &ctx, CallBase &CB, CallInst *call, bool handle,
                ArrayRef<Operand> ops) {
  if (CB.getType()->isVoidTy())
    return;
  bool q = ctx.T.isQuantum(&CB, ctx.S);
  if (handle != q)
    internalError(std::string("calls: the call's result is ") + (handle ? "a handle" : "classical") +
                      " but taint says the value is " + (q ? "quantum" : "classical"),
                  &CB);
  if (handle)
    ctx.unc().recordTemplate(call, callRecordSpec(CB.getType()), ops);
  ctx.bind(&CB, call);
}

// The ordinary call of the original (no clone): every operand classical.
void ordinaryCall(LoweringContext &ctx, CallBase &CB) {
  Instruction *n = CB.clone();
  for (unsigned i = 0; i < n->getNumOperands(); ++i) {
    Value *v = CB.getOperand(i);
    if (isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<Function>(v))
      continue;
    Operand op = ctx.operand(v);
    if (op.handle)
      internalError("calls: a rail reaching an ordinary call", &CB);
    n->setOperand(i, op.v);
  }
  if (!CB.getName().empty())
    n->setName(CB.getName());
  ctx.B().Insert(n);
  if (!CB.getType()->isVoidTy())
    ctx.bind(&CB, n);
}

// The call of the clone of S, at the builder, for the original call CB (an arm of an indirect call
// passes its candidate's specialization and the flag it computed before the dispatch).
struct CloneCall {
  CallInst *call;
  SmallVector<Operand, 8> ops;
  bool handle;   // the result is a rail (taint's per-clone record)
};
CloneCall emitCloneCall(LoweringContext &ctx, CallBase &CB, const Specialization &S, Value *flag) {
  Function *C = materialize(ctx.M, S);
  SmallVector<Value *, 8> args;
  CloneCall r{nullptr, {}, false};
  if (S.ctl) {
    Value *f = flag ? flag : ctlFlag(ctx, CB);
    args.push_back(f);
    r.ops.push_back(Operand{f, true});
  }
  appendActuals(ctx, CB, S.mask, args, r.ops);
  r.call = ctx.B().CreateCall(C, args);
  r.call->setCallingConv(C->getCallingConv());
  r.handle = !CB.getType()->isVoidTy() && resultIsHandle(ctx.T, S, &CB);
  return r;
}

// The C name a declared clone is named after (CR §1.4 fn). Rule 18: an LLVM math intrinsic on a
// quantum operand is the call of the libm function of the same name: llvm.<n>.<types> is n for a
// double, nf for a float, nl for an x86_fp80 first operand (175).
std::string calleeName(const Function &F, const Value *at) {
  if (!F.isIntrinsic())
    return F.getName().str();
  StringRef n = F.getName();
  if (!n.consume_front("llvm.") || n.empty())
    internalError("calls: an intrinsic whose name is not llvm.<name>.<types>", at);
  std::string base = n.take_until([](char c) { return c == '.'; }).str();
  Type *t = F.arg_size() ? F.getFunctionType()->getParamType(0) : nullptr;
  if (t && t->isDoubleTy())
    return base;
  if (t && t->isFloatTy())
    return base + "f";
  if (t && t->isX86_FP80Ty())
    return base + "l";
  unimplemented("calls: an LLVM math intrinsic whose first operand is not float, double or x86_fp80 (rule 18: no "
                "libm name)",
                at);
}

// K of a declared clone (rule 27, §0: flag, CQ_K, global flag, default 4).
// Rule 27: the trailing i32 K of a declared clone is the callee's K (flag, CQ_K, global, default 4).
Value *declaredK(LoweringContext &ctx, const Function &F) {
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), ctx.K(F));
}

// The declared clone of F for CB (rule 27): declared here, called at the builder.
CallInst *emitDeclaredCall(LoweringContext &ctx, CallBase &CB, Function &F, StringRef mask, Value *flag) {
  LLVMContext &C = ctx.M.getContext();
  if (!F.getFunctionType()->isVarArg() && F.arg_size() != CB.arg_size())
    internalError("calls: a declared callee called with another argument count", &CB);
  if (F.getFunctionType()->isVarArg())
    unimplemented("calls: a variadic declared callee (rule 27 per call-site arity)", &CB);
  bool ctl = flag != nullptr;
  SmallVector<Value *, 8> args;
  SmallVector<Operand, 8> ops;
  if (ctl) {
    args.push_back(flag);
    ops.push_back(Operand{flag, true});
  }
  appendActuals(ctx, CB, mask, args, ops);
  Value *K = declaredK(ctx, F);
  args.push_back(K);
  ops.push_back(Operand{K, false});
  Type *rt = CB.getType();
  if (!rt->isVoidTy()) {
    if (!scalarRailType(rt))
      unimplemented("calls: a declared clone with an aggregate, vector or pointer result (rule 27, aggr)", &CB);
    rt = handleTy(C);
  }
  SmallVector<Type *, 8> ps;
  for (Value *a : args)
    ps.push_back(a->getType());
  abi::CloneSpec cs{calleeName(F, &CB), mask.str(), {}, ctl, false, false, 0, false};
  std::string name = checkedName(cs, &CB);
  FunctionType *FT = FunctionType::get(rt, ps, false);
  Function *D = ctx.M.getFunction(name);
  if (D && D->getFunctionType() != FT)
    internalError("calls: declared clone @" + name + " exists with another type", &CB);
  if (!D)
    D = Function::Create(FT, GlobalValue::ExternalLinkage, name, ctx.M);
  CallInst *call = ctx.B().CreateCall(D, args);   // C calling convention (rule 27)
  if (!CB.getType()->isVoidTy()) {
    // Every result a handle (rule 27); taint agrees for a declared callee.
    if (!ctx.T.isQuantum(&CB, ctx.S))
      internalError("calls: a declared clone's result that taint says is classical", &CB);
    ctx.unc().recordTemplate(call, callRecordSpec(CB.getType()), ops);
    ctx.bind(&CB, call);
  }
  return call;
}

// The mask of a call site from its actuals (scalar arguments only).
std::string siteMask(LoweringContext &ctx, const CallBase &CB) {
  std::string m;
  for (const Use &u : CB.args()) {
    if (!scalarRailType(u->getType()))
      unimplemented("calls: a pointer, aggregate or vector argument of a quantum call (rules 21, 25, 26)", &CB);
    m.push_back(ctx.T.isQuantum(u.get(), ctx.S) ? '1' : '0');
  }
  return m;
}

// The specialization taint made for candidate G of an indirect call (rule 19).
const Specialization *candidateSpec(LoweringContext &ctx, const CallBase &CB, const Function &G, StringRef mask,
                                    bool underQ) {
  SmallVector<const Specialization *, 4> hits;
  for (const Specialization &s : ctx.T.specializations())
    if (s.F == &G && s.mask == mask && !s.adj && s.depth == 0)
      hits.push_back(&s);
  // ctl: under a quantum predicate iff the callee has a non-pure gate, i.e. iff taint made a _ctl clone.
  bool wantCtl = false;
  if (underQ)
    for (const Specialization *s : hits)
      wantCtl |= s->ctl;
  bool anyPure = false;
  for (const Specialization *s : hits)
    anyPure |= s->ctl == wantCtl && s->pure;
  bool wantPure = ctx.S.pure && anyPure;
  const Specialization *r = nullptr;
  for (const Specialization *s : hits) {
    if (s->ctl != wantCtl || s->pure != wantPure)
      continue;
    if (r)
      unimplemented("calls: an indirect-call candidate with several specializations for one mask (bounds)", &CB);
    r = s;
  }
  return r;
}

// Does the call's value need to stay allocated (measured, or escaping an entry as its handle)? The
// arms of an indirect call's merge are then kept (Uncompute U1: a merge is kept only when every arm
// is), otherwise they are garbage.
bool resultKept(LoweringContext &ctx, const CallBase &CB) {
  for (const User *u : CB.users()) {
    if (auto *uc = dyn_cast<CallBase>(u))
      if (classify(*uc, ctx.T, ctx.S) == Class::Measure)
        return true;
    if (isa<ReturnInst>(u) && ctx.S.isEntry())
      return true;
  }
  return false;
}

// Does G's body reach a call of F (G == F included)?
bool reaches(const Function *G, const Function *F) {
  SmallPtrSet<const Function *, 16> seen{G};
  SmallVector<const Function *, 16> work{G};
  while (!work.empty()) {
    const Function *X = work.pop_back_val();
    for (const BasicBlock &BB : *X)
      for (const Instruction &I : BB)
        if (auto *C = dyn_cast<CallBase>(&I))
          if (const Function *Y = C->getCalledFunction()) {
            if (Y == F)
              return true;
            if (!Y->isDeclaration() && seen.insert(Y).second)
              work.push_back(Y);
          }
  }
  return false;
}

// A recursive call that taint cut (rule 14): no callee specialization, a callee with a body that
// recurses back into this function, and a quantum argument or result.
bool isCutRecursion(LoweringContext &ctx, const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  if (!G || G->isDeclaration() || ctx.S.isEntry() || !reaches(G, ctx.S.F))
    return false;
  bool q = !CB.getType()->isVoidTy() && ctx.T.isQuantum(&CB, ctx.S);
  for (const Use &u : CB.args())
    q |= ctx.T.isQuantum(u.get(), ctx.S);
  return q;
}

} // namespace

Function *materialize(Module &M, const Specialization &S) {
  if (!S.F || S.F->isDeclaration())
    internalError("calls: materialize of a specialization with no body (a declared clone is rule 27's)");
  if (S.isEntry())
    internalError("calls: materialize of an entry specialization (rewritten in place by construct)", S.F);
  const TaintInfo &T = taintOf(S);
  LLVMContext &C = M.getContext();
  abi::CloneSpec cs = cloneSpecOf(S);
  std::string name = checkedName(cs, S.F);

  if (S.mask.size() != S.F->arg_size())
    unimplemented("calls: a clone whose mask is not one digit per formal (aggregate or pointer fields: aggr/fatptr)",
                  S.F);
  SmallVector<Type *, 8> ps;
  if (S.ctl)
    ps.push_back(handleTy(C));
  for (unsigned i = 0; i < S.F->arg_size(); ++i) {
    Type *t = S.F->getArg(i)->getType();
    if (!scalarRailType(t))
      unimplemented("calls: a clone with a pointer, aggregate or vector formal (rules 21, 25, 26)", S.F->getArg(i));
    ps.push_back(S.mask[i] == '1' ? handleTy(C) : t);
  }
  Type *rt = S.F->getReturnType();
  if (resultIsHandle(T, S, S.F))
    rt = handleTy(C);
  if (S.F->isVarArg())
    unimplemented("calls: a clone of a variadic function (per call-site arity, lowerVarargs)", S.F);
  FunctionType *FT = FunctionType::get(rt, ps, false);

  if (Function *ex = M.getFunction(name)) {
    if (ex->getFunctionType() != FT)
      internalError("calls: clone @" + name + " exists with another type", S.F);
    return ex;
  }
  Function *NF = Function::Create(FT, GlobalValue::InternalLinkage, name, &M);
  NF->setCallingConv(S.F->getCallingConv());
  return NF;
}

void lowerLifted(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!cs && isCutRecursion(ctx, CB)) {
    // Rule 14: the recursive call at the cut level (taint publishes no deeper level). This level is
    // the cut one, so B = depth when depth < K; at depth K the bound is not known here.
    const Function &G = *CB.getCalledFunction();
    unsigned K = ctx.K(G);
    std::optional<uint64_t> B;
    if (ctx.S.depth < K)
      B = ctx.S.depth;
    return loops::lowerQuantumDepthRecursion(ctx, CB, K, B);
  }
  if (!cs || cs->isEntry()) {
    // An untainted callee or the in-place specialization: the ordinary call (rule 19's inline of an
    // entry returning a quantum value is the spine's).
    for (const Use &u : CB.args())
      if (ctx.operand(u.get()).handle)
        internalError("calls: a quantum argument to a callee with no clone", &CB);
    return ordinaryCall(ctx, CB);
  }
  if (cs->F->isDeclaration()) {
    Value *flag = !ctx.currentPredicate().isTop() || ctx.S.ctl ? ctlFlag(ctx, CB) : nullptr;
    emitDeclaredCall(ctx, CB, *cs->F, cs->mask, flag);
    return;
  }
  CloneCall r = emitCloneCall(ctx, CB, *cs, nullptr);
  bindResult(ctx, CB, r.call, r.handle, r.ops);
}

void lowerDeclared(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Function *F = CB.getCalledFunction();
  if (!F || !F->isDeclaration())
    internalError("calls: lowerDeclared of a call that is not a direct call of a declaration", &CB);
  // Rule 27: "a call with no quantum argument stays the ordinary call"; the name's mask is the
  // call site's (CR §1.4 with no _b bounds).
  bool anyQ = false;
  for (const Use &u : CB.args())
    anyQ |= ctx.T.isQuantum(u.get(), ctx.S);
  if (!anyQ)
    return ordinaryCall(ctx, CB);
  std::string mask = siteMask(ctx, CB);
  Value *flag = !ctx.currentPredicate().isTop() || ctx.S.ctl ? ctlFlag(ctx, CB) : nullptr;
  emitDeclaredCall(ctx, CB, *F, mask, flag);
}

void lowerIndirect(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  const Value *callee = CB.getCalledOperand();
  Operand fp = ctx.operand(callee);
  if (fp.handle || ctx.T.isQuantum(callee, ctx.S))
    unimplemented("calls: a function pointer loaded at a quantum index (rule 19: a QROM of callee tags, every "
                  "candidate clone called unguarded and merged by select)",
                  &CB);
  // The static callee set: clang's !callees, else every address-taken function of the call's type.
  SmallVector<Function *, 4> cands;
  if (MDNode *md = CB.getMetadata(LLVMContext::MD_callees)) {
    for (const MDOperand &op : md->operands())
      if (auto *cm = dyn_cast_or_null<ConstantAsMetadata>(op.get()))
        if (auto *G = dyn_cast<Function>(cm->getValue()->stripPointerCasts()))
          cands.push_back(G);
  } else {
    for (Function &G : ctx.M)
      if (G.hasAddressTaken() && G.getFunctionType() == CB.getFunctionType() && !G.getName().starts_with("__cq_q_"))
        cands.push_back(&G);
  }
  if (cands.empty())
    unimplemented("calls: an indirect call with an empty static callee set", &CB);
  for (Function *G : cands)
    if (G->getFunctionType() != CB.getFunctionType())
      unimplemented("calls: an indirect-call candidate whose type differs from the call's", &CB);

  std::string mask = siteMask(ctx, CB);
  bool underQ = !ctx.currentPredicate().isTop() || ctx.S.ctl;
  // The flag dominates every arm: computed once, before the dispatch.
  Value *flag = nullptr;
  SmallVector<const Specialization *, 4> specs;
  bool anyCtl = false;
  for (Function *G : cands) {
    const Specialization *s = nullptr;
    if (!G->isDeclaration()) {
      s = candidateSpec(ctx, CB, *G, mask, underQ);
      if (!s)
        unimplemented("calls: an indirect-call candidate with no specialization for the call's mask", &CB);
      if (s->isEntry())
        unimplemented("calls: an indirect-call candidate whose specialization is its in-place one", &CB);
      anyCtl |= s->ctl;
    }
    specs.push_back(s);
  }
  bool declaredAny = false;
  for (const Specialization *s : specs)
    declaredAny |= s == nullptr;
  if (anyCtl || (declaredAny && underQ))
    flag = ctlFlag(ctx, CB);

  IRBuilder<> &B = ctx.B();
  Function &out = ctx.out();
  LLVMContext &C = ctx.M.getContext();
  BasicBlock *join = BasicBlock::Create(C, "", &out);
  bool hasResult = !CB.getType()->isVoidTy();
  bool handle = hasResult && ctx.T.isQuantum(&CB, ctx.S);
  SmallVector<std::pair<Value *, BasicBlock *>, 4> incoming;
  for (unsigned k = 0; k < cands.size(); ++k) {
    Function *G = cands[k];
    Value *eq = B.CreateICmpEQ(fp.v, G);
    BasicBlock *arm = BasicBlock::Create(C, "", &out, join);
    BasicBlock *next = BasicBlock::Create(C, "", &out, join);
    B.CreateCondBr(eq, arm, next);
    B.SetInsertPoint(arm);
    CallInst *call = nullptr;
    if (specs[k]) {
      CloneCall r = emitCloneCall(ctx, CB, *specs[k], specs[k]->ctl ? flag : nullptr);
      call = r.call;
      if (hasResult && r.handle != handle)
        unimplemented("calls: an indirect-call candidate whose result kind (handle / classical) differs from "
                      "taint's for the call",
                      &CB);
      if (r.handle)
        ctx.unc().recordTemplate(call, callRecordSpec(CB.getType()), r.ops);
    } else {
      // A candidate with no body (rule 27). emitDeclaredCall binds and records; unbind is not
      // possible, so a declared candidate in a set is unimplemented until the merge needs it.
      unimplemented("calls: a declared (rule 27) candidate of an indirect call", &CB);
    }
    if (hasResult)
      incoming.push_back({call, arm});
    B.CreateBr(join);
    B.SetInsertPoint(next);
  }
  B.CreateUnreachable();
  B.SetInsertPoint(join);
  if (!hasResult)
    return;
  PHINode *phi = B.CreatePHI(incoming.front().first->getType(), incoming.size());
  for (auto &[v, bb] : incoming)
    phi->addIncoming(v, bb);
  if (handle) {
    if (resultKept(ctx, CB))
      for (auto &[v, bb] : incoming)
        ctx.unc().setRole(ctx.unc().idOf(v), Role::Result);
    ctx.unc().recordMerge(phi);
  }
  ctx.bind(&CB, phi);
}

void lowerVarargs(LoweringContext &, Instruction &I) {
  unimplemented("calls: calls::lowerVarargs (variadic clones per call-site arity, CR §1.4)", &I);
}

void lowerAsm(LoweringContext &, CallBase &CB) {
  unimplemented("calls: calls::lowerAsm (inline asm with a quantum operand, rule 27: cq-w3-asm)", &CB);
}

void emitTwin(LoweringContext &ctx, CallBase &lowered) {
  capture(ctx);
  auto *call = dyn_cast<CallInst>(&lowered);
  Function *C = call ? call->getCalledFunction() : nullptr;
  std::optional<abi::CloneSpec> cs = C ? abi::parseClone(C->getName()) : std::nullopt;
  if (!cs || cs->unc)
    internalError("calls: emitTwin of a call that is not a forward clone call", &lowered);
  if (call->getType() != handleTy(ctx.M.getContext()))
    unimplemented("calls: emitTwin of a clone with no single handle result", &lowered);
  LLVMContext &Cx = ctx.M.getContext();
  SmallVector<Type *, 8> ps{handleTy(Cx)};
  SmallVector<Value *, 8> args{call};
  for (Value *a : call->args()) {
    ps.push_back(a->getType());
    args.push_back(a);
  }
  std::string tn = (C->getName() + "_unc").str();
  FunctionType *FT = FunctionType::get(Type::getVoidTy(Cx), ps, false);
  Function *Tw = ctx.M.getFunction(tn);
  if (Tw && Tw->getFunctionType() != FT)
    internalError("calls: twin @" + tn + " exists with another type", &lowered);
  if (!Tw)
    Tw = Function::Create(FT, GlobalValue::ExternalLinkage, tn, ctx.M);   // finalize defines an in-module twin
  ctx.B().CreateCall(Tw, args);
}

} // namespace cq::calls
