// DagTraversal.h — Whole-DAG recovery of a tainted data register (Phase 5 WI-4,
// PRD §2.1/§2.11). Pure analysis — emits no IR.
//
// The conservative WI-3 slice recovered a LINEAR reassignment chain per terminal
// and BAILED on fan-out (reversing a shared prefix twice). WI-4 recovers the whole
// def-use DAG from a SET of terminals via a visited-set worklist (the backward
// hop is every tainted operand, so a QQ node yields BOTH parents), adjointed once
// over a single reverse-topological pass. SSA dominance (def-before-use) makes
// reverse PROGRAM order a valid reverse-topological order, so `Calls` is returned
// in forward program order for the driver to walk in reverse.
//
// Reversal is sound ONLY for a CLOSED DAG: every forward consumer of every rail
// must itself be a recovered gate (so the whole sub-DAG returns to |0⟩ together).
// A rail read by a consumer OUTSIDE the DAG — a Phase-4 controlled copy/cswap that
// entangles it (the §16.5 safe-leak), a measurement sink, a `ret`/`cq_invert`
// escape, or a data gate leading to a measured/escaped terminal — means the rail
// is owned elsewhere and must stay allocated (Rule 6/8: never a dirty free). The
// recovery records that as `NotClosed`/`MeasuredUpstream`/`Escaped` so the driver
// declines (loudly for a measured register; a silent safe-leak otherwise).

#ifndef CQ_IRPASS_DAG_TRAVERSAL_H_
#define CQ_IRPASS_DAG_TRAVERSAL_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

namespace cq {

struct TaintSet;

// The recovered forward gate DAG of one or more terminals.
//   * `Calls`  — every in-place rotation and reassigning template producer in the
//                DAG, in FORWARD program order (the driver walks this in reverse,
//                adjointing each gate exactly once).
//   * `Roots`  — the `cqrt_alloc_<W>` / theta mints the DAG bottoms out at.
struct DataDag {
  llvm::SmallVector<llvm::CallInst *, 16> Calls;
  llvm::SmallVector<llvm::Value *, 8> Roots;

  // A NON-rotation rail (a root or a template result) in the DAG is read by a
  // `cqrt_measure_` sink. Reversing the DAG would free a register a user
  // measurement still reads — a hidden projective collapse (Rule 5/6). LOUD
  // decline; `UpstreamMeasure` carries the sink for the `!dbg` source location.
  bool MeasuredUpstream = false;
  llvm::CallInst *UpstreamMeasure = nullptr;

  // A DAG rail is consumed by a `ReturnInst` or a `cq_invert_*` call — it escapes
  // the function (the caller / Phase 7 owns its reversal). Silent skip (§2.6).
  bool Escaped = false;

  // A DAG rail has a forward consumer that is NOT a recovered gate: a Phase-4
  // controlled copy/cswap that entangled it (§16.5 safe-leak), a data gate
  // leading to a terminal we are NOT reversing, or any other unprovable user.
  // The sub-DAG is owned elsewhere — leave it allocated (Rule 6/8). Silent skip.
  bool NotClosed = false;

  // bd 261j(a) — rails that are RECORDED into a kept carrier (an output tape,
  // never uncomputed and never freed) AND whose forward chain is not a basis
  // permutation of still-live conditions. Such a rail is ENTANGLED with the
  // carrier at the free point, so re-emitting its adjoint does NOT return it to
  // |0⟩ and `cqrt_free` on it would be a hidden projective measurement (Rules
  // 5/6/8). A frozen rail gets NO FREE — it is LEFT ALLOCATED, the Rule-6
  // fallback. This is a PER-RAIL subtraction, not a DAG-global bail: every
  // non-frozen rail in the same DAG still frees.
  //
  // A frozen rail IS still fully reverse-played. The freeze suppresses the FREE and
  // never an adjoint — dropping the adjoint breaks invariant (d) for every
  // surviving rail that READS the frozen one, which the bd 261j(a) Rule-13 round
  // measured as four separate hidden measurements. See the long note at the
  // suppression site in `Uncomputation::emitDagReversal`.
  //
  // Consumed ONLY by `Uncomputation::emitDagReversal`, deliberately: `D.Calls`
  // stays intact so the driver's invertibility / InLoop / dominance scans still
  // see every recovered gate and still decline loudly. Pruning `Calls` instead
  // would blind all three (bd 261j(a) risks 1-2, MEASURED rc=1 → rc=0).
  llvm::SmallPtrSet<llvm::Value *, 4> FrozenRails;
};

// Recover the whole forward DAG of the registers whose live terminal handles are
// `Terminals` (a union — fan-out terminals sharing a prefix yield one DAG so the
// shared gates are recovered once). `DT` supplies the cross-block program order.
// The closure / measure / escape analysis (the fields above) runs over every
// recovered rail.
DataDag recoverDataDag(llvm::ArrayRef<llvm::Value *> Terminals,
                       const TaintSet &taint, llvm::DominatorTree &DT);

}  // namespace cq

#endif  // CQ_IRPASS_DAG_TRAVERSAL_H_
