// TerminalGroups.h — how the whole-DAG spine's DEAD-TERMINAL groups are formed
// and planned (bd test_C_libtooling-p3kd.13, R11 rounds 1-9), and which records
// their plans may leave CUT (bd r2j3.21 / r2j3.23 / r2j3.24 / p3kd.14, batch 053
// unit D). Internal to the uncompute spine: `Uncomputation::uncompute` calls
// `reverseTerminalGroups`, which calls `reverseTerminalGroup` (the per-group
// planner, defined in Uncomputation.cpp) once or more per group.

#ifndef CQ_IRPASS_TERMINAL_GROUPS_H_
#define CQ_IRPASS_TERMINAL_GROUPS_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Function;
class Instruction;
class LoopInfo;
class PostDominatorTree;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct DataDag;
struct TaintSet;

// ── CUT RECORDS (bd test_C_libtooling-r2j3.21 / r2j3.23 / r2j3.24) ───────────
//
// THE DEFECT CLASS. A dead-terminal group measured upstream is planned by the
// FRONTIER RETRY (`reverseTerminalGroup`), which BORROWS registers instead of
// walking them: every QRAM array root (bd 01po.4), every measured rail (bd ptue),
// and, in the frontier fixpoint, open roots and forced records (bd 01po.8 /
// 01po.12). A borrowed register is never walked, so every gate reachable from the
// terminals ONLY through it is CUT from the reversal: a store behind a borrowed
// array (r2j3.21), a QROM load behind a borrowed measured rail or forced record
// (r2j3.23), a template record of a rail measured on SOME paths only and borrowed
// as "measured" (r2j3.24). A cut gate's rail is a dead RECORD of the registers its
// operands came from; left standing, the next non-diagonal gate on any of them
// acts on a register entangled with garbage the source does not have (owner
// ruling 2026-10-05, bd memory dead-record-live-across-move-ruling; owner ruling
// 2026-10-13, owner-ruling-qram-dropped-store-2026-10-13). All three were
// verify-clean rc-0 accepts on main fc6ee653.
//
// THE CUT SET is a final-outcome gate set (CLAUDE.md L3), taken by the planner
// once, of the COMMITTED plans, whatever borrowed the frontier:
//     Cut = D.Calls − ⋃ plan.Calls − own gates (`railOf`) of the rails that record
//           nothing hazardous: the final frontier's non-array open roots (bd
//           01po.8; `cqrt_alloc` roots — a FORCED record is no longer exempt
//           wholesale since R11 r2: its keep is asked per move, clause (c)), its
//           measured rails that
//           are measured on EVERY path to an exit (`measuredOnEveryPath`: one
//           post-dominating measurement or several that jointly cover every path;
//           ptue's "a measured register is never touched" holds only then —
//           r2j3.24, R11 r9 F1), and
//           the walk's `cqrt_alloc` register roots (whose own gates record no
//           other register — R11 r9 F2).
// Ancestors of every exempt rail still count, and so does every QRAM store (its
// rail is the array, never exempt). A rail measured on SOME paths stays BORROWED
// (the plans read its label only, and clause (d) and the yiid fence still guard
// that read); only its own gates stop being exempt, so a later move turns it into
// a hazardous cut record (loud) and no later move leaves it a benign leak.
//
// WHERE THE ONE PREDICATE (`isHazardousCutRecord`, R12) IS ASKED:
//   (1) the planner, of cut STORES: the M-B interior partition never owns a
//       store, so a hazardous one can only be reversed by WALKING the array. The
//       planner retries with only the measured rails borrowed — the array walked,
//       its stores reversed LIFO at the group's reversal point, which is the
//       owner's "reversed early when the group's reversal point precedes the next
//       non-diagonal gate on the store's index or value register" — and asks
//       again of the retry's committed plans. Still hazardous: LOUD (Loud mode,
//       `kMsgCutRecord` at the store); every other mode refuses the plan;
//   (2) after M-B (`uncompute`), of every other hazardous cut record of a LOUD
//       group: the M-B interior partition may discharge a cut TEMPLATE record
//       after its last use (a cut QRAM-LOAD record it does not own yet: the
//       r2j3.23 route that admits a load rail in M-B is a batch-053 follow-up), and
//       one that no partition reversed is LOUD (`kMsgCutRecord` at the gate);
//   (3) the terminal-union probe (bd p3kd.14, `neverWorse` below).
// Ground truth: Bennett.jl 824458d1 src/pebble/eager.jl:1-17,55-80,110-147 (a
// dead-end wire is replayed right after its last write only while its controls
// are stable, `_controls_stable`; otherwise it waits for the full reverse — CQ
// cannot wait past a non-diagonal gate on a live register, so it reverses early or
// fails loudly); store protocol src/shadow_memory.jl:10-18 (the tape takes the OLD
// cell value). BennettVM.jl 23d28e64 src/ir/memory_floor.jl:318-355 and :395-403
// (a store's delta is (addr, old value), restored in strict LIFO).

// THE IDENTITY-STORE EXEMPTION (owner ruling 2026-10-13). A cut QRAM store `S`
// records NOTHING iff every cell holds 0 when it runs and it writes 0: then the
// runtime's per-store tape holds the old cell value 0 for every index (the
// documented contract, runtime/cq_runtime.h `cqrt_qram_store_<W>`: the backend
// tapes the displaced OLD CELL VALUE, never the address), the array is |0…0⟩
// after it, and the joint state is a product independent of the index. Asked of
// the lowered IR; all four must hold:
//   E1 `railOf(S)` is a `cqrt_qram_alloc_<W>` (fresh |0⟩ cells: QramLowering's
//      bd r2j3.15 initializer proof);
//   E2 the stored value is a `cqrt_alloc_<W>` minted from a null constant
//      (`railBornZero`; -0.0 is not null), untainted, never gated in place;
//   E3 every OTHER in-place gate on the array that can reach `S` (a back edge
//      counts) is a store satisfying E2;
//   E4 the array's remaining users are forward loads and load `_unc`s only.
// A backend that tapes the ADDRESS breaks this exemption (the ruling says so).
// It keeps bd 01po.4's zero-store accepts accepted, unchanged
// (lowering_qram_store_measured_index_nonmain.ll, e2e
// slice_qram_local_store_measured_index). A runtime zero the IR does not show as
// a null constant is not exempt (an accepted over-decline).
bool isIdentityStore(const llvm::CallInst *S, const TaintSet &taint,
                     llvm::DominatorTree &DT);

// Is the cut gate `G` a HAZARDOUS dead record? True iff it is not an identity
// store, its rail is not GARBAGE — a rail carrying a non-permutation gate that a
// later reader then recorded, which no schedule returns to |0⟩ (owner ruling
// 2026-10-03, owner-ruling-garbage-realizable-compiles: keep it and warn, never
// decline; the M-A live-record guard warns) — and some register in the CONE of its
// tainted operands (every value the
// backward walk from them reaches — a load's array included, whose cells record
// the stores that wrote them) has a NON-PERMUTATION MOVE (`isNonPermutationMove`)
// reachable from `G`, across which the program does not itself keep `G`'s rail
// (`recordLiveAcrossMove` with the group's reversal point `At`; a null `At` grants
// no such exemption). FAILS CLOSED (true) when a cone root is neither a
// `cqrt_alloc` register nor a QRAM array, or a cone rail belongs to a control
// emitter or a graveyard: the walk cannot see those registers' moves. A cut record
// with no later move is a benign leak (Rule 5) and is not hazardous. A cone member
// measured before the move is still counted (conservative; see bd follow-up in the
// batch-053 L1 report).
//
// R11 r1 (one invariant, per (record, move) pair, L3): every exemption above is
// asked on EVERY path from the record to EACH later move M of a cone register — a
// measurement of R on every path to M; garbage only when a rotation of R and a
// KEPT reader after it (not reversed by any committed plan, `Reversed`) lie on
// every path to M (R11 r2 F2: the reader's rail used after M, or a measurement of
// it on EVERY path from the reader to M); forced only across THAT move M (R11 r2
// F1: `recordLiveAcrossMove(…, OnlyMove = M)`), through a later use that keeps the
// record (for a store, a read that may observe a written cell, `mayObserveStore`).
bool isHazardousCutRecord(llvm::CallInst *G, llvm::Instruction *At,
                          llvm::DominatorTree &DT, const TaintSet &taint,
                          const llvm::SmallPtrSetImpl<const llvm::CallInst *> &Reversed);

// The first gate of `Cut` (program order) `isHazardousCutRecord` convicts, asked
// of QRAM stores only when `StoresOnly`; null when there is none.
llvm::CallInst *firstHazardousCutRecord(
    llvm::ArrayRef<llvm::CallInst *> Cut, llvm::Instruction *At,
    llvm::DominatorTree &DT, const TaintSet &taint, bool StoresOnly,
    const llvm::SmallPtrSetImpl<const llvm::CallInst *> &Reversed);

// R11 r1 A-F2 — may the later array user `U` observe a cell the QRAM store `S`
// wrote? Only a forward load can; a later store or an adjoint never does. A load
// at a literal index provably outside the store's index range (a different literal,
// or a literal > 1 against a one-bit index register) does not; everything else may
// (fail closed). THE one spelling of "a later read keeps this store's record",
// asked by `recordLiveAcrossMove` for a store record.
bool mayObserveStore(const llvm::CallInst *U, const llvm::CallInst *S,
                     const TaintSet &taint);

// bd 01po.8 — the forced-record test, defined in Uncomputation.cpp beside the
// frontier fixpoint that first asked it (see its comment there). Exported for
// `isHazardousCutRecord`.
// `OnlyMove` (R11 r2 F1), when non-null, restricts the question to that one move of
// `P` — what the per-(record, move) hazard asks; null is the fixpoint's "forced by
// SOME move of P".
bool recordLiveAcrossMove(llvm::CallInst *G, llvm::Value *R, llvm::Value *P,
                          llvm::Instruction *At, llvm::DominatorTree &DT,
                          const TaintSet &taint,
                          const llvm::CallInst *OnlyMove = nullptr);

// How one terminal group is planned:
//   Loud   — main's behaviour exactly (every refusal keeps its diagnostic);
//   Silent — no diagnostic; a plan is emitted only if it touches nothing an
//            earlier group reversed (`cloneTerminalReversalDisjoint`), and never
//            when its plans leave a hazardous cut record (that record would
//            need M-B and a later loud check this mode cannot add: a clone
//            terminal never adds a decline);
//   Probe  — Silent's verdict, but NOTHING is emitted: true iff at least one plan
//            and every plan would emit, with what they would do recorded in
//            `*Probe` (GroupProbe, below) — a hazardous cut load or template
//            record is RECORDED (`GroupProbe::HazardousCut`), not refused, so
//            `neverWorse` decides. Planning is SIDE-EFFECT-FREE (no taint write,
//            no IR change before `emitDagReversal`), which is what makes a refused
//            probe leave the module exactly as it found it. That invariant is
//            LOAD-BEARING for `reverseTerminalGroups`: a change that makes
//            planning mutate anything must give the probe a dry-run path first;
//   ProbeAsLoud — Probe WITHOUT the disjointness check, which Loud never asks: what
//            the template terminals' Loud plan would emit (R11 r3 F1 — a Probe
//            can refuse on `taint.SpineOps` adjoints minted BEFORE uncompute, by
//            BreakReversePlay and CondLiteral, where Loud emits; QramIndexWidth's
//            bracket runs AFTER uncompute, CQLoweringPass, so it is not one of them).
//            A FreePoint reject, and a hazardous cut STORE the array-walking retry
//            cannot clear, still refuse: Loud would DECLINE there.
//            WHY NO FIXTURE PINS IT (R11 r4 F-D, r5 F3 — the record): the two
//            differ only where a disjointness check refuses the template-only plan
//            on a gate g it would reverse-play (or a rail g writes or reads), and
//            Loud would emit. Under ProbeAsLoud the union must then reverse-play g
//            (`T.Gates ⊆ U.Gates`), meets g in its own disjointness check and
//            refuses: the split runs, as main. Under Probe the template would be
//            `!TmplOk` and the union must leave no HAZARDOUS cut record: it
//            reverse-plays g, meeting the conflict, unless g is cut and harmless —
//            the own gate of an exempt rail (above), or a record no later move
//            reaches. That needs, at once, a conflict with an adjoint minted before
//            uncompute (BreakReversePlay/CondLiteral) or an earlier group's
//            reversal, and a moved borrowed parent (or an open root) under g. Is
//            that buildable from C? Not shown either way: the r5 reviewer's
//            argument (a BreakReversePlay adjoint needs a loop, and a looped gate
//            sends the template plan to the InLoop Leak, `planTerminalReversal`)
//            covers the gates IN the loop, but a break condition can read a
//            register defined and stored before the loop, and CondLiteral needs no
//            loop. The record does not rest on it.
enum class GroupMode { Loud, Silent, Probe, ProbeAsLoud };

// What a Probe/ProbeAsLoud planner run WOULD do (emits nothing). Two sets, not one
// (R11 r5 F1): a producer call is both a gate and its own rail, so one mixed set
// could not tell "frees rail t" from "reverse-plays t's producer, freezes t".
struct GroupProbe {
  // Every gate any plan reverse-plays (`DataDag::Calls` — frozen rails' gates and
  // QRAM stores included) and every rail any plan frees (`Rails` − `FrozenRails`
  // − QRAM arrays, which are never freed).
  llvm::SmallPtrSet<const llvm::CallInst *, 16> Gates;
  llvm::SmallPtrSet<const llvm::Value *, 16> Frees;
  // The first HAZARDOUS record the COMMITTED plans leave cut (the CUT SET above,
  // asked of `isHazardousCutRecord` once, after planning, on every path that
  // commits); null when every cut record is harmless or nothing is cut, and left
  // null when the probe refuses. A hazardous cut store never gets here (the
  // planner refuses it); what can is a load or template record M-B might yet
  // discharge, which a probe cannot see (M-B runs after every group).
  const llvm::CallInst *HazardousCut = nullptr;
  void addPlan(const DataDag &D);
};

// The per-group planner (Uncomputation.cpp). Returns, for Probe, the verdict
// above; for Loud/Silent, whether every plan it reached was emitted. In Loud mode
// it appends to `Pending` every hazardous cut load / template record its committed
// plans leave, for `uncompute`'s post-M-B check (2).
bool reverseTerminalGroup(llvm::Function &F, llvm::ArrayRef<llvm::CallInst *> Terminals,
                          TaintSet &taint, WidthDispatch &wd, llvm::DominatorTree &DT,
                          llvm::PostDominatorTree &PDT, llvm::LoopInfo &LI,
                          bool IterLocal,
                          llvm::SmallPtrSetImpl<const llvm::CallInst *> &ReversedGates,
                          llvm::SmallPtrSetImpl<llvm::Value *> &ReversedRails,
                          llvm::SmallVectorImpl<llvm::CallInst *> &Pending,
                          GroupMode Mode, GroupProbe *Probe = nullptr);

// Partition `Terminals` (program order) into the REGULAR group and one group per
// Phase-7.3 iteration-local loop, and plan each:
//   * a group with no clone-result terminal — Loud, exactly as main;
//   * otherwise PROBE the union of its template and clone terminals, and a
//     ProbeAsLoud of the template terminals alone; emit the union (Silent) iff it
//     plans out AND is NEVER WORSE (the bd kyy1 test, `neverWorse`):
//       - the union leaves NO HAZARDOUS CUT RECORD (`GroupProbe::HazardousCut`
//         null, bd p3kd.14). Silent refuses such a plan, so this is also what
//         keeps the CHECKED re-plan below emitting what the probe accepted;
//       - the template plan emits: the union reverse-plays every gate and frees
//         every rail it would (R11 r4 F-A — comparing frees alone missed a union
//         whose measured-rail frontier BORROWS a QRAM array root, dropping the
//         template part's store `_unc`s and frozen-root adjoints, the bd sxuk
//         dephasing disposition);
//       - it does not (Loud declines or leaks): nothing more. Until bd p3kd.14 the
//         union had to leave NOTHING cut (R11 r5-r8, four rounds on one hole,
//         each an rc-0 accept of a record left unreversed where main declined:
//         r5, a conditional QRAM store behind a measured clone parent; r6, a dead
//         `arr[k] = 7` before a later Ry on k in a MEASURED template group
//         (spec_intermediate_unc_terminal_union_reject_measured_store.ll; r7 the
//         store only the CLONE terminal reaches, ..._reject_clone_store.ll); r7, a
//         QROM load record `a = tbl[k]` behind a MEASURED rail
//         (..._reject_measured_rail_cut{,_divergent}.ll); r8, the same load behind
//         a FORCED record the fixpoint borrows (..._reject_forced_cut.ll); r9, a
//         template record of a rail measured on SOME paths only
//         (..._reject_partial_measure.ll)). That clause was COARSE: it also split
//         a union whose cut records no later move reaches (R11 r6 probe P2: a
//         store whose index is never moved again; now
//         spec_intermediate_unc_terminal_union_cut_benign.ll). It asks the
//         planner's predicate now (R12), and the planner's own fix covers the
//         hazardous half: a hazardous cut store is reversed by walking the array
//         or refused, a hazardous cut load / template record is never emitted
//         Silent. Residual over-decline: a cut TEMPLATE record M-B would have
//         discharged before the move (R11 r7 probe q1 `mrc`; M-B runs after every
//         group and records nothing into a probe) still splits, main's own verdict
//         for the template terminals. (The other r9 residual, a rail measured on
//         every path only JOINTLY, is gone: `measuredOnEveryPath` walks the joint
//         cover since bd r2j3.24.)
//     else plan the template terminals Loud, exactly as main, and the clone
//     terminals after EVERY group, Silent.
// So a clone terminal never adds a decline, never changes a template terminal's
// verdict when the union refuses, and keeps round 1's joint reversal when it does
// not (a template interior a clone call consumes is closed only by the union).
//
// NO CUSTOMERS FOR A CUT RECORD (bd r2j3.21 / r2j3.23 / r2j3.24, L9). Every path
// that commits a frontier plan asks the cut set: a Loud group's hazardous cut
// record is reversed (walked array; M-B) or loud, a Silent group refuses one, and
// a union is emitted only with none. What any group still leaves cut is harmless
// by the predicate: an identity store, a record the program keeps across the move
// (forced), or a record no later move reaches (a benign leak, Rule 5). The L9
// disclosure of p3kd.13 (a store only a clone call's chain reaches, `arr[k] = 7;
// v = arr[p]; r = h(v); Ry(r); Ry(k, -.5)`, R11 r7 probe P3: never walked on
// main, cut by the union's array borrow) is now an accept with the store walked
// and reversed, or the loud decline.
void reverseTerminalGroups(llvm::Function &F,
                           llvm::ArrayRef<llvm::CallInst *> Terminals,
                           TaintSet &taint, WidthDispatch &wd,
                           llvm::DominatorTree &DT, llvm::PostDominatorTree &PDT,
                           llvm::LoopInfo &LI,
                           llvm::SmallPtrSetImpl<const llvm::CallInst *> &ReversedGates,
                           llvm::SmallPtrSetImpl<llvm::Value *> &ReversedRails,
                           llvm::SmallVectorImpl<llvm::CallInst *> &Pending);

}  // namespace cq

#endif  // CQ_IRPASS_TERMINAL_GROUPS_H_
