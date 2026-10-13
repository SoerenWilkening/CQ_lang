// SpeculationTwin.cpp — bd dm7f.21: see SpeculationTwin.h.
//
// Why a twin computes the source's value (R2, analytic). The twin is the callee
// with six kinds of edit; by induction over its instructions (in any order its
// CFG executes them) it holds the callee's values on a basis state where the
// source runs the call without UB:
//  1. a `freeze` on a SINK operand (a `noundef` argument, a branch or switch
//     condition, a divisor): defined on a UB-free execution, so the identity;
//  2. a `freeze` on a `ret` operand: a poison result becomes some defined value,
//     a refinement of poison; a dropped return constraint held there too;
//  3. a dropped parameter attribute (`range`, `nofpclass`, `returned`, dm7f.25):
//     dropping one makes no defined value poison. A `range`/`nofpclass` held on a
//     UB-free execution (violated, it is poison, UB under `noundef`). A false
//     `returned` is NOT UB, so nothing may rest on it: the plan tracks a
//     redirected result as possibly poison (a flag proof through it is modulo
//     poison), and the loop bounds are computed with `returned` stripped
//     (round-1 A-F2, TwinTotality.cpp `loopBounds`);
//  4. a divisor guard (dm7f.30), 5. a trip counter (dm7f.27) and 6. `ret <zero>`
//     for an `unreachable` (round-1 A-F3): TwinTotality.h states why each is
//     inactive on a UB-free execution.
// A redirected inner call computes its callee's value by the same induction. On
// a state where the source's call is UB, or where the guard excluded it, the
// twin returns SOME defined value: every sink is frozen or guarded, so it never
// traps, and every loop is bounded, so it terminates within ScalarEvolution's
// constant max trip count (a diverging input runs to that bound, accepted by
// owner ruling owner-ruling-twin-divergence-bounded-2026-10-13); the controlled
// copy never merges that value (the identity where the flag is 0) or it refines
// the source's UB.
// `freeze`, guards and counters are classical: no gate is added. The twin of a
// bodyless `speculatable` callee (dm7f.26) is the wrapper `ret freeze(F(...))`:
// edit 2 on a call the Direct route already trusts on that attribute.
#include "SpeculationTwin.h"

#include "CallContract.h"  // inertAttrs, twinDroppedParamAttrs
#include "PoisonFlow.h"    // TwinPlanner
#include "TwinTotality.h"  // TwinTotality, applyTwinShape

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

#include <cstdlib>
#include <utility>

using namespace llvm;

namespace cq {
namespace {

constexpr char TwinKind[] = "cq.specsafe.twin";

std::string twinName(const Function &F) {
  return ("__cq_specsafe_" + F.getName()).str();
}

bool isTwinOf(const Function &G, const Function &F) {
  const MDNode *N = G.getMetadata(TwinKind);
  return N && N->getNumOperands() == 1 &&
         mdconst::dyn_extract_or_null<Function>(N->getOperand(0)) == &F;
}

// bd r2j3.22: the twins this pass built and verified, by original. A `WeakVH`
// nulls when its twin is deleted; a deleted original nulls the twin's tag, so
// the `isTwinOf` cross-check refuses a recycled key. One pass instance runs per
// process (opt / cq-opt), single-threaded.
DenseMap<const Function *, WeakVH> &registry() {
  static DenseMap<const Function *, WeakVH> R;
  return R;
}

Function *findTwin(const Function &F) {
  auto It = registry().find(&F);
  if (It == registry().end())
    return nullptr;
  auto *T = dyn_cast_or_null<Function>(static_cast<Value *>(It->second));
  if (T && T->getParent() == F.getParent() && isTwinOf(*T, F))
    return T;
  registry().erase(It);
  return nullptr;
}

// Keep only the return attributes a defined, unconstrained value satisfies.
void keepInertReturn(CallInst &C, bool KeepNoUndef) {
  LLVMContext &Ctx = C.getContext();
  AttrBuilder Keep(Ctx);
  for (Attribute A : C.getAttributes().getRetAttrs())
    if (inertAttrs(AttributeSet::get(Ctx, {A})) &&
        (KeepNoUndef || !A.hasAttribute(Attribute::NoUndef)))
      Keep.addAttribute(A);
  C.setAttributes(C.getAttributes()
                      .removeAttributesAtIndex(Ctx, AttributeList::ReturnIndex)
                      .addRetAttributes(Ctx, Keep));
}
}  // namespace

bool isVerifiedTwin(const Function &T) {
  const MDNode *N = T.getMetadata(TwinKind);
  const Function *F = N && N->getNumOperands() == 1
                          ? mdconst::dyn_extract_or_null<Function>(N->getOperand(0))
                          : nullptr;
  return F && findTwin(*F) == &T;
}

void callSpeculationTwin(CallInst &Call, Function &Twin) {
  Call.setCalledFunction(&Twin);
  keepInertReturn(Call, /*KeepNoUndef=*/true);
  for (unsigned N = 0; N != Call.arg_size(); ++N)
    for (Attribute::AttrKind K : twinDroppedParamAttrs())
      Call.removeParamAttr(N, K);
}

namespace {
// Apply `E` (keyed by the instructions of the body it was planned on) to the body
// `At` maps it onto. Every redirect target's twin is already built.
void applyEdits(const TwinEdits &E,
                function_ref<Instruction *(const Instruction *)> At) {
  for (const auto &[I, N] : E.Freeze) {
    Instruction *U = At(I);
    Value *Op = U->getOperand(N);
    auto *Fr = new FreezeInst(Op, Op->getName() + ".fr", U);
    Fr->setDebugLoc(U->getDebugLoc());
    U->setOperand(N, Fr);
  }
  for (const CallInst *C : E.StripRet)
    keepInertReturn(*cast<CallInst>(At(C)), /*KeepNoUndef=*/false);
  for (const CallInst *C : E.Redirect)
    callSpeculationTwin(*cast<CallInst>(At(C)), *findTwin(*C->getCalledFunction()));
}

bool noEdits(const TwinEdits &E) {
  return E.Freeze.empty() && E.StripRet.empty() && E.Redirect.empty();
}

unsigned editCount(const TwinEdits &E) {
  return E.Freeze.size() + E.StripRet.size() + E.Redirect.size();
}

// Every edit a body can ever take, so a bound on the verification rounds (each
// round applies at least one): a freeze replaces an ORIGINAL operand slot by a
// `freeze`, which the walk never counts as possibly poison, so that slot is
// never frozen again and the new `freeze` is no sink; a strip leaves a call
// site nothing to strip; a redirect points a call at a verified twin, which is
// never UB and total, so it is never redirected again. Counted after the
// structural edits (guards, counters), which the plan never re-plans.
unsigned editSites(const Function &T) {
  unsigned N = 0;
  for (const BasicBlock &BB : T)
    for (const Instruction &I : BB)
      N += I.getNumOperands() + 2;
  return N;
}

// The name, linkage, and the attributes a frozen body no longer honours. The
// registry entry and tag are set only once the twin is verified (R11 round 2 F-B).
void shapeTwinDecl(Function &T, const Function &F) {
  LLVMContext &Ctx = F.getContext();
  T.setName(twinName(F));
  T.setLinkage(GlobalValue::InternalLinkage);
  T.setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  T.setComdat(nullptr);
  // Every may-poison `ret` is frozen, so the result is defined; a value
  // constraint (`range`, `nofpclass`, ...) a frozen value may violate is dropped.
  AttributeMask Drop;
  for (Attribute A : T.getAttributes().getRetAttrs())
    if (!inertAttrs(AttributeSet::get(Ctx, {A})))
      Drop.addAttribute(A);
  T.removeRetAttrs(Drop);
  for (Argument &A : T.args())
    for (Attribute::AttrKind K : twinDroppedParamAttrs())
      T.removeParamAttr(A.getArgNo(), K);
}

Function *cloneTwin(Function &F, ValueToValueMapTy &VMap) {
  Function *T = CloneFunction(&F, VMap);
  shapeTwinDecl(*T, F);
  return T;
}

// dm7f.26: the twin of a bodyless `speculatable` callee: `ret F(args)`, the call
// carrying no return attribute. The verification rounds freeze its `noundef`
// arguments and its `ret`, exactly as for a cloned body.
Function *wrapDeclaration(Function &F) {
  Function *T = Function::Create(F.getFunctionType(), F.getLinkage(),
                                 F.getAddressSpace(), "", F.getParent());
  T->copyAttributesFrom(&F);
  shapeTwinDecl(*T, F);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "", T);
  SmallVector<Value *, 4> Args;
  for (Argument &A : T->args())
    Args.push_back(&A);
  CallInst *C = CallInst::Create(&F, Args, "", BB);
  C->setCallingConv(F.getCallingConv());
  if (F.getReturnType()->isVoidTy())
    ReturnInst::Create(F.getContext(), BB);
  else
    ReturnInst::Create(F.getContext(), C, BB);
  return T;
}
}  // namespace

// R11 round 1 (F1/F2): a plan read off the ORIGINAL body proves flags through
// facts its own edits falsify (a `returned` callee now reads a frozen argument;
// a dropped `range` read through a pre-existing `freeze`). So every twin is
// VERIFIED on its own emitted body: the twin-mode dataflow runs on the twin with
// every parameter possibly poison, its new edits are applied, and that repeats
// until it plans nothing (each round applies at least one edit, at most
// `editSites` in all). The plan sees through its own frozen `returned`
// arguments, so a chain of THOSE converges in one pass (R11 round 2 F-A). A chain
// of USE-BASED licenses (a pre-existing `freeze` of a value LLVM deems defined
// because of a later `noundef` use the plan then freezes) still loses one stage
// per round: O(N^2) in N stages (R11 round 3 F1: N=1000, 999 rounds, 6.6s). Hand
// IR only: clang -O1's `visitFreeze` removes that freeze by the same license. The
// termination bound is unaffected; a same-pass rule is a filed follow-up.
// Only then is the twin registered, tagged and returned. The work is an explicit
// stack of originals (a twin's inner twin above it), as a chain may be 60000
// deep, over ONE planner memo (only the twin being edited is forgotten). The
// structural edits (TwinTotality.h) are applied once, to the fresh clone, from
// the ORIGINAL body's analysis; the rounds then verify the poison plan over them.
//
// INVARIANT (R11 round 2 F-B): an unregistered twin is unverified and has no
// caller, because a parent's twin is cloned, and a redirect applied, only after
// the inner twin is verified. So an abort erases every unregistered twin it
// built, and the cache (`findTwin`, registry only) never hands out a half-edited one.
Function *getOrCreateSpeculationTwin(Function &F) {
  if (Function *T = findTwin(F))
    return T;
  TwinPlanner Planner;
  TwinTotality Tot;
  SmallVector<Function *, 8> Stack{&F};
  SmallPtrSet<Function *, 8> Pending{&F};
  MapVector<Function *, Function *> Building;  // original -> unverified twin
  DenseMap<Function *, unsigned> Left;          // edit sites not yet used
  DenseMap<Function *, unsigned> Rounds;        // re-edit rounds (CQ_SPECSAFE_DBG)
  auto abort = [&]() -> Function * {
    for (auto &[G, T] : Building)
      if (T->use_empty())
        T->eraseFromParent();
    return nullptr;
  };
  while (!Stack.empty()) {
    Function *G = Stack.back();
    Function *T = Building.lookup(G);
    if (!Tot.admits(*G))
      return abort();  // the route asked the same walk: not reached
    if (!T && G->isDeclaration()) {  // dm7f.26: a wrapper, verified from round 1
      T = Building[G] = wrapDeclaration(*G);
      Left[G] = editSites(*T);
    }
    const std::optional<TwinEdits> E = Planner.edits(T ? *T : *G);
    if (!E)
      return abort();  // a hard sink: not reached for a routed callee
    Function *Missing = nullptr;
    for (const CallInst *C : E->Redirect)
      if (Function *H = C->getCalledFunction(); !findTwin(*H)) {
        Missing = H;
        break;
      }
    if (Missing) {
      if (!Pending.insert(Missing).second)
        return abort();  // a cycle: the plan refuses one; never build through it
      Stack.push_back(Missing);
      continue;
    }
    ValueToValueMapTy VMap;
    if (!T) {  // a fresh clone: verified on the next iteration
      T = Building[G] = cloneTwin(*G, VMap);
      applyTwinShape(*T, Tot.shape(*G), VMap);
      Left[G] = editSites(*T);
    } else if (noEdits(*E)) {
      if (::getenv("CQ_SPECSAFE_DBG"))
        errs() << "CQ_SPECSAFE_DBG: verified @" << T->getName()
               << " rounds=" << Rounds[G] << "\n";
      T->setMetadata(TwinKind,
                     MDNode::get(T->getContext(), {ValueAsMetadata::get(G)}));
      registry()[G] = WeakVH(T);
      Building.erase(G);
      Pending.erase(G);
      Stack.pop_back();
      continue;
    } else {
      Planner.forget(*T);
      ++Rounds[G];
    }
    if (editCount(*E) > Left[G])
      return abort();  // a site edited twice: a planner defect, never a loop
    Left[G] -= editCount(*E);
    // A plan on the original maps onto the clone; a plan on `T` is `T`'s own.
    applyEdits(*E, [&](const Instruction *I) {
      return I->getFunction() == T ? const_cast<Instruction *>(I)
                                   : cast<Instruction>(VMap.lookup(I));
    });
  }
  return findTwin(F);
}

}  // namespace cq
