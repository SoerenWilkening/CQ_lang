// SpeculationTwin.cpp — bd dm7f.21: see SpeculationTwin.h.
//
// Why a frozen twin computes the source's value (R2, analytic): the twin is the
// callee with freezes inserted, so by induction over its instructions it holds
// the callee's values on a basis state where the source runs the call without
// UB, as long as each freeze sees a defined value there. Every freeze sits on a
// sink operand (a `noundef` argument, a branch condition: defined on a UB-free
// execution, so the freeze is the identity) or on a `ret` operand (where a poison
// result becomes some defined value, a refinement of poison); a dropped return
// constraint held there too. On a state where the source's call is UB, or where
// the guard excluded it, the twin returns SOME defined value, which the
// controlled copy never merges (the identity where the flag is 0) or which
// refines the source's UB. `freeze` is a codegen no-op: no gate is added.
#include "SpeculationTwin.h"

#include "CallContract.h"  // inertAttrs
#include "PoisonFlow.h"    // TwinPlanner

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

// By name first; a module whose own function took the name (the twin was then
// renamed by the symbol table) is scanned for the attachment.
Function *findTwin(const Function &F) {
  Module &M = *const_cast<Module *>(F.getParent());
  Function *G = M.getFunction(twinName(F));
  if (!G)
    return nullptr;
  if (isTwinOf(*G, F))
    return G;
  for (Function &H : M)
    if (isTwinOf(H, F))
      return &H;
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

void callSpeculationTwin(CallInst &Call, Function &Twin) {
  Call.setCalledFunction(&Twin);
  keepInertReturn(Call, /*KeepNoUndef=*/true);
  for (unsigned N = 0; N != Call.arg_size(); ++N)
    Call.removeParamAttr(N, Attribute::Returned);
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
// never frozen again and the new `freeze` is no sink; a strip leaves an
// intrinsic call site nothing to strip; a redirect points a call at a verified
// twin, which is never UB, so it is never redirected again.
unsigned editSites(const Function &T) {
  unsigned N = 0;
  for (const BasicBlock &BB : T)
    for (const Instruction &I : BB)
      N += I.getNumOperands() + 2;
  return N;
}

// The bare clone: name, linkage, and the attributes a frozen body no longer
// honours. The cache tag is set only once the twin is verified (R11 round 2 F-B).
Function *cloneTwin(Function &F, ValueToValueMapTy &VMap) {
  LLVMContext &Ctx = F.getContext();
  Function *T = CloneFunction(&F, VMap);
  T->setName(twinName(F));
  T->setLinkage(GlobalValue::InternalLinkage);
  T->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  T->setComdat(nullptr);
  // Every may-poison `ret` is frozen, so the result is defined; a value
  // constraint (`range`, `nofpclass`, ...) a frozen value may violate is dropped,
  // and so is a `returned` a frozen `ret` no longer honours.
  AttributeMask Drop;
  for (Attribute A : T->getAttributes().getRetAttrs())
    if (!inertAttrs(AttributeSet::get(Ctx, {A})))
      Drop.addAttribute(A);
  T->removeRetAttrs(Drop);
  for (Argument &A : T->args())
    T->removeParamAttr(A.getArgNo(), Attribute::Returned);
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
// Only then is the twin tagged and returned. The work is an explicit stack
// of originals (a twin's inner twin above it), as a chain may be 60000 deep, over
// ONE planner memo (only the twin being edited is forgotten).
//
// INVARIANT (R11 round 2 F-B): an untagged twin is unverified and has no caller,
// because a parent's twin is cloned, and a redirect applied, only after the inner
// twin is verified. So an abort erases every untagged twin it built, and the
// cache (`findTwin`, tag only) never hands out a half-edited one.
Function *getOrCreateSpeculationTwin(Function &F) {
  if (Function *T = findTwin(F))
    return T;
  TwinPlanner Planner;
  SmallVector<Function *, 8> Stack{&F};
  SmallPtrSet<Function *, 8> Pending{&F};
  MapVector<Function *, Function *> Building;  // original -> untagged twin
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
    const std::optional<TwinEdits> E = Planner.edits(T ? *T : *G);
    if (!E)
      return abort();  // a hard sink: not reached for a strict-walk callee
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
      Left[G] = editSites(*T);
    } else if (noEdits(*E)) {
      if (::getenv("CQ_SPECSAFE_DBG"))
        errs() << "CQ_SPECSAFE_DBG: verified @" << T->getName()
               << " rounds=" << Rounds[G] << "\n";
      T->setMetadata(TwinKind,
                     MDNode::get(T->getContext(), {ValueAsMetadata::get(G)}));
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
