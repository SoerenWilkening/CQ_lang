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

#include <optional>

#include "cq/Abi.h"
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
    unimplemented("aggr: a scalable vector", at);
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

// The fields of an original value as leaves.
SmallVector<Operand, 4> leaves(LoweringContext &ctx, const Value *v) {
  SmallVector<Operand, 4> out;
  if (auto *c = dyn_cast<Constant>(v)) {
    constantLeaves(const_cast<Constant *>(c), out, v);
    return out;
  }
  unsigned n = leafCount(v->getType(), v);
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

// A composite with a rail among its leaves is bound field-wise. One with only classical leaves is
// bound as one classical value of its type: taint is lane-precise, so such a value may be classical
// and its users copied classically, which read it with operand() (one field).
void bindResult(LoweringContext &ctx, const Value *orig, ArrayRef<Operand> ops) {
  if (ops.empty())
    unimplemented("aggr: a value with no scalar leaves (an empty struct or array)", orig);
  Type *t = orig->getType();
  bool anyRail = false;
  for (const Operand &o : ops)
    anyRail |= o.handle;
  if (!anyRail && isComposite(t)) {
    unsigned k = 0;
    Value *v = materialize(ctx.B(), t, ops, k);
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
    unimplemented("aggr: a vector lane of IR type that is not iN/half/bfloat/float/double/x86_fp80", at);
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

// A lane with at least one quantum operand: the rule 4 template of the scalar opcode.
Operand quantumLane(LoweringContext &ctx, Instruction &I, SmallVector<Operand, 3> ops) {
  abi::TemplateSpec spec;
  if (auto *bo = dyn_cast<BinaryOperator>(&I)) {
    const char *op = binName(bo->getOpcode());
    if (!op)
      unimplemented("aggr: a vector binary opcode with no template", &I);
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
      unimplemented("aggr: a vector unary opcode with no template", &I);
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
      unimplemented("aggr: a vector pointer cast with a quantum lane", &I);
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
  unimplemented("aggr: a vector select with a quantum lane", &I);
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
    if (auto *ft = dyn_cast<FixedVectorType>(op->getType())) {
      for (unsigned m = 0; m < ft->getNumElements(); ++m)
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
    if (isa<ExtractValueInst>(P) || isa<InsertValueInst>(P))
      unimplemented("aggr: rule 6 on a vector lane whose rail is an aggregate field (alias through a struct)", &I);
    {
      SmallVector<Operand, 4> pf = ctx.fields(P);
      Operand at = org->lane < 0 ? (pf.size() == 1 ? pf[0] : Operand{nullptr, false})
                                 : (unsigned(org->lane) < pf.size() ? pf[unsigned(org->lane)] : Operand{nullptr, false});
      if (!at.handle || at.v != h)
        continue;
    }
    // Dead after the update.
    SmallVector<LaneRef, 8> aliases;
    SmallVector<Reader, 8> readers;
    aliasesOf(*org, aliases, readers);
    DominatorTree DT(*I.getFunction());
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

void lowerElementWise(LoweringContext &ctx, Instruction &I) {
  auto *vt = dyn_cast<FixedVectorType>(I.getType());
  if (!vt)
    unimplemented("aggr: an element-wise instruction with a vector operand and a non-vector result", &I);
  if (auto *ci = dyn_cast<CastInst>(&I)) {
    auto *st = dyn_cast<FixedVectorType>(ci->getSrcTy());
    if (!st || st->getNumElements() != vt->getNumElements())
      unimplemented("aggr: a vector cast that changes the lane count", &I);
  }
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
    if (r.handle && (ops.empty() || r.v != ops[0].v))
      laneRuleSix(ctx, I, l, ops, r.v, dem);
  }
  bindResult(ctx, &I, out);
}

unsigned constIndex(const Value *idx, const Instruction &I) {
  auto *ci = dyn_cast<ConstantInt>(idx);
  if (!ci)
    unimplemented("aggr: a vector lane index that is not a constant", &I);
  return unsigned(ci->getZExtValue());
}

} // namespace

void lowerExtractValue(LoweringContext &ctx, ExtractValueInst &I) {
  SmallVector<Operand, 4> all = leaves(ctx, I.getAggregateOperand());
  auto [first, count] = leafRange(I.getAggregateOperand()->getType(), I.getIndices(), &I);
  if (first + count > all.size())
    internalError("aggr: extractvalue past the aggregate's leaves", &I);
  bindResult(ctx, &I, ArrayRef<Operand>(all).slice(first, count));
}

void lowerInsertValue(LoweringContext &ctx, InsertValueInst &I) {
  SmallVector<Operand, 4> all = leaves(ctx, I.getAggregateOperand());
  SmallVector<Operand, 4> ins = leaves(ctx, I.getInsertedValueOperand());
  auto [first, count] = leafRange(I.getAggregateOperand()->getType(), I.getIndices(), &I);
  if (count != ins.size() || first + count > all.size())
    internalError("aggr: insertvalue leaf count mismatch", &I);
  for (unsigned i = 0; i < count; ++i)
    all[first + i] = ins[i];
  bindResult(ctx, &I, all);
}

void lowerVectorOp(LoweringContext &ctx, Instruction &I) {
  if (auto *ee = dyn_cast<ExtractElementInst>(&I)) {
    unsigned l = constIndex(ee->getIndexOperand(), I);
    SmallVector<Operand, 4> lanes = leaves(ctx, ee->getVectorOperand());
    if (l >= lanes.size()) {   // LLVM: poison
      bindResult(ctx, &I, {Operand{PoisonValue::get(I.getType()), false}});
      return;
    }
    bindResult(ctx, &I, {lanes[l]});
    return;
  }
  if (auto *ie = dyn_cast<InsertElementInst>(&I)) {
    unsigned l = constIndex(ie->getOperand(2), I);
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
  if (elementWise(&I))
    return lowerElementWise(ctx, I);
  unimplemented("aggr: a vector instruction with no lane construction", &I);
}

SmallVector<Operand, 4> flattenResult(LoweringContext &ctx, const Value *v) { return leaves(ctx, v); }

} // namespace cq::aggr
