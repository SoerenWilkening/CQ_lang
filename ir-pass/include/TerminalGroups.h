// TerminalGroups.h — how the whole-DAG spine's DEAD-TERMINAL groups are formed
// and planned (bd test_C_libtooling-p3kd.13, R11 rounds 1-9). Internal to the
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
//            `!TmplOk` and the union must leave nothing cut (`Cut`): it
//            reverse-plays g, meeting the conflict, unless g's rail is exempt: a
//            FORCED record or an open root of its frontier fixpoint, or a register
//            root (r9; cut under any exempt rail, a measured one included), so g
//            is not reverse-played. That needs, at
//            once, a conflict
//            with an adjoint minted before uncompute (BreakReversePlay/CondLiteral)
//            or an earlier group's reversal, and a moved borrowed parent (or an
//            open root) under g. Round 4's QRAM-store exception (a rail reached
//            only through a store of an array the union borrows) is closed in both
//            branches: under `TmplOk` the union reverse-plays every store the
//            template plan does, and under `!TmplOk` it leaves nothing cut, so it
//            reverse-plays the store (never exempt) and walks that rail into the
//            same alternative. (r5 claimed a first-DAG containment test closed it —
//            false for a measured template group, whose first DAG had already
//            borrowed the array, R11 r6 F1; r6's store-only clause missed the
//            measured-rail half of the cut, r7 F1; r7's first-frontier cut missed
//            what the fixpoint's forced borrow cuts, r8 F1.) Is the remaining shape
//            buildable from C? Not shown either way: the r5
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
  // What the COMMITTED plans leave CUT (R11 r7-r9): every gate of the whole,
  // unborrowed walk that no plan reverse-plays, minus the OWN gates (`railOf`) of
  // the rails that hold no hazardous record — the final frontier's FORCED
  // records and open roots (bd 01po.8's ruled dispositions); its measured rails
  // measured on EVERY path, one measurement post-dominating the rail (bd ptue's
  // "a measured register is never touched" holds only then: measured on some
  // paths, the rail is a live record on the others, r9 F1); and the walk's
  // `cqrt_alloc` register ROOTS, whose own gates record no other register (r9
  // F2). Their ancestors still count, and so does every QRAM store (its rail is
  // the array, never exempt): a store behind a borrowed array (bd r2j3.21), a
  // QROM load behind a measured rail (bd r2j3.23) or behind a forced record, a
  // template record of a rail measured on some paths only (bd r2j3.24). Taken
  // once, after planning, on every path that commits (`reverseTerminalGroup`):
  // a final-outcome gate set (L3), whatever borrowed the frontier. r7 measured
  // the first frontier's cut only, which is one path of it. Empty when a plan
  // reverses the whole walk, and left empty when the probe refuses (`neverWorse`
  // reads only the union's, and only when the union planned out).
  llvm::SmallPtrSet<const llvm::CallInst *, 8> Cut;
  void addPlan(const DataDag &D);
  // After the plans: `D` the whole walk, `Exempt` the rails above whose own gates
  // do not count.
  void setCut(const DataDag &D,
              const llvm::SmallPtrSetImpl<llvm::Value *> &Exempt);
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
//       - it does not (Loud declines or leaks): the union leaves NOTHING CUT
//         (`GroupProbe::Cut` empty). R11 r5-r8, four rounds on one hole, each an
//         rc-0 accept of a record left unreversed where main declined: r5, a
//         conditional QRAM store behind a measured clone parent, borrowed with
//         the array (sxuk again, through `!TmplOk`); r6, a dead `arr[k] = 7`
//         before a later Ry on k, in a MEASURED template group whose own first DAG
//         had already borrowed the array, so r5's first-DAG containment passed
//         vacuously (spec_intermediate_unc_terminal_union_reject_measured_store.ll;
//         r7 added the store only the CLONE terminal reaches,
//         ..._reject_clone_store.ll); r7, a QROM load record `a = tbl[k]` behind a
//         MEASURED rail, cut by the ptue borrow and refused by the M-B interior
//         partition (..._reject_measured_rail_cut{,_divergent}.ll); r8, the same
//         load behind a FORCED record the fixpoint borrows
//         (..._reject_forced_cut.ll); r9, a template record of a rail measured
//         on SOME paths only, exempt as "measured" (..._reject_partial_measure.ll).
//         `Cut` subsumes r6's store clause and what r5's containment was for: with
//         nothing cut, everything the template terminals' first DAG holds (it lies
//         in the union's whole walk) is reverse-played by a union plan (`Gates`)
//         or is an exempt rail's own gate.
//         The FORCED record or open root the frontier FIXPOINT borrows is itself
//         main's ruled disposition for a closed group (bd 01po.12/01po.8; @frk in
//         spec_intermediate_unc_terminal_union_forced.ll is the all-template
//         control); the dead ancestor RECORDS its borrow cuts are not, and count
//         in `Cut` (a register ROOT among its ancestors records nothing and does
//         not, r9 F2). So a union that closes what the template plan alone leaves
//         open (a template interior a clone call consumes) is kept when its forced
//         record cuts no other record, and so is one
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
// THE `Cut` CLAUSE IS COARSE. Under `!TmplOk` a union that leaves anything cut
// splits, also where nothing observable follows. The residual classes, each
// main's own verdict and an over-decline only against rounds 6-8:
//   * a store whose index is never touched again (the R11 r6 reviewer's probe P2,
//     accepted by round 6; its r7 reconstruction is ..._reject_clone_store.ll
//     without the move of k);
//   * a cut TEMPLATE record the M-B interior partition would have reversed before
//     the move (R11 r7 probe q1 `mrc`, accepted by e075f4ff; `Y = a >> 4` of r8's
//     @fx). M-B runs after every group (`uncompute`) and records nothing into a
//     probe, so the probe cannot see that discharge;
//   * a rail measured on every path only JOINTLY, by several measurements none of
//     which post-dominates it (`measuredOnEveryPath`, r9): its own gates count.
// (r9's F2 removed one class: a register ROOT's own gates, cut under a forced
// record or under a rail measured on every path, now count as nothing —
// spec_intermediate_unc_terminal_union_forced_root.ll pins the forced case; R11
// r10 probe p1 checked the measured case, which no fixture pins.)
// Retirement trigger: unit D (bd r2j3.21 / r2j3.23 / r2j3.24) — once main's
// planner names a cut record that would be left unreversed before its parent's
// next move (a planner-side `firstHazardousCutRecord`), this clause asks that
// predicate instead of requiring `Cut` empty (a follow-up).
//
// NO NEW CUSTOMERS FOR bd r2j3.21, r2j3.23 OR r2j3.24 (R11 r6 F2, r7-r9 F1; L9).
// Main's own bd 01po.4/ptue frontier and its 01po.8 fixpoint leave a record they
// CUT unreversed — a QRAM store behind a borrowed array (r2j3.21), a QROM load
// behind a borrowed measured rail or forced record (r2j3.23), a record of a rail
// borrowed as "measured" though measured on some paths only (r2j3.24) — and a
// later move of the record's parent makes that observable (pre-existing,
// all-template: @mlgk of the r6 probe, `qk` of r7's q5, `fk` of r8's p1, `cmk` of
// r9's p3).
// This file adds no program to either DEFECT: per group, every cut record this
// file leaves unreversed is one main leaves unreversed in the same group, where
// main accepts that group:
//   (1) the split: the template terminals run Loud, which IS main. A record only the
//       clone terminals' DAG reaches is reached by no terminal on main (there a
//       clone result is no terminal, and a template value a clone call consumes is
//       not dead), so main's planner never reverses it either;
//   (2) the union under `TmplOk`: it reverse-plays every gate main's plan does, so
//       a record it leaves unreversed is one main's plan leaves (or (1)'s);
//   (3) the union under `!TmplOk`: its committed plans leave nothing cut beyond
//       the own gates of a forced record, an open root, a register root, or a
//       rail measured on every path (`Cut`).
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
