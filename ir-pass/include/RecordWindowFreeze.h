// RecordWindowFreeze.h — the record-window half of the bd 261j(a) freeze
// (bd test_C_libtooling-r2j3.3). Pure analysis over one recovered DAG; it only
// ever ADDS to `DataDag::FrozenRails`, i.e. it can only remove `cqrt_free`s.
//
// THE GAP IT CLOSES. The 261j freeze (`DagTraversal` step 3b) asks, per rail,
// whether the rail's OWN gates are basis permutations, and freezes a recorded
// rail (or a recorded rail's ancestor) whose gates are not. That covers clauses
// (a)-(c) of the record-freeze invariant. Clause (d) — every register an adjoint
// reads holds the value it held when the forward gate ran — it leaves to
// "reverse program order", which delivers (d) only while nothing OUTSIDE the DAG
// looks at a register between a forward gate and its adjoint. A kept-carrier
// record (a tape write, a method-B copy-out) is exactly such a look:
//
//     G:  v = load(tbl, b)        reads b
//     N:  ry(b, -t)               non-basis gate on b, AFTER G
//     C:  tape(zext(b))           records b's POST-N label
//     ... reversal: ry(b, +t); load_unc(v, tbl, b); free(v)
//
// The tape distinguishes the post-N labels, so `ry(b, +t)` does not return b to
// its G-time label, `load_unc` recomputes from the wrong label, and `v` is not
// |0> at its free: a hidden measurement (Rule 5). The rail `v` is a perfectly good
// basis permutation of its parents — (a)-(c) hold — so step 3b cannot see it.
//
// THE RULE. For a gate G in the DAG and each tainted operand P of G (P not G's
// own rail): if some gate N in the DAG is in place on P, is NOT basis-preserving
// (`preservesBasisUnderRecord`), may run after G, and P's label after N is
// recorded into a kept carrier, then G's rail is frozen. "P's label at time t is
// recorded" is propagated BACKWARD from each kept-carrier record of a rail R at
// its sink S: R's label at S; and along each ancestor edge (child <- parent, read
// by gate E), a recorded child yields the parent's label at E, provided E may run
// before the record. Positions are compared with `provablyBefore`; anything not
// provably on the safe side counts against the rail (the freeze direction, a
// leak, Rule 6).
//
// WHY A RECORD BEFORE N, OR OF A RAIL MINTED BEFORE N, IS HARMLESS. N and its
// adjoint then sandwich a CNOT onto the carrier that never reads P's post-N
// label, so they commute past it and cancel exactly; P is restored. That is the
// `only_v` control of lowering_qram_load_index_record_window_freeze.ll and the
// interleaved-rotation shape of bd 261j's own fixtures, which must keep their
// frees.

#ifndef CQ_IRPASS_RECORD_WINDOW_FREEZE_H_
#define CQ_IRPASS_RECORD_WINDOW_FREEZE_H_

#include "llvm/ADT/ArrayRef.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Value;
}  // namespace llvm

namespace cq {

struct DataDag;

// One ancestor edge of a recovered DAG: `Gate` READ `Parent` while producing
// (or writing in place) `Child`.
struct AncestorEdge {
  llvm::Value *Child;
  llvm::Value *Parent;
  llvm::CallInst *Gate;
};

// Add to `D.FrozenRails` every rail the record-window rule above freezes.
// `Edges` are the ancestor edges `recoverDataDag` collected for `D`.
void freezeRecordWindowReaders(DataDag &D, llvm::ArrayRef<AncestorEdge> Edges,
                               llvm::DominatorTree &DT);

}  // namespace cq

#endif  // CQ_IRPASS_RECORD_WINDOW_FREEZE_H_
