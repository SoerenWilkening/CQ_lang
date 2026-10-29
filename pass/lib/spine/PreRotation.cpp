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
//    yet (a lazy reader such as fatptr's deriveGEP or a value -O1 sank, which reads w when it is
//    finally emitted). The operand v needing it gets the copy; any other value bound to h needing it
//    is cq::unimplemented. No use after T: nothing is emitted (the common case is unchanged).
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

// Does w have a use after P (see the contract)? skip: P itself when it reads w.
const Instruction *useAfter(Shared &sh, const Value *w, const Instruction *P, const DenseSet<const BasicBlock *> &reach) {
  for (const Use &U : w->uses()) {
    auto *I = dyn_cast<Instruction>(U.getUser());
    if (!I || I == P)
      continue;
    if (auto *phi = dyn_cast<PHINode>(I)) {
      if (isAfter(P, reach, phi->getIncomingBlock(U)->getTerminator()))
        return I;
      continue;
    }
    if (isAfter(P, reach, I))
      return I;
    if (!I->getType()->isVoidTy() && !sh.binds.count(I))
      return I;   // not lowered yet: a lazy reader reads w when it is emitted
  }
  return nullptr;
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
  const Instruction *u = useAfter(sh, v, &T, reach);
  if (!u)
    return std::nullopt;
  if (cyclic)
    unimplemented("spine: the pre-rotation value of an in-place cq_theta is read after it (by " + describe(u) +
                      ") inside a cycle where the value is invariant (cq-s32y)",
                  &T);

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
  auto *phi = dyn_cast_or_null<PHINode>(sh.cur);
  const Shared::PreRot &r = it->second;
  if (!phi || phi->getFunction() != r.T->getFunction())
    return bound;
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
