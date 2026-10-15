// MergeCarriedFenceFresh.h — clause (iv) of the carried-merge fence's hazard
// set: is a protected register FRESH (in a product state) at a gate? (bd
// test_C_libtooling-r2j3.36; the hazard set is stated in MergeCarriedFence.h.)
//
// THE INVARIANT. A register minted |0⟩ (or classical-seeded) and never COUPLED
// to another register before the gate is in a product state, so no gate on it
// can interfere branches a leaked record tells apart. Two producers qualify,
// everything else (a template result, a φ, a select) is never fresh:
//   * an ALLOCATION `cqrt_alloc_*` A: fresh at C when no coupling use of A's
//     alias class (`handleAliases`) lies on a CFG path A → X → C on which A
//     does not run again;
//   * a CELL LOAD L of a `!cq.railbank` bank (R11 round 1, F1: the 01po.19 S4
//     materialized arrays load each cell per trip), fresh at C when
//       (a) the bank alloca's direct users are cell addresses and lifetime
//           markers only (no initializer, carve clause C1), and every rail
//           its stores park (`railBankParkedRails`, RailBankPromote's one
//           address-tree walk) is a `cqrt_alloc_*` mint used only for parks
//           into this bank (materialization or rebind to a fresh mint: the
//           cell's register is |0⟩ when parked). Residual: a CONSTANT cell
//           store is invisible to that walk's wrapper. It is declined
//           DOWNSTREAM, after uncompute, in both entry points
//           (`declineNonHandleBankStores`), so the module still fails
//           loudly — which holds only while no stage between uncompute and
//           that check erases the store; see `materializedBank`;
//       (b) L's address is an affine SCEV AddRec of the CARRIED loop TL with a
//           nonzero step and a no-wrap flag, and TL is outermost — so distinct
//           trips of TL's one activation read distinct cells;
//       (c) no coupling use of a cell load with the SAME address SCEV lies on
//           a path X → C inside one trip (not through TL's header), and no
//           coupling use of a cell load with any OTHER address lies on any
//           path X → C. A different SCEV is never exempted: `b[i+1]` in trip k
//           is `b[i]` in trip k+1, so "the two indices differ" (isKnownNonZero
//           of the difference, same iteration) proves nothing across trips.
//     Anything unproven: not fresh (fail closed).
// A COUPLING USE of a register's (local) class is any user that is not a
// carrier inside the class, not a park into a proven rail bank, and not a
// runtime call touching one handle (a local gate, a measurement, a free).
//
// ⚠ THE STORE SKIP RELIES ON `handleAliases` (R11 round-1 note, reviewer A):
// `freshAt` skips a store user unconditionally because `handleAliases` has
// already REFUSED (returned false, so not fresh) any store that is not a park
// into a proven rail bank, and has put that bank's cell loads into the class.
// Loosen `handleAliases`' memory clause and this skip becomes unsound.

#ifndef CQ_IRPASS_MERGE_CARRIED_FENCE_FRESH_H_
#define CQ_IRPASS_MERGE_CARRIED_FENCE_FRESH_H_

#include "llvm/ADT/SmallVector.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Instruction;
class Loop;
class ScalarEvolution;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The HANDLES a call touches: every i32 register operand in a state slot
// (`readsState`), plus its i32 result when that is a fresh handle (a runtime
// or lifted producer, never a measurement's classical value).
void carriedFenceHandlesOf(llvm::CallInst *C, const TaintSet &taint,
                           llvm::SmallVectorImpl<llvm::Value *> &H);

// Is there a CFG path that runs `From`, then `To`, on which `Redef` does NOT
// run strictly in between? `From == To` asks for a cycle.
bool runsWithoutRedef(const llvm::Instruction *From,
                      const llvm::Instruction *To,
                      const llvm::Instruction *Redef);

// Clause (iv): is `V` fresh at `C`? `TL` is the loop carrying the record
// (`SE` is built over its function). See the header comment.
bool carriedFenceFreshAt(llvm::Value *V, const llvm::Instruction *C,
                         const llvm::Loop *TL, const TaintSet &taint,
                         const llvm::DominatorTree &DT,
                         llvm::ScalarEvolution &SE);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_CARRIED_FENCE_FRESH_H_
