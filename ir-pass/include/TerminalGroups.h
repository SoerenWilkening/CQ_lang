// TerminalGroups.h — how the whole-DAG spine's DEAD-TERMINAL groups are formed
// and planned (bd test_C_libtooling-p3kd.13, R11 rounds 1-5). Internal to the
// uncompute spine: `Uncomputation::uncompute` calls `reverseTerminalGroups`, which
// calls `reverseTerminalGroup` (the per-group planner, defined in Uncomputation.cpp)
// once or more per group.

#ifndef CQ_IRPASS_TERMINAL_GROUPS_H_
#define CQ_IRPASS_TERMINAL_GROUPS_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Function;
class LoopInfo;
class PostDominatorTree;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct DataDag;
struct TaintSet;

// How one terminal group is planned:
//   Loud   — main's behaviour exactly (every refusal keeps its diagnostic);
//   Silent — no diagnostic; a plan is emitted only if it touches nothing an
//            earlier group reversed (`cloneTerminalReversalDisjoint`);
//   Probe  — Silent's verdict, but NOTHING is emitted: true iff at least one plan
//            and every plan would emit, with what they would do recorded in
//            `*Probe` (GroupProbe, below). Planning is SIDE-EFFECT-FREE (no taint write, no IR
//            change before `emitDagReversal`), which is what makes a refused probe
//            leave the module exactly as it found it. That invariant is
//            LOAD-BEARING for `reverseTerminalGroups`: a change that makes
//            planning mutate anything must give the probe a dry-run path first;
//   ProbeAsLoud — Probe WITHOUT the disjointness check, which Loud never asks: what
//            the template terminals' Loud plan would emit (R11 r3 F1 — a Probe
//            can refuse on `taint.SpineOps` adjoints minted BEFORE uncompute, by
//            BreakReversePlay and CondLiteral, where Loud emits; QramIndexWidth's
//            bracket runs AFTER uncompute, CQLoweringPass, so it is not one of them).
//            A FreePoint reject still refuses: Loud would DECLINE there.
//            WHY NO FIXTURE PINS IT (R11 r4 F-D, r5 F3 — the record): the two
//            differ only where a disjointness check refuses the template-only plan
//            on a gate g it would reverse-play (or a rail g writes or reads), and
//            Loud would emit. Under ProbeAsLoud the union must then reverse-play g
//            (`T.Gates ⊆ U.Gates`), meets g in its own disjointness check and
//            refuses: the split runs, as main. Under Probe the template is
//            `!TmplOk` and the union need only WALK g first (`T.Walked ⊆
//            U.Walked`); the verdicts differ only if the union's frontier fixpoint
//            then FORCES g's record or borrows its open root, so g is not
//            reverse-played. That needs, at once, a conflict with an adjoint minted
//            before uncompute (BreakReversePlay/CondLiteral) or an earlier group's
//            reversal, and a moved borrowed parent (or an open root) under g. Round
//            4's QRAM-store exception is closed by both branches since r5 (the
//            union's first frontier may not cut the template's first DAG). Is the
//            remaining shape buildable from C? Not shown either way: the r5
//            reviewer's argument (a BreakReversePlay adjoint needs a loop, and a
//            looped gate sends the template plan to the InLoop Leak,
//            `planTerminalReversal`) covers the gates IN the loop, but a break
//            condition can read a register defined and stored before the loop, and
//            CondLiteral needs no loop. The record does not rest on it.
enum class GroupMode { Loud, Silent, Probe, ProbeAsLoud };

// What a Probe/ProbeAsLoud planner run WOULD do (emits nothing). Two sets, not one
// (R11 r5 F1): a producer call is both a gate and its own rail, so one mixed set
// could not tell "frees rail t" from "reverse-plays t's producer, freezes t".
struct GroupProbe {
  // Every gate any plan reverse-plays (`DataDag::Calls` — frozen rails' gates and
  // QRAM stores included) and every rail any plan frees (`Rails` − `FrozenRails`).
  llvm::SmallPtrSet<const llvm::CallInst *, 16> Gates;
  llvm::SmallPtrSet<const llvm::Value *, 16> Frees;
  // The gates of the FIRST DAG the planner walks — the whole DAG, or, when it is
  // measured upstream, the one its first frontier retry walks (every QRAM root
  // and measured rail borrowed, before anything is judged) — recorded whether or
  // not any plan emits. Every plan's DAG is inside it.
  llvm::SmallPtrSet<const llvm::CallInst *, 16> Walked;
  void addPlan(const DataDag &D);
  void setWalk(const DataDag &D);
};

// The per-group planner (Uncomputation.cpp). Returns, for Probe, the verdict
// above; for Loud/Silent, whether every plan it reached was emitted.
bool reverseTerminalGroup(llvm::Function &F, llvm::ArrayRef<llvm::CallInst *> Terminals,
                          TaintSet &taint, WidthDispatch &wd, llvm::DominatorTree &DT,
                          llvm::PostDominatorTree &PDT, llvm::LoopInfo &LI,
                          bool IterLocal,
                          llvm::SmallPtrSetImpl<const llvm::CallInst *> &ReversedGates,
                          llvm::SmallPtrSetImpl<llvm::Value *> &ReversedRails,
                          GroupMode Mode, GroupProbe *Probe = nullptr);

// Partition `Terminals` (program order) into the REGULAR group and one group per
// Phase-7.3 iteration-local loop, and plan each:
//   * a group with no clone-result terminal — Loud, exactly as main;
//   * otherwise PROBE the union of its template and clone terminals, and a
//     ProbeAsLoud of the template terminals alone; emit the union (Silent) iff it
//     plans out AND is NEVER WORSE (the bd kyy1 test, `neverWorse`):
//       - the template plan emits: the union reverse-plays every gate and frees
//         every rail it would (R11 r4 F-A — comparing frees alone missed a union
//         whose measured-rail frontier BORROWS a QRAM array root, dropping the
//         template part's store `_unc`s and frozen-root adjoints, the bd sxuk
//         dephasing disposition);
//       - it does not (Loud declines or leaks): the union's FIRST DAG contains
//         the template terminals' first DAG (`GroupProbe::Walked`) — its first
//         frontier, borrowed before anything is judged, cuts nothing Loud walks
//         (R11 r5: a conditional QRAM store behind a measured clone parent; the
//         union's first frontier borrowed the array, and main's loud divergent-arm
//         decline became an rc-0 accept with the store unreversed — sxuk again,
//         through `!TmplOk`). What the union's frontier FIXPOINT borrows after
//         that, a FORCED record or an open root, is main's own ruled disposition
//         for a closed group (bd 01po.12/01po.8; @frk in
//         spec_intermediate_unc_terminal_union_forced.ll is the all-template
//         control), so a union that closes what the template plan alone leaves
//         open (a template interior a clone call consumes) is kept;
//     else plan the template terminals Loud, exactly as main, and the clone
//     terminals after EVERY group, Silent.
// So a clone terminal never adds a decline, never changes a template terminal's
// verdict when the union refuses, and keeps round 1's joint reversal when it does
// not (a template interior a clone call consumes is closed only by the union).
void reverseTerminalGroups(llvm::Function &F,
                           llvm::ArrayRef<llvm::CallInst *> Terminals,
                           TaintSet &taint, WidthDispatch &wd,
                           llvm::DominatorTree &DT, llvm::PostDominatorTree &PDT,
                           llvm::LoopInfo &LI,
                           llvm::SmallPtrSetImpl<const llvm::CallInst *> &ReversedGates,
                           llvm::SmallPtrSetImpl<llvm::Value *> &ReversedRails);

}  // namespace cq

#endif  // CQ_IRPASS_TERMINAL_GROUPS_H_
