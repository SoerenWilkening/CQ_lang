// Module rot-cry (cq-w1-rot-cry): controlled Ry and state preparation, CR rule 10.
//
//   "A phi of cq_theta(v, θ) against v (or two thetas of one seed) is ry_<W>_controlled(flag, rail)
//    on a rail seeded with v; r = c; before the prep adds xorc_<W>_controlled; a second prep of a
//    rail nothing read in between undoes the first by its adjoint under the conjunction flag. The
//    rotated rail is frozen (never reverse-played). A flag that read the rotated register stays
//    allocated."  Witnesses: 39, 66, 120, 125, 133, 141.
//
// One construction, the REGISTER. A cq_theta under a quantum predicate (the spine calls
// lowerControlledTheta with the flag of the current block's quantum part) never mints a register of
// its own for the merge to copy: a select merge of a rotated rail would copy a label of an Ry
// superposition (125). Instead every cq_theta that reaches a merge, and the merge, name one rail:
//
//  - In place. cq_theta of a rail x (66, 113's CRy on q2): ry_<W>_controlled(flag, x, θ). Rule 2's
//    "on an existing handle it rotates that rail in place" under the flag. Nothing to reset.
//  - Prep of a classical value v. The register is found through the merge phis the theta reaches
//    (directly, or through a phi already bound to a register: 133 prep_twice's second if). A new
//    register is allocated at the prep with its STRAIGHT-THROUGH value s: the phi's classical
//    incoming (39: r0; 133: 7), or v when every incoming is a prep (39 _ifelse). Where the arm runs,
//    the rail is taken from s to v by xorc_<W>_controlled(flag, r, s ^ v) (133: "r = 0;", s ^ 0 = s;
//    none when v is s), then ry_<W>_controlled(flag, r, θ).
//  - Two thetas of one seed (140): a prep whose result nothing reads shares the rail of an earlier
//    such prep of the same classical value when their predicates are disjoint (only one of them runs
//    on any basis branch, so the shared rail is exactly the C variable on every branch).
//  - A second prep of a register (133 prep_twice). The register holds s except where an ACTIVE prep
//    i fired (its effective predicate e_i). Before the new prep under p, every active prep with
//    e_i & p not false is undone in reverse order under the conjunction flag of e_i & p: its adjoint
//    ry_controlled(g, r, -θ_i) then its reset xorc_controlled(g, r, lit_i). That is sound only when
//    nothing read the rail since prep i (rule 10); a reader in between is unimplemented. e_i becomes
//    e_i & !p, and the new prep is active under p.
//
// Roles and uncompute (A2, A4). The register's alloc is recordSeed, each xorc is recordCore (an
// involution on the register, never replayed because the register is kept), each Ry is
// noteNonDiagonal: a garbage rail that read the register before the rotation (66's flag, which read
// x) becomes KeptEntangled there, which is rule 10's "a flag that read the rotated register stays
// allocated". The rotated rail is Role::Frozen. An in-place target is never one of its own controls
// (CR §1.3): when the flag IS the target rail (`if (q) cq_theta(&q, a)` on a bool), the flag is
// first copied into a fresh rail (alloc 0, xor_i1), which then stays allocated by the same A4 rule.
//
// lowerStatePrepMerge binds the merge phi to its register's rail after checking every incoming:
// a prep or phi of the register, the register's own handle, or its straight-through value on an
// edge where no active prep fired. No gate is emitted at the merge (39: "no merge copy").
//
// Shapes not built yet are cq::unimplemented with the instruction: a prep whose register would be
// allocated under a classical guard (P1 factor) and merged or shared outside it; a phi merging a
// prep with a quantum value that is not its register; several distinct straight-through values; a
// second prep after a reader or after an in-place rotation of the register.
#include "cq/Rotation.h"

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::rot {

namespace {

struct Prep {
  Pred eff;          // where this prep is the register's current state (quantum part)
  Value *angle;      // the classical angle, new IR
  Value *lit;        // the xorc literal it applied first, or nullptr
};

struct Register {
  Value *rail = nullptr;                 // the register's handle, new IR
  RailType w{};
  Value *seed = nullptr;                 // new-IR classical straight-through value; nullptr: in place
  bool deadShare = false;                // made by a prep nothing reads (two thetas of one seed)
  bool locked = false;                   // rotated in place: no adjoint undo across it
  std::vector<Prep> active;
  std::optional<Pred> dirty;             // cq-2xi3: where an in-place rotation left it off seed-or-active
  std::optional<Pred> all;               // union of the full block predicates of its preps
  unsigned uses = 0;                     // rail's IR use count right after our last gate on it
};

struct FnState {
  WeakVH out;
  std::unique_ptr<DominatorTree> dt;     // over the original function
  const Function *orig = nullptr;
  std::vector<std::unique_ptr<Register>> regs;
  DenseMap<const Value *, Register *> of;   // original cq_theta calls and phis -> register
};

// One state per output function under construction; a WeakVH notices a reused address.
thread_local DenseMap<const Function *, std::unique_ptr<FnState>> states;

FnState &state(LoweringContext &ctx, const Function &origF) {
  Function *out = &ctx.out();
  auto &p = states[out];
  if (!p || (Value *)p->out != out) {
    p = std::make_unique<FnState>();
    p->out = out;
  }
  if (p->orig != &origF) {
    p->orig = &origF;
    p->dt = std::make_unique<DominatorTree>(const_cast<Function &>(origF));
  }
  return *p;
}

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

// A cq_theta with a classical angle under a quantum predicate: a prep this module lowers (or will).
bool isPrep(LoweringContext &ctx, const Value *v) {
  auto *CI = dyn_cast<CallInst>(v);
  const Function *F = CI ? CI->getCalledFunction() : nullptr;
  if (!F || !F->getName().starts_with("cq_theta_") || CI->arg_size() != 2)
    return false;
  if (ctx.T.isQuantum(CI->getArgOperand(1), ctx.S))
    return false;
  return !ctx.preds().block(CI->getParent()).quantumPart(ctx.T, ctx.S).isTop();
}

bool isZero(const Value *v) {
  if (auto *C = dyn_cast<Constant>(v))
    return C->isNullValue();
  return false;
}

// The xorc literal taking the rail from s to v: s ^ v (bitwise, on the rail's bits).
Value *xorLiteral(LoweringContext &ctx, Value *s, Value *v) {
  if (s == v)
    return nullptr;
  if (isZero(v))
    return isZero(s) ? nullptr : s;
  if (isZero(s))
    return v;
  IRBuilder<> &B = ctx.B();
  Type *t = s->getType();
  if (t->isIntegerTy())
    return B.CreateXor(s, v);
  Type *it = IntegerType::get(ctx.M.getContext(), t->getPrimitiveSizeInBits());
  return B.CreateBitCast(B.CreateXor(B.CreateBitCast(s, it), B.CreateBitCast(v, it)), t);
}

void recordXorc(LoweringContext &ctx, Value *flag, Register &R, Value *lit) {
  abi::CoreSpec spec{abi::Core::Xorc, R.w, /*ctl=*/true};
  CallInst *x = ctx.emitCore(spec, {flag, R.rail, lit});
  ctx.unc().recordCore(x, spec, {Operand{flag, true}, Operand{R.rail, true}, Operand{lit, false}},
                       ctx.unc().idOf(R.rail));
}

// The flag read into a fresh i1 rail (alloc 0, xor_i1): it read the register before the rotation
// that follows, so it stays allocated (A4); kept explicitly, since the register it read may be named
// by another handle value (a cell load) than the one the rotation targets.
Value *copyFlag(LoweringContext &ctx, Value *flag) {
  abi::CoreSpec a{abi::Core::Alloc, RailType{Kind::Int, 1}};
  CallInst *f = ctx.emitCore(a, {ConstantInt::getFalse(ctx.M.getContext())});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec x{abi::Core::XorI1, RailType{Kind::Int, 1}};
  CallInst *c = ctx.emitCore(x, {flag, f});
  ctx.unc().recordCore(c, x, {Operand{flag, true}, Operand{f, true}}, fid);
  ctx.unc().setRole(fid, Role::KeptEntangled);
  return f;
}

// cq-x80e. The handle values a handle may be at run time, through merges (phi, select): the leaves.
void handleLeaves(Value *v, SmallVectorImpl<Value *> &out, SmallPtrSetImpl<Value *> &seen) {
  if (!seen.insert(v).second)
    return;
  if (auto *P = dyn_cast<PHINode>(v)) {
    for (Value *u : P->incoming_values())
      handleLeaves(u, out, seen);
    return;
  }
  if (auto *S = dyn_cast<SelectInst>(v)) {
    handleLeaves(S->getTrueValue(), out, seen);
    handleLeaves(S->getFalseValue(), out, seen);
    return;
  }
  out.push_back(v);
}

// A rail made by a gate call of this function (alloc, a core or template result) whose handle
// value, or a merge of it, never leaves the gate calls: no store, no clone call, no return. No
// other handle value (a cell load, a formal) can name it at run time.
bool confined(Value *h) {
  if (!isa<CallInst>(h))
    return false;
  SmallVector<Value *, 8> work{h};
  SmallPtrSet<Value *, 8> seen;
  while (!work.empty()) {
    Value *v = work.pop_back_val();
    if (!seen.insert(v).second)
      continue;
    for (User *U : v->users()) {
      if (isa<PHINode>(U) || isa<SelectInst>(U)) {
        work.push_back(U);
        continue;
      }
      auto *CI = dyn_cast<CallInst>(U);
      const Function *G = CI ? CI->getCalledFunction() : nullptr;
      if (G && G->getName().starts_with("cqrt_") && !G->getName().starts_with("cqrt_qram") &&
          !G->getName().starts_with("cqrt_push") && !G->getName().starts_with("cqrt_tape"))
        continue;
      if (G && G->getName().starts_with("cq_template_"))
        continue;
      return false;
    }
  }
  return true;
}

// cq-x80e. b - a as a constant, when the two integers differ by one on every run: equal values,
// constants, an add of a constant on either side, and two phis of one block whose incomings differ
// by that constant on every edge (two induction variables of one step, 59's i and i + 1; the pair is
// assumed at the constant while its incomings are checked, an induction over the loop's trips).
using PairDiff = SmallVector<std::tuple<const Value *, const Value *, int64_t>, 4>;
std::optional<int64_t> constDiff(const Value *a, const Value *b, PairDiff &assumed, unsigned depth = 0) {
  if (a == b)
    return 0;
  if (depth > 8 || a->getType() != b->getType() || !a->getType()->isIntegerTy() ||
      a->getType()->getIntegerBitWidth() > 64)
    return std::nullopt;
  auto *ca = dyn_cast<ConstantInt>(a), *cb = dyn_cast<ConstantInt>(b);
  if (ca && cb)
    return cb->getSExtValue() - ca->getSExtValue();
  for (auto &[x, y, d] : assumed)
    if (x == a && y == b)
      return d;
  auto addC = [](const Value *v, const Value *&x, int64_t &c) {
    auto *BO = dyn_cast<BinaryOperator>(v);
    if (!BO || BO->getOpcode() != Instruction::Add)
      return false;
    auto *k = dyn_cast<ConstantInt>(BO->getOperand(1));
    if (!k || k->getBitWidth() > 64)
      return false;
    x = BO->getOperand(0);
    c = k->getSExtValue();
    return true;
  };
  const Value *x;
  int64_t c;
  if (addC(a, x, c))
    if (auto d = constDiff(x, b, assumed, depth + 1))
      return *d - c;
  if (addC(b, x, c))
    if (auto d = constDiff(a, x, assumed, depth + 1))
      return *d + c;
  auto *pa = dyn_cast<PHINode>(a), *pb = dyn_cast<PHINode>(b);
  if (pa && pb && pa->getParent() == pb->getParent()) {
    // The constant from an edge that does not need the assumption, then every edge under it.
    std::optional<int64_t> d;
    for (unsigned i = 0; i < pa->getNumIncomingValues() && !d; ++i) {
      PairDiff none;
      d = constDiff(pa->getIncomingValue(i), pb->getIncomingValueForBlock(pa->getIncomingBlock(i)), none,
                    depth + 1);
    }
    if (!d)
      return std::nullopt;
    assumed.push_back({a, b, *d});
    bool ok = true;
    for (unsigned i = 0; i < pa->getNumIncomingValues() && ok; ++i) {
      std::optional<int64_t> e = constDiff(pa->getIncomingValue(i),
                                           pb->getIncomingValueForBlock(pa->getIncomingBlock(i)), assumed, depth + 1);
      ok = e && *e == *d;
    }
    assumed.pop_back();
    if (ok)
      return d;
  }
  return std::nullopt;
}

// cq-x80e. An address or a 64-bit index as base + c + sum(k * leaf), modulo 2^64 (the GEP and
// add/sub/mul/shl arithmetic is exact modulo 2^64, so a nonzero constant difference of two forms is
// two different addresses on every run). Any other value is a leaf.
struct Lin {
  const Value *base = nullptr;
  uint64_t c = 0;
  SmallVector<std::pair<const Value *, uint64_t>, 4> terms;
  void add(const Value *v, uint64_t k) {
    for (auto &[x, kx] : terms)
      if (x == v) {
        kx += k;
        return;
      }
    terms.push_back({v, k});
  }
  void addLin(const Lin &o, uint64_t k) {
    c += o.c * k;
    for (auto &[x, kx] : o.terms)
      add(x, kx * k);
  }
};

Lin intLin(const Value *v, unsigned depth = 0) {
  Lin r;
  if (auto *C = dyn_cast<ConstantInt>(v); C && C->getBitWidth() == 64) {
    r.c = C->getZExtValue();
    return r;
  }
  auto *BO = dyn_cast<BinaryOperator>(v);
  if (BO && depth < 12 && BO->getType()->isIntegerTy(64)) {
    auto *k = dyn_cast<ConstantInt>(BO->getOperand(1));
    switch (BO->getOpcode()) {
    case Instruction::Add:
      r.addLin(intLin(BO->getOperand(0), depth + 1), 1);
      r.addLin(intLin(BO->getOperand(1), depth + 1), 1);
      return r;
    case Instruction::Sub:
      r.addLin(intLin(BO->getOperand(0), depth + 1), 1);
      r.addLin(intLin(BO->getOperand(1), depth + 1), uint64_t(0) - 1);
      return r;
    case Instruction::Mul:
      if (k) {
        r.addLin(intLin(BO->getOperand(0), depth + 1), k->getZExtValue());
        return r;
      }
      break;
    case Instruction::Shl:
      if (k && k->getZExtValue() < 64) {
        r.addLin(intLin(BO->getOperand(0), depth + 1), uint64_t(1) << k->getZExtValue());
        return r;
      }
      break;
    default:
      break;
    }
  }
  r.add(v, 1);
  return r;
}

Lin ptrLin(const DataLayout &DL, const Value *p, unsigned depth = 0) {
  auto *G = dyn_cast<GEPOperator>(p);
  if (!G || depth > 12) {
    Lin r;
    r.base = p;
    return r;
  }
  Lin r = ptrLin(DL, G->getPointerOperand(), depth + 1);
  for (gep_type_iterator it = gep_type_begin(G), e = gep_type_end(G); it != e; ++it) {
    const Value *idx = it.getOperand();
    if (StructType *ST = it.getStructTypeOrNull()) {
      r.c += DL.getStructLayout(ST)->getElementOffset(cast<ConstantInt>(idx)->getZExtValue());
      continue;
    }
    uint64_t stride = it.getSequentialElementStride(DL).getFixedValue();
    if (idx->getType()->isIntegerTy(64)) {
      r.addLin(intLin(idx), stride);
    } else if (auto *C = dyn_cast<ConstantInt>(idx)) {
      r.c += uint64_t(C->getSExtValue()) * stride;
    } else {
      r.add(idx, stride);   // a narrower index (sign-extended): a leaf
    }
  }
  return r;
}

// Two pointers that are different cell addresses on every run: two distinct allocas, or one base
// whose linear forms differ by a nonzero constant (120's q[i][0] and q[i][1]; 114's q[m-1] and
// q[m-2]). completePhis (the original IR only: a new-IR loop phi still lacks its back edge): two
// leftover phi terms of one block that differ by a constant on every trip (59's q[i] and q[i + 1]).
bool cellsDiffer(const DataLayout &DL, const Value *a, const Value *b, bool completePhis) {
  Lin la = ptrLin(DL, a), lb = ptrLin(DL, b);
  const Value *ua = getUnderlyingObject(la.base), *ub = getUnderlyingObject(lb.base);
  if (ua != ub && isa<AllocaInst>(ua) && isa<AllocaInst>(ub))
    return true;
  if (la.base != lb.base)
    return false;
  Lin d = lb;
  d.addLin(la, uint64_t(0) - 1);
  SmallVector<std::pair<const Value *, uint64_t>, 2> left;
  for (auto &[x, k] : d.terms)
    if (k != 0)
      left.push_back({x, k});
  if (left.size() == 2 && completePhis && left[0].second + left[1].second == 0) {
    // k * (x - y): x and y two phis differing by a constant on every trip.
    const Value *x = left[0].first, *y = left[1].first;
    PairDiff none;
    if (std::optional<int64_t> e = constDiff(y, x, none)) {
      d.c += left[0].second * uint64_t(*e);
      left.clear();
    }
  }
  return left.empty() && d.c != 0;
}

// Two leaves name different rails on every run: two distinct gate results; a confined rail and any
// other value; loads of two different cells; a gate result only ever stored into cells other than
// the one a load reads (114's q[m-1] ^= q[m-2] then the controlled Ry on q[m-2]). A slot cell holds a
// rail no other cell holds (mem-slots stores a copy of a stored value it does not own), so different
// cells name different rails.
bool storedOnlyElsewhere(const DataLayout &DL, const CallInst *def, const LoadInst *L) {
  for (const User *U : def->users()) {
    if (auto *St = dyn_cast<StoreInst>(U)) {
      // Same block as the definition: each run of the definition stores it once, with the address
      // values current wherever the definition's value is.
      if (St->getValueOperand() != def || St->getParent() != def->getParent() ||
          !cellsDiffer(DL, St->getPointerOperand(), L->getPointerOperand(), false))
        return false;
      continue;
    }
    auto *CI = dyn_cast<CallInst>(U);
    const Function *G = CI ? CI->getCalledFunction() : nullptr;
    if (G && ((G->getName().starts_with("cqrt_") && !G->getName().starts_with("cqrt_qram") &&
               !G->getName().starts_with("cqrt_push") && !G->getName().starts_with("cqrt_tape")) ||
              G->getName().starts_with("cq_template_")))
      continue;
    return false;
  }
  return true;
}

bool leavesDistinct(LoweringContext &ctx, Value *a, Value *b) {
  if (a == b)
    return false;
  if (isa<CallInst>(a) && isa<CallInst>(b))
    return true;
  if (confined(a) || confined(b))
    return true;
  const DataLayout &DL = ctx.M.getDataLayout();
  auto *la = dyn_cast<LoadInst>(a), *lb = dyn_cast<LoadInst>(b);
  if (la && lb)
    return cellsDiffer(DL, la->getPointerOperand(), lb->getPointerOperand(), false);
  auto *ca = dyn_cast<CallInst>(a), *cb = dyn_cast<CallInst>(b);
  if (ca && lb)
    return storedOnlyElsewhere(DL, ca, lb);
  if (cb && la)
    return storedOnlyElsewhere(DL, cb, la);
  return false;
}

// The original slot-cell load (a cq_theta's in-place operand, or a quantum branch condition of a
// block dominating T's) whose value is the new-IR handle h, or nullptr.
const LoadInst *originalLoad(LoweringContext &ctx, const CallInst &T, const DominatorTree &dt, Value *h) {
  SmallVector<const Value *, 8> cands{T.getArgOperand(0)};
  if (auto *N = dt.getNode(T.getParent()))
    for (auto *D = N->getIDom(); D; D = D->getIDom())
      if (auto *Br = dyn_cast<BranchInst>(D->getBlock()->getTerminator()); Br && Br->isConditional())
        cands.push_back(Br->getCondition());
  for (const Value *c : cands) {
    const Value *s = c;
    if (auto *Tr = dyn_cast<TruncInst>(s))
      s = Tr->getOperand(0);
    auto *L = dyn_cast<LoadInst>(s);
    if (!L || !ctx.T.isQuantum(c, ctx.S))
      continue;
    Operand o = ctx.operand(c);
    if (o.handle && o.v == h)
      return L;
  }
  return nullptr;
}

// cq-x80e. Whether the flag and the target (distinct handle values) may name one rail at run time.
enum class Alias { Distinct, Cells, Unknown };
Alias mayAlias(LoweringContext &ctx, const CallInst &T, const DominatorTree &dt, Value *flag, Value *rail) {
  SmallVector<Value *, 4> fl, rl;
  SmallPtrSet<Value *, 8> s1, s2;
  handleLeaves(flag, fl, s1);
  handleLeaves(rail, rl, s2);
  bool all = true;
  for (Value *a : fl)
    for (Value *b : rl)
      all &= leavesDistinct(ctx, a, b);
  if (all)
    return Alias::Distinct;
  if (!isa<LoadInst>(flag) || !isa<LoadInst>(rail))
    return Alias::Unknown;
  // Two cell loads: different cells by the original IR's addresses (59), else the same cell iff the
  // same address at run time (120 register_grid's q[0][1] and q[rows-1][1], one cell iff rows == 1).
  const LoadInst *lf = originalLoad(ctx, T, dt, flag), *lt = originalLoad(ctx, T, dt, rail);
  if (lf && lt && lf != lt &&
      cellsDiffer(ctx.M.getDataLayout(), lf->getPointerOperand(), lt->getPointerOperand(), true))
    return Alias::Distinct;
  return Alias::Cells;
}

// ry_<W>_controlled(flag, rail, θ): a non-diagonal gate on the rail (A4), which is frozen (rule 10).
void controlledRy(LoweringContext &ctx, Value *flag, Value *rail, RailType w, Value *angle, const CallInst &T,
                  const DominatorTree &dt) {
  abi::CoreSpec spec{abi::Core::Ry, w, /*ctl=*/true};
  RailId id = ctx.unc().idOf(rail);
  if (flag == rail) {
    // CR §1.3: an in-place target is never one of its own controls. The flag is read into a fresh
    // rail first; that copy read the register before the rotation, so it stays allocated (A4).
    flag = copyFlag(ctx, flag);
  } else if (Alias al = w.kind == Kind::Int && w.bits == 1 ? mayAlias(ctx, T, dt, flag, rail) : Alias::Distinct;
             al != Alias::Distinct) {
    if (al == Alias::Unknown)
      unimplemented("rot-cry: a controlled Ry whose control " + describe(flag) + " and target " + describe(rail) +
                        " may name one rail at run time, not as two slot-cell loads (cq-x80e)",
                    rail);
    // cq-x80e (CR §1.3, rules 9, 10; 120's reference): the two handles are loads of slot cells that
    // may be one cell at run time. A classical test of the two cell addresses: distinct, the bare
    // flag controls the Ry; the same cell, the flag is copied first and the copy stays allocated (66).
    IRBuilder<> &B = ctx.B();
    LLVMContext &C = ctx.M.getContext();
    Function &out = ctx.out();
    Value *eq = B.CreateICmpEQ(cast<LoadInst>(flag)->getPointerOperand(), cast<LoadInst>(rail)->getPointerOperand());
    BasicBlock *join = BasicBlock::Create(C, "", &out);
    BasicBlock *distinct = BasicBlock::Create(C, "", &out, join);
    BasicBlock *same = BasicBlock::Create(C, "", &out, join);
    B.CreateCondBr(eq, same, distinct);
    B.SetInsertPoint(distinct);
    ctx.unc().noteNonDiagonal(id, ctx.emitCore(spec, {flag, rail, angle}));
    B.CreateBr(join);
    B.SetInsertPoint(same);
    Value *f = copyFlag(ctx, flag);
    ctx.unc().noteNonDiagonal(id, ctx.emitCore(spec, {f, rail, angle}));
    B.CreateBr(join);
    B.SetInsertPoint(join);
    ctx.unc().setRole(id, Role::Frozen);
    return;
  }
  CallInst *ry = ctx.emitCore(spec, {flag, rail, angle});
  ctx.unc().noteNonDiagonal(id, ry);
  ctx.unc().setRole(id, Role::Frozen);
}

const Function *functionOf(const Value *v) {
  if (auto *I = dyn_cast<Instruction>(v))
    return I->getFunction();
  if (auto *A = dyn_cast<Argument>(v))
    return A->getParent();
  return nullptr;
}

// Forget what an earlier lowering of the same original theta (a loop body lowered again) left.
void forgetStale(FnState &st, const CallInst &T) {
  st.of.erase(&T);
  for (const User *U : T.users())
    if (isa<PHINode>(U))
      st.of.erase(U);
}

// The original blocks reachable from the end of T's block without passing def's block (another
// instance of def's value there). cyclic: T's block is among them.
DenseSet<const BasicBlock *> reachFrom(const Instruction &T, const Value *def, bool &cyclic) {
  const BasicBlock *db = nullptr;
  if (auto *D = dyn_cast<Instruction>(def))
    db = D->getParent();
  DenseSet<const BasicBlock *> reach;
  SmallVector<const BasicBlock *, 16> work(succ_begin(T.getParent()), succ_end(T.getParent()));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (b == db || !reach.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  cyclic = reach.count(T.getParent());
  return reach;
}

bool isAfter(const Instruction &T, const DenseSet<const BasicBlock *> &reach, const Instruction *I) {
  if (I->getParent() == T.getParent() && I != &T && T.comesBefore(I))
    return true;
  return reach.count(I->getParent());
}

// A cast that names its operand's rail (rule 3: a representation change, no gate).
bool isAlias(const Instruction *I) {
  if (isa<FreezeInst>(I))
    return true;
  if (auto *C = dyn_cast<BitCastInst>(I))
    return C->getSrcTy()->getPrimitiveSizeInBits() == C->getDestTy()->getPrimitiveSizeInBits();
  return false;
}

// cq-sx24. A second prep of R changes its rail in place (xorc, Ry under the flag). Every original
// value naming the register before this prep (an earlier prep, a merge of it) keeps its old value in
// the C program: a reader of it lowered after T (a phi edge after T, or a non-phi user T reaches,
// which -O1 may have sunk past T) must not read the re-prepared rail. Rule 10's adjoint undo (an
// overlapping prep) is sound only when nothing read the rail in between, and such a reader reads it
// in between in program order: cq::unimplemented. With disjoint predicates the rail is not undone,
// and the reader reads a copy taken just before the prep (the pre-rotation copy, cq-s32y: a Garbage
// rail that read the register, KeptEntangled from the copy on: the prep's xorc writes the register
// before the Ry that keeps it under A4). A phi reading the old value after
// T, an alias cast of it read after T, or a reader inside a cycle around T: cq::unimplemented.
void preserveOldValue(LoweringContext &ctx, FnState &st, Register &R, CallInst &T, bool overlap) {
  SmallVector<const Value *, 4> olds;
  for (auto &[w, r] : st.of)
    if (r == &R && w != &T && functionOf(w) == T.getFunction())
      // A value not dominating T has no reader that T reaches without a new instance of it.
      if (auto *I = dyn_cast<Instruction>(w); !I || st.dt->dominates(I, &T))
        olds.push_back(w);
  SmallVector<const Value *, 4> needCopy;
  for (const Value *w : olds) {
    bool cyclic = false;
    DenseSet<const BasicBlock *> reach = reachFrom(T, w, cyclic);
    const Instruction *reader = nullptr;
    bool copyOk = true;
    SmallVector<std::pair<const Value *, bool>, 8> work{{w, true}};   // (value, is w itself)
    SmallPtrSet<const Value *, 8> seen;
    while (!work.empty() && !reader) {
      auto [v, self] = work.pop_back_val();
      if (!seen.insert(v).second)
        continue;
      for (const Use &U : v->uses()) {
        auto *I = dyn_cast<Instruction>(U.getUser());
        if (!I || I == &T)
          continue;
        bool after;
        if (auto *phi = dyn_cast<PHINode>(I))
          after = isAfter(T, reach, phi->getIncomingBlock(U)->getTerminator());
        else
          after = isAfter(T, reach, I);
        if (after) {
          reader = I;
          copyOk = self && !isa<PHINode>(I) && !cyclic;
          break;
        }
        if (isAlias(I))
          work.push_back({I, false});
      }
    }
    if (!reader)
      continue;
    if (overlap)
      unimplemented("rot-cry: a second prep of a register whose earlier value " + describe(w) +
                        " is read after it (by " + describe(reader) +
                        "); rule 10 undoes the first prep by its adjoint only when nothing read the "
                        "register in between (cq-sx24)",
                    &T);
    if (!copyOk)
      unimplemented("rot-cry: a second prep of a register whose earlier value " + describe(w) +
                        " is read after it (by " + describe(reader) +
                        ") through a phi, an alias cast or a cycle around the prep (cq-sx24)",
                    &T);
    needCopy.push_back(w);
  }
  if (needCopy.empty())
    return;
  abi::CoreSpec a{abi::Core::Alloc, R.w};
  CallInst *c = ctx.emitCore(a, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), R.w))});
  RailId cid = ctx.unc().recordSeed(c);
  abi::CoreSpec cp{abi::Core::Copy, R.w};
  CallInst *cc = ctx.emitCore(cp, {R.rail, c});
  ctx.unc().recordCore(cc, cp, {Operand{R.rail, true}, Operand{c, true}}, cid);
  // The prep's xorc writes the register in place before its Ry: the copy read the register and the
  // Ry right after makes it KeptEntangled (A4); it is so from the copy on, never uncomputed across
  // the xorc.
  ctx.unc().setRole(cid, Role::KeptEntangled);
  for (const Value *w : needCopy) {
    Operand o = ctx.operand(w);
    if (!o.handle || o.v != R.rail)
      internalError("rot-cry: an earlier value of a register is not bound to its rail", w);
    ctx.rebind(w, {Operand{c, true}});
  }
}

} // namespace

void lowerControlledTheta(LoweringContext &ctx, CallInst &T, Value *flag) {
  if (!flag)
    internalError("rot-cry: lowerControlledTheta without a flag (an uncontrolled theta is rule 2's)", &T);
  if (T.arg_size() != 2)
    internalError("rot-cry: cq_theta with other than two arguments", &T);
  const Value *v = T.getArgOperand(0);
  Operand angle = ctx.operand(T.getArgOperand(1));
  if (angle.handle)
    internalError("rot-cry: a quantum angle (rules 11, 15: rot::lowerQuantumAngleTheta)", &T);
  RailType w = railTypeOf(v->getType());
  const Function &F = *T.getFunction();
  FnState &st = state(ctx, F);
  forgetStale(st, T);

  const BasicBlock *bb = T.getParent();
  Pred full = ctx.preds().block(bb);
  Pred cf = full.classicalFactor(ctx.T, ctx.S);
  Pred q = ctx.currentPredicate();

  Operand x = ctx.operand(v);
  if (x.handle) {
    // In place (rule 2 under the flag): the register is the operand's rail.
    Value *rail = ctx.rail(v);
    Register *R = nullptr;
    if (auto it = st.of.find(v); it != st.of.end() && it->second->rail == rail)
      R = it->second;
    if (!R) {
      for (auto &r : st.regs)
        if (r->rail == rail)
          R = r.get();
    }
    if (!R) {
      st.regs.push_back(std::make_unique<Register>());
      R = st.regs.back().get();
      R->rail = rail;
      R->w = w;
    }
    R->locked = true;   // its state is no longer seed-or-active-prep: no adjoint undo across this
    // cq-2xi3: where an active prep fired or this rotation runs, the register is not its seed; a
    // merge's straight-through edge there is not the register (lowerStatePrepMerge).
    Pred d = R->dirty ? (*R->dirty | q) : q;
    for (const Prep &p : R->active)
      d = d | p.eff;
    R->dirty = d;
    R->active.clear();
    controlledRy(ctx, flag, rail, w, angle.v, T, *st.dt);
    R->uses = rail->getNumUses();
    st.of[&T] = R;
    for (const User *U : T.users())
      if (isa<PHINode>(U))
        st.of[U] = R;
    ctx.bind(&T, rail);
    return;
  }

  // A prep of the classical value v. Find the register the merges name.
  Register *R = nullptr;
  auto pick = [&](Register *r, const Value *why) {
    if (R && R != r)
      unimplemented("rot-cry: a cq_theta whose merges name two different registers (" + describe(why) + ")", &T);
    R = r;
  };
  SmallVector<const PHINode *, 2> phis;
  bool otherUsers = false;
  for (const User *U : T.users()) {
    if (auto *P = dyn_cast<PHINode>(U)) {
      phis.push_back(P);
      if (auto it = st.of.find(P); it != st.of.end())
        pick(it->second, P);
      for (const Value *u : P->incoming_values())
        if (u != &T)
          if (auto it = st.of.find(u); it != st.of.end())
            pick(it->second, u);
    } else {
      otherUsers = true;
    }
  }
  (void)otherUsers;

  // Every value a merge of this prep takes on the edges where no prep runs: the straight-through
  // value. A cq_theta incoming is another prep; a phi incoming already bound to a register was
  // handled above.
  SmallVector<const Value *, 2> straight;
  for (const PHINode *P : phis)
    for (const Value *u : P->incoming_values()) {
      if (u == &T || isPrep(ctx, u) || st.of.count(u))
        continue;
      if (!isa<Constant>(u) && ctx.T.isQuantum(u, ctx.S)) {
        if (R && ctx.operand(u).handle && ctx.operand(u).v == R->rail)
          continue;
        unimplemented("rot-cry: a state prep merged with a quantum value that is not its register (" +
                          describe(u) + ")",
                      &T);
      }
      if (auto *I = dyn_cast<Instruction>(u); I && !st.dt->dominates(I, &T))
        unimplemented("rot-cry: a state prep whose straight-through value " + describe(u) +
                          " is defined after the prep",
                      &T);
      if (!is_contained(straight, u))
        straight.push_back(u);
    }

  Value *vv = x.v;
  bool dead = T.use_empty();
  if (!R && dead) {
    // Two thetas of one seed: share the rail of an earlier dead prep of the same value whose
    // predicates are disjoint from this one.
    for (auto &r : st.regs)
      if (r->deadShare && !r->locked && r->seed == vv && r->all && (*r->all & full).isBottom()) {
        R = r.get();
        break;
      }
  }

  bool fresh = !R;
  if (fresh) {
    Value *seed;
    if (straight.empty())
      seed = vv;
    else if (straight.size() == 1)
      seed = ctx.operand(straight.front()).v;
    else
      unimplemented("rot-cry: a state prep whose merges take several straight-through values", &T);
    if (!(phis.empty() && !dead) && !cf.isTop())
      unimplemented("rot-cry: a state prep under a classical guard whose register is merged or shared "
                    "outside it",
                    &T);
    if (seed->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("rot-cry: the straight-through value's type differs from the register's", &T);
    abi::CoreSpec a{abi::Core::Alloc, w};
    CallInst *alloc = ctx.emitCore(a, {seed});
    ctx.unc().recordSeed(alloc);
    st.regs.push_back(std::make_unique<Register>());
    R = st.regs.back().get();
    R->rail = alloc;
    R->w = w;
    R->seed = seed;
    R->deadShare = dead;
    R->uses = alloc->getNumUses();
  } else {
    if (!R->seed)
      unimplemented("rot-cry: a prep of a classical value into a register that holds a quantum value "
                    "(rotated in place)",
                    &T);
    if (R->locked)
      unimplemented("rot-cry: a second prep of a register rotated in place since its first prep", &T);
    if (!cf.isTop())
      unimplemented("rot-cry: a second prep of a register under a classical guard", &T);
    if (R->w.kind != w.kind || R->w.bits != w.bits)
      internalError("rot-cry: a prep of another width into a register", &T);
    for (const Value *s : straight)
      if (ctx.operand(s).v != R->seed)
        unimplemented("rot-cry: a second prep whose merge takes a straight-through value other than the "
                      "register's seed (" + describe(s) + ")",
                      &T);
  }

  // Rule 10: undo every active prep that may have fired where this one runs.
  bool overlap = false;
  for (const Prep &p : R->active)
    overlap |= !(p.eff & q).isBottom();
  if (!fresh)
    preserveOldValue(ctx, st, *R, T, overlap);
  if (overlap) {
    if (R->rail->getNumUses() != R->uses)
      unimplemented("rot-cry: a second prep of a register read since its first prep (rule 10 undoes "
                    "the first by its adjoint only when nothing read it in between)",
                    &T);
    for (auto it = R->active.rbegin(); it != R->active.rend(); ++it) {
      Pred g = it->eff & q;
      if (g.isBottom())
        continue;
      Value *gf = ctx.preds().flag(ctx, g);
      if (!gf)
        internalError("rot-cry: a conjunction flag that is constant true", &T);
      controlledRy(ctx, gf, R->rail, R->w, ctx.B().CreateFNeg(it->angle), T, *st.dt);
      if (it->lit)
        recordXorc(ctx, gf, *R, it->lit);
    }
  }
  std::vector<Prep> still;
  for (Prep &p : R->active) {
    Pred e = p.eff & !q;
    if (!e.isBottom())
      still.push_back(Prep{e, p.angle, p.lit});
  }
  R->active = std::move(still);

  // The prep itself: r = v where the arm runs (xorc from the straight-through value), then Ry.
  Value *lit = xorLiteral(ctx, R->seed, vv);
  if (lit)
    recordXorc(ctx, flag, *R, lit);
  controlledRy(ctx, flag, R->rail, R->w, angle.v, T, *st.dt);
  R->active.push_back(Prep{q, angle.v, lit});
  R->all = R->all ? (*R->all | full) : full;
  R->uses = R->rail->getNumUses();

  st.of[&T] = R;
  for (const PHINode *P : phis)
    st.of[P] = R;
  ctx.bind(&T, R->rail);
}

void lowerStatePrepMerge(LoweringContext &ctx, PHINode &phi) {
  FnState &st = state(ctx, *phi.getFunction());
  Register *R = nullptr;
  if (auto it = st.of.find(&phi); it != st.of.end())
    R = it->second;
  if (!R)
    for (const Value *u : phi.incoming_values())
      if (auto it = st.of.find(u); it != st.of.end()) {
        R = it->second;
        break;
      }
  if (!R)
    internalError("rot-cry: lowerStatePrepMerge on a phi with no state-prep incoming", &phi);

  const BasicBlock *bb = phi.getParent();
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const Value *u = phi.getIncomingValue(i);
    if (auto it = st.of.find(u); it != st.of.end()) {
      if (it->second != R)
        unimplemented("rot-cry: a merge of two different registers", &phi);
      continue;
    }
    if (isPrep(ctx, u))
      internalError("rot-cry: a merge incoming prep that was not lowered as a prep of a register", &phi);
    Operand o = ctx.operand(u);
    if (o.handle) {
      if (o.v != R->rail)
        unimplemented("rot-cry: a state-prep merge with a quantum incoming that is not its register (" +
                          describe(u) + ")",
                      &phi);
      continue;
    }
    if (!R->seed || o.v != R->seed)
      unimplemented("rot-cry: a state-prep merge whose classical incoming " + describe(u) +
                        " is not the register's straight-through value",
                    &phi);
    // The straight-through value is the register's value on this edge only where no prep fired.
    const Pred &e = ctx.preds().edge(phi.getIncomingBlock(i), bb);
    for (const Prep &p : R->active)
      if (!(p.eff & e).isBottom())
        unimplemented("rot-cry: a state-prep merge whose straight-through edge (incoming " + describe(u) +
                          ") may follow a prep",
                      &phi);
    if (R->dirty && !(*R->dirty & e).isBottom())
      unimplemented("rot-cry: a state-prep merge whose straight-through edge (incoming " + describe(u) +
                        ") may follow a prep or an in-place rotation of the register (cq-2xi3)",
                    &phi);
  }
  st.of[&phi] = R;
  ctx.bind(&phi, R->rail);
}

} // namespace cq::rot
