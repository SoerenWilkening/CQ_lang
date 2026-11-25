// Module aggr (cq-w1-aggr): widths, vectors and aggregates (CR rules 25, 26).
//
//  Fields. A value of struct, array or fixed-vector type is bound field-wise: one Operand per scalar
//  leaf (struct and array elements, vector lanes), depth first, left to right. A quantum leaf is a
//  rail handle, a classical leaf a classical value of the new IR (rule 26: one rail per quantum scalar
//  field, classical fields stay classical). A classical aggregate the spine copied as one value, or a
//  constant, is split into its leaves on demand (leaves(), flattenResult).
//
//  A composite whose leaves are all classical is bound as one classical value of its type instead
//  (rebuilt at the builder; taint is lane-precise, so its users may be copied classically).
//
//  extractvalue / insertvalue / extractelement / insertelement / shufflevector only re-index fields:
//  no gate (rules 25, 26). A poison lane of a shuffle mask is a classical poison leaf.
//
//  Element-wise vector instructions (binary, fneg, compare, cast, freeze) are lowered lane by lane
//  (rule 25: <N x T> is N lanes): a lane with a quantum operand is the rule 4 template of its scalar
//  opcode, with the spine's operand conventions (handle first for a commutative op, an fp one unless
//  the literal is a NaN constant; a compare flips its predicate instead of taking _lh); a lane with
//  only classical operands is the scalar classical opcode. A quantum lane that nothing reads gets no
//  template (rule 3): lane demand follows extractelement, insertelement, shufflevector and the
//  element-wise users; any other user reads every lane.
//
//  i128, _BitInt(N), _Float16 and x86_fp80 are width variants of the scalar rules (rule 25): they
//  need nothing here beyond RailType (Common.h).
#include "cq/Aggregates.h"

#include <map>
#include <optional>

#include "cq/Abi.h"
#include "../spine/SpineInternal.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/InstrTypes.h"

using namespace llvm;

namespace cq::aggr {

namespace {

bool isComposite(Type *t) { return t->isStructTy() || t->isArrayTy() || t->isVectorTy(); }

unsigned leafCount(Type *t, const Value *at) {
  if (auto *st = dyn_cast<StructType>(t)) {
    unsigned n = 0;
    for (Type *e : st->elements())
      n += leafCount(e, at);
    return n;
  }
  if (auto *at2 = dyn_cast<ArrayType>(t))
    return unsigned(at2->getNumElements()) * leafCount(at2->getElementType(), at);
  if (auto *vt = dyn_cast<FixedVectorType>(t))
    return vt->getNumElements();
  if (isa<ScalableVectorType>(t))
    internalError("aggr: IR the pinned pipeline cannot emit (CR §0, rule 25): a scalable vector", at);
  return 1;
}

Type *elementType(Type *t, unsigned i) {
  if (auto *st = dyn_cast<StructType>(t))
    return st->getElementType(i);
  if (auto *at = dyn_cast<ArrayType>(t))
    return at->getElementType();
  return cast<VectorType>(t)->getElementType();
}

unsigned elementCount(Type *t) {
  if (auto *st = dyn_cast<StructType>(t))
    return st->getNumElements();
  if (auto *at = dyn_cast<ArrayType>(t))
    return unsigned(at->getNumElements());
  return cast<FixedVectorType>(t)->getNumElements();
}

// The leaves of a constant (any composite constant, undef, poison and zeroinitializer included).
void constantLeaves(Constant *c, SmallVectorImpl<Operand> &out, const Value *at) {
  Type *t = c->getType();
  if (!isComposite(t)) {
    out.push_back(Operand{c, false});
    return;
  }
  unsigned n = elementCount(t);
  for (unsigned i = 0; i < n; ++i) {
    Constant *e = c->getAggregateElement(i);
    if (!e)
      internalError("aggr: a constant aggregate with no element " + std::to_string(i), at);
    constantLeaves(e, out, at);
  }
}

// The leaves of a classical composite value of the new IR, extracted at the builder.
void classicalLeaves(IRBuilder<> &B, Value *v, SmallVectorImpl<Operand> &out, const Value *at) {
  Type *t = v->getType();
  if (!isComposite(t)) {
    out.push_back(Operand{v, false});
    return;
  }
  if (auto *c = dyn_cast<Constant>(v)) {
    constantLeaves(c, out, at);
    return;
  }
  unsigned n = elementCount(t);
  for (unsigned i = 0; i < n; ++i) {
    Value *e = t->isVectorTy() ? B.CreateExtractElement(v, uint64_t(i)) : B.CreateExtractValue(v, {i});
    classicalLeaves(B, e, out, at);
  }
}

// cq-0umd (166, rule 26): the fields per scalar leaf of a composite value whose packed integer leaf is
// bound as several fields, per lowered function (another specialization of the same original binds its
// own). A value with no entry has one field per leaf.
std::map<std::pair<const Function *, const Value *>, SmallVector<unsigned, 4>> &leafFieldMap() {
  static std::map<std::pair<const Function *, const Value *>, SmallVector<unsigned, 4>> m;
  return m;
}

// The fields per leaf of v (scalar: the fields it is bound to, a packed integer's several).
SmallVector<unsigned, 4> fieldsPerLeaf(LoweringContext &ctx, const Value *v) {
  unsigned n = leafCount(v->getType(), v);
  if (!isComposite(v->getType())) {
    if (isa<Constant>(v) || !v->getType()->isIntegerTy())
      return {1};
    return {std::max(1u, unsigned(ctx.fields(v).size()))};
  }
  auto it = leafFieldMap().find({&ctx.out(), v});
  if (it != leafFieldMap().end() && it->second.size() == n)
    return it->second;
  return SmallVector<unsigned, 4>(n, 1);
}

void setFieldsPerLeaf(LoweringContext &ctx, const Value *v, ArrayRef<unsigned> per) {
  if (llvm::all_of(per, [](unsigned c) { return c == 1; }))
    leafFieldMap().erase({&ctx.out(), v});
  else
    leafFieldMap()[{&ctx.out(), v}] = SmallVector<unsigned, 4>(per.begin(), per.end());
}

unsigned sumOf(ArrayRef<unsigned> a, unsigned from, unsigned to) {
  unsigned s = 0;
  for (unsigned k = from; k < to; ++k)
    s += a[k];
  return s;
}

// The fields of an original value as leaves (a packed integer leaf contributes its several fields).
SmallVector<Operand, 4> leaves(LoweringContext &ctx, const Value *v) {
  SmallVector<Operand, 4> out;
  if (auto *c = dyn_cast<Constant>(v)) {
    constantLeaves(const_cast<Constant *>(c), out, v);
    return out;
  }
  SmallVector<unsigned, 4> per = fieldsPerLeaf(ctx, v);
  unsigned n = sumOf(per, 0, unsigned(per.size()));
  SmallVector<Operand, 4> fs = ctx.fields(v);
  if (fs.size() == 1 && isComposite(v->getType()) && fs.front().v->getType() == v->getType()) {
    if (fs.front().handle)
      internalError("aggr: a composite value bound to one rail handle", v);
    classicalLeaves(ctx.B(), fs.front().v, out, v);
  } else {
    out = fs;
  }
  if (out.size() != n)
    internalError("aggr: " + std::to_string(out.size()) + " fields bound where the type has " + std::to_string(n) +
                      " leaves",
                  v);
  for (const Operand &o : out)
    if (!o.handle && isComposite(o.v->getType()))
      internalError("aggr: a composite field", v);
  return out;
}

// The leaf range [first, first + count) of an index path into an aggregate type.
std::pair<unsigned, unsigned> leafRange(Type *t, ArrayRef<unsigned> idx, const Value *at) {
  unsigned first = 0;
  for (unsigned i : idx) {
    for (unsigned j = 0; j < i; ++j)
      first += leafCount(elementType(t, j), at);
    t = elementType(t, i);
  }
  return {first, leafCount(t, at)};
}

// Rebuilds a classical composite of type t from its leaves at the builder (constants fold).
Value *materialize(IRBuilder<> &B, Type *t, ArrayRef<Operand> ops, unsigned &k) {
  if (!isComposite(t))
    return ops[k++].v;
  Value *agg = PoisonValue::get(t);
  unsigned n = elementCount(t);
  for (unsigned i = 0; i < n; ++i) {
    Value *e = materialize(B, elementType(t, i), ops, k);
    agg = t->isVectorTy() ? B.CreateInsertElement(agg, e, uint64_t(i)) : B.CreateInsertValue(agg, e, {i});
  }
  return agg;
}

// The scalar leaf types of t, depth first, left to right.
void leafTypes(Type *t, SmallVectorImpl<Type *> &out) {
  if (!isComposite(t)) {
    out.push_back(t);
    return;
  }
  for (unsigned i = 0, n = elementCount(t); i < n; ++i)
    leafTypes(elementType(t, i), out);
}

// cq-0umd: the classical fields of a composite whose leaf k has per[k] fields, with each packed leaf
// rebuilt as one integer of its type: field j at the bit offset of the fields before it (zext, shl, or).
SmallVector<Operand, 4> repackClassical(IRBuilder<> &B, const DataLayout &DL, Type *t, ArrayRef<Operand> ops,
                                        ArrayRef<unsigned> per, const Value *at) {
  SmallVector<Type *, 8> tys;
  leafTypes(t, tys);
  if (tys.size() != per.size())
    internalError("aggr: a packed composite's field counts are not its leaves", at);
  SmallVector<Operand, 4> out;
  unsigned k = 0;
  for (unsigned l = 0; l < tys.size(); ++l) {
    if (per[l] == 1) {
      out.push_back(ops[k++]);
      continue;
    }
    auto *lt = dyn_cast<IntegerType>(tys[l]);
    if (!lt)
      internalError("aggr: a packed leaf that is not an integer", at);
    Value *acc = ConstantInt::get(lt, 0);
    unsigned shift = 0;
    for (unsigned j = 0; j < per[l]; ++j) {
      Value *f = ops[k++].v;
      unsigned bits = unsigned(DL.getTypeSizeInBits(f->getType()).getFixedValue());
      if (!f->getType()->isIntegerTy())
        f = B.CreateBitCast(f, B.getIntNTy(bits));
      if (shift + bits > lt->getBitWidth())
        internalError("aggr: a packed leaf's fields overflow it", at);
      Value *z = B.CreateZExt(f, lt);
      if (shift)
        z = B.CreateShl(z, shift);
      acc = B.CreateOr(acc, z);
      shift += bits;
    }
    if (shift != lt->getBitWidth())
      internalError("aggr: a packed leaf's fields do not tile it", at);
    out.push_back(Operand{acc, false});
  }
  return out;
}

// A composite with a rail among its leaves is bound field-wise. One with only classical leaves is
// bound as one classical value of its type: taint is lane-precise, so such a value may be classical
// and its users copied classically, which read it with operand() (one field).
void bindResult(LoweringContext &ctx, const Value *orig, ArrayRef<Operand> ops) {
  Type *t = orig->getType();
  if (ops.empty()) {
    // An empty struct or array has one value and no field: it is classical (rule 26, nothing to carry).
    ctx.bindFields(orig, {Operand{Constant::getNullValue(t), false}});
    return;
  }
  bool anyRail = false;
  for (const Operand &o : ops)
    anyRail |= o.handle;
  if (!anyRail && isComposite(t)) {
    // cq-0umd (166): a packed integer leaf bound as several classical fields is rebuilt as one classical
    // integer from them (low bits first, the fields tile the leaf), so the value is one classical value.
    SmallVector<Operand, 4> flat(ops.begin(), ops.end());
    auto it = leafFieldMap().find({&ctx.out(), orig});
    if (it != leafFieldMap().end()) {
      flat = repackClassical(ctx.B(), ctx.M.getDataLayout(), t, ops, it->second, orig);
      leafFieldMap().erase(it);
    }
    unsigned k = 0;
    Value *v = materialize(ctx.B(), t, flat, k);
    ctx.bindFields(orig, {Operand{v, false}});
    return;
  }
  ctx.bindFields(orig, ops);
}

// ---- lane demand (rule 3: a quantum lane that nothing reads gets no template) ----

bool elementWise(const Instruction *I) {
  return isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<CmpInst>(I) || isa<CastInst>(I) ||
         isa<FreezeInst>(I) || isa<SelectInst>(I);
}

class LaneDemand {
public:
  bool demanded(const Value *v, unsigned lane) {
    auto key = std::make_pair(v, lane);
    if (auto it = memo.find(key); it != memo.end())
      return it->second;
    memo[key] = true;   // a cycle (through a phi) reads it
    bool d = compute(v, lane);
    memo[key] = d;
    return d;
  }

private:
  DenseMap<std::pair<const Value *, unsigned>, bool> memo;

  bool compute(const Value *v, unsigned lane) {
    for (const User *u : v->users()) {
      const auto *I = dyn_cast<Instruction>(u);
      if (!I)
        return true;
      if (auto *ee = dyn_cast<ExtractElementInst>(I)) {
        auto *ci = dyn_cast<ConstantInt>(ee->getIndexOperand());
        if (!ci || ci->getZExtValue() == lane)
          return true;
        continue;
      }
      if (auto *ie = dyn_cast<InsertElementInst>(I)) {
        if (ie->getOperand(0) != v)
          return true;   // the vector inserted as a scalar operand: not a lane-wise read
        auto *ci = dyn_cast<ConstantInt>(ie->getOperand(2));
        if (!ci)
          return true;
        if (ci->getZExtValue() != lane && demanded(ie, lane))
          return true;
        continue;
      }
      if (auto *sv = dyn_cast<ShuffleVectorInst>(I)) {
        unsigned n = cast<FixedVectorType>(sv->getOperand(0)->getType())->getNumElements();
        ArrayRef<int> mask = sv->getShuffleMask();
        for (unsigned r = 0; r < mask.size(); ++r) {
          int m = mask[r];
          bool hit = (sv->getOperand(0) == v && m == int(lane)) || (sv->getOperand(1) == v && m == int(lane + n));
          if (hit && demanded(sv, r))
            return true;
        }
        continue;
      }
      if (elementWise(I) && I->getType()->isVectorTy()) {
        if (demanded(I, lane))
          return true;
        continue;
      }
      return true;
    }
    return false;
  }
};

// ---- one lane of an element-wise instruction ----

RailType laneRail(Type *t, const Value *at) {
  if (!t->isIntegerTy() && !t->isHalfTy() && !t->isBFloatTy() && !t->isFloatTy() && !t->isDoubleTy() &&
      !t->isX86_FP80Ty())
    internalError("aggr: IR the pinned pipeline cannot emit (CR §0, rule 25): a vector lane of IR type that is not iN/half/bfloat/float/double/x86_fp80 (a pointer vector)", at);
  return railTypeOf(t);
}

bool provablyNotNaN(const Value *v) {
  if (auto *c = dyn_cast<ConstantFP>(v))
    return !c->isNaN();
  return true;
}

const char *binName(Instruction::BinaryOps op) {
  switch (op) {
  case Instruction::Add: return "add";
  case Instruction::Sub: return "sub";
  case Instruction::Mul: return "mul";
  case Instruction::UDiv: return "udiv";
  case Instruction::SDiv: return "sdiv";
  case Instruction::URem: return "urem";
  case Instruction::SRem: return "srem";
  case Instruction::And: return "and";
  case Instruction::Or: return "or";
  case Instruction::Xor: return "xor";
  case Instruction::Shl: return "shl";
  case Instruction::LShr: return "lshr";
  case Instruction::AShr: return "ashr";
  case Instruction::FAdd: return "fadd";
  case Instruction::FSub: return "fsub";
  case Instruction::FMul: return "fmul";
  case Instruction::FDiv: return "fdiv";
  case Instruction::FRem: return "frem";
  default: return nullptr;
  }
}

const char *castName(Instruction::CastOps op) {
  switch (op) {
  case Instruction::ZExt: return "zext";
  case Instruction::SExt: return "sext";
  case Instruction::Trunc: return "trunc";
  case Instruction::FPExt: return "fpext";
  case Instruction::FPTrunc: return "fptrunc";
  case Instruction::SIToFP: return "sitofp";
  case Instruction::UIToFP: return "uitofp";
  case Instruction::FPToSI: return "fptosi";
  case Instruction::FPToUI: return "fptoui";
  case Instruction::BitCast: return "bitcast";
  default: return nullptr;
  }
}

// A classical lane: the scalar opcode over the lane operands, flags copied.
Value *classicalLane(LoweringContext &ctx, Instruction &I, ArrayRef<Value *> ops) {
  Instruction *n;
  if (auto *bo = dyn_cast<BinaryOperator>(&I))
    n = BinaryOperator::Create(bo->getOpcode(), ops[0], ops[1]);
  else if (auto *un = dyn_cast<UnaryOperator>(&I))
    n = UnaryOperator::Create(un->getOpcode(), ops[0]);
  else if (auto *cmp = dyn_cast<CmpInst>(&I))
    n = CmpInst::Create(cmp->getOpcode(), cmp->getPredicate(), ops[0], ops[1]);
  else if (auto *ci = dyn_cast<CastInst>(&I))
    n = CastInst::Create(ci->getOpcode(), ops[0], cast<VectorType>(I.getType())->getElementType());
  else if (isa<FreezeInst>(I))
    n = new FreezeInst(ops[0]);
  else if (isa<SelectInst>(I))
    n = SelectInst::Create(ops[0], ops[1], ops[2]);
  else
    internalError("aggr: classicalLane of a non-element-wise instruction", &I);
  n->copyIRFlags(&I);
  if (isa<FPMathOperator>(n) && isa<FPMathOperator>(&I))
    n->copyFastMathFlags(&I);
  return ctx.B().Insert(n);
}

// Rule 9 on one leaf of a select (a vector lane under its condition lane, or a field of a composite
// select under the scalar condition). A quantum condition: one select template over the arms
// (cq_template_select_<W>[_shape], the condition a handle). A classical condition: a classical select
// over the handles, a classical arm seeded (rule 7) when the other is a rail; no gate.
Operand selectLeaf(LoweringContext &ctx, Operand c, Operand t, Operand f, RailType w, const Value *at) {
  if (c.handle) {
    abi::TemplateSpec spec;
    spec.op = "select";
    spec.w = w;
    std::string shape = std::string(t.handle ? "h" : "l") + (f.handle ? "h" : "l");
    spec.shape = shape == "hh" ? "" : shape;
    return Operand{ctx.emitTemplate(spec, {c, t, f}), true};
  }
  IRBuilder<> &B = ctx.B();
  if (auto *k = dyn_cast<ConstantInt>(c.v))
    return k->isOne() ? t : f;
  if (!t.handle && !f.handle)
    return Operand{B.CreateSelect(c.v, t.v, f.v), false};
  if (t.v == f.v)
    return t;
  auto seed = [&](Operand o) -> Value * {
    if (o.handle)
      return o.v;
    if (o.v->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("aggr: a select arm whose type is not its leaf's rail type", at);
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {o.v});
    ctx.unc().recordSeed(a);
    return a;
  };
  Value *ht = seed(t), *hf = seed(f);
  auto *m = cast<Instruction>(B.CreateSelect(c.v, ht, hf));
  ctx.unc().recordMerge(m);
  return Operand{m, true};
}

// A lane with at least one quantum operand: the rule 4 template of the scalar opcode.
Operand quantumLane(LoweringContext &ctx, Instruction &I, SmallVector<Operand, 3> ops) {
  abi::TemplateSpec spec;
  if (auto *bo = dyn_cast<BinaryOperator>(&I)) {
    const char *op = binName(bo->getOpcode());
    if (!op)
      internalError("aggr: a binary opcode outside LLVM's set", &I);
    spec.op = op;
    spec.w = laneRail(I.getType()->getScalarType(), &I);
    Operand x = ops[0], y = ops[1];
    if (x.handle && y.handle) {
      spec.shape = "";
    } else if (x.handle) {
      spec.shape = "hl";
    } else {
      StringRef o = spec.op;
      bool commInt = o == "add" || o == "mul" || o == "and" || o == "or" || o == "xor";
      bool commFp = o == "fadd" || o == "fmul";
      if (commInt || (commFp && provablyNotNaN(x.v))) {
        std::swap(x, y);
        spec.shape = "hl";
      } else {
        spec.shape = "lh";
      }
    }
    return Operand{ctx.emitTemplate(spec, {x, y}), true};
  }
  if (auto *un = dyn_cast<UnaryOperator>(&I)) {
    if (un->getOpcode() != Instruction::FNeg)
      internalError("aggr: a unary opcode outside LLVM's set (fneg is the only one)", &I);
    spec.op = "fneg";
    spec.w = laneRail(I.getType()->getScalarType(), &I);
    return Operand{ctx.emitTemplate(spec, {ops[0]}), true};
  }
  if (auto *cmp = dyn_cast<CmpInst>(&I)) {
    Operand x = ops[0], y = ops[1];
    CmpInst::Predicate p = cmp->getPredicate();
    if (x.handle && !y.handle) {
      spec.shape = "hl";
    } else if (!x.handle && y.handle) {
      std::swap(x, y);   // compares never take _lh: flip the predicate (CR §1.2)
      p = CmpInst::getSwappedPredicate(p);
      spec.shape = "hl";
    }
    spec.op = isa<ICmpInst>(cmp) ? "icmp" : "fcmp";
    spec.pred = CmpInst::getPredicateName(p).str();
    spec.w = laneRail(cmp->getOperand(0)->getType()->getScalarType(), &I);
    return Operand{ctx.emitTemplate(spec, {x, y}), true};
  }
  if (auto *ci = dyn_cast<CastInst>(&I)) {
    const char *op = castName(ci->getOpcode());
    if (!op)
      internalError("aggr: IR the pinned pipeline cannot emit (CR §0, rule 25): a cast of a pointer vector", &I);
    Type *from = ci->getSrcTy()->getScalarType(), *to = ci->getDestTy()->getScalarType();
    if (from == to)
      return ops[0];   // a no-op bitcast lane: no gate (rule 3)
    spec.op = op;
    spec.w = laneRail(from, &I);
    spec.to = laneRail(to, &I);
    return Operand{ctx.emitTemplate(spec, {ops[0]}), true};
  }
  if (isa<FreezeInst>(I))
    return ops[0];   // rule 3: a rail's basis value is never poison
  if (isa<SelectInst>(I))
    return selectLeaf(ctx, ops[0], ops[1], ops[2], laneRail(I.getType()->getScalarType(), &I), &I);
  internalError("aggr: quantumLane of a non-element-wise instruction", &I);
}

// ---- rule 6 on a lane: the bijective update of a dead old lane value ----
//
// A lane of an element-wise add, sub, xor, mul by an odd literal or fneg is a bijective update of its
// operand lane y (CR rule 6). The old rail is cleaned when it is dead: lane re-indexing (extractelement,
// insertelement, shufflevector, freeze) only aliases a rail, so deadness follows every alias of it from
// the value that minted it, and every reader must be earlier than the update (an earlier lane of the
// same instruction is earlier) and none a store, return, call or phi. Operand 0 is tried first, as for
// a scalar update; an operand lane that reads y (a composite update, 127) blocks it.

struct LaneRef {
  const Value *v;
  int lane;   // -1: a scalar
  bool operator==(const LaneRef &o) const { return v == o.v && lane == o.lane; }
};

std::optional<unsigned> constLane(const Value *idx) {
  if (auto *ci = dyn_cast<ConstantInt>(idx))
    return unsigned(ci->getZExtValue());
  return std::nullopt;
}

// The value (and lane) that minted the rail r holds, through lane aliases; nullopt when the chain has a
// non-constant index or a poison lane.
std::optional<LaneRef> originOf(LaneRef r) {
  for (unsigned guard = 0; guard < 1024; ++guard) {
    const Value *v = r.v;
    if (auto *ee = dyn_cast<ExtractElementInst>(v)) {
      auto i = constLane(ee->getIndexOperand());
      if (!i)
        return std::nullopt;
      r = {ee->getVectorOperand(), int(*i)};
    } else if (auto *ie = dyn_cast<InsertElementInst>(v)) {
      auto i = constLane(ie->getOperand(2));
      if (!i)
        return std::nullopt;
      r = int(*i) == r.lane ? LaneRef{ie->getOperand(1), -1} : LaneRef{ie->getOperand(0), r.lane};
    } else if (auto *sv = dyn_cast<ShuffleVectorInst>(v)) {
      int m = sv->getMaskValue(unsigned(r.lane));
      int n = int(cast<FixedVectorType>(sv->getOperand(0)->getType())->getNumElements());
      if (m < 0)
        return std::nullopt;
      r = m < n ? LaneRef{sv->getOperand(0), m} : LaneRef{sv->getOperand(1), m - n};
    } else if (auto *fr = dyn_cast<FreezeInst>(v)) {
      r = {fr->getOperand(0), r.lane};
    } else if (auto *ev = dyn_cast<ExtractValueInst>(v)) {
      // A field of an aggregate (rule 26: re-indexing, no gate): leaf first + lane of the aggregate.
      auto [first, count] = leafRange(ev->getAggregateOperand()->getType(), ev->getIndices(), ev);
      (void)count;
      r = {ev->getAggregateOperand(), int(first) + (r.lane < 0 ? 0 : r.lane)};
    } else if (auto *iv = dyn_cast<InsertValueInst>(v)) {
      auto [first, count] = leafRange(iv->getType(), iv->getIndices(), iv);
      const Value *ins = iv->getInsertedValueOperand();
      if (r.lane >= int(first) && r.lane < int(first + count))
        r = {ins, isComposite(ins->getType()) ? r.lane - int(first) : -1};
      else
        r = {iv->getAggregateOperand(), r.lane};
    } else {
      return r;
    }
  }
  return std::nullopt;
}

struct Reader {
  const Instruction *u;
  unsigned operand;
  int lane;
};

// Every alias of the rail minted at `origin`, and every instruction that reads it (not an alias).
void aliasesOf(LaneRef origin, SmallVectorImpl<LaneRef> &aliases, SmallVectorImpl<Reader> &readers) {
  aliases.push_back(origin);
  for (size_t w = 0; w < aliases.size(); ++w) {
    LaneRef a = aliases[w];
    auto add = [&](LaneRef r) {
      if (llvm::find(aliases, r) == aliases.end())
        aliases.push_back(r);
    };
    for (const Use &use : a.v->uses()) {
      auto *u = dyn_cast<Instruction>(use.getUser());
      if (!u) {
        readers.push_back({nullptr, 0, a.lane});
        continue;
      }
      unsigned k = use.getOperandNo();
      if (auto *ee = dyn_cast<ExtractElementInst>(u); ee && k == 0) {
        auto i = constLane(ee->getIndexOperand());
        if (!i)
          readers.push_back({u, k, a.lane});
        else if (int(*i) == a.lane)
          add({u, -1});
        continue;
      }
      if (auto *ie = dyn_cast<InsertElementInst>(u); ie && k < 2) {
        auto i = constLane(ie->getOperand(2));
        if (!i)
          readers.push_back({u, k, a.lane});
        else if (k == 1)
          add({u, int(*i)});
        else if (int(*i) != a.lane)
          add({u, a.lane});
        continue;
      }
      if (auto *sv = dyn_cast<ShuffleVectorInst>(u); sv && k < 2) {
        int n = int(cast<FixedVectorType>(sv->getOperand(0)->getType())->getNumElements());
        ArrayRef<int> mask = sv->getShuffleMask();
        for (unsigned r = 0; r < mask.size(); ++r)
          if (mask[r] == a.lane + (k == 1 ? n : 0))
            add({u, int(r)});
        continue;
      }
      if (isa<FreezeInst>(u)) {
        add({u, a.lane});
        continue;
      }
      if (auto *ev = dyn_cast<ExtractValueInst>(u)) {
        auto [first, count] = leafRange(ev->getAggregateOperand()->getType(), ev->getIndices(), ev);
        if (a.lane >= int(first) && a.lane < int(first + count))
          add({u, isComposite(u->getType()) ? a.lane - int(first) : -1});
        continue;
      }
      if (auto *iv = dyn_cast<InsertValueInst>(u)) {
        auto [first, count] = leafRange(iv->getType(), iv->getIndices(), iv);
        if (k == 1)
          add({u, int(first) + (a.lane < 0 ? 0 : a.lane)});
        else if (!(a.lane >= int(first) && a.lane < int(first + count)))
          add({u, a.lane});
        continue;
      }
      readers.push_back({u, k, a.lane});
    }
  }
}

// Does lane `r` of an original value depend on a rail held by one of `aliases` (spine's reads(), per lane)?
bool laneReads(LoweringContext &ctx, LaneRef r, ArrayRef<LaneRef> aliases, unsigned depth = 0) {
  if (llvm::find(aliases, r) != aliases.end())
    return true;
  auto *I = dyn_cast<Instruction>(r.v);
  if (!I || depth > 64 || isa<Constant>(r.v))
    return false;
  {
    // Only quantum values carry the dependency (as in the spine): a classical value is a constant here.
    bool any = false;
    for (const Operand &o : ctx.fields(r.v))
      any |= o.handle;
    if (!any)
      return false;
  }
  if (auto *ee = dyn_cast<ExtractElementInst>(I)) {
    auto i = constLane(ee->getIndexOperand());
    if (i)
      return laneReads(ctx, {ee->getVectorOperand(), int(*i)}, aliases, depth + 1);
  } else if (auto *ie = dyn_cast<InsertElementInst>(I); ie && r.lane >= 0) {
    auto i = constLane(ie->getOperand(2));
    if (i)
      return int(*i) == r.lane ? laneReads(ctx, {ie->getOperand(1), -1}, aliases, depth + 1)
                               : laneReads(ctx, {ie->getOperand(0), r.lane}, aliases, depth + 1);
  } else if (auto *sv = dyn_cast<ShuffleVectorInst>(I); sv && r.lane >= 0) {
    int m = sv->getMaskValue(unsigned(r.lane));
    int n = int(cast<FixedVectorType>(sv->getOperand(0)->getType())->getNumElements());
    if (m < 0)
      return false;
    return laneReads(ctx, m < n ? LaneRef{sv->getOperand(0), m} : LaneRef{sv->getOperand(1), m - n}, aliases,
                     depth + 1);
  } else if (auto *ev = dyn_cast<ExtractValueInst>(I)) {
    auto [first, count] = leafRange(ev->getAggregateOperand()->getType(), ev->getIndices(), ev);
    (void)count;
    return laneReads(ctx, {ev->getAggregateOperand(), int(first) + (r.lane < 0 ? 0 : r.lane)}, aliases, depth + 1);
  } else if (auto *iv = dyn_cast<InsertValueInst>(I); iv && r.lane >= 0) {
    auto [first, count] = leafRange(iv->getType(), iv->getIndices(), iv);
    const Value *ins = iv->getInsertedValueOperand();
    if (r.lane >= int(first) && r.lane < int(first + count))
      return laneReads(ctx, {ins, isComposite(ins->getType()) ? r.lane - int(first) : -1}, aliases, depth + 1);
    return laneReads(ctx, {iv->getAggregateOperand(), r.lane}, aliases, depth + 1);
  } else if (elementWise(I) && I->getType()->isVectorTy() && r.lane >= 0) {
    for (const Use &u : I->operands())
      if (laneReads(ctx, {u.get(), u->getType()->isVectorTy() ? r.lane : -1}, aliases, depth + 1))
        return true;
    return false;
  }
  for (const Use &u : I->operands()) {
    Value *op = u.get();
    if (isa<BasicBlock>(op) || isa<Constant>(op) || isa<MetadataAsValue>(op) || op->getType()->isPointerTy())
      continue;   // an address is no data dependency of a lane here (memory is not followed)
    if (isComposite(op->getType())) {
      for (unsigned m = 0, nl = leafCount(op->getType(), op); m < nl; ++m)
        if (laneReads(ctx, {op, int(m)}, aliases, depth + 1))
          return true;
    } else if (laneReads(ctx, {op, -1}, aliases, depth + 1)) {
      return true;
    }
  }
  return false;
}

// Rule 6 after the template of lane l of I (operand lanes ops, result rail yp).
void laneRuleSix(LoweringContext &ctx, Instruction &I, unsigned l, ArrayRef<Operand> ops, Value *yp,
                 LaneDemand &dem) {
  abi::TemplateSpec inv;
  unsigned candidates;
  if (auto *bo = dyn_cast<BinaryOperator>(&I); bo && bo->getType()->isIntOrIntVectorTy()) {
    auto opc = bo->getOpcode();
    if (opc == Instruction::Add || opc == Instruction::Sub || opc == Instruction::Xor)
      candidates = 2;
    else if (opc == Instruction::Mul)
      candidates = 2;
    else
      return;
  } else if (auto *un = dyn_cast<UnaryOperator>(&I); un && un->getOpcode() == Instruction::FNeg) {
    candidates = 1;
  } else {
    return;
  }
  if (candidates == 2 && ops[0].handle && ops[1].handle && ops[0].v == ops[1].v)
    return;   // the same rail in both slots
  inv.w = laneRail(I.getType()->getScalarType(), &I);
  for (unsigned i = 0; i < candidates; ++i) {
    if (!ops[i].handle)
      continue;
    Value *h = ops[i].v;
    Operand z = candidates == 2 ? ops[1 - i] : Operand{nullptr, false};
    SmallVector<Operand, 3> invOps;
    if (auto *bo = dyn_cast<BinaryOperator>(&I)) {
      switch (bo->getOpcode()) {
      case Instruction::Add: inv.op = "sub"; invOps = {Operand{yp, true}, z}; break;
      case Instruction::Xor: inv.op = "xor"; invOps = {Operand{yp, true}, z}; break;
      case Instruction::Sub:
        if (i == 0) { inv.op = "add"; invOps = {Operand{yp, true}, z}; }
        else { inv.op = "sub"; invOps = {z, Operand{yp, true}}; }
        break;
      default: {   // mul: by an odd literal lane only
        auto *k = dyn_cast<ConstantInt>(z.v);
        if (z.handle || !k || !k->getValue()[0])
          continue;
        APInt x(k->getBitWidth(), 1);
        for (int it = 0; it < 7; ++it)   // Newton: x <- x (2 - k x), doubling the correct bits
          x = x * (APInt(k->getBitWidth(), 2) - k->getValue() * x);
        inv.op = "mul";
        invOps = {Operand{yp, true}, Operand{ConstantInt::get(k->getType(), x), false}};
        break;
      }
      }
    } else {
      inv.op = "fneg";
      invOps = {Operand{yp, true}};
    }
    // Cleanable: the rail was minted by an instruction of this function into a rail of its own.
    std::optional<LaneRef> org = originOf({I.getOperand(i), int(l)});
    if (!org)
      continue;
    auto *P = dyn_cast<Instruction>(org->v);
    if (!P || isa<LoadInst>(P) || isa<PHINode>(P))
      continue;
    if (auto *sel = dyn_cast<SelectInst>(P); sel) {
      if (P->getType()->isVectorTy())
        continue;
      bool qc = false;
      for (const Operand &o : ctx.fields(sel->getCondition()))
        qc |= o.handle;
      if (!qc)
        continue;
    }
    {
      SmallVector<Operand, 4> pf = ctx.fields(P);
      Operand at = org->lane < 0 ? (pf.size() == 1 ? pf[0] : Operand{nullptr, false})
                                 : (unsigned(org->lane) < pf.size() ? pf[unsigned(org->lane)] : Operand{nullptr, false});
      if (!at.handle || at.v != h || isa<SelectInst>(h) || isa<PHINode>(h))
        continue;   // a classical merge over handles aliases its arms (cq-oa67)
      // A field of a clone call's composite result (an extractvalue of the lowered call, U2; musl cacosf's
      // fneg of casinf's <2 x float>): the call's result rails are undone together by its twin (rule 18,
      // 166), never one of them by rule 6, as in the scalar clean-up (spine cleanable).
      if (isa<ExtractValueInst>(h))
        continue;
    }
    // Dead after the update.
    SmallVector<LaneRef, 8> aliases;
    SmallVector<Reader, 8> readers;
    aliasesOf(*org, aliases, readers);
    std::optional<DominatorTree> ownDT;
    DominatorTree &DT = spine::dtOrOwn(spine::shared(ctx), *I.getFunction(), ownDT);
    bool dead = true;
    for (const Reader &rd : readers) {
      if (rd.u == &I) {
        if (rd.operand == i && rd.lane == int(l))
          continue;
        if (rd.lane >= 0 && rd.lane < int(l) && I.getOperand(rd.operand)->getType()->isVectorTy())
          continue;   // an earlier lane of this instruction
        dead = false;
        break;
      }
      if (!rd.u || isa<StoreInst>(rd.u) || isa<ReturnInst>(rd.u) || isa<CallBase>(rd.u) || isa<PHINode>(rd.u)) {
        dead = false;
        break;
      }
      if (rd.lane >= 0 && elementWise(rd.u) && rd.u->getType()->isVectorTy() && !dem.demanded(rd.u, unsigned(rd.lane)))
        continue;   // a lane with no template reads nothing (rule 3)
      if (!DT.dominates(rd.u, &I)) {
        dead = false;
        break;
      }
    }
    if (!dead)
      continue;
    // cq-z6bul: an earlier update already cleans this rail from its own image (spine's rule 6 at a scalar
    // y' = y + k whose clean-up point is after this lane's reader); the rail has one clean-up.
    if (ctx.unc().hasCleanup(ctx.unc().idOf(h)))
      continue;
    if (z.v && candidates == 2) {
      int zl = I.getOperand(1 - i)->getType()->isVectorTy() ? int(l) : -1;
      if (laneReads(ctx, {I.getOperand(1 - i), zl}, aliases))
        continue;
    }
    // Shapes as for the scalar clean-up: both rails "", a rail first "hl", else a commutative op swaps.
    if (invOps.size() == 2) {
      if (invOps[0].handle && invOps[1].handle) {
        inv.shape = "";
      } else if (invOps[0].handle) {
        inv.shape = "hl";
      } else if (inv.op == "add" || inv.op == "xor" || inv.op == "mul") {
        std::swap(invOps[0], invOps[1]);
        inv.shape = "hl";
      } else {
        inv.shape = "lh";
      }
    }
    ctx.unc().cleanupBijective(ctx.unc().idOf(h), inv, invOps);
    return;
  }
}

// A bitcast that regroups bits across lanes (<2 x i32> to i64, i64 to <2 x i32>, <4 x i8> to <2 x i16>):
// rule 3 makes it a representation change of the bits, and x86-64 is little-endian (lane 0 holds the
// low bits). Each result lane is assembled from the bit pieces of the source lanes it covers: a
// classical piece by classical instructions, a quantum one by rule 4 templates into fresh rails (lshr,
// trunc to the piece, zext and shl to its place, or of the pieces; an fp lane passes through the
// bitcast template to and from the integer of its width). The intermediate rails are rule 5 garbage.
void lowerRegroupingBitcast(LoweringContext &ctx, CastInst &I) {
  LLVMContext &C = ctx.M.getContext();
  IRBuilder<> &B = ctx.B();
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *srcT = I.getSrcTy(), *dstT = I.getDestTy();
  Type *se = srcT->getScalarType(), *de = dstT->getScalarType();
  unsigned a = unsigned(DL.getTypeSizeInBits(se).getFixedValue());
  unsigned b = unsigned(DL.getTypeSizeInBits(de).getFixedValue());
  if (se->isVectorTy() || de->isVectorTy() || DL.getTypeSizeInBits(srcT) != DL.getTypeSizeInBits(dstT))
    internalError("aggr: a bitcast between types of different sizes", &I);
  SmallVector<Operand, 4> src;
  if (srcT->isVectorTy())
    src = leaves(ctx, I.getOperand(0));
  else
    src.push_back(ctx.operand(I.getOperand(0)));
  unsigned m = dstT->isVectorTy() ? cast<FixedVectorType>(dstT)->getNumElements() : 1;
  IntegerType *ia = IntegerType::get(C, a), *ib = IntegerType::get(C, b);
  auto tmpl = [&](StringRef op, RailType w, std::optional<RailType> to, StringRef shape,
                  ArrayRef<Operand> ops) -> Value * {
    abi::TemplateSpec spec;
    spec.op = op.str();
    spec.w = w;
    spec.to = to;
    spec.shape = shape.str();
    return ctx.emitTemplate(spec, ops);
  };
  RailType ra{Kind::Int, a}, rb{Kind::Int, b};
  // The source lanes as integers of a bits.
  SmallVector<Operand, 4> ints;
  for (const Operand &o : src) {
    if (se->isIntegerTy()) {
      ints.push_back(o);
    } else if (o.handle) {
      ints.push_back(Operand{tmpl("bitcast", laneRail(se, &I), ra, "", {o}), true});
    } else {
      ints.push_back(Operand{B.CreateBitCast(o.v, ia), false});
    }
  }
  SmallVector<Operand, 4> out;
  for (unsigned j = 0; j < m; ++j) {
    unsigned lo = j * b, hi = lo + b;
    Value *qacc = nullptr;        // the quantum pieces, or'ed
    Value *cacc = ConstantInt::get(ib, 0);   // the classical pieces
    for (unsigned i = lo / a; i * a < hi; ++i) {
      unsigned plo = std::max(lo, i * a), phi = std::min(hi, (i + 1) * a);
      unsigned off = plo - i * a, wdt = phi - plo, shift = plo - lo;
      const Operand &x = ints[i];
      if (!x.handle) {
        Value *v = x.v;
        if (off)
          v = B.CreateLShr(v, off);
        v = B.CreateZExtOrTrunc(B.CreateZExtOrTrunc(v, IntegerType::get(C, wdt)), ib);
        if (shift)
          v = B.CreateShl(v, shift);
        cacc = B.CreateOr(cacc, v);
        continue;
      }
      RailType rw{Kind::Int, wdt};
      Operand v = x;
      if (off)
        v = Operand{tmpl("lshr", ra, std::nullopt, "hl", {v, Operand{ConstantInt::get(ia, off), false}}), true};
      if (wdt < a)
        v = Operand{tmpl("trunc", ra, rw, "", {v}), true};
      if (wdt < b)
        v = Operand{tmpl("zext", rw, rb, "", {v}), true};   // else wdt == b: v already has b bits
      if (shift)
        v = Operand{tmpl("shl", rb, std::nullopt, "hl", {v, Operand{ConstantInt::get(ib, shift), false}}), true};
      qacc = qacc ? tmpl("or", rb, std::nullopt, "", {Operand{qacc, true}, v}) : v.v;
    }
    Operand lane;
    if (!qacc) {
      lane = Operand{cacc, false};
      if (!de->isIntegerTy())
        lane.v = B.CreateBitCast(lane.v, de);
    } else {
      auto *k = dyn_cast<ConstantInt>(cacc);
      if (!k || !k->isZero())
        qacc = tmpl("or", rb, std::nullopt, "hl", {Operand{qacc, true}, Operand{cacc, false}});
      lane = Operand{qacc, true};
      if (!de->isIntegerTy())
        lane = Operand{tmpl("bitcast", rb, laneRail(de, &I), "", {lane}), true};
    }
    out.push_back(lane);
  }
  if (dstT->isVectorTy()) {
    bindResult(ctx, &I, out);
  } else {
    ctx.bindFields(&I, {out[0]});
  }
}

void lowerElementWise(LoweringContext &ctx, Instruction &I) {
  if (auto *ci = dyn_cast<CastInst>(&I)) {
    auto *st = dyn_cast<FixedVectorType>(ci->getSrcTy());
    auto *dt = dyn_cast<FixedVectorType>(ci->getDestTy());
    if (!st || !dt || st->getNumElements() != dt->getNumElements()) {
      if (ci->getOpcode() != Instruction::BitCast)
        internalError("aggr: a cast other than bitcast that changes the lane count", &I);
      return lowerRegroupingBitcast(ctx, *ci);
    }
  }
  auto *vt = dyn_cast<FixedVectorType>(I.getType());
  if (!vt)
    internalError("aggr: an element-wise instruction with a vector operand and a scalar result that is not a "
                  "bitcast",
                  &I);
  unsigned n = vt->getNumElements();
  SmallVector<SmallVector<Operand, 4>, 3> opLanes;
  for (const Use &u : I.operands()) {
    Value *v = u.get();
    if (v->getType()->isVectorTy()) {
      opLanes.push_back(leaves(ctx, v));
    } else {
      // A scalar operand of a vector instruction (a select's i1 condition): the same for every lane.
      Operand o = ctx.operand(v);
      opLanes.push_back(SmallVector<Operand, 4>(n, o));
    }
  }
  LaneDemand dem;   // over the original IR, which is not mutated while it is lowered
  SmallVector<Operand, 4> out;
  for (unsigned l = 0; l < n; ++l) {
    SmallVector<Operand, 3> ops;
    bool anyQ = false;
    for (auto &lanes : opLanes) {
      ops.push_back(lanes[l]);
      anyQ |= lanes[l].handle;
    }
    if (!anyQ) {
      SmallVector<Value *, 3> vs;
      for (const Operand &o : ops)
        vs.push_back(o.v);
      out.push_back(Operand{classicalLane(ctx, I, vs), false});
      continue;
    }
    if (!dem.demanded(&I, l)) {
      out.push_back(Operand{PoisonValue::get(vt->getElementType()), false});   // rule 3: no template
      continue;
    }
    Operand r = quantumLane(ctx, I, ops);
    out.push_back(r);
    // cq-941o: no lane rule 6 inside a loop unit, as the spine's lowerInstruction (no ruleSixAfter): inside a rule-14
    // trip the mirror reads every old value, and a value from before the loop is read by every trip.
    if (r.handle && (ops.empty() || r.v != ops[0].v) && !ctx.loopUnit())
      laneRuleSix(ctx, I, l, ops, r.v, dem);
  }
  bindResult(ctx, &I, out);
}

// A lane index that is not a constant: lane k is chosen under idx == k, a classical compare for a
// classical index, the equality template cq_template_icmp_eq_<W>_hl into a fresh rail for a quantum one
// (rule 13's case flag on a scrutinee). An index at or beyond the lane count gives poison (LLVM): any
// value is right there.
Operand laneIsIndex(LoweringContext &ctx, Operand idx, unsigned k) {
  Constant *kc = ConstantInt::get(idx.v->getType(), k);
  if (!idx.handle)
    return Operand{ctx.B().CreateICmpEQ(idx.v, kc), false};
  abi::TemplateSpec spec;
  spec.op = "icmp";
  spec.pred = "eq";
  spec.w = railTypeOf(idx.v->getType());
  spec.shape = "hl";
  return Operand{ctx.emitTemplate(spec, {idx, Operand{kc, false}}), true};
}

// Rule 26 with rule 9: a select of a struct or array is one select per field under the scalar condition
// (selectLeaf). A classical field the two arms share stays that classical value.
void lowerCompositeSelect(LoweringContext &ctx, SelectInst &sel) {
  if (sel.getCondition()->getType()->isVectorTy())
    internalError("aggr: a select of an aggregate with a vector condition", &sel);
  Operand c = ctx.operand(sel.getCondition());
  SmallVector<Operand, 4> t = leaves(ctx, sel.getTrueValue()), f = leaves(ctx, sel.getFalseValue());
  SmallVector<unsigned, 4> pt = fieldsPerLeaf(ctx, sel.getTrueValue()), pf = fieldsPerLeaf(ctx, sel.getFalseValue());
  if (t.size() != f.size() || pt != pf)
    internalError("aggr: the arms of an aggregate select have different fields", &sel);
  SmallVector<Type *, 8> tys;
  leafTypes(sel.getType(), tys);
  SmallVector<Operand, 4> out;
  unsigned k = 0;
  for (unsigned l = 0; l < tys.size(); ++l)
    for (unsigned j = 0; j < pt[l]; ++j, ++k) {
      Operand a = t[k], b = f[k];
      if (!a.handle && !b.handle && (a.v == b.v || !c.handle)) {
        out.push_back(a.v == b.v ? a : Operand{ctx.B().CreateSelect(c.v, a.v, b.v), false});
        continue;
      }
      // The field's IR type: the leaf's, or for a field of a packed integer leaf (cq-0umd) the type of a
      // classical arm's field (a handle is an i32 whatever its rail's width).
      Type *ft = tys[l];
      if (pt[l] != 1) {
        if (a.handle && b.handle)
          unimplemented("aggr: a select whose two arms hold a packed integer leaf (cq-0umd) as rails: the "
                        "field widths are not recorded with the field counts",
                        &sel);
        ft = (a.handle ? b : a).v->getType();
      }
      if (ft->isPointerTy())
        unimplemented("aggr: a pointer field of a select that chooses between two pointers on a rail (rule 21's "
                      "pointer merge of a field)",
                      &sel);
      out.push_back(selectLeaf(ctx, c, a, b, railTypeOf(ft), &sel));
    }
  setFieldsPerLeaf(ctx, &sel, pt);
  bindResult(ctx, &sel, out);
}

} // namespace

void lowerExtractValue(LoweringContext &ctx, ExtractValueInst &I) {
  const Value *agg = I.getAggregateOperand();
  SmallVector<Operand, 4> all = leaves(ctx, agg);
  SmallVector<unsigned, 4> per = fieldsPerLeaf(ctx, agg);
  auto [first, count] = leafRange(agg->getType(), I.getIndices(), &I);
  if (first + count > per.size())
    internalError("aggr: extractvalue past the aggregate's leaves", &I);
  unsigned f0 = sumOf(per, 0, first), fn = sumOf(per, first, first + count);
  if (f0 + fn > all.size())
    internalError("aggr: extractvalue past the aggregate's fields", &I);
  ArrayRef<Operand> slice = ArrayRef<Operand>(all).slice(f0, fn);
  if (!isComposite(I.getType()) && fn > 1) {
    // A packed integer leaf (166): bound to its fields; spine reads them at the unpacking (Views.cpp).
    ctx.bindFields(&I, slice);
    return;
  }
  setFieldsPerLeaf(ctx, &I, ArrayRef<unsigned>(per).slice(first, count));
  bindResult(ctx, &I, slice);
}

void lowerInsertValue(LoweringContext &ctx, InsertValueInst &I) {
  const Value *agg = I.getAggregateOperand(), *insV = I.getInsertedValueOperand();
  SmallVector<Operand, 4> all = leaves(ctx, agg);
  SmallVector<unsigned, 4> per = fieldsPerLeaf(ctx, agg);
  SmallVector<unsigned, 4> insPer = fieldsPerLeaf(ctx, insV);
  SmallVector<Operand, 4> ins = isComposite(insV->getType()) || isa<Constant>(insV) ? leaves(ctx, insV)
                                                                                     : ctx.fields(insV);
  if (!isComposite(insV->getType()) && !isa<Constant>(insV) && ins.size() != insPer.front())
    internalError("aggr: insertvalue of a scalar bound to another field count", &I);
  auto [first, count] = leafRange(agg->getType(), I.getIndices(), &I);
  if (count != insPer.size() || first + count > per.size() || sumOf(insPer, 0, count) != ins.size())
    internalError("aggr: insertvalue leaf count mismatch", &I);
  unsigned f0 = sumOf(per, 0, first), fn = sumOf(per, first, first + count);
  if (f0 + fn > all.size())
    internalError("aggr: insertvalue past the aggregate's fields", &I);
  SmallVector<Operand, 4> out(all.begin(), all.begin() + f0);
  out.append(ins.begin(), ins.end());
  out.append(all.begin() + f0 + fn, all.end());
  for (unsigned i = 0; i < count; ++i)
    per[first + i] = insPer[i];
  setFieldsPerLeaf(ctx, &I, per);
  bindResult(ctx, &I, out);
}

void bindLeafFields(LoweringContext &ctx, const Value *orig, ArrayRef<Operand> fields, ArrayRef<unsigned> perLeaf) {
  if (perLeaf.size() != leafCount(orig->getType(), orig) || sumOf(perLeaf, 0, unsigned(perLeaf.size())) != fields.size())
    internalError("aggr: bindLeafFields with field counts that are not the value's leaves", orig);
  setFieldsPerLeaf(ctx, orig, perLeaf);
  bindResult(ctx, orig, fields);
}

void lowerVectorOp(LoweringContext &ctx, Instruction &I) {
  if (auto *ee = dyn_cast<ExtractElementInst>(&I); ee && !isa<ConstantInt>(ee->getIndexOperand())) {
    // Rule 9 over the lanes: a select chain under idx == k, the last lane innermost.
    SmallVector<Operand, 4> lanes = leaves(ctx, ee->getVectorOperand());
    Operand idx = ctx.operand(ee->getIndexOperand());
    RailType w = laneRail(I.getType(), &I);
    Operand r = lanes.back();
    for (unsigned k = unsigned(lanes.size()) - 1; k-- > 0;)
      r = selectLeaf(ctx, laneIsIndex(ctx, idx, k), lanes[k], r, w, &I);
    bindResult(ctx, &I, {r});
    return;
  }
  if (auto *ie = dyn_cast<InsertElementInst>(&I); ie && !isa<ConstantInt>(ie->getOperand(2))) {
    // Each lane k becomes the inserted value under idx == k, its old value otherwise (rule 9).
    SmallVector<Operand, 4> lanes = leaves(ctx, ie->getOperand(0));
    Operand idx = ctx.operand(ie->getOperand(2));
    Operand v = ctx.operand(ie->getOperand(1));
    RailType w = laneRail(ie->getOperand(1)->getType(), &I);
    for (unsigned k = 0; k < lanes.size(); ++k)
      lanes[k] = selectLeaf(ctx, laneIsIndex(ctx, idx, k), v, lanes[k], w, &I);
    bindResult(ctx, &I, lanes);
    return;
  }
  if (auto *ee = dyn_cast<ExtractElementInst>(&I)) {
    unsigned l = unsigned(cast<ConstantInt>(ee->getIndexOperand())->getZExtValue());
    SmallVector<Operand, 4> lanes = leaves(ctx, ee->getVectorOperand());
    if (l >= lanes.size()) {   // LLVM: poison
      bindResult(ctx, &I, {Operand{PoisonValue::get(I.getType()), false}});
      return;
    }
    bindResult(ctx, &I, {lanes[l]});
    return;
  }
  if (auto *ie = dyn_cast<InsertElementInst>(&I)) {
    unsigned l = unsigned(cast<ConstantInt>(ie->getOperand(2))->getZExtValue());
    SmallVector<Operand, 4> lanes = leaves(ctx, ie->getOperand(0));
    if (l >= lanes.size()) {   // LLVM: poison
      SmallVector<Operand, 4> p;
      constantLeaves(PoisonValue::get(I.getType()), p, &I);
      bindResult(ctx, &I, p);
      return;
    }
    lanes[l] = ctx.operand(ie->getOperand(1));
    bindResult(ctx, &I, lanes);
    return;
  }
  if (auto *sv = dyn_cast<ShuffleVectorInst>(&I)) {
    SmallVector<Operand, 4> src = leaves(ctx, sv->getOperand(0));
    SmallVector<Operand, 4> b = leaves(ctx, sv->getOperand(1));
    src.append(b.begin(), b.end());
    Type *et = cast<VectorType>(I.getType())->getElementType();
    SmallVector<Operand, 4> out;
    for (int m : sv->getShuffleMask()) {
      if (m < 0 || unsigned(m) >= src.size())
        out.push_back(Operand{PoisonValue::get(et), false});
      else
        out.push_back(src[unsigned(m)]);
    }
    bindResult(ctx, &I, out);
    return;
  }
  if (isa<ExtractValueInst>(I))
    return lowerExtractValue(ctx, cast<ExtractValueInst>(I));
  if (isa<InsertValueInst>(I))
    return lowerInsertValue(ctx, cast<InsertValueInst>(I));
  if (auto *sel = dyn_cast<SelectInst>(&I); sel && !I.getType()->isVectorTy())
    return lowerCompositeSelect(ctx, *sel);
  if (elementWise(&I))
    return lowerElementWise(ctx, I);
  internalError("aggr: lowerVectorOp of an instruction with no vector or aggregate construction", &I);
}

SmallVector<Operand, 4> flattenResult(LoweringContext &ctx, const Value *v) { return leaves(ctx, v); }
SmallVector<unsigned, 4> leafFieldCounts(LoweringContext &ctx, const Value *v) { return fieldsPerLeaf(ctx, v); }

} // namespace cq::aggr
