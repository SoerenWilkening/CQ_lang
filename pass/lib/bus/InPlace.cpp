// Rule 5 In-place form and its Readers clause (with rules 2, 4, 6 "a memory cell", 10; ABI §1.10 Undo 2).
//
//   y = load p; y_1 = g_1(y, ...); ...; y' = g_n(y_{n-1}, ...); store y', p
//
// on one SSA pointer with no memory version change between, each g_i a cq_theta of the previous value or a rule-6
// bijection in it, is: h = alloc(0); swap(p, h); the steps on h; swap(p, y'); free. Width casts: trunc (nuw or a range
// fact), the steps at the narrow width, zext, store. Readers: y may be the value forwarded from the preceding store.
//
// The plan is one per lowered body: the form's load and steps emit nothing where the walker meets them
// (inPlaceBefore), and the form is emitted at the store's position. Its rails are no business of Uncompute: nothing of
// the form outlives its second swap. The readers of its operands are the IR uses of the raw calls.
#include "BusInternal.h"

#include "cq/Abi.h"
#include "cq/Predicate.h"
#include "../spine/SpineInternal.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <memory>

using namespace llvm;
using namespace llvm::PatternMatch;

namespace cq::bus {

namespace {

[[noreturn]] void stop(const Twine &what, const Value *at) {
  std::string s;
  raw_string_ostream os(s);
  os << "cq: unimplemented: bus: " << what;
  if (at)
    os << ": " << *at;
  report_fatal_error(Twine(os.str()), /*gen_crash_diag=*/false);
}

bool isTheta(const Value *v) {
  auto *c = dyn_cast<CallInst>(v);
  const Function *G = c ? c->getCalledFunction() : nullptr;
  return G && G->isDeclaration() && G->getName().starts_with("cq_theta_") && c->arg_size() == 2;
}

bool range01(const LoadInst &L) {
  MDNode *md = L.getMetadata(LLVMContext::MD_range);
  if (!md || !L.getType()->isIntegerTy())
    return false;
  ConstantRange r = getConstantRangeFromMetadata(*md);
  return !r.isWrappedSet() && r.getUnsignedMax().ule(1);
}

// Width casts: the high bits above `bits` of L's value are 0 by a range fact.
bool highBitsZero(const LoadInst &L, unsigned bits) {
  MDNode *md = L.getMetadata(LLVMContext::MD_range);
  if (!md || !L.getType()->isIntegerTy())
    return false;
  ConstantRange r = getConstantRangeFromMetadata(*md);
  return !r.isWrappedSet() && r.getUnsignedMax().getActiveBits() <= bits;
}

// One rule-6 update of the previous value: its template, and the other operand. op empty: the previous value itself (a
// select's arm).
struct Update {
  const char *op = nullptr;
  const Value *z = nullptr;   // nullptr: unary. fsh*: the shift amount
  bool yFirst = true;         // sub: y - z or z - y
};

struct Step {
  enum Kind { Theta, Single, Choice } kind = Single;
  const Value *def = nullptr;     // the value this step defines (the atomicrmw for rule 4's)
  const CallInst *theta = nullptr;
  Update a, b;                    // Single: a. Choice: cond ? a : b
  const Value *cond = nullptr;
  SmallVector<const Instruction *, 2> arms;   // a Choice's arm instructions, read by the select only
  const Value *prev = nullptr;    // the operand the step is a bijection in
};

struct Form {
  StoreInst *S = nullptr;
  const Value *ptr = nullptr;
  Type *U = nullptr, *T = nullptr;      // the form's width; the cell's access type
  const LoadInst *L = nullptr;
  const Instruction *trunc = nullptr, *zext = nullptr;
  const StoreInst *Prev = nullptr;      // Readers: y is the value forwarded from this store
  const Value *y = nullptr;             // the value at width U the first step reads
  SmallVector<Step, 4> steps;           // first to last
  SmallVector<const Instruction *, 2> changes;   // Readers: the changes of the interval from Prev to S
  // Part ends: a step index at or after the first cq_theta whose value has another reader (the last step's included).
  SmallVector<unsigned, 2> ends;
  // State of the walk, Readers only:
  Value *d = nullptr;                   // the classical disjointness test; nullptr: the constant 0 (the copy)
  Value *copy = nullptr;                // y's copy: a load, or a classical phi with a poison incoming when d
  Operand copyAddr{nullptr, false};
  Value *copyCtl = nullptr;
  bool copied = false;
  unsigned emitted = 0;                 // steps already emitted
};

struct Plan {
  WeakVH out;
  const Function *orig = nullptr;
  std::vector<std::unique_ptr<Form>> forms;
  DenseMap<const StoreInst *, Form *> ofStore;
  DenseSet<const Instruction *> claimed;
  DenseMap<const Instruction *, std::pair<Form *, unsigned>> earlyAt;   // emit the part ending at this step here
  DenseMap<const Instruction *, SmallVector<Form *, 1>> copyBefore, copyAfter;
};

thread_local DenseMap<const Function *, std::unique_ptr<Plan>> plans;

// -------------------------------------------------------------------------------------------------------------------
// The matcher.

// Every memory version change of the original function on a path from `from` to `to`, both excluded.
void changesBetween(LoweringContext &ctx, const Instruction &from, const Instruction &to,
                    SmallVectorImpl<const Instruction *> &out) {
  const BasicBlock *FB = from.getParent(), *TB = to.getParent();
  auto scan = [&](BasicBlock::const_iterator a, BasicBlock::const_iterator b) {
    for (; a != b; ++a)
      if (&*a != &to && versionChange(ctx, *a))
        out.push_back(&*a);
  };
  if (FB == TB && from.comesBefore(&to)) {
    scan(std::next(from.getIterator()), to.getIterator());
    return;
  }
  scan(std::next(from.getIterator()), FB->end());
  scan(TB->begin(), to.getIterator());
  SmallPtrSet<const BasicBlock *, 16> fwd, back;
  SmallVector<const BasicBlock *, 16> w{FB};
  while (!w.empty())
    for (const BasicBlock *s : successors(w.pop_back_val()))
      if (s != FB && s != TB && fwd.insert(s).second)
        w.push_back(s);
  w.push_back(TB);
  while (!w.empty())
    for (const BasicBlock *p : predecessors(w.pop_back_val()))
      if (p != FB && p != TB && back.insert(p).second)
        w.push_back(p);
  for (const BasicBlock *b : fwd)
    if (back.count(b))
      scan(b->begin(), b->end());
}

// The preceding store to `ptr` on the one path that reaches S: back through S's block and single predecessors.
const StoreInst *precedingStore(const StoreInst &S, const Value *ptr) {
  const Instruction *at = S.getPrevNode();
  const BasicBlock *bb = S.getParent();
  SmallPtrSet<const BasicBlock *, 8> seen{bb};
  while (true) {
    for (; at; at = at->getPrevNode())
      if (auto *P = dyn_cast<StoreInst>(at); P && P->getPointerOperand() == ptr)
        return P->isVolatile() ? nullptr : P;
    bb = bb->getSinglePredecessor();
    if (!bb || !seen.insert(bb).second)
      return nullptr;
    at = bb->getTerminator();
  }
}

// Does the store's value `stored` (of type T) hold v (at width U)?
bool holds(const Value *stored, const Value *v) {
  if (stored == v)
    return true;
  if (auto *z = dyn_cast<ZExtInst>(stored); z && z->getOperand(0) == v)
    return true;
  auto *a = dyn_cast<ConstantInt>(stored), *b = dyn_cast<ConstantInt>(v);
  return a && b && a->getValue() == b->getValue().zext(a->getBitWidth());
}

// `v` reads a value of `set`, through instructions.
bool readsAny(const Value *v, const SmallPtrSetImpl<const Value *> &set, SmallPtrSetImpl<const Value *> &seen) {
  if (set.count(v))
    return true;
  auto *I = dyn_cast<Instruction>(v);
  if (!I || !seen.insert(I).second)
    return false;
  return any_of(I->operands(), [&](const Use &u) { return readsAny(u.get(), set, seen); });
}

// The rule-6 update of `y` that I is (rule 6's list), else no op.
Update updateOf(const Instruction &I, const Value *y) {
  Update u;
  const Value *a = nullptr, *b = nullptr;
  if (auto *bo = dyn_cast<BinaryOperator>(&I); bo && bo->getType()->isIntegerTy()) {
    a = bo->getOperand(0);
    b = bo->getOperand(1);
    if (a == b || (a != y && b != y))
      return u;
    const Value *z = a == y ? b : a;
    switch (bo->getOpcode()) {
    case Instruction::Add: u.op = "add"; break;
    case Instruction::Xor: u.op = "xor"; break;
    case Instruction::Sub:
      u.op = "sub";
      u.yFirst = a == y;
      break;
    case Instruction::Mul: {
      auto *k = dyn_cast<ConstantInt>(z);
      if (!k || !k->getValue()[0])
        return Update{};
      u.op = "mul";
      break;
    }
    default:
      return Update{};
    }
    u.z = z;
    return u;
  }
  if (auto *un = dyn_cast<UnaryOperator>(&I); un && un->getOpcode() == Instruction::FNeg && un->getOperand(0) == y) {
    u.op = "fneg";
    return u;
  }
  if (auto *II = dyn_cast<IntrinsicInst>(&I)) {
    Intrinsic::ID id = II->getIntrinsicID();
    if ((id == Intrinsic::bswap || id == Intrinsic::bitreverse) && II->getArgOperand(0) == y) {
      u.op = id == Intrinsic::bswap ? "bswap" : "bitreverse";
      return u;
    }
    if ((id == Intrinsic::fshl || id == Intrinsic::fshr) && II->getArgOperand(0) == y && II->getArgOperand(1) == y) {
      u.op = id == Intrinsic::fshl ? "fshl" : "fshr";
      u.z = II->getArgOperand(2);
      return u;
    }
  }
  return u;
}

// The operands a step instruction may be a bijection in.
void candidates(const Instruction &I, SmallVectorImpl<const Value *> &out) {
  if (isTheta(&I)) {
    out.push_back(cast<CallInst>(I).getArgOperand(0));
    return;
  }
  if (isa<BinaryOperator>(I)) {
    out.push_back(I.getOperand(0));
    out.push_back(I.getOperand(1));
    return;
  }
  if (auto *un = dyn_cast<UnaryOperator>(&I)) {
    out.push_back(un->getOperand(0));
    return;
  }
  if (auto *II = dyn_cast<IntrinsicInst>(&I))
    if (II->arg_size() >= 1)
      out.push_back(II->getArgOperand(0));
}

struct Matcher {
  LoweringContext &ctx;
  StoreInst &S;
  Form &F;
  const Value *ptr;
  const StoreInst *prevStore;
  Type *U;   // the form's width

  // Is v where the form starts? (the load, a trunc of it, or a forwarded value)
  bool start(const Value *v) {
    if (prevStore && holds(prevStore->getValueOperand(), v)) {
      F.Prev = prevStore;
      F.y = v;
      return true;
    }
    auto *tr = dyn_cast<TruncInst>(v);
    const Value *base = tr ? tr->getOperand(0) : v;
    auto *L = dyn_cast<LoadInst>(base);
    if (!L || L->getPointerOperand() != ptr || L->isVolatile() || L->getType() != F.T || hostAccess(ctx, *L))
      return false;
    if (!tr && F.T != U)
      return false;
    if (tr && (tr->getType() != U || !(tr->hasNoUnsignedWrap() || highBitsZero(*L, U->getIntegerBitWidth()))))
      return false;
    F.L = L;
    F.trunc = tr;
    F.y = v;
    return true;
  }

  // Walks back from v; on success F.y is set and steps are appended first to last.
  bool chain(const Value *v, unsigned depth) {
    if (depth > 64)
      return false;
    if (start(v) && depth > 0)
      return true;
    F.Prev = nullptr;
    F.L = nullptr;
    F.trunc = nullptr;
    F.y = nullptr;
    auto *I = dyn_cast<Instruction>(v);
    if (!I)
      return false;
    if (auto *sel = dyn_cast<SelectInst>(I))
      return choice(*sel, depth);
    SmallVector<const Value *, 2> cand;
    candidates(*I, cand);
    for (const Value *y : cand) {
      Step st;
      st.def = I;
      st.prev = y;
      if (isTheta(I)) {
        st.kind = Step::Theta;
        st.theta = cast<CallInst>(I);
      } else {
        st.a = updateOf(*I, y);
        if (!st.a.op || isa<Constant>(y))
          continue;
      }
      if (!chain(y, depth + 1))
        continue;
      F.steps.push_back(st);
      return true;
    }
    return false;
  }

  // Rule 6: a select whose arms are updates of y or y itself, its condition not reading y.
  bool choice(const SelectInst &sel, unsigned depth) {
    const Value *arms[2] = {sel.getTrueValue(), sel.getFalseValue()};
    SmallVector<const Value *, 2> cand;
    for (const Value *a : arms)
      if (auto *ai = dyn_cast<Instruction>(a))
        candidates(*ai, cand);
    for (const Value *y : cand) {
      Step st;
      st.kind = Step::Choice;
      st.def = &sel;
      st.prev = y;
      st.cond = sel.getCondition();
      bool ok = true;
      Update *slots[2] = {&st.a, &st.b};
      bool anyUpdate = false;
      for (unsigned i = 0; i < 2 && ok; ++i) {
        if (arms[i] == y)
          continue;   // op stays null: y itself
        auto *ai = dyn_cast<Instruction>(arms[i]);
        if (!ai || isTheta(ai) || !ai->hasOneUse()) {
          ok = false;
          break;
        }
        *slots[i] = updateOf(*ai, y);
        ok = slots[i]->op != nullptr;
        st.arms.push_back(ai);
        anyUpdate = true;
      }
      if (!ok || !anyUpdate || !chain(y, depth + 1))
        continue;
      F.steps.push_back(st);
      return true;
    }
    return false;
  }

  // `zext (icmp ne x, y)` of a _Bool cell's load: the step xor_i1 at width i1.
  bool boolXor(const ICmpInst &cmp) {
    const Value *a = cmp.getOperand(0), *b = cmp.getOperand(1);
    for (auto [l, z] : {std::pair{a, b}, std::pair{b, a}}) {
      auto *L = dyn_cast<LoadInst>(l);
      if (!L || L->getPointerOperand() != ptr || L->getType() != F.T || L->isVolatile() || !range01(*L) ||
          hostAccess(ctx, *L))
        continue;
      Step st;
      st.def = &cmp;
      st.prev = L;
      st.a.op = "xor";
      st.a.z = z;
      F.L = L;
      F.y = L;
      F.steps.push_back(st);
      return true;
    }
    return false;
  }

  bool run() {
    const Value *v = S.getValueOperand();
    if (auto *z = dyn_cast<ZExtInst>(v)) {
      if (!z->getSrcTy()->isIntegerTy() || !F.T->isIntegerTy())
        return false;
      U = z->getSrcTy();
      F.zext = z;
      v = z->getOperand(0);
      if (auto *cmp = dyn_cast<ICmpInst>(v); cmp && cmp->getPredicate() == CmpInst::ICMP_NE && U->isIntegerTy(1) &&
                                             !cmp->getOperand(0)->getType()->isIntegerTy(1) &&
                                             cmp->getOperand(0)->getType() == F.T)
        return boolXor(*cmp);
    }
    return chain(v, 0) && !F.steps.empty();
  }
};

// What the steps read besides the chain: the other operands must not read y (rule 6: a bijection for every value of
// the other operands, the condition not reading y).
bool bijectionsHold(const Form &F) {
  SmallPtrSet<const Value *, 8> chain;
  if (F.L)
    chain.insert(F.L);
  if (F.trunc)
    chain.insert(F.trunc);
  if (!isa<Constant>(F.y))
    chain.insert(F.y);
  for (const Step &st : F.steps) {
    SmallVector<const Value *, 4> others;
    if (st.kind == Step::Theta)
      others.push_back(st.theta->getArgOperand(1));
    if (st.a.z)
      others.push_back(st.a.z);
    if (st.b.z)
      others.push_back(st.b.z);
    if (st.cond)
      others.push_back(st.cond);
    for (const Value *o : others) {
      SmallPtrSet<const Value *, 16> seen;
      if (readsAny(o, chain, seen))
        return false;
    }
    chain.insert(st.def);
  }
  return true;
}

bool samePred(const Pred &a, const Pred &b) { return (a & !b).isBottom() && (b & !a).isBottom(); }

std::unique_ptr<Form> matchStore(LoweringContext &ctx, StoreInst &S) {
  if (S.isVolatile() || hostAccess(ctx, S) || !spine::isQ(ctx, S.getValueOperand()))
    return nullptr;
  Type *T = S.getValueOperand()->getType();
  if (!(T->isIntegerTy() || T->isFloatingPointTy()))
    return nullptr;
  auto F = std::make_unique<Form>();
  F->S = &S;
  F->ptr = S.getPointerOperand();
  F->T = T;
  Matcher m{ctx, S, *F, F->ptr, precedingStore(S, F->ptr), T};
  if (!m.run())
    return nullptr;
  F->U = m.U;
  if (!bijectionsHold(*F))
    return nullptr;
  // A cq_theta step fires where the store does (rule 10: the gate is the form's, under the store's predicate).
  const Pred &sp = ctx.preds().block(S.getParent());
  for (const Step &st : F->steps)
    if (st.theta && !samePred(ctx.preds().block(st.theta->getParent()), sp))
      return nullptr;
  if (F->L) {
    SmallVector<const Instruction *, 2> ch;
    changesBetween(ctx, *F->L, S, ch);
    if (!ch.empty())
      return nullptr;   // an update that is not this shape: rule 2's copy, a kept store
  } else {
    changesBetween(ctx, *F->Prev, S, F->changes);
  }
  return F;
}

// S dominates the reader (a phi's: the edge).
bool afterStore(LoweringContext &ctx, const StoreInst &S, const Use &U) {
  DominatorTree &DT = spine::shared(ctx).dt(*S.getFunction());
  auto *I = cast<Instruction>(U.getUser());
  if (auto *P = dyn_cast<PHINode>(I))
    return DT.dominates(&S, P->getIncomingBlock(U)->getTerminator());
  return DT.dominates(&S, I);
}

Plan &plan(LoweringContext &ctx) {
  Function *out = &ctx.out();
  auto &p = plans[out];
  if (p && (Value *)p->out == out && p->orig == ctx.S.F)
    return *p;
  p = std::make_unique<Plan>();
  p->out = out;
  p->orig = ctx.S.F;
  for (Instruction &I : instructions(*const_cast<Function *>(ctx.S.F)))
    if (auto *S = dyn_cast<StoreInst>(&I))
      if (auto F = matchStore(ctx, *S)) {
        p->ofStore[S] = F.get();
        p->forms.push_back(std::move(F));
      }
  DominatorTree &DT = spine::shared(ctx).dt(*ctx.S.F);
  // The first step of the next form on the same pointer reads the previous y' through the cell.
  DenseSet<const Instruction *> nextFirst;
  for (auto &F : p->forms)
    if (F->Prev && p->ofStore.count(F->Prev))
      nextFirst.insert(dyn_cast<Instruction>(F->steps.front().def));

  for (auto &Fp : p->forms) {
    Form &F = *Fp;
    const unsigned n = F.steps.size();
    unsigned ft = n;
    for (unsigned i = 0; i < n; ++i)
      if (F.steps[i].kind == Step::Theta) {
        ft = i;
        break;
      }
    // The uses of a chain value that are not the chain, S, or the next form's first step.
    auto others = [&](const Value *v, const User *next) {
      SmallVector<const Use *, 2> r;
      for (const Use &u : v->uses()) {
        const User *x = u.getUser();
        if (x == next || x == F.S || nextFirst.count(dyn_cast<Instruction>(x)))
          continue;
        r.push_back(&u);
      }
      return r;
    };
    auto nextOf = [&](unsigned i) -> const User * {
      const Value *nx = i + 1 < n ? F.steps[i + 1].def : (F.zext ? static_cast<const Value *>(F.zext) : F.S);
      return cast<User>(nx);
    };
    // Choice steps read y through their arms too.
    auto readsThroughArm = [&](const User *x, unsigned i) {
      if (i + 1 >= n)
        return false;
      return is_contained(F.steps[i + 1].arms, dyn_cast<Instruction>(x));
    };
    auto rest = [&](const Value *v, unsigned i) {
      SmallVector<const Use *, 2> r;
      for (const Use *u : others(v, nextOf(i)))
        if (!readsThroughArm(u->getUser(), i))
          r.push_back(u);
      return r;
    };

    // Before the first cq_theta: another reader reads a plain load taken before the swap-out, the bijections
    // recomputed on that copy. The last value of a chain with no cq_theta read only after the store is rule 5's later
    // reader of y' instead.
    int normalUpTo = -1;   // steps[0..normalUpTo] lowered at their own position; -1 with lowerY: y only
    bool lowerY = false;
    if (F.L) {
      const User *firstReader = F.trunc ? cast<User>(F.trunc) : nullptr;
      for (const Use &u : F.L->uses()) {
        const User *x = u.getUser();
        if (x == firstReader || x == cast<User>(F.steps[0].def) ||
            is_contained(F.steps[0].arms, dyn_cast<Instruction>(x)))
          continue;
        lowerY = true;
      }
      if (F.trunc)
        for (const Use &u : F.trunc->uses()) {
          const User *x = u.getUser();
          if (x == cast<User>(F.steps[0].def) || is_contained(F.steps[0].arms, dyn_cast<Instruction>(x)))
            continue;
          lowerY = true;
        }
    }
    SmallVector<unsigned, 2> ends;
    for (unsigned i = 0; i < n; ++i) {
      SmallVector<const Use *, 2> r = rest(F.steps[i].def, i);
      if (i == n - 1 && F.zext)
        for (const Use &u : F.zext->uses())
          if (u.getUser() != F.S && !nextFirst.count(dyn_cast<Instruction>(u.getUser())))
            r.push_back(&u);
      if (r.empty())
        continue;
      if (i < ft) {
        bool before = any_of(r, [&](const Use *u) { return !afterStore(ctx, *F.S, *u); });
        if (i < n - 1 || before)
          normalUpTo = i;
        else
          ends.push_back(i);
      } else {
        ends.push_back(i);
      }
    }
    if (normalUpTo >= 0)
      lowerY = true;
    if (ends.empty() || ends.back() != n - 1)
      ends.push_back(n - 1);
    F.ends = ends;

    if (F.L && !lowerY) {
      p->claimed.insert(F.L);
      if (F.trunc)
        p->claimed.insert(F.trunc);
    }
    for (unsigned i = 0; i < n; ++i) {
      if (int(i) <= normalUpTo)
        continue;
      if (auto *def = dyn_cast<Instruction>(F.steps[i].def))
        p->claimed.insert(def);
      for (const Instruction *a : F.steps[i].arms)
        p->claimed.insert(a);
    }
    if (F.zext) {
      bool wideBefore = any_of(F.zext->uses(), [&](const Use &u) { return u.getUser() != F.S && !afterStore(ctx, *F.S, u); });
      if (wideBefore && ft == n)
        ;   // lowered at its own position, on the recomputed copy
      else
        p->claimed.insert(F.zext);
    }

    // A part that ends before S with a reader before S is emitted at that step (no bus access may lie between).
    for (unsigned k = 0; k + 1 <= F.ends.size(); ++k) {
      unsigned e = F.ends[k];
      SmallVector<const Use *, 2> r = rest(F.steps[e].def, e);
      bool early = any_of(r, [&](const Use *u) { return !afterStore(ctx, *F.S, *u); });
      if (!early)
        continue;
      auto *def = dyn_cast<Instruction>(F.steps[e].def);
      if (!F.changes.empty())
        stop("rule 5 Readers: a form with changes in its interval that ends at a reader before its store", F.S);
      for (const Instruction *x = def->getNextNode(); x && x != F.S; x = x->getNextNode())
        if (isa<LoadInst>(x) && !hostAccess(ctx, *x))
          stop("the in-place form: a part ends at a reader before the store and a bus load lies between", x);
      if (def->getParent() != F.S->getParent())
        stop("the in-place form: a part ends at a reader in another block than the store", def);
      p->earlyAt[def] = {&F, k};
    }

    // Readers: where the copy of y is taken.
    if (!F.changes.empty()) {
      const Instruction *first = nullptr;
      for (const Instruction *c : F.changes)
        if (!c->isTerminator() && DT.dominates(c, F.S) &&
            all_of(F.changes, [&](const Instruction *o) { return o == c || DT.dominates(c, o); }))
          first = c;
      if (first)
        p->copyBefore[first].push_back(&F);
      else
        p->copyAfter[F.Prev].push_back(&F);
    }
  }
  return *p;
}

// -------------------------------------------------------------------------------------------------------------------
// The raw gates: nothing here is recorded with Uncompute.

struct Raw {
  CallInst *fwd;
  abi::TemplateSpec spec;
  SmallVector<Value *, 3> args;
};

Raw rawTemplate(LoweringContext &ctx, const abi::TemplateSpec &spec, ArrayRef<Operand> ops) {
  FunctionCallee fc = abi::declare(ctx.M, spec, /*unc=*/false);
  FunctionType *ft = fc.getFunctionType();
  if (ft->getNumParams() != ops.size())
    internalError("bus: " + abi::name(spec, false) + " takes another number of arguments");
  SmallVector<Value *, 3> args;
  for (unsigned i = 0; i < ops.size(); ++i) {
    Value *v = ops[i].handle ? ops[i].v : spine::codeAddressAsInt(ctx.B(), ops[i].v, ft->getParamType(i));
    if (v->getType() != ft->getParamType(i))
      internalError("bus: " + abi::name(spec, false) + " argument of the wrong type", v);
    args.push_back(v);
  }
  return Raw{ctx.B().CreateCall(fc, args), spec, args};
}

void rawUnc(LoweringContext &ctx, const Raw &r) {
  SmallVector<Value *, 4> args{r.fwd};
  args.append(r.args.begin(), r.args.end());
  ctx.B().CreateCall(abi::declare(ctx.M, r.spec, /*unc=*/true), args);
}

void freeRail(LoweringContext &ctx, Value *h) { ctx.emitCore(abi::CoreSpec{abi::Core::Free}, {h}); }

Operand zOperand(LoweringContext &ctx, const Value *z, Type *U) {
  // At a narrower width than z's own (xor_i1 of two _Bool cells): the view's rail, a zext's source, the literal.
  if (z->getType() != U) {
    spine::Shared &sh = spine::shared(ctx);
    if (auto *c = dyn_cast<ConstantInt>(z))
      return Operand{ConstantInt::get(U, c->getValue().trunc(U->getIntegerBitWidth())), false};
    if (auto it = sh.views.find(z); it != sh.views.end())
      return Operand{it->second.rail, true};
    if (auto *zx = dyn_cast<ZExtInst>(z); zx && zx->getSrcTy() == U)
      return ctx.operand(zx->getOperand(0));
    stop("the in-place form: an operand with no value at the form's width", z);
  }
  return ctx.operand(z);
}

abi::TemplateSpec spec2(const char *op, RailType w, const char *shape) {
  abi::TemplateSpec s;
  s.op = op;
  s.w = w;
  s.shape = shape;
  return s;
}

// y' = u(y, z), or y = u^-1(y', z) with inverse set. Templates are appended to log.
Value *applyUpdate(LoweringContext &ctx, const Update &u, Value *y, Type *U, bool inverse, SmallVectorImpl<Raw> &log,
                   bool recorded = false) {
  if (!u.op)
    return y;
  RailType w = railTypeOf(U);
  StringRef op = u.op;
  auto emit = [&](const abi::TemplateSpec &s, ArrayRef<Operand> ops) -> Value * {
    if (recorded)
      return ctx.emitTemplate(s, ops);
    log.push_back(rawTemplate(ctx, s, ops));
    return log.back().fwd;
  };
  Operand Y{y, true};
  if (op == "fneg" || op == "bswap" || op == "bitreverse")
    return emit(spec2(u.op, w, ""), {Y});
  if (op == "fshl" || op == "fshr") {
    const char *o = (op == "fshl") != inverse ? "fshl" : "fshr";
    Operand s = ctx.operand(u.z);
    return emit(spec2(o, w, s.handle ? "" : "qql"), {Y, Y, s});
  }
  if (op == "mul") {
    APInt k = cast<ConstantInt>(u.z)->getValue();
    if (inverse)
      k = k.multiplicativeInverse();
    return emit(spec2("mul", w, "hl"), {Y, Operand{ConstantInt::get(U, k), false}});
  }
  Operand z = zOperand(ctx, u.z, U);
  const char *hlShape = z.handle ? "" : "hl";
  if (op == "add")
    return emit(spec2(inverse ? "sub" : "add", w, hlShape), {Y, z});
  if (op == "xor")
    return emit(spec2("xor", w, hlShape), {Y, z});
  // sub
  if (u.yFirst)
    return emit(spec2(inverse ? "add" : "sub", w, hlShape), {Y, z});
  return emit(spec2("sub", w, z.handle ? "" : "lh"), {z, Y});
}

Value *selectRaw(LoweringContext &ctx, Value *c, Value *a, Value *b, Type *U, SmallVectorImpl<Raw> &log) {
  log.push_back(rawTemplate(ctx, spec2("select", railTypeOf(U), ""), {Operand{c, true}, Operand{a, true}, Operand{b, true}}));
  return log.back().fwd;
}

// Rule 5 (under a quantum predicate) and rule 6: the update with the clean of the previous rail; returns the new rail.
// 212: forward templates, the composite under c, its garbage undone (it reads the old rail), then the inverse, the copy,
// the inverse undone, the old rail freed.
Value *updateAndClean(LoweringContext &ctx, const Step &st, Value *cur, Type *U, Value *c) {
  RailType w = railTypeOf(U);
  // A classical select condition is a seed for the composite (rule 7).
  Value *k = nullptr, *seed = nullptr;
  if (st.kind == Step::Choice) {
    Operand co = ctx.operand(st.cond);
    k = co.v;
    if (!co.handle) {
      seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {co.v});
      k = seed;
    }
  }
  SmallVector<Raw, 4> F, I;
  Value *y1;
  if (st.kind == Step::Choice) {
    Value *a = applyUpdate(ctx, st.a, cur, U, false, F), *b = applyUpdate(ctx, st.b, cur, U, false, F);
    y1 = selectRaw(ctx, k, a, b, U, F);
  } else {
    y1 = applyUpdate(ctx, st.a, cur, U, false, F);
  }
  Value *yp = c ? selectRaw(ctx, c, y1, cur, U, F) : y1;
  for (unsigned i = F.size() - 1; i-- > 0;) {
    rawUnc(ctx, F[i]);
    freeRail(ctx, F[i].fwd);
  }
  Value *t0;
  if (st.kind == Step::Choice) {
    Value *a = applyUpdate(ctx, st.a, yp, U, true, I), *b = applyUpdate(ctx, st.b, yp, U, true, I);
    t0 = selectRaw(ctx, k, a, b, U, I);
  } else {
    t0 = applyUpdate(ctx, st.a, yp, U, true, I);
  }
  Value *t = c ? selectRaw(ctx, c, t0, yp, U, I) : t0;
  ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {t, cur});
  for (unsigned i = I.size(); i-- > 0;) {
    rawUnc(ctx, I[i]);
    freeRail(ctx, I[i].fwd);
  }
  freeRail(ctx, cur);
  if (seed)
    freeRail(ctx, seed);
  return yp;
}

void rotate(LoweringContext &ctx, const CallInst &T, Value *h, Type *U, Value *c) {
  Operand angle = ctx.operand(T.getArgOperand(1));
  abi::CoreSpec spec{angle.handle ? abi::Core::RyQAngle : abi::Core::Ry, railTypeOf(U), /*ctl=*/c != nullptr};
  SmallVector<Value *, 3> args;
  if (c)
    args.push_back(c);
  args.append({h, angle.v});
  ctx.emitCore(spec, args);
}

void swapCell(LoweringContext &ctx, Type *U, Operand addr, Value *h, Value *c) {
  abi::CoreSpec spec{abi::Core::QramSwap, railTypeOf(U), /*ctl=*/c != nullptr, /*hl=*/!addr.handle};
  SmallVector<Value *, 4> args;
  if (c)
    args.push_back(c);
  args.append({mem(ctx), addr.v, h});
  ctx.emitCore(spec, args);
}

// One form: steps [from, to) on the cell.
void emitSteps(LoweringContext &ctx, const Form &F, unsigned from, unsigned to, Operand addr, Value *c) {
  LLVMContext &C = ctx.M.getContext();
  CallInst *h = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(F.U)}, {Constant::getNullValue(irTypeOf(C, railTypeOf(F.U)))});
  ctx.unc().noteVersionChange(h);
  swapCell(ctx, F.U, addr, h, c);
  Value *cur = h;
  for (unsigned i = from; i < to; ++i) {
    const Step &st = F.steps[i];
    if (st.kind == Step::Theta)
      rotate(ctx, *st.theta, cur, F.U, c);
    else
      cur = updateAndClean(ctx, st, cur, F.U, c);
  }
  swapCell(ctx, F.U, addr, cur, c);
  freeRail(ctx, cur);
}

// Does a value of the chain have a reader the next form's step, or S, does not account for?
bool hasReader(const Form &F, const Value *v, const Plan &P) {
  for (const User *u : v->users()) {
    if (u == F.S || u == F.zext)
      continue;
    if (auto *I = dyn_cast<Instruction>(u)) {
      bool chain = any_of(F.steps, [&](const Step &st) { return st.def == I || is_contained(st.arms, I); });
      if (chain)
        continue;
      bool next = any_of(P.forms, [&](const std::unique_ptr<Form> &o) {
        return o->Prev && o->Prev == F.S && o->steps.front().def == I;
      });
      if (next)
        continue;
    }
    return true;
  }
  return false;
}

// The plain load after the swap-in that a later reader reads (rule 5, Readers: at the form's width), bound.
void bindReaders(LoweringContext &ctx, const Form &F, const Plan &P, unsigned e, Operand addr) {
  const Value *v = F.steps[e].def;
  if (hasReader(F, v, P))
    spine::bindOperand(ctx, v, Operand{emitLoad(ctx, F.U, addr), true});
  if (e + 1 == F.steps.size() && F.zext && hasReader(F, F.zext, P))
    spine::bindOperand(ctx, F.zext, Operand{emitLoad(ctx, F.T, addr), true});
}

void emitPart(LoweringContext &ctx, Form &F, const Plan &P, unsigned k) {
  unsigned e = F.ends[k];
  if (F.emitted > e)
    return;
  Operand addr = address(ctx, F.ptr);
  Value *c = accessControl(ctx);
  emitSteps(ctx, F, F.emitted, e + 1, addr, c);
  F.emitted = e + 1;
  bindReaders(ctx, F, P, e, addr);
}

// -------------------------------------------------------------------------------------------------------------------
// Readers: the test d, the copy, the second branch.

Value *cellsDisjoint(IRBuilder<> &B, Value *p, uint64_t Sp, Value *q, uint64_t Sq) {
  Type *I64 = p->getType();
  Value *a = B.CreateICmpUGE(B.CreateSub(q, p), ConstantInt::get(I64, Sp));
  Value *b = B.CreateICmpUGE(B.CreateSub(p, q), ConstantInt::get(I64, Sq));
  return B.CreateAnd(a, b);
}

// The cells a change touches at a classical address, nullptr when the change is of another kind or its address is a
// rail or not computed yet.
std::optional<std::pair<Value *, uint64_t>> changeCells(LoweringContext &ctx, const Plan &P, const Instruction &ch,
                                                        const Instruction &at) {
  auto *St = dyn_cast<StoreInst>(&ch);
  if (!St || St->isVolatile() || hostAccess(ctx, *St))
    return std::nullopt;
  const Value *q = St->getPointerOperand();
  DominatorTree &DT = spine::shared(ctx).dt(*St->getFunction());
  if (auto *qi = dyn_cast<Instruction>(q); qi && qi != &at && !DT.dominates(qi, &at))
    return std::nullopt;
  Operand a = address(ctx, q);
  if (a.handle)
    return std::nullopt;
  const DataLayout &DL = ctx.M.getDataLayout();
  Type *w = St->getValueOperand()->getType();
  if (auto fi = P.ofStore.find(St); fi != P.ofStore.end())
    w = fi->second->U;
  return std::make_pair(a.v, uint64_t(DL.getTypeStoreSize(w)));
}

void takeCopy(LoweringContext &ctx, Form &F, const Plan &P, const Instruction &at, bool before) {
  IRBuilder<> &B = ctx.B();
  const DataLayout &DL = ctx.M.getDataLayout();
  F.d = nullptr;
  F.copied = true;
  Operand addr{nullptr, false};
  bool computed = true;
  DominatorTree &DT = spine::shared(ctx).dt(*at.getFunction());
  if (auto *pi = dyn_cast<Instruction>(F.ptr); pi && !DT.dominates(pi, &at))
    computed = false;
  if (computed)
    addr = address(ctx, F.ptr);
  else
    stop("rule 5 Readers: the address of the form is not computed at the first change of its interval", &at);
  Value *d = nullptr;
  if (!addr.handle && before) {
    uint64_t Sp = DL.getTypeStoreSize(F.U);
    SmallVector<std::pair<Value *, uint64_t>, 2> cells;
    bool all = true;
    for (const Instruction *ch : F.changes) {
      auto c = changeCells(ctx, P, *ch, at);
      if (!c) {
        all = false;
        break;
      }
      cells.push_back(*c);
    }
    if (all)
      for (auto &[q, Sq] : cells) {
        Value *t = cellsDisjoint(B, addr.v, Sp, q, Sq);
        d = d ? B.CreateAnd(d, t) : t;
      }
  }
  F.copyAddr = addr;
  F.copyCtl = accessControl(ctx);
  if (!d) {
    F.copy = emitLoad(ctx, F.U, addr);
    return;
  }
  // `br d` around the plain load; its handle reaches the second branch through a classical phi, poison where d = 1.
  LLVMContext &C = ctx.M.getContext();
  Function &out = ctx.out();
  BasicBlock *from = B.GetInsertBlock();
  BasicBlock *over = BasicBlock::Create(C, "", &out);
  BasicBlock *join = BasicBlock::Create(C, "", &out);
  B.CreateCondBr(d, join, over);
  B.SetInsertPoint(over);
  Value *m = mem(ctx);
  Value *ctl = F.copyCtl;
  abi::CoreSpec spec{abi::Core::QramLoad, railTypeOf(F.U), /*ctl=*/ctl != nullptr, /*hl=*/true};
  SmallVector<Value *, 3> args;
  if (ctl)
    args.push_back(ctl);
  args.append({m, addr.v});
  CallInst *load = ctx.emitCore(spec, args);
  B.CreateBr(join);
  B.SetInsertPoint(join);
  PHINode *phi = B.CreatePHI(load->getType(), 2);
  phi->addIncoming(PoisonValue::get(load->getType()), from);
  phi->addIncoming(load, over);
  F.d = d;
  F.copy = phi;
}

// The steps act on the copy (rule 2) and the store is a kept store. Returns the rail of y'.
Value *stepsOnCopy(LoweringContext &ctx, Form &F, Value *copy, bool phiCopy) {
  Value *c = accessControl(ctx);
  Value *cur = copy;
  RailId cid = phiCopy ? ctx.unc().recordExternal(copy, Role::Overtaken) : ctx.unc().idOf(copy);
  bool rotated = false;
  for (const Step &st : F.steps) {
    if (st.kind == Step::Theta) {
      rotate(ctx, *st.theta, cur, F.U, c);
      if (cur == copy) {
        rotated = true;
        if (phiCopy)
          ctx.unc().setRole(cid, Role::Frozen);
        else
          ctx.unc().freezeLoadCopy(cid);
      } else {
        ctx.unc().setRole(ctx.unc().idOf(cur), Role::Frozen);
      }
      ctx.unc().noteNonDiagonal(ctx.unc().idOf(cur), cast<CallInst>(&*std::prev(ctx.B().GetInsertPoint())));
    } else if (st.kind == Step::Single) {
      SmallVector<Raw, 1> none;
      cur = applyUpdate(ctx, st.a, cur, F.U, false, none, /*recorded=*/true);
    } else {
      stop("rule 5 Readers: a select step on the copy of y", st.def);
    }
  }
  emitKeptStore(ctx, F.U, F.copyAddr, Operand{cur, true});
  if (phiCopy && !rotated && cur != copy) {
    // A copy nothing rotated is un-copied after its reader and, overtaken, not freed (rule 5 sentence 1).
    SmallVector<Value *, 4> args{copy};
    if (F.copyCtl)
      args.push_back(F.copyCtl);
    args.append({mem(ctx), F.copyAddr.v});
    abi::CoreSpec spec{abi::Core::QramLoad, railTypeOf(F.U), F.copyCtl != nullptr, !F.copyAddr.handle, /*unc=*/true};
    ctx.emitCore(spec, args);
  }
  return cur;
}

void lowerWithChanges(LoweringContext &ctx, Form &F, const Plan &P) {
  if (F.ends.size() != 1)
    stop("rule 5 Readers: a form with changes in its interval that ends at a reader", F.S);
  if (!F.copied || !F.copy)
    internalError("bus: a form's store reached before the copy of its interval", F.S);
  F.copied = false;
  IRBuilder<> &B = ctx.B();
  const Value *last = F.steps.back().def;
  bool reader = hasReader(F, last, P);
  if (!F.d) {
    Value *r = stepsOnCopy(ctx, F, F.copy, /*phiCopy=*/false);
    if (reader)
      spine::bindOperand(ctx, last, Operand{r, true});
    return;
  }
  LLVMContext &C = ctx.M.getContext();
  Function &out = ctx.out();
  BasicBlock *form = BasicBlock::Create(C, "", &out);
  BasicBlock *over = BasicBlock::Create(C, "", &out);
  BasicBlock *join = BasicBlock::Create(C, "", &out);
  B.CreateCondBr(F.d, form, over);
  B.SetInsertPoint(form);
  Operand addr = address(ctx, F.ptr);
  emitSteps(ctx, F, 0, F.steps.size(), addr, accessControl(ctx));
  Value *loaded = reader ? emitLoad(ctx, F.U, addr) : nullptr;
  BasicBlock *formEnd = B.GetInsertBlock();
  BranchInst *br1 = B.CreateBr(join);
  B.SetInsertPoint(over);
  Value *r = stepsOnCopy(ctx, F, F.copy, /*phiCopy=*/true);
  BasicBlock *overEnd = B.GetInsertBlock();
  BranchInst *br2 = B.CreateBr(join);
  ctx.unc().flushBefore(br2);
  (void)br1;
  B.SetInsertPoint(join);
  if (reader) {
    PHINode *phi = B.CreatePHI(r->getType(), 2);
    phi->addIncoming(loaded, formEnd);
    phi->addIncoming(r, overEnd);
    ctx.unc().recordMerge(phi);
    spine::bindOperand(ctx, last, Operand{phi, true});
  }
  // Rule 5 sentence 1: a load copy only the steps read (an angle, an operand) is un-copied here, past the two arms that
  // read it, not left to a later flush: the arms are one trip of a classical loop like any other code.
  SmallVector<RailId, 2> done;
  DominatorTree &DT = spine::shared(ctx).dt(*F.S->getFunction());
  auto consider = [&](const Value *orig) {
    if (!orig || isa<Constant>(orig) || !ctx.bound(orig))
      return;
    if (!all_of(orig->users(), [&](const User *u) {
          auto *I = dyn_cast<Instruction>(u);
          return I && (DT.dominates(I, F.S) || any_of(F.steps, [&](const Step &st) { return st.def == I; }));
        }))
      return;
    Operand o = ctx.operand(orig);
    auto *lc = o.handle ? dyn_cast<CallInst>(o.v) : nullptr;
    if (!lc || !lc->getCalledFunction() || !lc->getCalledFunction()->getName().starts_with("cqrt_qram_load_"))
      return;
    for (const User *u : lc->users()) {
      auto *g = dyn_cast<CallInst>(u);
      const Function *G = g ? g->getCalledFunction() : nullptr;
      if (!G || !(g->getParent() == form || g->getParent() == over) ||
          !(G->getName().starts_with("cqrt_") || G->getName().starts_with("cq_template_")))
        return;
    }
    if (ctx.unc().liveRole(ctx.unc().idOf(lc)))
      done.push_back(ctx.unc().idOf(lc));
  };
  for (const Step &st : F.steps) {
    if (st.theta)
      consider(st.theta->getArgOperand(1));
    consider(st.a.z);
  }
  if (!done.empty()) {
    Instruction *at = cast<Instruction>(B.CreateFreeze(PoisonValue::get(B.getInt1Ty())));
    ctx.unc().resolveAt(at, done);
    at->eraseFromParent();
    B.SetInsertPoint(join);
  }
}

} // namespace

// -------------------------------------------------------------------------------------------------------------------

bool inPlaceBefore(LoweringContext &ctx, Instruction &I) {
  if (I.getFunction() != ctx.S.F)
    return false;
  Plan &P = plan(ctx);
  if (auto it = P.copyBefore.find(&I); it != P.copyBefore.end())
    for (Form *F : it->second)
      takeCopy(ctx, *F, P, I, /*before=*/true);
  if (auto it = P.earlyAt.find(&I); it != P.earlyAt.end()) {
    emitPart(ctx, *it->second.first, P, it->second.second);
    return true;
  }
  return P.claimed.count(&I) != 0;
}

void inPlaceAfter(LoweringContext &ctx, Instruction &I) {
  if (I.getFunction() != ctx.S.F)
    return;
  Plan &P = plan(ctx);
  if (auto it = P.copyAfter.find(&I); it != P.copyAfter.end())
    for (Form *F : it->second)
      takeCopy(ctx, *F, P, I, /*before=*/false);
}

bool isInPlaceForm(LoweringContext &ctx, const StoreInst &S) {
  if (S.getFunction() != ctx.S.F)
    return false;
  return plan(ctx).ofStore.count(&S) != 0;
}

void lowerInPlace(LoweringContext &ctx, StoreInst &S) {
  Plan &P = plan(ctx);
  Form &F = *P.ofStore.lookup(&S);
  if (!F.changes.empty())
    return lowerWithChanges(ctx, F, P);
  for (unsigned k = 0; k < F.ends.size(); ++k)
    emitPart(ctx, F, P, k);
  F.emitted = 0;   // a loop body lowered again
}

// Rule 4: an add, sub or xor is the in-place form, its result a plain load before the swap-out.
void lowerInPlaceRMW(LoweringContext &ctx, AtomicRMWInst &R) {
  Type *T = R.getValOperand()->getType();
  Operand addr = address(ctx, R.getPointerOperand());
  if (!R.use_empty())
    spine::bindOperand(ctx, &R, Operand{emitLoad(ctx, T, addr), true});
  Form F;
  F.U = F.T = T;
  Step st;
  st.def = &R;
  st.a.z = R.getValOperand();
  switch (R.getOperation()) {
  case AtomicRMWInst::Add: st.a.op = "add"; break;
  case AtomicRMWInst::Sub: st.a.op = "sub"; break;
  case AtomicRMWInst::Xor: st.a.op = "xor"; break;
  default: internalError("bus: lowerInPlaceRMW of another operation", &R);
  }
  F.steps.push_back(st);
  emitSteps(ctx, F, 0, 1, addr, accessControl(ctx));
}

// Rule 5 Width casts: a load of a _Bool cell used as i1 is one access at i1. Every reader is a trunc to i1 (nuw, or the
// range fact), or an equality compare with a value readable at i1.
bool isBoolCellLoad(LoweringContext &ctx, const LoadInst &L) {
  SmallPtrSet<const LoadInst *, 4> visiting;
  std::function<bool(const LoadInst &)> test = [&](const LoadInst &X) -> bool {
    if (!X.getType()->isIntegerTy(8) || X.isVolatile() || X.use_empty())
      return false;
    if (!visiting.insert(&X).second)
      return true;
    bool range = range01(X);
    for (const Use &U : X.uses()) {
      const User *u = U.getUser();
      if (auto *t = dyn_cast<TruncInst>(u)) {
        if (!t->getType()->isIntegerTy(1) || !(t->hasNoUnsignedWrap() || range))
          return false;
        continue;
      }
      auto *cmp = dyn_cast<ICmpInst>(u);
      if (!cmp || !cmp->isEquality() || !range)
        return false;
      const Value *o = cmp->getOperand(1 - U.getOperandNo());
      if (auto *c = dyn_cast<ConstantInt>(o)) {
        if (c->getValue().getActiveBits() > 1)
          return false;
        continue;
      }
      if (auto *ol = dyn_cast<LoadInst>(o)) {
        if (hostAccess(ctx, *ol) || !test(*ol))
          return false;
        continue;
      }
      if (!spine::narrowUse(ctx, U, 1))
        return false;
    }
    return true;
  };
  return !hostAccess(ctx, L) && test(L);
}

void lowerBoolCellLoad(LoweringContext &ctx, LoadInst &L) {
  Type *I1 = Type::getInt1Ty(ctx.M.getContext());
  CallInst *h = emitLoad(ctx, I1, address(ctx, L.getPointerOperand()));
  spine::shared(ctx).views[&L] = spine::Shared::View{h, 1, /*cell=*/true};
  spine::bindOperand(ctx, &L, Operand{h, true});
}

} // namespace cq::bus
