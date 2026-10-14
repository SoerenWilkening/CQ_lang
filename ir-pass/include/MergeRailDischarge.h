// MergeRailDischarge.h — reverse a dead controlled-copy MERGE rail by replaying
// its copy core in reverse (bd test_C_libtooling-r2j3.32, a P1 verify-clean
// silent miscompile).
//
// THE HOLE. A Phase-4 merge emitter (the 4.4 `SelectMergeEmit` is the measured
// customer; the 6.5 classical-call arm and the PredMux value merges emit the
// same stream) mints `%out = cqrt_alloc_<W>(0)`, writes it ONLY through
// `cqrt_copy_<W>_controlled(f, src, %out)` under a condition network it mints
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
// adjoint of the mux is the mux reversed). The merge stream is
//     [mint: flag network] [CORE: copies into %out under the flag, `cqrt_x`
//     brackets, classical source loads] [STRIP: flag network undone, freed]
// The CORE is an involution on %out — its copies are transversal-CNOT XORs
// (runtime/cq_runtime.h) acting on complementary branches of the flag, and its
// brackets balance — and it changes no rail but %out. So, right after %out's
// last reader:
//   1. the adjoint of any in-place basis permutation on %out after the merge
//      (the M-C `cqrt_addc_<W>` reassignment), through `EmitInverse` (R12);
//   2. the CORE re-emitted in reverse order, under the SAME flag rails;
//   3. the stream's own STRIP, MOVED here — the flag rails stay allocated and
//      untouched across the window instead of being re-minted;
//   4. `cqrt_free(%out)`: %out is back to its born |0⟩ (Rules 5/6).
// Re-using the forward flags keeps every pair checkable by stage 2b's
// adjoint-pair reduction (same control register, held still).
//
// WHEN THE PROOF HOLDS — and otherwise %out stays allocated, exactly the
// pre-fix disposition (a Rule-6 leak, never a dirty free, never a new decline):
//   * %out born |0⟩ (`railBornZero`), never parked in a rail bank;
//   * every user of %out is a call on the merge block's STRAIGHT-LINE CHAIN
//     (the block, then each unconditional-`br` successor whose only
//     predecessor is the previous link — the flattened `br label %merge`
//     shape): a controlled copy INTO it (the core, in the merge's own block),
//     an admitted in-place permutation with constant operands, or a pure READ
//     (`onlyReads`) after the stream — no measure, tape, copy-out, `ret`, φ,
//     store or clone call;
//   * the stream closes: every rail it writes it minted, every rail it mints
//     (but %out and its classical source loads) it frees, all inside it, and
//     nothing foreign sits inside it (`streamGateWrites` is the allowlist);
//   * in the window between the stream and the replay point, every register
//     the stream reads (flag-network controls, compare operands, copy sources)
//     is touched only by pure reads and is never stored to memory.
// One straight-line chain ⇒ the replay runs exactly once per forward run and
// nothing off the chain runs in between (the degenerate case of the FreePoint
// post-dominator discipline: the replay point post-dominates the stream and the
// stream dominates it, with no repeat edge between them).
//
// Runs per function AFTER every uncompute partition (so the spine's adjoints of
// %out's readers already exist and are counted as readers), in REVERSE program
// order (an outer merge reading an inner one's rail as a copy source is undone
// first: LIFO). Every call it emits is recorded in `taint.SpineOps`
// (EmitInverse.h: an unrecorded self-inverse gate reads as a user data use to
// the M-A guards).

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
