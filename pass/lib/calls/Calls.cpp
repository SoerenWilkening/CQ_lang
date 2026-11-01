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
//  - emitTwin(ctx, lowered): emits, at the builder, the twin call of a lowered clone call whose
//    result rail the caller did NOT record (`<clone>_unc(out, args…)`). The twins of recorded
//    results are Uncompute's to emit. Twin bodies are defined by finalize.
//  - lowerVarargs and lowerAsm are unimplemented (variadic clones; inline asm is cq-w3-asm).
#include "cq/Calls.h"
#include "cq/FatPtr.h"

#include "cq/Abi.h"
#include "cq/Aggregates.h"
#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
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
  for (const BasicBlock &BB : F)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (const Value *V = RI->getReturnValue()) {
        if (V->getType()->isIntegerTy())
          return packedInteger(V);
        for (const Value *v = V; auto *iv = dyn_cast<InsertValueInst>(v); v = iv->getAggregateOperand())
          if (iv->getInsertedValueOperand()->getType()->isIntegerTy() && packedInteger(iv->getInsertedValueOperand()))
            return true;
        return false;
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
    unimplemented("calls: a scalable vector across a call", at);
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
  // T4 (CR rule 21, §1.4): a pointer formal crossing as (object, tag, i32 idx[, i32 cell count]); the
  // object is the caller's host pointer, or the i32 bus handle of a Qram pointee.
  PtrAbi abi = PtrAbi::Raw;
  ObjClass pointee = ObjClass::Classical;
  unsigned digits = 0;
};

std::vector<FormalLayout> formalLayout(const TaintInfo &T, const Specialization &S, const Value *at) {
  std::vector<FormalLayout> fs;
  unsigned need = 0, nPtr = 0;
  for (Argument &A : S.F->args()) {
    FormalLayout f;
    leafTypes(A.getType(), f.leaves, &A);
    f.q = T.fieldMask(&A, S);
    if (f.q.size() != f.leaves.size())
      internalError("calls: taint's field mask of a formal does not have one entry per scalar leaf", &A);
    f.pointer = A.getType()->isPointerTy();
    for (Type *l : f.leaves)
      if (l->isPointerTy() && !f.pointer)
        unimplemented("calls: an aggregate formal with a pointer field (rule 21 fat-pointer fields)", &A);
    if (f.pointer) {
      PtrFormal pf = T.pointerFormal(S, A.getArgNo());
      f.abi = pf.abi;
      f.pointee = pf.pointee;
      f.digits = pf.digits;
      if (pf.abi == PtrAbi::Raw) {
        if (f.q[0] || T.isFatPointer(&A, S))
          internalError("calls: a fat-pointer formal taint passes as a raw pointer", &A);
        for (ObjectId o : T.provenance(&A, S))
          if (T.classOf(o) == ObjClass::Qram)
            internalError("calls: a pointer formal into a QRAM object taint passes as a raw pointer", &A);
      } else {
        // T4 triple: object, tag, idx (handles where the digits say quantum), then the cell count.
        Type *i32 = Type::getInt32Ty(A.getContext());
        f.leaves.clear();
        f.q.clear();
        bool qramObj = pf.pointee == ObjClass::Qram;
        f.leaves.push_back(qramObj ? static_cast<Type *>(i32) : A.getType());
        f.q.push_back(qramObj);
        f.leaves.push_back(i32);
        f.q.push_back(false);
        f.leaves.push_back(i32);
        f.q.push_back(false);
        if (pf.abi == PtrAbi::TripleCount) {
          f.leaves.push_back(i32);
          f.q.push_back(false);
        }
      }
      ++nPtr;
    } else {
      need += f.leaves.size();
    }
    fs.push_back(std::move(f));
  }
  // The name's digits (taint's mask) must say the same, formal by formal. A pointer formal's digits
  // describe its pointee (one per cell or record field, '1' where the caller's cell holds a handle at
  // the call, rule 20): the clone gets the caller's pointer either way and loads the handles from the
  // cells (mem-slots' clone side); the twin reads them as the forward did (uncompute keeps every rail
  // that may sit in the object until after the twin, and a write into it between the two is a
  // barrier, cq-fwto). How many digits each pointer formal has is taint's (T1, not in Taint.h): with
  // several pointer formals the digits are not split, and fieldMask alone gives the scalar formals'.
  const std::string &m = S.mask;
  if (nPtr == 0 && m.size() != need)
    unimplemented("calls: a clone whose mask has another digit count than its formals' scalar fields (a "
                  "packed-integer formal, 159: cq-0umd)",
                  at);
  size_t total = need;
  for (const FormalLayout &f : fs)
    if (f.pointer) {
      if (f.digits == 0)
        internalError("calls: a pointer formal with no mask digit", at);
      total += f.digits;
    }
  if (total != m.size())
    internalError("calls: taint's mask has another digit count than its formals (T4 digits)", at);
  size_t d = 0;
  for (FormalLayout &f : fs) {
    if (f.pointer) {
      if (f.abi != PtrAbi::Raw) {
        // The triple's tag and idx digits are the parameters' kinds.
        f.q[1] = m[d] == '1';
        f.q[2] = m[d + 1] == '1';
      }
      d += f.digits;
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
  bool anyQ() const { return is_contained(q, true); }
};

// Does a formal of S cross as a triple onto a Qram pointee (T4)?
bool hasQramTriple(const TaintInfo &T, const Specialization &S) {
  for (Argument &A : S.F->args())
    if (A.getType()->isPointerTy()) {
      PtrFormal pf = T.pointerFormal(S, A.getArgNo());
      if (pf.abi != PtrAbi::Raw && pf.pointee == ObjClass::Qram)
        return true;
    }
  return false;
}

ResultLayout resultLayout(const TaintInfo &T, const Specialization &S, const Value *at) {
  ResultLayout r;
  Type *rt = S.F->getReturnType();
  if (rt->isVoidTy()) {
    // M2 (191): a void clone storing through a QRAM triple formal returns those stores' rails.
    r.qramFormal = hasQramTriple(T, S);
    if (r.qramFormal)
      r.stores = mem::calleeQramStoreCount(T, S);
    return r;
  }
  if (!isComposite(rt) && !scalarRailType(rt) && !(rt->isPointerTy() && !T.resultQuantum(S, 0)))
    unimplemented("calls: a clone with a pointer result (rule 21 fat-pointer result: fatptr)", at);
  if (packedIntegerResult(*S.F))
    unimplemented("calls: a clone whose integer result is packed from several fields (159, 166: cq-0umd)", at);
  r.composite = isComposite(rt);
  leafTypes(rt, r.leaves, at);
  for (unsigned k = 0; k < r.leaves.size(); ++k) {
    r.q.push_back(T.resultQuantum(S, k));
    if (r.q.back() && !scalarRailType(r.leaves[k]))
      unimplemented("calls: a clone result with a quantum pointer field (rule 21: fatptr)", at);
  }
  r.qramFormal = hasQramTriple(T, S);
  if (r.qramFormal)
    r.stores = mem::calleeQramStoreCount(T, S);
  return r;
}

Type *cloneResultType(LLVMContext &C, const ResultLayout &r, Type *orig) {
  if (r.stores) {
    // M2: the result's leaves (C type where classical, handles where quantum), then one handle per store;
    // a void clone with one store returns that handle.
    if (orig->isVoidTy() && r.stores == 1)
      return handleTy(C);
    SmallVector<Type *, 4> es;
    for (unsigned k = 0; k < r.leaves.size(); ++k)
      es.push_back(r.q[k] ? handleTy(C) : r.leaves[k]);
    for (unsigned k = 0; k < r.stores; ++k)
      es.push_back(handleTy(C));
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
  bool handle;      // the result is one rail (taint's per-clone record)
  bool fieldwise;   // the result is a literal struct of fields with a handle among them
  ResultLayout res;
  // Phase 2 (CR rules 18, 20, §1.4; cq-arch T2 + M1): a caller's slot object the clone writes. extra:
  // the old contents of the cells it may write (formal order, ascending cell), the twin's trailing
  // operands; slotOuts: the handles loaded from those cells right after the call.
  SmallVector<Operand, 4> extra;
  SmallVector<Value *, 4> slotOuts;
};

// A byval formal the callee may write is a private copy (cq-09xh): the clone keeps byval and the call
// passes a snapshot. A read-only byval formal needs no copy: the clone reads the caller's object, as
// the forward call ran, and the twin reads it unchanged (a write into it before the twin is an
// uncompute barrier, cq-fwto). 164: a slot record (handle cells) passed read-only by value.
bool byvalCopied(const Argument &A) { return A.hasByValAttr() && !A.onlyReadsMemory(); }

// Does the caller's actual point into a slot object (rule 20)?
bool pointsToSlot(LoweringContext &ctx, const Value *actual) {
  for (ObjectId o : ctx.T.provenance(actual, ctx.S))
    if (ctx.T.classOf(o) == ObjClass::Slot)
      return true;
  return false;
}

// T3 (CR rules 5, 18, 20; A4): a clone rotating a caller cell's rail in place through a pointer formal
// (124's step: cq_theta through int *r). Every rail the cell may hold at the call is hit by a
// non-diagonal gate there: noteNonDiagonal, so a garbage item reading it goes before the call (or the
// rail is kept entangled), and a merged cell needs every arm kept. The cells are the scalar leaves of
// the object's C type (taint's cell indices from the object's root), read with M4 as of the call.
void noteRotatedCells(LoweringContext &ctx, CallBase &CB, const Specialization &S,
                      const std::vector<FormalLayout> &fs, CallInst *fwd, ArrayRef<unsigned> argMap = {}) {
  unsigned nArgs = argMap.empty() ? CB.arg_size() : unsigned(argMap.size());
  for (unsigned i = 0; i < nArgs && i < fs.size(); ++i) {
    if (!fs[i].pointer)
      continue;
    SmallVector<unsigned, 4> cells = ctx.T.cellsRotated(S, i);
    if (cells.empty())
      continue;
    const Value *actual = CB.getArgOperand(argMap.empty() ? i : argMap[i]);
    if (!pointsToSlot(ctx, actual))
      internalError("calls: a clone rotates a cell of an object that is not a slot object", &CB);
    const Value *root = getUnderlyingObject(actual);
    Type *cellTy = nullptr;
    if (auto *AI = dyn_cast<AllocaInst>(root); AI && !AI->isArrayAllocation()) {
      Type *t = AI->getAllocatedType();
      while (auto *AT = dyn_cast<ArrayType>(t))
        t = AT->getElementType();
      if (t->isSingleValueType() && !t->isVectorTy())
        cellTy = t;
    }
    if (!cellTy)
      unimplemented("calls: a clone rotating a cell of an object that is not a local scalar or array (a record, a "
                    "global or a heap block: T3 consumer)",
                    &CB);
    SmallVector<Operand, 8> ops = mem::readSlotCells(ctx, root, cellTy, uint64_t(cells.back()) + 1, CB);
    for (unsigned c : cells) {
      if (c >= ops.size())
        internalError("calls: readSlotCells returned fewer cells than asked", &CB);
      if (!ops[c].handle)
        internalError("calls: a clone rotates a cell that holds no handle at the call", &CB);
      ctx.unc().noteNonDiagonal(ctx.unc().idOf(ops[c].v), fwd);
    }
  }
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
  CloneCall r{nullptr, {}, false, false, resultLayout(ctx.T, S, &CB), {}, {}};
  // The pointer formals into a caller's slot object that the clone writes (T2), their old cells (M1).
  SmallVector<unsigned, 2> slotArgs;
  for (unsigned i = 0; i < nArgs && i < fs.size(); ++i)
    if (fs[i].pointer && pointsToSlot(ctx, CB.getArgOperand(op(i))) && !ctx.T.cellsWritten(S, i).empty()) {
      if (fs[i].abi != PtrAbi::Raw)
        unimplemented("calls: a clone writing a caller's slot object through a triple pointer formal (T4, M1)",
                      &CB);
      if (CB.isByValArgument(op(i)))
        unimplemented("calls: a byval slot record a clone writes (rules 20, 26: 164)", &CB);
      slotArgs.push_back(i);
      // A non-constant i32 old cell is a handle (a slot cell is homogeneous, rule 20; poison where never
      // written): a read of the twin's item. A classical i32 cell of a record would be refused by
      // recordCall's lookup, never read as a handle silently.
      for (Value *v : mem::slotCellsBeforeCall(ctx, CB, i, argMap))
        r.extra.push_back(Operand{v, !isa<Constant>(v) && v->getType()->isIntegerTy(32)});
    }
  if (S.ctl) {
    Value *f = flag ? flag : ctlFlag(ctx, CB);
    args.push_back(f);
    r.ops.push_back(Operand{f, true});
  }
  struct ByVal { unsigned k; Type *T; Align al; };
  SmallVector<ByVal, 2> byvals;
  if (nArgs != fs.size())
    unimplemented("calls: a call whose argument count differs from the callee's formals (a variadic clone per "
                  "call-site arity, CR §1.4)",
                  &CB);
  for (unsigned i = 0; i < nArgs; ++i) {
    const Value *a = CB.getArgOperand(op(i));
    if (fs[i].pointer && fs[i].abi != PtrAbi::Raw) {
      // T4 (CR rule 21, §1.4): the triple (object, tag, idx) and, for TripleCount, the cell count.
      if (CB.isByValArgument(op(i)))
        unimplemented("calls: a byval formal passed as a rule 21 triple", &CB);
      fatptr::Triple t = fatptr::passAcrossCall(ctx, a);
      Value *vs[4] = {t.object, t.tag, t.idx, t.cellCount};
      unsigned n = fs[i].abi == PtrAbi::TripleCount ? 4 : 3;
      if (n == 4 && !t.cellCount)
        internalError("calls: passAcrossCall gave no cell count for a TripleCount formal", &CB);
      for (unsigned k = 0; k < n; ++k) {
        if (!vs[k] || vs[k]->getType() != (fs[i].q[k] ? handleTy(ctx.M.getContext()) : fs[i].leaves[k]))
          internalError("calls: passAcrossCall's triple does not match the formal's T4 layout", &CB);
        args.push_back(vs[k]);
        r.ops.push_back(Operand{vs[k], fs[i].q[k]});
      }
      continue;
    }
    SmallVector<Operand, 4> leaves;
    if (isComposite(a->getType()))
      leaves = aggr::flattenResult(ctx, a);
    else
      leaves.push_back(ctx.operand(a));
    if (leaves.size() != fs[i].leaves.size())
      internalError("calls: an actual with another field count than its formal", &CB);
    for (unsigned k = 0; k < leaves.size(); ++k) {
      const Operand &o = leaves[k];
      if (fs[i].q[k] && !o.handle)
        unimplemented("calls: a measured (collapsed, rule 2) value passed where the clone's mask is quantum", &CB);
      if (!fs[i].q[k] && o.handle)
        internalError("calls: a rail passed where the clone's mask is classical", &CB);
      Value *v = o.v;
      if (CB.isByValArgument(op(i)) && byvalCopied(*S.F->getArg(i))) {
        if (pointsToSlot(ctx, a))
          unimplemented("calls: a slot record passed by value to a clone that may write its copy (the copy "
                        "would need the record's lowered layout on both sides: rules 20, 26)",
                        &CB);
        // byval (cq-09xh): the clone gets a copy of the object as of the call. The copy is made from
        // a snapshot the caller takes here, and the snapshot is what the forward and the twin receive:
        // the twin, run later, recomputes from the values the forward saw, whatever the caller has
        // written into its object since.
        Type *T = CB.getParamByValType(op(i));
        const DataLayout &DL = ctx.M.getDataLayout();
        Align al = CB.getParamAlign(op(i)).value_or(DL.getABITypeAlign(T));
        AllocaInst *snap = ctx.B().CreateAlloca(T, DL.getAllocaAddrSpace(), nullptr, "byval.snap");
        snap->setAlignment(al);
        ctx.B().CreateMemCpy(snap, al, v, al, DL.getTypeAllocSize(T));
        v = snap;
        byvals.push_back({unsigned(args.size()), T, al});
      }
      args.push_back(v);
      r.ops.push_back(Operand{v, o.handle});
    }
  }
  r.call = ctx.B().CreateCall(C, args);
  r.call->setCallingConv(C->getCallingConv());
  for (const ByVal &b : byvals) {
    r.call->addParamAttr(b.k, Attribute::getWithByValType(C->getContext(), b.T));
    r.call->addParamAttr(b.k, Attribute::getWithAlignment(C->getContext(), b.al));
  }
  r.handle = !S.F->getReturnType()->isVoidTy() && !r.res.composite && r.res.anyQ();
  r.fieldwise = r.res.composite && r.res.anyQ();
  for (unsigned i : slotArgs)
    for (Value *h : mem::slotCellsAfterCall(ctx, CB, i, r.call, argMap))
      r.slotOuts.push_back(h);
  noteRotatedCells(ctx, CB, S, fs, r.call, argMap);
  return r;
}

// Binds a field-wise result (CR §1.4: a literal struct of handles and classical values): one
// extractvalue per field right after the call, the field operands bound to CB (aggr reads them), and
// the handles recorded as the call's results, undone together by the twin (U2).
void bindFieldwiseResult(LoweringContext &ctx, CallBase &CB, CallInst *call, const ResultLayout &res,
                         ArrayRef<Value *> slotOuts = {}, ArrayRef<Operand> extra = {}) {
  SmallVector<bool, 4> tq = ctx.T.fieldMask(&CB, ctx.S);
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
  ctx.unc().recordCall(call, outs, slotOuts, extra);
  ctx.bindFields(&CB, ops);
}

// M2/U3 (191): a clone with a triple formal onto a QRAM object. Its result is the C result's leaves then one
// handle per store the clone made through such a formal (cloneResultType). The quantum leaves and the
// stored rails are the call's outs, undone together by the twin (U2); mem-qram then records the stores
// on the caller's bus, popped before the twin (U3 with U6).
void bindQramCloneResult(LoweringContext &ctx, CallBase &CB, const Specialization &S, const CloneCall &r) {
  const ResultLayout &res = r.res;
  SmallVector<Value *, 4> outs, stored;
  bool hasResult = !CB.getType()->isVoidTy();
  if (res.stores == 0) {
    if (r.fieldwise) {
      SmallVector<Operand, 4> ops;
      for (unsigned k = 0; k < res.leaves.size(); ++k) {
        Value *e = ctx.B().CreateExtractValue(r.call, {k});
        ops.push_back(Operand{e, res.q[k]});
        if (res.q[k])
          outs.push_back(e);
      }
      ctx.bindFields(&CB, ops);
    } else if (hasResult) {
      if (r.handle != ctx.T.isQuantum(&CB, ctx.S))
        internalError("calls: the call's result kind and taint's disagree", &CB);
      if (r.handle)
        outs.push_back(r.call);
      ctx.bind(&CB, r.call);
    }
  } else if (!hasResult && res.stores == 1) {
    outs.push_back(r.call);
    stored.push_back(r.call);
  } else {
    SmallVector<Operand, 4> ops;
    for (unsigned k = 0; k < res.leaves.size(); ++k) {
      Value *e = ctx.B().CreateExtractValue(r.call, {k});
      ops.push_back(Operand{e, res.q[k]});
      if (res.q[k])
        outs.push_back(e);
    }
    for (unsigned k = 0; k < res.stores; ++k) {
      Value *e = ctx.B().CreateExtractValue(r.call, {unsigned(res.leaves.size() + k)});
      outs.push_back(e);
      stored.push_back(e);
    }
    if (hasResult) {
      if (res.composite) {
        ctx.bindFields(&CB, ops);
      } else {
        if (ops.size() != 1 || ops[0].handle != ctx.T.isQuantum(&CB, ctx.S))
          internalError("calls: the call's result kind and taint's disagree", &CB);
        ctx.bind(&CB, ops[0].v);
      }
    }
  }
  if (outs.empty() && r.slotOuts.empty()) {
    // Nothing to undo: no result rail, no store (a clone that only reads the bus classically).
    if (!r.extra.empty())
      internalError("calls: old slot cells passed to a clone that reloads none", &CB);
    return;
  }
  ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
  mem::noteCalleeQramStores(ctx, CB, S, r.call, stored);
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

// Rule 27: the trailing i32 K of a declared clone is the callee's K (flag, CQ_K, global, default 4),
// resolved on the callee's C name (cq-h8vd): an LLVM math intrinsic's callee is the libm function
// (rule 18), so llvm.exp.f64 resolves as exp. LoweringContext::K keys on a Function's name: an
// existing function of that name is asked, else a declaration made for the question and erased.
Value *declaredK(LoweringContext &ctx, const Function &F, const Value *at) {
  std::string n = calleeName(F, at);
  unsigned K;
  if (n == F.getName()) {
    K = ctx.K(F);
  } else if (GlobalValue *G = ctx.M.getNamedValue(n)) {
    auto *NF = dyn_cast<Function>(G);
    if (!NF)
      unimplemented("calls: the libm name @" + n + " of an LLVM math intrinsic names a global that is not a function", at);
    K = ctx.K(*NF);
  } else {
    Function *tmp = Function::Create(F.getFunctionType(), GlobalValue::ExternalLinkage, n, &ctx.M);
    K = ctx.K(*tmp);
    tmp->eraseFromParent();
  }
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), K);
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
  Value *K = declaredK(ctx, F, &CB);
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

// Rule 14's B for a quantum-depth recursion of G (cq-5xde): a bound on the recursion depth, proved, or
// none. The proof: G recurses only through direct calls of itself (every other callee in G does not
// reach G, no use of G but a direct call as the callee); a formal i such that every recursive call passes
// arg_i + (-1) and runs only on an edge whose branch condition (icmp of arg_i against a constant)
// excludes arg_i == 0 (so arg_i - 1 never wraps unsigned and arg_i falls by exactly 1 per level); and
// every call of G from outside G that starts a chain reaching S passes an actual whose unsigned range
// is [0, B]. Then the call at level d runs only when the top-level actual is at least d + 1, so no call
// at a level d >= B runs. B is the smallest such bound over the qualifying formals. The chains reaching
// S (a level clone) start at the level-0 clones of G whose bounds are S's (taint copies a level-0
// clone's bounds into each of its levels): those calls are the ones counted.
std::optional<uint64_t> provedDepthBound(const TaintInfo &T, const Specialization &S) {
  const Function &G = *S.F;
  using namespace PatternMatch;
  SmallVector<const CallBase *, 4> rec;
  for (const BasicBlock &BB : G)
    for (const Instruction &I : BB)
      if (auto *C = dyn_cast<CallBase>(&I)) {
        const Function *Y = C->getCalledFunction();
        if (Y == &G)
          rec.push_back(C);
        else if (!Y || (!Y->isDeclaration() && reaches(Y, &G)))
          return std::nullopt;
      }
  SmallVector<const CallBase *, 4> outside;
  for (const User *u : G.users()) {
    auto *C = dyn_cast<CallBase>(u);
    if (!C || C->getCalledOperand() != &G)
      return std::nullopt;
    if (C->getFunction() == &G)
      continue;
    bool starts = false;
    for (const Specialization &SH : T.specializations())
      if (SH.F == C->getFunction())
        if (const Specialization *cs = T.calleeSpecialization(*C, SH))
          starts |= cs->F == &G && cs->depth == 0 && cs->bounds == S.bounds;
    if (starts)
      outside.push_back(C);
  }
  if (rec.empty() || outside.empty())
    return std::nullopt;
  DominatorTree DT(const_cast<Function &>(G));
  std::optional<uint64_t> best;
  for (unsigned i = 0; i < G.arg_size(); ++i) {
    const Argument *A = G.getArg(i);
    if (!A->getType()->isIntegerTy())
      continue;
    unsigned W = A->getType()->getIntegerBitWidth();
    bool ok = true;
    for (const CallBase *RC : rec) {
      if (!match(RC->getArgOperand(i), m_Add(m_Specific(A), m_AllOnes()))) {
        ok = false;
        break;
      }
      // The values arg_i can take where RC runs, from the branches whose edges dominate RC's block.
      ConstantRange allowed = ConstantRange::getFull(W);
      const BasicBlock *at = RC->getParent();
      for (auto *N = DT.getNode(at); N && N->getIDom(); N = N->getIDom()) {
        const BasicBlock *D = N->getIDom()->getBlock();
        auto *Br = dyn_cast<BranchInst>(D->getTerminator());
        if (!Br || !Br->isConditional())
          continue;
        ICmpInst::Predicate pr;
        const APInt *c;
        bool lhs = match(Br->getCondition(), m_ICmp(pr, m_Specific(A), m_APInt(c)));
        if (!lhs && match(Br->getCondition(), m_ICmp(pr, m_APInt(c), m_Specific(A))))
          pr = ICmpInst::getSwappedPredicate(pr);
        else if (!lhs)
          continue;
        for (unsigned s = 0; s < 2; ++s)
          if (Br->getSuccessor(s) != Br->getSuccessor(1 - s) &&
              DT.dominates(BasicBlockEdge(D, Br->getSuccessor(s)), at))
            allowed = allowed.intersectWith(ConstantRange::makeExactICmpRegion(
                s == 0 ? pr : ICmpInst::getInversePredicate(pr), *c));
      }
      if (allowed.contains(APInt::getZero(W))) {
        ok = false;
        break;
      }
    }
    if (!ok)
      continue;
    std::optional<uint64_t> B;
    for (const CallBase *C : outside) {
      ConstantRange R = computeConstantRange(C->getArgOperand(i), /*ForSigned=*/false, /*UseInstrInfo=*/true);
      APInt hi = R.getUnsignedMax();
      if (R.isFullSet() || R.isWrappedSet() || hi.getActiveBits() > 63) {
        B.reset();
        ok = false;
        break;
      }
      B = std::max<uint64_t>(B.value_or(0), hi.getZExtValue());
    }
    if (ok && B)
      best = best ? std::min(*best, *B) : *B;
  }
  return best;
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
  if (S.F->isVarArg())
    unimplemented("calls: a clone of a variadic function (per call-site arity, lowerVarargs)", S.F);

  SmallVector<Type *, 8> ps;
  if (S.ctl)
    ps.push_back(handleTy(C));
  for (const FormalLayout &f : formalLayout(T, S, S.F))
    for (unsigned k = 0; k < f.leaves.size(); ++k)
      ps.push_back(f.q[k] ? handleTy(C) : f.leaves[k]);
  Type *rt = cloneResultType(C, resultLayout(T, S, S.F), S.F->getReturnType());
  FunctionType *FT = FunctionType::get(rt, ps, false);

  if (Function *ex = M.getFunction(name)) {
    if (ex->getFunctionType() != FT)
      internalError("calls: clone @" + name + " exists with another type", S.F);
    return ex;
  }
  Function *NF = Function::Create(FT, GlobalValue::InternalLinkage, name, &M);
  NF->setCallingConv(S.F->getCallingConv());
  // A byval formal the callee may write stays byval (cq-09xh): the clone writes its own copy, never
  // the caller's object. A read-only one is the caller's pointer (byvalCopied).
  unsigned p = S.ctl ? 1 : 0;
  std::vector<FormalLayout> fl = formalLayout(T, S, S.F);
  for (Argument &A : S.F->args()) {
    if (byvalCopied(A)) {
      NF->addParamAttr(p, Attribute::getWithByValType(C, A.getParamByValType()));
      if (MaybeAlign al = A.getParamAlign())
        NF->addParamAttr(p, Attribute::getWithAlignment(C, *al));
    }
    if (A.hasInAllocaAttr() || A.hasPreallocatedAttr())
      unimplemented("calls: an inalloca or preallocated formal of a clone", &A);
    p += unsigned(fl[A.getArgNo()].leaves.size());
  }
  return NF;
}

void lowerLifted(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!cs && isCutRecursion(ctx, CB)) {
    // Rule 14: the recursive call at the cut level C = ctx.S.depth (taint publishes no deeper level).
    // The cut is a |0> seed only when a proved depth bound B has B <= C (no call at level C runs);
    // taint's cut level comes from the actual's range, which bounds the depth only under the proof
    // (cq-5xde). A proved B > C (taint cut too early) or no proof: the kept overflow predicate.
    const Function &G = *CB.getCalledFunction();
    unsigned K = ctx.K(G);
    std::optional<uint64_t> B;
    if (ctx.S.F == &G)
      B = provedDepthBound(ctx.T, ctx.S);
    if (B && *B > ctx.S.depth && *B <= K)
      unimplemented("calls: a quantum-depth recursion cut at level " + std::to_string(ctx.S.depth) +
                        " below its proved depth bound " + std::to_string(*B) + " (rule 14)",
                    &CB);
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
  if (r.res.qramFormal)
    return bindQramCloneResult(ctx, CB, *cs, r);
  if (r.fieldwise)
    return bindFieldwiseResult(ctx, CB, r.call, r.res, r.slotOuts, r.extra);
  if (!r.slotOuts.empty() || !r.extra.empty()) {
    // Phase 2: the result (if a handle) and the reloaded cells are one call's results, undone together
    // by the twin <clone>_unc(out?, args..., old cells...) (U2).
    SmallVector<Value *, 1> outs;
    if (!CB.getType()->isVoidTy()) {
      bool q = ctx.T.isQuantum(&CB, ctx.S);
      if (r.handle != q)
        internalError("calls: the call's result kind and taint's disagree", &CB);
      if (r.handle)
        outs.push_back(r.call);
      ctx.bind(&CB, r.call);
    }
    if (r.slotOuts.empty())
      internalError("calls: old slot cells passed to a clone that reloads none", &CB);
    ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
    return;
  }
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
      if (r.res.qramFormal)
        unimplemented("calls: an indirect-call candidate with a triple formal onto a QRAM object (U3)", &CB);
      if (!r.slotOuts.empty() || !r.extra.empty())
        unimplemented("calls: an indirect-call candidate that writes a caller's slot object (the merge of its "
                      "reloaded cells)",
                      &CB);
      if (r.fieldwise)
        unimplemented("calls: an indirect call whose candidates return several fields with a handle (the merge "
                      "of literal structs of handles)",
                      &CB);
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

namespace cq::calls {
// C1 (cq-arch 2026-11-01): stub until stream A builds it.
// C1 (CR rule 24, 106): site is lowered as the direct call of taint's callee specialization for it (the
// start routine's clone at a pthread_create), formal k taking site's operand argMap[k]. M1 (with the map),
// recordCall and the twin as for a plain clone call. site's own result is the consumer's to bind; the
// clone's result is a result of the call group (undone by the twin) and bound to nothing.
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
  CloneCall r = emitCloneCall(ctx, site, *cs, flag, argMap);
  if (r.res.qramFormal)
    unimplemented("calls: lowerLiftedVia of a clone with a triple formal onto a QRAM object (U3)", &site);
  SmallVector<Value *, 4> outs;
  if (r.fieldwise) {
    for (unsigned k = 0; k < r.res.leaves.size(); ++k)
      if (r.res.q[k])
        outs.push_back(ctx.B().CreateExtractValue(r.call, {k}));
  } else if (r.handle) {
    outs.push_back(r.call);
  }
  if (outs.empty() && r.slotOuts.empty()) {
    if (!r.extra.empty())
      internalError("calls: old slot cells passed to a clone that reloads none", &site);
    return;
  }
  ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
}
} // namespace cq::calls
