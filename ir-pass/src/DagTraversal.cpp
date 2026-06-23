// DagTraversal.cpp — see header. Whole-DAG recovery (WI-4) via a visited-set
// worklist: backward from the terminals through every tainted operand (QQ = two
// parents), collecting in-place rotations + reassigning template producers, then
// the closure / measure / escape analysis over every recovered rail.

#include "DagTraversal.h"

#include "ChainWalk.h"          // isInPlaceGateOn / isAllocMint / isMeasureSink
#include "TaintPropagation.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

namespace {

// A `cq_invert_*` region call — Phase-7 manual inversion owns the handle (PRD
// §2.6); mirrors `FreePoint::isRecognizedEscapeUser`.
bool isInvertEscape(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cq_invert_");
}

// A reassigning template producer (`cq_template_<op>_<W>…`) — its result is a
// fresh rail the DAG must zero and free. (Rotations are in-place; allocs are
// roots; controlled forms / `_inv`/`_unc` twins are not forward data producers.)
bool isTemplateProducer(const CallInst *G) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // Phase 7.5: a QRAM load result is also a fresh rail the DAG must zero (via its
  // `_unc`) and free — and, crucially, must be CLOSURE-CHECKED here so a load whose
  // value fans out to a consumer OUTSIDE the recovered DAG marks the DAG NotClosed
  // (a Rule-8 safe-leak), never a use-after-free of a freed cell-copy.
  if (N.starts_with("cqrt_qram_load_") && !N.ends_with("_unc"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc");
}

}  // namespace

DataDag recoverDataDag(ArrayRef<Value *> Terminals, const TaintSet &taint,
                       DominatorTree &DT) {
  DataDag D;

  // 1. Backward worklist DAG recovery. Each handle contributes its in-place
  //    rotations as gates; a template-produced handle is itself a gate and hops
  //    to ALL its tainted operands (QQ ⇒ two parents); an alloc/non-call handle
  //    is a root. A visited-set dedups shared prefixes (fan-out reconvergence).
  SmallVector<Value *, 16> Work(Terminals.begin(), Terminals.end());
  SmallPtrSet<Value *, 16> VisitedHandles;
  SmallPtrSet<CallInst *, 16> SeenGates;
  while (!Work.empty()) {
    Value *H = Work.pop_back_val();
    if (!VisitedHandles.insert(H).second)
      continue;
    for (User *U : H->users())
      if (auto *G = dyn_cast<CallInst>(U))
        if (isInPlaceGateOn(G, H) && SeenGates.insert(G).second) {
          D.Calls.push_back(G);
          // A multi-input in-place gate — a Phase 7.5 QRAM store
          // `cqrt_qram_store_<W>(arr=H, idx, val)` — carries additional TAINTED
          // borrowed operands (idx, val) that are its parents in the DAG. Enqueue
          // them so their producers (the index rotation; a tainted store value's
          // chain) are recovered and reverse AFTER this gate's `_unc` (SSA
          // dominance: the gate `_unc` reads them, so it is emitted before their
          // own adjoints/frees). A rotation's only non-handle operand is a
          // classical angle (untainted), so this loop is a no-op for rotations.
          for (Value *Op : G->args())
            if (Op != H && taint.Tainted.count(Op))
              Work.push_back(Op);
        }
    auto *CI = dyn_cast<CallInst>(H);
    if (CI && !isAllocMint(CI)) {
      if (SeenGates.insert(CI).second)
        D.Calls.push_back(CI);
      for (Value *Op : CI->args())
        if (taint.Tainted.count(Op))
          Work.push_back(Op);
    } else {
      D.Roots.push_back(H);
    }
  }

  // 2. Program order (same block ⇒ position, else dominance, BirthOrder tie-break
  //    only — FileCheck-stable). Because every gate dominates the single
  //    insertion point (the driver's dominance check), dominance is a TOTAL order
  //    here, so reverse program order is an unambiguous reverse-topological order.
  llvm::stable_sort(D.Calls, [&](CallInst *A, CallInst *B) {
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

  // 3. Closure / measure / escape analysis over every RAIL (a root or a template
  //    producer's result — the values the DAG zeroes and frees; rotations mint no
  //    rail). Every forward consumer of a rail must itself be a recovered gate;
  //    anything else means the rail is owned outside the DAG.
  SmallPtrSet<Value *, 16> Rails;
  for (Value *R : D.Roots)
    Rails.insert(R);
  for (CallInst *G : D.Calls)
    if (isTemplateProducer(G))
      Rails.insert(G);

  for (Value *R : Rails) {
    // A Phase-4-owned control rail reached as a DAG ancestor (e.g. `x = merged +
    // 1` off a merge OUT-rail) is owned by Phase 4 (DD-4) — never reverse/free it.
    // Explicit, not incidental: the closure scan below would also catch it via the
    // rail's controlled-copy users, but ControlOwnedRails is the load-bearing
    // image (PRD §2.2) so the protection does not rest on that coincidence.
    if (taint.ControlOwnedRails.count(R)) {
      D.NotClosed = true;
      continue;
    }
    // A kept I/O output rail (7.6, PRD-7.6 §2.5) — never reverse/free it. The
    // `out_handle` of a `cqrt_tape_write_<W>` is not a data producer, so it is
    // never a DAG root or template-producer rail here, but the explicit
    // OutputRails subtraction is the SAME load-bearing discipline as
    // ControlOwnedRails above (do NOT rest on that incidental exclusion).
    if (taint.OutputRails.count(R)) {
      D.NotClosed = true;
      continue;
    }
    // A parked abort/exit graveyard rail (7.2 Inc 3, plan §2-A) reached as a DAG
    // ancestor — kept frozen + entangled, never reverse-played/freed (Rule 6).
    // Missing THIS site (subtracting only at terminal selection) would let a
    // graveyard rail reached as an upstream operand be reversed/freed = a hidden
    // collapse of the parked superposition; the explicit image is load-bearing
    // (the SAME discipline as ControlOwnedRails / OutputRails above — do NOT rest
    // on the closure scan's incidental controlled-cswap-user exclusion).
    if (taint.GraveyardRails.count(R)) {
      D.NotClosed = true;
      continue;
    }
    for (User *U : R->users()) {
      if (auto *CU = dyn_cast<CallInst>(U)) {
        if (isInPlaceGateOn(CU, R))
          continue;  // R's own in-place rotation — part of R's chain
        if (isMeasureSink(CU)) {
          D.MeasuredUpstream = true;
          if (!D.UpstreamMeasure)
            D.UpstreamMeasure = CU;
          continue;
        }
        if (isOutputSink(CU))
          continue;  // 7.6: a `cqrt_tape_write_<W>` SINK on R — it READS R (a
                     // CNOT-class copy that PRESERVES R; the kept out_handle is
                     // an OutputRails member, subtracted above), so it is NOT a
                     // forward data consumer and does NOT mark the DAG NotClosed:
                     // R's lineage uncomputes normally (Bennett, PRD-7.6 §2.4).
                     // Unlike a measure it is NOT a collapse (no MeasuredUpstream).
        if (isInvertEscape(CU)) {
          D.Escaped = true;
          continue;
        }
        if (SeenGates.count(CU))
          continue;  // a covered DAG gate — the legit fan-out / QQ consumer
        D.NotClosed = true;  // controlled copy/cswap, free, or out-of-DAG gate
        continue;
      }
      if (isa<ReturnInst>(U)) {
        D.Escaped = true;  // a returned rail — the caller owns its reversal
        continue;
      }
      if (auto *Phi = dyn_cast<PHINode>(U))
        if (Phi->use_empty())
          continue;  // a benign both-arm live-range merge (dead result)
      D.NotClosed = true;  // any other user we cannot prove reversible
    }
  }
  return D;
}

}  // namespace cq
