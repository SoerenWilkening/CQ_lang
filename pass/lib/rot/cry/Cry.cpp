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
//    A quantum angle (rule 15, cq-t3rd: rot-qangle delegates here) is the same case with
//    ry_<W>_qangle_controlled(flag, x, A): the register bookkeeping (locked, dirty) is the classical
//    angle's, so a later prep of the rotated register stops loudly.
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
// cq-oa67: a merge's other straight-through values (a second classical value, one defined after the
// prep, a rail that is not the register) are written into the register on their own edges at the merge
// (lowerStatePrepMerge): xorc of seed ^ u under the edge's flag, recorded as an active entry a later prep
// undoes, or a cleared seed and copy_<W>_controlled of the rail (the register is then locked). A quantum
// angle (rule 15) preps the register like a classical one, with ry_<W>_qangle_controlled.
//
// Rule 10's second prep (ruling 2026-11-02, cq-oa67): when the first prep cannot be undone by its adjoint
// (something read the register since, an old value is read after the prep, the register was rotated in
// place or holds a quantum value) or the prep runs under a classical guard, it is a prep of a FRESH rail
// seeded with v; the old rail stays allocated (frozen), and every merge that cannot be the register itself
// (two registers, a straight-through edge a prep or rotation may precede, a register of a classical
// guard) is rule 9's over the handles (pred::lowerMerge).
#include "cq/Rotation.h"
#include "cq/Order.h"

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::rot {

namespace {

struct Prep {
  Pred eff;          // where this prep is the register's current state (quantum part)
  Value *angle;      // the angle, new IR (a classical double, or an f64 rail: qangle); nullptr: no Ry (a
                     // merge's straight-through fix-up, cq-oa67)
  Value *lit;        // the xorc literal it applied first, or nullptr
  bool qangle = false;
};

struct Register {
  Value *rail = nullptr;                 // the register's handle, new IR
  RailType w{};
  Value *seed = nullptr;                 // new-IR classical straight-through value; nullptr: in place
  bool deadShare = false;                // made by a prep nothing reads (two thetas of one seed)
  bool locked = false;                   // rotated in place: no adjoint undo across it
  bool guarded = false;                  // allocated under a classical guard: merged by rule 9 outside it
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
  MapVector<const Value *, Register *> of;   // original cq_theta calls and phis -> register, in insertion order
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

// A cq_theta under a quantum predicate: a prep this module lowers, with a classical angle or with rule
// 15's angle rail (cq-oa67).
bool isPrep(LoweringContext &ctx, const Value *v) {
  auto *CI = dyn_cast<CallInst>(v);
  const Function *F = CI ? CI->getCalledFunction() : nullptr;
  if (!F || !F->getName().starts_with("cq_theta_") || CI->arg_size() != 2)
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

// cq-oa67 (CR §1.3, rule 15): a rail read into a fresh rail of its width (alloc 0, copy_<W>) before a
// rotation of the rail it copies (cq_theta(x, x): the target is never one of its own controls, so the
// angle is the copy). The copy read the register before the rotation, so it stays allocated (A4).
Value *copyRail(LoweringContext &ctx, Value *h, RailType w) {
  abi::CoreSpec a{abi::Core::Alloc, w};
  CallInst *f = ctx.emitCore(a, {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *c = ctx.emitCore(cp, {h, f});
  ctx.unc().recordCore(c, cp, {Operand{h, true}, Operand{f, true}}, fid);
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

bool leavesDistinct(LoweringContext &ctx, Value *a, Value *b) {
  if (a == b)
    return false;
  // cq-nqa6 (117's grover_1000_ctl: cRy(pred, x[i])): a _ctl clone's entry flag names no rail the clone
  // reaches otherwise (rule 19).
  for (Value *v : {a, b})
    if (auto *A = dyn_cast<Argument>(v); A && ctx.S.ctl && A->getParent() == &ctx.out() && A->getArgNo() == 0) {
      return true;
    }
  if (isa<CallInst>(a) && isa<CallInst>(b))
    return true;
  if (confined(a) || confined(b))
    return true;
  return false;
}

// cq-x80e. Whether the flag and the target (distinct handle values) may name one rail at run time.
enum class Alias { Distinct, Unknown };
Alias mayAlias(LoweringContext &ctx, Value *flag, Value *rail) {
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
  return Alias::Unknown;
}

// ry_<W>_controlled(flag, rail, θ): a non-diagonal gate on the rail (A4), which is frozen (rule 10).
// qangle (cq-t3rd, rule 15): θ is an f64 angle rail, ry_<W>_qangle_controlled(flag, rail, A).
void controlledRy(LoweringContext &ctx, Value *flag, Value *rail, RailType w, Value *angle, bool qangle = false) {
  abi::CoreSpec spec{qangle ? abi::Core::RyQAngle : abi::Core::Ry, w, /*ctl=*/true};
  RailId id = ctx.unc().idOf(rail);
  if (flag == rail) {
    // CR §1.3: an in-place target is never one of its own controls. The flag is read into a fresh
    // rail first; that copy read the register before the rotation, so it stays allocated (A4).
    flag = copyFlag(ctx, flag);
  } else if (Alias al = w.kind == Kind::Int && w.bits == 1 ? mayAlias(ctx, flag, rail) : Alias::Distinct;
             al != Alias::Distinct) {
    // cq-x80e (CR §1.3, rules 9, 10; 120's reference): the two handles may name one rail at run time. A
    // classical test: distinct, the bare flag controls the Ry; the same rail, the flag is copied first
    // and the copy stays allocated (66). The handle values are compared, which name one rail iff they are
    // equal (cq-oa67).
    IRBuilder<> &B = ctx.B();
    LLVMContext &C = ctx.M.getContext();
    Function &out = ctx.out();
    Value *eq = B.CreateICmpEQ(flag, rail);
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
  if (I->getParent() == T.getParent() && I != &T && cq::comesBefore(&T, I))
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
bool preserveOldValue(LoweringContext &ctx, FnState &st, Register &R, CallInst &T, bool overlap, bool dryRun) {
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
    // Rule 10 (ruling 2026-11-02, cq-oa67): a reader of the earlier value after the prep means the first
    // prep cannot be undone, and an old value read through a phi, an alias or a cycle cannot be copied out
    // in front of the prep: the second prep is then a prep of a FRESH rail (the caller's), and the old
    // register stays as it is.
    if (overlap || !copyOk)
      return false;
    needCopy.push_back(w);
  }
  if (needCopy.empty() || dryRun)
    return true;
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
  return true;
}

} // namespace

void lowerControlledTheta(LoweringContext &ctx, CallInst &T, Value *flag) {
  if (!flag)
    internalError("rot-cry: lowerControlledTheta without a flag (an uncontrolled theta is rule 2's)", &T);
  if (T.arg_size() != 2)
    internalError("rot-cry: cq_theta with other than two arguments", &T);
  const Value *v = T.getArgOperand(0);
  Operand angle = ctx.operand(T.getArgOperand(1));
  RailType w = railTypeOf(v->getType());
  const Function &F = *T.getFunction();
  FnState &st = state(ctx, F);
  forgetStale(st, T);

  const BasicBlock *bb = T.getParent();
  Pred full = ctx.preds().block(bb);
  Pred cf = full.classicalFactor(ctx.T, ctx.S);
  Pred q = ctx.currentPredicate();

  Operand x = ctx.operand(v);
  // cq-t3rd: a quantum angle (rule 15, from rot::lowerQuantumAngleTheta) is built on the in-place
  // case only, with the classical angle's register bookkeeping and ry_<W>_qangle_controlled.
  if (x.handle) {
    // In place (rule 2 under the flag): the register is the operand's rail.
    Value *rail = ctx.rail(v);
    if (angle.handle && angle.v == rail)
      angle.v = copyRail(ctx, rail, RailType{Kind::Fp, 64});   // cq-oa67: the angle is a copy of the target
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
    controlledRy(ctx, flag, rail, w, angle.v, angle.handle);
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
  bool twoRegisters = false;
  auto pick = [&](Register *r, const Value *) {
    // Merges naming two registers (rule 10, cq-oa67): this prep is a prep of a fresh rail and each merge
    // is rule 9's over the registers' handles (lowerStatePrepMerge).
    if (R && R != r)
      twoRegisters = true;
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
  // cq-oa67: only a classical value defined before the prep can seed the register here. Any other
  // straight-through value (a second classical one, one defined after the prep, a quantum value that is
  // not the register) is written into the register on its own edge at the merge (lowerStatePrepMerge).
  SmallVector<const Value *, 2> straight;
  for (const PHINode *P : phis)
    for (const Value *u : P->incoming_values()) {
      if (u == &T || isPrep(ctx, u) || st.of.count(u))
        continue;
      if (!isa<Constant>(u) && ctx.T.isQuantum(u, ctx.S))
        continue;
      if (auto *I = dyn_cast<Instruction>(u); I && !st.dt->dominates(I, &T))
        continue;
      if (!is_contained(straight, u))
        straight.push_back(u);
    }

  if (twoRegisters)
    R = nullptr;
  Value *vv = x.v;
  bool dead = T.use_empty();
  if (!R && dead && cf.isTop()) {
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
    // The seed: the straight-through value when it is available here (the first one, cq-oa67: the merge
    // writes the others on their edges), else v (every incoming is a prep, 39 _ifelse).
    // Under a classical guard (P1 factor) the register exists on the guard's path only: it is seeded with
    // v, and a merge outside the guard is rule 9's over the handles (a classical phi, lowerStatePrepMerge).
    bool guarded = !cf.isTop();
    Value *seed = straight.empty() || guarded ? vv : ctx.operand(straight.front()).v;
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
    R->deadShare = dead && !guarded;
    R->guarded = guarded;
    R->locked = guarded;
    R->uses = alloc->getNumUses();
  } else {
    if (R->w.kind != w.kind || R->w.bits != w.bits)
      internalError("rot-cry: a prep of another width into a register", &T);
    // Rule 10 (ruling 2026-11-02, cq-oa67): when the first prep cannot be undone (the register holds a
    // quantum value or was rotated in place, something read it since, an old value is read after this
    // prep, a quantum angle's rail is gone) or this prep runs under a classical guard, the second prep is a
    // prep of a FRESH rail seeded with v: the register's handle moves to it, the old rail stays allocated
    // as a frozen which-path record, and the arms merge by rule 9 over the two handles.
    bool overlapNow = false;
    for (const Prep &p : R->active)
      overlapNow |= !(p.eff & q).isBottom();
    bool undoable = R->seed && !R->locked && cf.isTop() &&
                    (!overlapNow || R->rail->getNumUses() == R->uses) &&
                    preserveOldValue(ctx, st, *R, T, overlapNow, /*dryRun=*/true);
    if (undoable && overlapNow)
      for (const Prep &p : R->active)
        if (p.angle && p.qangle && !(p.eff & q).isBottom() && !ctx.unc().liveRole(ctx.unc().idOf(p.angle)))
          undoable = false;
    if (!undoable) {
      R->locked = true;   // retired: no later prep undoes across this one
      abi::CoreSpec a{abi::Core::Alloc, w};
      CallInst *alloc = ctx.emitCore(a, {vv});
      ctx.unc().recordSeed(alloc);
      st.regs.push_back(std::make_unique<Register>());
      Register *N = st.regs.back().get();
      N->rail = alloc;
      N->w = w;
      N->seed = vv;
      N->guarded = true;   // the register's handle moved: every merge of it is rule 9's
      N->locked = true;
      controlledRy(ctx, flag, N->rail, N->w, angle.v, angle.handle);
      N->active.push_back(Prep{q, angle.v, nullptr, angle.handle});
      N->all = full;
      N->uses = N->rail->getNumUses();
      st.of[&T] = N;
      ctx.bind(&T, N->rail);
      return;
    }
  }

  // Rule 10: undo every active prep that may have fired where this one runs.
  bool overlap = false;
  for (const Prep &p : R->active)
    overlap |= !(p.eff & q).isBottom();
  if (!fresh)
    preserveOldValue(ctx, st, *R, T, overlap, /*dryRun=*/false);
  if (overlap) {
    if (R->rail->getNumUses() != R->uses)
      internalError("rot-cry: an undo of a register read since its first prep", &T);
    for (auto it = R->active.rbegin(); it != R->active.rend(); ++it) {
      Pred g = it->eff & q;
      if (g.isBottom())
        continue;
      Value *gf = ctx.preds().flag(ctx, g);
      if (!gf)
        internalError("rot-cry: a conjunction flag that is constant true", &T);
      if (it->angle && it->qangle) {
        // Rule 15's angle rail, negated by the fneg template into a fresh rail (garbage of this undo).
        RailId aid = ctx.unc().idOf(it->angle);
        if (!ctx.unc().liveRole(aid))
          internalError("rot-cry: an undo of a quantum-angle prep whose angle rail is already uncomputed", &T);
        abi::TemplateSpec neg;
        neg.op = "fneg";
        neg.w = RailType{Kind::Fp, 64};
        controlledRy(ctx, gf, R->rail, R->w, ctx.emitTemplate(neg, {Operand{it->angle, true}}), true);
      } else if (it->angle) {
        controlledRy(ctx, gf, R->rail, R->w, ctx.B().CreateFNeg(it->angle));
      }
      if (it->lit)
        recordXorc(ctx, gf, *R, it->lit);
    }
  }
  std::vector<Prep> still;
  for (Prep &p : R->active) {
    Pred e = p.eff & !q;
    if (!e.isBottom())
      still.push_back(Prep{e, p.angle, p.lit, p.qangle});
  }
  R->active = std::move(still);

  // The prep itself: r = v where the arm runs (xorc from the straight-through value), then Ry.
  Value *lit = xorLiteral(ctx, R->seed, vv);
  if (lit)
    recordXorc(ctx, flag, *R, lit);
  controlledRy(ctx, flag, R->rail, R->w, angle.v, angle.handle);
  R->active.push_back(Prep{q, angle.v, lit, angle.handle});
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
  if (!R) {
    // Every state-prep incoming is itself a rule 9 merge (a fresh rail's): this one is too.
    ctx.bind(&phi, lowerMerge(ctx, phi));
    return;
  }

  const BasicBlock *bb = phi.getParent();
  // Rule 10 (ruling 2026-11-02, cq-oa67): the merge is the register itself when every edge carries it or a
  // value the register can be made to hold on that edge (its seed where no prep fired, written there).
  // Otherwise (two registers, a fresh rail of a second prep beside the old one, a straight-through edge a
  // prep or an in-place rotation of the register may precede) the arms merge by rule 9 over the handles.
  bool byRule9 = R->guarded;
  for (unsigned i = 0; i < phi.getNumIncomingValues() && !byRule9; ++i) {
    const Value *u = phi.getIncomingValue(i);
    if (auto it = st.of.find(u); it != st.of.end()) {
      byRule9 = it->second != R;
      continue;
    }
    Operand o = ctx.operand(u);
    if (o.handle && o.v == R->rail)
      continue;
    const Pred &e = ctx.preds().edge(phi.getIncomingBlock(i), bb);
    for (const Prep &p : R->active)
      byRule9 |= !(p.eff & e).isBottom();
    byRule9 |= R->dirty && !(*R->dirty & e).isBottom();
    byRule9 |= !R->seed && !(!o.handle && o.v == R->seed);
  }
  if (byRule9) {
    ctx.bind(&phi, lowerMerge(ctx, phi));
    return;
  }
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    const Value *u = phi.getIncomingValue(i);
    if (auto it = st.of.find(u); it != st.of.end()) {
      if (it->second != R)
        internalError("rot-cry: a register merge of two registers", &phi);
      continue;
    }
    if (isPrep(ctx, u))
      internalError("rot-cry: a merge incoming prep that was not lowered as a prep of a register", &phi);
    Operand o = ctx.operand(u);
    if (o.handle && o.v == R->rail)
      continue;
    // The straight-through value is the register's value on this edge only where no prep fired.
    const Pred &e = ctx.preds().edge(phi.getIncomingBlock(i), bb);
    if (!o.handle && R->seed && o.v == R->seed)
      continue;
    // cq-oa67 (rules 9, 10): any other straight-through value is written into the register on its own
    // edge, where the register holds its seed (no prep fired there, checked above): under the edge's
    // flag, xorc of seed ^ u for a classical u (undone like a prep's reset by a later prep), or the seed
    // cleared and a controlled basis copy of a rail u (the register then holds a copy of u there and is
    // locked: no later prep undoes across it).
    if (!R->seed)
      internalError("rot-cry: a register merge over a register with no seed", &phi);
    if (!o.handle && o.v->getType() != R->seed->getType())
      internalError("rot-cry: a straight-through value of another type than the register's seed", &phi);
    Value *g = ctx.preds().flag(ctx, e);
    if (!o.handle) {
      Value *lit = xorLiteral(ctx, R->seed, o.v);
      if (!lit)
        continue;
      if (!g) {
        abi::CoreSpec spec{abi::Core::Xorc, R->w};
        CallInst *x = ctx.emitCore(spec, {R->rail, lit});
        ctx.unc().recordCore(x, spec, {Operand{R->rail, true}, Operand{lit, false}}, ctx.unc().idOf(R->rail));
      } else {
        recordXorc(ctx, g, *R, lit);
      }
      R->active.push_back(Prep{e, nullptr, lit, false});
      continue;
    }
    if (!g)
      internalError("rot-cry: a state-prep merge whose straight-through edge is taken on every path", &phi);
    if (Value *lit = xorLiteral(ctx, R->seed, Constant::getNullValue(R->seed->getType())))
      recordXorc(ctx, g, *R, lit);
    abi::CoreSpec cp{abi::Core::Copy, R->w, /*ctl=*/true};
    CallInst *c = ctx.emitCore(cp, {g, o.v, R->rail});
    ctx.unc().recordCore(c, cp, {Operand{g, true}, o, Operand{R->rail, true}}, ctx.unc().idOf(R->rail));
    R->dirty = R->dirty ? (*R->dirty | e) : e;
    R->locked = true;
  }
  st.of[&phi] = R;
  ctx.bind(&phi, R->rail);
}

} // namespace cq::rot
