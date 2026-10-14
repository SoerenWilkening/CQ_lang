// RailBankUnroll.h — bd `test_C_libtooling-01po.19`: a quantum local array whose
// cells are addressed by a classical loop index, compiled by FULL UNROLLING of
// the constant-trip loops that index it, followed by LLVM's own scalar
// replacement (SROA) of the now constant-indexed array.
//
// ── THE POPULATION ───────────────────────────────────────────────────────────
//
// A rail bank (`RailBankPromote.h`, `QramLowering.h` clauses C1–C7) is the
// ROLLED lowering of ONE shape: one store site, one `{0,+,1}` walk that is not
// re-executed, every cell written once. Everything else that holds quantum data
// in a `bool q[N]` indexed by a classical loop variable declined at one of the
// rail-bank clauses or at the generic `kMsgStore`:
//
//   * several store sites (`q[m-1] ^= q[m-2]; if (q[m-1]) cq_theta(&q[m-2], …)`,
//     the general-N Dicke circuit) — `kMsgBankMultiStore`;
//   * a walk re-executed by an enclosing loop (`for i { for v { if (c == v)
//     cq_theta(&q[i], …) } … }`, CQ_FINDINGS F5) — `kMsgBankNested`;
//   * a straight-line store beside a walk (`cq_theta(&q[0], .5); for (i = 1..3)
//     if (q[i-1]) cq_theta(&q[i], …)`, p16) — the generic `kMsgStore`.
//
// None of these is physics-forbidden (NORTHSTAR goal 1). With a classical index,
// cell `k` is one definite register on every path, so the program is exactly the
// hand-unrolled scalar program the reporter wrote by hand.
//
// ── THE CONSTRUCTION ─────────────────────────────────────────────────────────
//
// When every loop that gives the array a VARIABLE index has a SCEV-proven
// constant MAX trip count, unroll completely every such loop that touches the
// array (outermost first, picked in INSTRUCTION order, never use-list order;
// LLVM's `UnrollLoop`, the `LoopUnrollPrepass` call sequence: loop-simplify,
// LCSSA, `Count == max trip`). When the exact trip is also constant the two are
// equal; when it is not (an early exit on a measured cell) the unproven exits
// stay conditional branches in every copy (review round 1, item 3). A
// variable index a later round can resolve (a loop whose bound another loop
// computes, review probe rv/p4) does not fail the round. A constant-index
// access inside a constant-trip loop is unrolled out too, because SROA would
// otherwise turn its cell into a loop-carried register that the hand-unrolled
// program does not have (F5's inner `for (v…) if (c == v) cq_theta(&q[i], …)`).
// A constant-index access in a loop WITHOUT a constant trip stays rolled and is
// promoted to a loop-carried register, the loop owner's input. Then run the
// stock scalar cleanup a hand-unrolled source would get at `clang -O1`
// (InstSimplify, SROA, EarlyCSE, InstCombine, SimplifyCFG). SROA splits the
// array into one SSA register per cell and promotes it. The function the rest
// of the pass sees is then plain SSA over scalar registers, an input class the
// existing pipeline already owns; nothing about memory survives for the
// memory-blind wire/uncompute machinery to misread.
//
// Why this is sound (the three questions bd 01po.19 asks):
//   * A store of a basis value into a cell (bd memory
//     `38t2-fp-cell-commits-to-basis-sound`) becomes the SSA definition of that
//     cell's register. A classical init store becomes a classical constant.
//   * A store of a tainted value into a cell that already holds a rail is an
//     SSA REBIND: the old value stays a live SSA value that every downstream
//     owner (M-C in-place reassignment, the uncompute spine, `FreePoint`)
//     tracks exactly as it tracks `x = f(x)` on a scalar. Nothing is
//     overwritten in the physical sense, so no live rail is dropped (R7) and
//     no rail is freed by this stage (R5): it mints no gate and frees nothing.
//   * Unrolling and SROA are semantics-preserving LLVM transforms; the result
//     equals `clang -O1` of the hand-unrolled source up to pass order.
//
// R12 ground truth: Bennett.jl lowers a bounded loop by unrolling it
// (`lower_loop!`, src/lowering/cfg.jl:707 at 824458d1) and dispatches a
// compile-time-constant array index to per-slot wires (`_pick_alloca_strategy`
// `idx isa ConstOperand && return :shadow`, src/lowering/memory.jl:154; the
// slot write `_lower_store_via_shadow!`, memory.jl:872, touches only that
// cell's W wires). BennettVM.jl gives a static alloca a compile-time cell
// index (`StackAlloca`, src/ir/stack_alloca.jl:1 at 23d28e64) and keeps a
// separate instruction for a runtime index (`VarGEP`, src/ir/array_index.jl).
// This stage is the composition of the two: unroll, then per-cell registers.
//
// ── WHAT STAYS LOUD ──────────────────────────────────────────────────────────
//
// A loop without a constant max trip count, a trip above `kMaxUnrollTrip`, a
// function that would grow past `kMaxFunctionInsts`, a tainted cell index (the
// QRAM axis, 7.5), an escaping or dynamically-sized array, or a shape SROA
// cannot fully promote is left BYTE-UNTOUCHED: the transformation runs on a
// clone of the function, and the clone's body is ADOPTED (spliced into the
// function, which takes the clone's DISubprogram) only if the array disappears
// completely. The trial IS the adoption: there is no second run to diverge, and
// `true` always means the function changed (review round 1, item 1).
// Those keep their existing rail-bank or generic decline; the rolled
// generalisation for a runtime trip count is the remaining gap.
//
// ── PRIORITY AND SLOT ────────────────────────────────────────────────────────
//
// PER ARRAY (review round 1, item 2): an array a tainted store into which the
// rail-bank verdict classifies `Bank` or `BankRaw` is owned by the rolled bank
// and is never a candidate, and the first trial unrolls no loop that stores
// into it (its walk). Only if that trial fails, because `-O1` fused the bank's
// walk with the candidate's, does a second trial unroll it, and then every
// bank whose walk it unrolled must be scalarized too (none is left half
// rolled). A function that calls a `returns_twice` function is not touched.
// The call sits at the
// tail of `promoteRailBankCells` (so it runs only when the promoter claimed
// nothing on this turn) and therefore inherits the promoter's slot and its L1
// argument verbatim: it runs inside the first normaliser fixpoint, above every
// stage that adjudicates consumers of tainted values, and its caller re-runs
// `propagate` from scratch after every change (`CQLoweringPass.cpp`, both entry
// points). Forwarding a stored tainted value to a load GROWS taint exactly as
// the promoter does; the slot is what makes that safe. RETIREMENT TRIGGER:
// moving the call out of `promoteRailBankCells`, or the promoter below a
// taint-consuming stage, owes `adjudicateTaintDelta`.
//
// ACCEPT-ONLY, ONE FUNCTION PER CALL. Pure analysis decides candidacy; the
// mutation happens on a clone and is adopted whole or discarded whole.

#ifndef CQ_IRPASS_RAILBANK_UNROLL_H_
#define CQ_IRPASS_RAILBANK_UNROLL_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Unroll and scalarize ONE function's quantum constant-trip-indexed local
// array(s). Returns true iff the module changed; the caller re-propagates.
bool unrollQuantumArrayWalks(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_RAILBANK_UNROLL_H_
