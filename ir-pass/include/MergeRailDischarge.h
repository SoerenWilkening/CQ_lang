// MergeRailDischarge.h — reverse a dead controlled-copy MERGE rail by replaying
// its copy core in reverse (bd test_C_libtooling-r2j3.32, a P1 verify-clean
// silent miscompile).
//
// THE HOLE. A Phase-4 merge emitter (the 4.4 `SelectMergeEmit` is the measured
// customer; the 6.5 classical-call arm and the PredMux value merges emit the
// same stream) mints `%out = cqrt_alloc_<W>(0)`, writes it ONLY through
// `cqrt_copy_<W>_controlled(f, src, %out)` — or, for a classical arm since bd
// dm7f.81, `cqrt_xorc_<W>_controlled(f, %out, imm)` — under a condition network it mints
// and strips in the same stream, and records `%out` in `ControlOwnedRails`
// (DD-4). Every uncompute partition subtracts that set, so nobody ever reversed
// `%out`. After its readers ran (or were themselves reversed) `%out` stayed
// allocated holding a CNOT record of the condition registers, and a later
// non-diagonal gate on one of them (p18: `cq_theta(&a, -.5)` after
// `int s = 2*a + b`) rotated a register entangled with that record — `opt`
// rc 0, stage 2b clean.
//
// THE MECHANISM (Bennett.jl `bennett_transform.jl:365-377`: the forward gates,
// the copy-out, then the SAME gates replayed in reverse while the inputs are
// still live; its mux `lowering/arith.jl:616-626` is CNOT/Toffoli only, so the
// adjoint of the mux is the mux reversed). A merge stream (`MergeStreamPlan`)
// is a CLOSED range [Lo, Hi] around %out's writers in which every value
// written is minted, every minted value but %out is NET (freed exactly once in
// range) or KEPT (never freed, only read; since dm7f.81 a classical arm is a
// literal, not a kept rail), and its CORE (first..last write of %out plus the
// `cqrt_x` brackets that open or close it) holds a REPLAY subsequence S = every
// write of %out and every `cqrt_x` on a network flag. S's writes are XORs
// (runtime/cq_runtime.h: transversal-CNOT copies, controlled xor-immediates, the
// 4.5 switch-value preload `cqrt_copy_<W>`) and
// nothing else in the core writes a value an earlier S gate read, so S
// reversed, run where S's inputs are unchanged, is S's adjoint. Right after
// %out's last reader, `emitReplay` emits:
//   1. the adjoint of any in-place basis permutation on %out after the merge
//      (the M-C `cqrt_addc_<W>` reassignment), through `EmitInverse` (R12);
//   2. S re-emitted in reverse order, under the SAME flag rails;
//   3. the stream's own STRIP (everything after the core), MOVED here — the
//      flag rails stay allocated and untouched across the window;
//   4. for a SEEDED rail (the 4.5 data-mux preload `cqrt_alloc_<W>(v_d)`, a
//      Constant or classical caller Argument), `cqrt_xorc_<W>(%out, v_d)`;
//   5. `cqrt_free(%out)`: %out is back to |0⟩ (Rules 5/6).
// Re-using the forward flags keeps every pair checkable by stage 2b's
// adjoint-pair reduction (rule A3 admits the classical xorc residue).
//
// WHEN THE PROOF HOLDS — and otherwise %out stays allocated, exactly the
// pre-fix disposition (a Rule-6 leak, never a dirty free, never a new decline):
//   * %out born |0⟩ or seeded as above;
//   * its writers are in the merge block; every other user is a pure READ
//     (`onlyReads`, which admits slot 0 of a `_controlled` gate: Dicke's CCRy
//     reads a merge flag as a control) or an admitted in-place permutation in
//     the stream's block or the replay block — no measure, tape, copy-out,
//     `ret`, φ, store or clone call;
//   * the REGION: the replay block PB is the nearest common post-dominator of
//     the stream's block and its readers' blocks, and the blocks between them
//     form a single-entry region that reaches PB on every path without taking
//     the innermost loop's back edge or leaving the loop (`sese`). That is the
//     FreePoint post-dominator discipline in its exact form: the replay runs
//     exactly once per run of the stream — once per TRIP for an in-loop merge,
//     at the post-dominating join for a reader in a multi-pred block. A rail
//     read across a back edge (a loop-carried merge, the next trip's copy
//     source) has no such PB and stays allocated: its reversal is LIFO across
//     trips, a post-loop reverse loop not emitted yet;
//   * in the WINDOW (stream end .. replay point, over the region) every
//     register the stream reads is touched only by pure reads, through EVERY
//     alias of its handle: φ (minus a same-trip fresh mint that does not
//     dominate the φ), select, cast, freeze and the rail-bank park/reload hop;
//     any other memory hop refuses. `isRegister` fails closed: every operand
//     but a Constant or a classical caller Argument is a register.
//
// Runs per function AFTER every uncompute partition (so the spine's adjoints of
// %out's readers already exist and are counted as readers), also for functions
// with no tainted producer, in reverse dominance order (an outer merge reading
// an inner one's rail as a copy source is undone first: LIFO; a reader inside
// an earlier replay group is passed by the whole group). Every call it emits is
// recorded in `taint.SpineOps` (EmitInverse.h: an unrecorded self-inverse gate
// reads as a user data use to the M-A guards).
//
// NOT A FULL DISENTANGLE (R9/L9). A template rail minted FROM %out before the
// reversal (a hoisted chain `add(%out, -3)`) is not reversed here: it stays
// allocated and entangled with the condition (the chain-final leak; r2j3.7 is
// its dead-op twin). Measured 2026-10-15 over the e2e goldens: 2421 such rails
// in 88 slices, 2417 feeding a measured result, 4 dead (the iwr7 QRAM-index
// `zext`, four libm erf goldens), none followed by a non-diagonal gate on a
// condition leaf.

#ifndef CQ_IRPASS_MERGE_RAIL_DISCHARGE_H_
#define CQ_IRPASS_MERGE_RAIL_DISCHARGE_H_

namespace llvm {
class Function;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// Reverse and free every dischargeable controlled-copy merge rail of `F`.
// Returns the number of rails discharged.
unsigned dischargeMergeRails(llvm::Function &F, TaintSet &taint,
                             WidthDispatch &wd);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_RAIL_DISCHARGE_H_
