// Module eff-conc (CR rule 24, 101): setjmp/longjmp, a longjmp under a quantum predicate.
//
// A longjmp under a quantum predicate is a multi-frame predicated early return (101's header): the
// callee's clone computes the predicate of its longjmp block as an ESCAPED flag beside its result and
// returns {result, escaped}; at the setjmp site the two continuations merge on that flag. The host
// setjmp and longjmp are never executed; jb is a classical object nothing writes.
//
// Built (the IR class, explicit boundaries; everything else is cq::unimplemented):
//  - The clone (cloneEscapes): a non-entry specialization whose body calls longjmp/_longjmp/siglongjmp
//    under a quantum predicate (calls::Class::Longjmp). Exactly one such call, followed by `unreachable`,
//    outside any loop unit, under no classical factor; every longjmp of the body is that one; one return.
//    No other instruction of the body may have a side effect, and no call other than a side-effect-free
//    intrinsic (cq-jwdf: pred takes the longjmp block for a dead end, so the code after its branch runs
//    under the predicate before it, not under !escaped: only pure values, which are merged away at the
//    setjmp, may run there). jb is a classical pointer to a global; every use of the clone's function is
//    a direct call in the normal arm of a setjmp diamond on the same object.
//    lowerLongjmp emits no host call: escaped = cqrt_alloc_i1(false); cqrt_copy_i1(flag, escaped), the
//    flag being the longjmp block's quantum predicate (currentFlag), escaped a Role::Result rail returned
//    as the clone's last field (calls::materialize, Walker::emitCloneReturn). The twin XORs it out as any
//    copied-out field (calls::finalize).
//  - The setjmp site (setjmpDiamond): head ends in `br (icmp eq|ne (setjmp(jb), 0)), ...` (the setjmp
//    call and the icmp in head, each with that one use); the zero edge goes to `normal`, a block whose
//    only predecessor is head, ending in `br join`; the other edge goes straight to join, whose
//    predecessors are exactly head and normal. normal holds exactly one call whose clone escapes; nothing
//    after it in normal has a side effect (they run when the callee escaped too). The walker emits no
//    setjmp and no icmp, lowers normal under head's predicate (the first return always runs it), and
//    lowers each phi of join as select(escaped, value from head, value from normal). A setjmp result read
//    elsewhere, a longjmp argument that would be read (setjmp's result reaches only the test with 0, which
//    longjmp's argument cannot pass: C17 7.13.2.1), an escaped continuation with a block of its own, an
//    escaping call in a nested frame (the caller's own escaped flag): unimplemented.
#include "Setjmp.h"
#include "../../spine/SpineInternal.h"

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Effects.h"
#include "cq/Predicate.h"
#include "cq/Uncompute.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq::conc {
namespace {

bool isLongjmpName(StringRef n) { return n == "longjmp" || n == "_longjmp" || n == "siglongjmp"; }

bool callsLongjmp(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  return G && G->isDeclaration() && isLongjmpName(G->getName());
}

bool returnsTwice(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  return CB.hasFnAttr(Attribute::ReturnsTwice) || (G && G->hasFnAttribute(Attribute::ReturnsTwice));
}

// The shape of a setjmp test at head, without the specialization's classification: the setjmp call, the
// icmp, the normal arm and the join. nullopt when head's terminator does not test a returns_twice call.
struct Shape {
  const CallBase *sj;
  const ICmpInst *cmp;
  const BasicBlock *normal, *join;
};
std::optional<Shape> shapeOf(const BasicBlock &H) {
  auto *br = dyn_cast<BranchInst>(H.getTerminator());
  if (!br || !br->isConditional())
    return std::nullopt;
  auto *cmp = dyn_cast<ICmpInst>(br->getCondition());
  if (!cmp)
    return std::nullopt;
  const CallBase *sj = nullptr;
  unsigned side = 0;
  for (unsigned k = 0; k < 2 && !sj; ++k)
    if (auto *c = dyn_cast<CallBase>(cmp->getOperand(k)); c && returnsTwice(*c)) {
      sj = c;
      side = k;
    }
  if (!sj)
    return std::nullopt;
  auto *zero = dyn_cast<ConstantInt>(cmp->getOperand(1 - side));
  if (!cmp->isEquality() || !zero || !zero->isZero())
    unimplemented("eff-conc: a setjmp result tested other than by == 0 or != 0 (rule 24: setjmp's value on the "
                  "second return is longjmp's argument)",
                  cmp);
  if (sj->getParent() != &H || cmp->getParent() != &H || !sj->hasOneUse() || !cmp->hasOneUse())
    unimplemented("eff-conc: a setjmp whose result or test is read other than by its block's branch (rule 24)", sj);
  const BasicBlock *normal = br->getSuccessor(cmp->getPredicate() == CmpInst::ICMP_EQ ? 0 : 1);
  const BasicBlock *other = br->getSuccessor(cmp->getPredicate() == CmpInst::ICMP_EQ ? 1 : 0);
  auto *nbr = dyn_cast<BranchInst>(normal->getTerminator());
  if (normal == other || normal->getSinglePredecessor() != &H || !nbr || nbr->isConditional() ||
      nbr->getSuccessor(0) != other)
    unimplemented("eff-conc: a setjmp diamond whose first-return arm is not one block branching to the join "
                  "(rule 24)",
                  sj);
  unsigned preds = 0;
  for (const BasicBlock *p : predecessors(other)) {
    ++preds;
    if (p != &H && p != normal)
      unimplemented("eff-conc: a setjmp diamond whose join has another predecessor (rule 24)", sj);
  }
  if (preds != 2)
    unimplemented("eff-conc: a setjmp diamond whose join is not reached once from each arm (rule 24)", sj);
  return Shape{sj, cmp, normal, other};
}

const GlobalVariable *jmpBufObject(const Value *jb, const Instruction *at) {
  auto *g = dyn_cast<GlobalVariable>(getUnderlyingObject(jb));
  if (!g)
    unimplemented("eff-conc: a jmp_buf that is not a global object (rule 24)", at);
  return g;
}

bool sideEffectFree(const Instruction &I) {
  if (isa<DbgInfoIntrinsic>(I))
    return true;
  if (auto *ii = dyn_cast<IntrinsicInst>(&I))
    if (ii->getIntrinsicID() == Intrinsic::lifetime_start || ii->getIntrinsicID() == Intrinsic::lifetime_end)
      return true;
  if (isa<CallBase>(I) && !isa<IntrinsicInst>(I))
    return false;
  return !I.mayHaveSideEffects();
}

} // namespace

bool cloneEscapes(const TaintInfo &T, const Specialization &S) {
  if (S.isEntry() || !S.F || S.F->isDeclaration())
    return false;
  for (const Instruction &I : instructions(*S.F))
    if (auto *CB = dyn_cast<CallBase>(&I); CB && callsLongjmp(*CB) &&
                                           calls::classify(*CB, T, S) == calls::Class::Longjmp)
      return true;
  return false;
}

std::optional<SetjmpDiamond> setjmpDiamond(LoweringContext &ctx, const BasicBlock &H) {
  std::optional<Shape> sh = shapeOf(H);
  if (!sh)
    return std::nullopt;
  jmpBufObject(sh->sj->getArgOperand(0), sh->sj);
  if (sh->sj->arg_size() < 1 || ctx.T.isQuantum(sh->sj->getArgOperand(0), ctx.S))
    unimplemented("eff-conc: a setjmp on a quantum jmp_buf pointer (rule 24)", sh->sj);
  const CallBase *call = nullptr;
  for (const Instruction &I : *sh->normal) {
    auto *CB = dyn_cast<CallBase>(&I);
    if (call && !sideEffectFree(I))
      unimplemented("eff-conc: an effect after the escaping call in a setjmp's first-return arm (rule 24: it "
                    "runs only when the callee did not escape; a !escaped guard is not built)",
                    &I);
    if (!CB || calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Lift)
      continue;
    const Specialization *cs = ctx.T.calleeSpecialization(*CB, ctx.S);
    if (!cs || !cloneEscapes(ctx.T, *cs))
      continue;
    if (cs->ctl)
      unimplemented("eff-conc: an escaping clone called as a _ctl clone in a setjmp's first-return arm (rule 24: "
                    "its body has effects, which would run under the predicate before the longjmp's branch, cq-jwdf)",
                    CB);
    if (call)
      unimplemented("eff-conc: two escaping calls in a setjmp's first-return arm (rule 24: the second runs under "
                    "!escaped)",
                    CB);
    call = CB;
  }
  if (!call)
    unimplemented("eff-conc: a setjmp diamond in a lowered function whose first-return arm calls no clone that "
                  "escapes by longjmp under a quantum predicate (rule 24: a classical longjmp to it, or one "
                  "reached otherwise)",
                  sh->sj);
  for (const PHINode &phi : sh->join->phis())
    if (!phi.getType()->isIntegerTy() && !phi.getType()->isFloatingPointTy())
      unimplemented("eff-conc: a setjmp join phi of a non-scalar type (rule 24)", &phi);
  return SetjmpDiamond{sh->sj, sh->cmp, &H, sh->normal, sh->join, call};
}

bool isSetjmpArmCall(LoweringContext &ctx, const CallBase &CB) {
  const BasicBlock *H = CB.getParent()->getSinglePredecessor();
  if (!H)
    return false;
  std::optional<SetjmpDiamond> d = setjmpDiamond(ctx, *H);
  return d && d->normal == CB.getParent() && d->call == &CB;
}

void noteEscapedOut(LoweringContext &ctx, const CallBase &CB, Value *rail) {
  if (!spine::shared(ctx).escapedOut.insert({&CB, rail}).second)
    internalError("eff-conc: the escaped flag of a call recorded twice", &CB);
}

Value *escapedOut(LoweringContext &ctx, const CallBase &CB) { return spine::shared(ctx).escapedOut.lookup(&CB); }

Value *cloneEscapedFlag(LoweringContext &ctx) { return spine::shared(ctx).cloneEscaped; }

void lowerSetjmp(LoweringContext &, CallBase &CB) {
  // The walker lowers the diamond (setjmpDiamond) and never dispatches its setjmp.
  unimplemented("eff-conc: a setjmp outside a setjmp diamond the walker lowers (rule 24, 101)", &CB);
}

void lowerLongjmp(LoweringContext &ctx, CallBase &CB) {
  if (ctx.S.isEntry())
    unimplemented("eff-conc: a longjmp under a quantum predicate in an entry function (rule 24: the escaped "
                  "flag is a clone's result)",
                  &CB);
  if (!callsLongjmp(CB) || CB.arg_size() != 2)
    unimplemented("eff-conc: a noreturn call classified longjmp that is not longjmp(jb, v) (rule 24)", &CB);
  if (ctx.loopUnit())
    unimplemented("eff-conc: a longjmp under a quantum predicate inside a loop (rule 24)", &CB);
  if (!isa<UnreachableInst>(CB.getNextNode()))
    unimplemented("eff-conc: a longjmp not followed by unreachable (rule 24)", &CB);
  if (ctx.operand(CB.getArgOperand(0)).handle)
    unimplemented("eff-conc: a longjmp on a quantum jmp_buf pointer (rule 24)", &CB);
  if (!ctx.preds().block(CB.getParent()).classicalFactor(ctx.T, ctx.S).isTop())
    unimplemented("eff-conc: a longjmp under a classical guard (rule 24: its escaped copy-out would not reach the "
                  "clone's return)",
                  &CB);
  const GlobalVariable *jb = jmpBufObject(CB.getArgOperand(0), &CB);
  const Function &F = *ctx.S.F;
  unsigned rets = 0;
  for (const Instruction &I : instructions(F)) {
    if (isa<ReturnInst>(I))
      ++rets;
    if (&I == &CB || isa<UnreachableInst>(I) || isa<ReturnInst>(I) || isa<BranchInst>(I) || isa<SwitchInst>(I))
      continue;
    if (auto *C = dyn_cast<CallBase>(&I); C && callsLongjmp(*C))
      unimplemented("eff-conc: a clone with several longjmps (rule 24: the escaped flag is their OR)", C);
    if (!sideEffectFree(I))
      unimplemented("eff-conc: an effect or a call in a clone that escapes by longjmp (rule 24; cq-jwdf: the code "
                    "after the longjmp's branch would run under the predicate before it, not under !escaped)",
                    &I);
  }
  if (rets != 1)
    unimplemented("eff-conc: an escaping clone with other than one return (rule 24)", &CB);
  for (const Use &U : F.uses()) {
    auto *C = dyn_cast<CallBase>(U.getUser());
    if (!C || !C->isCallee(&U))
      unimplemented("eff-conc: an escaping function whose address is taken (rule 24)", U.getUser());
    const BasicBlock *H = C->getParent()->getSinglePredecessor();
    std::optional<Shape> sh = H ? shapeOf(*H) : std::nullopt;
    if (!sh || sh->normal != C->getParent())
      unimplemented("eff-conc: a call of an escaping function outside the first-return arm of a setjmp diamond "
                    "(rule 24: nested frames, the caller's own escaped flag)",
                    C);
    if (jmpBufObject(sh->sj->getArgOperand(0), sh->sj) != jb)
      unimplemented("eff-conc: a longjmp to another jmp_buf than its caller's setjmp (rule 24)", &CB);
  }
  Value *flag = ctx.currentFlag();
  if (!flag)
    internalError("eff-conc: a longjmp classified under a quantum predicate with no flag in scope", &CB);
  Value *&slot = spine::shared(ctx).cloneEscaped;
  if (slot)
    internalError("eff-conc: an escaping clone's longjmp lowered twice", &CB);
  RailType w{Kind::Int, 1};
  CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {ConstantInt::getFalse(ctx.M.getContext())});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec cp{abi::Core::Copy, w};
  CallInst *c = ctx.emitCore(cp, {flag, f});
  ctx.unc().recordCore(c, cp, {Operand{flag, true}, Operand{f, true}}, fid);
  ctx.unc().setRole(fid, Role::Result);
  slot = f;
}

} // namespace cq::conc
