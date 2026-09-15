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
// The carve (`QramLowering.h`, Track A) answers ONE question — *is this store a
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
//   B4′ NOTHING NON-REWRITABLE OBSERVES THE OBJECT INSIDE `L` — THE CLAUSE THAT
//       LICENSES MOVING THE STORE. This stage relocates the activation's write to
//       the activation's END, so any other observer inside the body would see the
//       write at a different point in the trip; that is a CLASSICAL miscompile and
//       `opt -verify` cannot see it. ⚠ It is keyed on the OBSERVATION POINTS, not
//       on the addresses (bd `test_C_libtooling-n74d`, P1, fixed 2026-09-15): `-O1`
//       LICM hoists a loop-invariant cell address to the preheader and leaves the
//       LOAD in the loop, so the gep's block and the load's block are routinely
//       different blocks on the validated floor. A gep observes nothing.
//   B5  ONE WRITER. No store to the bank outside `L` — a second writer makes the
//       per-activation seed something other than the initializer.
//   B6  ≥1 `BankRaw` store inside `L`, and EVERY store into the alloca is
//       `BankRaw`. ⚠ `BankRaw`, NOT `Bank` — the carve's clause C7 (bd
//       `test_C_libtooling-de8n`, 2026-09-15) splits the accept-shaped verdict in
//       two, and the split IS this stage's contract: **the promoter's INPUT is
//       `BankRaw` and its OUTPUT is `Bank`.** `Bank` means "no read of the bank
//       survives inside `L`, and the store is total per trip", which is exactly
//       what `applyBank` produces and exactly what the deferred type rewrite may
//       consume. Requiring `BankRaw` narrows nothing that ever fired (B8 refuses a
//       bank with no in-`L` load, and a `Bank` bank has none); it makes the
//       contract checked at both ends, and gives the caller's fixpoint a SECOND
//       termination guarantee beside B8.
//   B7  MATERIALISABLE AT THE LATCH. The canonical access gep's operands all
//       dominate the latch terminator, so the clone is legal there.
//   B8  ≥1 load inside `L`. With no load there is nothing to forward, the
//       existing store already IS the activation's write, and firing would only
//       churn the IR — so the module is left BYTE-UNTOUCHED (and that refusal is
//       pinned by `railbank_promote_reject_already_ssa.ll`, against a module
//       dump, so it is not the vacuity trap Rule 12 hygiene defect (c)
//       describes).
//       ⚠ AND B8 IS LOAD-BEARING FOR TERMINATION, not only for "is it worth
//       doing" — see the note at `RailBankPromote.cpp`'s `applyBank` tail. The
//       caller drives this stage to a fixpoint and the stage ADDS a store, so
//       something must stop it re-promoting its own output. `applyBank`
//       replaces EVERY in-`L` load, so after a promotion the write loop
//       contains none and `planBank` refuses on the next turn. RETIREMENT
//       TRIGGER: weaken B8 (for instance to admit a bank with no load, a no-op
//       today) and the fixpoint DOES NOT TERMINATE — reinstate a membership
//       record in the same change.
//   B9  EXACTLY ONE WRITE PER ACTIVATION (added 2026-09-15, merge filing F-2).
//       Unreachable today — the carve's C4 second half refuses a multi-store bank
//       before B6 returns — and written here anyway, because *the promoter's
//       soundness must not rest on a conjunct that lives in another file and was
//       cleared for a different purpose* (`MERGE_FILINGS.md` F-1). Its second job
//       is to keep `applyBank` simple: with one store there is one available value
//       to register and one write to relocate, so the several-stores-per-activation
//       `SSAUpdater` merge that used to sit in PASS A — unreachable, untested, and
//       one widening away from becoming live — is DELETED rather than dormant.
//       ⚠ RETIREMENT TRIGGER, stating what is OWED rather than what is allowed:
//       the day C4 or B9 admits a two-writer bank, PASS A needs the several-stores
//       merge back (register the last cell store of every block; take the
//       canonical store by dominance among them) and it lands WITH a red-green
//       pair — an accept with two stores in one activation, and an adversarial
//       probe putting them in sibling arms. Never one without the other.
//
// ⚠ THE CLAUSE THAT USED TO BE B9 WAS STALE FOR THE WHOLE OF TRACK B'S GATE, AND
// ITS NUMBER HAS SINCE BEEN REUSED (above). It read *"B9 NOT ALREADY PROMOTED
// (`isRailBankAlloca` — the `!cq.railbank` record this stage MINTS)"*, and the
// shipped stage mints NO metadata: `SCOPE_L1a.md` §4.3 designs the record as the
// FREEZE's membership proof, the freeze is in the deferred half, and minted now it
// would have no reader (Rule 12 hygiene defect (c)). `RailBankPromote.cpp`'s
// `applyBank` tail carries the correct statement, Track B's own injection round 4
// (mutant M13, "re-add the mint") is CAUGHT by all seven accept fixtures through
// their `NOMD` prefix, and `isRailBankAlloca` is not shipped at all
// (`trackA/SIGNATURE.md` deviation (2)). Corrected at the 2026-09-14c merge
// gate; `IMPL_B.md` §2.3 / §7 / §8 / §10.1 still carry the old wording and are
// history. ⚠ L7-WITH-A-TWIST, verbatim: *a record correction that is not applied
// to the source is not a correction* — this one had been applied to the .cpp and
// not to the .h, which is the same defect wearing the other shoe.
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
class AllocaInst;
class Module;
class Type;
class Value;
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

// ── bd `xdu2` / L-1a Increment W1, THE SECOND HALF (session 2026-09-15) ────
//
// Three pieces that land TOGETHER or not at all, because any two of them
// without the third is a SILENT MISCOMPILE with a measured trace:
//
//   piece 1  THE TAINT RULE     — a `load` from a `!cq.railbank` alloca is
//                                 tainted (`TaintPropagation::collectAndSeed`);
//   piece 2  THE TYPE REWRITE   — `[N x cell]` → `[N x i32]` of handles
//                                 (`rewriteRailBankCellTypes`, below);
//   piece 3  THE D5 ALLOW-LIST  — the `Bank` store stops declining and every
//                                 reader of a bank load that is not on a
//                                 POSITIVE list is a loud decline
//                                 (`declineUnallowedRailBankReaders`).
//
// ⚠ PIECE 3 WITHOUT PIECE 1 IS THE MISCOMPILE, AND IT WAS REPRODUCED WITH A
// TRACE BEFORE THE FIX (`trackB/IMPL_B2.md` §1, probe
// `probes/emulate_piece3.sh b12_bank_bool_measureloop.c`): `opt` exit 0,
// STRICT stage 2b `0 violation(s), 0 unproven`, a plausible SIX-line trace of
// three minted and rotated rails — and the program's three `cq_measure(b0[i])`
// calls emit NOTHING AT ALL, because `MeasureLowering`'s classical split on an
// UNTAINTED operand emits no gate, no symbol and no trace line, and a golden
// byte-diff cannot see a measurement that was never emitted. That is why there
// is no staged landing here: the three pieces are one commit.
//
// ⚠ AND THE WHOLE OF IT GATES ON `RailBankCarve::Bank`, NEVER ON "a bank"
// (`trackA/SIGNATURE.md` §4). `BankRaw` is the PROMOTER'S INPUT and must keep
// declining forever: its per-trip cell read is still INSIDE the walk loop and
// PARTIALLY AVAILABLE, so after the `[N x cell]` → `[N x i32]` rewrite it would
// read the initializer `0` AS A HANDLE — and `h0` is a LIVE RAIL in this
// runtime (`cqrt_alloc_i1(0) -> h0`).

// THE `!cq.railbank` MEMBERSHIP RECORD, minted by `markRailBankAllocas` and by
// nothing else. It is the ONE spelling of "this object is a proven rail bank",
// and every consumer of the second half asks it by CALLING this (Rule 14).
//
// ⚠ IT DOES NOT RESURRECT THE RETIRED CLAUSE **B9** (`RailBankPromote.h`'s
// note above, merge filing F-9). B9 read *"NOT ALREADY PROMOTED
// (`isRailBankAlloca` — the `!cq.railbank` record this stage MINTS)"* and was
// retired as false: the promoter mints nothing and **B8** is what terminates
// its fixpoint. The mint is back; the GUARD is not, and must not come back — a
// membership guard on the promoter's fixpoint would MASK a B8 regression that
// otherwise does not terminate. The mint happens AFTER the promoter's fixpoint
// has already settled, so the promoter never sees it.
bool isRailBankAlloca(const llvm::AllocaInst *AI);

// The bank's **RAIL** type, read back out of that record — NOT its cell type,
// and the two differ for exactly the owner's spelling: a `_Bool` cell's C
// storage type is `i8` while the rail is `i1`.
//
// ⚠ IT IS RECORDED RATHER THAN RE-DERIVED BECAUSE IT BECOMES UNRECOVERABLE.
// After `lowerRotations`' cross-type RAUW the store's storage-extension cast
// reads `zext i32 %h to i8` and its original source type is gone, so the type
// rewrite could not compute it even though it needs it.
//
// ⚠ AND IT IS LOAD-BEARING AGAINST A MEASURED OVER-ACCEPT, not bookkeeping: a
// cast to any width OTHER than the rail's is a cast the USER wrote, whose
// register spelling emits a real `cq_template_{trunc,zext}_*` GATE minting a
// NEW rail. Without the width conjunct, `int b0[3]` with
// `cq_measure((short) b0[i])` minted `cqrt_alloc_i32` and measured
// `cqrt_measure_i16` — the gate DROPPED (`trackB/probes/d5g` vs the
// array-free scalar twin `d5h`, which emits it on this binary and on the
// ORACLE). Returns null if the record is absent or malformed, and every caller
// treats null as a refusal.
llvm::Type *railBankRailType(const llvm::AllocaInst *AI);

// The proven rail bank `P` points into, or null. `getUnderlyingObject` is
// LLVM's own machinery (Rule 14, the "ask LLVM" move) and stops at a `phi` /
// `select` / `inttoptr`, which is the conservative direction. The answer is
// only ever non-null for an alloca `markRailBankAllocas` proved, and clause C1
// of the carve is what makes that proof alloca-WIDE: every user of a `Bank`
// alloca is a canonical cell access, a lifetime marker or the initializer, so
// "points into the object" and "is a canonical cell address" coincide.
llvm::AllocaInst *railBankOfPointer(llvm::Value *P);

// Is `H` stored into a cell of a proven rail bank? The D1/D6 FREEZE predicate:
// a rail whose value is parked in a bank cell is owned by the bank, so the
// whole-DAG spine must neither adjoint nor free it (Rule 6 — it is left
// allocated, deliberately).
//
// ⚠ DEMAND-DRIVEN AND STRUCTURAL, never a `Value *`-keyed owner set: that
// spelling is recorded in `TaintPropagation.h` as a shipped silent miscompile
// (a set keyed on a pre-`lowerOps` SSA value the lowering then erases).
bool railStoredToRailBank(const llvm::Value *H);

// Mint `!cq.railbank` on every alloca whose store the carve calls `Bank`.
// Returns true iff anything was newly marked; the caller then re-`propagate`s,
// which is what makes piece 1 fire and what discharges L1 (the taint-GROWTH
// species) STRUCTURALLY rather than by a record.
//
// ⚠ THE CARVE ITSELF STAYS A PURE PREDICATE (`QramLowering.h`'s SECOND
// RETIREMENT TRIGGER). This stage is the one that mutates, and all it mutates
// is metadata on an `AllocaInst`; the verdict is unchanged and is still re-asked
// at the round-2 fixpoint through `declineTaintEscapes`.
bool markRailBankAllocas(llvm::Module &M, const TaintSet &taint);

// PIECE 2 — rewrite a proven bank's cells to RUNTIME HANDLES: `[N x cell]` →
// `[N x i32]` (Rule 15: a handle is ALWAYS `i32`, at every width), every cell
// address gep retyped, every cell load retyped to `i32`, every storage
// extension/truncation cast erased.
//
// ⚠ THE SLOT IS BETWEEN `lowerRotations` AND `lowerOps`, AND BOTH BOUNDS ARE
// LOAD-BEARING. Above `lowerRotations` the store's value is still the
// `@cq_theta` call and there is no handle to store. Below `lowerOps` the
// storage cast has already become `cq_template_zext_i1_to_i8` — A SECOND,
// ENTANGLED RAIL per cell, with the original left allocated (measured:
// `probes/b09_bool_zext_to_int.c` → `cq_template_zext_i1_to_i32(h0) -> h1`).
//
// ⚠ AND IT IS INVISIBLE TO THE VERIFIER. After `lowerRotations`,
// `store i32 %h, ptr %cell` into a `[3 x i8]` alloca is WELL-TYPED — opaque
// pointers give a `store` no pointee constraint — so a 4-byte write into a
// 3-byte object is `opt -verify` CLEAN. Retyping the object is semantically
// load-bearing and the verifier cannot witness it: Rule 2's exact shape.
void rewriteRailBankCellTypes(llvm::Module &M, TaintSet &taint);

// PIECE 3 — the D5 POSITIVE allow-list. Every reader of a rail-bank cell load
// that is not one of
//   (1) a `@cq_measure_<sfx>` call taking the load as its operand,
//   (2) that load's storage-TRUNCATION cast, single-use, whose one user is (1),
// is a LOUD decline. (`SCOPE_B.md` §5.1 designed a THIRD entry — a further store
// into a rail-bank cell — and it was removed after being measured to have no
// reachable subject at the `-O1` floor; the argument and its retirement trigger
// are at the definition.) ⚠ It is an allow-list and NEVER a deny-list: the fences
// that would otherwise adjudicate these consumers are all SSA-shaped and go
// SILENT on a memory-resident wire (`SCOPE_B.md` §4.4) — `hasTaintedCondBranch`
// is blind to a memory-resident branch condition, and `railWireClosure` has no
// memory hop (and must not be taught one: that trips
// `f2SeedPinnedByLiveRegister`'s retirement trigger and forces a from-scratch
// re-derivation of the F2 narrowing). The refusal happens HERE instead.
//
// ⚠ ENTRY (2) IS LOAD-BEARING AND EASY TO MISS: at D5 time piece 2 has NOT run,
// so the `trunc i8 → i1` the C storage type forces is still standing.
void declineUnallowedRailBankReaders(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_RAILBANKPROMOTE_H
