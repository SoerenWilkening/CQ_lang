// ControlPlan.h — Shared data shapes for controlled-region lowering.
//
// NOTE (swap-route-control branch): the old controlled-op lowering that produced
// and consumed a populated `ControlPlan` (ControlDetection / ControlledLowering /
// ControlFlag / ControlledSubstitution / MergeDissolution / CFGLinearization)
// was removed pending the RSSA swap-route emitter. The struct survives because
// `RotationLowering` reads `plan->InShadow` to skip in-shadow gate bodies; the
// WI-1 `detectControlRegions` (ControlDetect.cpp) recognizes the swap-route
// phase-arm shape but, having no emitter yet, declines every tainted region and
// returns an EMPTY plan (no regions, empty InShadow), so every rotation lowers
// uncontrolled. The rich `ControlRegion` fields below are retained as the design
// vocabulary the swap-route emitter will reshape — they are currently unpopulated.
//
// Historical shape (PRD §2.2/§2.6/§2.10/§2.11, IMPLEMENTATION §5.1).
//
// Detection is PURE ANALYSIS (no IR mutation) so it runs before
// `lowerRotations`: the region/shadow membership is by SSA *value* identity,
// which survives the rotation lowering's RAUW-to-handle (the gate-body
// `cq_phi` CallInst* is stable until it is itself erased). `Condition` /
// `Merge` are likewise stable instruction identities.

#ifndef CQ_IRPASS_CONTROL_PLAN_H_
#define CQ_IRPASS_CONTROL_PLAN_H_

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/ValueHandle.h"  // WeakTrackingVH — see `RoutedBase`

namespace llvm {
class BasicBlock;
class ConstantInt;
class Instruction;
class Module;
class PHINode;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// 4.2 (PRD Part II §8.3) — per-arm content class. A region is lowerable only
// when HOMOGENEOUS: all-phase or all-value (method-B: route + chain replay +
// copy-out + reverse-play) over ONE shared routed base.
//
// ⚠ HOW A `Phase` ARM IS EMITTED DEPENDS ON THE EMITTER, AND IT IS NO LONGER
// "the 4.1 route" EVERYWHERE (bd drbq Inc 2a, 2026-09-02; round-1 review L3 F4).
//   * FLAT regions (`SwapRouteEmit::emitRegion` — diamond, if/else, hcrg
//     sequential, the 8h7d.5 rolled in-loop region, `ShareCondFlag`, the 4.5
//     eq-folded diamond) lower CONTROL-IN-PLACE: flag mint, ONE
//     `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate, icmp_inv flag-strip, flag
//     free. No work rail, no `cqrt_cswap`.
//   * The 4.3 depth-2 nest (`NestedRouteEmit`) and the 4.5 switch
//     (`SwitchRouteEmit`) KEEP the 4.1 route + verbatim-Rz replay + icmp_inv
//     strip. `SwitchClass::Phase`'s doc below is therefore still literally true —
//     do not "fix" it to match this one. Any mixture — phase and value
// links in one chain, or a phase arm beside a value arm in an if/else —
// declines `mixed phase/value arm`: a chain carrying both a phase and a
// changed basis has no copy-safe, strip-valid lowering (the CNOT copy
// dephases the Rz answer, Rule 7; §6a control-in-place territory). `Phase` is
// the default so the 4.1 phase-arm paths need not write it.
//
// `InPlaceRotation` (control-in-place-PRD §4, bd test_C_libtooling-drbq Inc 1)
// is the THIRD class, and it is neither of the other two — Rule 7 again: a
// tainted-control Ry arm is not a phase arm (the answer is a superposition, not
// a phase, so the route's "the work rail is |0⟩ for free" premise is FALSE and
// the inactive rail comes back dirty and entangled, PRD §2) and not a value arm
// (method-B's copy-out copies a basis LABEL and dephases it). It has NO route
// and NO work rail at all: the arm's `cq_theta` is HOISTED to the pred and
// lowered as `cqrt_ry_<W>_controlled(flag, R, θ)` in place on the user's own
// register, with the flag minted and stripped exactly as a phase arm's is.
// The arm's single `cq_theta` is recorded in `Shadow`/`ShadowFalse`.
enum class ArmClass { Phase, Value, InPlaceRotation };

// 4.5 (PRD Part V §20.5) — the per-CONTENT-class discriminator for an accepted
// `SwitchRegion`, parallel to `ArmClass`/`ClassArm` (a *content* class, NOT a
// top-level `Kind`). `Phase` = homogeneous phase-arm switch (route + verbatim-Rz
// replay + icmp_inv strip, zero controlled gates); `Value` = homogeneous value
// chain on a base `p != q` (method-B route + chain replay + copy-out +
// reverse-play); `DataMux` = all-`ConstantInt` merge incomings (preload + per-case
// XOR-delta controlled-copy). Scoped (`enum class`) so its `Phase`/`Value`
// enumerators do NOT collide with `ArmClass`'s in the `cq` namespace.
enum class SwitchClass { Phase, Value, DataMux };

// WP18 (PRD §8.5) — one case arm of a gated `SwitchRegion`: the case constant(s)
// targeting it, its arm block, and the arm's in-shadow gate bodies (the `cq_phi`
// calls that become `_controlled` on the arm's flag). The DEFAULT arm is carried
// by the region's own `Arm`/`Shadow` (controlled on the ¬OR "none-matched" flag).
//
// `Values` holds ALL case constants that target `Block`: usually one, but a
// SHARED arm block — two+ case values folded onto one body by `clang` for
// duplicate-body cases (test_C_libtooling-6qg) — carries several. The arm is then
// controlled on the OR of its cases' `icmp eq` flags (`f_{v1} ∨ … ∨ f_{vm}`),
// which gates both the gate-body substitution and the angle difference.
struct SwitchArm {
  llvm::SmallVector<llvm::ConstantInt *, 2> Values;
  llvm::BasicBlock *Block = nullptr;
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;
};

// One recovered controlled region, normalized from a tainted `select i1` or a
// tainted `br i1` diamond to a single internal shape (IMPLEMENTATION §5.1).
// WP3 builds only the `BranchRegion` (`br`-diamond) case; the `SelectRegion`
// fields/enum are present for WP4 but unused here.
struct ControlRegion {
  // The tainted i1 condition that gates the region: the `br`/`select`
  // condition. For a plain compare it is the `CmpInst` itself; for a
  // compound `&&`/`||` it is the flag-combination `SelectInst`
  // (`select i1 %fa, i1 %fb, i1 false` / `…, i1 true, i1 %fb`, PRD §2.5),
  // whose sub-compares live in `CondA`/`CondB`. Lowered as the control flag
  // by `ControlFlag`; the original instruction stays until linearization
  // erases it (§1.3, keeps the `br i1` well-typed mid-pass).
  llvm::Value *Condition = nullptr;

  // ⚠ THE WP5 COMPOUND-CONDITION FIELDS (`Conj`/`CondA`/`CondB`/`FlagA`/`FlagB`)
  // AND THE `Flag` FIELD ARE **DELETED** (bd test_C_libtooling-3qlq Inc 1 part
  // B). They belonged to the EXCISED controlled-op generation
  // (`ControlFlag::lowerControlFlag` + `FlagConjunction::combineFlags`, neither
  // of which exists), were written by nothing and read by nothing, and would
  // have been a SECOND representation of a compound condition beside the one
  // that is now real: the `CondTree` walk (`SelectClassify.h`), re-derived from
  // `Condition` by every consumer and lowered by `CondTreeEmit`. Do not
  // resurrect them — a compound condition is a TREE, not a two-compare pair, and
  // the tree is the thing the emitter and the classifier share.

  // The INNER condition of a depth-2 register-free PHASE NEST
  // (`Kind == PhaseKickbackNest`; null for every other kind). Like `Condition`
  // it is the ROOT of a `CondTree` — a `CmpInst` or a logical `and`/`or`/`xor`
  // tree over compares — and is re-derived, never cached as a flag.
  llvm::Value *InnerCondition = nullptr;

  // SelectRegion — a tainted-condition DATA select (the WP4/4.2 mux, integer
  // handle width). BranchRegion — a `br`-diamond (WP3/WP5/WP8).
  //
  // AngleSelectRegion (control-in-place-PRD §12.3, bd test_C_libtooling-drbq
  // Inc 2b) — a tainted-condition select over the classical rotation ANGLE
  // (`select i1 %c, double A, double B`) whose SOLE user is the arg-1 slot of a
  // chained `cq_theta`/`cq_phi` `T`. `Merge` is the select, `Condition` the bare
  // single-user compare, and `Shadow` holds exactly ONE element: the consuming
  // rotation. Every block field stays NULL (there is no CFG diamond — the user
  // wrote the select, or, for `cq_phi` only, `clang -O1` SimplifyCFG merged the
  // two arms into this one call; for `cq_theta` that merge is forbidden by CQ.h's
  // `nomerge` since bd test_C_libtooling-fmt3, 2026-09-28), which makes the
  // region inert to `lowerControlRegions`' cross-region pre-flight exactly like a
  // `SelectRegion`.
  //
  // Lowered by `AngleSelectEmit` BY DIFFERENCE, which is exact IN REAL
  // ARITHMETIC by angle additivity on one axis (`R(A) = R(B)·R(A−B)` for both Ry
  // and, under `Rz = diag(1,e^{iθ})`, Rz — the diagonals multiply entrywise, so
  // there is no global-phase residue). In IEEE double the emitted true-arm angle
  // is `B + fl(A−B)`, `|δ| ≤ ½ ulp(A−B)`, so **BOTH ARMS MUST BE `ConstantFP`**
  // and their evaluated residual must sit under the placeholder
  // `kAngleSelectMaxRoundingRad` = 2^-40 rad. A RUN-TIME arm DECLINES (`rotation
  // angle under quantum control`): the compiler would synthesize an `fsub` the
  // source never wrote, whose error is unbounded in absolute radians (measured
  // 0.858 rad from plain C — `Ry(pi)` realized as `Ry(4.0)`) and whose result can
  // be `inf`/`NaN` from two FINITE arms (measured: `inf` in the controlled gate
  // from ±8.99e307), neither fenceable at compile time. That narrowing is the
  // Rule-13 CLEARANCE review's (finding F-11, owner option (2)); the rounding
  // fence itself is the round-1 review's (lens L7-F1) and the both-halves wording
  // the round-2 one's (lens R1 item 1). The stream is an
  // UNCONDITIONAL `R(h, B)`, the ordinary flag mint,
  // the drbq in-place `R_controlled(f, h, A−B)`, the ordinary strip, one
  // `cqrt_free`. No CFG surgery, no hoist, no flatten, no `cqrt_x` bracket (a
  // select always means "A when the flag is 1", so there is no polarity case),
  // no work rail and no route.
  //
  // ⚠ THE ENUMERATOR PRE-DATES THAT DESIGN. It was declared for the retired WP10
  // "Family B2" vocabulary and was read by NO src file until Inc 2b; the text
  // above describes what it means NOW. Its old sibling fields `AnglePhi` /
  // `AngleConsumers` below belong to that retired design and are still populated
  // by nothing.
  // SwitchRegion (WP18, PRD §8.5) — a gated multi-arm `switch` whose arms apply
  // distinct SIDE-EFFECTING gate sequences (not a value/angle select). `Pred`
  // is the switch block, `Condition` the tainted scrutinee, `MergeBB` the common
  // merge, `SwitchArms` the case arms (case value(s) + block + gate shadow), and
  // `Arm`/`Shadow` the DEFAULT arm. Lowered by `lowerGatedSwitch`: per-case
  // `icmp eq` flags, each arm controlled on the OR of its cases' flags, the
  // default on the ¬(f_1∨…∨f_n) flag, the N-way φ dissolved, switch linearized.
  // ClassicalCallArm (6.5, DD-7) — a tainted-condition `br`-diamond whose single
  // content arm computes a PURE CLASSICAL call (all-classical-args) whose i32
  // result `c` feeds the 2-incoming merge `φ` (the other incoming the tainted
  // straight-through `q`). NOT a clone-on-taint site (mask 0 / `readsTaintedValue`
  // false — no SpecPlan membership). Lowered by `ClassicalCallArmEmit`: hoist the
  // pure call into `Pred` (inert), then the 4.4-style controlled-copy merge over
  // the FLATTENED diamond — no cswap/route, no reverse-play, no clone. `Pred`/`Arm`/
  // `MergeBB`/`Merge` and `ArmNegated` (Rule 9 polarity) carry the shape exactly as
  // a `BranchRegion` diamond does; the call is re-derived as the `Arm`-edge merge
  // incoming (the emitter is a pure consumer of the by-identity plan).
  // AbortPark (7.2 Inc 3, PRD-7.2 §2.8 / §2.11-B) — a tainted-condition `br`
  // whose one arm is a recognized NORETURN SINK (`@abort`/`@exit`/…/`@llvm.trap`
  // + `unreachable`, NO value, NO merge φ), the sibling being the ordinary
  // uncontrolled remainder. `Pred` is the branch block, `Arm` the sink arm (the
  // ONLY block the emitter erases), `Condition` the tainted compare, `ArmNegated`
  // the Rule-9 polarity (the sink arm is the FALSE successor). `Merge`/`MergeBB`/
  // `ArmFalse` stay null (the sink arm has nothing to merge; the sibling SURVIVES
  // — it is NOT doomed, so it is deliberately absent from the pre-flight's doomed
  // set). Lowered by `AbortParkEmit`: mint the flag → `cqrt_cswap` the routed
  // handle into a kept graveyard rail (self-bracketed) → record the flag on the
  // tape → run the sibling/downstream UNCONTROLLED (abort terminates, so the
  // branch-correlated tail-garbage never dephases). The graveyard + flag join the
  // new `taint.GraveyardRails` (kept, NEVER reversed/freed — Rule 6).
  // GuardedStoreArm (iw81.7) — a tainted-condition `br`-diamond whose single
  // content arm is SIDE-EFFECT-ONLY: a bounded-alloca tainted-index Shadow STORE
  // (a gep chain + one `store`, NO merge φ — a store mints no SSA value), the
  // sibling being the empty straight-to-merge edge. NOT swap-routable (memory has
  // no per-arm work rail; swap-routing writes `arr[0]=0` on the inactive branch) —
  // it is GENUINELY CONTROLLED. Lowered by `emitGuardedStoreArmRegion`: mint the
  // path-predicate flag from the pre-store condition handle, RECORD (store→flag) in
  // `taint.GuardedStores`, FLATTEN the diamond (splice the arm's gep+store into
  // `Pred`, unconditional `br` to `MergeBB`), and DO NOT strip the flag. Then
  // `lowerShadowMemory` emits the guarded store `cqrt_qram_store_<W>_controlled(
  // flag, arr, idx, val)` for the recorded store, and the whole-DAG LIFO uncompute
  // reverses it via `..._controlled_unc` (EmitInverse's existing generic
  // qram-store branch) and strips+frees the flag (the flag-mint compare is a
  // reversible DAG ancestor, §6.0 compare `_unc`). `Pred`/`Arm`/`MergeBB`/
  // `Condition`/`ArmNegated` carry the shape as a `BranchRegion` diamond does.
  // PhaseKickback (bd test_C_libtooling-3qlq Inc 1, PRD
  // `retire-swap-route-PRD.md` §6.2 row P1) — a flat tainted-condition DIAMOND
  // whose arm is exactly ONE register-free `call void @cq_phi(double θ)` and a
  // `br`. `Merge` is NULL by construction (a void arm produces no merge φ, which
  // is precisely why `recoverRegion` cannot see this shape and why it is
  // pre-peeled); `MergeBB` IS set, so `flattenRegion` and
  // `flatRegionRollableInLoop` work on it exactly as they do for the phi-less
  // void-I/O diamond `lowerControlledIOSinks` builds. `Shadow` holds the one
  // phase call; `Condition`/`Pred`/`Arm`/`ArmNegated` carry the shape as a
  // `BranchRegion` diamond does. Emitted by
  // `SwapRouteEmit::emitPhaseKickbackRegion`.
  // PhaseKickbackNest (bd test_C_libtooling-3qlq Inc 1 part B, PRD §6.2 row P4)
  // — the GENUINE depth-2 nest `if (a) { …cq_phi…; if (b) { …cq_phi… } }` that
  // SimplifyCFG did NOT fold (it cannot: the outer arm holds an opaque call). It
  // is ONE region, not the 4.3 parent/child pair, because the register-free
  // lowering has nothing to route between levels: `Pred`/`Arm` (= the Mid block,
  // which holds the outer arm's phase calls AND the inner condition tree) /
  // `ArmFalse` (= the inner content arm) / `MergeBB` (the 3-predecessor join,
  // with NO φ) carry the whole shape, `Condition` and `InnerCondition` the two
  // condition trees, `ArmNegated` and `InnerArmNegated` the two Rule-9
  // polarities, and `Shadow`/`ShadowFalse` the two arms' phase calls — the
  // ordinary field convention (`ShadowFalse` is `ArmFalse`'s), which also makes
  // `lowerControlRegions`' doomed-block set `{Arm, ArmFalse, MergeBB}` exactly
  // right without a special case. Emitted by
  // `SwapRouteEmit::emitPhaseKickbackNestRegion`: two condition NETWORKS, ONE
  // `cqrt_toffoli` conjunction ancilla, `cqrt_rz_i1` on the outer root for the
  // outer arm and on the conjunction for the inner, then the exact LIFO undo. NO
  // `cqrt_cswap`, no work rail, no per-level route — the 4.3 swap route is what
  // this retires.
  enum Kind {
    SelectRegion,
    BranchRegion,
    AngleSelectRegion,
    SwitchRegion,
    ClassicalCallArm,
    AbortPark,
    GuardedStoreArm,
    PhaseKickback,
    PhaseKickbackNest
  } Kind = BranchRegion;

  // The merge node: a `SelectInst` (select-sourced) or the merge-block
  // `PHINode` (br-sourced). `SwapRouteEmit` RAUWs/erases it (the excised
  // `MergeDissolution` is gone, 7cde677).
  llvm::Instruction *Merge = nullptr;

  // In-shadow gate-body ops, in program order. For a PHASE arm this is the
  // retained-but-unpopulated 4.1 vocabulary: `SwapRouteEmit` walks the arm
  // blocks directly and replays each `cq_phi` verbatim+uncontrolled on the
  // routed work rail (the excised `ControlledSubstitution`'s `_controlled`
  // lowering survives only as the §6a control-in-place reserve,
  // `ControlledSymbols`). For a VALUE arm (4.2, `ClassArm == Value`)
  // `ArmClassify` populates it with the arm's ordered chain links
  // (FORWARD/base-first order. ⚠ THE EMIT ORDER CHANGED AT bd
  // test_C_libtooling-3qlq Inc 2: the pre-3qlq emitter moved each link onto a |0>
  // work rail, `rewriteBinary`d it there and reverse-played the minted calls via
  // `emitInverseChain`; `emitValueRegion` now simply HOISTS the links into the
  // pred as ORDINARY tainted instructions — `lowerOps` lowers them and the
  // whole-DAG spine reverses them — and merges via the 4.4 controlled-copy
  // `emitSelectRegion`. Forward/base-first order is still what the hoist needs.) `Shadow` is `Arm`'s content and
  // `ShadowFalse` is `ArmFalse`'s — by FIELD identity, not edge truth: for an
  // orientation-B diamond `Arm` is the FALSE successor (`ArmNegated` carries
  // the polarity, Rule 9).
  llvm::SmallVector<llvm::Instruction *, 4> Shadow;

  // 4.2 (PRD Part II §8.3) — the per-arm classes for `Arm` / `ArmFalse`.
  // Meaningful only on a region that survived `classifyArms`; `Phase` is the
  // 4.1 default (phase paths never write these). A value-class arm's ordered
  // chain links live in `Shadow` / `ShadowFalse` above.
  ArmClass ClassArm = ArmClass::Phase;
  ArmClass ClassArmFalse = ArmClass::Phase;

  // 4.5 WI-5 (equality-folded `br` diamond) — the routed quantum handle the
  // PHASE emitter (`emitRegion`) must CSWAP into the work rails, set by
  // `tryEqFoldArm` to the icmp's non-constant tainted operand. Null for every
  // non-eq-fold region (emitRegion then derives it as before: a diamond's
  // Pred-edge incoming, or an if/else's first-arm phase-spine base).
  //
  // LOAD-BEARING for the eq-fold IF/ELSE: `clang -O1` const-folds the `q==k`
  // (true) arm's gate to `cq_phi(i32 k, θ)` — arg-0 is the literal `k`, not the
  // handle `q`. An if/else has NO Pred-edge merge incoming, so emitRegion would
  // otherwise derive `Q` via `phaseSpineBase(R.Arm)`, which bottoms at that
  // folded constant `k` and routes a CONSTANT instead of `q` (a verify-clean
  // silent miscompile — the eq-fold analog of the §5 switch re-anchor; §4D's
  // "reuse emitRegion verbatim" misses it). Recording the classifier-proven
  // routed handle here re-anchors the emitter by SSA identity. Unused by the
  // value/data-mux emitters (they derive their own routed base).
  //
  // ⚠ A `WeakTrackingVH`, NOT A RAW `Value *`, AND THAT IS THE FIX FOR A
  // CONFIRMED CRASH (round-1 Rule-13 review of bd test_C_libtooling-drbq Inc 1,
  // lens L4 §1-2). This field is RECORDED AT DETECTION and READ AT EMISSION, and
  // between those two moments `lowerControlRegions` may emit ANOTHER region
  // which does `MergePhi->replaceAllUsesWith(base); MergePhi->eraseFromParent()`.
  // A raw pointer is not a USE, so the RAUW does not update it and the erase
  // leaves it DANGLING. Measured, from plain C at `-O1`:
  //
  //   * `if (q==5) q=cq_phi(q,.2); if (cc) g(); if (q==6) q=cq_phi(q,.3);` —
  //     two eq-fold PHASE regions with a CLASSICAL branch between them, so the
  //     bd hcrg pre-flight (which reasons about BASIC BLOCKS) sees no alias and
  //     orders nothing. Region 2's `RoutedBase` IS region 1's merge φ, and the
  //     phase emitter dereferences it (`emitRoute` → `CreateCall` reads
  //     `Q->getType()`) — SIGSEGV under libgmalloc.
  //   * the same CFG with in-place Ry arms declines `control flow`, because
  //     `emitInPlaceRotationRegion` COMPARES the stale pointer against the
  //     RAUW-updated theta operand and they disagree. Same defect, one
  //     dereference short of the crash. The verdict depended on textual BLOCK
  //     ORDER, which detection (pure SSA + DominatorTree analysis) cannot see.
  //
  // A `WeakTrackingVH` follows RAUW and nulls on erase, so after region 1
  // collapses its merge φ this field names region 1's BASE — which is the
  // correct routed handle for BOTH readers. The pre-flight protects BLOCK
  // identities across emitters; nothing protected VALUE identities, and this
  // handle is that protection.
  llvm::WeakTrackingVH RoutedBase;

  // Was a routed base ever RECORDED? Distinguishes "this region never had one"
  // (every non-eq-fold, non-rotation region — the emitter derives `Q` as before)
  // from "it had one and the handle has since been ERASED with no replacement",
  // which the `WeakTrackingVH` reports as null and which must be a LOUD DECLINE
  // rather than a fall-through to the φ derivation: for an eq-fold if/else that
  // derivation bottoms at the folded constant `k` and routes a CONSTANT — the
  // exact verify-clean miscompile the field exists to prevent. Written ONLY
  // through `setRoutedBase` so the two cannot drift.
  bool RoutedBaseRecorded = false;

  void setRoutedBase(llvm::Value *V) {
    RoutedBase = V;
    RoutedBaseRecorded = V != nullptr;
  }

  // 4.5 (PRD Part V §20.5) — the per-content class of an accepted `SwitchRegion`
  // (`SwitchClassify` writes it on accept). Meaningful only when
  // `Kind == SwitchRegion`; `Phase` is the default. Picks the emit recipe in
  // `lowerControlRegions` (WI-2/3/4: phase / value / data-mux).
  SwitchClass SwitchCls = SwitchClass::Phase;

  // br-sourced CFG anchors (null for a select region). `Pred` holds the
  // outer `br i1`; `Arm` is the innermost guarded block (the gate body);
  // `MergeBB` is the common merge.
  llvm::BasicBlock *Pred = nullptr;
  llvm::BasicBlock *Arm = nullptr;
  llvm::BasicBlock *MergeBB = nullptr;

  // WP8 (Family C) symmetric two-content-arm diamond: `if(q){A}else{B}` where
  // BOTH successors hold content and fall through to a common merge. `Arm` is
  // the TRUE arm (gates controlled on `flag`); `ArmFalse` is the FALSE arm
  // (gates controlled on `¬flag` via the §2.5 `cqrt_x` LIFO bracket), and
  // `ShadowFalse` its gate bodies. Null/empty for the one-content-arm diamond
  // (WP3) and select/nested shapes. When `ArmFalse` is set the merge `φ`
  // dissolves by the `Arm`-edge incoming (the merge's predecessors are the two
  // arms, not `Pred`), and linearization splices BOTH arms into `Pred`.
  llvm::BasicBlock *ArmFalse = nullptr;
  llvm::SmallVector<llvm::Instruction *, 4> ShadowFalse;

  // bd `test_C_libtooling-fn1q` increment 1 — THE ARM'S CLASSICAL CONE, in
  // BLOCK order (so operand-before-user holds by construction), for `Arm` /
  // `ArmFalse` respectively. These are the arm-block instructions that are NOT
  // chain links: the pure, UNTAINTED computation feeding a chain link's
  // classical operand (`if (c) p += (k*3+7)^5;` — the `load @k`, `mul`, `add`,
  // `xor`). `emitValueRegion` hoists them into the pred AHEAD of the chain.
  //
  // ⚠ THIS IS A RECORD, NOT A HINT, AND THAT IS THE WHOLE POINT (standing
  // lesson L1). `classifyArms` is the only place that PROVES a cone member is
  // classical, side-effect-free, non-escaping and speculatable; the emitter
  // must hoist exactly that proven set and re-derive nothing. A second spelling
  // of "which arm ops may be hoisted" is the drbq Inc-3 (b') defect.
  //
  // EMPTY on every phase/rotation/prep arm and on a value arm whose chain is
  // the arm's whole content — i.e. on every region that lowered before this
  // increment, which is why the increment moves no shipped stream.
  llvm::SmallVector<llvm::Instruction *, 4> ShadowCone;
  llvm::SmallVector<llvm::Instruction *, 4> ShadowConeFalse;

  // ⚠ NOTHING POPULATES EITHER OF THESE, ANYWHERE — stated as a MEASURED FACT,
  // not a hedge (bd drbq Inc 2b; the same audit `InShadow` got in round 2).
  // `grep -rn "AnglePhi\|AngleConsumers" ir-pass/` finds this declaration, its
  // comments, and exactly ONE read — `ArmClassify.cpp:1538` (the `if
  // (!Region.AnglePhi.empty() || !Region.AngleConsumers.empty())` itself; the
  // round-1 correction cited `:1534`, which is a closing brace four lines up —
  // round-2 Rule-13 review, lens R2 N8), the in-place rotation-arm R7
  // defence-in-depth clause. (The first draft said TWO and named
  // `EqFoldArm` as the second; `EqFoldArm` never reads `AnglePhi` at all —
  // corrected by the Inc-2b round-1 Rule-13 review, lens L6-N4.) There is no
  // `push_back` on either field in the tree, so both are permanently empty and
  // that one read is a no-op.
  //
  // The retired design they belong to: cwk fix (b) (test_C_libtooling-byx) — a
  // wholly-classical scalar-FP merge `φ` (a rotation ANGLE) dispatched under
  // quantum control via the `br`-diamond / gated-switch form, i.e. the CFG analog
  // of what `AngleSelectRegion` now is. Detection was to record the angle `φ`(s)
  // here and their consuming rotations in `AngleConsumers`, which would also join
  // `plan.InShadow` so `lowerRotations` skipped them.
  //
  // THE FUNCTION THAT COMMENT NAMED AS THE LOWERING — `reduceAngleDiamondPhi` —
  // WAS REAL SHIPPED CODE (added in `f4c8684`/`b9b6a7a`) AND WAS EXCISED IN
  // `7cde677` with the rest of the controlled-op generation. The first draft of
  // this note said it "never did exist in this generation" and offered a `grep`
  // returning "zero hits", which is wrong twice: `.beads`' JSONL export carries
  // hits, and the name was a LIVE pointer the excision left dangling — an
  // ordinary stale reference, not design vocabulary mistaken for one (corrected
  // by the Inc-2b round-1 Rule-13 review, lens L6-N5). The name is removed rather
  // than left to send the next reader looking for a file. What DOES implement the
  // by-difference idea, for the `select` form rather than the `φ` form, is
  // `AngleSelectEmit` (Inc 2b).
  //
  // `dissolveBranchPhi` is likewise GONE (excised in the same `7cde677`); the
  // draft named it in the PRESENT tense as something that "really does skip any
  // `φ` listed here". Nothing skips them, because nothing lists them.
  llvm::SmallVector<llvm::PHINode *, 2> AnglePhi;
  llvm::SmallVector<llvm::Instruction *, 4> AngleConsumers;

  // WP18 (SwitchRegion) — the case arms. The default arm rides `Arm`/`Shadow`
  // (above). Empty for every non-switch region.
  llvm::SmallVector<SwitchArm, 4> SwitchArms;

  // WP18 follow-on (test_C_libtooling-509): the switch's DEFAULT edge goes
  // STRAIGHT to the merge (an empty `default:`), so there is NO distinct default
  // block — `clang -O1` routes `switch …, label %merge [ … ]`. When true, `Arm`
  // is null (no default gate body / nothing to splice) and the default angle
  // base rides the `Pred` (switch-block) φ edge instead of an `Arm` edge; the
  // default control is implicit (no case matched ⇒ no gate, the unconditional
  // base angle), so `lowerGatedSwitch` skips the ¬OR default substitution and
  // the OR-fold entirely. False for a distinct default block (gated or empty).
  bool SwitchDefaultDirect = false;

  // npu.5/.6 (MUX-EXCH): the merge carries exactly one DISTINCT-per-case-handle
  // mux φ (a coherent multiplexer dispatching case0→qx, case1→qy, …) that PASSED
  // the conservative G0–G7 safety gate in `tryBuildGatedSwitchRegion`. When set,
  // `lowerGatedSwitch` lowers that φ by a fresh `regOut = cqrt_alloc(0)` + a
  // per-distinct-base `cqrt_cswap(f_q, regOut, q)` controlled MOVE + a
  // `cqrt_ry_<W>_controlled_inv(¬f_q, q, angle)` uncompute of every non-selected
  // source (so regOut is not left entangled with the scrutinee), instead of the
  // step-4 first-tainted RAUW (which would silently drop every other-handle
  // edge). False ⇒ every handle φ is uniform-base (the RAUW path) — the gate
  // declined any distinct-base φ to the WP12 diagnostic, so a distinct-base φ
  // never reaches lowering with this false. The mux φ self-identifies at
  // lowering (≥2 distinct tainted incomings); this bit only certifies the gate
  // passed. See the archived
  // docs/archive/old-design/phases/phase04-controlled-form/npu6-mux-exch-gate-spec.md
  // + [[cwk-merge-phi-discriminator]].
  bool MuxExch = false;

  // The single gate arm is the FALSE successor of the `br i1 cond, S0, S1` (i.e.
  // `Arm == S1`), so it is taken when `cond` is FALSE and its gates fire on
  // ¬flag, not flag. `clang` produces this whenever it swaps the branch targets
  // — e.g. `if (u != 5)` canonicalizes to `icmp eq; br eq, Merge, Arm`. The
  // controlled substitution wraps such an arm in the self-inverse `cqrt_x` flag
  // bracket (the same ¬flag mechanism as the WP8 symmetric false arm). False for
  // the ordinary true-successor diamond and for select/symmetric regions (whose
  // polarity is carried explicitly by the arm assignment).
  bool ArmNegated = false;

  // Rule-9 polarity of the INNER level of a `PhaseKickbackNest`: true when the
  // inner content arm is the inner branch's FALSE successor. Expressed at emit
  // time as a `cqrt_x` bracket on the inner root inside the conjunction node
  // (`CondNetwork::Node::NegR`), never as a second flag mint.
  bool InnerArmNegated = false;
  // Nested-AND intermediate guard block (WP5, PRD §2.7): for the un-flattened
  // `if (a) { if (b) gate; }` shape, `Pred -[a]-> {Mid, Merge}`,
  // `Mid -[b]-> {Arm, Merge}`, `Arm -> Merge`. `Mid` holds the inner compare
  // `CondB` + the inner `br i1`; it is spliced out at linearization with `Arm`.
  // Null for a flat (WP3) or compound-`&&`-select (single-block-condition)
  // region. When set, `Conj == ConjAnd`, `CondA` is the outer compare, `CondB`
  // the inner — so nesting reuses the conjunction flag machinery verbatim.
  llvm::BasicBlock *Mid = nullptr;

  // Nesting depth (0 = outermost) and the enclosing region, for the
  // single-flag AND model (PRD §2.7). For a nested region (`Depth > 0`),
  // `ParentIdx` is the index of the enclosing region in `ControlPlan::Regions`
  // (an index, not a pointer — the region list is a `SmallVector` that may
  // reallocate as detection pushes; `kNoParent` ⇒ outermost). `ParentFlag` is
  // resolved from the parent's `Flag` at lowering time (the outer→inner Depth
  // sort guarantees the parent's flag is already minted, IMPLEMENTATION
  // §"Nesting"). The inner region's own condition flag is then AND-combined
  // with `ParentFlag` into a single `f_both` (`FlagConjunction`), and every
  // inner controlled op uses that one flag (§1.2). WP3/WP4's flat fixtures
  // leave `ParentIdx == kNoParent` and `ParentFlag` null.
  static constexpr unsigned kNoParent = ~0u;
  unsigned Depth = 0;
  unsigned ParentIdx = kNoParent;
  llvm::Value *ParentFlag = nullptr;

  // bd `boi6` D-B / Track M, round-1 finding F-M1 — THE ADMITTING PREP REGION of
  // a merge-φ-conditioned `SelectRegion`: the index in `ControlPlan::Regions` of
  // the `BranchRegion` whose `InPlaceRotation` verdict `classifySelectRegion`'s
  // rung 0 accepted this select's φ on. `kNoParent` for every other region and
  // for a compare/rail-conditioned select. An INDEX, not a pointer, for exactly
  // the reason `ParentIdx` gives one line above (the list is a `SmallVector` that
  // reallocates as detection pushes) — and indices are stable because
  // `plan.Regions` is only ever `push_back`'d, never erased, sorted or resized.
  //
  // ⚠ IT EXISTS TO CARRY AN EMISSION-ORDER OBLIGATION, and the obligation is real
  // rather than theoretical (MEASURED, round-1 probe `r03_order_third_region.c`).
  // `lowerControlRegions` does NOT emit in plan order: it Kahn-sorts the bd `hcrg`
  // precedence graph, in which a `SelectRegion` is INERT (all four block fields
  // null ⇒ it aliases nothing and nothing aliases it ⇒ `Pending == 0` always). A
  // following `PhaseKickback` whose `Pred` IS the prep's `MergeBB` is the
  // sanctioned `sequentialChainAlias` and gets `Precedes[kickback] = {prep}` — so
  // the prep is scheduled LAST, AFTER the inert select, and the select's
  // condition re-read then finds the φ still present (M-β has not run) and takes
  // the loud H-1 backstop. Safe, and an OVER-DECLINE on plain C.
  //
  // The fix is this field plus ONE edge in that graph (`SwapRouteEmit`,
  // `lowerControlRegions`): the admitting region BEFORE this select. The edge is
  // added by CALLING this record — the predicate that produced it is
  // `classifySelectRegion`'s and is never re-derived in the emitter (Rule 14).
  // A select can only gain INCOMING edges this way, so it can never sit on a
  // precedence cycle.
  //
  // ⚠ bd `4aiu` (Track P) — A LIST, because the grammar no longer caps a tree at
  // ONE φ leaf. Dropping Track M's ROOT-ONLY conjunct makes `(b1 && b2) ? … : …`
  // in-grammar, and each φ leaf is admitted by its OWN prep region, so the
  // obligation above is owed ONCE PER LEAF. One entry per admitted φ leaf, in
  // `Tree.RailPhiLeaves` order; EMPTY for every other region and for a
  // compare/rail-conditioned select. The vector is the enforcement the same way
  // `RailPhiLeaves`' element type is: a scalar field would have silently kept the
  // LAST leaf's index and dropped the others' edges, which is an over-decline at
  // best and a use-after-free at worst.
  //
  // ⚠ bd `test_C_libtooling-hn29` / `-leyd` / `-52og` (Track P′, 2026-09-15) —
  // A `PhaseKickback` NOW RECORDS HERE TOO, AND ITS EDGE POINTS THE OTHER WAY.
  // The paragraph this replaces said a kickback records NOTHING because the bd
  // `hcrg` alias pre-flight ALREADY supplies `Precedes[kickback] = {prep}`. That
  // was true of the population that existed when it was written, and its
  // derivation is `ArmClassify` step 5c's theorem, whose HYPOTHESIS is
  // `φ->getParent() == kickback.Pred` ⟹ `kickback.Pred == prep.MergeBB` ⟹ the
  // `Aliases` test fires. Track P′ admits φ leaves OUTSIDE `Pred`; for those the
  // hypothesis fails, no alias edge exists, and plan (detection) order emits the
  // PREP first — measured, and it turns the module into a loud `control flow`
  // decline at `emitPhaseKickbackRegion`'s condition-identity check.
  //
  // SO ONE FIELD CARRIES TWO OPPOSITE OBLIGATIONS, keyed on `Kind`:
  //   * `SelectRegion`  → `Precedes[prep] = {select}`   — PREP FIRST, because
  //     `SelectMergeEmit` RE-READS its condition and needs M-β to have run;
  //   * `PhaseKickback` → `Precedes[kickback] = {prep}` — KICKBACK FIRST, because
  //     `emitPhaseKickbackRegion` consumes the φ AS A VALUE and needs it live.
  // Both loops live in `SwapRouteEmit::lowerControlRegions`, each opening with
  // its own `Kind` test, and the kickback's DEDUPES against the alias edge so the
  // Kahn "at most one edge per ordered pair" invariant stays literally true. The
  // old sentence's last clause — that adding the SELECT's direction at a kickback
  // would close a cycle — remains correct and is exactly why the direction, not
  // just the recording, is part of the contract.
  //
  // ⚠ THIS FIELD IS A CALLER OF `TaintSet::RailCondReads` CASE (3), AND THE
  // DIRECTION IT USES THAT RECORD IN IS **GRANTING** (CLAUDE.md L3-MIRROR: *"when
  // you ADD A CALLER to a shared predicate, read the callee's RETIREMENT TRIGGER
  // and state which direction you are using it in"* — the omission that cost a P1
  // on 2026-09-14, bd `a3z7`). `TaintPropagation.h`'s `RailCondReads` block names
  // three cases at `reverifyRailCondReads`; case (3) is a LIVE non-`CallInst`
  // value — today exactly a region-merge `PHINode` — and it is SKIPPED, a skip
  // that is INERT rather than conservative and is held open ONLY by the premise
  // *"M-β RAUWs the φ to the hoisted `cq_theta_i1` before the reader looks"*.
  // The `PhaseKickback` direction of this field **ENLARGES case (3)'s
  // population**: it is precisely the mechanism by which a kickback is emitted
  // BEFORE its prep, which is when `markRailCondRead` sees a φ rather than a
  // call. Before Track P′ that population was whatever the bd `hcrg` alias
  // supplied for free (φ in `Pred`); now it is every cross-block φ leaf under an
  // explicit edge.
  //
  // ⚠ THE PREMISE IS PRESERVED BY CONSTRUCTION, AND THAT IS WHY THIS IS A
  // DISCLOSURE AND NOT A DEFECT — re-checked at the 2026-09-15 Rule-13 round
  // (R-4) and again at the ARM group gate. This edge changes the ORDER WITHIN one
  // `lowerControlRegions` call, never WHETHER the prep region is emitted in it:
  // both regions are in the same plan (rung 0 admits the φ only for a region
  // ALREADY committed as `InPlaceRotation`, which is what `PrepRegionIdxs`
  // records), `emitInPlaceRotationRegion`'s M-β still RAUWs the φ to the hoisted
  // `cq_theta_i1`, the record's `WeakTrackingVH` FOLLOWS that RAUW, and
  // `reverifyRailCondReads` still runs after the round-2 fixpoint — so case (3)
  // becomes case (2) before the reader looks, exactly as its block claims.
  // ⚠ RETIREMENT TRIGGER, and it is the callee's own, restated in this field's
  // terms: the day a region index recorded HERE names a prep that is **not in the
  // same plan**, or a `SelectRegion`-kind prep (whose emitter performs no M-β),
  // the RAUW that discharges case (3) does not happen and the record names a live
  // register whose ladder is never re-asked, **silently**. Read
  // `TaintPropagation.h`'s case-(3) trigger in full before widening either
  // direction of this field.
  llvm::SmallVector<unsigned, 2> PrepRegionIdxs;

  // 4.3 (IMPLEMENTATION-4.3 §1/§4) — the parent region's work rail (`rail1`),
  // onto which the parent routes its base before the child mints + routes. The
  // child's inner flag is minted FROM this rail (`lowerCompareToFlagRail`), not
  // from the now-stale-on-`q` SSA register the source compare read (§12.2). Null
  // for a flat region or the outermost nest level; populated at EMIT time by
  // `NestedRouteEmit` (WI-3) — WI-1 detection leaves it null (the parent/child
  // link is the existing `ParentIdx`, the same link the pre-flight exemption
  // and the emit-loop child lookup key on; no `ChildIdx` field — MD4).
  llvm::Value *ParentRail = nullptr;

  // ziov WI-1 (owner 2026-06-15) — the tainted condition compare `q>5` is read in
  // BOTH a control (the `br`) AND a data position (`int f = (q>5)`; clang -O1 CSEs
  // them to one `icmp` with two uses). The compare IS the control flag, so the
  // route and the data use must share ONE physical flag: `SwapRouteEmit::emitRegion`
  // mints it once, routes with it, feeds the SAME handle to the data use, and
  // SKIPS the eager strip+free (the data lineage owns the handle — it escapes or
  // is measured, FreePoint → Escaped/Measured, no free). `classifyArms` sets this
  // ONLY when the condition has a non-branch user whose forward lineage is wholly
  // escaped/measured; a dead-within-function lineage declines PERMANENTLY (ziov.2
  // proposed a deferred in-function strip there but it was closed won't-fix — a
  // flag-only strip leaves the data-copy rails entangled with q, a silent
  // miscompile). False for the common no-data-use region (the unchanged eager
  // strip+free path). The VALUE-arm twin is not yet implemented —
  // `emitValueRegion` declines a `ShareCondFlag` region (WI-later).
  bool ShareCondFlag = false;

  // bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 round-1 item F-B1R1-2 — set by
  // `classifySelectRegion` on ACCEPT iff the condition tree carries a RAIL LEAF,
  // i.e. PRD §14.3's rail ladder (tainted · not measured before the SELECT · the
  // wire question with the DT prong) was asked and passed. `emitSelectRegion`
  // REFUSES a rail-carrying tree whose region does not carry this flag, with the
  // original `bare i1 register condition` string: that emitter has THREE callers
  // and only the classifier asks the ladder — `SwapRouteEmit::emitValueRegion`
  // builds its own `SelectRegion` and calls the emitter directly (structurally
  // `CmpInst`-only today; bd `fg9k` widens that and MUST route a rail through the
  // ladder and set this before handing over). The old pre-1b-B.1 guard was the
  // caller-independent backstop for all three; this is its replacement, and
  // unlike the `RootIsRail` re-ask it is not dead code.
  bool RailLadderProven = false;

  // bd `test_C_libtooling-xdu2.13` — the CLASSICAL LITERALS `classifySelectRegion`
  // admitted into this `SelectRegion`'s condition tree (`CondLiteral.h`), in walk
  // order. `emitSelectRegion` re-derives the tree by MEMBERSHIP of this list and
  // refuses a size mismatch, so detection and emission cannot drift. EMPTY for
  // every other producer (incl. `emitValueRegion`'s synthesized region), which is
  // what keeps their walk byte-identical. `WeakTrackingVH`: a literal RAUW'd
  // between detection and emission is followed (and re-asked for taint there),
  // an erased one nulls and forces the mismatch decline.
  llvm::SmallVector<llvm::WeakTrackingVH, 2> CondLiterals;

  // bd test_C_libtooling-8h7d.5 (7.3 Inc 3) — this region sits WHOLLY INSIDE a
  // reducible `LoopInfo` loop and was admitted by
  // `ControlDetect::flatRegionRollableInLoop`. Set at detection, read only by
  // `handleBranchRegion`'s own in-loop scope fence (PHASE arms only) — the
  // emitters are UNCHANGED: an in-loop region emits the exact same routed
  // stream, positionally, into its own `Pred`, which is why the rolled loop's
  // trace is byte-identical to its hand-unrolled twin's.
  bool InLoop = false;
};

// The full detection result: the recovered regions plus the set of in-shadow
// `cq_phi` calls (so `lowerRotations` skips them — the orchestrator lowers
// them controlled). `InShadow` is keyed on the gate-body `Instruction*`.
//
// ⚠ `InShadow` HAS NO `insert` ANYWHERE IN `ir-pass/` — stated as a FACT, not a
// hedge (bd drbq round-2 review, lens C §2). Measured: `grep -rn "InShadow"
// ir-pass/` returns this declaration, its comments, and ONE read
// (`RotationLowering.cpp`'s `plan->InShadow.count(Phi)`). No emitter populates
// it, so it is permanently empty and that read is a no-op.
//
// WHY THAT MATTERS RATHER THAN BEING TRIVIA: it is the ONLY field of the ROUND-1
// plan that `lowerRotations` reads, and `lowerRotations` runs AFTER the round-2
// (`plan2`) emission. So the round-1 plan is inert from the moment emission
// finishes, which is what makes the plan-lifetime obligation hold. If a future
// control path ever DOES populate this set — one that keeps gate bodies in place
// rather than erasing them — the set must also be re-scoped per round: a stale
// round-1 `Instruction *` whose address is reused by a round-2-minted `cq_phi`
// would silently suppress that phi's `cqrt_rz`.
struct ControlPlan {
  llvm::SmallVector<ControlRegion, 4> Regions;
  llvm::SmallPtrSet<const llvm::Instruction *, 8> InShadow;
};

// Shared loud-decline primitive (swap-route 4.1 IMPLEMENTATION §2). Emits a
// `DiagnosticInfoUnsupported(DS_Error)` of the form
// `"cq controlled lowering: " + What + " under quantum control"`, anchored on
// `Where`'s `!dbg` so the rejection is source-located and `opt` exits non-zero.
// Defined once in `ControlDetect.cpp`; shared by `ControlDetect`/`ArmClassify`
// so every control decline (shape, §3c clobber, value-arm, nested, select,
// switch) speaks one diagnostic dialect. Over-declining is always safe; a
// silent pass-through of quantum control is the only unforgivable bug.
void diagnoseUnderControl(llvm::Instruction *Where, llvm::StringRef What);

// Does `I` carry a `!dbg` that will actually PRINT as a source location?
// THE ONE SPELLING of that question (Rule 14) — `declAnchor` (ArmClassify) and
// the R7-loop re-ask's escape anchor (LoopLowering) both call it, so the two
// cannot drift.
//
// ⚠ TWO FAILURE FORMS, AND A NULL TEST ALONE FIXES ONLY HALF THE CLASS —
// measured, not defensive (bd `test_C_libtooling-wx8g` review round 2, finding
// F-W2-5, 2026-09-14):
//   * NO `!dbg` AT ALL. `-O1` LICM DROPS the debug location of every non-call
//     instruction it hoists into a preheader, which is exactly how a
//     loop-invariant compare reaches a region classifier.
//   * A `!dbg` WHOSE LINE IS 0. `clang -O1` stamps `!DILocation(line: 0, …)` on
//     merge `phi`s and on the scopes of promoted locals — the "no single source
//     line" location — and `DiagnosticInfoUnsupported` renders it as `file:0:0`,
//     no more actionable than `<unknown>:0:0`.
// The failure is invisible to every gate this project runs: no hand-written
// `.ll` fixture carries debug info at a decline site, so an anchorless
// diagnostic survives a fully green `ir-pass-lit` and is visible only by
// compiling a `-g` `.c` probe and reading stderr. Rule 1 wants the diagnostic
// SOURCE-LOCATED; an anchorless one is a Rule-1 regression even when the
// accept/decline verdict is right.
bool anchorIsLocated(const llvm::Instruction *I);

// Pure-analysis detection (swap-route 4.1 IMPLEMENTATION §0/§3). For each
// tainted-condition `br i1`, recognize the §0 clean diamond / if-else shape by
// SSA-value identity (Rule 9 — before any mutation), classify each arm
// (phase / value / §3c clobber) via `ArmClassify`, and decline everything that
// is not a pure-phase-over-tainted-handle region. An accepted phase-arm DIAMOND
// (one content arm, WI-2) or IF/ELSE (two arms, WI-3) is pushed onto
// `plan.Regions` for `SwapRouteEmit::lowerControlRegions`. `plan.InShadow`
// stays empty — the emitter erases each arm `cq_phi` before `lowerRotations`
// runs, so there is no in-place gate body to skip (IMPLEMENTATION §3). A
// classical-condition branch is ignored (detection keys strictly on condition
// taint). No IR is mutated here.
ControlPlan detectControlRegions(llvm::Module &M, WidthDispatch &wd,
                                 TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROL_PLAN_H_
