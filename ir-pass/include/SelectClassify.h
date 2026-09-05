// SelectClassify.h — Pure-analysis detection ladder for a tainted-condition
// `select` (swap-route 4.4 / PRD Part IV §§15–18; IMPLEMENTATION-4.4 §0/§3).
//
// A tainted-condition integer-data `select` (the `-O1`-folded ternary / small
// if/else) is the SIMPLEST Phase-4 shape: one SSA instruction, no CFG diamond,
// no rail, no route, no `RegionFlatten`, no reverse-play. 4.4 lowers it via the
// controlled-XOR copy merge (`SelectMergeEmit`, WI-3). This TU is the WI-1
// front half: the §0 prove-or-decline ladder that either ACCEPTS the region
// (pushing a `SelectRegion` onto the plan — WI-3) or declines loudly. It MUTATES
// no IR — every gate is by SSA-value identity before any mutation (Rule 9), so
// it survives rotation lowering's later RAUW-to-handle.
//
// The six gates (IMPLEMENTATION-4.4 §0), in order:
//   1. tainted condition (entry; classical-cond is `declineClassicalMuxes`'s);
//   2. lowerable `CmpInst` condition (`comparePredLowerable`);
//   3. NOT an angle — the §3.2 BLOCKER: no transitive user of `%sel` through
//      value-preserving carriers reaches a `cq_phi`/`cq_theta` arg-1 (there is
//      NO downstream backstop — `declineTaintedAngle` runs after the select's
//      product is RAUW'd to an untainted handle, so the angle MUST be caught
//      here, pre-mutation; the f64/angle miscompile family);
//   4. ABI-width scalar-integer result, AFTER the FP-use fence (the f64 trap:
//      f64 has a valid width yet is an angle);
//   5. conservative coherent-operand default — no tainted value operand has a
//      downstream rotation/gate beyond the select (the channel-B dephasing
//      case); cleared/widened only by the §8 Rule-13 review;
//   6. distinct operands — the two value operands resolve to provably-disjoint
//      post-lowering registers (`diagonalAliasHit` closures do not intersect).
//
// Gates 1–2 are SSA-shape checks; gate 3 is the load-bearing BLOCKER; gates 4–6
// are over-decline-safe type/coherence/alias fences. Over-declining is always
// safe; a silent pass-through of quantum control is the only unforgivable bug
// (Prime Directive). See IMPLEMENTATION-4.4 §3, PRD Part IV §16.

#ifndef CQ_IRPASS_SELECT_CLASSIFY_H_
#define CQ_IRPASS_SELECT_CLASSIFY_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstrTypes.h"   // llvm::Instruction::BinaryOps (CondTree node ops)

namespace llvm {
class BinaryOperator;
class CmpInst;
class Instruction;
class DominatorTree;
class LoopInfo;
class SelectInst;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// 3c6m.12 (L4) — the compound-condition tree (compound-cond-select-PRD §2).
// A select condition is accepted as a TREE of `and i1`/`or i1`
// `BinaryOperator`s whose leaves are `CmpInst`s; a bare `CmpInst` root is the
// degenerate single-leaf tree (the pre-L4 shape, byte-identical emission).
// `Leaves` holds each UNIQUE leaf in first-visit (left-to-right post-order)
// order — a leaf shared by two tree positions appears ONCE (its flag mints
// once; the network's controls are read-only). `Nodes` is in post-order
// (children strictly before parents): exactly the emission order and,
// reversed, exactly the LIFO uncompute order.
// `Nodes` holds `Instruction *` rather than `BinaryOperator *` since bd
// test_C_libtooling-3qlq Inc 1 part B: with `AllowLogicalSelect` a node may also
// be a LOGICAL `SelectInst`. Ask `decomposeCondNode` for a node's operator and
// children — NEVER `cast<BinaryOperator>` at a use site (that cast is exactly
// what would crash, or silently mis-read, on the logical-select spelling).
struct CondTree {
  llvm::SmallVector<llvm::CmpInst *, 4> Leaves;
  llvm::SmallVector<llvm::Instruction *, 4> Nodes;
};

// THE GRAMMAR'S NODE DECOMPOSITION — one spelling, asked by the walk below AND
// by every emitter that reads a `CondTree` (`CondTreeEmit`). True iff `V` is an
// interior node, yielding its LOGICAL operator and its two i1 children.
//
//   * `and i1` / `or i1` / `xor i1` (`BinaryOperator`) — always;
//   * `select i1 %a, i1 %b, i1 false`  ≡ `and i1 %a, %b`   ⎫ only when
//     `select i1 %a, i1 true, i1 %b`   ≡ `or  i1 %a, %b`   ⎭ `AllowLogicalSelect`.
//
// The two logical-select forms are the CANONICAL LLVM-19 spelling of C's
// short-circuit `&&`/`||` (`clang -O1` emits them and InstCombine deliberately
// does NOT fold them to `and`/`or`, to keep the un-taken side's poison from
// propagating) — MEASURED on `if (q==5 && r==3) cq_phi(θ)`. The complementary
// spellings `select %a, i1 false, i1 %b` (≡ `¬a ∧ b`) and
// `select %a, i1 %b, i1 true` (≡ `¬a ∨ b`) are NOT admitted: they carry an
// implicit NOT, which is the same thing the `xor X, 1` fence declines, and no
// caller has a probe family for a negated leaf.
bool decomposeCondNode(llvm::Value *V, llvm::Instruction::BinaryOps &Opc,
                       llvm::Value *&L, llvm::Value *&R,
                       bool AllowLogicalSelect);

// Shape-only walk of `Root` into `Tree`: returns false on ANY off-grammar node
// (`freeze`, a general i1 `select` combinator, a phi/trunc/call/argument leaf).
// Purely structural — the taint/predicate/staleness gates live in
// `classifySelectRegion`. ONE walk shared by the classifier and
// `SelectMergeEmit` (which re-derives the tree at emit time and loud-bails on
// mismatch) so the accept predicate and the emitter cannot drift — the g387
// phase-invariant carve/enqueue discipline.
//
// `AllowLogicalSelect` (bd test_C_libtooling-3qlq Inc 1 part B) admits the two
// logical-select node spellings above. It is DELIBERATELY OFF for the 4.4 data
// select and the 6.x clone lift: `control_swap_reject_select_i1sel_combinator.ll`
// is a SHIPPED decline fixture for exactly that spelling on a data select, and
// flipping it is a widening of a DIFFERENT construct's accept set that this
// increment has no probe family for (Prime Directive — over-declining is safe).
// The register-free BRANCH PHASE (P3) turns it ON because the logical select is
// the ONLY spelling `clang -O1` hands its `br`. Widening the data select to
// match is a filed follow-on, not a side effect.
bool collectCondTree(llvm::Value *Root, CondTree &Tree,
                     bool AllowLogicalSelect = false);

// Run the §0 ladder on a tainted-condition `Sel`. On ACCEPT push a
// `ControlRegion{Kind=SelectRegion, Merge=Sel, Condition=Sel->getCondition()}`
// onto `plan` for `SelectMergeEmit` (WI-3); otherwise fire the precise loud
// diagnostic (`diagnoseUnderControl`) and leave the plan untouched. The caller
// (`ControlDetect`'s select scan) guarantees `taint.Tainted.count(getCondition())`
// — gate 1 re-checks defensively. No IR is mutated.
//
// WI-1 (this increment, emission unbuilt): an ACCEPT declines TRANSITIONALLY
// (`control flow`) instead of pushing — pushing a `SelectRegion` now would
// reach `emitRegion`'s null-block dereference (there is no `SelectRegion`
// dispatch until WI-3), so lowering nothing is the Prime-Directive-safe
// placeholder. WI-3 flips the ACCEPT branch to the push above.
//
// `wd` / `DT` / `LI` are threaded for GATE 3's `classifyAngleSelect` hook (bd
// drbq Inc 2b): the width fence asks the MINT's own expression
// (`wd.abiWidthFor(suffixFromName(...))`), the loop fence asks `LI`, and R6's
// position proofs ask `DT`. `DT`/`LI` may be null (the caller builds them
// LAZILY, on the first tainted branch OR select in the function) — a null pair
// makes the angle hook return `NotApplicable`, i.e. the pre-2b decline. All six
// pre-existing gates are unchanged and use none of the three.
void classifySelectRegion(llvm::SelectInst *Sel, TaintSet &taint,
                          WidthDispatch &wd, llvm::DominatorTree *DT,
                          llvm::LoopInfo *LI, ControlPlan &plan);

}  // namespace cq

#endif  // CQ_IRPASS_SELECT_CLASSIFY_H_
