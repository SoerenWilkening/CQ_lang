// Module spine (cq-s32y): a register's pre-rotation value read after its in-place rotation.
//
// CONTRACT
//
//  Rule 2 rotates an existing rail in place: cq_theta(v, θ) on v's rail h is an Ry on h, and the
//  cq_theta's result names h. The C program (the §6 oracle, NORTHSTAR p2/p5) still reads v's own
//  value wherever v is used after the cq_theta. Orchestrator decision on cq-s32y (owner may
//  override): such a use reads a copy taken just before the rotation.
//
//  - Need. Before the cq_theta T is lowered (uncontrolled, rule 10 controlled, or rule 15 quantum
//    angle), every value w bound to h is checked for a use after T: a non-phi user lowered after T
//    in the original CFG (reachable from T's end without passing w's definition, which would make it
//    another instance of w), a phi incoming whose edge is so reachable, or a non-phi user not lowered
//    yet that precedes T (a lazy reader such as fatptr's deriveGEP or a value -O1 sank, which reads w
//    when it is finally emitted; cq-drcl: a user in a block T cannot reach, a sibling arm, is no
//    reader after T). The operand v needing it gets the copy; any other value bound to h needing it
//    is cq::unimplemented. No use after T: nothing is emitted (the common case is unchanged).
//  - Classical guards (cq-drcl). The copy is emitted at T. A reader after T whose block's classical
//    factor does not imply T's block's is reached by a path on which T did not run (a classical arm
//    joined): it would need a merge of c and h at the classical join, cq::unimplemented.
//  - Not after T (cq-drcl). An instruction lowered after the rebinding that T does not reach (a
//    sibling arm, quantum or classical) reads h for v: there the rotation did not happen.
//  - Copy. c = cqrt_alloc_<W>(0), copy_<W>(h, c), recorded (recordSeed, recordCore): a Garbage rail
//    that read h, so the Ry's noteNonDiagonal makes it KeptEntangled (A4) unless a later measurement
//    gives it Role::Measured. After the lowering emitted the Ry on h, v is rebound to c: every later
//    operand(v), fatptr's lazy derivations included, reads the pre-rotation value. Classical
//    collapse never reads through the copy to a later outcome of h (Collapse.cpp, cq-nvfi).
//  - Phi edges. A phi lowered after T whose incoming v arrives only on edges not after T reads h
//    (atPhiEdge): there h is unrotated (the merge of a rule 10 controlled rotation names the
//    register h, never a select of h and its copy). Edges of both kinds for v: cq::unimplemented.
//  - Loops. A copy needed while T can reach itself without passing v's definition (v invariant
//    over a cycle around T) is cq::unimplemented: a body lowered once would rotate h on every trip.
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::spine {

namespace {

std::string describe(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

const Function *functionOf(const Value *v) {
  if (auto *I = dyn_cast<Instruction>(v))
    return I->getFunction();
  if (auto *A = dyn_cast<Argument>(v))
    return A->getParent();
  return nullptr;
}

// The original blocks reachable from the end of P's block without passing def's block (the
// definition of the value whose instance is tracked). cyclic: P's block is among them.
DenseSet<const BasicBlock *> reachFrom(const Instruction *P, const Value *def, bool &cyclic) {
  const BasicBlock *db = nullptr;
  if (auto *D = dyn_cast<Instruction>(def))
    db = D->getParent();
  DenseSet<const BasicBlock *> reach;
  SmallVector<const BasicBlock *, 16> work(succ_begin(P->getParent()), succ_end(P->getParent()));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (b == db || !reach.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  cyclic = reach.count(P->getParent());
  return reach;
}

bool isAfter(const Instruction *P, const DenseSet<const BasicBlock *> &reach, const Instruction *point) {
  if (point->getParent() == P->getParent() && point != P && P->comesBefore(point))
    return true;
  return reach.count(point->getParent());
}

// Does I come before P on some path that does not pass def's block after I (I would read another
// instance of def's value otherwise)? I in P's block before P, or P's block reachable from I's.
bool precedes(const Instruction *I, const Instruction *P, const Value *def) {
  if (I->getParent() == P->getParent() && I != P && I->comesBefore(P))
    return true;
  const BasicBlock *db = nullptr;
  if (auto *D = dyn_cast<Instruction>(def))
    db = D->getParent();
  DenseSet<const BasicBlock *> seen;
  SmallVector<const BasicBlock *, 16> work(succ_begin(I->getParent()), succ_end(I->getParent()));
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (b == P->getParent())
      return true;
    if (b == db || !seen.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  return false;
}

// Does w have a use after P (see the contract)? skip: P itself when it reads w. lazy (optional): the
// unlowered readers found, which are emitted at a later reader of theirs.
const Instruction *useAfter(Shared &sh, const Value *w, const Instruction *P, const DenseSet<const BasicBlock *> &reach,
                            SmallVectorImpl<const Instruction *> *all = nullptr) {
  const Instruction *first = nullptr;
  for (const Use &U : w->uses()) {
    auto *I = dyn_cast<Instruction>(U.getUser());
    if (!I || I == P)
      continue;
    bool after;
    if (auto *phi = dyn_cast<PHINode>(I))
      after = isAfter(P, reach, phi->getIncomingBlock(U)->getTerminator());
    else
      // cq-drcl: a user not lowered yet is a lazy reader only when the walk passed it already (it
      // precedes P); one in a block P cannot reach (a sibling arm) is lowered later and reads w's
      // rail where the rotation did not happen (atPhiEdge).
      after = isAfter(P, reach, I) ||
              (!I->getType()->isVoidTy() && !sh.binds.count(I) && precedes(I, P, w));
    if (!after)
      continue;
    if (!first)
      first = I;
    if (!all)
      return first;
    all->push_back(I);
  }
  return first;
}

// The point standing for T in function F: T itself, or the inlined call site in F that leads to it.
const Instruction *pointIn(Shared &sh, const Instruction *T, const Function *F) {
  if (T->getFunction() == F)
    return T;
  for (size_t i = sh.inlineStack.size(); i-- > 0;)
    if (sh.inlineStack[i]->getFunction() == F)
      return sh.inlineStack[i];
  return nullptr;
}

} // namespace

std::optional<PendingCopy> beginPreRotation(LoweringContext &ctx, CallInst &T) {
  if (T.arg_size() != 2)
    internalError("spine: cq_theta with other than two arguments", &T);
  const Value *v = T.getArgOperand(0);
  if (!isQ(ctx, v))
    return std::nullopt;
  Operand x = ctx.operand(v);
  if (!x.handle)
    return std::nullopt;   // a classical value or a measured rail: the rotation mints its own rail
  Shared &sh = shared(ctx);
  Value *h = x.v;

  // Any other value bound to h and read after the rotation would need a copy of its own.
  for (auto &[w, ops] : sh.binds) {
    if (w == v || w == &T || ops.size() != 1 || !ops.front().handle || ops.front().v != h)
      continue;
    const Function *F = functionOf(w);
    const Instruction *P = F ? pointIn(sh, &T, F) : nullptr;
    if (!P)
      continue;
    bool cyc = false;
    DenseSet<const BasicBlock *> r = reachFrom(P, w, cyc);
    if (const Instruction *u = useAfter(sh, w, P, r))
      unimplemented("spine: " + describe(w) + ", bound to the rail cq_theta rotates in place, is read after the "
                        "rotation (by " + describe(u) + ") and is not the cq_theta's operand (cq-s32y)",
                    &T);
  }

  bool cyclic = false;
  DenseSet<const BasicBlock *> reach = reachFrom(&T, v, cyclic);
  SmallVector<const Instruction *, 4> readers;
  const Instruction *u = useAfter(sh, v, &T, reach, &readers);
  if (!u)
    return std::nullopt;
  if (cyclic)
    unimplemented("spine: the pre-rotation value of an in-place cq_theta is read after it (by " + describe(u) +
                      ") inside a cycle where the value is invariant (cq-s32y)",
                  &T);
  // cq-drcl: the copy is emitted at T, so it is available to a reader after T only when every output
  // path to the reader passes T's output block: quantum arms are linearized, a classical branch is
  // not. A reader whose block's classical factor does not imply T's is reached by a path on which T's
  // classical guard failed, where v's value is h unrotated: that needs a merge of c and h at the
  // classical join, which is not built.
  if (T.getFunction() == sh.orig) {
    auto cf = [&](const BasicBlock *b) {
      const Pred &p = ctx.preds().block(b);
      return p.isBottom() ? Pred::bottom() : p.classicalFactor(ctx.T, ctx.S);
    };
    Pred tf = cf(T.getParent());
    for (const Instruction *r : readers)
      if (!(cf(r->getParent()) & !tf).isBottom())
        unimplemented("spine: the pre-rotation value of an in-place cq_theta under a classical guard is read (by " +
                          describe(r) + ") where the guard may not have held: the copy and the rotated rail "
                          "would merge at the classical join (cq-drcl)",
                      &T);
  }

  RailType w = railTypeOf(v->getType());
  CallInst *c = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                             {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
  RailId cid = ctx.unc().recordSeed(c);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *cc = ctx.emitCore(cp, {h, c});
  ctx.unc().recordCore(cc, cp, {Operand{h, true}, Operand{c, true}}, cid);

  PendingCopy pc;
  pc.v = v;
  pc.rec.T = &T;
  pc.rec.h = h;
  pc.rec.c = c;
  pc.rec.reach = std::move(reach);
  return pc;
}

void finishPreRotation(LoweringContext &ctx, std::optional<PendingCopy> &pc) {
  if (!pc)
    return;
  Shared &sh = shared(ctx);
  auto it = sh.binds.find(pc->v);
  if (it == sh.binds.end() || it->second.size() != 1 || it->second.front().v != pc->rec.h)
    internalError("spine: the operand of an in-place cq_theta changed its binding during the rotation", pc->rec.T);
  it->second.assign({Operand{pc->rec.c, true}});
  sh.preRot[pc->v] = std::move(pc->rec);
  pc.reset();
}

Operand atPhiEdge(Shared &sh, const Value *orig, Operand bound) {
  if (!bound.handle)
    return bound;
  auto it = sh.preRot.find(orig);
  if (it == sh.preRot.end() || bound.v != it->second.c)
    return bound;
  const Shared::PreRot &r = it->second;
  if (!sh.cur || sh.cur->getFunction() != r.T->getFunction())
    return bound;
  auto *phi = dyn_cast<PHINode>(sh.cur);
  if (!phi) {
    // cq-drcl: an instruction the rotation does not reach (a sibling arm of the cq_theta, quantum or
    // classical) reads h: on its paths h was not rotated (rule 10's controlled Ry is the identity
    // where its flag is false).
    if (sh.cur != r.T && !isAfter(r.T, r.reach, sh.cur))
      return Operand{r.h, true};
    return bound;
  }
  bool before = false, after = false;
  for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i)
    if (phi->getIncomingValue(i) == orig)
      (isAfter(r.T, r.reach, phi->getIncomingBlock(i)->getTerminator()) ? after : before) = true;
  if (!before)
    return bound;
  if (after)
    unimplemented("spine: a phi takes " + describe(orig) + " both on edges after an in-place rotation of its "
                      "rail and on edges before it (cq-s32y)",
                  phi);
  return Operand{r.h, true};
}

} // namespace cq::spine
