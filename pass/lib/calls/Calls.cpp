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
#include "CallsInternal.h"

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
  return abi::CloneSpec{S.F->getName().str(), S.mask.empty() ? "v" : S.mask, S.bounds, S.ctl, S.pure, false, S.table};
}

bool sameFields(const abi::CloneSpec &a, const abi::CloneSpec &b) {
  return a.fn == b.fn && a.mask == b.mask && a.bounds == b.bounds && a.ctl == b.ctl && a.pure == b.pure &&
         a.unc == b.unc && a.table == b.table;
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
  // M2 (191): the clone's stores through Qram-pointee formals, one i32 handle each after the leaves.
  unsigned stores = 0;
  bool qramFormal = false;
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
  bool packed = !S.table && packedIntegerResult(*S.F);   // §1.4: a table clone's ABI follows from the C signature alone
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
      bus::emitKeptStore(ctx, t, at, ctx.operand(a));
      continue;
    }
    SmallVector<bus::Leaf, 4> leaves;
    bus::scalarLeaves(DL, t, 0, leaves);
    SmallVector<Operand, 4> fields = aggr::flattenResult(ctx, a);
    if (fields.size() != leaves.size())
      internalError("calls: a variadic actual whose fields are not its scalar leaves", &CB);
    for (unsigned k = 0; k < leaves.size(); ++k)
      bus::emitKeptStore(ctx, leaves[k].type, bus::offsetAddress(ctx, at, leaves[k].offset), fields[k]);
  }
  return block;
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
      if (fs[i].q[k])
        o = seedActual(ctx, o);
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
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), K);
}



// Rule 27: the declared clone of F for CB, the table clone of §1.4: __cq_q_<fn>_<1…1>_t[_ctl]([pred,] handles…, K), every
// scalar actual a handle (a classical one a seed, a classical pointer alloc_i64 of its address), every result a handle,
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
  std::string mask;
  for (const Use &u : CB.args())
    for (Operand o : actualFields(ctx, u.get())) {
      o = seedActual(ctx, o);
      mask.push_back('1');
      args.push_back(o.v);
      ops.push_back(o);
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
  if (leaves.empty()) {
    outs.push_back(call);
    fops.push_back(Operand{call, true});
  } else {
    for (unsigned k = 0; k < leaves.size(); ++k) {
      Value *e = ctx.B().CreateExtractValue(call, {k});
      outs.push_back(e);
      fops.push_back(Operand{e, true});
    }
  }
  ctx.unc().recordTableCall(call, outs);
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
            if (!Y->isDeclaration() && seen.insert(Y).second)
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

// §1.4: a table clone's twin does nothing but count and pop when rule 18 gives it none: a tainted measurement (Q3), which
// is every measurement in a _ctl clone (rule 19's controlled copy). A measurement on a classical path of the clone with no
// predicate keeps its rule-18 twin; the outcome's seed stays allocated (rule 2, rulings3 E, Finalize's defineTwin).
bool tableKeepsResults(const TaintInfo &T, const Specialization &S) {
  if (!hasTwin(T, S))
    return true;
  if (!S.ctl)
    return false;
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
            if (!G->isDeclaration() && seen.insert(G).second)
              work.push_back(G);
          }
  }
  return false;
}

DenseMap<const Function *, unsigned> mintCounts;

void noteTableClone(Module &M, const TaintInfo &T, const Specialization &S, const abi::CloneSpec &cs) {
  std::vector<TableRow> &rows = tableRows[&M];
  auto it = find_if(rows, [&](const TableRow &r) { return r.fn == cs.fn; });
  if (it == rows.end()) {
    rows.push_back(TableRow{cs.fn, S.F->getFunctionType(), {}, {}});
    abi::CloneSpec f = cs;
    f.ctl = false;
    rows.back().forward = abi::name(f);
    f.ctl = true;
    rows.back().ctl = abi::name(f);
    it = std::prev(rows.end());
  }
  (S.ctl ? it->ctlKeepsResults : it->forwardKeepsResults) = tableKeepsResults(T, S);
}
} // namespace

ArrayRef<const CallBase *> mintSites(const TaintInfo &T, const Specialization &S) {
  static std::map<std::pair<const void *, const Specialization *>, SmallVector<const CallBase *, 2>> memo;
  auto key = std::make_pair(static_cast<const void *>(T.specializations().data()), &S);
  auto it = memo.find(key);
  if (it != memo.end())
    return it->second;
  SmallVector<const CallBase *, 2> sites;
  // A table clone's twin that does something, or a by-name clone's that runs and has a result to zero.
  bool twin = S.table ? !tableKeepsResults(T, S)
                      : !S.isEntry() && !S.F->getReturnType()->isVoidTy() && T.needsTwin(S) && hasTwin(T, S) && !fenv::cloneCarriesEnv(T, S);
  if (twin) {
    DominatorTree DT(*S.F);
    LoopInfo LI(DT);
    for (const Instruction &I : instructions(*S.F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (const Function *G = CB->getCalledFunction(); G && G->isDeclaration() && G->getName().starts_with("cq_theta_")) {
          if (LI.getLoopFor(CB->getParent()))
            noteUnbuilt("calls: a rotation in a loop of a clone with a twin (rule 19's registers are per site)", CB);
          else
            sites.push_back(CB);
        }
  }
  return memo[key] = std::move(sites);
}

unsigned mintCount(const Function &clone) { return mintCounts.lookup(&clone); }

void noteMint(LoweringContext &ctx, CallInst &site, BasicBlock *startBlock, Instruction *before) {
  if (ctx.S.isEntry())
    return;
  ArrayRef<const CallBase *> sites = mintSites(ctx.T, ctx.S);
  auto at = find(sites, &site);
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
}

Value *mintHandle(LoweringContext &ctx, const CallBase &site) {
  Value *zero = ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), 0);
  spine::Shared &sh = spine::shared(ctx);
  auto bi = sh.binds.find(&site);
  if (bi == sh.binds.end() || bi->second.size() != 1 || !bi->second[0].handle)
    return zero;
  auto *h = dyn_cast<CallInst>(bi->second[0].v);
  if (!h || !h->getMetadata("cq.mint"))
    return zero;
  if (sh.ruleSixCleaned.count(h))
    return zero;   // absorbed by rule 6: no register remains
  return h;
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
  Value *K = S.table ? static_cast<Value *>(C.getArg(C.arg_size() - 1)) : ConstantInt::get(i32, ctx.K(F));
  BasicBlock *body = &C.getEntryBlock();
  BasicBlock *entry = BasicBlock::Create(LC, "", &C, body);
  BasicBlock *cut = BasicBlock::Create(LC, "", &C);
  IRBuilder<> B(entry);
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
  std::string name = checkedName(cs, S.F);

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
  if (fenv::cloneCarriesEnv(T, S)) {
    // E1 (CR rule 23, 82): the caller's mode and flags trail the parameters; the new flags handle is
    // the result's last field: i32 alone for an otherwise void clone, {result, i32} for a scalar result,
    // and for a field-wise result (CR §1.4: its literal struct of leaves, handles where quantum) that
    // struct's fields followed by i32 (cq-xhv4).
    ps.push_back(handleTy(C));
    ps.push_back(handleTy(C));
    if (rl.stores) {
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
    // Rule 26: `sret` stays on the classical ptr formal, an ABI note.
    if (!S.table && A.hasStructRetAttr() && NF->getArg(p)->getType()->isPointerTy())
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
  // Rule 19: a frozen result is kept like the caller's own registers. Rule 18: every other result is zeroed by the twin
  // __cq_q_<fn>_<mask>_unc (the all-zero mask, `v` with no formal), a load for rule 5; with no twin KEPT.
  bool twin = hasTwin(ctx.T, cs) && er->registers == 0;
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
    }
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

// The actual's scalar fields: a pointer its address (rule 21), a composite its leaves, classical ones not yet seeds.
SmallVector<Operand, 8> tableActuals(LoweringContext &ctx, CallBase &CB) {
  SmallVector<Operand, 8> out;
  for (const Use &u : CB.args()) {
    if (u->getType()->isPointerTy()) {
      out.push_back(bus::address(ctx, u.get()));
      continue;
    }
    for (const Operand &o : actualFields(ctx, u.get()))
      out.push_back(o);
  }
  return out;
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
  FunctionType *FT = FunctionType::get(rt, SmallVector<Type *, 8>(args.size(), h), false);
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
  B.CreateCall(FunctionType::get(Type::getVoidTy(C), SmallVector<Type *, 8>(args.size(), handleTy(C)), false), twin, args);
}

// Rules 18, 19: must the value be a kept rail? Measured, stored or returned by an own symbol, or a memory version change
// (or another block) comes before its last consumer. The twin then runs right after the copy: no change lies between.
bool keptResult(LoweringContext &ctx, CallBase &CB) {
  SmallVector<const Instruction *, 8> work{&CB};
  SmallPtrSet<const Instruction *, 8> seen{&CB};
  const BasicBlock *bb = CB.getParent();
  const Instruction *last = &CB;
  while (!work.empty()) {
    const Instruction *D = work.pop_back_val();
    for (const User *U : D->users()) {
      auto *I = cast<Instruction>(U);
      if (I->getParent() != bb || isa<PHINode>(I) || isa<StoreInst>(I))
        return true;
      if (isa<ReturnInst>(I) && ctx.S.isEntry())
        return true;
      if (auto *c = dyn_cast<CallBase>(I)) {
        const Function *G = c->getCalledFunction();
        if (!G || G->getName().starts_with("cq_measure_"))
          return true;
      }
      if (last->comesBefore(I))
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
  bool allClassical = none_of(actuals, [](const Operand &o) { return o.handle; });
  bool ordinary = allClassical && !flag && !ctx.T.afterEvent(CB, ctx.S);
  SmallVector<Value *, 8> seeds, handles;
  for (const Operand &o : actuals)
    handles.push_back(actualHandle(M, B, o, seeds));
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
    bindCallValue(ctx, CB, merged);
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
                      ArrayRef<Operand> actuals, function_ref<SmallVector<Value *, 2>(Value *pn)> complement) {
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
    bindCallValue(ctx, CB, kept);
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

} // namespace

void lowerIndirect(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Operand fp = ctx.operand(CB.getCalledOperand());
  if (!fp.handle)
    return lowerClassicalPointer(ctx, CB, fp.v);
  SmallVector<Type *, 4> leaves;
  resultLeaves(CB, leaves);
  SmallVector<Operand, 8> actuals = tableActuals(ctx, CB);
  dispatchOverRail(ctx, CB, CB.getFunctionType(), fp.v, leaves, actuals, [&](Value *pn) {
    return tape::lowerTableEffect(ctx, CB, fp, pn);
  });
}

void lowerSignal(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Operand sig = ctx.operand(CB.getArgOperand(0));
  Operand h = bus::address(ctx, CB.getArgOperand(1));
  if (!sig.handle && !h.handle && !bus::accessControl(ctx)) {
    // The host call as it stands, whatever precedes it (the ordinary-host-call test is not asked for signal).
    Instruction *n = CB.clone();
    for (unsigned i = 0; i < CB.arg_size(); ++i)
      n->setOperand(i, ctx.operand(CB.getArgOperand(i)).v);
    ctx.B().Insert(n);
  }
  Type *i64 = Type::getInt64Ty(ctx.M.getContext());
  Operand cell = signalCell(ctx, sig);
  CallInst *old = bus::emitLoad(ctx, i64, cell);
  bus::emitKeptStore(ctx, i64, cell, h);
  if (CB.use_empty())
    ctx.unc().resolveAt(old->getNextNode(), {ctx.unc().idOf(old)});   // un-copied before the store
  else
    spine::bindOperand(ctx, &CB, Operand{old, true});
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
  dispatchOverRail(ctx, CB, FT, rail, {}, {sig}, [&](Value *pn) {
    re = tape::lowerRaiseEffect(ctx, CB, pn);
    return SmallVector<Value *, 2>{};
  });
  // A result the program reads: the entry's rail under the complement, 0 under every candidate flag (|0> there, rule 9).
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
  if (r.res.qramFormal)
    unimplemented("calls: lowerLiftedVia of a clone with a formal onto a bus object (U3: mem-qram's "
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

