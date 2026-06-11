// ChainWalk.cpp — see header. Whole-register forward-chain reconstruction from
// def-use threading (PRD §2.1). Generalizes `recoverPrepChain`
// (ControlledLowering.cpp:276-309) to `cq_template_*` data ops + the RAUW
// reassignment lineage; `BirthOrder` is a tie-breaker only.

#include "ChainWalk.h"

#include "TaintPropagation.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

namespace {

// The data-input handle of a producer call — the operand that carries the
// register's value into this gate (the chain predecessor). For a controlled
// producer the i32 flag is arg 0 (PRD §1.2), so the data operand starts at arg 1;
// for an uncontrolled producer every operand is a data candidate. Returns the
// FIRST tainted operand at/after that start (the single-register lineage handle),
// or null if none (a literal-only call / the alloc mint).
Value *dataInputHandle(CallInst *CI, const TaintSet &taint) {
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return nullptr;
  const unsigned Start = Callee->getName().contains("_controlled") ? 1 : 0;
  for (unsigned I = Start, E = CI->arg_size(); I < E; ++I) {
    Value *Op = CI->getArgOperand(I);
    if (taint.Tainted.count(Op))
      return Op;
  }
  return nullptr;
}

// An in-place, handle-threading gate on `H`: an UNCONTROLLED rotation
// `cqrt_ry/rz_<W>(H, θ)` whose arg 0 IS the handle (arg_size 2). These mint no
// new handle (void), so they belong to `H`'s link of the chain — exactly the
// `recoverPrepChain` predicate (ControlledLowering.cpp:291), which the 3-arg
// controlled forms and `_inv` twins fail. Self-adjoint `cqrt_x`/`cqrt_cswap` are
// Phase-4 flag scratch and are deliberately NOT pulled into a data chain.
bool isInPlaceGateOn(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
         !N.contains("_controlled") && G->arg_size() == 2 &&
         G->getArgOperand(0) == H;
}

bool isAllocMint(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_alloc_");
}

bool isMeasureSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_measure_");
}

// Number of FORWARD consumers of `H`: CallInst users that are neither an in-place
// rotation on `H` (which mints no new handle) nor a measurement sink. In a linear
// register chain each non-terminal handle has exactly ONE — its single producer
// successor. More than one means the register fans out (a sibling branch).
unsigned forwardConsumerCount(const Value *H) {
  unsigned N = 0;
  for (const User *U : H->users())
    if (const auto *CI = dyn_cast<CallInst>(U))
      if (!isInPlaceGateOn(CI, H) && !isMeasureSink(CI))
        ++N;
  return N;
}

}  // namespace

bool isTerminalHandle(Value *Handle, const TaintSet &taint) {
  if (!taint.Tainted.count(Handle))
    return false;
  // Terminal iff EVERY user is benign: an in-place rotation on `Handle` (which
  // mints no new value), a measurement sink, or a non-quantum read. ANY other
  // gate that takes `Handle` as an operand — a data/compare/cast template, a
  // controlled gate, a `_controlled`/teardown `_inv` — consumes the register
  // forward or keeps it live as control input, so `Handle` is NOT the terminal.
  //
  // This is deliberately STRICTER than a tainted-RESULT test: Phase-4 flag and
  // teardown producers (`cq_template_icmp_* → flag`, the `_inv` teardown) are NOT
  // in `taint.Tainted`, yet a condition register feeding them is still live (its
  // `_inv` teardown reads it after any candidate free point). Keying on the
  // result's taint would mis-free that base register — observed breaking the
  // control e2e goldens.
  for (User *U : Handle->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      continue;  // a classical/non-call read does not extend the quantum chain
    if (isInPlaceGateOn(CI, Handle) || isMeasureSink(CI))
      continue;  // in-place rotation (no new handle) or measurement sink
    return false;  // any other gate consumes `Handle` ⇒ not the chain terminal
  }
  return true;
}

ForwardChain recoverForwardChain(Value *Terminal, const TaintSet &taint,
                                 DominatorTree &DT) {
  ForwardChain FC;
  FC.Terminal = Terminal;

  // 1. Walk the RAUW reassignment lineage backward from the terminal to its
  //    alloc mint, hopping each producer's tainted data operand. Cycle-guarded.
  SmallVector<Value *, 8> Lineage;
  SmallPtrSet<Value *, 8> InLineage;
  for (Value *Cur = Terminal; Cur && InLineage.insert(Cur).second;) {
    Lineage.push_back(Cur);
    auto *CI = dyn_cast<CallInst>(Cur);
    if (!CI || isAllocMint(CI))
      break;  // reached a non-call root or the alloc mint
    Value *Pred = dataInputHandle(CI, taint);
    if (!Pred)
      break;
    Cur = Pred;
  }
  FC.AllocHandle = Lineage.empty() ? Terminal : Lineage.back();

  // Fan-out guard: every NON-terminal lineage handle must have exactly one
  // forward consumer (the next link). If any has more, the register is shared by
  // a sibling branch and the linear reversal is unsafe (Step 2 skips it). The
  // terminal itself (Lineage[0]) is exempt — its dead/measured/escape users are
  // the caller's concern.
  for (size_t I = 1, E = Lineage.size(); I < E; ++I)
    if (forwardConsumerCount(Lineage[I]) > 1) {
      FC.HasFanOut = true;
      break;
    }

  // Lineage-measure guard (test_C_libtooling-3h8): a NON-terminal lineage handle
  // read by a measurement sink. `forwardConsumerCount` excludes measure sinks
  // (a measured handle is a sink, not a fan-out branch), so the fan-out guard
  // above is BLIND to a measured upstream handle — yet the whole-chain adjoint +
  // `cqrt_free` this terminal would emit resets the shared physical register
  // BEFORE (or after) that measurement reads it: a hidden projective collapse
  // (Rule 5/6) and a verify-clean wrong unitary. Flag it for the caller's loud
  // decline. The terminal (Lineage[0]) is exempt — a measured terminal is the
  // existing silent Measured skip (FreePoint), reached before this walk.
  for (size_t I = 1, E = Lineage.size(); I < E && !FC.MeasuredUpstream; ++I)
    for (User *U : Lineage[I]->users())
      if (auto *CI = dyn_cast<CallInst>(U))
        if (isMeasureSink(CI)) {
          FC.MeasuredUpstream = true;
          FC.UpstreamMeasure = CI;
          break;
        }

  // 2. Collect the per-link gates: every lineage handle that is a template
  //    producer (i.e. a non-alloc call) IS a forward link, and each lineage
  //    handle's in-place rotations are links on it. A seen-set dedups (a handle
  //    appears once in the lineage; its rotations are unique users).
  SmallPtrSet<CallInst *, 8> Seen;
  for (Value *H : Lineage) {
    if (auto *CI = dyn_cast<CallInst>(H))
      if (!isAllocMint(CI) && Seen.insert(CI).second)
        FC.Calls.push_back(CI);
    for (User *U : H->users())
      if (auto *G = dyn_cast<CallInst>(U))
        if (isInPlaceGateOn(G, H) && Seen.insert(G).second)
          FC.Calls.push_back(G);
  }

  // 3. Program order: same block ⇒ position, else dominance, with BirthOrder as
  //    the ONLY tie-breaker for cross-block-incomparable gates (FileCheck-stable).
  llvm::stable_sort(FC.Calls, [&](CallInst *A, CallInst *B) {
    if (A == B)
      return false;
    if (A->getParent() == B->getParent())
      return A->comesBefore(B);
    if (DT.dominates(A, B))
      return true;
    if (DT.dominates(B, A))
      return false;
    return taint.BirthOrder.lookup(A) < taint.BirthOrder.lookup(B);
  });
  return FC;
}

}  // namespace cq
