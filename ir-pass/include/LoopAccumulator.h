// LoopAccumulator.h — the SEEDED quantum accumulator: a loop-carried scalar
// register with a CLASSICAL seed, updated IN PLACE each trip by a quantum
// source (bd test_C_libtooling-01po.19.18, CQ_FINDINGS F5; 01po.19 design §4).
//
//     int c = 0;
//     for (i < N) { …reads of c…; if (q[i]) c = c + 1; }   // -O1: c + zext(q[i])
//
// `-O1` gives a tainted header phi `%c = phi [0, pre], [%c.next, latch]` with
// `%c.next = add %c, %src`, BOTH operands quantum. Until this file that was the
// X1 decline (`loop-carried tainted value crosses iterations`): the in-place
// vocabulary (`inPlaceValueRailOperand`, dtzb) admits one tainted operand only,
// and the Case-A collapse needs a `cq_theta` root mint, which a counter seeded
// by a classical constant does not have.
//
// THE LOWERING (Mogensen RSSA `x ⊕= f(y)` with a loop-carried block parameter:
// BennettVM.jl 23d28e6 `src/ir/arithmetic_assignment.jl:1-97` (modop set
// {xor, add, sub}, operand/target aliasing forbidden at `:79`) and
// `src/ir/ingest_phi.jl:1-40` (φ as block parameter); the in-place adder is
// Bennett.jl 824458d1 `src/adder.jl:96` `lower_add_cuccaro!`, which refuses an
// aliased operand pair at `:103`):
//   * the register is minted ONCE, `%h = cqrt_alloc_<W>(seed)` at the end of the
//     loop's single external entry block (a basis state: the seed is classical);
//   * each trip's QQ step becomes the void in-place gate
//     `cqrt_{add,sub,xor}_<W>(src, %h)` (`cqrt_cnot` at i1), tagged
//     `!cq.inplace.qq` exactly as dm7f.51's straight-line conversion tags it, so
//     the spine's existing relation (`isInPlaceQQGate`: slot 1 written, slot 0 a
//     borrowed reader) applies unchanged;
//   * the header phi then is the ordinary Case-A rail and the CALLER's collapse
//     (`tryCaseA` / `collapseRailPhisIn`) owns everything after the mint: the
//     Rule-8 fan-out guard, the record-liveness fence (`staleRailRecordRead`,
//     which sees the step as a gate through `inPlaceValueRailOperand`), the
//     marking, the RAUW and the renaming fixpoint. No second spelling of any of
//     them lives here.
//
// THE REGISTER IS PERSISTENT (R5). It is never freed: after the loop it holds
// `seed ⊕ Σ src_k`, which is user data entangled with the sources, not a
// provably-|0⟩ rail. Reversing it needs the post-loop reverse loop (bd 8h7d.20).
//
// RECOGNITION (pure analysis; `seededAccumulatorPhi`):
//   (A1) `P` is a tainted integer header phi of width ≤ 64 with an in-place QQ
//        symbol, exactly two incomings: the latch and ONE external edge.
//   (A2) the external incoming (the SEED) is classical, not undef/poison, and
//        available at the entry block's terminator (the mint point).
//   (A3) the latch incoming walks back to `P` through in-place steps only: the
//        caller's `Step` (rotations, classical-immediate add/xor), or a QQ STEP —
//        `add`/`xor` (either operand the rail) or `sub` (minuend only) whose
//        other operand, the SOURCE, is quantum and does not read the rail
//        (`accSourceReadsRail`; `c += c` is the aliased pair both references
//        refuse). At least one QQ step (otherwise the shape is not this kind).
//   (A4) every QQ step runs once per trip: its block is in `L` and in no
//        subloop of `L`.
//   (A5) the width is `i32`, the handle ABI width, so the RAUW onto the minted
//        handle is type-exact. A narrower/wider counter stays X1 (bd
//        01po.19.18 follow-up: the retype needs the promotion's P4 user gate).
#ifndef CQ_IRPASS_LOOP_ACCUMULATOR_H_
#define CQ_IRPASS_LOOP_ACCUMULATOR_H_

#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"

#include <optional>

namespace llvm {
class BasicBlock;
class Module;
class BinaryOperator;
class DominatorTree;
class Loop;
class PHINode;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

struct SeededAccumulator {
  llvm::PHINode *Phi = nullptr;
  llvm::Value *Seed = nullptr;
  llvm::BasicBlock *Entry = nullptr;  // the single external predecessor
  llvm::Value *Latch = nullptr;       // the latch incoming (the trip's result)
  const llvm::Loop *L = nullptr;
  // The QQ steps on the chain, with the operand index of the RAIL in each.
  llvm::SmallVector<std::pair<llvm::BinaryOperator *, unsigned>, 2> Steps;
};

// One in-place step of the caller's existing vocabulary (`peelInPlaceStep`):
// the rail parent of `V`, or null when `V` is not such a step.
using AccStepFn = llvm::function_ref<llvm::Value *(llvm::Value *)>;

// Pure analysis: is `P` a seeded accumulator of `L` (A1)-(A5)?
std::optional<SeededAccumulator>
seededAccumulatorPhi(llvm::PHINode &P, const llvm::Loop *L,
                     const TaintSet &taint, const llvm::DominatorTree &DT,
                     AccStepFn Step);

// The commit: record every QQ step (`taint.InPlaceQQRailOps` + its rail index,
// after which `inPlaceValueRailOperand` names the rail operand), mint the
// register at the entry block's terminator, and make it the phi's external
// incoming. Returns the mint, which is the rail's ROOT from here on (tainted,
// with its logical width and a birth slot), or null when no allocator exists
// for the width (nothing is mutated then).
// A guarded loop's exit φ that merges the seed on a bypass edge the mint
// dominates is renamed to the register there (the zero-trip path).
llvm::Value *commitSeededAccumulator(const SeededAccumulator &A,
                                     WidthDispatch &wd, TaintSet &taint,
                                     const llvm::DominatorTree &DT);

// `lowerOps`' emission of one recorded QQ step: `cqrt_{add,sub,xor}_<W>(src,
// rail)` (`cqrt_cnot` at i1) tagged `!cq.inplace.qq`, then `BO` is RAUW'd to the
// rail handle (the caller erases it). False (loud) when no symbol exists.
bool emitAccumulatorQQStep(llvm::BinaryOperator *BO, WidthDispatch &wd,
                           TaintSet &taint);

// THE DEAD-ACCUMULATOR POSTCONDITION (after `uncompute`, both entry points; see
// the .cpp): a register that is never read again after a non-diagonal gate on a
// rail its sources read, with no intervening trip, fails loudly — it is a dead
// record the spine cannot reverse yet (bd 8h7d.20). Returns true after
// diagnosing.
bool declineDeadAccumulatorMoves(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_LOOP_ACCUMULATOR_H_
