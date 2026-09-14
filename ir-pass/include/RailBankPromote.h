// RailBankPromote.h — bd `xdu2` / L-1a clause C5: THE PER-ACTIVATION PROMOTER.
//
// An ACCEPT-ONLY IR-to-IR normalisation (the `MergePhiPeel` / `promoteFp80Union`
// / `flattenPredMuxRegions` / `promoteVolatileScalarLocals` family): it forwards
// a bounded rail BANK's cell to SSA WITHIN ONE ACTIVATION, so the loop body the
// rest of the pass sees is register-resident and the existing control chain
// applies unchanged. It mints NO gate, emits NO runtime symbol and NEVER
// diagnoses; an off-pattern shape is left BYTE-UNTOUCHED for its existing loud
// owner.
//
// ── THE CONTRACT, PER ACTIVATION (`SCOPE_L1a.md` §2 clause C5) ──────────────
//
//   1. the SEED load becomes the proven initializer CONSTANT;
//   2. every intra-activation load becomes the dominating store's VALUE — an SSA
//      merge φ where the store is conditional;
//   3. exactly ONE store per activation survives, at the activation's END.
//
// ── WHY THE NAIVE THING IS WRONG (`SCOPE_L1a.md` §0 H3, MEASURED) ───────────
//
// bd `xdu2` clause 5 says "the alloca's element type is rewritten to the handle
// type and the `store`/`load` pair carries handles". Measured, that is NOT
// SUFFICIENT: in the raw customer the cell is read TWICE per trip and the second
// read is PARTIALLY AVAILABLE — the store sits in the conditional arm, so GVN
// does not forward it and `-O1` emits a second `load` off the same address:
//
//    8:  %9  = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
//        %10 = load i8, ptr %9                  ; the SEED (cell never written yet)
//        %12 = call i1 @cq_theta_i1(i1 %11, double 5.000000e-01)
//        store i8 %13, ptr %9
//   14:  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5   ; SAME address
//        %16 = load i8, ptr %15                 ; handle on the arm edge, SEED on
//                                               ; the pred edge
//
// A naive element-type rewrite makes `%16` load `0` AS A HANDLE on the pred
// edge — and `h0` is a REAL RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`), so
// that reading is a live-qubit alias, not a null. The correct reading of `%16`
// is THE REGION'S MERGE φ, which is what this stage builds. The target is not a
// hand construction: `clang -O1` emits it verbatim from the equivalent source
// (`trackL/probes/L1_promoted_store.c`), and everything after the promotion is
// SSA.
//
// ⚠ It also FALSIFIES A SHIPPED DOCTRINE CLAIM, and the fixture that carries it
// must be amended rather than left to contradict the code:
// `control_classical_call_arm_reject_localarray_store.ll` says the store->load
// forwarding is "UNREACHABLE on the clang -O1/-O2/-O3 validated floor — GVN
// already forwards every provably-same-address round-trip before cq-lowering
// runs." `a_loop_n3.c` at `-O1` is a counterexample. The claim holds for FULLY
// AVAILABLE stores only.
//
// ── THE SLOT, AND WHY IT MAKES THE ROUND-2 (L1) ANSWER TRIVIAL ──────────────
//
// FIRST in the `-O1`-repair normaliser fixpoint family of `CQLoweringPass.cpp`:
// immediately after the `lowerByRefInline` fixpoint and BEFORE
// `foldIdentityBitcasts`, in BOTH entry points. The full proof is at the call
// site; the shape of it is:
//
//   * this stage is a NORMALISER, not a lowering (Rule 14 / L6). Its caller runs
//     `while (promoteRailBankCells(M, taint)) taint = propagate(M, wd);` — a FULL
//     re-propagation from scratch after every change, which is strictly stronger
//     than a taint DELTA. So `adjudicateTaintDelta` is NOT owed;
//   * and every stage that adjudicates CONSUMERS of tainted values runs AFTER
//     it, including `foldIdentityBitcasts`, which is the SOLE handler for a
//     same-width int<->int `bitcast` and is `adjudicateTaintDelta`'s CALL 1
//     precisely because a bitcast made tainted by a later taint-growth stage is
//     left standing and dies at `no template for opcode 'bitcast i32'`
//     (bd b6ap F-B6R2-1). Taking the slot ABOVE it closes that window by ORDER.
//
// ⚠ L1's TAINT-GROWTH SPECIES IS THE ONE THIS STAGE MUST ARGUE WITH, and the
// argument is the SLOT, never the stage's good behaviour. `MergePhiPeel`
// manufactures tainted values ~90 lines AFTER the guards that adjudicate
// consumers of tainted values, and the cure was `adjudicateTaintDelta` — five
// plain-C escapes of a rail HANDLE compiled at `opt` exit 0 (bd b6ap F-B6-1).
// THIS STAGE GROWS TAINT TOO, and by more than the peel does: replacing a bank
// `load` (untainted today — taint is SSA-only, `propagateWorklist` has no
// load/store rule) with the STORED VALUE makes every downstream user of that
// load quantum. The reason it is safe is ONLY that no consumer guard has run
// yet. RETIREMENT TRIGGER: the day this call moves below `detectSpecializations`
// / `declineTaintEscapes` / `declineStaleRecordOps` / `recordStaleQuantumReaders`
// — or the day a taint-consuming stage is added ABOVE it — it owes
// `adjudicateTaintDelta` exactly as the peel does, and the omission has NO
// DIAGNOSTIC ANYWHERE.
//
// ── THE STAGED LANDING: THIS DOES NOT MAKE ANYTHING COMPILE ─────────────────
//
// W1 is three pieces and only two land this session. The TAINT RULE (a `load`
// from a `!cq.railbank` alloca is tainted), the `[N x i1]` -> `[N x i32]` TYPE
// REWRITE and the D5 ALLOW-LIST are deliberately deferred. Until they land, an
// ACCEPTED bank is a SILENT MISCOMPILE and `SCOPE_L1a.md` §4.4(D) names the
// mechanism exactly: `cq_measure(b[i])` on an UNTAINTED load takes
// `MeasureLowering.cpp:151`'s classical split and emits NO GATE, NO SYMBOL AND
// NO TRACE LINE — and the golden byte-diff cannot see a measurement that was
// never emitted.
//
// So after this promotion the program STILL DECLINES `cq taint escape: tainted
// value stored to memory`, at the ONE surviving store per activation. The
// observable blast radius is confined to programs that decline `kMsgStore`
// today, and the confinement is STRUCTURAL rather than hoped for: the stage
// fires only on an alloca whose stores Track A's carve calls `Bank`, and the
// carve's C3 requires a TAINTED STORED VALUE. No classical array anywhere is a
// candidate.
//
// ⚠ This is a STAGED LANDING of one capability, not Rule 17's punt. Rule 17
// forbids substituting a decline for the hard work; it does not forbid landing a
// multi-piece capability in the order that keeps the tree sound at every commit.
//
// ── WHAT IT REFUSES, AND WHY EACH CLAUSE IS THE REWRITE'S AND NOT THE CARVE'S ─
//
// The carve (`RailBankCarve.h`, Track A) answers ONE question — *is this store a
// rail-bank cell write?* — and this stage CALLS it, never re-derives it (Rule
// 14; a second spelling of a predicate the tree owns is the drbq Inc-3 (b')
// defect, filed by name). The B-clauses below are not a second carve: they are
// the REWRITE'S OWN worklist and the shapes the rewrite cannot express. An
// accept needs BOTH, so a divergence can only ever over-DECLINE.
//
//   B1  ONE BANK, ONE LOOP. Every access inside any loop is inside the SAME loop
//       `L`, directly (`LI.getLoopFor(BB) == L` — an access in a SUB-LOOP is
//       refused, not modelled), and `L` has a preheader and a single latch.
//   B2  ONE CELL PER ACTIVATION. Every in-`L` access gep has the same address
//       SCEV. Two addresses in one activation (`b[i]` beside `b[i+1]`) is
//       refused: `b[i+1]`'s write would be trip `i+1`'s SEED, so the "the cell
//       starts at the initializer" premise this whole stage rests on is false.
//   B3  NO EARLY EXIT. `L->getExitingBlock() == L->getLoopLatch()`. The single
//       store is placed at the latch, so a path that leaves the loop without
//       reaching the latch would DROP a write the source performed — and with a
//       measure loop after the break that write is observable.
//   B4  SIMPLE ACCESSES. Non-volatile, non-atomic, exact cell type; no lifetime
//       marker and no `MemIntrinsic` touching the bank inside `L`.
//   B5  ONE WRITER. No store to the bank outside `L` — a second writer makes the
//       per-activation seed something other than the initializer.
//   B6  ≥1 `Bank` store inside `L`, and EVERY store into the alloca is `Bank`.
//   B7  MATERIALISABLE AT THE LATCH. The canonical access gep's operands all
//       dominate the latch terminator, so the clone is legal there.
//   B8  ≥1 load inside `L`. With no load there is nothing to forward, the
//       existing store already IS the activation's write, and firing would only
//       churn the IR — so the module is left BYTE-UNTOUCHED (and that refusal is
//       pinned by `railbank_promote_o1_shape.ll`, against a module dump, so it
//       is not the vacuity trap Rule 12 hygiene defect (c) describes).
//   B9  NOT ALREADY PROMOTED (`isRailBankAlloca` — the `!cq.railbank` record this
//       stage MINTS). This is what makes the caller's fixpoint TERMINATE: the
//       stage ADDS a store, so without the record it would re-promote its own
//       output forever.
//
// ── THE PER-ACTIVATION CONTAINMENT PROOF (why no φ crosses the back edge) ────
//
// φ placement is `llvm::SSAUpdater`'s, not hand-rolled. What IS hand-rolled is
// the ACCESS ORDERING inside each block — exactly the part `LoadAndStorePromoter`
// hand-rolls too — because this stage needs one thing that utility does not
// offer: the live-in value at the LOOP HEADER is the INITIALIZER, not a value
// flowing round the back edge.
//
// `SSA.AddAvailableValue(Header, …)` is registered UNCONDITIONALLY for the
// header — the last in-header store's value, or the seed constant when the
// header has none. `SSAUpdater` stops its predecessor walk at any block that has
// an available value, and the header is the ONLY block of a natural loop with a
// predecessor outside `L` or across the back edge. Therefore every query made
// here terminates inside `L` without ever reading the latch's value from the
// previous trip. The one remaining case is a load IN the header with no
// preceding in-header store: `GetValueInMiddleOfBlock(Header)` WOULD walk the
// header's predecessors (preheader AND latch) and build exactly the wrong φ, so
// that case is answered directly with the seed and never asked of the updater.
//
// ⚠ THE PROOF IS A THEOREM ONLY UNDER B2 + C2'. It says "this trip's cell was
// never written before", and that is the carve's INJECTIVITY clause — an affine
// `{0,+,1}` index with a constant exact trip count — plus B2's one-address rule.
// Weaken either and the seed is a previous trip's live rail read as a classical
// zero: a hidden `|0>` assertion on an entangled qubit, which no fence in the
// tree would see (`SCOPE_L1a.md` §4.1: the rail/wire/uncompute machinery is
// MEMORY-BLIND by construction).
//
// Design of record: `docs/prd/phase-04-swap-route-control/inc1-records/
// session-2026-09-14-orchestrator/trackL/SCOPE_L1a.md` (§0 H3, §2 C5, §3(a),
// §4.4(D)); this session's `trackB/{BRIEF_B,IMPL_B}.md`; owner rulings in
// `trackB/../DECISIONS.md` (D1).

#ifndef CQ_IRPASS_RAILBANKPROMOTE_H
#define CQ_IRPASS_RAILBANKPROMOTE_H

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Promote ONE rail bank's cells to per-activation SSA. Returns true iff the
// module was mutated; the caller drives it to a fixpoint and re-`propagate`s
// after every true return (see the slot note above — the re-propagation is what
// discharges L1, and it is the caller's obligation, not this function's).
//
// ONE BANK PER CALL, the `flattenPredMuxRegions` / `unrollConstTripLoops`
// precedent: each claim then sees fresh taint and fresh dominance, and no cached
// block identity crosses an erasure (Rule 9).
//
// `taint` is READ ONLY — this stage maintains no taint bookkeeping of its own
// (contrast `MergePhiPeel`, which must, because by its slot the `TaintSet`
// carries fields a rebuild would discard). At this slot NOTHING has written
// bookkeeping into the set, so the caller's `taint = propagate(M, wd)` is a
// complete and exact update. RETIREMENT TRIGGER: the day this call moves below
// `lowerControlledIOSinks` / `lowerLoops`, the caller can no longer rebuild the
// set and this signature must change with it.
//
// Env lever `CQ_RAILBANK_DBG` (no behaviour change): one line per promotion,
// plus a module dump at the call site once the fixpoint settles — the
// `CQ_FP80_DBG` / `CQ_SPEC_DBG` precedent. It exists because every module this
// stage fires on still DECLINES, and a `DS_Error` decline writes 0 bytes to
// stdout, so the promotion is not observable on the lowered IR at all.
bool promoteRailBankCells(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_RAILBANKPROMOTE_H
