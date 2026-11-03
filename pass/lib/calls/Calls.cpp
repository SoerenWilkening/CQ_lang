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
#include "cq/FatPtr.h"

#include "cq/Abi.h"
#include "cq/Aggregates.h"
#include "cq/Common.h"
#include "cq/Effects.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "../spine/SpineInternal.h"
#include "../mem/slots/SlotsInternal.h"
#include "../fatptr/FatPtrInternal.h"

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

bool carriesOverflow(const TaintInfo &T, const Specialization &S);

const TaintInfo &taintOf(const Specialization &S) {
  if (!runTaint)
    internalError("calls: materialize of a clone before any call site of the run was lowered (no TaintInfo)", S.F);
  ArrayRef<Specialization> all = runTaint->specializations();
  if (S.kept) {
    // cq-i9wk: a kept clone is calls' own (keptSpec), answered by taint as its in-place specialization.
    for (const Specialization &P : all)
      if (P.F == S.F && P.isEntry())
        return *runTaint;
  } else if (!all.empty() && &S >= all.begin() && &S < all.end()) {
    return *runTaint;
  }
  internalError("calls: materialize of a specialization that is not one of the run's TaintInfo", S.F);
}

abi::CloneSpec cloneSpecOf(const Specialization &S) {
  return abi::CloneSpec{S.F->getName().str(), S.mask, S.bounds, S.ctl, S.pure, S.depth, false};
}

bool sameFields(const abi::CloneSpec &a, const abi::CloneSpec &b) {
  return a.fn == b.fn && a.mask == b.mask && a.bounds == b.bounds && a.ctl == b.ctl && a.pure == b.pure &&
         a.depth == b.depth && a.unc == b.unc && a.inv == b.inv;
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
  // T4 (CR rule 21, §1.4): a pointer formal crossing as (object, tag, i32 idx[, i32 cell count]); the
  // object is the caller's host pointer, or the i32 bus handle of a Qram pointee.
  PtrAbi abi = PtrAbi::Raw;
  ObjClass pointee = ObjClass::Classical;
  unsigned digits = 0;
  // cq-0umd (rule 26): an integer formal the callee unpacks into fields (159's coerced struct): one
  // leaf per field at spine::unpackCuts, the digits the mask's.
  SmallVector<unsigned, 4> cuts;
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
    } else {
      need += f.leaves.size();
    }
    fs.push_back(std::move(f));
  }
  // CR §1.4 (95, 109): a variadic function's clone is per call-site arity; its formals past the fixed
  // ones are the call's variadic actuals, one digit each (the mask's last digits), of the actuals' types.
  if (S.F->isVarArg()) {
    SmallVector<VariadicActual, 4> vt = variadicActuals(T, S, at);
    for (const VariadicActual &va : vt) {
      FormalLayout f;
      f.leaves.push_back(va.ty);
      f.q.push_back(false);
      need += 1;
      fs.push_back(std::move(f));
    }
    // A pointer formal contributes its own digits (T4: taint's pointerFormal), before the variadic ones.
    size_t ptrDigits = 0;
    for (const FormalLayout &f : fs)
      if (f.pointer)
        ptrDigits += f.digits;
    if (S.mask.size() != need + ptrDigits)
      internalError("calls: a variadic clone whose mask is not one digit per fixed field and variadic actual", at);
    for (size_t k = 0; k < vt.size(); ++k) {
      bool q = S.mask[S.mask.size() - vt.size() + k] == '1';
      fs[fs.size() - vt.size() + k].q[0] = q;
      // A quantum actual crosses as its one handle and its save-area cell holds that handle (rule 20's
      // uniform slot array). A quantum pointer (rule 21's fat pointer in a pointer-kind cell), a quantum
      // vector (rule 25's lanes) or a quantum aggregate passed in memory has no one-handle cell.
      if (q && (!vaScalar(vt[k].ty) || vt[k].ty->isPointerTy() || vt[k].byval))
        unimplemented("calls: a quantum variadic actual that is a pointer, a vector or an aggregate in memory "
                      "(its save-area cell is no one handle: rules 21, 25, 26 in the variadic save area)",
                      at);
    }
  }
  // The name's digits (taint's mask) must say the same, formal by formal. A pointer formal's digits
  // describe its pointee (one per cell or record field, '1' where the caller's cell holds a handle at
  // the call, rule 20): the clone gets the caller's pointer either way and loads the handles from the
  // cells (mem-slots' clone side); the twin reads them as the forward did (uncompute keeps every rail
  // that may sit in the object until after the twin, and a write into it between the two is a
  // barrier, cq-fwto). How many digits each pointer formal has is taint's (T1, not in Taint.h): with
  // several pointer formals the digits are not split, and fieldMask alone gives the scalar formals'.
  const std::string &m = S.mask;
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
    if (f.cuts.size() > 2) {
      for (unsigned k = 0; k < f.q.size(); ++k)
        f.q[k] = m[d++] == '1';
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
  // Rule 21 (85): a quantum pointer result is the fat pointer {i32 tag, i32 idx}, both handles, in the
  // caller's object table (fatptr: the clone's result roots are its triple formals and NULL, tag 0).
  bool fatPtr = false;
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
  if (rt->isPointerTy() && T.resultQuantum(S, 0)) {
    Type *i32 = Type::getInt32Ty(rt->getContext());
    r.composite = r.fatPtr = true;
    r.leaves = {i32, i32};
    r.q = {true, true};
    // Rules 18, 21, M2 (85 with 191): the fat pointer's two fields, then one handle per store the clone makes
    // through a triple formal onto a QRAM (cloneResultType), as after any other result's leaves.
    r.qramFormal = hasQramTriple(T, S);
    if (r.qramFormal)
      r.stores = mem::calleeQramStoreCount(T, S);
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

// x & y into a fresh i1 rail (and_i1, recorded: the uncompute spine undoes it).
Value *andRail(LoweringContext &ctx, Value *x, Value *y) {
  RailType i1{Kind::Int, 1};
  CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
  RailId id = ctx.unc().recordSeed(t);
  abi::CoreSpec spec{abi::Core::AndI1, i1};
  CallInst *g = ctx.emitCore(spec, {x, y, t});
  ctx.unc().recordCore(g, spec, {Operand{x, true}, Operand{y, true}, Operand{t, true}}, id);
  return t;
}

// x | y into a fresh i1 rail (or_i1, recorded).
Value *orRail(LoweringContext &ctx, Value *x, Value *y) {
  RailType i1{Kind::Int, 1};
  CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
  RailId id = ctx.unc().recordSeed(t);
  abi::CoreSpec spec{abi::Core::OrI1, i1};
  CallInst *g = ctx.emitCore(spec, {x, y, t});
  ctx.unc().recordCore(g, spec, {Operand{x, true}, Operand{y, true}, Operand{t, true}}, id);
  return t;
}

// A copy of x in a fresh i1 rail (alloc_i1(0), copy_i1, recorded).
Value *copyRail(LoweringContext &ctx, Value *x) {
  RailType i1{Kind::Int, 1};
  CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(ctx.M.getContext())});
  RailId id = ctx.unc().recordSeed(t);
  abi::CoreSpec spec{abi::Core::Copy, i1};
  CallInst *g = ctx.emitCore(spec, {x, t});
  ctx.unc().recordCore(g, spec, {Operand{x, true}, Operand{t, true}}, id);
  return t;
}

// One recursive call site's term of its level's predicate: a fresh rail the level's return reads, pinned so no
// flush before the return uncomputes it.
void addOverflowArm(LoweringContext &ctx, Value *c) {
  ctx.unc().pin(ctx.unc().idOf(c));
  spine::shared(ctx).overflowArms.push_back(c);
}

// A cut call keeping the overflow predicate: its term is the predicate it runs under (|1> when none).
void overflowAtCut(LoweringContext &ctx, const CallBase &CB) {
  if (underQuantumPredicate(ctx))
    return addOverflowArm(ctx, copyRail(ctx, ctlFlag(ctx, CB)));
  CallInst *one = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}},
                               {ConstantInt::getTrue(ctx.M.getContext())});
  ctx.unc().recordSeed(one);
  addOverflowArm(ctx, one);
}

// After a call of a clone returning the overflow predicate ovf (a result of the call, zeroed by its twin), made
// under the quantum predicate p (nullptr: none, or a _ctl call: its clone's predicates, ovf's terms included,
// are conjoined with its entry flag p already). A call of the next level from a level returning the predicate
// is a term of that level's (p & ovf); any other caller keeps p & ovf in a fresh rail.
void overflowAfterCall(LoweringContext &ctx, Value *ovf, Value *p, bool level) {
  if (level)
    return addOverflowArm(ctx, p ? andRail(ctx, p, ovf) : copyRail(ctx, ovf));
  ctx.unc().setRole(ctx.unc().idOf(p ? andRail(ctx, p, ovf) : copyRail(ctx, ovf)), Role::KeptOverflow);
}

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
  // Phase 2 (CR rules 18, 20, §1.4; cq-arch T2 + M1): a caller's slot object the clone writes. extra:
  // the old contents of the cells it may write (formal order, ascending cell), the twin's trailing
  // operands; slotOuts: the handles loaded from those cells right after the call.
  SmallVector<Operand, 4> extra;
  SmallVector<Value *, 4> slotOuts;
  // CR rule 14 with rule 19 (cq-ew5z): a level clone returning the overflow predicate after its base result
  // (materialize). ovf: the handle of that rail, a result of the call undone by the twin with the others (the
  // last out); value: the base result as the binders read it (the call itself when the base is a struct, whose
  // fields keep their indices; the scalar field 0; nullptr for a void base). Without it, ovf is null and value
  // is the call.
  Value *ovf = nullptr;
  Value *value = nullptr;
};

// A byval formal the callee may write is a private copy (cq-09xh): the clone keeps byval and the call
// passes a snapshot. A read-only byval formal needs no copy: the clone reads the caller's object, as
// the forward call ran, and the twin reads it unchanged (a write into it before the twin is an
// uncompute barrier, cq-fwto). 164: a slot record (handle cells) passed read-only by value.
bool byvalCopied(const Argument &A) { return A.hasByValAttr() && !A.onlyReadsMemory(); }

// cq-09xh: the snapshot of byval actual k of CB (lowered: obj) the clone's copy is made from, its byval type and
// alignment. cq-dd3q (CR rules 20, 26): a slot record's snapshot is its lowered record (handle cells and classical
// cells, rule 20) copied whole, so the copy names the caller's rails, which the call only reads; the clone's own
// byval formal is that layout (mem-slots decideFields: the caller's fields hold a handle where the clone's do,
// the clone's writes included, cloneWritesCell).
std::tuple<Value *, Type *, Align> byvalSnapshot(LoweringContext &ctx, CallBase &CB, unsigned k, Value *obj,
                                                 bool slot) {
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *T = CB.getParamByValType(k);
  Align al = CB.getParamAlign(k).value_or(DL.getABITypeAlign(T));
  if (slot) {
    // The clone's formal is a record of the byval type's fields (rule 26); the caller's object must be laid out as
    // that record (mem-slots: a struct read across its fields is byte cells instead, 63).
    ArrayRef<ObjectId> objs = ctx.T.provenance(CB.getArgOperand(k), ctx.S);
    if (objs.size() != 1 ||
        !mem::slotLayout(ctx, getUnderlyingObject(CB.getArgOperand(k)), objs.front(), CB).record)
      unimplemented("calls: a slot record passed by value to a clone that may write its copy (the copy "
                    "would need the record's lowered layout on both sides: rules 20, 26)",
                    &CB);
    // The lowered record: a local's (mem-slots allocateSlots: one alloca of its record type) or a clone's own byval
    // formal handed on (its byval type is its record's, decideFields).
    if (auto *rec = dyn_cast<AllocaInst>(obj); rec && !rec->isArrayAllocation()) {
      T = rec->getAllocatedType();
      al = std::max(al, rec->getAlign());
    } else if (auto *A = dyn_cast<Argument>(obj); A && A->hasByValAttr()) {
      T = A->getParamByValType();
    } else {
      internalError("calls: a byval actual that is not the start of its object (clang passes a byval "
                    "aggregate's own temporary or the aggregate itself)",
                    &CB);
    }
  }
  AllocaInst *snap = ctx.B().CreateAlloca(T, DL.getAllocaAddrSpace(), nullptr, "byval.snap");
  snap->setAlignment(al);
  ctx.B().CreateMemCpy(snap, al, obj, al, DL.getTypeAllocSize(T));
  return {snap, T, al};
}

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
// A by-value formal is a copy (C semantics, owner 2026-11-02, cq-c09h): a clone's cq_theta on it rotates
// a copy the clone mints (spine beginPreRotation), never the caller's rail, so only pointer formals hit.
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
    if (cells.front() == TaintInfo::kAnyCell) {
      // cq-budv (117): a rotation at a variable offset may hit any cell: every rail the object's cells may
      // hold at the call is hit by a non-diagonal gate there.
      for (Value *h : mem::slotRailsMayHold(ctx, actual, CB))
        ctx.unc().noteNonDiagonal(ctx.unc().idOf(h), fwd);
      continue;
    }
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
  SmallVector<unsigned, 2> slotArgs, tableArgs;
  for (unsigned i = 0; i < nArgs && i < fs.size(); ++i) {
    if (fs[i].pointer && fs[i].abi != PtrAbi::Raw && fatptr::slotTableActual(ctx, CB.getArgOperand(op(i)))) {
      // M7 (129): a fat pointer over local slot objects crosses as their object table; the clone's writes are
      // reloaded after the call (fatptr::afterSlotTableCall).
      if (!argMap.empty() || CB.isByValArgument(op(i)))
        unimplemented("calls: a slot object table passed through an argument map or by value (M7)", &CB);
      tableArgs.push_back(i);
      continue;
    }
    // cq-dd3q (CR rules 20, 26; cq-09xh): a byval actual is the callee's own copy (C semantics): the clone writes
    // the copy it is handed (byvalSnapshot), never the caller's cells, so the caller reloads nothing (no slot
    // result) and its rails in the record are only read by the call (slotRailsReadByCall).
    if (fs[i].pointer && pointsToSlot(ctx, CB.getArgOperand(op(i))) && !ctx.T.cellsWritten(S, i).empty() &&
        !CB.isByValArgument(op(i))) {
      // A triple formal (rule 21) names the same caller cells as a raw one: the clone writes them through the
      // object, the caller reads their new handles after the call (M1) whatever the ABI.
      slotArgs.push_back(i);
      // A non-constant i32 old cell is a handle (a slot cell is homogeneous, rule 20; poison where never
      // written): a read of the twin's item. A classical i32 cell of a record would be refused by
      // recordCall's lookup, never read as a handle silently.
      for (Value *v : mem::slotCellsBeforeCall(ctx, CB, i, argMap))
        r.extra.push_back(Operand{v, !isa<Constant>(v) && v->getType()->isIntegerTy(32)});
    }
  }
  if (S.ctl) {
    Value *f = flag ? flag : ctlFlag(ctx, CB);
    args.push_back(f);
    r.ops.push_back(Operand{f, true});
  }
  struct ByVal { unsigned k; Type *T; Align al; };
  SmallVector<ByVal, 2> byvals;
  // A direct call's arity is its callee's (a mismatched call is indirect: getCalledFunction is null), the
  // variadic actuals being formals of the per-arity clone (formalLayout); an argument map names one operand
  // per formal (lowerLiftedVia).
  if (nArgs != fs.size())
    internalError("calls: a call whose argument count differs from the clone's formals", &CB);
  for (unsigned i = 0; i < nArgs; ++i) {
    const Value *a = CB.getArgOperand(op(i));
    if (fs[i].pointer && fs[i].abi != PtrAbi::Raw) {
      // T4 (CR rule 21, §1.4): the triple (object, tag, idx) and, for TripleCount, the cell count. cq-2cl6: the
      // frame copy of the caller's cells this clone hands on is one object of its own: (frame, 1, 0, its cells).
      fatptr::Triple t;
      if (Value *frame = is_contained(slotArgs, i) ? mem::paramCellFrame(ctx, CB, i) : nullptr) {
        auto *fa = cast<AllocaInst>(frame);
        Type *i32 = Type::getInt32Ty(ctx.M.getContext());
        t = fatptr::Triple{frame, ConstantInt::get(i32, 1), ConstantInt::get(i32, 0),
                           ConstantInt::get(i32, cast<ArrayType>(fa->getAllocatedType())->getNumElements())};
      } else {
        t = fatptr::passAcrossCall(ctx, a);
      }
      // A byval formal the callee may write (cq-09xh) crossing as a triple: its object is a snapshot of the
      // caller's object as of the call, passed byval (the clone keeps byval on the object parameter), so the
      // forward and the twin see the same copy whatever the caller writes later. A read-only one is the
      // caller's object itself.
      bool snapByval = op(i) < S.F->arg_size() && CB.isByValArgument(op(i)) && byvalCopied(*S.F->getArg(i));
      if (snapByval) {
        if (fs[i].pointee == ObjClass::Qram)
          internalError("calls: a byval formal onto a QRAM object (a byval copy is host memory)", &CB);
        auto *idx0 = dyn_cast<ConstantInt>(t.idx);
        if (!idx0 || !idx0->isZero())
          internalError("calls: a byval actual that is not the start of its object (clang passes a byval "
                        "aggregate's own temporary or the aggregate itself)",
                        &CB);
        auto [snap, BT, al] = byvalSnapshot(ctx, CB, op(i), t.object, fs[i].pointee != ObjClass::Classical);
        t.object = snap;
        byvals.push_back({unsigned(args.size()), BT, al});
      }
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
    if (Value *frame = fs[i].pointer && is_contained(slotArgs, i) ? mem::paramCellFrame(ctx, CB, i) : nullptr)
      leaves.push_back(Operand{frame, false});   // cq-2cl6: the frame copy of the caller's cells this clone hands on
    else if (fs[i].cuts.size() > 2)
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
      Value *v = o.v;
      if (op(i) < S.F->arg_size() && CB.isByValArgument(op(i)) && byvalCopied(*S.F->getArg(i))) {
        // byval (cq-09xh): the clone gets a copy of the object as of the call. The copy is made from
        // a snapshot the caller takes here, and the snapshot is what the forward and the twin receive:
        // the twin, run later, recomputes from the values the forward saw, whatever the caller has
        // written into its object since.
        auto [snap, T, al] = byvalSnapshot(ctx, CB, op(i), v, pointsToSlot(ctx, a));
        v = snap;
        byvals.push_back({unsigned(args.size()), T, al});
      }
      args.push_back(v);
      r.ops.push_back(Operand{v, o.handle});
    }
  }
  if (fenv::cloneCarriesEnv(ctx.T, S)) {
    // E1 (82) beside the caller's cells (163's slot results, rules 18, 20) and QRAM stores (191): the mode and
    // flags trail the formals' fields, whatever the formals are.
    for (const Operand &e : fenv::envArgs(ctx, CB)) {   // mode (classical), flags (a handle the twin reads)
      args.push_back(e.v);
      r.ops.push_back(e);
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
  for (unsigned i : tableArgs)
    for (Value *h : fatptr::afterSlotTableCall(ctx, CB, i, S, r.call))
      r.slotOuts.push_back(h);
  // cq-567j: a pointer into caller slot objects the clone only reads: their rails are read by the call.
  for (unsigned i = 0; i < nArgs && i < fs.size(); ++i)
    if (fs[i].pointer && !is_contained(slotArgs, i) && !is_contained(tableArgs, i) &&
        pointsToSlot(ctx, CB.getArgOperand(op(i))))
      mem::slotRailsReadByCall(ctx, CB, i, r.call, argMap);
  mem::noteProgramSlotCall(ctx, CB, S, r.call);   // 102: a _ctl clone's guarded store into a program slot
  noteRotatedCells(ctx, CB, S, fs, r.call, argMap);
  r.value = r.call;
  if (Type *base = spine::keptCloneBaseType(*C); base && !S.kept && carriesOverflow(ctx.T, S)) {
    // cq-ew5z: {base fields..., ovf} or the ovf handle alone (materialize).
    if (base->isVoidTy()) {
      r.ovf = r.call;
      r.value = nullptr;
    } else {
      auto *st = cast<StructType>(r.call->getType());
      r.ovf = ctx.B().CreateExtractValue(r.call, {st->getNumElements() - 1});
      if (!isa<StructType>(base))
        r.value = ctx.B().CreateExtractValue(r.call, {0u});
    }
  }
  return r;
}

// Binds a field-wise result (CR §1.4: a literal struct of handles and classical values): one
// extractvalue per field right after the call, the field operands bound to CB (aggr reads them), and
// the handles recorded as the call's results, undone together by the twin (U2).
void bindFieldwiseResult(LoweringContext &ctx, CallBase &CB, CallInst *call, const ResultLayout &res,
                         ArrayRef<Value *> slotOuts = {}, ArrayRef<Operand> extra = {}, Value *ovf = nullptr) {
  SmallVector<bool, 4> tq = ctx.T.fieldMask(&CB, ctx.S);
  if (res.cuts.size() > 2 || !res.leafFields.empty() || res.fatPtr)
    tq = res.q;   // cq-0umd: a packed integer result's fields are the callee's (resultQuantum); 85: {tag, idx}
  if (res.fatPtr && !ctx.T.isFatPointer(&CB, ctx.S))
    internalError("calls: a clone's fat-pointer result where taint says the call's pointer is not fat", &CB);
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
  if (ovf)
    outs.push_back(ovf);   // cq-ew5z: the overflow predicate, the clone's last field
  ctx.unc().recordCall(call, outs, slotOuts, extra);
  fatptr::finishSlotTableCall(ctx, call);
  mem::finishParamCells(ctx, call);
  if (!res.leafFields.empty())
    aggr::bindLeafFields(ctx, &CB, ops, res.leafFields);   // 166: a packed leaf's fields
  else
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
  if (!res.leafFields.empty())
    unimplemented("calls: a QRAM-triple clone whose aggregate result has a packed integer leaf (166 with 191)", &CB);
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
        outs.push_back(r.value);
      ctx.bind(&CB, r.value);
    }
  } else if (!hasResult && res.stores == 1) {
    outs.push_back(r.value);
    stored.push_back(r.value);
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
  if (r.ovf)
    outs.push_back(r.ovf);   // cq-ew5z: the overflow predicate, the clone's last field
  if (outs.empty() && r.slotOuts.empty()) {
    // Nothing to undo: no result rail, no store (a clone that only reads the bus classically).
    if (!r.extra.empty())
      internalError("calls: old slot cells passed to a clone that reloads none", &CB);
    return;
  }
  ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
  fatptr::finishSlotTableCall(ctx, r.call);
  mem::finishParamCells(ctx, r.call);
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

// Rule 27 Cutoff for a callee known only by its host address (cq-sd95): no name, so neither a per-function flag
// nor a CQ_K line names it; the global flag, else the default (§0).
Value *resolvedK(LoweringContext &ctx) {
  Function *tmp = Function::Create(FunctionType::get(Type::getVoidTy(ctx.M.getContext()), false),
                                   GlobalValue::ExternalLinkage, "", &ctx.M);
  unsigned K = ctx.K(*tmp);
  tmp->eraseFromParent();
  return ConstantInt::get(Type::getInt32Ty(ctx.M.getContext()), K);
}

// CR §1.3 clone_resolve(fp, kind): the registered clone of the function at host address fp (0 forward, 1 _ctl).
Value *resolveClone(LoweringContext &ctx, Value *fp, unsigned kind) {
  return ctx.B().CreateCall(abi::declare(ctx.M, abi::CoreSpec{abi::Core::CloneResolve}),
                            {fp, ctx.B().getInt32(kind)});
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
  Value *K = Fp ? declaredK(ctx, *Fp, &CB) : resolvedK(ctx);
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
    call = ctx.B().CreateCall(FT, resolveClone(ctx, resolved, ctl ? 1 : 0), args);   // C calling convention
  } else {
    abi::CloneSpec cs{calleeName(*Fp, &CB), mask.str(), {}, ctl, false, 0, false};
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
          starts |= cs->F == &G && cs->depth == 0 && cs->bounds == S.bounds && cs->boundFormals == S.boundFormals;
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

// Rule 14 (recursion with quantum depth): the cut call keeps the overflow predicate "the cut level would
// recurse once more" iff B > K or no bound is proved; with B <= K no call at the cut level runs (98).
bool cutKeepsOverflow(unsigned K, std::optional<uint64_t> B) { return !B || *B > K; }

// isCutRecursion over taint alone (no lowering context): CB, a call of S's body, is a recursive call taint cut.
bool cutCall(const TaintInfo &T, const Specialization &S, const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  if (!G || G->isDeclaration() || S.isEntry() || T.calleeSpecialization(CB, S) || !reaches(G, S.F))
    return false;
  if (classify(CB, T, S) != Class::Lift)
    return false;
  bool q = !CB.getType()->isVoidTy() && T.isQuantum(&CB, S);
  for (const Use &u : CB.args())
    q |= T.isQuantum(u.get(), S);
  return q;
}

// CR rule 14 with rule 19's extra result (cq-ew5z): does the clone of S return the overflow predicate of a
// quantum-depth recursion as an extra result? S is a clone (neither the in-place body nor a kept clone,
// whose ABI is the C one or rule 19's registers) whose body has a cut call keeping the predicate (B > K or
// no bound), or a direct call of the next level (depth + 1) whose clone returns one. Each level returns the
// predicate up to the level below it; the first caller outside the chain keeps it.
bool carriesOverflow(const TaintInfo &T, const Specialization &S) {
  if (!runKO || !S.F || S.F->isDeclaration() || S.isEntry() || S.kept)
    return false;
  SmallPtrSet<const BasicBlock *, 32> seen{&S.F->getEntryBlock()};
  SmallVector<const BasicBlock *, 32> work{&S.F->getEntryBlock()};
  while (!work.empty()) {
    const BasicBlock *BB = work.pop_back_val();
    for (const Instruction &I : *BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      const Function *G = CB ? CB->getCalledFunction() : nullptr;
      if (!G || G->isDeclaration())
        continue;
      if (const Specialization *cs = T.calleeSpecialization(*CB, S)) {
        if (cs->F == G && cs->depth == S.depth + 1 && carriesOverflow(T, *cs))
          return true;
        continue;
      }
      if (cutCall(T, S, *CB)) {
        std::optional<uint64_t> B;
        if (S.F == G)
          B = provedDepthBound(T, S);
        if (cutKeepsOverflow(loops::resolveK(*G, *runKO), B))
          return true;
      }
    }
    for (const BasicBlock *X : successors(BB))
      if (seen.insert(X).second)
        work.push_back(X);
  }
  return false;
}

} // namespace

bool overflowResult(const Specialization &S) { return runTaint && carriesOverflow(*runTaint, S); }

Value *overflowOfLevel(LoweringContext &ctx) {
  SmallVector<Value *, 2> arms;
  arms.swap(spine::shared(ctx).overflowArms);
  IRBuilder<> &B = ctx.B();
  BasicBlock *at = B.GetInsertBlock();
  Function &F = *at->getParent();
  LLVMContext &C = ctx.M.getContext();
  RailType i1{Kind::Int, 1};
  for (Value *c : arms)
    ctx.unc().unpin(ctx.unc().idOf(c));
  DominatorTree DT(F);
  SmallVector<Value *, 2> terms;
  for (Value *c : arms) {
    BasicBlock *cb = cast<Instruction>(c)->getParent();
    if (DT.dominates(cb, at)) {
      terms.push_back(c);
      continue;
    }
    // A call site in a classical arm (rule 9): its term on the paths through it, a |0> seed elsewhere (minted
    // in the entry, before every branch), merged by classical phis.
    CallInst *z;
    {
      IRBuilderBase::InsertPointGuard guard(B);
      BasicBlock &E = F.getEntryBlock();
      B.SetInsertPoint(E.getTerminator());
      z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(C)});
      ctx.unc().recordSeed(z);
    }
    SmallVector<PHINode *, 4> phis;
    SSAUpdater up(&phis);
    up.Initialize(handleTy(C), "cq.ovf");
    up.AddAvailableValue(&F.getEntryBlock(), z);
    up.AddAvailableValue(cb, c);
    Value *v = up.GetValueInMiddleOfBlock(at);
    DenseMap<const BasicBlock *, unsigned> order;
    for (BasicBlock *b : ReversePostOrderTraversal<Function *>(&F))
      order[b] = unsigned(order.size());
    llvm::sort(phis, [&](PHINode *a, PHINode *b) { return order.lookup(a->getParent()) < order.lookup(b->getParent()); });
    for (PHINode *phi : phis)
      ctx.unc().recordMerge(phi);
    terms.push_back(v);
  }
  if (terms.empty()) {
    // No recursive call site lowered on any path (the body's cut call lies where the walk emits nothing): the
    // predicate is 0.
    CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i1}, {ConstantInt::getFalse(C)});
    ctx.unc().recordSeed(z);
    return z;
  }
  Value *acc = terms.front();
  for (size_t k = 1; k < terms.size(); ++k)
    acc = orRail(ctx, acc, terms[k]);
  return acc;
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
  // Rule 19 (cq-i9wk): a kept clone returns, after all of the above, the handle of each register it minted
  // that is still allocated at its return (spine::liveRegisters, counted by its in-place lowering).
  Type *keptBase = nullptr;
  unsigned keptRegs = 0;
  if (S.kept) {
    const spine::EntryReturn *er = spine::entryReturn(*S.F);
    if (!er)
      internalError("calls: materialize of a kept clone before its in-place lowering", S.F);
    keptRegs = er->registers;
    if (keptRegs) {
      keptBase = rt;
      SmallVector<Type *, 4> es;
      if (auto *st = dyn_cast<StructType>(rt))
        es.append(st->element_begin(), st->element_end());
      else
        es.push_back(rt);
      es.append(keptRegs, handleTy(C));
      rt = StructType::get(C, es);
    }
  }
  // CR rule 14 with rule 19's extra result (cq-ew5z): a level of a quantum-depth recursion whose cut keeps the
  // overflow predicate returns, after all of the above, the handle of a fresh i1 rail holding it (copied out
  // like a result, zeroed by the twin with the results): the handle alone for an otherwise void clone, else
  // the base result's fields (or the one scalar) followed by it. The spine builds the base as for any clone
  // (the base type, keptCloneBaseType) and appends the rail (Walker::emitOverflowReturn).
  Type *ovfBase = nullptr;
  if (!S.kept && carriesOverflow(T, S)) {
    ovfBase = rt;
    if (rt->isVoidTy()) {
      rt = handleTy(C);
    } else {
      SmallVector<Type *, 4> es;
      if (auto *st = dyn_cast<StructType>(rt))
        es.append(st->element_begin(), st->element_end());
      else
        es.push_back(rt);
      es.push_back(handleTy(C));
      rt = StructType::get(C, es);
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
  if (keptBase) {
    spine::setKeptCloneBaseType(*NF, keptBase);
    NF->addFnAttr(spine::kKeptRegistersAttr, std::to_string(keptRegs));
  }
  if (ovfBase)
    spine::setKeptCloneBaseType(*NF, ovfBase);
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
    // CR §0: x86-64 only; inalloca and preallocated are the 32-bit Windows C++ ABI's.
    if (A.hasInAllocaAttr() || A.hasPreallocatedAttr())
      internalError("calls: an inalloca or preallocated formal (no x86-64 C function has one, CR §0)", &A);
    p += unsigned(fl[A.getArgNo()].leaves.size());
  }
  return NF;
}

// E1 (CR rule 23, 82): the result of a clone carrying the environment. Its last field is the new flags
// handle: the call's outs are the result (when a handle) then the flags, undone together by the twin (U2),
// and the caller's FLAGS become the returned rail (fenv::afterCloneCall).
namespace {
void cleanDeadCells(LoweringContext &ctx, CallBase &CB, const Specialization &S, const CloneCall &r,
                    ArrayRef<Value *> outs);
} // namespace

void bindEnvResult(LoweringContext &ctx, CallBase &CB, const Specialization &S, const CloneCall &r) {
  SmallVector<Value *, 4> outs;
  Value *flags = r.value;
  // cq-ew5z: a level clone's overflow predicate follows the flags (materialize).
  unsigned ovfField = r.ovf ? 1 : 0;
  // The call's caller cells (rules 18, 20: the reloaded slot results and the old cells the twin restores) are
  // recorded with its outs, as for a clone without the environment.
  auto finish = [&]() {
    if (r.ovf)
      outs.push_back(r.ovf);
    ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
    fatptr::finishSlotTableCall(ctx, r.call);
    mem::finishParamCells(ctx, r.call);
    if (!r.slotOuts.empty())
      cleanDeadCells(ctx, CB, S, r, outs);
  };
  if (r.res.stores) {
    // 191 with 82: {leaves..., stores..., flags} (materialize); the stored rails are outs, popped before the
    // twin (U3), as bindQramCloneResult's.
    const ResultLayout &res = r.res;
    auto *st = dyn_cast<StructType>(r.call->getType());
    if (!st || st->getNumElements() != res.leaves.size() + res.stores + 1 + ovfField)
      internalError("calls: a clone carrying the environment with QRAM stores whose result is not "
                    "{leaves..., stores..., flags}",
                    &CB);
    if (!res.leafFields.empty())
      internalError("calls: a QRAM-triple clone whose aggregate result has a packed integer leaf reached the "
                    "environment's binding (bindQramCloneResult's case)",
                    &CB);
    SmallVector<Operand, 4> ops;
    SmallVector<Value *, 2> stored;
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
    flags = ctx.B().CreateExtractValue(r.call, {unsigned(res.leaves.size() + res.stores)});
    outs.push_back(flags);
    if (!CB.getType()->isVoidTy()) {
      if (res.composite) {
        ctx.bindFields(&CB, ops);
      } else {
        if (ops.size() != 1 || ops[0].handle != ctx.T.isQuantum(&CB, ctx.S))
          internalError("calls: the call's result kind and taint's disagree", &CB);
        ctx.bind(&CB, ops[0].v);
      }
    }
    finish();
    mem::noteCalleeQramStores(ctx, CB, S, r.call, stored);
    fenv::afterCloneCall(ctx, CB, flags);
    return;
  }
  if (r.fieldwise) {
    // cq-xhv4: a field-wise result (bindFieldwiseResult's binding) whose last field is the new flags.
    const ResultLayout &res = r.res;
    SmallVector<bool, 4> tq = ctx.T.fieldMask(&CB, ctx.S);
    if (res.cuts.size() > 2)
      tq = res.q;   // cq-0umd: a packed integer result's fields are the callee's (resultQuantum)
    if (tq.size() != res.q.size() || !std::equal(tq.begin(), tq.end(), res.q.begin()))
      internalError("calls: the clone's result fields and taint's field mask of the call disagree", &CB);
    auto *st = dyn_cast<StructType>(r.call->getType());
    if (!st || st->getNumElements() != res.leaves.size() + 1 + ovfField)
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

// I's block lies on a cycle.
bool inCycle(const Instruction *I, const DominatorTree *DT) {
  const BasicBlock *b = I->getParent();
  for (const BasicBlock *succ : successors(b))
    if (isPotentiallyReachable(succ, b, nullptr, DT))
      return true;
  return false;
}

struct InvChain {
  SmallVector<Instruction *, 4> steps;   // outermost (the stored value) first
  SmallVector<Value *, 4> chainOps;      // the operand of steps[k] that carries the old value
  LoadInst *load = nullptr;              // the load of the old cell content
  StoreInst *store = nullptr;
};

// (base, constant byte offset) of a pointer in the callee.
std::pair<const Value *, int64_t> baseOffset(const Value *p, const DataLayout &DL) {
  APInt off(DL.getIndexTypeSizeInBits(p->getType()), 0);
  const Value *b = p->stripAndAccumulateConstantOffsets(DL, off, /*AllowNonInbounds=*/true);
  return {b, off.getSExtValue()};
}

bool readsAny(const Value *v, const SmallPtrSetImpl<const Value *> &loads, unsigned depth = 0) {
  if (loads.count(v))
    return true;
  auto *I = dyn_cast<Instruction>(v);
  if (!I || depth > 64)
    return depth > 64;
  if (isa<LoadInst>(I))
    return false;
  for (const Value *op : I->operands())
    if (readsAny(op, loads, depth + 1))
      return true;
  return false;
}

// The callee's update of cell `cell` of formal argNo, as a chain of rule-6 bijections. nullopt: no rule-6
// bijection of the old content (no clean-up). Unimplemented shapes stop with the instruction.
std::optional<InvChain> invChainOf(const Specialization &S, unsigned argNo, unsigned cell, const std::vector<FormalLayout> &fs,
                                   const CallBase &site) {
  Function &F = *S.F;
  const DataLayout &DL = F.getParent()->getDataLayout();
  Argument *A = F.getArg(argNo);
  SmallVector<StoreInst *, 2> stores;
  SmallPtrSet<const Value *, 4> loads;
  Type *cellTy = nullptr;
  for (Instruction &I : instructions(F)) {
    auto *st = dyn_cast<StoreInst>(&I);
    if (!st)
      continue;
    auto [b, off] = baseOffset(st->getPointerOperand(), DL);
    if (b != A)
      continue;
    uint64_t sz = DL.getTypeStoreSize(st->getValueOperand()->getType());
    if (off == int64_t(cell * sz)) {
      stores.push_back(st);
      cellTy = st->getValueOperand()->getType();
    }
  }
  if (stores.size() > 1) {
    // cq-gujb (rules 6, 9, 20): the new content is a function of the old one only if some load of the cell may
    // read the caller's content: a load some path from the entry reaches without passing a store of the cell.
    // Otherwise there is no bijection of the old content (the cell is a value of the clone, the twin restores the
    // caller's).
    int64_t lo = int64_t(cell * DL.getTypeStoreSize(stores.front()->getValueOperand()->getType()));
    int64_t hi = lo + int64_t(DL.getTypeStoreSize(stores.front()->getValueOperand()->getType()));
    auto storeIn = [&](const BasicBlock *bb, const Instruction *upto) {
      for (const Instruction &I : *bb) {
        if (&I == upto)
          return false;
        if (is_contained(stores, &I))
          return true;
      }
      return false;
    };
    bool readsOld = false;
    for (Instruction &I : instructions(F)) {
      auto *ld = dyn_cast<LoadInst>(&I);
      if (!ld || readsOld)
        continue;
      auto [b, off] = baseOffset(ld->getPointerOperand(), DL);
      if (b != A || off >= hi || off + int64_t(DL.getTypeStoreSize(ld->getType())) <= lo)
        continue;
      SmallVector<const BasicBlock *, 16> work{&F.getEntryBlock()};
      SmallPtrSet<const BasicBlock *, 16> seen{&F.getEntryBlock()};
      while (!work.empty() && !readsOld) {
        const BasicBlock *bb = work.pop_back_val();
        if (bb == ld->getParent() && !storeIn(bb, ld))
          readsOld = true;
        else if (!storeIn(bb, nullptr))
          for (const BasicBlock *sc : successors(bb))
            if (seen.insert(sc).second)
              work.push_back(sc);
      }
    }
    if (!readsOld)
      return std::nullopt;
  }
  if (stores.size() != 1)
    unimplemented("calls: _inv<c> (CR §1.4): a clone cell written by " + std::to_string(stores.size()) +
                      " stores at a constant offset (one store of a bijective update is built)",
                  &site);
  StoreInst *st = stores.front();
  if (!cellTy->isIntegerTy() && !cellTy->isFloatingPointTy())
    return std::nullopt;
  for (Instruction &I : instructions(F))
    if (auto *ld = dyn_cast<LoadInst>(&I); ld && ld->getType() == cellTy) {
      auto [b, off] = baseOffset(ld->getPointerOperand(), DL);
      if (b == A && off == int64_t(cell * DL.getTypeStoreSize(cellTy)))
        loads.insert(ld);
    }
  Value *V = st->getValueOperand();
  if (!readsAny(V, loads)) {
    // The new content reads another cell's old content through this formal: coupled cells (a swap).
    SmallPtrSet<const Value *, 4> others;
    for (Instruction &I : instructions(F))
      if (auto *ld = dyn_cast<LoadInst>(&I); ld && baseOffset(ld->getPointerOperand(), DL).first == A &&
                                             !loads.count(ld))
        others.insert(ld);
    if (readsAny(V, others))
      unimplemented("calls: _inv<c>_<c'> (CR §1.4): coupled cells whose updates read each other's old values (the "
                    "group form)",
                    st);
    return std::nullopt;   // the new content is no function of the old one in this cell
  }
  InvChain ch;
  ch.store = st;
  Value *cur = V;
  while (!loads.count(cur)) {
    auto *I = dyn_cast<Instruction>(cur);
    if (!I)
      return std::nullopt;
    SmallVector<unsigned, 2> carry;
    for (unsigned k = 0; k < I->getNumOperands(); ++k)
      if (readsAny(I->getOperand(k), loads))
        carry.push_back(k);
    if (carry.size() != 1 || isa<SelectInst>(I) || isa<PHINode>(I))
      unimplemented("calls: _inv<c> (CR §1.4): a cell update that is a composite or merged function of the old "
                    "content (rule 6, 125/127 shapes)",
                    I);
    for (unsigned k = 0; k < I->getNumOperands(); ++k) {
      if (k == carry[0])
        continue;
      Value *z = I->getOperand(k);
      if (isa<Constant>(z))
        continue;
      auto *za = dyn_cast<Argument>(z);
      if (!za || fs[za->getArgNo()].pointer || fs[za->getArgNo()].leaves.size() != 1 ||
          !fs[za->getArgNo()].cuts.empty())
        unimplemented("calls: _inv<c> (CR §1.4): an operand of a cell update the callee computes (only constants "
                      "and scalar formals are built)",
                      I);
    }
    ch.steps.push_back(I);
    ch.chainOps.push_back(I->getOperand(carry[0]));
    cur = I->getOperand(carry[0]);
  }
  ch.load = cast<LoadInst>(cur);
  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  if (!DT.dominates(ch.load, st))
    unimplemented("calls: _inv<c> (CR §1.4): the old cell content read by a load that does not precede the store",
                  ch.load);
  if (!PDT.dominates(st->getParent(), &F.getEntryBlock()) || inCycle(st, &DT))
    unimplemented("calls: _inv<c> (CR §1.4): a conditional or looping cell update", st);
  if (ch.steps.empty())
    return std::nullopt;   // the cell is stored back unchanged
  return ch;
}

// The CR §1.4 _inv clone of C (the forward clone of S) for cell position `pos`: (forward args..., old).
Function *materializeInv(Module &M, const Specialization &S, Function *C, unsigned pos, unsigned argNo,
                         unsigned cell, const InvChain &ch, const std::vector<FormalLayout> &fs, const CallBase &site) {
  abi::CloneSpec cs = cloneSpecOf(S);
  cs.inv = {pos};
  std::string name = checkedName(cs, &site);
  if (Function *G = M.getFunction(name)) {
    if (G->isDeclaration())
      internalError("calls: an _inv clone declared without a body", &site);
    return G;
  }
  LLVMContext &Cx = M.getContext();
  Type *i32 = Type::getInt32Ty(Cx);
  SmallVector<Type *, 8> params(C->getFunctionType()->params().begin(), C->getFunctionType()->params().end());
  params.push_back(i32);
  Function *G = Function::Create(FunctionType::get(Type::getVoidTy(Cx), params, false), GlobalValue::InternalLinkage,
                                 name, M);
  if (G->getName() != name)
    internalError("calls: _inv clone symbol collision", &site);
  G->setCallingConv(C->getCallingConv());
  auto paramOf = [&](unsigned formal) {
    unsigned k = S.ctl ? 1 : 0;
    for (unsigned j = 0; j < formal; ++j)
      k += fs[j].leaves.size();
    return k;
  };
  IRBuilder<> B(BasicBlock::Create(Cx, "", G));
  // cq-ja4w: the clone's slot formal holds one i32 handle per cell (a local scalar or scalar-array object,
  // the only kind cleanDeadCells admits), addressed as the forward clone addresses it (mem-slots
  // cellPointer): the i32 cell index, whatever the cell's C width.
  Value *cellPtr = G->getArg(paramOf(argNo));
  if (cell)
    cellPtr = B.CreateConstInBoundsGEP1_64(i32, cellPtr, cell);
  Value *yp = B.CreateAlignedLoad(i32, cellPtr, Align(4));
  SmallPtrSet<const Value *, 4> loadSet{ch.load};
  auto operandOf = [&](Value *z) -> Operand {
    if (auto *za = dyn_cast<Argument>(z); za && za->getParent() == S.F)
      return Operand{G->getArg(paramOf(za->getArgNo())), bool(fs[za->getArgNo()].q[0])};
    if (isa<Constant>(z))
      return Operand{z, false};
    internalError("calls: _inv clone: an operand that is neither a formal nor a constant", z);
  };
  auto readsY = [&](Value *z) { return readsAny(z, loadSet); };
  struct Emitted { abi::TemplateSpec spec; SmallVector<Value *, 3> args; CallInst *t; };
  SmallVector<Emitted, 4> done;
  Operand cur{yp, true};
  for (unsigned k = 0; k < ch.steps.size(); ++k) {
    std::optional<spine::InverseStep> inv = spine::inverseStep(*ch.steps[k], ch.chainOps[k], cur, operandOf, readsY);
    if (!inv)
      internalError("calls: _inv clone: a step the dry run inverted has no inverse", ch.steps[k]);
    SmallVector<Value *, 3> args;
    for (const Operand &o : inv->ops)
      args.push_back(o.v);
    CallInst *t = B.CreateCall(abi::declare(M, inv->spec, false), args);
    done.push_back({inv->spec, args, t});
    cur = Operand{t, true};
  }
  abi::TemplateSpec last = done.back().spec;
  RailType w = last.to ? *last.to : last.w;
  B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, w}), {cur.v, G->getArg(params.size() - 1)});
  for (auto it = done.rbegin(); it != done.rend(); ++it) {
    SmallVector<Value *, 4> uargs{it->t};
    uargs.append(it->args.begin(), it->args.end());
    B.CreateCall(abi::declare(M, it->spec, true), uargs);
    B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Free, {}}), {it->t});
  }
  B.CreateRetVoid();
  return G;
}

// Is every inverse step a rule-6 bijection (a dry run over placeholders)?
bool chainInvertible(const Specialization &S, const InvChain &ch, const std::vector<FormalLayout> &fs) {
  LLVMContext &Cx = S.F->getContext();
  Value *ph = PoisonValue::get(Type::getInt32Ty(Cx));
  SmallPtrSet<const Value *, 4> loadSet{ch.load};
  for (unsigned k = 0; k < ch.steps.size(); ++k) {
    auto operandOf = [&](Value *z) -> Operand {
      if (auto *za = dyn_cast<Argument>(z))
        return Operand{z, bool(fs[za->getArgNo()].q[0])};
      return Operand{z, false};
    };
    auto readsY = [&](Value *z) { return readsAny(z, loadSet); };
    if (!spine::inverseStep(*ch.steps[k], ch.chainOps[k], Operand{ph, true}, operandOf, readsY))
      return false;
  }
  return true;
}

// The caller's old rail h of a cell the call overwrites is dead after the call (CR rule 6 Dead, narrow):
// h is the caller's register, not measured, every original reader of a value bound to h precedes the call,
// and the only store of it is into the very cell the call overwrites. The object is a local whose address
// reaches only loads, stores into it, constant GEPs, lifetime markers and this call.
// cq-p8r6: Dead::Unknown where the narrow test cannot decide (a root that is not a local, an address that
// reaches other users, a copy stored elsewhere) although no reader of h follows the call: its caller stops
// loudly unless the call's twin restores the cell (Uncompute::cleanupUnbuilt).
enum class Dead { No, Yes, Unknown };
Dead oldDeadAfter(LoweringContext &ctx, CallBase &CB, Value *h, const Value *actual, std::optional<int64_t> cellOff) {
  spine::Shared &sh = spine::shared(ctx);
  std::optional<Role> role = ctx.unc().liveRole(ctx.unc().idOf(h));
  if (!role || *role != Role::UserRegister || sh.measured.count(h))
    return Dead::No;
  const DataLayout &DL = ctx.M.getDataLayout();
  auto [root, aoff] = baseOffset(actual, DL);
  bool unknown = !isa<AllocaInst>(root) || !cellOff;
  int64_t target = aoff + cellOff.value_or(0);
  DominatorTree &DT = sh.dt(*CB.getFunction());
  SmallPtrSet<const Value *, 8> A;
  for (auto &[w, ops] : sh.binds)
    if (ops.size() == 1 && ops.front().handle && ops.front().v == h)
      A.insert(w);
  for (auto &[w, v] : sh.views)
    if (v.rail == h)
      A.insert(w);
  for (const Value *w : A) {
    SmallVector<const Use *, 8> uses;
    spine::readingUses(sh, w, uses);
    for (const Use *U : uses) {
      auto *ui = dyn_cast<Instruction>(U->getUser());
      if (!ui || ui->getFunction() != CB.getFunction() || ui == &CB || !DT.dominates(ui, &CB))
        return Dead::No;
      if (isa<ReturnInst>(ui) || isa<PHINode>(ui))
        return Dead::No;
      if (auto *st = dyn_cast<StoreInst>(ui)) {
        auto [b, o] = baseOffset(st->getPointerOperand(), DL);
        if (st->getValueOperand() != w || b != root || o != target)
          unknown = true;
      }
    }
  }
  if (unknown)
    return Dead::Unknown;
  // The object's address: no copy of the rail elsewhere through memory.
  SmallVector<const Value *, 8> ptrs{root};
  SmallPtrSet<const Value *, 8> seen;
  while (!ptrs.empty()) {
    const Value *p = ptrs.pop_back_val();
    if (!seen.insert(p).second)
      continue;
    for (const User *u : p->users()) {
      if (isa<LoadInst>(u))
        continue;
      if (auto *s2 = dyn_cast<StoreInst>(u); s2 && s2->getPointerOperand() == p && s2->getValueOperand() != p)
        continue;
      if (auto *g = dyn_cast<GetElementPtrInst>(u); g && g->hasAllConstantIndices()) {
        ptrs.push_back(g);
        continue;
      }
      if (auto *II = dyn_cast<IntrinsicInst>(u); II && II->isLifetimeStartOrEnd())
        continue;
      if (u == &CB)
        continue;
      return Dead::Unknown;
    }
  }
  return Dead::Yes;
}

// After the clone call r (phase 2: recordCall made), the _inv<c> clean-up of every dead old cell rail.
void cleanDeadCells(LoweringContext &ctx, CallBase &CB, const Specialization &S, const CloneCall &r,
                    ArrayRef<Value *> outs) {
  std::vector<FormalLayout> fs = formalLayout(ctx.T, S, &CB);
  unsigned pos = 0;
  for (unsigned i = 0; i < CB.arg_size() && i < fs.size(); ++i) {
    // The formals emitCloneCall passed old cells for (its slotArgs): not an object table (M7).
    if (!fs[i].pointer || (fs[i].abi != PtrAbi::Raw && fatptr::slotTableActual(ctx, CB.getArgOperand(i))) ||
        !pointsToSlot(ctx, CB.getArgOperand(i)))
      continue;
    SmallVector<unsigned, 4> cells = ctx.T.cellsWritten(S, i);
    for (unsigned c : cells) {
      if (ctx.T.cellForward(S, i, c) >= 0)
        continue;
      unsigned k = pos++;
      if (k >= r.extra.size() || k >= r.slotOuts.size())
        internalError("calls: _inv<c>: fewer old or new cell handles than cells the clone writes", &CB);
      const Operand &old = r.extra[k];
      if (!old.handle || !isa<Instruction>(old.v))
        continue;
      // cq-p8r6: the reads of this cell's clean-up: the call's results, the cell's new content, the call
      // group's leader (its twin reads the old rail, so the clean-up is pruned when the twin runs).
      SmallVector<Value *, 4> reads(outs.begin(), outs.end());
      reads.push_back(r.slotOuts[k]);
      if (outs.empty() && r.slotOuts[0] != r.slotOuts[k])
        reads.push_back(r.slotOuts[0]);
      // cq-p8r6 (CR rules 6, 18): a possibly dead old rail of a shape the _inv<c> kind is not built for: no
      // silent keep; a stop unless the call's twin restores the cell.
      auto unbuilt = [&](std::optional<int64_t> off, const char *shape) {
        if (oldDeadAfter(ctx, CB, old.v, CB.getArgOperand(i), off) == Dead::No)
          return;
        ctx.unc().cleanupUnbuilt(ctx.unc().idOf(old.v),
                                 std::string("calls: _inv<c> (CR §1.4, rule 18): the dead old content of a caller "
                                             "cell a clone overwrote, ") +
                                     shape + " (no twin restores it)",
                                 &CB, reads);
      };
      if (fs[i].abi != PtrAbi::Raw) {
        unbuilt(std::nullopt, "through a triple (fat-pointer) formal");   // 107's idx half: the twin restores it
        continue;
      }
      // The caller's cell: a scalar or an array of scalars local (records and other objects: not built here).
      auto *AI = dyn_cast<AllocaInst>(getUnderlyingObject(CB.getArgOperand(i)));
      Type *et = AI ? AI->getAllocatedType() : nullptr;
      while (et && et->isArrayTy())
        et = et->getArrayElementType();
      if (!et || !(et->isIntegerTy() || et->isFloatingPointTy())) {
        unbuilt(std::nullopt, "in a record, heap block or other object that is not a local scalar or array");
        continue;
      }
      uint64_t cellBytes = ctx.M.getDataLayout().getTypeStoreSize(et);
      Dead dead = oldDeadAfter(ctx, CB, old.v, CB.getArgOperand(i), int64_t(c * cellBytes));
      if (dead == Dead::Unknown)
        unbuilt(int64_t(c * cellBytes), "of an object whose address or old content reaches other users");
      if (dead != Dead::Yes)
        continue;
      std::optional<InvChain> ch = invChainOf(S, i, c, fs, CB);
      if (!ch || !chainInvertible(S, *ch, fs))
        continue;
      if (ctx.M.getDataLayout().getTypeStoreSize(ch->store->getValueOperand()->getType()) != cellBytes)
        unimplemented("calls: _inv<c> (CR §1.4): a callee store of another width than the caller's cell", ch->store);
      // Rule 6 group (CR §1.4): an update of this cell reading another written cell's old content.
      for (unsigned c2 : cells)
        if (c2 != c)
          for (Instruction *I : ch->steps)
            for (Value *op : I->operands())
              if (auto *ld = dyn_cast<LoadInst>(op)) {
                auto [b, o] = baseOffset(ld->getPointerOperand(), S.F->getParent()->getDataLayout());
                if (b == S.F->getArg(i) && o == int64_t(c2 * cellBytes))
                  unimplemented("calls: _inv<c>_<c'> (CR §1.4): coupled cells whose updates read each other's old "
                                "values (the group form)",
                                &CB);
              }
      if (S.ctl)
        unimplemented("calls: _inv<c> (CR §1.4) of a _ctl clone call", &CB);
      const DominatorTree &DT = spine::shared(ctx).dt(*CB.getFunction());
      if (inCycle(&CB, &DT))
        unimplemented("calls: _inv<c> (CR §1.4) of a clone call in a cycle", &CB);
      auto [root, aoff] = baseOffset(CB.getArgOperand(i), ctx.M.getDataLayout());
      for (const Instruction &X : instructions(*CB.getFunction())) {
        if (&X == &CB || !X.mayWriteToMemory() || !isPotentiallyReachable(&CB, &X, nullptr, &DT))
          continue;
        if (auto *II = dyn_cast<IntrinsicInst>(&X); II && II->isLifetimeStartOrEnd())
          continue;
        const Value *wp = nullptr;
        if (auto *st = dyn_cast<StoreInst>(&X))
          wp = st->getPointerOperand();
        bool hits = !wp;   // a call or another writer: may write the object unless it cannot reach it
        if (auto *cb2 = dyn_cast<CallBase>(&X)) {
          hits = false;
          for (const Use &u : cb2->args())
            if (u->getType()->isPointerTy() && getUnderlyingObject(u.get()) == root)
              hits = true;
        }
        if (wp && getUnderlyingObject(wp) == root)
          hits = true;
        if (hits)
          unimplemented("calls: _inv<c> (CR §1.4): the caller writes the cell's object again after the call (the "
                        "clean-up reads the cell's new content)",
                        &X);
      }
      Function *G = materializeInv(ctx.M, S, r.call->getCalledFunction(), k, i, c, *ch, fs, CB);
      ctx.unc().cleanupByCall(ctx.unc().idOf(old.v), G, r.ops, reads);
      // cq-necw (CR rules 6, 18): the cell's new content is the caller's register, as an inline update's
      // result is. When it is the call group's only member, rule 6 may clean it at a later bijective update
      // (spine cleanable); the twin then never runs and the _inv<c> clean-up is not pruned. Otherwise (it
      // stays garbage) the twin restores the old content, which is then not dead (rule 18), the clean-up is
      // pruned, and calls::finalize drops the unused _inv<c> (§1.4: defined only when a call site uses it).
      if (outs.empty() && r.slotOuts.size() == 1)
        spine::shared(ctx).invCellImages.insert(r.slotOuts[k]);
    }
  }
}

// Rule 19 (cq-i9wk): a callee reached with no quantum argument whose quantum result is not frozen is a
// clone: its in-place body lowered as a clone (Specialization::kept, built before the module's epilogue),
// which copies its results out, uncomputes, and returns after them the handle of each register it minted
// that is still allocated. The caller keeps those registers like its own (never freed) and its twin
// zeroes the results against them: <clone>_unc(registers..., outs..., args..., old cells...).
void lowerKeptClone(LoweringContext &ctx, CallBase &CB, const Specialization &cs) {
  const Specialization &K = spine::keptSpec(ctx.M, cs);
  CloneCall r = emitCloneCall(ctx, CB, K, nullptr);
  if (r.res.qramFormal)
    unimplemented("calls: a kept clone (rule 19) that stores through a QRAM triple",
                  &CB);
  IRBuilder<> &B = ctx.B();
  auto *wt = dyn_cast<StructType>(r.call->getType());
  unsigned nRegs = 0;
  if (const Attribute a = r.call->getCalledFunction()->getFnAttribute(spine::kKeptRegistersAttr); a.isValid())
    nRegs = unsigned(std::stoul(a.getValueAsString().str()));
  bool env = fenv::cloneCarriesEnv(ctx.T, K);
  // The base result (what the clone returns before its registers): its fields (the result's leaves, then
  // the flags handle when it carries the environment), or the one handle.
  Type *baseTy = nRegs ? spine::keptCloneBaseType(*r.call->getCalledFunction()) : r.call->getType();
  if (!baseTy || (nRegs && (!wt || wt->getNumElements() < nRegs)))
    internalError("calls: a kept clone whose return type is not its result then its registers", &CB);
  SmallVector<Value *, 4> base;
  if (auto *bst = dyn_cast<StructType>(baseTy))
    for (unsigned k = 0; k < bst->getNumElements(); ++k)
      base.push_back(B.CreateExtractValue(r.call, {k}));
  else
    base.push_back(nRegs ? B.CreateExtractValue(r.call, {0u}) : static_cast<Value *>(r.call));
  unsigned nBase = unsigned(base.size());
  SmallVector<Value *, 4> regs;
  for (unsigned k = 0; k < nRegs; ++k) {
    Value *h = B.CreateExtractValue(r.call, {nBase + k});
    ctx.unc().recordExternal(h, Role::UserRegister);   // kept like the caller's own registers
    spine::shared(ctx).frozenResults.insert(h);
    regs.push_back(h);
  }
  SmallVector<Value *, 4> outs;
  Value *flags = nullptr;
  if (env) {
    flags = base.pop_back_val();
  }
  if (r.fieldwise) {
    const ResultLayout &res = r.res;
    if (base.size() != res.leaves.size())
      internalError("calls: a kept clone's field-wise result with another field count than its layout", &CB);
    SmallVector<Operand, 4> ops;
    for (unsigned k = 0; k < res.leaves.size(); ++k) {
      ops.push_back(Operand{base[k], res.q[k]});
      if (res.q[k])
        outs.push_back(base[k]);
    }
    if (!res.leafFields.empty())
      aggr::bindLeafFields(ctx, &CB, ops, res.leafFields);
    else
      ctx.bindFields(&CB, ops);
  } else {
    if (base.size() != 1 || !r.handle)
      internalError("calls: a kept clone whose result is not one handle", &CB);
    outs.push_back(base[0]);
    ctx.bind(&CB, base[0]);
  }
  if (flags)
    outs.push_back(flags);
  SmallVector<Operand, 4> extra(r.extra.begin(), r.extra.end());
  for (Value *h : regs)
    extra.push_back(Operand{h, true});
  ctx.unc().recordCall(r.call, outs, r.slotOuts, extra);
  ctx.unc().noteCallExtraFirst(r.call, nRegs);
  fatptr::finishSlotTableCall(ctx, r.call);
  mem::finishParamCells(ctx, r.call);
  if (!r.slotOuts.empty())
    cleanDeadCells(ctx, CB, K, r, outs);
  if (flags)
    fenv::afterCloneCall(ctx, CB, flags);
}

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
    return lowerKeptClone(ctx, CB, cs);
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
  if (r.res.qramFormal)
    return bindQramCloneResult(ctx, CB, cs, r);
  if (r.fieldwise)
    return bindFieldwiseResult(ctx, CB, r.call, r.res, r.slotOuts, r.extra, r.ovf);
  if (!r.slotOuts.empty() || !r.extra.empty() || r.ovf) {
    // Phase 2: the result (if a handle) and the reloaded cells are one call's results, undone together
    // by the twin <clone>_unc(out?, args..., old cells...) (U2). cq-ew5z: a recursion level's overflow
    // predicate is the last out.
    SmallVector<Value *, 2> outs;
    if (!CB.getType()->isVoidTy()) {
      bool q = ctx.T.isQuantum(&CB, ctx.S);
      if (r.handle != q)
        internalError("calls: the call's result kind and taint's disagree", &CB);
      if (r.handle)
        outs.push_back(r.value);
      ctx.bind(&CB, r.value);
    }
    if (r.ovf)
      outs.push_back(r.ovf);
    if (r.slotOuts.empty() && !r.extra.empty())
      internalError("calls: old slot cells passed to a clone that reloads none", &CB);
    ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
    fatptr::finishSlotTableCall(ctx, r.call);
    mem::finishParamCells(ctx, r.call);
    if (!r.slotOuts.empty())
      cleanDeadCells(ctx, CB, cs, r, outs);
    return;
  }
  bindResult(ctx, CB, r.call, r.handle, r.ops);
}
} // namespace

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
    // cq-ew5z: the cut call's term of this level's overflow predicate (B > K or no bound), returned by the
    // level clone (calls::materialize's extra result) and kept by the recursion's first outside caller.
    if (cutKeepsOverflow(K, B))
      overflowAtCut(ctx, CB);
    return loops::lowerQuantumDepthRecursion(ctx, CB, K, B);
  }
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
  if (r.ovf) {
    // cq-ew5z: the callee returned the overflow predicate of a quantum-depth recursion. A call of the next
    // level from a level that returns it too is a term of this level's; any other caller keeps it.
    bool level = overflowResult(ctx.S) && cs->depth == ctx.S.depth + 1 && cs->F == CB.getCalledFunction();
    overflowAfterCall(ctx, r.ovf, !cs->ctl && underQuantumPredicate(ctx) ? ctlFlag(ctx, CB) : nullptr, level);
  }
}

// cq-r8-d (CR rule 27 Pointers; 190): a void declared call with a pointer argument into a local slot object.
// The pointer crosses as (object, tag, idx, cell count) with the digits tag 0, idx 0 and one object digit (1:
// some cell holds a handle at the call); before the call the caller copies the object's cells into a
// snapshot of the same size; the twin <clone>_unc(args..., K, snapshot) runs after the last read of a cell
// the clone may have written (Uncompute U7 over mem-slots' later cell reads), before the items of the rails
// the cells held (the call's footprint). One such pointer; a result, a _ctl call, an object digit 0 and a
// quantum or multi-object pointer are unimplemented.
// resolved (cq-sd95): the callee is the registered all-handles clone at that host address (rules 19, 27): every
// digit 1, the triple's tag and idx crossing as seed rails; F is null.
void lowerDeclaredPointers(LoweringContext &ctx, CallBase &CB, Function *F, Value *resolved = nullptr) {
  LLVMContext &C = ctx.M.getContext();
  if (!CB.getType()->isVoidTy())
    unimplemented("calls: a declared clone with a pointer argument and a result (rule 27: the result's twin and the "
                  "snapshot in one item)",
                  &CB);
  if (underQuantumPredicate(ctx))
    unimplemented("calls: a declared clone with a pointer argument under a quantum predicate (rule 27 _ctl: the "
                  "cells merged by select)",
                  &CB);
  std::string mask;
  SmallVector<Value *, 8> args;
  int ptrArg = -1;
  mem::DeclaredCells cells;
  fatptr::Triple t{};
  for (unsigned i = 0; i < CB.arg_size(); ++i) {
    const Value *a = CB.getArgOperand(i);
    if (a->getType()->isPointerTy()) {
      if (ptrArg >= 0)
        unimplemented("calls: a declared clone with two pointer arguments (rule 27: one snapshot per object)", &CB);
      ptrArg = int(i);
      cells = mem::declaredCellsAtCall(ctx, CB, i);
      if (!all_of(cells.atCall, [](const Operand &o) { return o.handle; }))
        unimplemented("calls: a declared clone's pointer into a slot object a cell of which holds no handle at the "
                      "call (rule 27: the clone reads every cell of an object marked 1 as a handle; object digit 0)",
                      &CB);
      t = fatptr::passAcrossCall(ctx, a);
      if (!t.cellCount)
        internalError("calls: passAcrossCall gave no cell count for a slot object", &CB);
      if (resolved) {
        args.append({t.object, seedActual(ctx, Operand{t.tag, false}).v, seedActual(ctx, Operand{t.idx, false}).v,
                     t.cellCount});
        mask += "111";
      } else {
        args.append({t.object, t.tag, t.idx, t.cellCount});
        mask += "001";
      }
      continue;
    }
    // A scalar is one field, an aggregate or vector one per scalar leaf (CR §1.4, rules 25, 26).
    SmallVector<bool, 4> q = isComposite(a->getType()) ? ctx.T.fieldMask(a, ctx.S)
                                                       : SmallVector<bool, 4>{ctx.T.isQuantum(a, ctx.S)};
    SmallVector<Operand, 4> fields = actualFields(ctx, a);
    if (q.size() != fields.size())
      internalError("calls: taint's field mask of an actual has another field count than the actual", &CB);
    for (unsigned k = 0; k < fields.size(); ++k) {
      Operand o = fields[k];
      if (q[k] || resolved)
        o = seedActual(ctx, o);
      else if (o.handle)
        internalError("calls: a rail where taint says the actual is classical", &CB);
      args.push_back(o.v);
      mask.push_back(o.handle ? '1' : '0');
    }
  }
  if (ptrArg < 0)
    internalError("calls: lowerDeclaredPointers of a call without a pointer argument", &CB);
  args.push_back(F ? declaredK(ctx, *F, &CB) : resolvedK(ctx));
  // The snapshot: the object's cells as handle numbers, a classical copy.
  uint64_t n = cast<ConstantInt>(t.cellCount)->getZExtValue();
  IRBuilder<> EB(&*ctx.out().getEntryBlock().getFirstInsertionPt());
  AllocaInst *snap = EB.CreateAlloca(ArrayType::get(Type::getInt32Ty(C), n), nullptr);
  snap->setAlignment(Align(4));
  ctx.B().CreateMemCpy(snap, Align(4), t.object, Align(4), n * 4);
  SmallVector<Type *, 8> ps;
  for (Value *a : args)
    ps.push_back(a->getType());
  FunctionType *FT = FunctionType::get(Type::getVoidTy(C), ps, false);
  CallInst *call;
  if (resolved) {
    call = ctx.B().CreateCall(FT, resolveClone(ctx, resolved, 0), args);   // C calling convention (rule 27)
  } else {
    abi::CloneSpec cs{calleeName(*F, &CB), mask, {}, false, false, 0, false};
    std::string name = checkedName(cs, &CB);
    Function *D = ctx.M.getFunction(name);
    if (D && D->getFunctionType() != FT)
      internalError("calls: declared clone @" + name + " exists with another type", &CB);
    if (!D)
      D = Function::Create(FT, GlobalValue::ExternalLinkage, name, ctx.M);
    call = ctx.B().CreateCall(D, args);   // C calling convention (rule 27)
  }
  SmallVector<RailId, 8> reads;
  for (const Operand &o : cells.atCall)
    if (o.handle && !is_contained(reads, ctx.unc().idOf(o.v)))
      reads.push_back(ctx.unc().idOf(o.v));
  ctx.unc().noteCallReads(call, reads);
  RailId pseudo = ctx.unc().recordDeclaredWrites(call, {Operand{snap, false}});
  mem::noteDeclaredWrites(ctx, CB, unsigned(ptrArg), pseudo, cells.atCall);
}

void lowerDeclared(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  Function *F = CB.getCalledFunction();
  if (!F || !F->isDeclaration())
    internalError("calls: lowerDeclared of a call that is not a direct call of a declaration", &CB);
  if (any_of(CB.args(), [](const Use &u) { return u->getType()->isPointerTy(); }))
    return lowerDeclaredPointers(ctx, CB, F);
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

// Does F (or a defined callee of it) have a non-pure gate (CR rule 19: a rotation, a phase, a store,
// tape or any other effect)? Conservative: every memory write and every call of a declaration other
// than cq_measure or a memory-free intrinsic counts.
bool bodyHasNonPureGate(const Function &F, SmallPtrSetImpl<const Function *> &seen) {
  if (!seen.insert(&F).second)
    return false;
  for (const Instruction &I : instructions(F)) {
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      const Function *G = CB->getCalledFunction();
      if (!G)
        return true;
      if (G->isIntrinsic()) {
        if (CB->doesNotAccessMemory() || isa<DbgInfoIntrinsic>(CB) || G->getIntrinsicID() == Intrinsic::lifetime_start ||
            G->getIntrinsicID() == Intrinsic::lifetime_end)
          continue;
        return true;
      }
      if (G->getName().starts_with("cq_measure_"))
        continue;
      if (G->isDeclaration() || bodyHasNonPureGate(*G, seen))
        return true;
      continue;
    }
    if (I.mayWriteToMemory())
      return true;
  }
  return false;
}

namespace {
// The scalar leaves of a lowered classical value (rules 25, 26: depth first, vector lanes).
void classicalLeaves(IRBuilder<> &B, Value *v, SmallVectorImpl<Operand> &out) {
  Type *t = v->getType();
  if (auto *st = dyn_cast<StructType>(t)) {
    for (unsigned k = 0; k < st->getNumElements(); ++k)
      classicalLeaves(B, B.CreateExtractValue(v, {k}), out);
  } else if (auto *at = dyn_cast<ArrayType>(t)) {
    for (unsigned k = 0; k < at->getNumElements(); ++k)
      classicalLeaves(B, B.CreateExtractValue(v, {k}), out);
  } else if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    for (unsigned k = 0; k < vt->getNumElements(); ++k)
      out.push_back(Operand{B.CreateExtractElement(v, uint64_t(k)), false});
  } else {
    out.push_back(Operand{v, false});
  }
}

// One candidate's call in an indirect call (rule 19), at the builder: its result fields (empty for void; the
// whole classical value in `whole` when the result is classical), recorded for their twins and bound to
// nothing (the caller merges). flag: the candidate's quantum predicate, nullptr when none.
SmallVector<Operand, 4> emitCandidate(LoweringContext &ctx, CallBase &CB, Function &G, const Specialization *s,
                                      Value *flag, Value *&whole, Value *&envOut) {
  whole = nullptr;
  envOut = nullptr;
  SmallVector<Operand, 4> fields;
  bool anyQArg = any_of(CB.args(), [&](const Use &u) { return ctx.T.isQuantum(u.get(), ctx.S); });
  if (!s || (G.isDeclaration() && !anyQArg)) {
    // The candidate's untainted body, or a body-less candidate with no quantum argument (rule 27: the
    // ordinary call): the host call with the call's classical operands, executed unguarded (rule 19).
    SmallVector<Value *, 8> args;
    for (const Use &u : CB.args()) {
      Operand o = ctx.operand(u.get());
      if (o.handle)
        internalError("calls: a rail reaching an untainted candidate of an indirect call", &CB);
      args.push_back(o.v);
    }
    CallInst *c = ctx.B().CreateCall(CB.getFunctionType(), &G, args);
    c->setCallingConv(CB.getCallingConv());
    c->setAttributes(CB.getAttributes());
    if (!CB.getType()->isVoidTy()) {
      whole = c;
      classicalLeaves(ctx.B(), c, fields);
    }
    return fields;
  }
  if (G.isDeclaration()) {
    // Rule 27: the declared clone, its _ctl form under a quantum predicate.
    if (any_of(CB.args(), [](const Use &u) { return u->getType()->isPointerTy(); }))
      unimplemented("calls: a body-less candidate of an indirect call with a pointer argument (rule 27 Pointers in "
                    "rule 19's arms: the snapshot per arm)",
                    &CB);
    emitDeclaredCall(ctx, CB, &G, siteMask(ctx, CB), flag, &fields);
    return fields;
  }
  if (s->ctl && !flag)
    internalError("calls: a _ctl candidate of an indirect call with no predicate", &CB);
  CloneCall r = emitCloneCall(ctx, CB, *s, s->ctl ? flag : nullptr);
  if (r.res.qramFormal)
    unimplemented("calls: an indirect-call candidate with a triple formal onto a QRAM object (U3 in rule 19's "
                  "arms)",
                  &CB);
  if (!r.slotOuts.empty() || !r.extra.empty())
    unimplemented("calls: an indirect-call candidate that writes a caller's slot object (the merge of its "
                  "reloaded cells over rule 19's arms)",
                  &CB);
  if (fenv::cloneCarriesEnv(ctx.T, *s)) {
    // E1 (82) in rule 19's arms: the clone's result fields then its new flags (bindEnvResult's layout); the
    // flags are this arm's, merged over the arms by lowerIndirect (fenv::afterCloneCall at the join).
    SmallVector<Value *, 4> outs;
    if (r.fieldwise) {
      for (unsigned k = 0; k < r.res.leaves.size(); ++k) {
        Value *e = ctx.B().CreateExtractValue(r.call, {k});
        fields.push_back(Operand{e, bool(r.res.q[k])});
        if (r.res.q[k])
          outs.push_back(e);
      }
      envOut = ctx.B().CreateExtractValue(r.call, {unsigned(r.res.leaves.size())});
    } else if (!CB.getType()->isVoidTy()) {
      Value *res = ctx.B().CreateExtractValue(r.call, {0u});
      envOut = ctx.B().CreateExtractValue(r.call, {1u});
      if (r.handle) {
        outs.push_back(res);
        fields.push_back(Operand{res, true});
      } else {
        whole = res;
        classicalLeaves(ctx.B(), res, fields);
      }
    } else {
      envOut = r.value;
    }
    outs.push_back(envOut);
    if (r.ovf)
      outs.push_back(r.ovf);   // cq-ew5z: the overflow predicate, the clone's last field
    ctx.unc().recordCall(r.call, outs, {}, {});
    if (r.ovf)
      overflowAfterCall(ctx, r.ovf, s->ctl ? nullptr : flag, false);   // a call outside the recursion keeps it
    return fields;
  }
  if (r.fieldwise) {
    SmallVector<Value *, 4> outs;
    for (unsigned k = 0; k < r.res.leaves.size(); ++k) {
      Value *e = ctx.B().CreateExtractValue(r.call, {k});
      fields.push_back(Operand{e, bool(r.res.q[k])});
      if (r.res.q[k])
        outs.push_back(e);
    }
    if (r.ovf)
      outs.push_back(r.ovf);
    ctx.unc().recordCall(r.call, outs, {}, {});
    if (r.ovf)
      overflowAfterCall(ctx, r.ovf, s->ctl ? nullptr : flag, false);
    return fields;
  }
  if (r.ovf) {
    // cq-ew5z: the result (when a handle) and the overflow predicate, one call group; the predicate kept here.
    SmallVector<Value *, 2> outs;
    if (r.handle) {
      outs.push_back(r.value);
      fields.push_back(Operand{r.value, true});
    } else if (!CB.getType()->isVoidTy()) {
      whole = r.value;
      classicalLeaves(ctx.B(), r.value, fields);
    }
    outs.push_back(r.ovf);
    ctx.unc().recordCall(r.call, outs, {}, {});
    overflowAfterCall(ctx, r.ovf, s->ctl ? nullptr : flag, false);
    return fields;
  }
  if (r.handle) {
    ctx.unc().recordTemplate(r.call, callRecordSpec(CB.getType()), r.ops);
    fields.push_back(Operand{r.call, true});
    return fields;
  }
  if (!CB.getType()->isVoidTy()) {
    whole = r.call;
    classicalLeaves(ctx.B(), r.call, fields);
  }
  return fields;
}

// Which leaves of CB's value are quantum (taint's record; CR §1.4 field order).
SmallVector<bool, 4> resultFieldKinds(LoweringContext &ctx, const CallBase &CB) {
  if (CB.getType()->isVoidTy())
    return {};
  if (isComposite(CB.getType()))
    return ctx.T.fieldMask(&CB, ctx.S);
  return {ctx.T.isQuantum(&CB, ctx.S)};
}

// Binds CB to its merged leaves.
void bindMerged(LoweringContext &ctx, CallBase &CB, ArrayRef<Operand> leaves) {
  if (isComposite(CB.getType()))
    ctx.bindFields(&CB, leaves);
  else
    ctx.bind(&CB, leaves.front().v);
}
} // namespace

// CR rule 19 (97): a function pointer loaded at a quantum index is a QROM of callee tags (mem-qrom binds the
// load to the tag rail, Q1). Per candidate k an equality flag tag == k (the last candidate's is the complement,
// needed only as a _ctl predicate); every candidate is called: a pure one unguarded, one with a non-pure gate
// as its _ctl clone under tag == k (and the enclosing quantum predicate), a body-less one as its rule 27 _ctl
// declared clone. Each result field is merged by a select chain on the flags, complement innermost (rule 9);
// a candidate's classical field enters the merge as a seed rail (rule 7). The spine uncomputes twins and flags.
void lowerQromIndirect(LoweringContext &ctx, CallBase &CB, Operand tag) {
  SmallVector<std::pair<Function *, unsigned>, 4> cands = mem::qromCallees(ctx, CB.getCalledOperand());
  if (cands.empty())
    unimplemented("calls: awaiting owner ruling: SPEC_ISSUES \"rule 19: a quantum function pointer that is not "
                  "loaded at a quantum index (a select or merge of function pointers on quantum data)\"",
                  &CB);
  auto taintCands = ctx.T.calleeCandidates(CB, ctx.S);
  auto specOf = [&](Function *G) -> const Specialization * {
    for (auto &[F, sp] : taintCands)
      if (F == G)
        return sp;
    internalError("calls: a QROM callee candidate taint did not lift", &CB);
  };
  bool underQ = underQuantumPredicate(ctx);
  Value *outer = underQ ? ctlFlag(ctx, CB) : nullptr;
  LLVMContext &C = ctx.M.getContext();
  RailType i1{Kind::Int, 1};
  SmallVector<bool, 4> kinds = resultFieldKinds(ctx, CB);
  SmallVector<Value *, 4> flags;
  SmallVector<SmallVector<Operand, 4>, 4> results;
  // E1 (82): a candidate carrying the environment takes the caller's flags and returns its own; the call's
  // flags are the select over the tag, as a result field (a candidate that does not carry them: the caller's).
  bool envAny = any_of(cands, [&](const auto &c) {
    const Specialization *s = specOf(c.first);
    return s && !c.first->isDeclaration() && fenv::cloneCarriesEnv(ctx.T, *s);
  });
  Value *flags0 = envAny ? fenv::envArgs(ctx, CB)[1].v : nullptr;
  SmallVector<Value *, 4> envs;
  for (unsigned k = 0; k < cands.size(); ++k) {
    Function *G = cands[k].first;
    const Specialization *s = specOf(G);
    bool last = k + 1 == cands.size();
    bool needsPred = G->isDeclaration() || (s && s->ctl);
    Value *eqf = nullptr;
    if (!last || needsPred) {
      abi::TemplateSpec eq;
      eq.op = "icmp";
      eq.pred = "eq";
      eq.w = RailType{Kind::Int, 32};
      eq.shape = "hl";
      eqf = ctx.emitTemplate(eq, {tag, Operand{ConstantInt::get(Type::getInt32Ty(C), cands[k].second), false}});
    }
    if (!last)
      flags.push_back(eqf);
    Value *pred = nullptr;
    if (needsPred) {
      pred = eqf;
      if (outer) {
        abi::TemplateSpec andT;
        andT.op = "and";
        andT.w = i1;
        pred = ctx.emitTemplate(andT, {Operand{eqf, true}, Operand{outer, true}});
      }
    }
    Value *whole, *env;
    SmallVector<Operand, 4> f = emitCandidate(ctx, CB, *G, s, pred, whole, env);
    if (envAny)
      envs.push_back(env ? env : flags0);
    if (f.size() != kinds.size())
      internalError("calls: a QROM callee candidate whose result has another field count than the call's", &CB);
    for (unsigned j = 0; j < f.size(); ++j) {
      if (!kinds[j])
        internalError("calls: a classical result field of a call through a quantum function pointer", &CB);
      f[j] = seedActual(ctx, f[j]);
    }
    results.push_back(std::move(f));
  }
  if (envAny) {
    abi::TemplateSpec sel;
    sel.op = "select";
    sel.w = RailType{Kind::Int, 32};
    Value *v = envs.back();
    for (unsigned k = unsigned(flags.size()); k-- > 0;)
      v = ctx.emitTemplate(sel, {Operand{flags[k], true}, Operand{envs[k], true}, Operand{v, true}});
    if (v == flags0) {
      // No candidate changed them: the caller's flags stay.
    } else {
      fenv::afterCloneCall(ctx, CB, v);
    }
  }
  if (kinds.empty())
    return;
  SmallVector<Operand, 4> merged;
  SmallVector<Type *, 4> leafTys;
  if (isComposite(CB.getType()))
    leafTypes(CB.getType(), leafTys, &CB);
  else
    leafTys.push_back(CB.getType());
  for (unsigned j = 0; j < kinds.size(); ++j) {
    abi::TemplateSpec sel;
    sel.op = "select";
    sel.w = railTypeOf(leafTys[j]);
    Value *v = results.back()[j].v;
    for (unsigned k = unsigned(flags.size()); k-- > 0;)
      v = ctx.emitTemplate(sel, {Operand{flags[k], true}, results[k][j], Operand{v, true}});
    merged.push_back(Operand{v, true});
  }
  bindMerged(ctx, CB, merged);
}

// CR rules 19, 27 (cq-sd95): a call through a classical pointer with NO in-module candidate denotes a function outside
// the program; with a quantum argument (or under a quantum predicate) it is rule 27's declared-clone call of the
// function's registered ALL-HANDLES clone, clone_resolve(fp, 0), or its _ctl, clone_resolve(fp, 1), under a
// quantum predicate: every field a handle (a classical actual a seed rail, rule 7), K trailing (the global K: the
// callee has no name here); its twin is clone_resolve(fp, 2) (Uncompute). With no quantum argument outside a
// quantum predicate it stays the ordinary call.
void lowerResolved(LoweringContext &ctx, CallBase &CB, Value *fp, bool underQ) {
  bool anyQ = false;
  for (const Use &u : CB.args())
    anyQ |= ctx.T.isQuantum(u.get(), ctx.S);
  if (!anyQ && !underQ)
    return ordinaryCall(ctx, CB);
  if (any_of(CB.args(), [](const Use &u) { return u->getType()->isPointerTy(); }))
    return lowerDeclaredPointers(ctx, CB, nullptr, fp);
  std::string mask(siteMask(ctx, CB).size(), '1');
  Value *flag = underQ ? ctlFlag(ctx, CB) : nullptr;
  emitDeclaredCall(ctx, CB, nullptr, mask, flag, nullptr, fp);
}

// CR rule 19: a call through a classical function pointer dispatches over the static callee set (taint's
// candidates: the pointer's provenance, else every address-taken function of the call's type): a classical
// chain of pointer-equality tests, each arm calling its candidate as a direct call would (its clone, its _ctl
// clone under the block's quantum predicate, its rule 27 declared clone, or the untainted original); the last
// test's false edge is unreachable (a pointer outside the set is the program's UB). A result field is merged
// by a classical phi (Uncompute::recordMerge for a handle); an arm's classical field of a quantum merged field
// enters as a seed rail (rule 7). The builder is left in the join block.
void lowerIndirect(LoweringContext &ctx, CallBase &CB) {
  capture(ctx);
  const Value *callee = CB.getCalledOperand();
  Operand fp = ctx.operand(callee);
  if (fp.handle)
    return lowerQromIndirect(ctx, CB, fp);
  if (ctx.T.isQuantum(callee, ctx.S))
    unimplemented("calls: awaiting owner ruling: SPEC_ISSUES \"rule 19: a quantum function pointer that is not "
                  "loaded at a quantum index (a select or merge of function pointers on quantum data)\"",
                  &CB);
  auto cands = ctx.T.calleeCandidates(CB, ctx.S);
  bool underQ = underQuantumPredicate(ctx);
  if (cands.empty())
    return lowerResolved(ctx, CB, fp.v, underQ);
  // The flag dominates every arm: computed once, before the dispatch.
  Value *flag = underQ ? ctlFlag(ctx, CB) : nullptr;
  // E1 (82) in rule 19's arms: when a candidate carries the environment, the caller's flags rail (made here,
  // before the dispatch, when there is none yet) goes to the carrying arms, and each arm's flags (the clone's
  // new ones, or a copy of the caller's where the candidate does not carry it) merge at the join.
  bool envAny = any_of(cands, [&](const auto &c) {
    return c.second && !c.first->isDeclaration() && fenv::cloneCarriesEnv(ctx.T, *c.second);
  });
  Value *flags0 = envAny ? fenv::envArgs(ctx, CB)[1].v : nullptr;

  IRBuilder<> &B = ctx.B();
  Function &out = ctx.out();
  LLVMContext &C = ctx.M.getContext();
  BasicBlock *join = BasicBlock::Create(C, "", &out);
  SmallVector<bool, 4> kinds = resultFieldKinds(ctx, CB);
  bool anyQ = is_contained(kinds, true);
  struct Arm { BasicBlock *bb; SmallVector<Operand, 4> f; Value *whole; Value *env; };
  SmallVector<Arm, 4> arms;
  for (auto &[G, s] : cands) {
    Value *eq = B.CreateICmpEQ(fp.v, G);
    BasicBlock *arm = BasicBlock::Create(C, "", &out, join);
    BasicBlock *next = BasicBlock::Create(C, "", &out, join);
    B.CreateCondBr(eq, arm, next);
    B.SetInsertPoint(arm);
    Value *whole, *env;
    SmallVector<Operand, 4> f = emitCandidate(ctx, CB, *G, s, flag, whole, env);
    if (env && anyQ)
      for (unsigned j = 0; j < f.size(); ++j)
        if (kinds[j] && f[j].handle && resultKept(ctx, &CB, j)) {
          // Rule 18 partial measurement (ruling 2026-11-02): the arm's kept result is copied into a fresh rail
          // and the copy continues; the clone's own outs (the result and the flags) stay its twin's.
          SmallVector<Type *, 4> leafTys;
          if (isComposite(CB.getType()))
            leafTypes(CB.getType(), leafTys, &CB);
          else
            leafTys.push_back(CB.getType());
          RailType w = railTypeOf(leafTys[j]);
          CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                     {Constant::getNullValue(irTypeOf(C, w))});
          RailId cid = ctx.unc().recordSeed(c);
          abi::CoreSpec cp{abi::Core::Copy, w};
          CallInst *cc = ctx.emitCore(cp, {f[j].v, c});
          ctx.unc().recordCore(cc, cp, {f[j], Operand{c, true}}, cid);
          f[j] = Operand{c, true};
        }
    if (envAny && !env) {
      // This arm leaves the flags as they are: a fresh copy of them, so every arm's flags are a rail of its own.
      RailType w{Kind::Int, 32};
      CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {B.getInt32(0)});
      RailId cid = ctx.unc().recordSeed(c);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cc = ctx.emitCore(cp, {flags0, c});
      ctx.unc().recordCore(cc, cp, {Operand{flags0, true}, Operand{c, true}}, cid);
      env = c;
    }
    if (f.size() != kinds.size())
      internalError("calls: an indirect-call candidate whose result has another field count than the call's", &CB);
    if (anyQ)
      for (unsigned j = 0; j < f.size(); ++j) {
        // A candidate that measures returns the outcome (rule 2: classical) where another returns a rail. On
        // its path a measurement of the merged value is a classical re-read (rule 2), on the others a
        // measurement: a per-path kind the merge of one rail cannot carry (a seed rail would be measured).
        if (kinds[j] && !f[j].handle)
          unimplemented("calls: an indirect call whose candidates' results differ in kind (a measured outcome in "
                        "one arm, a rail in another: rule 2's per-path re-read of the merged value)",
                        &CB);
        if (!kinds[j] && f[j].handle)
          internalError("calls: a candidate's handle where taint says the call's field is classical", &CB);
      }
    arms.push_back({B.GetInsertBlock(), std::move(f), whole, env});
    B.CreateBr(join);
    B.SetInsertPoint(next);
  }
  B.CreateUnreachable();
  B.SetInsertPoint(join);
  // The flags' merge: its phi with the others at the join's top, the fenv state set after them (the items
  // afterCloneCall may emit split the block).
  PHINode *envPhi = nullptr;
  if (envAny) {
    envPhi = B.CreatePHI(B.getInt32Ty(), arms.size());
    for (Arm &a : arms)
      envPhi->addIncoming(a.env, a.bb);
  }
  auto finishEnv = [&]() {
    if (!envPhi)
      return;
    ctx.unc().recordMerge(envPhi);
    fenv::afterCloneCall(ctx, CB, envPhi);
  };
  if (kinds.empty())
    return finishEnv();
  if (!anyQ) {
    // A classical result: the phi of the arms' values.
    PHINode *phi = B.CreatePHI(CB.getType(), arms.size());
    for (Arm &a : arms) {
      if (!a.whole)
        internalError("calls: a classical indirect-call result with no classical value in an arm", &CB);
      phi->addIncoming(a.whole, a.bb);
    }
    ctx.bind(&CB, phi);
    return finishEnv();
  }
  SmallVector<Operand, 4> merged;
  for (unsigned j = 0; j < kinds.size(); ++j) {
    PHINode *phi = B.CreatePHI(arms.front().f[j].v->getType(), arms.size());
    for (Arm &a : arms)
      phi->addIncoming(a.f[j].v, a.bb);
    if (kinds[j]) {
      if (resultKept(ctx, &CB, j))
        for (Arm &a : arms)
          ctx.unc().setRole(ctx.unc().idOf(a.f[j].v), Role::Result);
      ctx.unc().recordMerge(phi);
    }
    merged.push_back(Operand{phi, bool(kinds[j])});
  }
  bindMerged(ctx, CB, merged);
  finishEnv();
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
namespace {
struct VaArea { ObjectId obj; SmallVector<RailId, 4> rails; };
std::map<const Function *, SmallVector<VaArea, 2>> &vaAreas() {
  static std::map<const Function *, SmallVector<VaArea, 2>> m;
  return m;
}
} // namespace

void lowerVarargs(LoweringContext &ctx, Instruction &I) {
  auto *II = dyn_cast<IntrinsicInst>(&I);
  // clang's x86-64 SysV ABI expands va_arg into loads of the save and overflow areas (CR §0: x86-64, -O1
  // only), so no va_arg instruction reaches the pass.
  if (!II)
    internalError("calls: a va_arg instruction (clang expands va_arg on x86-64, CR §0)", &I);
  // An entry is called classically: its variadic actuals are classical and its va_list host memory, so
  // the intrinsics are the ordinary ones even under a quantum predicate (initialising a va_list carries
  // no quantum data and nothing reads it but the va_arg code of the same activation).
  if (ctx.S.isEntry()) {
    for (const Use &u : II->args())
      if (ctx.operand(u.get()).handle)
        internalError("calls: a va_list pointer bound to a rail", &I);
    spine::copyClassical(ctx, I);
    return;
  }
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  Type *i32 = Type::getInt32Ty(C), *i8 = Type::getInt8Ty(C);
  switch (II->getIntrinsicID()) {
  case Intrinsic::vaend:
    return;
  case Intrinsic::vacopy: {
    Operand d = ctx.operand(II->getArgOperand(0)), sr = ctx.operand(II->getArgOperand(1));
    if (d.handle || sr.handle)
      internalError("calls: a va_list pointer bound to a rail", &I);
    B.CreateMemCpy(d.v, Align(8), sr.v, Align(8), 24);
    return;
  }
  case Intrinsic::vastart:
    break;
  default:
    internalError("calls: lowerVarargs of another intrinsic", &I);
  }
  const Function &F = *ctx.S.F;
  if (!F.isVarArg())
    internalError("calls: llvm.va_start in a function that is not variadic (invalid IR)", &I);
  if (Triple(ctx.M.getTargetTriple()).getArch() != Triple::x86_64)
    internalError("calls: llvm.va_start on a target other than x86-64 SysV (CR §0)", &I);
  const DataLayout &DL = ctx.M.getDataLayout();
  // The registers the named parameters take (x86-64 SysV, as LLVM's CC_X86_64_C assigns the IR parameters
  // clang emits): an integer of at most 64 bits or a pointer one of the 6 gp registers, a wider integer
  // (at most 128 bits) two, a float, double or vector of at most 128 bits one of the 8 xmm registers; an
  // x86_fp80, a byval aggregate and whatever finds its registers taken go to the stack, which va_arg never
  // reads for a named parameter.
  unsigned gp = 0, fp = 0;
  auto takeGp = [&](unsigned n) {
    if (gp + n <= 6) {
      gp += n;
      return true;
    }
    return false;
  };
  auto takeFp = [&]() {
    if (fp < 8) {
      ++fp;
      return true;
    }
    return false;
  };
  for (const Argument &A : F.args()) {
    Type *t = A.getType();
    if (A.hasByValAttr() || t->isX86_FP80Ty())
      continue;
    if (t->isPointerTy() || (t->isIntegerTy() && t->getIntegerBitWidth() <= 64))
      takeGp(1);
    else if (t->isIntegerTy() && t->getIntegerBitWidth() <= 128)
      takeGp(2);
    else if (t->isFloatingPointTy() || (t->isVectorTy() && DL.getTypeSizeInBits(t).getFixedValue() <= 128))
      takeFp();
    else
      internalError("calls: a named parameter of a type no x86-64 C function has (CR §0)", &A);
  }
  unsigned gpNamed = gp, fpNamed = fp;
  spine::Shared &sh = spine::shared(ctx);
  const SmallVector<Operand, 4> &va = sh.varargs;
  SmallVector<VariadicActual, 4> vt = variadicActuals(ctx.T, ctx.S, &I);
  if (vt.size() != va.size())
    internalError("calls: a variadic clone whose parameters are not its call sites' variadic actuals", &I);
  bool handles = any_of(va, [](const Operand &o) { return o.handle; });
  // Where each actual goes: the register save area (gp slot k at 8k, xmm slot k at 48 + 16k) or the overflow
  // area, which follows the save area at 176 in the same object (taint's one save-area object) in 8-byte
  // slots, 16-byte aligned for an x86_fp80, a 16-byte integer and an aggregate of 16-byte alignment.
  struct Place { uint64_t off; uint64_t size; };
  SmallVector<Place, 4> place;
  uint64_t over = 0;
  auto overflow = [&](uint64_t size, uint64_t align) {
    over = alignTo(over, std::max<uint64_t>(align, 8));
    Place p{176 + over, size};
    over += alignTo(size, 8);
    return p;
  };
  for (const VariadicActual &a : vt) {
    Type *t = a.ty;
    if (a.byval) {
      if (handles)
        unimplemented("calls: a variadic clone whose save area holds handles and an aggregate actual passed in "
                      "memory (its fields' cells: rules 20, 26 in the variadic save area)",
                      &I);
      place.push_back(overflow(DL.getTypeAllocSize(a.byval), std::max<uint64_t>(DL.getABITypeAlign(a.byval).value(), 8)));
    } else if (t->isPointerTy() || (t->isIntegerTy() && t->getIntegerBitWidth() <= 64)) {
      unsigned k = gp;
      place.push_back(takeGp(1) ? Place{8 * k, 8} : overflow(8, 8));
    } else if (t->isIntegerTy()) {
      unsigned k = gp;
      place.push_back(takeGp(2) ? Place{8 * k, 16} : overflow(16, 16));
    } else if (t->isX86_FP80Ty()) {
      place.push_back(overflow(16, 16));
    } else {
      if (handles && t->isVectorTy())
        unimplemented("calls: a variadic clone whose save area holds handles and a vector actual (rule 25's "
                      "lanes in the variadic save area)",
                      &I);
      uint64_t sz = DL.getTypeAllocSize(t);
      unsigned k = fp;
      place.push_back(takeFp() ? Place{48 + 16 * k, 16} : overflow(sz, sz > 8 ? 16 : 8));
    }
  }
  Operand ap = ctx.operand(II->getArgOperand(0));
  if (ap.handle)
    internalError("calls: a va_list pointer bound to a rail", &I);
  IRBuilder<> EB(&ctx.out().getEntryBlock(), ctx.out().getEntryBlock().getFirstInsertionPt());
  AllocaInst *area = EB.CreateAlloca(ArrayType::get(Type::getInt8Ty(C), 176 + std::max<uint64_t>(over, 8)), nullptr,
                                     "va.save");
  area->setAlignment(Align(16));
  VaArea rec;
  for (unsigned k = 0; k < va.size(); ++k) {
    Value *slot = B.CreateConstInBoundsGEP1_64(i8, area, place[k].off);
    Value *v = va[k].v;
    if (vt[k].byval) {
      Align al = DL.getABITypeAlign(vt[k].byval);
      B.CreateMemCpy(slot, Align(8), v, al, DL.getTypeAllocSize(vt[k].byval));
      continue;
    }
    if (handles && !va[k].handle && !v->getType()->isPointerTy()) {
      // A classical actual in a save area of handles is promoted to a seed rail (rule 7, 95's reference);
      // a classical pointer stays the pointer the cell holds (taint: its pointer actuals are its pointers).
      CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(v->getType())}, {v});
      rec.rails.push_back(ctx.unc().recordSeed(seed));
      v = seed;
    } else if (va[k].handle) {
      rec.rails.push_back(ctx.unc().idOf(v));
    }
    B.CreateAlignedStore(v, slot, Align(8));
  }
  B.CreateAlignedStore(ConstantInt::get(i32, 8 * gpNamed), ap.v, Align(16));
  B.CreateAlignedStore(ConstantInt::get(i32, 48 + 16 * fpNamed), B.CreateConstInBoundsGEP1_64(i8, ap.v, 4), Align(4));
  B.CreateAlignedStore(B.CreateConstInBoundsGEP1_64(i8, area, 176), B.CreateConstInBoundsGEP1_64(i8, ap.v, 8),
                       Align(8));
  B.CreateAlignedStore(area, B.CreateConstInBoundsGEP1_64(i8, ap.v, 16), Align(8));
  if (handles) {
    rec.obj = ctx.T.objectOf(II, ctx.S);
    vaAreas()[&ctx.out()].push_back(rec);
  }
}

bool isVaArea(LoweringContext &ctx, ObjectId o) {
  auto it = vaAreas().find(&ctx.out());
  return it != vaAreas().end() && any_of(it->second, [&](const VaArea &a) { return a.obj == o; });
}

bool lowerVaAreaLoad(LoweringContext &ctx, LoadInst &ld) {
  auto it = vaAreas().find(&ctx.out());
  if (it == vaAreas().end())
    return false;
  ArrayRef<ObjectId> prov = ctx.T.provenance(ld.getPointerOperand(), ctx.S);
  const VaArea *a = nullptr;
  for (const VaArea &r : it->second)
    if (prov.size() == 1 && prov[0] == r.obj)
      a = &r;
  if (!a)
    return false;
  Operand p = ctx.operand(ld.getPointerOperand());
  if (p.handle)
    internalError("calls: a save-area pointer bound to a rail", &ld);
  if (ld.getType()->isPointerTy()) {
    // A pointer cell holds the classical pointer actual (lowerVarargs): the host load.
    LoadInst *n = ctx.B().CreateAlignedLoad(ld.getType(), p.v, ld.getAlign());
    ctx.bind(&ld, n);
    return true;
  }
  // Every other cell of a save area of handles holds one actual's handle (lowerVarargs lays out scalars
  // only there): -O1's va_arg code reads an actual as one value of its type at its slot.
  if (!scalarRailType(ld.getType()))
    internalError("calls: a read of a variadic save area of handles that is not one scalar actual", &ld);
  // The slot holds a handle (one of the actuals' rails, rule 20's uniform slot array).
  LoadInst *h = ctx.B().CreateAlignedLoad(handleTy(ctx.M.getContext()), p.v, Align(4));
  ctx.unc().recordCellLoad(h, a->rails);
  ctx.bindFields(&ld, {Operand{h, true}});
  return true;
}

void lowerAsm(LoweringContext &, CallBase &CB) {
  unimplemented("calls: calls::lowerAsm (inline asm with a quantum operand, rule 27: cq-w3-asm)", &CB);
}

} // namespace cq::calls

namespace cq::calls {
// C1 (cq-arch 2026-11-01): stub until stream A builds it.
// C1 (CR rule 24, 106): site is lowered as the direct call of taint's callee specialization for it (the
// start routine's clone at a pthread_create), formal k taking site's operand argMap[k]. M1 (with the map),
// recordCall and the twin as for a plain clone call. site's own result is the consumer's to bind; the
// clone's result is a result of the call group (undone by the twin) and bound to nothing.
llvm::Value *emitDispatchArm(LoweringContext &ctx, llvm::CallBase &site, llvm::Function &G, const Specialization *s,
                             llvm::Value *flag) {
  capture(ctx);
  Value *whole = nullptr, *env = nullptr;
  (void)emitCandidate(ctx, site, G, s, flag, whole, env);
  return env;
}

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
      unsigned last = st->getNumElements() - 1 - (r.ovf ? 1 : 0);   // cq-ew5z: the overflow predicate follows
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
  if (r.ovf)
    outs.push_back(r.ovf);   // cq-ew5z: the overflow predicate, the clone's last field
  if (outs.empty() && r.slotOuts.empty()) {
    if (!r.extra.empty())
      internalError("calls: old slot cells passed to a clone that reloads none", &site);
    return;
  }
  ctx.unc().recordCall(r.call, outs, r.slotOuts, r.extra);
  fatptr::finishSlotTableCall(ctx, r.call);
  mem::finishParamCells(ctx, r.call);
  if (r.ovf)
    overflowAfterCall(ctx, r.ovf, !cs->ctl && underQuantumPredicate(ctx) ? ctlFlag(ctx, site) : nullptr, false);
}
} // namespace cq::calls

