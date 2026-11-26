// Module calls (cq-w1-calls): function lifting (rule 18), indirect callees (rule 19) and declared
// clones (rule 27). calls::classify is the spine's; calls::finalize (Finalize.cpp) drops dead
// originals and defines the twins the lowering called.
//
// CONTRACT (Calls.h is frozen, so what its callers may rely on is stated here)
//
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
//  - lowerIndirect(ctx, call): rule 19, always a call of a table clone resolved at run time: a classical pointer through
//    __cq_clone_resolve (null: rule 16's host boundary), an address rail through the dispatch loop over the registered
//    functions of the call's type. The builder is left in the join block.
//  - lowerVarargs: the va intrinsics of a variadic clone (rule 16 block form); lowerAsm waits on
//    CQ_spec's inline-asm example (build step 3, rule 27).
#include "cq/Calls.h"
#include "cq/Order.h"
#include "CallsInternal.h"
#include "../loops/cutoff/Exits.h"

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
#include "../bus/BusInternal.h"

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
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
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"

#include <map>
#include <optional>
#include <string>

using namespace llvm;

namespace cq::calls {

// Rule 18: a function that writes memory (rule 5), measures or reads the result rail of an effect entry has no twin; its
// rail results are KEPT by the caller, which means no twin is called: rule 6 may still clean them (31, 204).
bool hasTwin(const TaintInfo &T, const Specialization &S) {
  return !bus::writesMemory(T, *S.F) && !T.noTwinByEffects(S);
}

namespace {

// The TaintInfo of the current run (see the contract).
std::optional<TaintInfo> runTaint;

void capture(LoweringContext &ctx) {
  runTaint = ctx.T;
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
  abi::CloneSpec cs{S.F->getName().str(), S.mask.empty() ? "v" : S.mask, S.bounds, S.ctl, S.pure, false, S.table, S.rm};
  // cq-7guqg (CR §1.4: two distinct clones whose names would coincide get distinct symbols): the name's `_b` values read
  // onto the quantum integer formals in order. A bound on a later formal (lnchoose_e(n, m) with m bounded, beside a call
  // with n bounded by the same value) is spelled at its own position, each formal before it with no bound of its own
  // taking its type's maximum, a bound that always holds. Without it both specializations materialized one function.
  if (S.boundFormals.size() != S.bounds.size())
    return cs;
  const TaintInfo &T = taintOf(S);
  SmallVector<std::pair<unsigned, unsigned>, 4> qi;   // (formal, width), the reading order
  for (Argument &A : S.F->args())
    if (A.getType()->isIntegerTy() && A.getType()->getIntegerBitWidth() > 1 && is_contained(T.fieldMask(&A, S), true))
      qi.push_back({A.getArgNo(), A.getType()->getIntegerBitWidth()});
  bool inOrder = S.boundFormals.size() <= qi.size();
  for (size_t i = 0; inOrder && i < S.boundFormals.size(); ++i)
    inOrder = S.boundFormals[i] == qi[i].first;
  if (inOrder)
    return cs;
  cs.bounds.clear();
  for (auto [f, w] : qi) {
    if (f > S.boundFormals.back())
      break;
    auto at = find(S.boundFormals, f);
    cs.bounds.push_back(at != S.boundFormals.end() ? S.bounds[at - S.boundFormals.begin()]
                                                   : (w >= 64 ? ~uint64_t(0) : (uint64_t(1) << w) - 1));
  }
  return cs;
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

struct FormalLayout {
  SmallVector<Type *, 4> leaves;
  SmallVector<bool, 4> q;
  bool pointer = false;
  // cq-0umd (rule 26): an integer formal the callee unpacks into fields (159's coerced struct): one
  // leaf per field at spine::unpackCuts, the digits the mask's.
  SmallVector<unsigned, 4> cuts;
  // §1.4: a variadic clone's last formal, the block's classical ptr (digit 0).
  bool variadic = false;
};

std::vector<FormalLayout> formalLayout(const TaintInfo &T, const Specialization &S, const Value *at) {
  std::vector<FormalLayout> fs;
  unsigned need = 0;
  for (Argument &A : S.F->args()) {
    FormalLayout f;
    leafTypes(A.getType(), f.leaves, &A);
    f.q = T.fieldMask(&A, S);
    if (A.getType()->isIntegerTy() && !S.table) {
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
    need += f.leaves.size();
    fs.push_back(std::move(f));
  }
  // CR §1.4: a variadic clone's formals are its fixed formals followed by ONE classical ptr, digit 0: the block.
  if (S.plain && S.F->isVarArg()) {
    FormalLayout f;
    f.variadic = true;
    f.leaves.push_back(PointerType::getUnqual(S.F->getContext()));
    f.q.push_back(false);
    f.pointer = true;
    need += 1;
    fs.push_back(std::move(f));
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
      if (m[d++] != '0')
        internalError("calls: a variadic clone's block digit that is not 0", at);
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
  // cq-0umd: an integer result packed from fields (159): its field boundaries (composite = true).
  SmallVector<unsigned, 4> cuts;
  // cq-0umd (166): an aggregate result with a packed integer leaf: the fields per leaf (the leaves are
  // then the fields, a packed leaf split); empty when every leaf is one field.
  SmallVector<unsigned, 4> leafFields;
  // Rule 19: the registers a by-name clone returns after its results.
  unsigned extras = 0;
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
  // §1.4: a table clone's ABI follows from the C signature alone; rule 19: an own symbol's integer result is one handle
  // (cq-stmvu), and the _pure clone its twin recomputes through has its layout.
  bool packed = !S.table && !(rt->isIntegerTy() && S.wholeIntResult()) && packedIntegerResult(*S.F);
  if (packed && !rt->isIntegerTy()) {
    // cq-0umd (166, rule 26): a leaf packed from fields (the coerced inner struct) crosses as its fields.
    for (const SmallVector<unsigned, 4> &c : spine::resultLeafCuts(*S.F))
      r.leafFields.push_back(c.size() > 2 ? unsigned(c.size() - 1) : 1u);
  } else if (packed) {
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
  for (unsigned k = 0; k < r.leaves.size(); ++k)
    r.q.push_back(T.resultQuantum(S, k));
  if (!S.table)
    r.extras = unsigned(mintSites(T, S).size());
  return r;
}

Type *cloneResultType(LLVMContext &C, const ResultLayout &r, Type *orig) {
  if (r.extras) {
    SmallVector<Type *, 4> es;
    for (unsigned k = 0; k < r.leaves.size(); ++k)
      es.push_back(r.q[k] ? handleTy(C) : r.leaves[k]);
    es.append(r.extras, handleTy(C));
    return StructType::get(C, es);
  }
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

// CR rules 2, 7: an actual whose rail was measured at a point dominating the call denotes the classical
// outcome (rule 2), while the clone's mask digit, fixed by taint for every call site of the clone, is
// quantum. The clone takes a handle there: the outcome minted as a seed rail alloc_<W>(v) (rule 7: a rail
// minted from a classical value and never written, freed directly once its last reader, the call and its
// twin, has run).
Operand seedActual(LoweringContext &ctx, const Operand &o) {
  if (o.handle)
    return o;
  Value *v = o.v;
  if (v->getType()->isPointerTy())
    v = ctx.B().CreatePtrToInt(v, Type::getInt64Ty(ctx.M.getContext()));   // rule 27: alloc_i64 of its address
  CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(v->getType())}, {v});
  ctx.unc().recordSeed(seed);
  return Operand{seed, true};
}

// Rules 2, 18: does clone S measure its by-value rail formal `idx` itself: a cq_measure of the formal, or a call that hands it
// to a clone that does, on every path of S from its entry to a return (what lowerMeasure asks; otherwise S measures a basis
// copy and the actual stays as it was). A _ctl clone measures a controlled copy (rule 19), so never.
bool measuresFormal(const TaintInfo &T, const Specialization &S, unsigned idx, SmallPtrSetImpl<const Specialization *> &onStack) {
  if (S.ctl || S.F->isDeclaration() || idx >= S.F->arg_size() || !T.formalMayReachMeasure(*S.F, idx) ||
      !onStack.insert(&S).second)
    return false;
  const Argument *A = S.F->getArg(idx);
  SmallVector<const Value *, 4> views{A};
  bool found = false;
  while (!views.empty() && !found) {
    const Value *v = views.pop_back_val();
    for (const Use &U : v->uses()) {
      if (isa<FreezeInst>(U.getUser())) {
        views.push_back(U.getUser());
        continue;
      }
      auto *CB = dyn_cast<CallBase>(U.getUser());
      const Function *G = CB && CB->isArgOperand(&U) ? CB->getCalledFunction() : nullptr;
      if (!G)
        continue;
      if (G->isDeclaration()) {
        found = G->getName().starts_with("cq_measure_") && spine::measuredOnEveryPath(T, S, A);
      } else if (const Specialization *C = T.calleeSpecialization(*CB, S)) {
        found = measuresFormal(T, *C, CB->getArgOperandNo(&U), onStack) && spine::measuredOnEveryPath(T, S, A, CB);
      }
      if (found)
        break;
    }
  }
  onStack.erase(&S);
  return found;
}

// Rules 2, 5, 18: an actual the clone measures itself is the caller's measured rail from the call on: it stays allocated, no
// gate touches it and nothing frees it. Measured on some classical paths of the caller only, it is lowered as unmeasured (rule 2,
// collapse is static), so the clone gets a kept basis copy of it, as lowerMeasure does (rule 18's partial-measurement copy).
// A table clone always copies (cq-t2jj2): the rail may be its formal, which is the caller's.
Operand measuredActual(LoweringContext &ctx, const CallBase &CB, unsigned arg, const Value *a, Operand o, bool seeded) {
  if (seeded || (!ctx.S.table && spine::measuredOnEveryPath(ctx, a, &CB))) {
    ctx.unc().setRole(ctx.unc().idOf(o.v), Role::Measured);
    return o;
  }
  RailType w = railTypeOf(a->getType());
  CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
  ctx.unc().recordExternal(c, Role::Measured);
  CallInst *cp = ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {o.v, c});
  if (ctx.S.table)
    noteMeasuredCopy(ctx, CB, arg, c, cp);
  return Operand{c, true};
}

// The fields of a non-pointer actual (CR §1.4: a scalar is one field; an aggregate or vector one per scalar
// leaf, rules 25, 26, flattened depth first).
SmallVector<Operand, 4> actualFields(LoweringContext &ctx, const Value *a) {
  if (isComposite(a->getType()))
    return aggr::flattenResult(ctx, a);
  return {ctx.operand(a)};
}

// One rail result of a clone call: the twin's record (the twin's ABI is a template's _unc), a load for rule 5 when the
// clone loads from the bus; no twin: KEPT.
void recordResult(LoweringContext &ctx, CallInst *call, CallBase &CB, const Specialization &cs, ArrayRef<Operand> ops) {
  if (!hasTwin(ctx.T, cs)) {
    ctx.unc().recordExternal(call, Role::Kept);
    return;
  }
  RailId r = ctx.unc().recordTemplate(call, callRecordSpec(CB.getType()), ops);
  if (ctx.T.loadsBus(cs))
    ctx.unc().noteLoadsBus(r);
}

// Binds CB's result to the lowered call's result and records a quantum result (see the contract).
void bindResult(LoweringContext &ctx, CallBase &CB, CallInst *call, bool handle, const Specialization &cs,
                ArrayRef<Operand> ops) {
  if (CB.getType()->isVoidTy())
    return;
  bool q = ctx.T.isQuantum(&CB, ctx.S);
  if (handle != q)
    internalError(std::string("calls: the call's result is ") + (handle ? "a handle" : "classical") +
                      " but taint says the value is " + (q ? "quantum" : "classical"),
                  &CB);
  if (handle)
    recordResult(ctx, call, CB, cs, ops);
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





// Rule 26 byval: right before the call, after its other arguments: q = __cq_alloc(size, align), a rule-22 bus copy of
// size bytes from the actual (_controlled under the predicate in scope, like the call); q is a plain ptr.
Value *byvalCopy(LoweringContext &ctx, CallBase &CB, unsigned i) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *I64 = Type::getInt64Ty(ctx.M.getContext());
  Type *T = CB.getParamByValType(i);
  uint64_t size = DL.getTypeAllocSize(T);
  MaybeAlign al = CB.getParamAlign(i);
  uint64_t align = al ? al->value() : DL.getABITypeAlign(T).value();
  CallInst *q = ctx.B().CreateCall(abi::declareHost(ctx.M, abi::Host::Alloc),
                                   {ConstantInt::get(I64, size), ConstantInt::get(I64, align)});
  bus::lowerCopy(ctx, Operand{ctx.B().CreatePtrToInt(q, I64), false}, bus::address(ctx, CB.getArgOperand(i)),
                 Operand{ConstantInt::get(I64, size), false}, bus::accessControl(ctx), CB);
  return q;
}

// Rule 16 Variadic calls: every variadic argument stored into a __cq_alloc block in the SysV overflow-area layout (in
// order, 8-byte slots at the promoted type, 16-byte-aligned types in 16), kept stores (rule 5) under the predicate in
// scope; a byval actual is its bytes, by rule 22's copy.
Value *variadicBlock(LoweringContext &ctx, CallBase &CB, unsigned fixed) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *I64 = Type::getInt64Ty(ctx.M.getContext());
  struct Slot { unsigned arg; uint64_t off; uint64_t size; };
  SmallVector<Slot, 8> slots;
  uint64_t off = 0;
  for (unsigned i = fixed; i < CB.arg_size(); ++i) {
    Type *t = CB.isByValArgument(i) ? CB.getParamByValType(i) : CB.getArgOperand(i)->getType();
    uint64_t size = DL.getTypeAllocSize(t);
    uint64_t align = DL.getABITypeAlign(t).value();
    if (CB.isByValArgument(i))
      if (MaybeAlign al = CB.getParamAlign(i))
        align = al->value();
    off = alignTo(off, align > 8 ? align : 8);
    slots.push_back({i, off, size});
    off += alignTo(size, 8);
  }
  CallInst *block = ctx.B().CreateCall(abi::declareHost(ctx.M, abi::Host::Alloc),
                                       {ConstantInt::get(I64, off), ConstantInt::get(I64, 16)});
  Operand base{ctx.B().CreatePtrToInt(block, I64), false};
  for (const Slot &sl : slots) {
    Operand at = bus::offsetAddress(ctx, base, sl.off);
    const Value *a = CB.getArgOperand(sl.arg);
    if (CB.isByValArgument(sl.arg)) {
      bus::lowerCopy(ctx, at, bus::address(ctx, a), Operand{ConstantInt::get(I64, sl.size), false}, bus::accessControl(ctx), CB);
      continue;
    }
    Type *t = a->getType();
    if (!isComposite(t)) {
      bus::emitKeptStore(ctx, t, at, ctx.operand(a), bus::storesData(a));
      continue;
    }
    SmallVector<bus::Leaf, 4> leaves;
    bus::scalarLeaves(DL, t, 0, leaves);
    SmallVector<Operand, 4> fields = aggr::flattenResult(ctx, a);
    if (fields.size() != leaves.size())
      internalError("calls: a variadic actual whose fields are not its scalar leaves", &CB);
    for (unsigned k = 0; k < leaves.size(); ++k)
      bus::emitKeptStore(ctx, leaves[k].type, bus::offsetAddress(ctx, at, leaves[k].offset), fields[k],
                         !leaves[k].type->isPointerTy() && bus::storesData(a));
  }
  return block;
}

// cq-729s6 (CR §1.4, rule 26): a field taint reads as classical of an integer actual the caller holds as one rail
// (x & 1 into a formal unpacked at bytes): the bits `need` of v recomputed classically, along taint's lane rules
// (Taint.cpp transferBinary / transferCast / transferSelect), from the classical values they come from. Bits outside
// `need` are 0.
Value *classicalBits(LoweringContext &ctx, const Value *v, const APInt &need, const Value *at) {
  using namespace PatternMatch;
  IRBuilder<> &B = ctx.B();
  if (need.isZero())
    return ConstantInt::get(v->getType(), 0);
  if (!spine::isQ(ctx, v)) {
    Operand o = ctx.operand(v);
    if (o.handle)
      internalError("calls: a classical value bound to a rail", at);
    return o.v;
  }
  unsigned W = need.getBitWidth();
  auto *I = dyn_cast<Instruction>(v);
  const APInt *C;
  auto ev = [&](unsigned k, const APInt &m) { return classicalBits(ctx, I->getOperand(k), m, at); };
  if (I && (I->getOpcode() == Instruction::And || I->getOpcode() == Instruction::Or ||
            I->getOpcode() == Instruction::Xor)) {
    // The bits a literal operand fixes (and 0, or 1) do not read the other operand.
    APInt m = need;
    if (match(I->getOperand(1), m_APInt(C)))
      m = I->getOpcode() == Instruction::And ? need & *C : I->getOpcode() == Instruction::Or ? need & ~*C : need;
    return B.CreateBinOp(Instruction::BinaryOps(I->getOpcode()), ev(0, m), ev(1, m));
  }
  if (I && match(I, m_Shl(m_Value(), m_APInt(C))) && C->ult(W))
    return B.CreateShl(ev(0, need.lshr(*C)), *C);
  if (I && (match(I, m_LShr(m_Value(), m_APInt(C))) || match(I, m_AShr(m_Value(), m_APInt(C)))) && C->ult(W)) {
    APInt m = need.shl(*C);
    unsigned c = unsigned(C->getZExtValue());
    if (I->getOpcode() == Instruction::AShr && !need.extractBits(c, W - c).isZero())
      m.setBit(W - 1);   // the bits shifted in are the sign's
    return B.CreateBinOp(Instruction::BinaryOps(I->getOpcode()), ev(0, m), ConstantInt::get(v->getType(), *C));
  }
  if (I && (isa<ZExtInst>(I) || isa<SExtInst>(I)) && I->getType()->isIntegerTy()) {
    unsigned M = I->getOperand(0)->getType()->getIntegerBitWidth();
    APInt m = need.trunc(M);
    if (isa<SExtInst>(I) && !need.extractBits(W - M, M).isZero())
      m.setBit(M - 1);
    return B.CreateCast(Instruction::CastOps(I->getOpcode()), ev(0, m), v->getType());
  }
  if (I && isa<TruncInst>(I) && I->getType()->isIntegerTy())
    return B.CreateTrunc(ev(0, need.zext(I->getOperand(0)->getType()->getIntegerBitWidth())), v->getType());
  if (isa_and_nonnull<SelectInst>(I))
    return B.CreateSelect(ev(0, APInt(1, 1)), ev(1, need), ev(2, need));
  if (I && isa<FreezeInst>(I))
    return ev(0, need);
  internalError("calls: a field of a rail actual whose mask digit is classical, through an instruction taint "
                "keeps whole",
                at);
}

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
  // names one operand per formal (lowerLiftedVia). A variadic clone's last formal is the block.
  unsigned nFixed = S.plain && S.F->isVarArg() ? unsigned(fs.size()) - 1 : unsigned(fs.size());
  if (S.plain && S.F->isVarArg() ? nArgs < nFixed : nArgs != nFixed)
    internalError("calls: a call whose argument count differs from the clone's formals", &CB);
  SmallVector<std::pair<unsigned, unsigned>, 2> byvals;   // (args index, actual index): made last (rule 26)
  for (unsigned i = 0; i < nFixed; ++i) {
    const Value *a = CB.getArgOperand(op(i));
    if (S.plain && CB.isByValArgument(op(i))) {
      byvals.push_back({unsigned(args.size()), op(i)});
      args.push_back(nullptr);
      r.ops.push_back(Operand{nullptr, false});
      continue;
    }
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
      if (!fs[i].q[k] && o.handle && fs[i].cuts.size() > 2) {
        // Taint's lanes keep this field classical though the actual is held as a rail (cq-729s6).
        unsigned lo = fs[i].cuts[k], hi = fs[i].cuts[k + 1], W = fs[i].cuts.back();
        Value *bits = classicalBits(ctx, a, APInt::getBitsSet(W, lo, hi), &CB);
        o = Operand{ctx.B().CreateTrunc(ctx.B().CreateLShr(bits, lo), fs[i].leaves[k]), false};
      }
      bool seeded = fs[i].q[k] && !o.handle;
      if (fs[i].q[k])
        o = seedActual(ctx, o);
      if (fs[i].q[k] && leaves.size() == 1 && !isComposite(a->getType())) {
        SmallPtrSet<const Specialization *, 8> onStack;
        if (measuresFormal(ctx.T, S, i, onStack))
          o = measuredActual(ctx, CB, i, a, o, seeded);
      }
      if (!fs[i].q[k] && o.handle)
        internalError("calls: a rail passed where the clone's mask is classical", &CB);
      args.push_back(o.v);
      r.ops.push_back(Operand{o.v, o.handle});
    }
  }
  for (auto [at, i] : byvals) {
    Value *q = byvalCopy(ctx, CB, i);
    args[at] = q;
    r.ops[at] = Operand{q, false};
  }
  if (S.plain && S.F->isVarArg()) {
    Value *block = variadicBlock(ctx, CB, nFixed);
    args.push_back(block);
    r.ops.push_back(Operand{block, false});
  }
  if (fenv::cloneTakesMode(ctx.T, S)) {
    // CR §1.4, rule 23 (owner 2026-11-12, cq-a9ij3): _rm / _rmq, the caller's mode trails the formals' fields.
    Operand m = fenv::modeArg(ctx, CB, S);
    args.push_back(m.v);
    r.ops.push_back(m);
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
  // Rule 26: `sret` stays on the formal and the call, an ABI note.
  for (unsigned p = 0; p < C->arg_size(); ++p)
    if (C->hasParamAttribute(p, Attribute::StructRet))
      r.call->addParamAttr(p, C->getParamAttribute(p, Attribute::StructRet));
  r.handle = !S.F->getReturnType()->isVoidTy() && !r.res.composite && r.res.anyQ() && !r.res.extras;
  r.fieldwise = r.res.composite && r.res.anyQ() && !r.res.extras;
  r.value = r.call;
  return r;
}

// Binds a field-wise result (CR §1.4: a literal struct of handles and classical values): one
// extractvalue per field right after the call, the field operands bound to CB (aggr reads them), and
// the handles recorded as the call's results, undone together by the twin (U2).
void bindFieldwiseResult(LoweringContext &ctx, CallBase &CB, CallInst *call, const ResultLayout &res,
                         const Specialization &cs) {
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
  if (hasTwin(ctx.T, cs)) {
    ctx.unc().recordCall(call, outs, {}, ctx.T.loadsBus(cs));
  } else {
    for (Value *h : outs)
      ctx.unc().recordExternal(h, Role::Kept);   // rule 18: no twin
  }
  if (!res.leafFields.empty())
    aggr::bindLeafFields(ctx, &CB, ops, res.leafFields);   // 166: a packed leaf's fields
  else
    ctx.bindFields(&CB, ops);
}


// Rule 27: the trailing i32 K of a declared clone is the callee's K (flag, CQ_K, global, default 4),
// resolved on the callee's C name (cq-h8vd): an LLVM math intrinsic's callee is the libm function
// (rule 18), so llvm.exp.f64 resolves as exp. LoweringContext::K keys on a Function's name: an
// existing function of that name is asked, else a declaration made for the question and erased.
Value *declaredK(LoweringContext &ctx, const Function &F, const Value *at) {
  if (ctx.S.table)
    return spine::shared(ctx).tableK;   // rule 27: calls inside a table clone pass the received K down
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
  // Owner ruling Q2 (CR 1.4 "Received K", rule 27 "Cutoff"): in a function a table clone reaches by name, the K received
  // through @__cq_k is passed down, in place of the callee's own unless it is all ones (owner 2026-11-15).
  if (Value *r = loops::exits::receivedKBelow(ctx, K))
    return r;
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), K);
}



// Rule 27: the declared clone of F for CB, a table clone of §1.4: __cq_q_<fn>_<mask>_t[_ctl]([pred,] actuals…, K), the mask
// the call's arrangement selects (a classical actual at a digit 1 a seed, a classical pointer alloc_i64 of its address; at a
// digit 0 its C value), every result a handle,
// the C calling convention. The call is a memory version change. Its twin frees the results (rule 19), called exactly
// once at its rule-18 position; with no result right after the call.
void emitDeclaredCall(LoweringContext &ctx, CallBase &CB, Function *Fp, Value *flag) {
  LLVMContext &C = ctx.M.getContext();
  SmallVector<Value *, 8> args;
  SmallVector<Operand, 8> ops;
  if (flag) {
    args.push_back(flag);
    ops.push_back(Operand{flag, true});
  }
  // Owner ruling 2026-11-20: the library exports the arrangements tableMasks gives Fp's C signature; the call takes the
  // one with the fewest quantum digits covering its rails (declaredMask). A classical actual at a digit 0 crosses as its C
  // value, at a digit 1 as a seed (rule 7). A variadic callee's further actuals go into rule 16's block, its digit 0.
  FunctionType *CT = Fp->getFunctionType();
  unsigned nFixed = CT->getNumParams();
  if (CB.arg_size() < nFixed)
    internalError("calls: a declared clone's call with fewer actuals than the callee's fixed formals", &CB);
  SmallVector<Operand, 8> fields;
  SmallVector<bool, 8> quantum;
  for (unsigned i = 0; i < nFixed; ++i)
    for (const Operand &o : actualFields(ctx, CB.getArgOperand(i))) {
      fields.push_back(o);
      quantum.push_back(o.handle);
    }
  bool blockRail = false;   // rule 27: a variadic rail with every fixed actual classical takes the all-ones mask
  for (unsigned i = nFixed; i < CB.arg_size(); ++i)
    blockRail = blockRail || ctx.T.isQuantum(CB.getArgOperand(i), ctx.S);
  std::string mask = declaredMask(CT, quantum, blockRail);
  for (unsigned i = 0; i < fields.size(); ++i) {
    Operand o = mask[i] == '1' ? seedActual(ctx, fields[i]) : fields[i];
    args.push_back(o.v);
    ops.push_back(o);
  }
  if (CT->isVarArg()) {
    Value *block = variadicBlock(ctx, CB, nFixed);
    args.push_back(block);
    ops.push_back(Operand{block, false});
  }
  Value *K = declaredK(ctx, *Fp, &CB);
  args.push_back(K);
  ops.push_back(Operand{K, false});
  Type *rt = CB.getType();
  SmallVector<Type *, 4> leaves;
  if (isComposite(rt)) {
    leafTypes(rt, leaves, &CB);
    rt = StructType::get(C, SmallVector<Type *, 4>(leaves.size(), handleTy(C)));
  } else if (!rt->isVoidTy()) {
    rt = handleTy(C);
  }
  SmallVector<Type *, 8> ps;
  for (Value *a : args)
    ps.push_back(a->getType());
  FunctionType *FT = FunctionType::get(rt, ps, false);
  abi::CloneSpec cs{calleeName(*Fp, &CB), mask.empty() ? "v" : mask, {}, flag != nullptr, false, false, true};
  std::string name = abi::name(cs);
  Function *D = ctx.M.getFunction(name);
  if (D && D->getFunctionType() != FT)
    internalError("calls: declared clone @" + name + " exists with another type", &CB);
  if (!D)
    D = Function::Create(FT, GlobalValue::ExternalLinkage, name, ctx.M);
  CallInst *call = ctx.B().CreateCall(D, args);
  if (rt->isVoidTy()) {
    FunctionType *TT = FunctionType::get(Type::getVoidTy(C), ps, false);
    FunctionCallee twin = ctx.M.getOrInsertFunction(name + "_unc", TT);
    CallInst *u = ctx.B().CreateCall(twin, args);
    for (const Operand &o : ops)
      if (o.handle)
        ctx.unc().noteUse(ctx.unc().idOf(o.v), u);
    return;
  }
  SmallVector<Value *, 4> outs;
  SmallVector<Operand, 4> fops;
  SmallVector<RailType, 4> widths;
  if (leaves.empty()) {
    outs.push_back(call);
    fops.push_back(Operand{call, true});
    widths.push_back(railTypeOf(CB.getType()));
  } else {
    for (unsigned k = 0; k < leaves.size(); ++k) {
      Value *e = ctx.B().CreateExtractValue(call, {k});
      outs.push_back(e);
      fops.push_back(Operand{e, true});
      widths.push_back(railTypeOf(leaves[k]));
    }
  }
  ctx.unc().recordTableCall(call, outs, widths);
  if (leaves.empty())
    ctx.bind(&CB, call);
  else
    ctx.bindFields(&CB, fops);
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
            if (!hostCallee(*Y) && seen.insert(Y).second)
              work.push_back(Y);
          }
  }
  return false;
}






} // namespace



// ---- The clone table (rule 19, §1.4) ---------------------------------------------------------------------------------

namespace {
// One row per function with a table clone, in the order of the run's specializations. The function type and the twin
// facts are read here, while S.F is the original and the run's TaintInfo in hand: the row is emitted by finalize, after
// the lowered own symbols replaced the originals.
std::map<const Module *, std::vector<TableRow>> tableRows;

// §1.4 (ruling cq-t2jj2, CQ_spec 96c7bc5): in a table clone with no predicate a cq_measure of a formal measures a kept copy t
// that stays allocated and is not pushed. A twin would have to re-read t (rule 2 never measures again) and has no handle of it,
// so such a clone has no rule-18 twin: its twin only pops and its results stay allocated (211's __cq_q_peek_1_t_unc). The same
// holds for a by-name callee that measures the formal on every path: _t hands it such a copy (measuredActual).
bool measuresFormalCopy(const TaintInfo &T, const Specialization &S) {
  if (!S.table || S.ctl || S.F->isDeclaration())
    return false;
  for (const Argument &A : S.F->args()) {
    SmallVector<const Value *, 4> views{&A};
    while (!views.empty()) {
      const Value *v = views.pop_back_val();
      for (const Use &U : v->uses()) {
        if (isa<FreezeInst>(U.getUser())) {
          views.push_back(U.getUser());
          continue;
        }
        auto *CB = dyn_cast<CallBase>(U.getUser());
        const Function *G = CB && CB->isArgOperand(&U) ? CB->getCalledFunction() : nullptr;
        if (!G)
          continue;
        if (G->isDeclaration()) {
          if (G->getName().starts_with("cq_measure_") && T.isQuantum(v, S))
            return true;
        } else if (const Specialization *C = T.calleeSpecialization(*CB, S)) {
          SmallPtrSet<const Specialization *, 8> onStack;
          if (measuresFormal(T, *C, CB->getArgOperandNo(&U), onStack))
            return true;
        }
      }
    }
  }
  return false;
}

// §1.4: a table clone's twin does nothing but count and pop when rule 18 gives it none: a tainted measurement, which is every
// measurement in a _ctl clone (rule 19's controlled copy), itself or in a callee by name, or a measurement of a formal in the clone
// with no predicate (measuresFormalCopy). Any other measurement on a classical path of the clone with no predicate keeps its
// rule-18 twin; the outcome's seed stays allocated (rule 2, Finalize's defineTwin).
bool tableKeepsResults(const TaintInfo &T, const Specialization &S) {
  if (!hasTwin(T, S))
    return true;
  if (!S.ctl)
    return measuresFormalCopy(T, S);
  SmallPtrSet<const Function *, 8> seen{S.F};
  SmallVector<const Function *, 8> work{S.F};
  while (!work.empty()) {
    const Function *X = work.pop_back_val();
    for (const BasicBlock &BB : *X)
      for (const Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (const Function *G = CB->getCalledFunction()) {
            if (G->isDeclaration() && G->getName().starts_with("cq_measure_"))
              return true;
            if (!hostCallee(*G) && seen.insert(G).second)
              work.push_back(G);
          }
  }
  return false;
}

// F's body rotates, itself or through a callee by name.
static bool rotatesWalk(const Function &F) {
  SmallPtrSet<const Function *, 8> seen{&F};
  SmallVector<const Function *, 8> work{&F};
  while (!work.empty()) {
    const Function *X = work.pop_back_val();
    for (const Instruction &I : instructions(*X))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (const Function *G = CB->getCalledFunction()) {
          if (G->getName().starts_with("cq_theta_"))
            return true;
          if (!hostCallee(*G) && seen.insert(G).second)
            work.push_back(G);
        }
  }
  return false;
}

// rotatesWalk, kept per function for one module's constructions (keyed as mintSites keys its memo, whose answers already
// rest on this one): every query asks about an original body, and no construct() edits one (an entry's lowered body
// replaces it after the last construct(), spine finishEntries; calls::finalize runs after that and asks nothing here).
bool rotates(const TaintInfo &T, const Function &F) {
  static thread_local struct {
    const Module *M = nullptr;
    const void *specs = nullptr;
    DenseMap<const Function *, bool> m;
  } memo;
  if (memo.M != F.getParent() || memo.specs != T.specializations().data()) {
    memo.M = F.getParent();
    memo.specs = T.specializations().data();
    memo.m.clear();
  }
  auto [it, fresh] = memo.m.try_emplace(&F, false);
  if (fresh)
    it->second = rotatesWalk(F);
  return it->second;
}

// §1.4 with rule 18's no-twin case (rulings3 F): a table clone that rotates and whose twin only pops. Its registers may be minted
// per trip, on any path, between a loop's pushes and its reverse loop's pops, so the clone lists them in its frame and pushes them
// at its return, the count on top; the twin pops the count, then the handles.
bool tablePopsMints(const TaintInfo &T, const Specialization &S) {
  return S.table && !S.pure && tableKeepsResults(T, S) && rotates(T, *S.F);
}

constexpr const char *mintHeadName = "cq.mints";

Value *mintHead(LoweringContext &ctx) {
  Function &F = ctx.out();
  if (Value *h = F.getValueSymbolTable()->lookup(mintHeadName))
    return h;
  IRBuilder<> B(&F.getEntryBlock(), F.getEntryBlock().begin());
  PointerType *ptr = PointerType::getUnqual(ctx.M.getContext());
  AllocaInst *h = B.CreateAlloca(ptr, nullptr, mintHeadName);
  B.CreateStore(ConstantPointerNull::get(ptr), h);
  return h;
}

// One node {handle, next} of the frame's list.
void listMint(LoweringContext &ctx, Value *handle) {
  LLVMContext &C = ctx.M.getContext();
  Type *i32 = Type::getInt32Ty(C);
  PointerType *ptr = PointerType::getUnqual(C);
  StructType *node = StructType::get(i32, ptr);
  Value *head = mintHead(ctx);
  IRBuilder<> &B = ctx.B();
  Value *n = B.CreateAlloca(node);
  B.CreateStore(handle, B.CreateStructGEP(node, n, 0));
  B.CreateStore(B.CreateLoad(ptr, head), B.CreateStructGEP(node, n, 1));
  B.CreateStore(n, head);
}

// internal @__cq_mints_push(list): pushes every handle of the list, then their count.
Function *mintsPush(Module &M) {
  constexpr const char *name = "__cq_mints_push";
  if (Function *f = M.getFunction(name))
    return f;
  LLVMContext &C = M.getContext();
  Type *i32 = Type::getInt32Ty(C);
  PointerType *ptr = PointerType::getUnqual(C);
  StructType *node = StructType::get(i32, ptr);
  Function *f = Function::Create(FunctionType::get(Type::getVoidTy(C), {ptr}, false), GlobalValue::InternalLinkage, name, &M);
  BasicBlock *entry = BasicBlock::Create(C, "", f), *head = BasicBlock::Create(C, "", f), *body = BasicBlock::Create(C, "", f),
             *done = BasicBlock::Create(C, "", f);
  FunctionCallee push = abi::declare(M, abi::CoreSpec{abi::Core::Push});
  IRBuilder<> B(entry);
  B.CreateBr(head);
  B.SetInsertPoint(head);
  PHINode *p = B.CreatePHI(ptr, 2);
  PHINode *n = B.CreatePHI(i32, 2);
  p->addIncoming(f->getArg(0), entry);
  n->addIncoming(ConstantInt::get(i32, 0), entry);
  B.CreateCondBr(B.CreateIsNull(p), done, body);
  B.SetInsertPoint(body);
  B.CreateCall(push, {B.CreateLoad(i32, B.CreateStructGEP(node, p, 0))});
  p->addIncoming(B.CreateLoad(ptr, B.CreateStructGEP(node, p, 1)), body);
  n->addIncoming(B.CreateAdd(n, ConstantInt::get(i32, 1)), body);
  B.CreateBr(head);
  B.SetInsertPoint(done);
  B.CreateCall(push, {n});
  B.CreateRetVoid();
  return f;
}

DenseMap<const Function *, unsigned> mintCounts;

void noteTableClone(Module &M, const TaintInfo &T, const Specialization &S, const abi::CloneSpec &cs) {
  std::vector<TableRow> &rows = tableRows[&M];
  abi::CloneSpec fwd = cs;
  fwd.ctl = false;
  std::string fwdName = abi::name(fwd);
  auto it = find_if(rows, [&](const TableRow &r) { return r.forward == fwdName; });
  if (it == rows.end()) {
    rows.push_back(TableRow{cs.fn, S.F->getFunctionType(), {}, {}});
    // Every digit 1 but a variadic function's block digit: the clone of the function's row (§1.4).
    StringRef digits = StringRef(cs.mask).drop_back(S.F->isVarArg() ? 1 : 0);
    rows.back().registered = cs.mask == "v" || digits.find('0') == StringRef::npos;
    abi::CloneSpec f = cs;
    f.ctl = false;
    rows.back().forward = abi::name(f);
    f.ctl = true;
    rows.back().ctl = abi::name(f);
    it = std::prev(rows.end());
  }
  (S.ctl ? it->ctlKeepsResults : it->forwardKeepsResults) = tableKeepsResults(T, S);
  (S.ctl ? it->ctlPopsMints : it->forwardPopsMints) = tablePopsMints(T, S);
  it->exported = T.exportedRoot(*S.F);
  it->hostOwn = T.hostRoot(*S.F);
}
} // namespace

namespace {
// A slot's sub from here up is a measured copy of the call's formal (sub - kMeasuredCopy), not a register the callee hands back.
constexpr unsigned kMeasuredCopy = 1u << 16;
std::map<std::tuple<const Function *, const CallBase *, unsigned>, Value *> measuredCopies;
// The rails a call hands back for the caller's twin, in slot order, per the clone being lowered.
std::map<std::pair<const Function *, const CallBase *>, SmallVector<Value *, 2>> callRegisters;

// Rule 19: a call whose callee rotates carries its slots' indices for the twin (Finalize's replay).
void tagRegisterCall(LoweringContext &ctx, CallBase &CB, CallInst *call, bool ownSymbol) {
  ArrayRef<MintSlot> slots = mintSites(ctx.T, ctx.S);
  auto at = find_if(slots, [&](const MintSlot &m) { return m.site == &CB && m.sub < kMeasuredCopy; });
  if (at == slots.end())
    return;
  Type *i32 = Type::getInt32Ty(ctx.M.getContext());
  call->setMetadata("cq.mint.call", MDNode::get(ctx.M.getContext(), {ConstantAsMetadata::get(ConstantInt::get(i32, at - slots.begin())),
                                                                       ConstantAsMetadata::get(ConstantInt::get(i32, ownSymbol))}));
}
} // namespace

ArrayRef<MintSlot> mintSites(const TaintInfo &T, const Specialization &S) {
  static std::map<std::pair<const void *, const Specialization *>, SmallVector<MintSlot, 2>> memo;
  auto key = std::make_pair(static_cast<const void *>(T.specializations().data()), &S);
  auto it = memo.find(key);
  if (it != memo.end())
    return it->second;
  SmallVector<MintSlot, 2> sites;
  // A table clone's twin that does something, or a by-name clone's that runs and has a result to zero.
  bool twin = S.table ? !tableKeepsResults(T, S)
                      : !S.isEntry() && !S.F->getReturnType()->isVoidTy() && T.needsTwin(S) && hasTwin(T, S) && !fenv::cloneCarriesEnv(T, S);
  // Rule 18 (rulings3 F): a rotation in a loop, or a callee that rotates called in a loop or on a call cycle, leaves S no twin,
  // so every site here is per call.
  if (twin) {
    for (const Instruction &I : instructions(*S.F)) {
      auto *CB = dyn_cast<CallBase>(&I);
      const Function *G = CB ? CB->getCalledFunction() : nullptr;
      if (!G)
        continue;
      if (G->isDeclaration() && G->getName().starts_with("cq_theta_")) {
        sites.push_back({CB, 0});
        continue;
      }
      if (G->isDeclaration() || G->getReturnType()->isVoidTy() || !rotates(T, *G))
        continue;
      const Specialization *C = T.calleeSpecialization(*CB, S);
      if (!C)
        continue;
      if (C->isEntry()) {
        if (T.isQuantum(CB, S) && !G->getReturnType()->isStructTy())
          sites.push_back({CB, 0});
        else if (T.isQuantum(CB, S) || !G->getReturnType()->isVoidTy())
          noteUnbuilt("calls: an own symbol that rotates with a composite or classical result, in a clone with a twin", CB);
        continue;
      }
      unsigned n = unsigned(mintSites(T, *C).size());
      for (unsigned k = 0; k < n; ++k)
        sites.push_back({CB, k});
    }
    // Rule 18, §1.4: the measured copies of a table clone with no predicate, after the registers (tagRegisterCall reads a call's first).
    if (S.table && !S.ctl)
      for (const Instruction &I : instructions(*S.F)) {
        auto *CB = dyn_cast<CallBase>(&I);
        const Function *G = CB ? CB->getCalledFunction() : nullptr;
        if (!G)
          continue;
        if (G->isDeclaration()) {
          if (G->getName().starts_with("cq_measure_") && T.isQuantum(CB->getArgOperand(0), S))
            sites.push_back({CB, kMeasuredCopy});
          continue;
        }
        const Specialization *C = T.calleeSpecialization(*CB, S);
        for (unsigned i = 0; C && i < G->arg_size(); ++i) {
          SmallPtrSet<const Specialization *, 8> onStack;
          if (measuresFormal(T, *C, i, onStack))
            sites.push_back({CB, kMeasuredCopy + i});
        }
      }
  }
  return memo[key] = std::move(sites);
}

unsigned mintCount(const Function &clone) { return mintCounts.lookup(&clone); }

void noteMint(LoweringContext &ctx, CallInst &site, BasicBlock *startBlock, Instruction *before) {
  if (ctx.S.isEntry())
    return;
  if (tablePopsMints(ctx.T, ctx.S)) {
    auto bi = spine::shared(ctx).binds.find(&site);
    if (bi != spine::shared(ctx).binds.end() && bi->second.size() == 1 && bi->second[0].handle)
      listMint(ctx, bi->second[0].v);
    return;
  }
  ArrayRef<MintSlot> sites = mintSites(ctx.T, ctx.S);
  auto at = find_if(sites, [&](const MintSlot &m) { return m.site == &site; });
  if (at == sites.end())
    return;
  auto bi = spine::shared(ctx).binds.find(&site);
  if (bi == spine::shared(ctx).binds.end() || bi->second.size() != 1 || !bi->second[0].handle)
    return;
  Value *h = bi->second[0].v;
  Type *i32 = Type::getInt32Ty(ctx.M.getContext());
  MDNode *tag = MDNode::get(ctx.M.getContext(), ConstantAsMetadata::get(ConstantInt::get(i32, at - sites.begin())));
  BasicBlock *bb = ctx.B().GetInsertBlock();
  if (bb != startBlock) {
    noteUnbuilt("calls: a rotation whose lowering branched, its register is not handed to the twin", &site);
    return;
  }
  for (Instruction *I = before ? before->getNextNode() : &bb->front(); I; I = I->getNextNode()) {
    auto *c = dyn_cast<CallInst>(I);
    const Function *G = c ? c->getCalledFunction() : nullptr;
    if (!G || !G->getName().starts_with("cqrt_"))
      continue;
    if (c == h || is_contained(c->args(), h))
      c->setMetadata("cq.mint", tag);
  }
  // A rail rotated in place: whatever made it (a template, a merge of arms) the twin does not make again.
  SmallPtrSet<Value *, 4> seen;
  SmallVector<Value *, 4> work{h};
  while (!work.empty()) {
    Value *v = work.pop_back_val();
    if (!seen.insert(v).second)
      continue;
    if (auto *p = dyn_cast<PHINode>(v))
      work.append(p->value_op_begin(), p->value_op_end());
    else if (auto *c = dyn_cast<CallInst>(v))
      c->setMetadata("cq.mint", tag);
  }
}

void pushListedMints(LoweringContext &ctx) {
  if (!tablePopsMints(ctx.T, ctx.S))
    return;
  IRBuilder<> &B = ctx.B();
  B.CreateCall(mintsPush(ctx.M), {B.CreateLoad(PointerType::getUnqual(ctx.M.getContext()), mintHead(ctx))});
}

void noteMeasuredCopy(LoweringContext &ctx, const CallBase &site, unsigned arg, CallInst *alloc, CallInst *copy) {
  ArrayRef<MintSlot> sites = mintSites(ctx.T, ctx.S);
  auto at = find_if(sites, [&](const MintSlot &m) { return m.site == &site && m.sub == kMeasuredCopy + arg; });
  if (at == sites.end())
    return;
  measuredCopies[{&ctx.out(), &site, arg}] = alloc;
  Type *i32 = Type::getInt32Ty(ctx.M.getContext());
  MDNode *tag = MDNode::get(ctx.M.getContext(), ConstantAsMetadata::get(ConstantInt::get(i32, at - sites.begin())));
  alloc->setMetadata("cq.mint", tag);
  copy->setMetadata("cq.mint", tag);
}

Value *mintHandle(LoweringContext &ctx, const MintSlot &slot) {
  Value *zero = ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), 0);
  if (slot.sub >= kMeasuredCopy) {
    auto it = measuredCopies.find({&ctx.out(), slot.site, slot.sub - kMeasuredCopy});
    return it != measuredCopies.end() ? it->second : zero;
  }
  if (auto it = callRegisters.find({&ctx.out(), slot.site}); it != callRegisters.end())
    return slot.sub < it->second.size() ? it->second[slot.sub] : zero;
  spine::Shared &sh = spine::shared(ctx);
  auto bi = sh.binds.find(slot.site);
  if (bi == sh.binds.end() || bi->second.size() != 1 || !bi->second[0].handle)
    return zero;
  // Finalize's settleRegisters reads what became of the rail: rule 6 may still free it, or it may be minted on some paths only.
  return bi->second[0].v;
}

std::vector<TableRow> takeTableRows(const Module &M) {
  auto it = tableRows.find(&M);
  if (it == tableRows.end())
    return {};
  std::vector<TableRow> r = std::move(it->second);
  tableRows.erase(it);
  return r;
}

Constant *sigString(Module &M, FunctionType *FT) {
  std::string s;
  raw_string_ostream os(s);
  FT->print(os);
  os.flush();
  Constant *init = ConstantDataArray::getString(M.getContext(), s, /*AddNull=*/true);
  for (GlobalVariable &G : M.globals())
    if (G.getName().starts_with(".cq.sig") && G.hasInitializer() && G.getInitializer() == init)
      return &G;
  auto *gv = new GlobalVariable(M, init->getType(), /*isConstant=*/true, GlobalValue::PrivateLinkage, init, ".cq.sig");
  gv->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  gv->setAlignment(Align(1));
  return gv;
}

Value *enclosingK(LoweringContext &ctx) {
  if (ctx.S.table)
    return spine::shared(ctx).tableK;
  // Owner ruling Q2: in a function a table clone reaches by name, select(@__cq_k == -1, its own K, @__cq_k).
  if (Value *r = loops::exits::receivedKBelow(ctx, ctx.K(*ctx.S.F)))
    return r;
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), ctx.K(*ctx.S.F));
}

GlobalVariable *activationCounter(Module &M, StringRef fn) {
  std::string n = ("__cq_act_" + fn).str();
  if (GlobalVariable *g = M.getGlobalVariable(n, /*AllowInternal=*/true))
    return g;
  Type *i32 = Type::getInt32Ty(M.getContext());
  auto *g = new GlobalVariable(M, i32, false, GlobalValue::InternalLinkage, ConstantInt::get(i32, 0), n);
  g->setAlignment(Align(4));
  return g;
}

void insertActivationCounter(LoweringContext &ctx) {
  const Specialization &S = ctx.S;
  if (!S.ctl)
    return;
  const Function &F = *S.F;
  if (!S.table && F.hasLocalLinkage() && !F.hasAddressTaken() && !reaches(&F, &F))
    return;
  Function &C = ctx.out();
  LLVMContext &LC = ctx.M.getContext();
  Type *i32 = Type::getInt32Ty(LC);
  GlobalVariable *act = activationCounter(ctx.M, F.getName());
  Value *K = S.table ? static_cast<Value *>(C.getArg(C.arg_size() - 1)) : nullptr;
  // Owner ruling Q2 (CR 1.4 "Received K"; rule 27 "Cutoff": "quantum-depth recursion is cut at K"): in a function a table
  // clone reaches by name the cut is at select(@__cq_k == -1, own K, @__cq_k); the load (made for the body's K-loops or here) moves into
  // the new entry block, ahead of the counter, so it stays the one load on entry.
  if (!K)
    if (Value *r = loops::exits::receivedKBelow(ctx, ctx.K(F)))
      K = r;
  BasicBlock *body = &C.getEntryBlock();
  BasicBlock *entry = BasicBlock::Create(LC, "", &C, body);
  BasicBlock *cut = BasicBlock::Create(LC, "", &C);
  IRBuilder<> B(entry);
  if (K && !S.table) {
    GlobalVariable *g = loops::exits::receivedKGlobal(ctx.M);
    // The load and its select(ld == -1, K, ld) (owner 2026-11-15, loops-cutoff's loadedReceivedK), in body order.
    SmallVector<Instruction *, 4> hoist;
    SmallPtrSet<const Value *, 2> lds;
    for (Instruction &I : *body)
      if (auto *l = dyn_cast<LoadInst>(&I); l && l->getPointerOperand() == g) {
        lds.insert(l);
        hoist.push_back(l);
      } else if ((isa<ICmpInst>(I) || isa<SelectInst>(I)) && any_of(I.operands(), [&](const Use &o) { return lds.count(o.get()); })) {
        hoist.push_back(&I);
      }
    for (Instruction *I : hoist)
      I->moveBefore(*entry, entry->end());
  }
  if (!K)
    K = ConstantInt::get(i32, ctx.K(F));
  Value *d = B.CreateLoad(i32, act);
  B.CreateStore(B.CreateAdd(d, ConstantInt::get(i32, 1)), act);
  B.CreateCondBr(B.CreateICmpULT(d, K), body, cut);

  // The cut: each result a |0> rail, a copy_i1 of the predicate the kept overflow predicate (rule 14).
  B.SetInsertPoint(cut);
  auto zero = [&](RailType w) -> Value * {
    return B.CreateCall(abi::declare(ctx.M, abi::CoreSpec{abi::Core::Alloc, w}), {Constant::getNullValue(irTypeOf(LC, w))});
  };
  ResultLayout rl = resultLayout(ctx.T, S, &F);
  Type *RT = C.getReturnType();
  Value *rv = nullptr;
  auto field = [&](unsigned k, Type *t) -> Value * {
    if (k < rl.leaves.size() && rl.q[k])
      return zero(railTypeOf(rl.leaves[k]));
    if (k >= rl.leaves.size() + rl.extras && t == handleTy(LC))
      return zero(RailType{Kind::Int, 32});   // rule 23: a clone's flags rail
    return Constant::getNullValue(t);
  };
  if (auto *st = dyn_cast<StructType>(RT); st && (rl.anyQ() || rl.extras || rl.leaves.size() != st->getNumElements())) {
    rv = PoisonValue::get(st);
    for (unsigned k = 0; k < st->getNumElements(); ++k)
      rv = B.CreateInsertValue(rv, field(k, st->getElementType(k)), {k});
  } else if (!RT->isVoidTy()) {
    rv = rl.anyQ() ? field(0, RT) : Constant::getNullValue(RT);
  }
  RailType i1{Kind::Int, 1};
  Value *o = zero(i1);
  B.CreateCall(abi::declare(ctx.M, abi::CoreSpec{abi::Core::Copy, i1}), {C.getArg(0), o});
  if (tablePopsMints(ctx.T, S))
    B.CreateCall(abi::declare(ctx.M, abi::CoreSpec{abi::Core::Push}), {ConstantInt::get(i32, 0)});   // no register listed
  if (S.table)
    for (unsigned k = 0; k < mintSites(ctx.T, S).size(); ++k) {
      CallInst *p = B.CreateCall(abi::declare(ctx.M, abi::CoreSpec{abi::Core::Push}), {ConstantInt::get(i32, 0)});
      p->setMetadata("cq.mint.push", MDNode::get(LC, {}));
    }
  if (rv)
    B.CreateRet(rv);
  else
    B.CreateRetVoid();

  for (BasicBlock &BB : C)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator())) {
      IRBuilder<> RB(R);
      Value *n = RB.CreateLoad(i32, act);
      RB.CreateStore(RB.CreateAdd(n, ConstantInt::get(i32, -1, true)), act);
    }
}

Function *materialize(Module &M, const Specialization &S) {
  if (!S.F || S.F->isDeclaration())
    internalError("calls: materialize of a specialization with no body (a declared clone is rule 27's)");
  if (S.isEntry())
    internalError("calls: materialize of an entry specialization (rewritten in place by construct)", S.F);
  const TaintInfo &T = taintOf(S);
  LLVMContext &C = M.getContext();
  abi::CloneSpec cs = cloneSpecOf(S);
  std::string name = abi::name(cs);

  SmallVector<Type *, 8> ps;
  if (S.ctl)
    ps.push_back(handleTy(C));
  for (const FormalLayout &f : formalLayout(T, S, S.F))
    for (unsigned k = 0; k < f.leaves.size(); ++k)
      ps.push_back(f.q[k] ? handleTy(C) : f.leaves[k]);
  ResultLayout rl = resultLayout(T, S, S.F);
  Type *rt = cloneResultType(C, rl, S.F->getReturnType());
  if (S.table)
    ps.push_back(Type::getInt32Ty(C));   // §1.4: the cutoff K
  if (fenv::cloneTakesMode(T, S))
    ps.push_back(Type::getInt32Ty(C));   // §1.4 (cq-a9ij3): _rm's classical mode, _rmq's mode handle
  if (fenv::cloneCarriesEnv(T, S)) {
    // E1 (CR rule 23, 82): the caller's mode and flags trail the parameters; the new flags handle is
    // the result's last field: i32 alone for an otherwise void clone, {result, i32} for a scalar result,
    // and for a field-wise result (CR §1.4: its literal struct of leaves, handles where quantum) that
    // struct's fields followed by i32 (cq-xhv4).
    ps.push_back(handleTy(C));
    ps.push_back(handleTy(C));
    if (rt->isVoidTy()) {
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
  // §1.4: a clone called by name keeps the original's linkage, calling convention and unnamed_addr; a name with _b
  // bounds is internal to its module.
  // §1.4: a table clone is reached through its row: module-internal, the C calling convention.
  Function *NF = Function::Create(FT, S.bounds.empty() && !S.table ? S.F->getLinkage() : GlobalValue::InternalLinkage, name, &M);
  mintCounts[NF] = unsigned(mintSites(T, S).size());
  if (S.table) {
    if (!S.pure)
      noteTableClone(M, T, S, cs);
  } else {
    NF->setCallingConv(S.F->getCallingConv());
    NF->setUnnamedAddr(S.F->getUnnamedAddr());
  }
  unsigned p = S.ctl ? 1 : 0;
  std::vector<FormalLayout> fl = formalLayout(T, S, S.F);
  for (Argument &A : S.F->args()) {
    // CR §0: x86-64 only; inalloca and preallocated are the 32-bit Windows C++ ABI's.
    if (A.hasInAllocaAttr() || A.hasPreallocatedAttr())
      internalError("calls: an inalloca or preallocated formal (no x86-64 C function has one, CR §0)", &A);
    // Rule 26: `sret` stays on the classical ptr formal, an ABI note. LLVM allows it only on a void return, so a clone
    // that returns something (a _ctl clone's flags, the environment) has the plain pointer formal.
    if (!S.table && A.hasStructRetAttr() && rt->isVoidTy() && NF->getArg(p)->getType()->isPointerTy())
      NF->addParamAttr(p, Attribute::getWithStructRetType(C, A.getParamStructRetType()));
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
  auto finish = [&]() {
    if (hasTwin(ctx.T, S)) {
      ctx.unc().recordCall(r.call, outs, {});
      return;
    }
    for (Value *h : outs)
      ctx.unc().recordExternal(h, Role::Kept);   // rule 18: no twin
  };
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
  // (An own symbol keeps the C ABI: it cannot return a register's handle for a twin; such a result is KEPT, below.)
  for (const Use &u : CB.args())
    if (ctx.operand(u.get()).handle)
      internalError("calls: a quantum argument to a callee with no clone", &CB);
  if (CB.getType()->isVoidTy() || !ctx.T.isQuantum(&CB, ctx.S)) {
    ordinaryCall(ctx, CB);
    auto *made = dyn_cast<CallInst>(&ctx.B().GetInsertBlock()->back());
    if (CB.getType()->isVoidTy() && made && made->getCalledFunction() == cs.F && rotates(ctx.T, *cs.F))
      made->setMetadata("cq.mint.drop", MDNode::get(ctx.M.getContext(), {}));
    return;
  }
  if (underQuantumPredicate(ctx))
    internalError("calls: an in-place callee reached under a quantum predicate (taint makes it a _ctl clone)", &CB);
  Function &F = *cs.F;
  Type *crt = CB.getType();
  LLVMContext &C = ctx.M.getContext();
  Type *i32 = Type::getInt32Ty(C);
  spine::EntryReturn inCycle;
  const spine::EntryReturn *er = spine::entryReturn(F);
  if (!er) {
    // Rule 19: a callee on a call cycle with this function has no record yet (the plugin constructs a callee first unless
    // the calls form a cycle), and the records are the least fixpoint over the cycle. A FROZEN result is a register or its
    // rule-6 image, so a body that does not rotate has none: its result is zeroed by the twin. One that rotates on a
    // cycle has no twin (rulings3 F) and its result is KEPT, the same as frozen to this caller. The return type follows
    // from the C one and the result's taint alone (193, rule 26).
    inCycle.frozen = false;
    SmallVector<bool, 4> q = ctx.T.fieldMask(&CB, ctx.S);
    if (crt->isAggregateType() || crt->isVectorTy()) {
      SmallVector<Type *, 4> types;
      leafTypes(crt, types, &CB);
      if (types.size() != q.size())
        internalError("calls: an in-place callee's aggregate result whose field mask does not match its leaves", &CB);
      for (unsigned k = 0; k < types.size(); ++k)
        if (q[k])
          types[k] = i32;
      inCycle.ret = StructType::get(C, types);
      inCycle.leafQ.assign(q.begin(), q.end());
    } else {
      inCycle.ret = crt->isIntegerTy() && crt->getIntegerBitWidth() >= 32 ? crt : i32;
    }
    er = &inCycle;
  }
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
  // Rule 19: a frozen result is kept like the caller's own registers. Rule 18: every other result is zeroed by the twin
  // __cq_q_<fn>_<mask>_unc (the all-zero mask, `v` with no formal), a load for rule 5; with no twin KEPT.
  bool twin = hasTwin(ctx.T, cs) && er->registers == 0 && !rotates(ctx.T, F);
  std::string twinName = abi::name(abi::CloneSpec{F.getName().str(), cs.mask.empty() ? "v" : cs.mask, {}, false, false, true});
  SmallVector<Value *, 2> dead;
  auto keep = [&](Value *h) {
    if (er->frozen) {
      ctx.unc().recordExternal(h, Role::UserRegister);
      spine::shared(ctx).frozenResults.insert(h);
    } else if (!twin) {
      ctx.unc().recordExternal(h, Role::Kept);
    } else {
      dead.push_back(h);
    }
  };
  auto recordDead = [&]() {
    if (dead.empty())
      return;
    ctx.unc().noteTwinName(call, twinName);
    ctx.unc().recordCall(call, dead, {}, ctx.T.loadsBus(cs));
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
    recordDead();
    ctx.bindFields(&CB, ops);
    return;
  }
  if (!rt->isIntegerTy() || rt->getIntegerBitWidth() < 32)
    internalError("calls: an in-place callee returning a handle in a return type that cannot hold it", &CB);
  Value *h = rt == i32 ? static_cast<Value *>(call) : ctx.B().CreateTrunc(call, i32);
  keep(h);
  callRegisters[{&ctx.out(), &CB}].push_back(h);
  if (tablePopsMints(ctx.T, ctx.S) && rotates(ctx.T, F))
    listMint(ctx, h);
  tagRegisterCall(ctx, CB, call, true);
  recordDead();
  spine::bindOperand(ctx, &CB, Operand{h, true});
}

} // namespace

namespace {
// The binding of a lifted clone call's results (lowerLifted): by the clone's result ABI, its outs recorded as
// one call group undone by the twin (U2), the overflow predicate of a recursion level last (cq-ew5z).
void bindCloneCall(LoweringContext &ctx, CallBase &CB, const Specialization &cs, const CloneCall &r) {
  if (r.res.extras) {
    // Rule 19: the results, then the handles of the registers the callee minted, which stay allocated and which its twin
    // reads.
    SmallVector<Operand, 4> ops, extra;
    SmallVector<Value *, 4> outs;
    unsigned n = unsigned(r.res.leaves.size());
    for (unsigned k = 0; k < n; ++k) {
      Value *e = ctx.B().CreateExtractValue(r.call, {k});
      ops.push_back(Operand{e, r.res.q[k]});
      if (r.res.q[k])
        outs.push_back(e);
    }
    for (unsigned k = 0; k < r.res.extras; ++k) {
      Value *e = ctx.B().CreateExtractValue(r.call, {n + k});
      ctx.unc().recordExternal(e, Role::Kept);
      extra.push_back(Operand{e, true});
      callRegisters[{&ctx.out(), &CB}].push_back(e);
      if (tablePopsMints(ctx.T, ctx.S))
        listMint(ctx, e);
    }
    tagRegisterCall(ctx, CB, r.call, false);
    ctx.unc().recordCall(r.call, outs, extra, ctx.T.loadsBus(cs));
    if (r.res.composite)
      ctx.bindFields(&CB, ops);
    else
      spine::bindOperand(ctx, &CB, ops[0]);
    return;
  }
  if (fenv::cloneCarriesEnv(ctx.T, cs))
    return bindEnvResult(ctx, CB, cs, r);
  if (r.fieldwise)
    return bindFieldwiseResult(ctx, CB, r.call, r.res, cs);
  bindResult(ctx, CB, r.call, r.handle, cs, r.ops);
}
} // namespace

void noteRun(LoweringContext &ctx) { capture(ctx); }

void lowerLifted(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
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
    emitDeclaredCall(ctx, CB, cs->F, underQuantumPredicate(ctx) ? ctlFlag(ctx, CB) : nullptr);
    return;
  }
  CloneCall r = emitCloneCall(ctx, CB, *cs, nullptr);
  if (CB.getType()->isVoidTy() && rotates(ctx.T, *cs->F))
    r.call->setMetadata("cq.mint.drop", MDNode::get(ctx.M.getContext(), {}));
  bindCloneCall(ctx, CB, *cs, r);
}


void lowerDeclared(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Function *F = CB.getCalledFunction();
  if (!F || !F->isDeclaration())
    internalError("calls: lowerDeclared of a call that is not a direct call of a declaration", &CB);
  emitDeclaredCall(ctx, CB, F, underQuantumPredicate(ctx) ? ctlFlag(ctx, CB) : nullptr);
}


// ---- Rule 19: the call through a function pointer ---------------------------------------------------------------------
//
// It is always a call of a table clone (§1.4, BACKEND_ABI §1.14), and the caller has no record of the callee: its rails
// are not Uncompute's. What Uncompute sees is the call's value: a kept rail (the twin ran already), or a fresh rail
// holding the value whose deferred item undoes the rest after the value's readers.

namespace {

// kind of __cq_clone_resolve (BACKEND_ABI §1.14)
enum : unsigned { kForward = 0, kCtl = 1, kUnc = 2, kCtlUnc = 3 };

void resultLeaves(const CallBase &CB, SmallVectorImpl<Type *> &leaves) {
  if (!CB.getType()->isVoidTy())
    leafTypes(CB.getType(), leaves, &CB);
}

// The actual's scalar fields: a pointer its address (rule 21), a composite its leaves, classical ones not yet seeds. Only
// the fixed formals of a variadic function type: the rest go into rule 16's block (variadicActuals).
SmallVector<Operand, 8> tableActuals(LoweringContext &ctx, CallBase &CB) {
  SmallVector<Operand, 8> out;
  FunctionType *FT = CB.getFunctionType();
  for (const Use &u : CB.args()) {
    if (FT->isVarArg() && CB.getArgOperandNo(&u) >= FT->getNumParams())
      break;
    if (u->getType()->isPointerTy()) {
      out.push_back(bus::address(ctx, u.get(), /*access=*/false));
      continue;
    }
    for (const Operand &o : actualFields(ctx, u.get()))
      out.push_back(o);
  }
  return out;
}

// Rules 16, 19: the table clone of a variadic function takes the block as its one classical ptr, after the handles. The
// caller stores into it as a call by name does; a callee that turns out to be host code gets its actuals as they stand.
Value *variadicActuals(LoweringContext &ctx, CallBase &CB) {
  FunctionType *FT = CB.getFunctionType();
  return FT->isVarArg() ? variadicBlock(ctx, CB, FT->getNumParams()) : nullptr;
}

// Rule 7: the handle of an actual: its rail, or a seed made here, which the caller frees (`seeds`).
Value *actualHandle(Module &M, IRBuilder<> &B, const Operand &o, SmallVectorImpl<Value *> &seeds) {
  if (o.handle)
    return o.v;
  Value *v = o.v;
  if (v->getType()->isPointerTy())
    v = B.CreatePtrToInt(v, Type::getInt64Ty(M.getContext()));
  Value *s = B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, railTypeOf(v->getType())}), {v});
  seeds.push_back(s);
  return s;
}

void freeRail(Module &M, IRBuilder<> &B, Value *h) { B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Free}), {h}); }

Value *zeroRail(Module &M, IRBuilder<> &B, RailType w) {
  return B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, w}), {Constant::getNullValue(irTypeOf(M.getContext(), w))});
}

Value *resolveClone(Module &M, IRBuilder<> &B, Value *fn, unsigned kind) {
  return B.CreateCall(abi::declareHost(M, abi::Host::CloneResolve), {fn, B.getInt32(kind)});
}

// The table clone's call at a resolved pointer: ([pred,] handles..., K), one result per leaf.
SmallVector<Value *, 2> callTable(Module &M, IRBuilder<> &B, Value *callee, Value *pred, ArrayRef<Value *> handles, Value *K,
                                  ArrayRef<Type *> leaves) {
  LLVMContext &C = M.getContext();
  Type *h = handleTy(C);
  SmallVector<Value *, 8> args;
  if (pred)
    args.push_back(pred);
  args.append(handles.begin(), handles.end());
  args.push_back(K);
  Type *rt = leaves.empty()      ? Type::getVoidTy(C)
             : leaves.size() == 1 ? h
                                  : static_cast<Type *>(StructType::get(C, SmallVector<Type *, 4>(leaves.size(), h)));
  SmallVector<Type *, 8> params;
  for (Value *a : args)
    params.push_back(a->getType());   // handles, K, and a variadic function's block ptr
  FunctionType *FT = FunctionType::get(rt, params, false);
  CallInst *call = B.CreateCall(FT, callee, args);
  SmallVector<Value *, 2> out;
  if (leaves.size() == 1)
    out.push_back(call);
  else
    for (unsigned k = 0; k < leaves.size(); ++k)
      out.push_back(B.CreateExtractValue(call, {k}));
  return out;
}

// The table twin: ([pred,] outs..., handles..., K).
void callTableTwin(Module &M, IRBuilder<> &B, Value *twin, Value *pred, ArrayRef<Value *> outs, ArrayRef<Value *> handles,
                   Value *K) {
  LLVMContext &C = M.getContext();
  SmallVector<Value *, 8> args;
  if (pred)
    args.push_back(pred);
  args.append(outs.begin(), outs.end());
  args.append(handles.begin(), handles.end());
  args.push_back(K);
  SmallVector<Type *, 8> params;
  for (Value *a : args)
    params.push_back(a->getType());
  B.CreateCall(FunctionType::get(Type::getVoidTy(C), params, false), twin, args);
}

// Rules 18, 19: must the value be a kept rail? Measured, stored or returned by an own symbol, or a memory version change
// (or another block) comes before its last consumer. The twin then runs right after the copy: no change lies between.
bool keptResult(LoweringContext &ctx, CallBase &CB) {
  // Rule 14: in a loop the reverse reads the result, past the next trip's call (a memory version change).
  std::optional<DominatorTree> ownDT;
  std::optional<LoopInfo> ownLI;
  if (spine::liOrOwn(spine::shared(ctx), *CB.getFunction(), ownDT, ownLI).getLoopFor(CB.getParent()))
    return true;
  SmallVector<const Instruction *, 8> work{&CB};
  SmallPtrSet<const Instruction *, 8> seen{&CB};
  const BasicBlock *bb = CB.getParent();
  const Instruction *last = &CB;
  while (!work.empty()) {
    const Instruction *D = work.pop_back_val();
    for (const User *U : D->users()) {
      auto *I = cast<Instruction>(U);
      // A branch's flag reads the result until the arms' merge, which the arms' memory version changes precede.
      if (I->getParent() != bb || isa<PHINode>(I) || isa<StoreInst>(I) || I->isTerminator())
        return true;
      // The caller's next uses are behind a return. A table call writes memory, so this clone has no twin (rule 18): its result
      // is KEPT here (and returned as that rail, bindKeptValue).
      if (isa<ReturnInst>(I))
        return true;
      if (auto *c = dyn_cast<CallBase>(I)) {
        const Function *G = c->getCalledFunction();
        if (!G || G->getName().starts_with("cq_measure_"))
          return true;
      }
      if (cq::comesBefore(last, I))
        last = I;
      if (!I->getType()->isVoidTy() && seen.insert(I).second)
        work.push_back(I);
    }
  }
  for (const Instruction *I = CB.getNextNode(); I && last != &CB; I = I->getNextNode()) {
    if (bus::versionChange(ctx, *I))
      return true;
    if (I == last)
      break;
  }
  return false;
}

void bindCallValue(LoweringContext &ctx, CallBase &CB, ArrayRef<Value *> values) {
  if (values.empty())
    return;
  if (!isComposite(CB.getType())) {
    spine::bindOperand(ctx, &CB, Operand{values[0], true});
    return;
  }
  SmallVector<Operand, 4> ops;
  for (Value *v : values)
    ops.push_back(Operand{v, true});
  ctx.bindFields(&CB, ops);
}

// The value in fresh rails the readers read; `tail` (run with the builder after their last item, the fresh rails already
// |0>, freed) undoes what remains.
void deferValue(LoweringContext &ctx, CallBase &CB, ArrayRef<Value *> merged, ArrayRef<Type *> leaves,
                ArrayRef<Value *> readHandles, std::function<void(IRBuilder<> &)> tail) {
  Module &M = ctx.M;
  Uncompute &U = ctx.unc();
  SmallVector<Value *, 4> vals;
  std::vector<RailId> ids;
  // The item's region is one block of its own: Uncompute places a deferred item after the uses outside its region.
  IRBuilder<> &IB = ctx.B();
  BasicBlock *Region = BasicBlock::Create(M.getContext(), "", &ctx.out()), *After = BasicBlock::Create(M.getContext(), "", &ctx.out());
  IB.CreateBr(Region);
  IB.SetInsertPoint(Region);
  unsigned sc = U.openScope();
  for (Type *t : leaves) {
    RailType w = railTypeOf(t);
    CallInst *v = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {Constant::getNullValue(irTypeOf(M.getContext(), w))});
    ids.push_back(U.recordSeed(v));
    vals.push_back(v);
  }
  U.closeScope(sc);
  for (unsigned k = 0; k < vals.size(); ++k)
    ctx.emitCore(abi::CoreSpec{abi::Core::Copy, railTypeOf(leaves[k])}, {merged[k], vals[k]});
  IB.CreateBr(After);
  IB.SetInsertPoint(After);
  std::vector<RailId> reads;
  for (Value *h : readHandles)
    if (RailId r = U.idOf(h); !is_contained(reads, r))
      reads.push_back(r);
  SmallVector<Value *, 4> mergedCopy(merged.begin(), merged.end());
  SmallVector<Type *, 4> leafCopy(leaves.begin(), leaves.end());
  U.recordDeferred({sc}, ids,
                   [&M, &U, sc, vals, mergedCopy, leafCopy, tail](IRBuilder<> &B) {
                     for (unsigned k = 0; k < vals.size(); ++k)
                       B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, railTypeOf(leafCopy[k])}), {mergedCopy[k], vals[k]});
                     U.emitMirror(sc, B);   // frees the fresh rails, and tells Uncompute they are gone
                     tail(B);
                   },
                   reads);
  bindCallValue(ctx, CB, vals);
}

// The call's value in KEPT rails. A rail only returned is the clone's result as it is, not copied again (rule 18, no twin).
void bindKeptValue(LoweringContext &ctx, CallBase &CB, ArrayRef<Value *> kept) {
  if (kept.size() == 1 && !isComposite(CB.getType()) && !ctx.S.isEntry() && !CB.use_empty() &&
      all_of(CB.users(), [](const User *U) { return isa<ReturnInst>(U); }) && !CB.getType()->isPointerTy())
    spine::shared(ctx).ctlMeasured.insert(kept[0]);
  bindCallValue(ctx, CB, kept);
}

// The value copied out into fresh KEPT rails.
SmallVector<Value *, 2> copyOutKept(LoweringContext &ctx, ArrayRef<Value *> vals, ArrayRef<Type *> leaves) {
  SmallVector<Value *, 2> out;
  for (unsigned k = 0; k < vals.size(); ++k) {
    RailType w = railTypeOf(leaves[k]);
    Value *c = zeroRail(ctx.M, ctx.B(), w);
    ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {vals[k], c});
    out.push_back(c);
  }
  return out;
}

void noteReads(LoweringContext &ctx, ArrayRef<Value *> handles) {
  BasicBlock *bb = ctx.B().GetInsertBlock();
  if (bb->empty())
    return;
  Instruction *last = &bb->back();
  for (Value *h : handles)
    ctx.unc().noteUse(ctx.unc().idOf(h), last);
}

// Rule 19 Classical pointer: __cq_clone_resolve(fp, kind); null is rule 16's host boundary with fp as the callee.
void lowerClassicalPointer(LoweringContext &ctx, CallBase &CB, Value *fp) {
  Module &M = ctx.M;
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = M.getContext();
  Function &Out = ctx.out();
  Value *flag = bus::accessControl(ctx);
  Value *K = enclosingK(ctx);
  SmallVector<Type *, 4> leaves;
  resultLeaves(CB, leaves);
  SmallVector<Operand, 8> actuals = tableActuals(ctx, CB);
  bool allClassical = none_of(CB.args(), [&](const Use &u) { return ctx.T.isQuantum(u.get(), ctx.S); });
  bool ordinary = allClassical && !flag && !ctx.T.afterEvent(CB, ctx.S);
  SmallVector<Value *, 8> seeds, handles;
  for (const Operand &o : actuals)
    handles.push_back(actualHandle(M, B, o, seeds));
  if (Value *block = variadicActuals(ctx, CB))
    handles.push_back(block);
  SmallVector<Value *, 8> readHandles;
  for (const Operand &o : actuals)
    if (o.handle)
      readHandles.push_back(o.v);
  if (flag)
    readHandles.push_back(flag);

  bool keep = !leaves.empty() && keptResult(ctx, CB);
  Value *fwd = resolveClone(M, B, fp, flag ? kCtl : kForward);
  Value *none = B.CreateICmpEQ(fwd, ConstantPointerNull::get(cast<PointerType>(fwd->getType())));
  BasicBlock *Tbl = BasicBlock::Create(C, "", &Out), *Host = BasicBlock::Create(C, "", &Out),
             *Join = BasicBlock::Create(C, "", &Out);
  B.CreateCondBr(none, Host, Tbl);

  B.SetInsertPoint(Tbl);
  SmallVector<Value *, 2> res = callTable(M, B, fwd, flag, handles, K, leaves);
  SmallVector<Value *, 2> tblOut = res;
  if (leaves.empty() || keep) {
    tblOut = copyOutKept(ctx, res, leaves);
    callTableTwin(M, B, resolveClone(M, B, fp, flag ? kCtlUnc : kUnc), flag, res, handles, K);
  }
  BasicBlock *TblEnd = B.GetInsertBlock();
  B.CreateBr(Join);

  B.SetInsertPoint(Host);
  SmallVector<Value *, 2> hostOut;
  if (ordinary) {
    // The instruction as it stands; its classical result a seed (every result of the call is a handle).
    Instruction *n = CB.clone();
    for (unsigned i = 0; i < n->getNumOperands(); ++i) {
      Value *v = CB.getOperand(i);
      if (!isa<BasicBlock>(v) && !isa<MetadataAsValue>(v) && !isa<Function>(v))
        n->setOperand(i, ctx.operand(v).v);
    }
    B.Insert(n);
    if (!CB.getType()->isVoidTy()) {
      if (isComposite(CB.getType()))
        noteUnbuilt("calls: a composite result of an ordinary call through a function pointer", &CB);
      for (unsigned k = 0; k < leaves.size(); ++k) {
        Value *v = leaves.size() == 1 ? static_cast<Value *>(n) : B.CreateExtractValue(n, {k});
        if (v->getType()->isPointerTy())
          v = B.CreatePtrToInt(v, Type::getInt64Ty(C));
        hostOut.push_back(B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Alloc, railTypeOf(v->getType())}), {v}));
      }
    }
  } else {
    hostOut = tape::lowerTableEffect(ctx, CB, Operand{B.CreatePtrToInt(fp, Type::getInt64Ty(C)), false}, flag);
    if (!leaves.empty() && hostOut.size() != leaves.size())   // a result the program does not read: no _<W> form
      for (unsigned k = hostOut.size(); k < leaves.size(); ++k)
        hostOut.push_back(zeroRail(M, B, railTypeOf(leaves[k])));
  }
  BasicBlock *HostEnd = B.GetInsertBlock();
  B.CreateBr(Join);

  B.SetInsertPoint(Join);
  SmallVector<Value *, 2> merged;
  for (unsigned k = 0; k < leaves.size(); ++k) {
    PHINode *p = B.CreatePHI(handleTy(C), 2);
    p->addIncoming(tblOut[k], TblEnd);
    p->addIncoming(hostOut[k], HostEnd);
    merged.push_back(p);
  }
  if (leaves.empty() || keep) {
    for (Value *s : seeds)
      freeRail(M, B, s);
    for (Value *m : merged)
      ctx.unc().recordExternal(m, Role::Kept);
    noteReads(ctx, readHandles);
    bindKeptValue(ctx, CB, merged);
    return;
  }
  // Rule 18's position: after the last consumer.
  SmallVector<Value *, 2> resCopy = res, hostCopy = hostOut, handleCopy(handles.begin(), handles.end()), seedCopy(seeds.begin(), seeds.end());
  deferValue(ctx, CB, merged, leaves, readHandles,
             [&M, fp, flag, K, none, ordinary, resCopy, hostCopy, handleCopy, seedCopy, &Out](IRBuilder<> &TB) {
               LLVMContext &LC = M.getContext();
               BasicBlock *TwinB = BasicBlock::Create(LC, "", &Out), *HostB = BasicBlock::Create(LC, "", &Out),
                          *Cont = BasicBlock::Create(LC, "", &Out);
               TB.CreateCondBr(none, HostB, TwinB);
               TB.SetInsertPoint(TwinB);
               callTableTwin(M, TB, resolveClone(M, TB, fp, flag ? kCtlUnc : kUnc), flag, resCopy, handleCopy, K);
               TB.CreateBr(Cont);
               TB.SetInsertPoint(HostB);
               if (ordinary)
                 for (Value *h : hostCopy)
                   freeRail(M, TB, h);
               TB.CreateBr(Cont);
               TB.SetInsertPoint(Cont);
               for (Value *s : seedCopy)
                 freeRail(M, TB, s);
             });
}

// The reverse of the dispatch loop: pops each trip, uncomputes its select, its p_{i+1} and its flag; the seeds p_0
// (unless it is the predicate in scope) and out_0 are freed.
struct ReverseLoop {
  Module *M;
  Function *Out;
  Value *n, *sig, *rail, *pn, *pred;
  SmallVector<Value *, 2> outN;
  SmallVector<Type *, 2> leaves;
  void emit(IRBuilder<> &B) const {
    LLVMContext &C = M->getContext();
    Type *i32 = Type::getInt32Ty(C), *i64 = Type::getInt64Ty(C), *h = handleTy(C);
    RailType i1w{Kind::Int, 1}, i64w{Kind::Int, 64};
    FunctionCallee pop = abi::declare(*M, abi::CoreSpec{abi::Core::Pop});
    FunctionCallee notI1 = abi::declare(*M, abi::CoreSpec{abi::Core::NotI1, i1w});
    FunctionCallee andI1 = abi::declare(*M, abi::CoreSpec{abi::Core::AndI1, i1w});
    BasicBlock *pre = B.GetInsertBlock();
    BasicBlock *Hdr = BasicBlock::Create(C, "", Out), *Body = BasicBlock::Create(C, "", Out), *End = BasicBlock::Create(C, "", Out);
    B.CreateBr(Hdr);
    B.SetInsertPoint(Hdr);
    PHINode *k = B.CreatePHI(i32, 2), *p = B.CreatePHI(h, 2);
    SmallVector<PHINode *, 2> outs;
    for (Value *o : outN) {
      PHINode *ph = B.CreatePHI(h, 2);
      ph->addIncoming(o, pre);
      outs.push_back(ph);
    }
    k->addIncoming(n, pre);
    p->addIncoming(pn, pre);
    B.CreateCondBr(B.CreateICmpEQ(k, ConstantInt::get(i32, 0)), End, Body);
    B.SetInsertPoint(Body);
    Value *k1 = B.CreateAdd(k, ConstantInt::get(i32, -1, true));
    Value *f = B.CreateCall(pop);
    SmallVector<Value *, 2> cs(leaves.size()), prev(leaves.size());
    for (unsigned j = leaves.size(); j-- > 0;)
      cs[j] = B.CreateCall(pop);
    for (unsigned j = leaves.size(); j-- > 0;)
      prev[j] = B.CreateCall(pop);
    Value *pp = B.CreateCall(pop);
    for (unsigned j = 0; j < leaves.size(); ++j) {
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = railTypeOf(leaves[j]);
      B.CreateCall(abi::declare(*M, sel, true), {outs[j], f, cs[j], prev[j]});
      freeRail(*M, B, outs[j]);
      outs[j]->addIncoming(prev[j], Body);
    }
    B.CreateCall(notI1, {f});
    B.CreateCall(andI1, {pp, f, p});
    B.CreateCall(notI1, {f});
    freeRail(*M, B, p);
    Value *a = B.CreateCall(abi::declareHost(*M, abi::Host::CloneAt), {sig, k1});
    Value *ai = B.CreatePtrToInt(a, i64);
    abi::TemplateSpec eq;
    eq.op = "icmp";
    eq.pred = "eq";
    eq.w = i64w;
    eq.shape = "hl";
    B.CreateCall(abi::declare(*M, eq, true), {f, rail, ai});
    freeRail(*M, B, f);
    k->addIncoming(k1, Body);
    p->addIncoming(pp, Body);
    B.CreateBr(Hdr);
    B.SetInsertPoint(End);
    if (!pred)
      freeRail(*M, B, p);
    for (PHINode *o : outs)
      freeRail(*M, B, o);
  }
};

// Rule 19 Address rail (and rule 16's raise): one classical loop over the registered functions of type FT, the complement
// made by `complement` under p_n, its results returned; the reverse loop. The builder is left where the code continues.
void dispatchOverRail(LoweringContext &ctx, CallBase &CB, FunctionType *FT, Value *rail, ArrayRef<Type *> leaves,
                      ArrayRef<Operand> actuals, Value *block, function_ref<SmallVector<Value *, 2>(Value *pn)> complement) {
  Module &M = ctx.M;
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = M.getContext();
  Function &Out = ctx.out();
  Type *i32 = Type::getInt32Ty(C), *i64 = Type::getInt64Ty(C), *h = handleTy(C);
  RailType i1w{Kind::Int, 1}, i64w{Kind::Int, 64};
  Value *P = bus::accessControl(ctx);
  Value *K = enclosingK(ctx);
  Value *sig = sigString(M, FT);
  Value *n = B.CreateCall(abi::declareHost(M, abi::Host::CloneCount), {sig});
  Value *p0 = P ? P : ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1w}, {ConstantInt::getTrue(C)});
  SmallVector<Value *, 2> out0;
  for (Type *t : leaves)
    out0.push_back(zeroRail(M, B, railTypeOf(t)));
  FunctionCallee push = abi::declare(M, abi::CoreSpec{abi::Core::Push});
  FunctionCallee notI1 = abi::declare(M, abi::CoreSpec{abi::Core::NotI1, i1w});
  FunctionCallee andI1 = abi::declare(M, abi::CoreSpec{abi::Core::AndI1, i1w});

  BasicBlock *pre = B.GetInsertBlock();
  BasicBlock *Hdr = BasicBlock::Create(C, "", &Out), *Body = BasicBlock::Create(C, "", &Out), *Exit = BasicBlock::Create(C, "", &Out);
  B.CreateBr(Hdr);
  B.SetInsertPoint(Hdr);
  PHINode *i = B.CreatePHI(i32, 2), *p = B.CreatePHI(h, 2);
  i->addIncoming(ConstantInt::get(i32, 0), pre);
  p->addIncoming(p0, pre);
  SmallVector<PHINode *, 2> outs;
  for (Value *o : out0) {
    PHINode *ph = B.CreatePHI(h, 2);
    ph->addIncoming(o, pre);
    outs.push_back(ph);
  }
  B.CreateCondBr(B.CreateICmpULT(i, n), Body, Exit);

  B.SetInsertPoint(Body);
  Value *a = B.CreateCall(abi::declareHost(M, abi::Host::CloneAt), {sig, i});
  Value *ai = B.CreatePtrToInt(a, i64);
  abi::TemplateSpec eq;
  eq.op = "icmp";
  eq.pred = "eq";
  eq.w = i64w;
  eq.shape = "hl";
  Value *f = B.CreateCall(abi::declare(M, eq, false), {rail, ai});
  Value *ctl = f;
  if (P) {
    ctl = zeroRail(M, B, i1w);
    B.CreateCall(andI1, {P, f, ctl});
  }
  SmallVector<Value *, 8> seeds, handles;
  for (const Operand &o : actuals)
    handles.push_back(actualHandle(M, B, o, seeds));
  if (block)
    handles.push_back(block);
  SmallVector<Value *, 2> res = callTable(M, B, resolveClone(M, B, a, kCtl), ctl, handles, K, leaves);
  SmallVector<Value *, 2> cs;
  for (unsigned j = 0; j < leaves.size(); ++j) {
    RailType w = railTypeOf(leaves[j]);
    Value *c = zeroRail(M, B, w);
    B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, w}), {res[j], c});
    cs.push_back(c);
  }
  callTableTwin(M, B, resolveClone(M, B, a, kCtlUnc), ctl, res, handles, K);
  for (Value *s : seeds)
    freeRail(M, B, s);
  if (P) {
    B.CreateCall(andI1, {P, f, ctl});
    freeRail(M, B, ctl);
  }
  Value *p1 = zeroRail(M, B, i1w);
  B.CreateCall(notI1, {f});
  B.CreateCall(andI1, {p, f, p1});
  B.CreateCall(notI1, {f});
  B.CreateCall(push, {p});
  for (unsigned j = 0; j < leaves.size(); ++j) {
    abi::TemplateSpec sel;
    sel.op = "select";
    sel.w = railTypeOf(leaves[j]);
    Value *o1 = B.CreateCall(abi::declare(M, sel, false), {f, cs[j], outs[j]});
    B.CreateCall(push, {outs[j]});
    outs[j]->addIncoming(o1, Body);
  }
  for (Value *c : cs)
    B.CreateCall(push, {c});
  B.CreateCall(push, {f});
  Value *i1 = B.CreateAdd(i, ConstantInt::get(i32, 1));
  i->addIncoming(i1, Body);
  p->addIncoming(p1, Body);
  B.CreateBr(Hdr);

  B.SetInsertPoint(Exit);
  ReverseLoop R{&M, &Out, n, sig, rail, p, P, {}, {}};
  R.leaves.assign(leaves.begin(), leaves.end());
  for (PHINode *o : outs)
    R.outN.push_back(o);
  SmallVector<Value *, 8> readHandles{rail};
  for (const Operand &o : actuals)
    if (o.handle)
      readHandles.push_back(o.v);
  if (P)
    readHandles.push_back(P);

  SmallVector<Value *, 2> re = complement(p);
  if (leaves.empty()) {
    R.emit(B);
    noteReads(ctx, readHandles);
    return;
  }
  // The call's value: select_<W>(p_n, r_e, out_n).
  SmallVector<Value *, 2> vals;
  for (unsigned j = 0; j < leaves.size(); ++j) {
    abi::TemplateSpec sel;
    sel.op = "select";
    sel.w = railTypeOf(leaves[j]);
    Value *rj = j < re.size() ? re[j] : zeroRail(M, B, railTypeOf(leaves[j]));
    re.resize(std::max<size_t>(re.size(), j + 1));
    re[j] = rj;
    vals.push_back(B.CreateCall(abi::declare(M, sel, false), {p, rj, outs[j]}));
  }
  auto undoSelects = [&M, vals, re, p, outsV = SmallVector<Value *, 2>(R.outN), L = SmallVector<Type *, 2>(R.leaves)](IRBuilder<> &TB) {
    for (unsigned j = 0; j < L.size(); ++j) {
      abi::TemplateSpec sel;
      sel.op = "select";
      sel.w = railTypeOf(L[j]);
      TB.CreateCall(abi::declare(M, sel, true), {vals[j], p, re[j], outsV[j]});
      freeRail(M, TB, vals[j]);
    }
  };
  if (keptResult(ctx, CB)) {
    SmallVector<Value *, 2> kept = copyOutKept(ctx, vals, leaves);
    undoSelects(B);
    R.emit(B);
    for (Value *c : kept)
      ctx.unc().recordExternal(c, Role::Kept);
    noteReads(ctx, readHandles);
    bindKeptValue(ctx, CB, kept);
    return;
  }
  deferValue(ctx, CB, vals, leaves, readHandles, [undoSelects, R](IRBuilder<> &TB) {
    undoSelects(TB);
    R.emit(TB);
  });
}

// &__cq_sig[sig] (rule 16): classical, or an address rail for a rail sig (rule 20).
Operand signalCell(LoweringContext &ctx, Operand sig) {
  Module &M = ctx.M;
  IRBuilder<> &B = ctx.B();
  Type *i64 = Type::getInt64Ty(M.getContext());
  GlobalVariable *tbl = abi::sigTable(M);
  if (!sig.handle) {
    Value *cell = B.CreateInBoundsGEP(tbl->getValueType(), tbl, {ConstantInt::get(i64, 0), B.CreateSExt(sig.v, i64)});
    return Operand{B.CreatePtrToInt(cell, i64), false};
  }
  RailType w64{Kind::Int, 64};
  abi::TemplateSpec sx;
  sx.op = "sext";
  sx.w = railTypeOf(sig.v->getType());
  sx.w = RailType{Kind::Int, 32};
  sx.to = w64;
  Value *wide = ctx.emitTemplate(sx, {sig});
  abi::TemplateSpec mul;
  mul.op = "mul";
  mul.w = w64;
  mul.shape = "hl";
  Value *scaled = ctx.emitTemplate(mul, {Operand{wide, true}, Operand{ConstantInt::get(i64, 8), false}});
  abi::TemplateSpec add;
  add.op = "add";
  add.w = w64;
  add.shape = "hl";
  return Operand{ctx.emitTemplate(add, {Operand{scaled, true}, Operand{B.CreatePtrToInt(tbl, i64), false}}), true};
}

// A valid signal number (rule 16; owner 2026-11-12, cq-silnj): 1 <= sig <= 64 and none of 9, 19, 32, 33, 34. Bit
// sig - 1 of kSigValid is set exactly for a valid sig in [1, 64].
constexpr uint64_t kSigValid = ~((1ull << 8) | (1ull << 18) | (1ull << 31) | (1ull << 32) | (1ull << 33));

bool validSignal(int64_t sig) { return sig >= 1 && sig <= 64 && ((kSigValid >> (sig - 1)) & 1); }

// The flag v of that test, by ordinary templates over a rail sig: t = sig - 1; v = (t <u 64) & bit (t & 63) of
// kSigValid. Over a classical sig the classical test, its outcome a seed.
Value *signalValidFlag(LoweringContext &ctx, Operand sig) {
  IRBuilder<> &B = ctx.B();
  Type *i32 = B.getInt32Ty(), *i64 = B.getInt64Ty();
  if (!sig.handle) {
    Value *t = B.CreateAdd(sig.v, ConstantInt::get(i32, -1, true));
    Value *in = B.CreateICmpULT(t, ConstantInt::get(i32, 64));
    Value *bit = B.CreateTrunc(B.CreateLShr(ConstantInt::get(i64, kSigValid), B.CreateZExt(B.CreateAnd(t, 63), i64)),
                               B.getInt1Ty());
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {B.CreateAnd(in, bit)});
    ctx.unc().recordSeed(seed);
    return seed;
  }
  RailType w32{Kind::Int, 32}, w64{Kind::Int, 64}, w1{Kind::Int, 1};
  auto tmpl = [&](const char *op, const char *pred, RailType w, std::optional<RailType> to, const char *shape,
                  ArrayRef<Operand> ops) {
    abi::TemplateSpec t;
    t.op = op;
    if (pred)
      t.pred = pred;
    t.w = w;
    t.to = to;
    t.shape = shape;
    return Operand{ctx.emitTemplate(t, ops), true};
  };
  Operand t = tmpl("add", nullptr, w32, std::nullopt, "hl", {sig, Operand{ConstantInt::get(i32, -1, true), false}});
  Operand in = tmpl("icmp", "ult", w32, std::nullopt, "hl", {t, Operand{ConstantInt::get(i32, 64), false}});
  Operand t6 = tmpl("and", nullptr, w32, std::nullopt, "hl", {t, Operand{ConstantInt::get(i32, 63), false}});
  Operand z = tmpl("zext", nullptr, w32, w64, "", {t6});
  Operand sh = tmpl("lshr", nullptr, w64, std::nullopt, "lh", {Operand{ConstantInt::get(i64, kSigValid), false}, z});
  Operand bit = tmpl("trunc", nullptr, w64, w1, "", {sh});
  return tmpl("and", nullptr, w1, std::nullopt, "", {in, bit}).v;
}

// t = a & b into a fresh rail (b negated when `negA`: t = !a & b, an X bracket on a), kept: a bus access's control.
Value *conjoin(LoweringContext &ctx, Value *a, Value *b, bool negA) {
  RailType w1{Kind::Int, 1};
  CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w1}, {ConstantInt::getFalse(ctx.M.getContext())});
  ctx.unc().recordExternal(t, Role::Kept);
  if (negA)
    ctx.emitCore(abi::CoreSpec{abi::Core::NotI1, w1}, {a});
  ctx.emitCore(abi::CoreSpec{abi::Core::AndI1}, {a, b, t});
  if (negA)
    ctx.emitCore(abi::CoreSpec{abi::Core::NotI1, w1}, {a});
  return t;
}

// Owner 2026-11-12 (clarifies cq-silnj): signal's EINVAL goes to errno through the accessor the module declares or
// defines for its own errno reads, int *(void) by name and signature: __errno_location (musl, glibc) or __error (a
// Darwin-built module). The pass never declares one. Neither present: no store, by the rule (nothing in the module can
// read errno). Both present: the module reads errno through each accessor it calls, so the store goes through each one
// with a call in the module (__errno_location first); with neither called, __errno_location alone.
SmallVector<Function *, 2> errnoAccessors(Module &M) {
  SmallVector<Function *, 2> acc;
  for (const char *name : {"__errno_location", "__error"}) {
    if (Function *f = M.getFunction(name); f && errnoAccessor(*f))
      acc.push_back(f);
  }
  auto called = [](Function *f) {
    for (const User *u : f->users())
      if (auto *c = dyn_cast<CallBase>(u); c && c->getCalledOperand() == f)
        return true;
    return false;
  };
  if (acc.size() == 2 && (called(acc[0]) || called(acc[1]))) {
    SmallVector<Function *, 2> used;
    for (Function *f : acc)
      if (called(f))
        used.push_back(f);
    acc = used;
  } else if (acc.size() == 2) {
    acc.pop_back();
  }
  return acc;
}

// The address each accessor returns: its call as it stands, unguarded (owner 2026-11-13: no host effect, no event).
SmallVector<Operand, 2> errnoAddresses(LoweringContext &ctx) {
  IRBuilder<> &B = ctx.B();
  SmallVector<Operand, 2> out;
  for (Function *f : errnoAccessors(ctx.M))
    out.push_back(Operand{B.CreatePtrToInt(B.CreateCall(f), B.getInt64Ty()), false});
  return out;
}

} // namespace

// EINVAL (22) stored at errno through each accessor (errnoAccessors): under the rail c (under NOT c when neg) ANDed with
// flag, the predicate in scope as bus::accessControl gave it (read once by the caller: it may make a rail); c null: under
// the predicate in scope alone. No accessor: nothing.
void storeEinval(LoweringContext &ctx, Value *c, bool neg, Value *flag) {
  Operand einval{ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), 22), false};
  Type *i32 = einval.v->getType();
  if (!c) {
    for (const Operand &e : errnoAddresses(ctx))
      bus::emitKeptStore(ctx, i32, e, einval);
    return;
  }
  for (const Operand &e : errnoAddresses(ctx)) {
    if (flag)
      bus::emitKeptStoreUnder(ctx, i32, e, einval, conjoin(ctx, c, flag, neg), false);
    else
      bus::emitKeptStoreUnder(ctx, i32, e, einval, c, neg);
  }
}

// Owner 2026-11-13 (errno of a computed failure value; CR rule 16 Results): EINVAL where (unsigned)a > max. A constant a:
// the test at compile time and the store under the predicate in scope; a classical a: the classical test, its outcome a
// seed; a rail a: the flag by the ordinary icmp template. No accessor: no test and no store.
void storeEinvalAbove(LoweringContext &ctx, Value *arg, uint64_t max) {
  if (errnoAccessors(ctx.M).empty())
    return;
  IRBuilder<> &B = ctx.B();
  Operand a = ctx.operand(arg);
  Type *ty = arg->getType();
  if (!a.handle) {
    if (auto *k = dyn_cast<ConstantInt>(a.v)) {
      if (k->getValue().ugt(max))
        storeEinval(ctx, nullptr, false, nullptr);
      return;
    }
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}},
                                  {B.CreateICmpUGT(a.v, ConstantInt::get(ty, max))});
    ctx.unc().recordSeed(seed);
    return storeEinval(ctx, seed, false, bus::accessControl(ctx));
  }
  abi::TemplateSpec t;
  t.op = "icmp";
  t.pred = "ugt";
  t.w = railTypeOf(ty);
  t.shape = "hl";
  Value *bad = ctx.emitTemplate(t, {a, Operand{ConstantInt::get(ty, max), false}});
  storeEinval(ctx, bad, false, bus::accessControl(ctx));
}

void lowerIndirect(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Operand fp = ctx.operand(CB.getCalledOperand());
  if (!fp.handle)
    return lowerClassicalPointer(ctx, CB, fp.v);
  SmallVector<Type *, 4> leaves;
  resultLeaves(CB, leaves);
  SmallVector<Operand, 8> actuals = tableActuals(ctx, CB);
  Value *block = variadicActuals(ctx, CB);
  dispatchOverRail(ctx, CB, CB.getFunctionType(), fp.v, leaves, actuals, block, [&](Value *pn) {
    return tape::lowerTableEffect(ctx, CB, fp, pn);
  });
}

// Rule 16 signal table; owner 2026-11-12, cq-silnj: an invalid signal number gives SIG_ERR with no load and no store.
// A valid constant: the load and store as they stand. An invalid constant: SIG_ERR and EINVAL stored at errno (under
// the predicate in scope). Otherwise the flag v of the test: the load and store under v (ANDed with the predicate in
// scope), the result select(v, loaded, -1), EINVAL stored at errno under NOT v (ANDed likewise).
void lowerSignal(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Operand sig = ctx.operand(CB.getArgOperand(0));
  Operand h = bus::address(ctx, CB.getArgOperand(1));
  Value *flag = bus::accessControl(ctx);
  if (!sig.handle && !h.handle && !flag) {
    // The host call as it stands, whatever precedes it (the ordinary-host-call test is not asked for signal).
    Instruction *n = CB.clone();
    for (unsigned i = 0; i < CB.arg_size(); ++i)
      n->setOperand(i, ctx.operand(CB.getArgOperand(i)).v);
    ctx.B().Insert(n);
  }
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  auto *k = sig.handle ? nullptr : dyn_cast<ConstantInt>(sig.v);
  if (k && !validSignal(k->getSExtValue())) {
    storeEinval(ctx, nullptr, false, nullptr);
    if (!CB.use_empty()) {   // the result is a rail (the table's cell is bus memory): SIG_ERR as a seed
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 64}}, {ConstantInt::get(i64, -1, true)});
      ctx.unc().recordSeed(seed);
      spine::bindOperand(ctx, &CB, Operand{seed, true});
    }
    return;
  }
  Operand cell = signalCell(ctx, sig);
  if (k) {
    CallInst *old = bus::emitLoad(ctx, i64, cell);
    bus::emitKeptStore(ctx, i64, cell, h);
    if (CB.use_empty())
      ctx.unc().resolveAt(old->getNextNode(), {ctx.unc().idOf(old)});   // un-copied before the store
    else
      spine::bindOperand(ctx, &CB, Operand{old, true});
    return;
  }
  Value *v = signalValidFlag(ctx, sig);
  Value *c = flag ? conjoin(ctx, v, flag, false) : v;
  CallInst *old = bus::emitLoadUnder(ctx, i64, cell, c);
  bus::emitKeptStoreUnder(ctx, i64, cell, h, c, false);
  storeEinval(ctx, v, true, flag);
  if (CB.use_empty()) {
    ctx.unc().resolveAt(old->getNextNode(), {ctx.unc().idOf(old)});   // un-copied before the store
    return;
  }
  abi::TemplateSpec sel;
  sel.op = "select";
  sel.w = RailType{Kind::Int, 64};
  sel.shape = "hl";
  spine::bindOperand(ctx, &CB, Operand{ctx.emitTemplate(sel, {Operand{v, true}, Operand{old, true},
                                                              Operand{ConstantInt::get(i64, -1, true), false}}), true});
}

void lowerRaise(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  LLVMContext &C = ctx.M.getContext();
  Type *i64 = Type::getInt64Ty(C);
  Operand sig = ctx.operand(CB.getArgOperand(0));
  Operand cell = signalCell(ctx, sig);
  Value *rail = bus::emitLoad(ctx, i64, cell);
  // A call of function type void (i32) with sig as its one actual.
  FunctionType *FT = FunctionType::get(Type::getVoidTy(C), {Type::getInt32Ty(C)}, false);
  SmallVector<Value *, 2> re;
  dispatchOverRail(ctx, CB, FT, rail, {}, {sig}, nullptr, [&](Value *pn) {
    re = tape::lowerRaiseEffect(ctx, CB, pn);
    return SmallVector<Value *, 2>{};
  });
  // A result the program reads is musl's value by tape::rewriteDeferredResults (cq-dbtpi), so none is read here unless
  // the callee is not raise's prototype: then the entry's rail under the complement, 0 under every candidate flag.
  tape::storeFailureErrno(ctx, CB);   // owner 2026-11-13: EINVAL with the complement's -1
  if (!re.empty())
    spine::bindOperand(ctx, &CB, Operand{re[0], true});
}

// Rule 16 Variadic calls, in a clone. va_start(ap) is the bus stores of {gp_offset = 48, fp_offset = 176,
// overflow_arg_area = block, reg_save_area = 0} into ap; va_arg and va_end are the -O1 code as it stands (va_end is
// nothing). Q11: va_copy is rule 22's copy of sizeof(va_list) = 24 bytes when a side is bus-resident; with both
// host-resident it stays. In the own symbol va_start stays the intrinsic: it fills ap with host bytes.
void lowerVarargs(LoweringContext &ctx, Instruction &I) {
  auto *II = dyn_cast<IntrinsicInst>(&I);
  LLVMContext &C = ctx.M.getContext();
  Type *I32 = Type::getInt32Ty(C), *I64 = Type::getInt64Ty(C);
  if (!II) {
    // A va_arg instruction (clang's x86-64 va_arg is -O1 code, so none reaches here from C): the overflow area's slot.
    auto &VA = cast<VAArgInst>(I);
    Operand ap = bus::address(ctx, VA.getPointerOperand());
    Operand area = bus::offsetAddress(ctx, ap, 8);
    Operand slot{bus::emitLoad(ctx, I64, area), true};
    spine::bindOperand(ctx, &I, Operand{bus::emitLoad(ctx, I.getType(), slot), true});
    abi::TemplateSpec add;
    add.op = "add";
    add.w = RailType{Kind::Int, 64};
    add.shape = "hl";
    uint64_t step = alignTo(ctx.M.getDataLayout().getTypeAllocSize(I.getType()), 8);
    Value *next = ctx.emitTemplate(add, {slot, Operand{ConstantInt::get(I64, step), false}});
    bus::emitKeptStore(ctx, I64, area, Operand{next, true});
    return;
  }
  switch (II->getIntrinsicID()) {
  case Intrinsic::vaend:
    return;
  case Intrinsic::vacopy: {
    const Value *dst = II->getArgOperand(0), *src = II->getArgOperand(1);
    if (ctx.T.hostObjectOf(dst, ctx.S) && ctx.T.hostObjectOf(src, ctx.S) && !ctx.currentFlag() && !ctx.S.ctl) {
      spine::copyClassical(ctx, I);
      return;
    }
    bus::lowerCopy(ctx, bus::address(ctx, dst), bus::address(ctx, src), Operand{ConstantInt::get(I64, 24), false},
                   bus::accessControl(ctx), I);
    return;
  }
  case Intrinsic::vastart: {
    if (ctx.S.isEntry()) {
      // At an address rail no host write is possible: the program's ap stays as it is.
      if (!ctx.operand(II->getArgOperand(0)).handle)
        spine::copyClassical(ctx, I);
      return;
    }
    spine::Shared &sh = spine::shared(ctx);
    if (sh.varargs.size() != 1)
      internalError("calls: va_start in a clone that has no variadic block", &I);
    Operand ap = bus::address(ctx, II->getArgOperand(0));
    Value *block = ctx.B().CreatePtrToInt(sh.varargs[0].v, I64);
    bus::emitKeptStore(ctx, I32, ap, Operand{ConstantInt::get(I32, 48), false});
    bus::emitKeptStore(ctx, I32, bus::offsetAddress(ctx, ap, 4), Operand{ConstantInt::get(I32, 176), false});
    bus::emitKeptStore(ctx, I64, bus::offsetAddress(ctx, ap, 8), Operand{block, false});
    bus::emitKeptStore(ctx, I64, bus::offsetAddress(ctx, ap, 16), Operand{ConstantInt::get(I64, 0), false});
    return;
  }
  default:
    internalError("calls: lowerVarargs of an intrinsic that is none of va_start, va_copy, va_end", &I);
  }
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

