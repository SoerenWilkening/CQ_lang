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

#include "llvm/ADT/STLFunctionalExtras.h"  // llvm::function_ref (IsLiteral)
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstrTypes.h"   // llvm::Instruction::BinaryOps (CondTree node ops)

namespace llvm {
class BinaryOperator;
class CmpInst;
class Instruction;
class DominatorTree;
class LoopInfo;
class PHINode;
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
  // bd test_C_libtooling-3qlq.4 (Inc 1b) — RAIL LEAVES. A leaf that is not a
  // compare but a tainted `i1` REGISTER: the result of a `cq_theta_i1` call
  // (root mint or chained), i.e. `_Bool b = b0; cq_theta(&b, θ); if (b) …`. Such a
  // leaf mints NO flag — the register IS its own flag (`isCondRailLeaf`), so
  // `CondTreeEmit` maps it to itself and strips/frees NOTHING for it.
  //
  // ⚠ EVERY CONSUMER THAT READS `Leaves` MUST DECIDE ON `RailLeaves` EXPLICITLY.
  // A consumer that iterates `Leaves` alone and treats the tree as compare-only
  // would silently mint a network with a missing child (the emitter reports
  // `Malformed`) or, worse, accept a shape it never proved. The shipped
  // dispositions: the register-free branch phase (flat kickback, the depth-2
  // nest, the Rz-stem angle select) ACCEPT rail leaves; the 4.4 data select, the
  // Ry-stem angle select and the 6.x clone lift DECLINE them loudly with
  // `kBareRailCondReason` — those are the filed follow-on increments, not
  // omissions. `collectCondTree` returns true iff at least one leaf of EITHER
  // kind was collected.
  llvm::SmallVector<llvm::CallInst *, 2> RailLeaves;
  // bd `boi6` (D-B) / Track M — REGION-MERGE-φ RAIL LEAVES. The `Merge` φ of a
  // diamond ALREADY accepted into the plan as a controlled in-place Ry / state
  // PREP (`ArmClass::InPlaceRotation`): `bool b1 = 0; if (!b0)
  // cq_theta(&b1, .5); if (b1) a -= 3;`, which `clang -O1` hands over as
  // `select i1 %phi, …`. Such a φ is NOT a `CallInst`, so it can never join
  // `RailLeaves` — THE ELEMENT TYPE THERE IS THE ENFORCEMENT (bd `boi6` H-3:
  // retyping it to `Instruction *` would hand a φ, with no code change and no
  // review, to the depth-2 nest, the Rz-stem angle select, the kickback,
  // `Specialization` and `SwapRouteEmit`). A SECOND field is the whole point.
  //
  // ⚠ THE SAME OBLIGATION AS `RailLeaves`, RE-ARMED FOR THIS FIELD: EVERY
  // CONSUMER THAT READS `Leaves` MUST DECIDE ON `RailPhiLeaves` EXPLICITLY. A
  // consumer that iterates `Leaves`/`RailLeaves` and treats the tree as
  // compare-plus-call-only accepts a shape it never proved. The shipped
  // dispositions, decided ONCE (bd `boi6` H-8) and EXTENDED ONCE (bd `3qps`,
  // Track P): exactly TWO classifiers admit a φ leaf — `classifySelectRegion`
  // (the 4.4 data select) and `ArmClassify::classifyPhaseKickback` (the
  // register-free branch phase) — and BOTH prove it by CALLING the one owner of
  // "what this merge φ becomes", `preppedRailPhiRegionIdx` over the region's own
  // committed `ClassArm`/`Shadow` verdict in `plan.Regions` (`ArmClassify`),
  // never by re-deriving it (Rule 14, the drbq Inc-3 (b′) lesson).
  // `Specialization` SKIPS a φ-carrying tree. Every OTHER consumer sees
  // `AllowRailPhi == false`, so its string is UNCHANGED: a φ at a VALUE/EQ-FOLD
  // `br` keeps `control flow` (`ArmClassify`'s ternaries are deliberately
  // untouched), a φ at the depth-2 NEST or at the Ry-stem angle select keeps its
  // own, a φ in a loop keeps the loop layer's. Re-pointing `kBareRailCondReason`
  // at a φ would claim a rail capability that does not exist at those consumers
  // and would move shipped fixtures' strings without moving a disposition.
  //
  // ⚠ THE FLAT KICKBACK IS THE ONE STRING THAT MOVED, and only because its
  // DISPOSITION moved: `if (b1) cq_phi(θ)` on a prep φ WAS
  // `branch phase on a bare i1 condition` and is now an ACCEPT (bd `3qps`). The
  // discriminator survives intact — that string still fires for every `i1`
  // residual the grammar does not admit (`trunc`/`zext`/argument — bd `r903`; a
  // loop-carried header φ — bd `boi6`; and a φ NO region claimed, which is this
  // increment's own decline family).
  llvm::SmallVector<llvm::PHINode *, 2> RailPhiLeaves;
  llvm::SmallVector<llvm::Instruction *, 4> Nodes;
  // bd `test_C_libtooling-xdu2.13` — CLASSICAL LITERAL children of an `and`/`or`
  // node, collected ONLY when the caller passes `IsLiteral` (the 4.4 data select
  // and its emitter; see `CondLiteral.h`). Not walked into, never minted: the
  // node becomes `cq_template_<op>_i1_hl(flag, literal)`. `LiteralNodes` pairs
  // each (node, literal, tainted sibling) so the classifier can refuse a RAIL
  // sibling. ⚠ The same obligation as `RailLeaves`: every consumer that reads
  // `Leaves` must decide on these explicitly — the ones that do not pass
  // `IsLiteral` never see any.
  struct LiteralNode {
    llvm::Instruction *Node;
    llvm::Value *Literal;
    llvm::Value *Sibling;
  };
  llvm::SmallVector<llvm::Value *, 2> LiteralLeaves;
  llvm::SmallVector<LiteralNode, 2> LiteralNodes;
};

// bd 3qlq.4 — THE ONE SPELLING of "this condition value is a bare i1 REGISTER".
// True iff `V` is a call to `@cq_theta_i1` (the frozen `_Bool` spelling of the
// taint source, `include/CQ.h`), whose result is the register's own rail after
// `lowerRotations` RAUWs it to its `i32` handle. Deliberately NARROW: a `trunc`,
// a `zext`/`sext`, a `phi` (a loop-carried or region-merge rail), a template
// result, a clone `Argument` or a QRAM load are tainted `i1` values too, but
// each is a DIFFERENT rail story (a derived rail needs a mint+discharge; a merge
// phi is dissolved by a preceding emitter; an argument is a clone's) and none is
// admitted here — they keep the pre-existing `branch phase on a bare i1
// condition` decline, which is exactly what makes that string a discriminator.
bool isCondRailLeaf(const llvm::Value *V);

// bd `boi6` (D-B) / Track M — THE SYNTACTIC HALF of "this condition value is the
// merge φ of a region the plan already owns". DELIBERATELY WEAK, and the weakness
// is the design: true for any 2-incoming `i1` `PHINode`, because the PROOF is not
// a shape question at all — it is the classifier asking `plan.Regions` whether
// some `BranchRegion` committed that very φ as its `Merge` with an
// `InPlaceRotation` arm (`classifySelectRegion`'s rung 0). Taint is NOT asked
// here either (neither does `isCondRailLeaf`): rung (i) re-asks it, so an
// untainted φ admitted by the grammar still declines `control flow`, the same
// string it takes today.
//
// TWO CALLERS, TWO JOBS. `collectCondTree` uses it behind `AllowRailPhi` to
// admit the leaf; `RegionFlatten` uses it beside `isCondRailLeaf` so that a
// φ-conditioned region can never erase its own condition. The latter has NO
// SUBJECT today — the φ's erasure belongs to the PREP region's own
// `emitInPlaceRotationRegion`/`flattenRegion`, not to the select's — and it is
// added as defence in depth, so that the first widening which gives a
// φ-conditioned region a `Pred`/`MergeBB` of its own does not re-open the L9
// block-lifetime hole silently.
bool isCondRailPhiShape(const llvm::Value *V);

// bd `fn1q` increment 5a — `isCondRailPhiShape` AND every incoming is a rail
// (`isCondRailLeaf`) or an `i1` constant. The refinement exists because
// `PredMuxFlatten`'s E6 gate runs BEFORE `detectControlRegions` and so cannot ask
// `preppedRailPhiRegionIdx`; this is the strongest thing provable there with no
// plan and no taint. ⚠ NECESSARY, NOT SUFFICIENT — a φ it admits can still be
// refused downstream, with the verdict and the string unchanged. Read the
// definition before adding a caller.
bool isStructuralRailPhi(const llvm::Value *V);

// bd `boi6` (D-B) / Track M — THE SEMANTIC HALF, and THE ONE SPELLING OF RUNG 0
// (Rule 14). Returns the INDEX in `plan.Regions` of the `BranchRegion` that
// COMMITTED `P` as its `Merge` with an `InPlaceRotation` arm (the controlled
// in-place Ry arm and the controlled state PREP share that class and that
// emitter), or `ControlRegion::kNoParent` when no region did.
//
// It RE-DERIVES NOTHING: `ArmClassify::classifyArms` is the one owner of "what
// this merge φ becomes", and this reads its committed `Merge`/`ClassArm`/
// `Shadow` fields by SSA-value identity. See the definition in
// `SelectClassify.cpp` for why each conjunct is there.
//
// ⚠ TWO CONSUMERS, ONE SPELLING (bd `3qps`, Track P): `classifySelectRegion`'s
// §M.0 ladder for the 4.4 DATA SELECT, and `ArmClassify::classifyPhaseKickback`
// step 5c for the register-free BRANCH PHASE. Both ask this function; NEITHER
// re-derives its conjuncts. An INDEX rather than a pointer because the select
// consumer must RECORD it (`ControlRegion::PrepRegionIdxs`) and `plan.Regions`
// is a `SmallVector` that reallocates.
unsigned preppedRailPhiRegionIdx(const llvm::PHINode *P,
                                 const ControlPlan &plan);

// bd 3qlq.4 — the ONE decline string for a rail-leaf condition reaching a
// consumer that does not lower it yet (the 4.4 data select, the Ry-stem angle
// select, and — through `ControlDetect`'s off-pattern fall-through — the value /
// in-place-Ry / state-prep / abort / tape / guarded-store arms). Mirrored
// character-for-character by the `control_*_reject_rail_*.ll` fixtures, so each
// follow-on increment that lowers one of those flips its own fixture and no
// other.
constexpr const char *kBareRailCondReason = "bare i1 register condition";

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
//
// `AllowRailPhi` (bd `boi6` D-B / Track M) admits `isCondRailPhiShape` leaves.
// The `AllowLogicalSelect` precedent verbatim: one grammar, per-consumer
// verdicts, default OFF. Passed `true` by exactly TWO callers (bd `3qps`, Track
// P) — `classifySelectRegion` for the 4.4 DATA SELECT and
// `ArmClassify::classifyPhaseKickback` for the register-free BRANCH PHASE, plus
// each one's own emitter re-derivation, which MUST pass the same value or the
// walk drifts between detection and emission.
//
// ⚠ ROOT-ONLY IS GONE (bd `4aiu`, Track P) — Track M's `V == Root` conjunct was
// a SCOPE decision, and its retirement trigger has fired. A φ at an INTERIOR
// position reaches `CondTreeEmit`'s NON-root rail path, where it is mapped to
// itself and read as a READ-ONLY control of the node's `cqrt_toffoli`/`cqrt_cnot`
// — the identical path an interior `isCondRailLeaf` rail has taken since bd
// 3qlq.4. It is now measured on the ORACLE with the φ already RAUW'd
// (`trackP/probes/p18.ll`, 18 lines: `cqrt_toffoli(rail, cmpflag, g)`, `rz` on
// `g`, the LIFO undo, one free) and pinned by its own fixtures and probe family.
// `control_swap_reject_select_mergephi_tree_leaf.ll` was flipped to the ACCEPT
// `control_swap_accept_select_mergephi_tree_leaf.ll` with its stream derived from
// the pass output, exactly as that fixture's own trigger instructed.
//
// ⚠ WHAT IS *STILL* NOT ADMITTED, so the grammar's shape stays readable: a φ is a
// LEAF, never a NODE — `decomposeCondNode` is not widened, so a tree cannot be
// rooted in a φ that combines two conditions. And `AllowLogicalSelect` remains
// independent (FALSE for the data select, TRUE for the branch phase): the two
// flags are orthogonal, and a data select over `b1 && q > 3` still declines on
// the logical-select node, not on the φ (bd `xqgx` (3)).
//
// `IsLiteral` (bd `test_C_libtooling-xdu2.13`) — when non-null, a child of an
// `and`/`or` node (never an `xor`, never the root) for which it returns true is
// recorded in `Tree.LiteralLeaves`/`LiteralNodes` and NOT walked. Null (every
// caller but the 4.4 data select and its emitter) is byte-identical to before.
// The classifier passes `condLiteralAdmissible`; the emitter passes MEMBERSHIP
// of the classifier's committed `ControlRegion::CondLiterals`, so the two walks
// cannot drift. A node whose BOTH children are literals is off-grammar.
bool collectCondTree(llvm::Value *Root, CondTree &Tree,
                     bool AllowLogicalSelect = false,
                     bool AllowRailPhi = false,
                     llvm::function_ref<bool(llvm::Value *)> IsLiteral = nullptr);

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
