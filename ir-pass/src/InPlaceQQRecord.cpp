// InPlaceQQRecord.cpp — the two analysis halves of the in-place quantum-source
// round that bracket it in the pipeline (bd test_C_libtooling-r2j3.33, dm7f.51
// step 1; see InPlaceQQ.h): the pre-emission DEAD-OPERAND record it keys its
// eligibility on, and the post-`uncompute` POSTCONDITION that re-asks its
// prediction. Split out of InPlaceQQ.cpp for the 400-line file budget.

#include "InPlaceQQ.h"

#include "ArmAnalysis.h"       // isFrontEndThetaCall
#include "ChainWalk.h"         // isInPlaceGateOn / isMeasureSink / isOutputSink / isTemplateProducer
#include "CloneProducer.h"     // isCloneProducer
#include "EmitInverse.h"       // inPlaceQQAdjointName
#include "FreePoint.h"         // blockCanRepeat
#include "MergeStreamGates.h"  // streamGateWrites / handleAliases
#include "RegCondLeaf.h"       // kRegCondTag (stripped after uncompute)
#include "TaintPropagation.h"  // TaintSet
#include "WireWalk.h"          // provablyBefore

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

#include <cstring>
#include <optional>

using namespace llvm;

namespace cq {

namespace {

bool isQQStem(Instruction::BinaryOps Op) {
  return Op == Instruction::Xor || Op == Instruction::Add ||
         Op == Instruction::Sub;
}

unsigned maskOf(const Instruction *I) {
  MDNode *MD = I->getMetadata(kDeadOperandTag);
  if (!MD || MD->getNumOperands() != 1)
    return 0;
  auto *C = mdconst::dyn_extract<ConstantInt>(MD->getOperand(0));
  return C ? static_cast<unsigned>(C->getZExtValue()) & 15u : 0u;
}

void setDeadMask(Instruction *I, unsigned Mask) {
  LLVMContext &Ctx = I->getContext();
  I->setMetadata(kDeadOperandTag,
                 MDNode::get(Ctx, ConstantAsMetadata::get(ConstantInt::get(
                                      Type::getInt32Ty(Ctx), Mask))));
}

// Is `V` DEAD after `BO` in the IR the user wrote: is `BO` its last reader?
// Bennett's exclusive reader (one operand occurrence) is the order-free special
// case; CQ asks the POSITIONAL question — every other user provably BEFORE `BO`
// (`provablyBefore`, the shared spelling) — because a completed earlier reader
// (a region compare, a measured record) does not keep the old value alive
// (owner ruling Q1: "the OLD x is dead at the op"). Whether that earlier reader
// is SETTLED is the fence's question (G7), asked later; here it only decides
// eligibility, i.e. in-place-or-loud versus out-of-place. A `BO` that can run
// again reads `V` again unless `V` is re-defined in the same cycle, so a `V`
// from outside `BO`'s loop is live (and an irreducible repeat is not proven).
// A φ is a target only when it names ONE wire (`singleWirePhiDeadAfter`, below);
// Bennett refuses φ targets because a φ can alias another live name.
bool isThetaChainLink(const Value *V) {
  return isFrontEndThetaCall(V) && cast<CallInst>(V)->arg_size() >= 2;
}

// bd dm7f.77 (dm7f.51 step 2, design D2(b): "every use of every member of x's
// wire closure") — the ONE φ that IS a register: a merge φ every incoming of
// which is a name on ONE rotation chain (`%m = phi [Ry(%q), %q]`, a controlled
// in-place Ry region's merge, which the region emitter collapses onto the
// hoisted theta's rail). Bennett's reason to refuse a φ target — it can alias
// ANOTHER live name — is answered by asking deadness of every chain member: each
// is read only by the φ, by the next link of the chain, or provably before `BO`.
// R11 round 1 (B-F1): a CONSTANT incoming is the same wire when it IS the seed
// the chain's root theta starts from (`phi [Ry(false), false]`, a controlled
// state prep's merge: the prep rail is minted at that seed and left there on the
// other edge) — proved by identity with the root theta's arg 0 (`ConstantInt`
// is uniqued per context). Any other constant is a different value: not one wire.
bool singleWirePhiDeadAfter(PHINode *P, BinaryOperator *BO,
                            const DominatorTree &DT) {
  SmallPtrSet<Value *, 8> Wire;
  SmallVector<Constant *, 2> Seeds;
  Value *Root = nullptr;
  for (Value *In : P->incoming_values()) {
    if (auto *K = dyn_cast<Constant>(In)) {
      Seeds.push_back(K);
      continue;
    }
    Value *X = In;
    while (isThetaChainLink(X) &&
           isa<Instruction>(cast<CallInst>(X)->getArgOperand(0))) {
      Wire.insert(X);
      X = cast<CallInst>(X)->getArgOperand(0);
    }
    if (!isa<Instruction>(X) || (Root && Root != X))
      return false;  // two different wires.
    Root = X;
    Wire.insert(X);
  }
  if (!Root)
    return false;
  for (Constant *K : Seeds)
    if (!isThetaChainLink(Root) || cast<CallInst>(Root)->getArgOperand(0) != K)
      return false;  // a constant that is not the chain's own seed.
  for (Value *M : Wire)
    for (User *U : M->users()) {
      if (U == P || Wire.count(U))
        continue;
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || !provablyBefore(UI, BO, DT))
        return false;
    }
  return true;
}

// The positional question every deadness answer shares.
bool usersBefore(Value *V, BinaryOperator *BO, const DominatorTree &DT,
                 const LoopInfo &LI) {
  if (Loop *L = LI.getLoopFor(BO->getParent())) {
    auto *VI = dyn_cast<Instruction>(V);
    if (!VI || !L->contains(VI))
      return false;
  } else if (blockCanRepeat(BO->getParent())) {
    return false;
  }
  for (User *U : V->users()) {
    if (U == BO)
      continue;
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI || !provablyBefore(UI, BO, DT))
      return false;
  }
  return true;
}

bool deadAfter(Value *V, BinaryOperator *BO, const DominatorTree &DT,
               const LoopInfo &LI) {
  if (isa<Constant>(V) || BO->getOperand(0) == BO->getOperand(1))
    return false;
  if (auto *P = dyn_cast<PHINode>(V); P && !singleWirePhiDeadAfter(P, BO, DT))
    return false;
  return usersBefore(V, BO, DT, LI);
}

// R11 round 1 (B-F1): a φ that is dead by its OWN users but is not provably one
// wire. The late round must not silently leave it out of place when it is a user
// register beside a surviving result (step 1's Q1: in place or LOUD).
bool deadUnprovenPhi(Value *V, BinaryOperator *BO, const DominatorTree &DT,
                     const LoopInfo &LI) {
  auto *P = dyn_cast<PHINode>(V);
  return P && BO->getOperand(0) != BO->getOperand(1) &&
         !singleWirePhiDeadAfter(P, BO, DT) && usersBefore(V, BO, DT, LI);
}

}  // namespace

bool qqOperandDeadAfter(Value *V, BinaryOperator *BO, const DominatorTree &DT,
                        const LoopInfo &LI) {
  return deadAfter(V, BO, DT, LI);
}

void recordDeadQQOperands(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LI;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO || !isQQStem(BO->getOpcode()) || !BO->getType()->isIntegerTy() ||
            BO->getType()->getIntegerBitWidth() > 64)
          continue;
        if (!taint.Tainted.count(BO->getOperand(0)) &&
            !taint.Tainted.count(BO->getOperand(1)))
          continue;
        if (!DT) {
          DT.emplace(F);
          LI.emplace(*DT);
        }
        unsigned Mask = 0;
        for (unsigned Idx = 0; Idx < 2; ++Idx) {
          if (deadAfter(BO->getOperand(Idx), BO, *DT, *LI))
            Mask |= 1u << Idx;
          else if (deadUnprovenPhi(BO->getOperand(Idx), BO, *DT, *LI))
            Mask |= 4u << Idx;  // bits 2-3: a dead φ not provably one wire.
        }
        if (Mask)
          setDeadMask(BO, Mask);
      }
  }
}

void transferDeadOperandMask(const BinaryOperator *BO, CallInst *T,
                             bool Swapped) {
  unsigned Mask = maskOf(BO);
  if (!Mask)
    return;
  if (Swapped)
    Mask = ((Mask & 5u) << 1) | ((Mask >> 1) & 5u);  // swap each bit pair.
  setDeadMask(T, Mask);
}

const char kMsgInPlaceQQStaleRecord[] =
    "cq in-place lowering: a gate writes a record of a register's old value "
    "after its in-place quantum reassignment";
const char kMsgInPlaceQQReaderUnknown[] =
    "cq in-place lowering: a reader of an in-place reassigned register cannot "
    "be classified";
// UNREACHABLE TODAY, KEPT FAIL-CLOSED (R11 round 2c finding F2). `handleAliases`
// answers false on exactly two paths: a store of the target to memory that is not
// a proven rail bank, and a load that is not a proven bank cell. Neither reaches
// this postcondition: `declineTaintEscapes` (TaintPropagation) runs on the
// pre-lowering module and loud-declines every tainted value stored to, or loaded
// from, memory that `markRailBankAllocas` has not proven a rail bank ("cq taint
// escape: tainted value stored to memory" — the reviewer's hand-IR probe
// review_s1R2c/h4.ll stops there), and for a proven bank `handleAliases` follows
// the cells and returns true. The pass's own later stores (the rail-bank cell
// type rewrite) are bank stores by construction. So no fixture can pin this
// message; it stays a loud failure, never a silent `{P}` fallback.
const char kMsgInPlaceQQAliasUnknown[] =
    "cq in-place lowering: the aliases of an in-place reassigned register "
    "cannot be enumerated";
const char kMsgInPlaceQQStaleAdjoint[] =
    "cq in-place lowering: an adjoint reads a register after its in-place "
    "quantum reassignment";

namespace {

// Is `I` an adjoint of `G` on the same operands? The symbol is EmitInverse's
// (`inPlaceQQAdjointName`, the one spelling), never re-derived here.
bool isAdjointOf(const CallInst *I, const CallInst *G) {
  return I != G && isInPlaceQQGate(I) &&
         I->getArgOperand(0) == G->getArgOperand(0) &&
         I->getArgOperand(1) == G->getArgOperand(1) &&
         I->getCalledFunction()->getName() ==
             inPlaceQQAdjointName(G->getCalledFunction()->getName());
}

// How a call `X` positioned AFTER the gate uses the relabelled target `V` (or an
// alias of it). R11 round 2 (finding F3, L2): the classification must be a
// SUPERSET of b12d4452's `_unc` scan and FAIL CLOSED on anything it cannot place.
enum class LaterUse {
  NewValue,  // reads the NEW value and writes no older record: fine.
  Records,   // writes the rails in `W`; stale iff one predates the gate.
  Adjoint,   // an adjoint whose FORWARD is `*Fwd`; stale iff it predates the gate.
  Unknown,   // a reader the classification does not know: fail closed.
};

LaterUse classifyLaterUse(const CallInst *X, const Value *V, const TaintSet &taint,
                     SmallVectorImpl<const Value *> &W, const CallInst *&Fwd) {
  const Function *Fn = X->getCalledFunction();
  if (!Fn)
    return LaterUse::Unknown;
  StringRef N = Fn->getName();
  // An ADJOINT of any family re-reads its operands expecting the values its
  // FORWARD saw. It is stale exactly when that forward ran BEFORE the gate (it
  // read `V`'s old value); a forward after the gate read the same new value the
  // adjoint reads (R11 round 2b, finding N1: `r = t & tmp` after `t ^= c+tmp`,
  // its `_unc` re-reading the new `t`, is fine). The forward is located by
  // EmitInverse's own recipes (`forwardOfAdjoint`, R12); a family it cannot place
  // (the `_inv` reserve, anything else) fails closed.
  if (N.ends_with("_unc") || N.ends_with("_inv")) {
    Fwd = forwardOfAdjoint(X);
    return Fwd ? LaterUse::Adjoint : LaterUse::Unknown;
  }
  if (isInPlaceQQGate(X)) {  // `V` as its SOURCE: writes its dst.
    W.push_back(X->getArgOperand(1));
    return LaterUse::Records;
  }
  SmallVector<unsigned, 2> Slots;
  if (streamGateWrites(X, Slots)) {  // cnot / toffoli / x / copy / free
    for (unsigned S : Slots)
      W.push_back(X->getArgOperand(S));
    return LaterUse::Records;
  }
  // A forward reader that mints a FRESH rail from `V`'s NEW value (a template,
  // a QRAM load, a clone call proven read-only), a measurement, a tape write, a
  // branch-phase gate (diagonal): nothing older is written.
  if (isMeasureSink(X) || isOutputSink(X) || isBranchPhaseGate(X) ||
      isTemplateProducer(X) || isCloneProducer(X, taint))
    return LaterUse::NewValue;
  // A controlled rotation reading `V` only as its CONTROL writes its target.
  if (N.starts_with("cqrt_r") && N.ends_with("_controlled") &&
      X->arg_size() == 3 && X->getArgOperand(0) == V &&
      X->getArgOperand(1) != V) {
    W.push_back(X->getArgOperand(1));
    return LaterUse::Records;
  }
  return LaterUse::Unknown;
}

}  // namespace

// THE POSTCONDITION AS A GATE SET (R11 rounds 1-2; L2/L3). Invariant: no gate
// after the in-place gate `G` reads `G`'s target `P` (or any alias of it) to act
// on `P`'s OLD value — every adjoint, strip and merge replay of a computation that
// read `P` before `G` — unless `G`'s own adjoint ran in between (the spine
// reversing a dead target's DAG). Each later reader is classified by
// `classifyLaterUse`; a reader that writes a non-user rail minted before `G` is
// stale, and a reader the classification does not know FAILS CLOSED, as does a
// target whose aliases cannot be enumerated (`handleAliases` false — parked in
// memory that is not a proven rail bank). It is a superset of b12d4452's `_unc`
// scan: every `_unc`/`_inv` is a `Records` reader of all its other handles.
bool declineStaleInPlaceQQReads(Module &M, const TaintSet &taint) {
  // bd dm7f.77: the register-condition tags are records the spine read (row
  // (c′)); `uncompute` has run, so they leave the module here.
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        for (const char *Tag : {kRegCondTag, kRegCondRailTag})
          I.setMetadata(Tag, nullptr);
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallVector<CallInst *, 4> Gates;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *G = dyn_cast<CallInst>(&I); G && isInPlaceQQGate(G))
          Gates.push_back(G);
    if (Gates.empty())
      continue;
    DominatorTree DT(F);
    auto loud = [&](const Instruction *At, const char *Msg) {
      F.getContext().diagnose(
          DiagnosticInfoUnsupported(F, Msg, At->getDebugLoc()));
      return true;
    };
    for (CallInst *G : Gates) {
      Value *P = G->getArgOperand(1);
      SmallPtrSet<Value *, 8> Names;
      if (!handleAliases(P, taint, DT, Names))
        return loud(G, kMsgInPlaceQQAliasUnknown);  // fail closed.
      Names.insert(P);
      SmallVector<CallInst *, 4> Undo;
      for (User *U : P->users())
        if (auto *I = dyn_cast<CallInst>(U); I && isAdjointOf(I, G))
          Undo.push_back(I);
      auto undoneBefore = [&](const Instruction *X) {
        return llvm::any_of(Undo, [&](CallInst *Inv) {
          return provablyBefore(G, Inv, DT) && provablyBefore(Inv, X, DT);
        });
      };
      for (Value *V : Names)
        for (User *U : V->users()) {
          auto *X = dyn_cast<CallInst>(U);
          if (!X || X == G || !provablyBefore(G, X, DT) ||
              isInPlaceGateOn(X, V) || isAdjointOf(X, G))
            continue;  // not after G, a gate ON the new value, or G's undo.
          SmallVector<const Value *, 4> W;
          const CallInst *Fwd = nullptr;
          LaterUse K = classifyLaterUse(X, V, taint, W, Fwd);
          if (K == LaterUse::NewValue || undoneBefore(X))
            continue;
          if (K == LaterUse::Unknown)
            return loud(X, kMsgInPlaceQQReaderUnknown);
          if (K == LaterUse::Adjoint) {
            if (provablyBefore(Fwd, G, DT))
              return loud(X, kMsgInPlaceQQStaleAdjoint);
            continue;
          }
          for (const Value *Rec : W) {
            const auto *RI = dyn_cast<Instruction>(Rec);
            if (Rec != V && RI && provablyBefore(RI, G, DT) &&
                !railIsUserData(Rec))
              return loud(X, kMsgInPlaceQQStaleRecord);
          }
        }
    }
  }
  return false;
}

unsigned deadOperandMask(const CallInst *T) { return maskOf(T) & 3u; }

unsigned unprovenPhiOperandMask(const CallInst *T) {
  return (maskOf(T) >> 2) & 3u;
}

}  // namespace cq
