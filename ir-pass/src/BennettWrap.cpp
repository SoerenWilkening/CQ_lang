// BennettWrap.cpp — the Bennett compute-copy-uncompute synthesizer (DD-3); see
// BennettWrap.h for the mechanical reverse (bd p3kd.7.8).

#include "BennettWrap.h"
#include "SpeculationSafety.h"

#include "EmitInverse.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

#include <optional>

using namespace llvm;

namespace cq {

namespace {

// Loud declines (Rule 12; not fixture-pinned in 6.1 — the pre-scan is
// unreachable-by-construction over a pure-classical clone whose data templates
// and compares are all invertible post-WI-0, but defends a future widening of
// the accepted body set).
constexpr char kMsgCloneUninvertible[] =
    "cq specialization: clone body contains an un-invertible primitive under "
    "quantum lift";
constexpr char kMsgCloneNoCopy[] =
    "cq specialization: clone return width has no reversible copy under quantum "
    "lift";
// bd p3kd.7.1 review rounds 1 and 2: since `scanBody` admits `unreachable`, a body
// with no `ret` at all reaches the wrap as ONE block whose terminator is not a
// `ret` (a parameter read by a branch stays live, because every terminator is a
// liveness root, so the dead-argument drop keeps the quantum slot). The wrap used
// to return false silently and `buildClone` dropped the result: an unwrapped clone,
// forward gates never reversed or freed, at `opt` exit 0. Such a callee never
// returns, so every call is UB, but the pass still fails loudly (R1: never guess).
// Pinned by spec_reject_clone_no_return.ll.
constexpr char kMsgCloneNoReturn[] =
    "cq specialization: lifted callee never returns under quantum lift";

void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// What one captured forward call is, for the reverse.
enum class GateKind {
  Skip,    // classical: a non-runtime call, a QRAM array token, a classical
           // inner clone call (it restored its inputs)
  Mint,    // `h = T(…)`: a template / QRAM load / lifted inner clone call
  Unc,     // `T_unc(h, …)`: a template rail zeroed in the forward (an emitter strip)
  Alloc,   // `g = cqrt_alloc_<W>(c)`
  Free,    // `cqrt_free(h)`
  Gate,    // anything else `emitInverseCall` inverts (involutions, QRAM store, …)
  Unknown, // nothing inverts it: decline
};

GateKind classify(CallInst *CI, const SmallPtrSetImpl<CallInst *> &LiftedCalls) {
  Function *F = CI->getCalledFunction();
  if (!F)
    return GateKind::Skip;  // an indirect call in a lifted body is classical.
  StringRef N = F->getName();
  if (N.starts_with("__cq_q_"))
    return N.ends_with("_unc") ? GateKind::Unknown
           : LiftedCalls.count(CI) ? GateKind::Mint
                                   : GateKind::Skip;
  if (!N.starts_with("cqrt_") && !N.starts_with("cq_template_"))
    return GateKind::Skip;  // classical computation, run once in the forward.
  if (N.starts_with("cqrt_qram_alloc_"))
    return GateKind::Skip;  // the classical array-handle token (bd 20xt.4).
  if (N == "cqrt_free")
    return GateKind::Free;
  if (N.starts_with("cqrt_alloc_"))
    return GateKind::Alloc;
  if (N.starts_with("cq_template_") && N.ends_with("_unc") &&
      !N.contains("_controlled") && !CI->arg_empty())
    return GateKind::Unc;
  if (!isInverseEmittable(CI))
    return GateKind::Unknown;
  if (!CI->getType()->isVoidTy() &&
      (N.starts_with("cq_template_") || N.starts_with("cqrt_qram_load_")))
    return GateKind::Mint;
  return GateKind::Gate;
}

bool isZeroAlloc(const CallInst *CI) {
  const auto *C = dyn_cast<Constant>(CI->getArgOperand(0));
  return C && C->isNullValue();
}

// The rails a gate WRITES, for the strip elision below. `std::nullopt` means
// "not known": every handle operand is then treated as both read and written.
std::optional<SmallVector<Value *, 2>> gateTargets(CallInst *CI,
                                                   GateKind K) {
  StringRef N = CI->getCalledFunction()->getName();
  auto arg = [&](unsigned I) { return CI->getArgOperand(I); };
  if (K == GateKind::Mint || K == GateKind::Alloc)
    return SmallVector<Value *, 2>{};  // writes only its own fresh result
  if (K == GateKind::Unc)
    return SmallVector<Value *, 2>{arg(0)};
  if (N == "cqrt_x" && CI->arg_size() == 1)
    return SmallVector<Value *, 2>{arg(0)};
  if (N == "cqrt_cnot" && CI->arg_size() == 2)
    return SmallVector<Value *, 2>{arg(1)};
  if (N == "cqrt_toffoli" && CI->arg_size() == 3)
    return SmallVector<Value *, 2>{arg(2)};
  if (N.starts_with("cqrt_copy_") && N.ends_with("_controlled") &&
      CI->arg_size() == 3)
    return SmallVector<Value *, 2>{arg(2)};
  return std::nullopt;
}

// STRIP ELISION. Main's control emitters strip their condition networks and
// arm chains inline (`stripCondNetwork`, the chain `_unc`) and free the rails,
// which suits main, where nothing reverses the region later. Inside a lifted
// clone the Bennett reverse replays the whole forward anyway, and a rail the
// forward freed must then be re-minted, so the replayed gates read a different
// rail than the forward ones and stage 2b cannot pair them.
//
// For a rail R the forward frees, delete every gate after R's LAST READ that
// writes R and nothing else, together with the free. Sound because a lifted
// clone's body is a permutation of basis states (`scanBody` rejects every phase
// and rotation primitive): a gate that writes only R, after nothing reads R any
// more, changes no other rail at any later point, so the copy-out sees the same
// values; the mirror reverse then undoes the writes R keeps, R ends `|0>` and
// (e) frees it. A rail with a non-call user (a rail select reads it through the
// select), a write after its last read that also writes another rail, or an
// unknown gate touching it keeps its strip and reaches the loud capture check.
// This is an emitter-strip optimization: the emitting owner already guarantees
// no use of its scratch after the free. The scan below relies on that invariant
// and finds the last read before the free, not a last read in arbitrary IR.
// Frees are taken in program order on the live body, so deleting one rail's
// strip (which READ an earlier rail, e.g. a node toffoli reading its leaf flags)
// can expose the next rail's strip.
void elideForwardStrips(BasicBlock &BB,
                        const SmallPtrSetImpl<CallInst *> &LiftedCalls) {
  SmallVector<CallInst *, 16> Frees;
  for (Instruction &I : BB)
    if (auto *CI = dyn_cast<CallInst>(&I))
      if (CI->getCalledFunction() &&
          CI->getCalledFunction()->getName() == "cqrt_free")
        Frees.push_back(CI);
  for (CallInst *Free : Frees) {
    Value *R = Free->getArgOperand(0);
    auto *Minter = dyn_cast<CallInst>(R);
    if (!Minter || Minter->getParent() != &BB)
      continue;
    bool OK = true;
    for (User *U : R->users())
      if (!isa<CallInst>(U))
        OK = false;
    SmallVector<CallInst *, 4> Writes;  // writes of R after its last read
    for (Instruction *I = Minter->getNextNode(); OK && I != Free;
         I = I->getNextNode()) {
      auto *CI = dyn_cast<CallInst>(I);
      if (!CI || !CI->getCalledFunction() || !is_contained(CI->args(), R))
        continue;
      const GateKind K = classify(CI, LiftedCalls);
      auto T = gateTargets(CI, K);
      if (!T) {
        OK = false;
        break;
      }
      const bool WritesR = is_contained(*T, R);
      bool ReadsR = false;
      for (Value *A : CI->args())
        if (A == R && !WritesR)
          ReadsR = true;
      if (ReadsR) {
        Writes.clear();  // a later read: the earlier writes are not strips
        continue;
      }
      if (WritesR) {
        if (T->size() != 1) {
          OK = false;
          break;
        }
        Writes.push_back(CI);
      }
    }
    if (!OK || Writes.empty())
      continue;
    for (CallInst *W : Writes)
      W->eraseFromParent();
    Free->eraseFromParent();
  }
}

}  // namespace

bool emitBennettWrap(Function &Clone, const SmallPtrSetImpl<CallInst *> &LiftedCalls,
                     Value *ResultRail, StringRef RetAbiWidth, WidthDispatch &wd,
                     TaintSet &cloneTaint) {
  // The accepted body is ONE block terminated by `ret` (`lowerCloneControl`'s
  // backstop): main's stages flatten a lowered region, so the forward is a
  // straight-line gate stream.
  auto *Ret = dyn_cast<ReturnInst>(Clone.getEntryBlock().getTerminator());
  if (!Ret && Clone.size() == 1) {
    diagnose(Clone.getEntryBlock().getTerminator(), kMsgCloneNoReturn);
    return false;
  }
  // A body that still has blocks is surviving control, not a missing `ret`
  // (review 2026-10-08: the message used to say "never returns" here too).
  // `lowerCloneControl`'s size backstop fires first today, with this string.
  if (!Ret || Clone.size() != 1) {
    diagnose(Clone.getEntryBlock().getTerminator(),
             "cq specialization: callee contains tainted control flow under "
             "quantum lift");
    return false;
  }

  stabilizeSpeculatedValues(Clone, cloneTaint);
  elideForwardStrips(Clone.getEntryBlock(), LiftedCalls);

  // (a) Capture and pre-scan. After the elision no rail is zeroed or freed inside
  // the forward. One that still is (an emitter strip the elision could not prove
  // deletable) would need the reverse to re-mint it, and no measured input needs
  // that in the fixtures, e2e slices and census probes exercised on 2026-10-07: it
  // fails LOUDLY rather than ship an untested adjoint path (R1, R10).
  SmallVector<std::pair<CallInst *, GateKind>, 64> Fwd;
  for (Instruction &I : Clone.getEntryBlock()) {
    auto *CI = dyn_cast<CallInst>(&I);
    if (!CI)
      continue;
    const GateKind K = classify(CI, LiftedCalls);
    if (K == GateKind::Unknown || K == GateKind::Free || K == GateKind::Unc) {
      diagnose(CI, kMsgCloneUninvertible);
      return false;
    }
    if (K != GateKind::Skip)
      Fwd.emplace_back(CI, K);
  }

  IRBuilder<> B(Ret);
  Value *Out = nullptr;
  if (ResultRail) {
    // The copy-out over the lift-boundary widths (bd p3kd.9): `copyFnClone` is the
    // one resolver, null outside `liftHandleWidth`.
    FunctionCallee Alloc = wd.allocFn(RetAbiWidth);
    FunctionCallee Copy = wd.copyFnClone(RetAbiWidth);
    Type *WTy = wd.llvmWidthType(RetAbiWidth);
    if (!Alloc || !Copy || !WTy) {
      diagnose(Ret, kMsgCloneNoCopy);  // i128/fp128 return — gated earlier, defensive.
      return false;
    }
    // (b) out = alloc(0); (c) copy(result, out). Copy BEFORE reverse.
    Out = B.CreateCall(Alloc, {Constant::getNullValue(WTy)}, "cqq.out");
    B.CreateCall(Copy, {ResultRail, Out});
  }

  // (d) The reverse: every captured gate's adjoint, in reverse program order. An
  // alloc has none here (its rail is freed in (e) once the reverse zeroed it).
  for (auto It = Fwd.rbegin(); It != Fwd.rend(); ++It) {
    if (It->second == GateKind::Alloc)
      continue;
    if (!emitInverseCall(B, It->first, wd, /*CurHandle=*/nullptr, /*Rec=*/nullptr)) {
      diagnose(It->first, kMsgCloneUninvertible);
      return false;
    }
  }

  // (e) Free every rail the forward minted, in program order: a template / QRAM
  // load / lifted-call result and a `|0>` alloc, each zeroed by (d). A non-zero
  // or runtime-valued alloc is a `|v>` product rail and stays allocated (R5).
  FunctionCallee Free = wd.freeFn();
  for (auto &[CI, K] : Fwd) {
    if (K != GateKind::Mint && !(K == GateKind::Alloc && isZeroAlloc(CI)))
      continue;
    B.CreateCall(Free, {CI});
    cloneTaint.ControlOwnedRails.insert(CI);  // defense-in-depth (DD-2).
  }
  if (Out) {
    cloneTaint.ControlOwnedRails.insert(Out);
    Ret->setOperand(0, Out);
  }
  return true;
}

}  // namespace cq
