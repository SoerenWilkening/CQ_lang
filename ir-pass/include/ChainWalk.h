// ChainWalk.h — Whole-register forward-chain reconstruction (Phase 5, PRD §2.1).
//
// A tainted DATA register is built by a chain of gates: a `cqrt_alloc_<W>` mint,
// in-place rotations (`cqrt_ry/rz_<W>`), and reassigning data templates
// (`cq_template_<op>_<W>[_hl|_lh]`) that each RAUW-produce a FRESH result handle
// (`q = q + 1; q = q * 2` ⇒ distinct i32 results h0 → h1 → h2). To emit the
// whole-chain adjoint ONCE at the last-use point (rather than per-SSA), Phase 5
// must recover that chain from the terminal handle.
//
// There is NO recorded lineage to walk: `BirthOrder` (TaintPropagation.h) is a
// flat monotonic mint counter used only for commutative-operand canonicalization,
// not a parent pointer (PRD §2.3, R-birthorder-not-lineage). So `recoverForwardChain`
// reconstructs the chain from DEF-USE operand threading — exactly the idiom of the
// tested `recoverPrepChain` (ControlledLowering.cpp:276-309, rotation-only +
// single-handle), GENERALIZED to also match `cq_template_*` data ops and to chase
// the RAUW reassignment lineage back to the alloc mint. `BirthOrder` is consulted
// only as a tie-breaker for cross-block-incomparable gates, to keep FileCheck output
// stable.
//
// Pure analysis — emits no IR.

#ifndef CQ_IRPASS_CHAIN_WALK_H_
#define CQ_IRPASS_CHAIN_WALK_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

namespace cq {

struct TaintSet;

// The recovered forward gate chain of one register, in FORWARD program order.
//   * `Calls`       — the in-place gates (rotations) and reassigning template
//                     producers that built the register, earliest first. The
//                     adjoint is emitted by walking this in REVERSE.
//   * `Terminal`    — the last (live) handle in the def-use lineage (the value
//                     passed in; the head the reverse walk threads from).
//   * `AllocHandle` — the `cqrt_alloc_<W>` mint the lineage bottoms out at (or
//                     the lineage root reached if no alloc is found).
struct ForwardChain {
  llvm::SmallVector<llvm::CallInst *, 8> Calls;
  llvm::Value *Terminal = nullptr;
  llvm::Value *AllocHandle = nullptr;
  // True when a NON-terminal handle in the lineage fans out — it has more than
  // one forward consumer (a sibling branch reads the same register). The linear
  // whole-chain reversal then does NOT apply: uncomputing the shared prefix
  // would run twice (once per terminal) and/or before the sibling's use. Step 2
  // is conservative and skips such terminals (true DAG/tree reversal is deferred);
  // the caller bails on this flag.
  bool HasFanOut = false;
};

// Reconstruct the whole forward chain of the register whose live terminal handle
// is `Terminal`. Walks the RAUW reassignment lineage back from `Terminal` to its
// `cqrt_alloc_<W>` mint via each producer's tainted data operand, then collects
// the per-link gates (the producer templates + the in-place rotations on every
// lineage handle) and orders them by program position (same block ⇒ `comesBefore`,
// else dominance, `BirthOrder` tie-break only). `DT` supplies the cross-block
// dominance order.
ForwardChain recoverForwardChain(llvm::Value *Terminal, const TaintSet &taint,
                                 llvm::DominatorTree &DT);

// Is `Handle` the TERMINAL of its register's def-use chain? True when no OTHER
// tainted instruction consumes it as a forward data operand — its only remaining
// users are non-producers (a measurement sink, a `ret` escape, classical reads,
// or its own in-place rotations, which mint no new handle). This collapses a
// reassigned-variable chain (`q = q + 1; q = q * 2`) to a SINGLE terminal so the
// whole chain is reversed once (PRD §2.1, R-whole-chain).
bool isTerminalHandle(llvm::Value *Handle, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CHAIN_WALK_H_
