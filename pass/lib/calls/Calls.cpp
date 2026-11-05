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
//    calling convention and carries no attributes but byval on a byval formal the callee may write
//    (cq-09xh; the call passes a snapshot of the caller's object taken at the call, byval, and the twin
//    gets that snapshot); a read-only byval formal is the caller's pointer. Its body is the spine's (construct()).
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
//  - lowerVarargs: the va intrinsics of a variadic clone (the x86-64 SysV save area); lowerAsm waits on
//    CQ_spec's inline-asm example (build step 3, rule 27).
#include "cq/Calls.h"

#include "cq/Abi.h"
#include "cq/Aggregates.h"
#include "cq/Common.h"
#include "cq/Effects.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Bus.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "../spine/SpineInternal.h"

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"

#include <map>
#include <optional>
#include <string>

using namespace llvm;

namespace cq::calls {
namespace {

// The TaintInfo of the current run (see the contract).
std::optional<TaintInfo> runTaint;
// The run's K resolution (CLAUDE.md "K per loop"), captured with it: rule 14's cut of a quantum-depth
// recursion decides from K and B whether a clone returns the overflow predicate (cq-ew5z).
std::optional<loops::KOptions> runKO;

void capture(LoweringContext &ctx) {
  runTaint = ctx.T;
  runKO = spine::shared(ctx).KO;
}

const TaintInfo &taintOf(const Specialization &S) {
  if (!runTaint)
    internalError("calls: materialize of a clone before any call site of the run was lowered (no TaintInfo)", S.F);
  ArrayRef<Specialization> all = runTaint->specializations();
  if (!all.empty() && &S >= all.begin() && &S < all.end()) {
    return *runTaint;
  }
  internalError("calls: materialize of a specialization that is not one of the run's TaintInfo", S.F);
}

abi::CloneSpec cloneSpecOf(const Specialization &S) {
  return abi::CloneSpec{S.F->getName().str(), S.mask, S.bounds, S.ctl, S.pure, false};
}

bool sameFields(const abi::CloneSpec &a, const abi::CloneSpec &b) {
  return a.fn == b.fn && a.mask == b.mask && a.bounds == b.bounds && a.ctl == b.ctl && a.pure == b.pure &&
         a.unc == b.unc;
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

// An integer result, or an integer field of a composite result, packed from narrower fields by the
// C ABI's coercion (zext / shl / or disjoint: 159, 166). Its fields are the struct's (cq-0umd).
bool packedInteger(const Value *V) {
  using namespace PatternMatch;
  Value *X, *Y;
  const APInt *C;
  return (match(V, m_DisjointOr(m_Shl(m_ZExt(m_Value(X)), m_APInt(C)), m_ZExt(m_Value(Y)))) ||
          match(V, m_DisjointOr(m_ZExt(m_Value(Y)), m_Shl(m_ZExt(m_Value(X)), m_APInt(C))))) &&
         C->getZExtValue() % 8 == 0;
}

bool packedIntegerResult(const Function &F) {
  // Any return's packing makes the result field-wise (rule 26: the union of the returns' packings, cq-jkq8).
  for (const BasicBlock &BB : F)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (const Value *V = RI->getReturnValue()) {
        if (V->getType()->isIntegerTy()) {
          if (packedInteger(V))
            return true;
          continue;
        }
        for (const Value *v = V; auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
          if (iv->getInsertedValueOperand()->getType()->isIntegerTy() && packedInteger(iv->getInsertedValueOperand()))
            return true;
      }
  return false;
}

bool isComposite(Type *t) { return t->isStructTy() || t->isArrayTy() || t->isVectorTy(); }

// The scalar leaves of a type, depth first, left to right (struct and array elements, vector lanes):
// the fields aggr binds a composite value to (rules 25, 26).
void leafTypes(Type *t, SmallVectorImpl<Type *> &out, const Value *at) {
  if (auto *st = dyn_cast<StructType>(t)) {
    for (Type *e : st->elements())
      leafTypes(e, out, at);
  } else if (auto *a = dyn_cast<ArrayType>(t)) {
    for (uint64_t k = 0; k < a->getNumElements(); ++k)
      leafTypes(a->getElementType(), out, at);
  } else if (auto *v = dyn_cast<FixedVectorType>(t)) {
    for (unsigned k = 0; k < v->getNumElements(); ++k)
      out.push_back(v->getElementType());
  } else if (isa<ScalableVectorType>(t)) {
    // CR §0: x86-64 only; no x86-64 C type is a scalable vector, so none reaches a call of the input.
    internalError("calls: a scalable vector across a call (no x86-64 C type lowers to one, CR §0)", at);
  } else {
    out.push_back(t);
  }
}

// The clone ABI of one formal (CR §1.4): one parameter per scalar leaf, an i32 handle where taint's
// field mask is quantum, the leaf's C type where it is classical; a pointer formal is the caller's
// classical pointer (a pointee that holds no handle at the call, not a fat pointer).
struct FormalLayout {
  SmallVector<Type *, 4> leaves;
  SmallVector<bool, 4> q;
  bool pointer = false;
  // cq-0umd (rule 26): an integer formal the callee unpacks into fields (159's coerced struct): one
  // leaf per field at spine::unpackCuts, the digits the mask's.
  SmallVector<unsigned, 4> cuts;
  // CR §1.4 (cq-tqev): a variadic actual of the per-signature clone; a scalar's one digit is the mask's.
  bool variadic = false;
};

// The variadic actuals of the call sites of variadic S (CR §1.4: one clone per call-site arity; every call
// taint maps to S has the same arity, the mask's): their IR types, and for a byval actual (an aggregate the
// x86-64 C ABI passes in memory) its byval type. lowerVarargs lays them out as the x86-64 SysV calling
// convention places them (registers, then the overflow area).
struct VariadicActual {
  Type *ty;
  Type *byval = nullptr;
};

// A scalar the x86-64 SysV convention passes in one or two gp registers, an xmm register or memory, and that
// -O1's va_arg code reads back as one value: the variadic actuals a save area lays out (lowerVarargs).
bool vaScalar(Type *t) {
  return t->isPointerTy() || (t->isIntegerTy() && t->getIntegerBitWidth() <= 128) || t->isFloatTy() ||
         t->isDoubleTy() || t->isX86_FP80Ty();
}

SmallVector<VariadicActual, 4> variadicActuals(const TaintInfo &T, const Specialization &S, const Value *at) {
  unsigned fixed = S.F->arg_size();
  std::optional<SmallVector<VariadicActual, 4>> found;
  const CallBase *first = nullptr;
  for (const Use &U : S.F->uses()) {
    auto *CB = dyn_cast<CallBase>(U.getUser());
    if (!CB || !CB->isCallee(&U))
      continue;
    for (const Specialization &C : T.specializations()) {
      if (C.F != CB->getFunction() || T.calleeSpecialization(*CB, C) != &S)
        continue;
      SmallVector<VariadicActual, 4> ts;
      for (unsigned i = fixed; i < CB->arg_size(); ++i) {
        VariadicActual va{CB->getArgOperand(i)->getType()};
        if (CB->isByValArgument(i))
          va.byval = CB->getParamByValType(i);
        else if (!vaScalar(va.ty) && !va.ty->isVectorTy())
          internalError("calls: a variadic actual of a type no x86-64 C call passes (CR §0)", CB);
        ts.push_back(va);
      }
      auto same = [](const SmallVector<VariadicActual, 4> &a, const SmallVector<VariadicActual, 4> &b) {
        return a.size() == b.size() && std::equal(a.begin(), a.end(), b.begin(), [](const VariadicActual &x,
                                                                                    const VariadicActual &y) {
                 return x.ty == y.ty && x.byval == y.byval;
               });
      };
      if (found && !same(*found, ts))
        unimplemented("calls: awaiting owner ruling: SPEC_ISSUES \"variadic clone per call-site arity: two call "
                      "sites of one arity and mask with different variadic actual types\" (here and at " +
                          first->getFunction()->getName().str() + ")",
                      CB);
      found = ts;
      first = CB;
    }
  }
  if (!found)
    internalError("calls: a variadic clone with no call site taint maps to it", at);
  return *found;
}


std::vector<FormalLayout> formalLayout(const TaintInfo &T, const Specialization &S, const Value *at) {
  std::vector<FormalLayout> fs;
  unsigned need = 0;
  for (Argument &A : S.F->args()) {
    FormalLayout f;
    leafTypes(A.getType(), f.leaves, &A);
    f.q = T.fieldMask(&A, S);
    if (A.getType()->isIntegerTy()) {
      SmallVector<unsigned, 4> cuts = spine::unpackCuts(&A);
      if (cuts.size() > 2) {
        f.cuts = cuts;
        f.leaves.clear();
        for (unsigned k = 0; k + 1 < cuts.size(); ++k)
          f.leaves.push_back(IntegerType::get(A.getContext(), cuts[k + 1] - cuts[k]));
        f.q.assign(f.leaves.size(), false);   // set from the mask's digits below
      }
    }
    if (f.q.size() != f.leaves.size())
      internalError("calls: taint's field mask of a formal does not have one entry per scalar leaf", &A);
    f.pointer = A.getType()->isPointerTy();
    for (Type *l : f.leaves)
      if (l->isPointerTy() && !f.pointer)
        unimplemented("calls: an aggregate formal with a pointer field (rule 21 fat-pointer fields)", &A);
    need += f.leaves.size();
    fs.push_back(std::move(f));
  }
  // CR §1.4 (95, 109; cq-tqev): a variadic function's clone is per call-site signature; its formals past the
  // fixed ones are the call's variadic actuals, of the actuals' types, fields of the clone's formal list like
  // any other: a scalar is one field (one digit), a pointer is a pointer formal (taint's T4 pointerFormal:
  // the raw pointer's digits, or the rule 21 triple's tag, idx and pointee-cell digits; scanf's `int *`
  // targets). Their digits follow the fixed formals' in the mask, left to right.
  if (S.F->isVarArg()) {
    SmallVector<VariadicActual, 4> vt = variadicActuals(T, S, at);
    for (size_t k = 0; k < vt.size(); ++k) {
      FormalLayout f;
      f.variadic = true;
      f.leaves.push_back(vt[k].ty);
      f.q.push_back(false);
      need += 1;
      fs.push_back(std::move(f));
    }
  }
  // The name's digits (taint's mask) must say the same, formal by formal; a pointer is one digit.
  const std::string &m = S.mask;
  if (need != m.size())
    internalError("calls: taint's mask has another digit count than its formals", at);
  size_t d = 0;
  for (FormalLayout &f : fs) {
    if (f.cuts.size() > 2) {
      for (unsigned k = 0; k < f.q.size(); ++k)
        f.q[k] = m[d++] == '1';
      continue;
    }
    if (f.variadic) {
      // A quantum scalar actual crosses as its one handle; its save-area cell holds that handle (rule 20's
      // uniform slot array, lowerVarargs). A vector actual's digits are its lanes (rule 25, buildMask).
      f.q[0] = m[d++] == '1';
      if (f.q[0] && !vaScalar(f.leaves[0]))
        unimplemented("calls: a quantum variadic actual that is a pointer, a vector or an aggregate in memory "
                      "(its save-area cell is no one handle: rules 21, 25, 26 in the variadic save area)",
                      at);
      continue;
    }
    for (bool q : f.q)
      if ((m[d++] == '1') != q)
        internalError("calls: taint's mask and field mask of a formal disagree", at);
  }
  return fs;
}

// The clone ABI of the result (CR §1.4): void; one scalar (an i32 handle when taint records it
// quantum, rule 18, else the C type); a composite with a quantum leaf is a literal struct of its leaves
// (a nested aggregate flattened, 166), handles where quantum; a composite with none is the C type.
struct ResultLayout {
  bool composite = false;
  SmallVector<Type *, 4> leaves;
  SmallVector<bool, 4> q;
  // M2 (191): the clone's stores through Qram-pointee formals, one i32 handle each after the leaves.
  unsigned stores = 0;
  bool qramFormal = false;
  // cq-0umd: an integer result packed from fields (159): its field boundaries (composite = true).
  SmallVector<unsigned, 4> cuts;
  // cq-0umd (166): an aggregate result with a packed integer leaf: the fields per leaf (the leaves are
  // then the fields, a packed leaf split); empty when every leaf is one field.
  SmallVector<unsigned, 4> leafFields;
  bool anyQ() const { return is_contained(q, true); }
};


ResultLayout resultLayout(const TaintInfo &T, const Specialization &S, const Value *at) {
  ResultLayout r;
  Type *rt = S.F->getReturnType();
  if (rt->isVoidTy()) {
    return r;
  }
  // Every other return type of C on x86-64 is a scalar rail type, a composite or a (classical) pointer.
  if (!isComposite(rt) && !scalarRailType(rt) && !rt->isPointerTy())
    internalError("calls: a clone result type no C function on x86-64 returns", at);
  if (packedIntegerResult(*S.F) && !rt->isIntegerTy()) {
    // cq-0umd (166, rule 26): a leaf packed from fields (the coerced inner struct) crosses as its fields.
    for (const SmallVector<unsigned, 4> &c : spine::resultLeafCuts(*S.F))
      r.leafFields.push_back(c.size() > 2 ? unsigned(c.size() - 1) : 1u);
  } else if (packedIntegerResult(*S.F)) {
    r.cuts = spine::resultIntCuts(*S.F);   // the union of the returns' packings (rule 26, cq-jkq8)
  }
  r.composite = isComposite(rt) || r.cuts.size() > 2;
  if (r.cuts.size() > 2) {
    for (unsigned k = 0; k + 1 < r.cuts.size(); ++k)
      r.leaves.push_back(IntegerType::get(rt->getContext(), r.cuts[k + 1] - r.cuts[k]));
  } else if (!r.leafFields.empty()) {
    r.leaves = spine::resultFieldTypes(*S.F);
  } else {
    leafTypes(rt, r.leaves, at);
  }
  for (unsigned k = 0; k < r.leaves.size(); ++k) {
    r.q.push_back(T.resultQuantum(S, k));
    if (r.q.back() && !scalarRailType(r.leaves[k]))
      unimplemented("calls: a clone result with a quantum pointer field (rule 21: fatptr)", at);
  }
  return r;
}

Type *cloneResultType(LLVMContext &C, const ResultLayout &r, Type *orig) {
  if (orig->isVoidTy() || !r.anyQ())
    return orig;
  if (!r.composite)
    return handleTy(C);
  SmallVector<Type *, 4> es;
  for (unsigned k = 0; k < r.leaves.size(); ++k)
    es.push_back(r.q[k] ? handleTy(C) : r.leaves[k]);
  return StructType::get(C, es);
}

// The placeholder spec of a clone-call record (see the contract).
abi::TemplateSpec callRecordSpec(Type *origResult) {
  abi::TemplateSpec spec;
  spec.w = railTypeOf(origResult);
  return spec;
}

// Is the call under a quantum predicate (CR rules 19, 27: its _ctl form)? The block's quantum part, a _ctl
// clone's own entry flag, or a rule-14 trip rail (lowerInstruction's tripFlag: case 2 and case 3 trips).
// currentPredicate() does not see the trip (cq-99f7); currentFlag() is the control (cq-ro82).
bool underQuantumPredicate(LoweringContext &ctx) {
  return !ctx.currentPredicate().isTop() || ctx.S.ctl || spine::shared(ctx).tripFlag;
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

// ---- Rule 14's kept overflow predicate of a quantum-depth recursion (cq-ew5z) -------------------------------
//
// CR rule 14: a recursion with quantum depth runs one clone per level, the call at the cut level is a |0> rail,
// and "the cut level would recurse once more" is the kept overflow predicate when B > K or no bound is
// proved. The levels run unguarded or as _ctl clones (rule 19), so a cut call's own predicate holds the
// recursion's path only from its level on: the predicate is built up the levels, each returning it as an
// extra result (rule 19's extra results; calls::materialize, Walker::emitOverflowReturn). At level d it is
// the OR over d's recursive call sites s of (the quantum predicate s runs under) AND (at a cut call: true; at
// a call of level d + 1: the predicate that level returned). A level's returned rail is a result of its call,
// zeroed by the twin with the others (rule 18), so every level's rails are clean; the first caller outside
// the chain (the entry, or a clone calling the recursion) keeps a fresh rail holding the returned predicate
// under its own call's predicate (Role::KeptOverflow), never read, one per activation of the recursion like
// a K-loop's a_K (rule 14, 169); a twin replaying such a caller does not compute it again (calls::finalize).







// CR rules 2, 7: an actual whose rail was measured at a point dominating the call denotes the classical
// outcome (rule 2), while the clone's mask digit, fixed by taint for every call site of the clone, is
// quantum. The clone takes a handle there: the outcome minted as a seed rail alloc_<W>(v) (rule 7: a rail
// minted from a classical value and never written, freed directly once its last reader, the call and its
// twin, has run).
Operand seedActual(LoweringContext &ctx, const Operand &o) {
  if (o.handle)
    return o;
  CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(o.v->getType())}, {o.v});
  ctx.unc().recordSeed(seed);
  return Operand{seed, true};
}

// The fields of a non-pointer actual (CR §1.4: a scalar is one field; an aggregate or vector one per scalar
// leaf, rules 25, 26, flattened depth first).
SmallVector<Operand, 4> actualFields(LoweringContext &ctx, const Value *a) {
  if (isComposite(a->getType()))
    return aggr::flattenResult(ctx, a);
  return {ctx.operand(a)};
}

// Remapped actual arguments of CB for a callee whose mask digits are `mask` (one per field of the actuals,
// CR §1.4; no pointer actual: rule 27's pointers are lowerDeclaredPointers').
void appendActuals(LoweringContext &ctx, const CallBase &CB, StringRef mask, SmallVectorImpl<Value *> &args,
                   SmallVectorImpl<Operand> &ops) {
  size_t d = 0;
  for (unsigned i = 0; i < CB.arg_size(); ++i) {
    const Value *a = CB.getArgOperand(i);
    if (a->getType()->isPointerTy())
      internalError("calls: a pointer actual of a declared clone outside lowerDeclaredPointers", &CB);
    for (Operand o : actualFields(ctx, a)) {
      if (d >= mask.size())
        internalError("calls: a call with more fields than its clone's mask digits", &CB);
      if (mask[d] == '1')
        o = seedActual(ctx, o);
      if (mask[d] == '0' && o.handle)
        internalError("calls: a rail passed where the clone's mask is classical", &CB);
      ++d;
      args.push_back(o.v);
      ops.push_back(o);
    }
  }
  if (d != mask.size())
    internalError("calls: a call with fewer fields than its clone's mask digits", &CB);
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
  bool handle;      // the result is one rail (taint's per-clone record)
  bool fieldwise;   // the result is a literal struct of fields with a handle among them
  ResultLayout res;
  Value *value = nullptr;   // the result as the binders read it (the call itself)
};





CloneCall emitCloneCall(LoweringContext &ctx, CallBase &CB, const Specialization &S, Value *flag,
                        ArrayRef<unsigned> argMap = {}) {
  // C1: formal k takes CB's operand argMap[k] (identity when argMap is empty).
  unsigned nArgs = argMap.empty() ? CB.arg_size() : unsigned(argMap.size());
  auto op = [&](unsigned k) { return argMap.empty() ? k : argMap[k]; };
  for (unsigned k : argMap)
    if (k >= CB.arg_size())
      internalError("calls: an argument map past the call's operands", &CB);
  Function *C = materialize(ctx.M, S);
  std::vector<FormalLayout> fs = formalLayout(ctx.T, S, &CB);
  SmallVector<Value *, 8> args;
  CloneCall r{nullptr, {}, false, false, resultLayout(ctx.T, S, &CB)};
  if (S.ctl) {
    Value *f = flag ? flag : ctlFlag(ctx, CB);
    args.push_back(f);
    r.ops.push_back(Operand{f, true});
  }
  // A direct call's arity is its callee's (a mismatched call is indirect: getCalledFunction is null); an argument map
  // names one operand per formal (lowerLiftedVia).
  if (nArgs != fs.size())
    internalError("calls: a call whose argument count differs from the clone's formals", &CB);
  for (unsigned i = 0; i < nArgs; ++i) {
    const Value *a = CB.getArgOperand(op(i));
    // Rule 26: a byval copy is W3d's (__cq_alloc and the rule-22 copy).
    if (op(i) < S.F->arg_size() && CB.isByValArgument(op(i)))
      report_fatal_error("cq: unimplemented: bus: byval actual (rule 26)", /*gen_crash_diag=*/false);
    SmallVector<Operand, 4> leaves;
    if (fs[i].cuts.size() > 2)
      leaves = spine::packFields(ctx, a, fs[i].cuts);   // cq-0umd: the coerced struct's fields
    else if (isComposite(a->getType()))
      leaves = aggr::flattenResult(ctx, a);
    else
      leaves.push_back(ctx.operand(a));
    if (leaves.size() != fs[i].leaves.size())
      internalError("calls: an actual with another field count than its formal", &CB);
    for (unsigned k = 0; k < leaves.size(); ++k) {
      Operand o = leaves[k];
      if (fs[i].q[k])
        o = seedActual(ctx, o);
      if (!fs[i].q[k] && o.handle)
        internalError("calls: a rail passed where the clone's mask is classical", &CB);
      args.push_back(o.v);
      r.ops.push_back(Operand{o.v, o.handle});
    }
  }
  if (fenv::cloneCarriesEnv(ctx.T, S)) {
    // E1 (82): the mode and flags trail the formals' fields.
    for (const Operand &e : fenv::envArgs(ctx, CB)) {   // mode (classical), flags (a handle the twin reads)
      args.push_back(e.v);
      r.ops.push_back(e);
    }
  }
  r.call = ctx.B().CreateCall(C, args);
  r.call->setCallingConv(C->getCallingConv());
  r.handle = !S.F->getReturnType()->isVoidTy() && !r.res.composite && r.res.anyQ();
  r.fieldwise = r.res.composite && r.res.anyQ();
  r.value = r.call;
  return r;
}

// Binds a field-wise result (CR §1.4: a literal struct of handles and classical values): one
// extractvalue per field right after the call, the field operands bound to CB (aggr reads them), and
// the handles recorded as the call's results, undone together by the twin (U2).
void bindFieldwiseResult(LoweringContext &ctx, CallBase &CB, CallInst *call, const ResultLayout &res) {
  SmallVector<bool, 4> tq = ctx.T.fieldMask(&CB, ctx.S);
  if (res.cuts.size() > 2 || !res.leafFields.empty())
    tq = res.q;   // cq-0umd: a packed integer result's fields are the callee's (resultQuantum)
  if (tq.size() != res.q.size() || !std::equal(tq.begin(), tq.end(), res.q.begin()))
    internalError("calls: the clone's result fields and taint's field mask of the call disagree", &CB);
  SmallVector<Operand, 4> ops;
  SmallVector<Value *, 4> outs;
  for (unsigned k = 0; k < res.leaves.size(); ++k) {
    Value *e = ctx.B().CreateExtractValue(call, {k});
    ops.push_back(Operand{e, res.q[k]});
    if (res.q[k])
      outs.push_back(e);
  }
  ctx.unc().recordCall(call, outs, {});
  if (!res.leafFields.empty())
    aggr::bindLeafFields(ctx, &CB, ops, res.leafFields);   // 166: a packed leaf's fields
  else
    ctx.bindFields(&CB, ops);
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
  // The intrinsics whose C function has another name (taint's libmNameOf names the same): IEEE 754-2019
  // minimum/maximum are C23 fminimum/fmaximum; powi has no C name and is LLVM's own libcall,
  // compiler-rt's __powi<m>f2.
  if (F.getIntrinsicID() == Intrinsic::minimum)
    base = "fminimum";
  else if (F.getIntrinsicID() == Intrinsic::maximum)
    base = "fmaximum";
  else if (F.getIntrinsicID() == Intrinsic::powi && t &&
           (t->isFloatTy() || t->isDoubleTy() || t->isX86_FP80Ty()))
    return t->isFloatTy() ? "__powisf2" : t->isDoubleTy() ? "__powidf2" : "__powixf2";
  if (t && t->isDoubleTy())
    return base;
  if (t && t->isFloatTy())
    return base + "f";
  if (t && t->isX86_FP80Ty())
    return base + "l";
  // Owner 2026-11-03 (no fences): whatever LLVM does. Codegen promotes half/bfloat to float and scalarises a vector
  // per element, so the name is the element type's: half/bfloat -> the float name, anything else the double name.
  if (Type *e = t ? t->getScalarType() : nullptr; e && (e->isHalfTy() || e->isBFloatTy() || e->isFloatTy()))
    return base + "f";
  if (Type *e = t ? t->getScalarType() : nullptr; e && e->isX86_FP80Ty())
    return base + "l";
  return base;
}

// Rule 27: the trailing i32 K of a declared clone is the callee's K (flag, CQ_K, global, default 4),
// resolved on the callee's C name (cq-h8vd): an LLVM math intrinsic's callee is the libm function
// (rule 18), so llvm.exp.f64 resolves as exp. LoweringContext::K keys on a Function's name: an
// existing function of that name is asked, else a declaration made for the question and erased.
Value *declaredK(LoweringContext &ctx, const Function &F, const Value *at) {
  std::string n = calleeName(F, at);
  unsigned K;
  if (n == F.getName()) {
    K = ctx.K(F);
  } else if (GlobalValue *G = ctx.M.getNamedValue(n); G && isa<Function>(G)) {
    K = ctx.K(*cast<Function>(G));
  } else if (G) {
    // A file-scope object of the libm name (legal in a TU that includes no <math.h>, C17 §7.1.3): K resolves
    // on the name alone (flag, CQ_K, global, default). The object steps aside for the question's
    // declaration and gets its name back.
    std::string keep = G->getName().str();
    G->setName(keep + ".cq.k");
    Function *tmp = Function::Create(F.getFunctionType(), GlobalValue::ExternalLinkage, n, &ctx.M);
    if (tmp->getName() != n)
      internalError("calls: the K question's declaration did not get the libm name @" + n, at);
    K = ctx.K(*tmp);
    tmp->eraseFromParent();
    G->setName(keep);
  } else {
    Function *tmp = Function::Create(F.getFunctionType(), GlobalValue::ExternalLinkage, n, &ctx.M);
    K = ctx.K(*tmp);
    tmp->eraseFromParent();
  }
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), K);
}



// The declared clone of F for CB (rule 27): declared here, called at the builder.
// fields: when given, the result's fields (handles) are returned there and CB is not bound (an arm of an
// indirect call, rule 19: the caller merges them); otherwise CB is bound.
// resolved (cq-sd95, rules 19, 27): CB calls through this classical pointer with no in-module candidate; the
// callee is the registered all-handles clone clone_resolve(fp, kind) (§1.3), F is null.
CallInst *emitDeclaredCall(LoweringContext &ctx, CallBase &CB, Function *Fp, StringRef mask, Value *flag,
                           SmallVectorImpl<Operand> *fields = nullptr, Value *resolved = nullptr) {
  if (!Fp == !resolved)
    internalError("calls: emitDeclaredCall needs exactly one of a declared callee and a resolved pointer", &CB);
  LLVMContext &C = ctx.M.getContext();
  // CR §1.4: a variadic clone is specialised per call-site arity: the declared clone's formals are the
  // call's actuals (fixed and variadic alike, one digit each), its type the actuals' (rule 27 Name).
  if (Fp && !Fp->getFunctionType()->isVarArg() && Fp->arg_size() != CB.arg_size())
    internalError("calls: a declared callee called with another argument count", &CB);
  bool ctl = flag != nullptr;
  SmallVector<Value *, 8> args;
  SmallVector<Operand, 8> ops;
  if (ctl) {
    args.push_back(flag);
    ops.push_back(Operand{flag, true});
  }
  appendActuals(ctx, CB, mask, args, ops);
  Value *K = declaredK(ctx, *Fp, &CB);
  args.push_back(K);
  ops.push_back(Operand{K, false});
  // Rule 27 Results: every result a handle, an i32 per scalar; an aggregate or vector result is the literal
  // struct of its leaves' handles (CR §1.4, rules 25, 26).
  Type *rt = CB.getType();
  SmallVector<Type *, 4> leaves;
  if (rt->isPointerTy())
    unimplemented("calls: awaiting owner ruling: SPEC_ISSUES \"rule 27: a declared clone with a pointer result "
                  "(the provenance of a fat pointer an opaque clone returns)\"",
                  &CB);
  if (isComposite(rt)) {
    leafTypes(rt, leaves, &CB);
    for (Type *l : leaves)
      if (l->isPointerTy())
        unimplemented("calls: awaiting owner ruling: SPEC_ISSUES \"rule 27: a declared clone with a pointer "
                      "result (the provenance of a fat pointer an opaque clone returns)\"",
                      &CB);
    rt = StructType::get(C, SmallVector<Type *, 4>(leaves.size(), handleTy(C)));
  } else if (!rt->isVoidTy()) {
    rt = handleTy(C);
  }
  SmallVector<Type *, 8> ps;
  for (Value *a : args)
    ps.push_back(a->getType());
  FunctionType *FT = FunctionType::get(rt, ps, false);
  CallInst *call;
  if (resolved) {
    report_fatal_error("cq: unimplemented: bus: __cq_clone_resolve (rule 27)", /*gen_crash_diag=*/false);
  } else {
    abi::CloneSpec cs{calleeName(*Fp, &CB), mask.str(), {}, ctl, false, false};
    std::string name = checkedName(cs, &CB);
    Function *D = ctx.M.getFunction(name);
    if (D && D->getFunctionType() != FT)
      internalError("calls: declared clone @" + name + " exists with another type", &CB);
    if (!D)
      D = Function::Create(FT, GlobalValue::ExternalLinkage, name, ctx.M);
    call = ctx.B().CreateCall(D, args);   // C calling convention (rule 27)
  }
  if (!leaves.empty()) {
    // The fields, undone together by the twin <clone>_unc(outs..., args..., K) (U2).
    SmallVector<Operand, 4> fops;
    SmallVector<Value *, 4> outs;
    for (unsigned k = 0; k < leaves.size(); ++k) {
      Value *e = ctx.B().CreateExtractValue(call, {k});
      fops.push_back(Operand{e, true});
      outs.push_back(e);
    }
    SmallVector<bool, 4> tq = ctx.T.fieldMask(&CB, ctx.S);
    if (tq.size() != leaves.size() || !all_of(tq, [](bool q) { return q; }))
      internalError("calls: a declared clone's composite result whose fields taint does not all make quantum", &CB);
    ctx.unc().recordCall(call, outs, {}, {});
    if (fields)
      fields->assign(fops.begin(), fops.end());
    else
      ctx.bindFields(&CB, fops);
  } else if (!CB.getType()->isVoidTy()) {
    // Every result a handle (rule 27); taint agrees for a declared callee.
    if (!ctx.T.isQuantum(&CB, ctx.S))
      internalError("calls: a declared clone's result that taint says is classical", &CB);
    ctx.unc().recordTemplate(call, callRecordSpec(CB.getType()), ops);
    if (fields)
      fields->assign({Operand{call, true}});
    else
      ctx.bind(&CB, call);
  }
  return call;
}

// The mask of a call site from its non-pointer actuals (CR §1.4: one digit per field; an aggregate or vector
// one per scalar leaf, taint's field mask).
std::string siteMask(LoweringContext &ctx, const CallBase &CB) {
  std::string m;
  for (const Use &u : CB.args()) {
    if (u->getType()->isPointerTy())
      internalError("calls: siteMask of a call with a pointer actual (its digits are the callee's T4)", &CB);
    if (isComposite(u->getType()))
      for (bool q : ctx.T.fieldMask(u.get(), ctx.S))
        m.push_back(q ? '1' : '0');
    else
      m.push_back(ctx.T.isQuantum(u.get(), ctx.S) ? '1' : '0');
  }
  return m;
}

// The scalar leaves a use of CB's value reads (CR §1.4 field order): every leaf for CB itself, the leaves under
// an extractvalue's index path.
std::pair<unsigned, unsigned> leafRange(Type *t, ArrayRef<unsigned> idx) {
  unsigned first = 0;
  for (unsigned i : idx) {
    if (auto *st = dyn_cast<StructType>(t)) {
      for (unsigned k = 0; k < i; ++k) {
        SmallVector<Type *, 4> l;
        leafTypes(st->getElementType(k), l, nullptr);
        first += l.size();
      }
      t = st->getElementType(i);
    } else if (auto *a = dyn_cast<ArrayType>(t)) {
      SmallVector<Type *, 4> l;
      leafTypes(a->getElementType(), l, nullptr);
      first += i * unsigned(l.size());
      t = a->getElementType();
    } else {
      internalError("calls: an extractvalue path through a type that is not an aggregate");
    }
  }
  SmallVector<Type *, 4> l;
  leafTypes(t, l, nullptr);
  return {first, unsigned(l.size())};
}

// Does field `leaf` of the call's value need to stay allocated (measured, or escaping an entry as its handle)?
// The arms of an indirect call's merge are then kept (Uncompute U1: a merge is kept only when every arm is),
// otherwise they are garbage.
bool resultKept(LoweringContext &ctx, const Value *v, unsigned leaf, unsigned first = 0) {
  for (const User *u : v->users()) {
    if (auto *uc = dyn_cast<CallBase>(u))
      if (classify(*uc, ctx.T, ctx.S) == Class::Measure)
        return true;
    if (isa<ReturnInst>(u) && ctx.S.isEntry())
      return true;
    if (auto *ev = dyn_cast<ExtractValueInst>(u)) {
      auto [f, n] = leafRange(ev->getAggregateOperand()->getType(), ev->getIndices());
      if (leaf >= first + f && leaf < first + f + n && resultKept(ctx, ev, leaf, first + f))
        return true;
    }
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

  SmallVector<Type *, 8> ps;
  if (S.ctl)
    ps.push_back(handleTy(C));
  for (const FormalLayout &f : formalLayout(T, S, S.F))
    for (unsigned k = 0; k < f.leaves.size(); ++k)
      ps.push_back(f.q[k] ? handleTy(C) : f.leaves[k]);
  ResultLayout rl = resultLayout(T, S, S.F);
  Type *rt = cloneResultType(C, rl, S.F->getReturnType());
  if (fenv::cloneCarriesEnv(T, S)) {
    // E1 (CR rule 23, 82): the caller's mode and flags trail the parameters; the new flags handle is
    // the result's last field: i32 alone for an otherwise void clone, {result, i32} for a scalar result,
    // and for a field-wise result (CR §1.4: its literal struct of leaves, handles where quantum) that
    // struct's fields followed by i32 (cq-xhv4).
    ps.push_back(handleTy(C));
    ps.push_back(handleTy(C));
    if (rl.stores) {
      // With QRAM stores (191): the result's leaves, one handle per store, then the flags: always the struct.
      SmallVector<Type *, 4> es;
      for (unsigned k = 0; k < rl.leaves.size(); ++k)
        es.push_back(rl.q[k] ? handleTy(C) : rl.leaves[k]);
      for (unsigned k = 0; k < rl.stores; ++k)
        es.push_back(handleTy(C));
      es.push_back(handleTy(C));
      rt = StructType::get(C, es);
    } else if (rt->isVoidTy()) {
      rt = handleTy(C);
    } else if (rl.composite && rl.anyQ()) {
      SmallVector<Type *, 4> es(cast<StructType>(rt)->elements());
      es.push_back(handleTy(C));
      rt = StructType::get(C, es);
    } else {
      // A scalar result, or a composite with no quantum leaf (its C type, the spine returns it as it is):
      // {result, flags}.
      rt = StructType::get(C, {rt, handleTy(C)});
    }
  }
  FunctionType *FT = FunctionType::get(rt, ps, false);

  if (Function *ex = M.getFunction(name)) {
    if (ex->getFunctionType() != FT)
      internalError("calls: clone @" + name + " exists with another type", S.F);
    return ex;
  }
  Function *NF = Function::Create(FT, GlobalValue::InternalLinkage, name, &M);
  NF->setCallingConv(S.F->getCallingConv());
  unsigned p = S.ctl ? 1 : 0;
  std::vector<FormalLayout> fl = formalLayout(T, S, S.F);
  for (Argument &A : S.F->args()) {
    // CR §0: x86-64 only; inalloca and preallocated are the 32-bit Windows C++ ABI's.
    if (A.hasInAllocaAttr() || A.hasPreallocatedAttr())
      internalError("calls: an inalloca or preallocated formal (no x86-64 C function has one, CR §0)", &A);
    // cq-utb8 (CR rules 5, 18): a pointer formal the C body never accesses through (readnone) is one the clone and
    // its twin never access either (the lowering accesses only what the C body does): its pointer parameters
    // carry readnone, so a twin's footprint leaves its object out (musl c32rtomb's ps handed to wcrtomb).
    if (A.getType()->isPointerTy() && A.hasAttribute(Attribute::ReadNone))
      for (unsigned k = 0; k < fl[A.getArgNo()].leaves.size(); ++k)
        if (fl[A.getArgNo()].leaves[k]->isPointerTy() && p + k < NF->arg_size() &&
            NF->getArg(p + k)->getType()->isPointerTy())
          NF->addParamAttr(p + k, Attribute::ReadNone);
    // cq-utb8 (C restrict, CR rules 5, 18): a pointer formal the C body names noalias (musl c32rtomb's
    // char *restrict s) crosses as one pointer parameter that keeps it: during the clone, the object it points into
    // is accessed through it alone, never through a pointer the clone or a callee loads (Uncompute::reachable).
    if (A.getType()->isPointerTy() && A.hasNoAliasAttr() && fl[A.getArgNo()].leaves.size() == 1 &&
        p < NF->arg_size() && NF->getArg(p)->getType()->isPointerTy())
      NF->addParamAttr(p, Attribute::NoAlias);
    p += unsigned(fl[A.getArgNo()].leaves.size());
  }
  return NF;
}

// E1 (CR rule 23, 82): the result of a clone carrying the environment. Its last field is the new flags
// handle: the call's outs are the result (when a handle) then the flags, undone together by the twin (U2),
// and the caller's FLAGS become the returned rail (fenv::afterCloneCall).
namespace {
} // namespace

void bindEnvResult(LoweringContext &ctx, CallBase &CB, const Specialization &S, const CloneCall &r) {
  SmallVector<Value *, 4> outs;
  Value *flags = r.value;
  auto finish = [&]() { ctx.unc().recordCall(r.call, outs, {}); };
  if (r.fieldwise) {
    // cq-xhv4: a field-wise result (bindFieldwiseResult's binding) whose last field is the new flags.
    const ResultLayout &res = r.res;
    SmallVector<bool, 4> tq = ctx.T.fieldMask(&CB, ctx.S);
    if (res.cuts.size() > 2)
      tq = res.q;   // cq-0umd: a packed integer result's fields are the callee's (resultQuantum); 85: {tag, idx}
    if (tq.size() != res.q.size() || !std::equal(tq.begin(), tq.end(), res.q.begin()))
      internalError("calls: the clone's result fields and taint's field mask of the call disagree", &CB);
    auto *st = dyn_cast<StructType>(r.call->getType());
    if (!st || st->getNumElements() != res.leaves.size() + 1)
      internalError("calls: a clone carrying the environment whose field-wise result is not {fields..., flags}",
                    &CB);
    SmallVector<Operand, 4> ops;
    for (unsigned k = 0; k < res.leaves.size(); ++k) {
      Value *e = ctx.B().CreateExtractValue(r.call, {k});
      ops.push_back(Operand{e, res.q[k]});
      if (res.q[k])
        outs.push_back(e);
    }
    flags = ctx.B().CreateExtractValue(r.call, {unsigned(res.leaves.size())});
    outs.push_back(flags);
    ctx.bindFields(&CB, ops);
    finish();
    fenv::afterCloneCall(ctx, CB, flags);
    return;
  }
  if (!CB.getType()->isVoidTy()) {
    bool q = ctx.T.isQuantum(&CB, ctx.S);
    if (r.handle != q)
      internalError("calls: the call's result kind and taint's disagree", &CB);
    Value *res = ctx.B().CreateExtractValue(r.call, {0u});
    flags = ctx.B().CreateExtractValue(r.call, {1u});
    if (r.handle)
      outs.push_back(res);
    ctx.bind(&CB, res);
  }
  outs.push_back(flags);
  finish();
  fenv::afterCloneCall(ctx, CB, flags);
}

// ---- INVERSE-UPDATE clones (cq-xivx; CR §1.4 `_inv<c>`, rule 18, rule 6) ------------------------------
//
// A clone that overwrites a caller cell c with a rule-6 bijection f_c of the cell's old value, the old value
// dead in the caller after the call: the caller's rule 6 clean-up of the old rail is the call
// `__cq_q_<fn>_<mask>_inv<c>(args..., old)` (its item, Uncompute U8), then cqrt_free(old). The _inv clone
// loads the cell's new content y', computes f_c^-1 fresh by rule 6's per-instruction inverses
// (spine::inverseStep: sub for add, the odd literal's inverse for mul, fshr for fshl, ...), copies it onto
// the old rail, uncomputes and frees its own rails. c is the cell's position among the call's old cell
// handles (the twin's trailing operands, slot order).
//
// Scope (narrow, owner 2026-11-01). Built: a void or single-result clone call that writes one caller slot
// object through a raw pointer formal, no _ctl; a written integer or floating cell whose callee update is
// one store at a constant cell offset of the formal, outside any cycle and on every path (its block
// post-dominates the entry), of a chain of rule-6 bijections down to a load of the same cell that dominates
// the store, each step's other operands constants or scalar formals. Not a chain of bijections (a step
// rule 6 cannot invert, a value that does not read the old cell): no clean-up, as rule 6 asks. The old rail
// is cleaned only when it is the caller's register (Role::UserRegister; seeds and garbage are rules 7 and
// 5) and provably dead after the call: every original reader of it precedes the call, and it sits in no
// other cell. Unimplemented, with the instruction: coupled cells (a swap: the group `_inv<c>_<c'>`), a
// composite or merged update (127, 125 shapes), an operand the callee computes, two stores to the cell, a
// conditional or looping store, a _ctl clone, a caller that writes the object again after the call, a call
// in a cycle.
namespace {


struct InvChain {
  SmallVector<Instruction *, 4> steps;   // outermost (the stored value) first
  SmallVector<Value *, 4> chainOps;      // the operand of steps[k] that carries the old value
  LoadInst *load = nullptr;              // the load of the old cell content
  StoreInst *store = nullptr;
};







// The caller's old rail h of a cell the call overwrites is dead after the call (CR rule 6 Dead, narrow):
// h is the caller's register, not measured, every original reader of a value bound to h precedes the call,
// and the only store of it is into the very cell the call overwrites. The object is a local whose address
// reaches only loads, stores into it, constant GEPs, lifetime markers and this call.
// cq-p8r6: Dead::Unknown where the narrow test cannot decide (a root that is not a local, an address that
// reaches other users, a copy stored elsewhere) although no reader of h follows the call: its caller stops
// loudly unless the call's twin restores the cell (Uncompute::cleanupUnbuilt).
enum class Dead { No, Yes, Unknown };



// Rule 19 (cq-i9wk, ruling 2026-11-02: the compiler never inlines): a callee with a body reached with no
// quantum argument is called as it is: the call of its in-place lowering (the entry). A quantum result is
// the handle the entry returns (the C return type when it is an integer of 32 bits or more, the handle
// zero-extended; i32 otherwise). When every quantum value the callee returns is FROZEN (a register it
// minted or that register's rule-6 image; spine::entryReturn), the caller keeps the rail like its own
// registers: never uncomputed, never freed (162).
void lowerEntryCall(LoweringContext &ctx, CallBase &CB, const Specialization &cs) {
  for (const Use &u : CB.args())
    if (ctx.operand(u.get()).handle)
      internalError("calls: a quantum argument to a callee with no clone", &CB);
  if (CB.getType()->isVoidTy() || !ctx.T.isQuantum(&CB, ctx.S))
    return ordinaryCall(ctx, CB);
  if (underQuantumPredicate(ctx))
    internalError("calls: an in-place callee reached under a quantum predicate (taint makes it a _ctl clone)", &CB);
  Function &F = *cs.F;
  Type *crt = CB.getType();
  const spine::EntryReturn *er = spine::entryReturn(F);
  if (!er)
    unimplemented("calls: awaiting owner ruling: SPEC_ISSUES rule 19 results of an in-place callee in a cycle of "
                  "in-place calls (its frozen record is made after the call is lowered)",
                  &CB);
  if (!er->frozen)
    report_fatal_error("cq: unimplemented: bus: own-symbol rail result of a callee (rules 18, 19)",
                       /*gen_crash_diag=*/false);
  LLVMContext &C = ctx.M.getContext();
  Type *i32 = Type::getInt32Ty(C);
  Type *rt = er->ret;   // the lowered entry's return type (rule 19: the C one, the i32 handle, or the leaves)
  if (!rt)
    internalError("calls: an in-place callee's return record without its return type", &CB);
  SmallVector<Value *, 8> args;
  for (const Use &u : CB.args())
    args.push_back(ctx.operand(u.get()).v);
  FunctionType *FT = FunctionType::get(rt, F.getFunctionType()->params(), F.isVarArg());
  CallInst *call = ctx.B().CreateCall(FT, &F, args, CB.getName());
  call->setCallingConv(CB.getCallingConv());
  AttributeList AL = CB.getAttributes();
  if (rt != crt)
    AL = AL.removeRetAttributes(C, AttributeMask(AL.getRetAttrs()));
  call->setAttributes(AL);
  auto keep = [&](Value *h) {
    ctx.unc().recordExternal(h, Role::UserRegister);
    spine::shared(ctx).frozenResults.insert(h);
  };
  if (auto *st = dyn_cast<StructType>(rt)) {
    // Rule 26: the literal struct of the leaves; each quantum leaf is a frozen rail, kept.
    if (er->leafQ.size() != st->getNumElements())
      internalError("calls: an in-place callee's aggregate return record does not match its leaves", &CB);
    SmallVector<Operand, 4> ops;
    for (unsigned k = 0; k < st->getNumElements(); ++k) {
      Value *e = ctx.B().CreateExtractValue(call, {k});
      if (er->leafQ[k])
        keep(e);
      ops.push_back(Operand{e, bool(er->leafQ[k])});
    }
    ctx.bindFields(&CB, ops);
    return;
  }
  if (!rt->isIntegerTy() || rt->getIntegerBitWidth() < 32)
    internalError("calls: an in-place callee returning a handle in a return type that cannot hold it", &CB);
  Value *h = rt == i32 ? static_cast<Value *>(call) : ctx.B().CreateTrunc(call, i32);
  keep(h);
  spine::bindOperand(ctx, &CB, Operand{h, true});
}

} // namespace

namespace {
// The binding of a lifted clone call's results (lowerLifted): by the clone's result ABI, its outs recorded as
// one call group undone by the twin (U2), the overflow predicate of a recursion level last (cq-ew5z).
void bindCloneCall(LoweringContext &ctx, CallBase &CB, const Specialization &cs, const CloneCall &r) {
  if (fenv::cloneCarriesEnv(ctx.T, cs))
    return bindEnvResult(ctx, CB, cs, r);
  if (r.fieldwise)
    return bindFieldwiseResult(ctx, CB, r.call, r.res);
  bindResult(ctx, CB, r.call, r.handle, r.ops);
}
} // namespace

void lowerLifted(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
  // Rule 14: a recursive call under a quantum predicate is the one clone with its activation counter.
  if (const Function *G = CB.getCalledFunction(); G && ctx.T.controlTainted(CB.getParent(), ctx.S) && reaches(G, ctx.S.F))
    report_fatal_error("cq: unimplemented: bus: recursion activation counter (rule 14)", /*gen_crash_diag=*/false);
  // An untainted callee or the in-place specialization. Under a quantum predicate (or in a _ctl clone)
  // taint lifted the call to the callee's untainted in-place specialization: classical arguments and
  // no gate in the body (a gate makes a _ctl clone, which taint publishes). Rule 19 (ruling
  // 2026-11-02, cq-fl4n): such a host call stays the host call, executed unguarded, its classical result
  // merged like any classical arm value (rule 9): musl's __math_oflow(0) in exp, __math_divzero(1) in log.
  // A tainted in-place callee reached with no quantum argument is called as it is (rule 19, cq-i9wk).
  if (cs && cs->isEntry())
    return lowerEntryCall(ctx, CB, *cs);
  if (!cs) {
    for (const Use &u : CB.args())
      if (ctx.operand(u.get()).handle)
        internalError("calls: a quantum argument to a callee with no clone", &CB);
    return ordinaryCall(ctx, CB);
  }
  if (cs->F->isDeclaration()) {
    Value *flag = underQuantumPredicate(ctx) ? ctlFlag(ctx, CB) : nullptr;
    emitDeclaredCall(ctx, CB, cs->F, cs->mask, flag);
    return;
  }
  CloneCall r = emitCloneCall(ctx, CB, *cs, nullptr);
  bindCloneCall(ctx, CB, *cs, r);
}


void lowerDeclared(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Function *F = CB.getCalledFunction();
  if (!F || !F->isDeclaration())
    internalError("calls: lowerDeclared of a call that is not a direct call of a declaration", &CB);
  if (any_of(CB.args(), [](const Use &u) { return u->getType()->isPointerTy(); }))
    report_fatal_error("cq: unimplemented: bus: a declared clone with a pointer argument (rule 27)",
                       /*gen_crash_diag=*/false);
  // Rule 27: "a call with no quantum argument stays the ordinary call"; the name's mask is the
  // call site's (CR §1.4 with no _b bounds).
  bool anyQ = false;
  for (const Use &u : CB.args())
    anyQ |= ctx.T.isQuantum(u.get(), ctx.S);
  if (!anyQ)
    return ordinaryCall(ctx, CB);
  std::string mask = siteMask(ctx, CB);
  Value *flag = underQuantumPredicate(ctx) ? ctlFlag(ctx, CB) : nullptr;
  emitDeclaredCall(ctx, CB, F, mask, flag);
}


namespace {



} // namespace



// CR rule 19: a call through a classical function pointer dispatches over the static callee set (taint's
// candidates: the pointer's provenance, else every address-taken function of the call's type): a classical
// chain of pointer-equality tests, each arm calling its candidate as a direct call would (its clone, its _ctl
// clone under the block's quantum predicate, its rule 27 declared clone, or the untainted original); the last
// test's false edge is unreachable (a pointer outside the set is the program's UB). A result field is merged
// by a classical phi (Uncompute::recordMerge for a handle); an arm's classical field of a quantum merged field
// enters as a seed rail (rule 7). The builder is left in the join block.
void lowerIndirect(LoweringContext &, CallBase &) {
  report_fatal_error("cq: unimplemented: bus: lowerTableCall (rule 19)", /*gen_crash_diag=*/false);
}

// CR §1.4, rules 20, 7 (95, 109): the va intrinsics of a variadic clone (per call-site arity, its
// variadic actuals are parameters, spine Shared::varargs). llvm.va_start(ap) is the x86-64 SysV spill:
// a register save area of 6 gp slots of 8 bytes (gp_offset = 8 * the named gp parameters, fp_offset =
// 48) and an empty overflow area; the actuals go to the gp slots after the named ones. When one is
// quantum the area is a slot array of handles (taint's save-area object): a classical actual is
// promoted to a seed rail (rule 7), a quantum one is its handle. -O1's own va_arg code reads the slots
// (lowerVaAreaLoad). va_copy copies the 24-byte va_list; va_end is nothing. Unimplemented: an fp,
// aggregate or wider-than-64-bit actual, more gp arguments than the 6 registers, a named parameter that
// is not one gp register, VAArgInst.
void lowerVarargs(LoweringContext &, Instruction &) {
  report_fatal_error("cq: unimplemented: bus: varargs (rules 16, 22)", /*gen_crash_diag=*/false);
}

SmallVector<Type *, 4> variadicTypes(const TaintInfo &T, const Specialization &S, const Value *at) {
  SmallVector<Type *, 4> out;
  for (const VariadicActual &a : variadicActuals(T, S, at))
    out.push_back(a.ty);
  return out;
}



void lowerAsm(LoweringContext &, CallBase &CB) {
  unimplemented("calls: calls::lowerAsm (inline asm with a quantum operand, rule 27: cq-w3-asm)", &CB);
}

} // namespace cq::calls

namespace cq::calls {

void lowerLiftedVia(LoweringContext &ctx, llvm::CallBase &site, llvm::ArrayRef<unsigned> argMap) {
  capture(ctx);
  const Specialization *cs = ctx.T.calleeSpecialization(site, ctx.S);
  if (!cs)
    internalError("calls: lowerLiftedVia of a call taint gives no callee specialization", &site);
  if (cs->isEntry() || cs->F->isDeclaration())
    internalError("calls: lowerLiftedVia of a call whose callee specialization is not a lifted clone", &site);
  if (argMap.size() != cs->F->arg_size())
    internalError("calls: lowerLiftedVia's argument map does not name one operand per formal", &site);
  Value *flag = cs->ctl ? ctlFlag(ctx, site) : nullptr;
  bool env = fenv::cloneCarriesEnv(ctx.T, *cs);
  CloneCall r = emitCloneCall(ctx, site, *cs, flag, argMap);
  if (r.res.qramFormal)
    unimplemented("calls: lowerLiftedVia of a clone with a triple formal onto a QRAM object (U3: mem-qram's "
                  "store record through an argument map)",
                  &site);
  SmallVector<Value *, 4> outs;
  // E1 (CR rule 23, 82): the start routine takes the creating thread's mode and flags (C17 §7.6: a thread's
  // environment starts as its creator's) and returns its own new flags rail as the result's last field. Its
  // environment is its own: the creator's FLAGS stay as they were (no fenv::afterCloneCall); the returned
  // rail is fenv state the program never reads, undone by the twin with the result (rule 23: twin, free,
  // never kept).
  Value *res = r.value;
  if (env) {
    auto *st = dyn_cast<StructType>(r.call->getType());
    if (st) {
      unsigned last = st->getNumElements() - 1;
      outs.push_back(ctx.B().CreateExtractValue(r.call, {last}));
      if (r.fieldwise) {
        for (unsigned k = 0; k < r.res.leaves.size(); ++k)
          if (r.res.q[k])
            outs.insert(outs.end() - 1, ctx.B().CreateExtractValue(r.call, {k}));
      } else if (r.handle) {
        outs.insert(outs.begin(), ctx.B().CreateExtractValue(r.call, {0u}));
      }
    } else {
      outs.push_back(r.call);   // a void start routine: the flags handle alone
    }
    res = nullptr;
  }
  if (!env && r.fieldwise) {
    for (unsigned k = 0; k < r.res.leaves.size(); ++k)
      if (r.res.q[k])
        outs.push_back(ctx.B().CreateExtractValue(r.call, {k}));
  } else if (!env && r.handle) {
    outs.push_back(res);
  }
  if (outs.empty())
    return;
  ctx.unc().recordCall(r.call, outs, {});
}
} // namespace cq::calls

