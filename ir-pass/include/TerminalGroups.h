// TerminalGroups.h — how the whole-DAG spine's DEAD-TERMINAL groups are formed
// and planned (bd test_C_libtooling-p3kd.13, R11 rounds 1-6). Internal to the
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
//            `!TmplOk` and the union's first frontier must cut nothing (`Cut`), so
//            it WALKS g (a gate the template plan reverse-plays is no measured
//            rail's own); the verdicts differ only if the union's frontier fixpoint
//            then FORCES g's record or borrows its open root, so g is not
//            reverse-played. That needs, at once, a conflict with an adjoint minted
//            before uncompute (BreakReversePlay/CondLiteral) or an earlier group's
//            reversal, and a moved borrowed parent (or an open root) under g. Round
//            4's QRAM-store exception (a rail reached only through a store of an
//            array the union borrows) is closed in both branches: under `TmplOk`
//            the union reverse-plays every store the template plan does, and under
//            `!TmplOk` its first frontier cuts nothing, a store included, so it
//            walks that rail and meets the conflict. (r5 claimed a first-DAG
//            containment test closed it — false for a measured template group,
//            whose first DAG had already borrowed the array, R11 r6 F1; r6's
//            store-only clause missed the measured-rail half of the cut, R11 r7
//            F1.) Is the remaining shape buildable from C? Not shown either way: the r5
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
  // What the FIRST frontier CUTS (R11 r7 F1): when the group is measured
  // upstream, the bd 01po.4/ptue retry borrows every QRAM array root and every
  // measured rail before anything is judged, and every plan walks inside that
  // borrowed DAG (the fixpoint only borrows more). `Cut` is the whole walk's gates
  // minus the borrowed walk's, minus the measured rails' OWN gates (`railOf` in
  // `MeasuredRails` — ptue's ruled disposition: a measured register is never
  // touched): a QRAM store (bd r2j3.21) and any record reachable only through a
  // borrowed array or measured rail, a QROM load behind a measured rail included
  // (bd r2j3.23). No plan of this group reverse-plays a member, and recorded
  // whether or not any plan emits. Empty when the group is not measured upstream.
  llvm::SmallPtrSet<const llvm::CallInst *, 8> Cut;
  void addPlan(const DataDag &D);
  // `D` the whole walk, `DR` the first frontier's borrowed walk of the same terms.
  void setCut(const DataDag &D, const DataDag &DR);
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
//       - it does not (Loud declines or leaks): the union's FIRST frontier cuts
//         NOTHING (`GroupProbe::Cut` empty). R11 r5-r7, three rounds on one hole,
//         each an rc-0 accept of a record left unreversed where main declined:
//         r5, a conditional QRAM store behind a measured clone parent, borrowed
//         with the array (sxuk again, through `!TmplOk`); r6, a dead `arr[k] = 7`
//         before a later Ry on k, in a MEASURED template group whose own first DAG
//         had already borrowed the array, so r5's first-DAG containment passed
//         vacuously (spec_intermediate_unc_terminal_union_reject_measured_store.ll;
//         r7 added the store only the CLONE terminal reaches,
//         ..._reject_clone_store.ll); r7, a
//         QROM load record `a = tbl[k]` behind a MEASURED rail, which the ptue
//         borrow cuts and the M-B interior partition refuses (a template record
//         there M-B would discharge; a load it does not) — the measured-rail half
//         of the same cut (..._reject_measured_rail_cut.ll). Every store is cut
//         (its rail is the array, never a measured register), so `Cut` subsumes
//         r6's store clause, and r5's first-DAG containment is implied (the
//         template terminals' walk is a sub-closure of the union's, and with
//         nothing cut it lies inside the union's borrowed walk). What the union's
//         frontier FIXPOINT borrows after that, a
//         FORCED record or an open root, is main's own ruled disposition for a
//         closed group (bd 01po.12/01po.8; @frk in
//         spec_intermediate_unc_terminal_union_forced.ll is the all-template
//         control), so a union that closes what the template plan alone leaves
//         open (a template interior a clone call consumes) is kept. So is one
//         whose fixpoint plans PER COMPONENT, each at its own anchor, where the
//         template terminals' single plan (no fixpoint: not measured upstream)
//         declines on a divergent arm — the union is measured upstream through a
//         clone parent, and each component's plan passes every check main's would
//         (R11 r6 I1; spec_intermediate_unc_terminal_union_percomp.ll);
//     else plan the template terminals Loud, exactly as main, and the clone
//     terminals after EVERY group, Silent.
// So a clone terminal never adds a decline, never changes a template terminal's
// verdict when the union refuses, and keeps round 1's joint reversal when it does
// not (a template interior a clone call consumes is closed only by the union).
//
// THE `Cut` CLAUSE IS COARSE. Under `!TmplOk` a union whose first frontier cuts
// anything splits, also where nothing observable follows: a store whose index is
// never touched again (the R11 r6 reviewer's probe P2, accepted by round 6; its r7
// reconstruction is ..._reject_clone_store.ll without the move of k), and a cut
// TEMPLATE record the M-B interior partition would have reversed before the move
// (R11 r7 probe q1 `mrc`, accepted by e075f4ff). M-B runs after every group
// (`uncompute`) and records nothing into a probe, and no plan of the group walks a
// cut gate, so the probe cannot see that discharge. Every such split is main's
// own verdict, an over-decline only against rounds 6-7. Retirement trigger: bd
// r2j3.21 / r2j3.23 (unit D) — once main's planner reverses a cut record before
// its parent's next move, or fails loudly, this clause can go.
//
// NO NEW CUSTOMERS FOR bd r2j3.21 OR r2j3.23 (R11 r6 F2, r7 F1; L9). Main's own bd
// 01po.4/ptue first frontier leaves a record it CUTS unreversed — a QRAM store
// behind a borrowed array (r2j3.21) or a QROM load behind a borrowed measured rail
// (r2j3.23) — and a later move of the record's parent makes that observable
// (pre-existing, all-template: @mlgk of the r6 probe, `qk` of the r7 probe q5).
// This file adds no program to either DEFECT: per group, every cut record this
// file leaves unreversed is one main leaves unreversed in the same group, where
// main accepts that group:
//   (1) the split: the template terminals run Loud, which IS main. A record only the
//       clone terminals' DAG reaches is reached by no terminal on main (there a
//       clone result is no terminal, and a template value a clone call consumes is
//       not dead), so main's planner never reverses it either;
//   (2) the union under `TmplOk`: it reverse-plays every gate main's plan does, so
//       a record it leaves unreversed is one main's plan leaves (or (1)'s);
//   (3) the union under `!TmplOk`: it cuts nothing (`Cut`).
// A record this file reverses where main leaves it is an improvement, never a
// customer. It does move programs between MECHANISMS (L9 disclosure, R11 r7 probe
// P3): under `TmplOk`, a store only a clone call's operand chain reaches
// (`arr[k] = 7; v = arr[p]; r = h(v); Ry(r); Ry(k, -.5); measure p, k`) is never
// walked on main, where the whole clone chain leaks (this bug), while the union
// reverses v and r and leaves the store through the 01po.4 borrow. Both rc 0 with
// the same unreversed store before Ry(k); the r2j3.21 fix must cover the union too.
void reverseTerminalGroups(llvm::Function &F,
                           llvm::ArrayRef<llvm::CallInst *> Terminals,
                           TaintSet &taint, WidthDispatch &wd,
                           llvm::DominatorTree &DT, llvm::PostDominatorTree &PDT,
                           llvm::LoopInfo &LI,
                           llvm::SmallPtrSetImpl<const llvm::CallInst *> &ReversedGates,
                           llvm::SmallPtrSetImpl<llvm::Value *> &ReversedRails);

}  // namespace cq

#endif  // CQ_IRPASS_TERMINAL_GROUPS_H_
