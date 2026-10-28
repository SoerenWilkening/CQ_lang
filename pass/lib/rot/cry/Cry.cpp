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
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
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

// ry_<W>_controlled(flag, rail, θ): a non-diagonal gate on the rail (A4), which is frozen (rule 10).
void controlledRy(LoweringContext &ctx, Value *flag, Value *rail, RailType w, Value *angle) {
  if (flag == rail) {
    // CR §1.3: an in-place target is never one of its own controls. The flag is read into a fresh
    // rail first; that copy read the register before the rotation, so it stays allocated (A4).
    abi::CoreSpec a{abi::Core::Alloc, RailType{Kind::Int, 1}};
    CallInst *f = ctx.emitCore(a, {ConstantInt::getFalse(ctx.M.getContext())});
    ctx.unc().recordSeed(f);
    abi::CoreSpec x{abi::Core::XorI1, RailType{Kind::Int, 1}};
    CallInst *c = ctx.emitCore(x, {flag, f});
    ctx.unc().recordCore(c, x, {Operand{flag, true}, Operand{f, true}}, ctx.unc().idOf(f));
    flag = f;
  }
  abi::CoreSpec spec{abi::Core::Ry, w, /*ctl=*/true};
  CallInst *ry = ctx.emitCore(spec, {flag, rail, angle});
  RailId id = ctx.unc().idOf(rail);
  ctx.unc().noteNonDiagonal(id, ry);
  ctx.unc().setRole(id, Role::Frozen);
}

// Forget what an earlier lowering of the same original theta (a loop body lowered again) left.
void forgetStale(FnState &st, const CallInst &T) {
  st.of.erase(&T);
  for (const User *U : T.users())
    if (isa<PHINode>(U))
      st.of.erase(U);
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
    R->active.clear();
    controlledRy(ctx, flag, rail, w, angle.v);
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
      controlledRy(ctx, gf, R->rail, R->w, ctx.B().CreateFNeg(it->angle));
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
  controlledRy(ctx, flag, R->rail, R->w, angle.v);
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
        unimplemented("rot-cry: a state-prep merge whose straight-through edge may follow a prep", &phi);
  }
  st.of[&phi] = R;
  ctx.bind(&phi, R->rail);
}

} // namespace cq::rot
