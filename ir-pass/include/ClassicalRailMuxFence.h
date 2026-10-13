// ClassicalRailMuxFence.h — bd dm7f.15 / dm7f.16: the pure-analysis half of the
// classical-condition rail router (ClassicalRailMux.h carries the lowering and
// the soundness argument). Split out only for the 400-line file budget; the one
// customer of everything here is `ClassicalRailMux.cpp`.

#ifndef CQ_IRPASS_CLASSICAL_RAIL_MUX_FENCE_H_
#define CQ_IRPASS_CLASSICAL_RAIL_MUX_FENCE_H_

#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The router SHAPE: a select on an UNTAINTED condition, or a phi whose every
// incoming block ends in a classical `br`/`switch` (`terminatorIsClassical`), that
// reads at least one tainted value, sits on no CFG cycle (`blockOnCycle`), is not
// a bd zujr promoted carried-handle phi, and has a type a classical arm can be
// materialized at (`isMuxableType` and a known ABI width).
bool isClassicalRailMuxShape(llvm::Instruction *I, const TaintSet &taint);

// The value operands a router chooses between (select arms / phi incomings).
llvm::SmallVector<llvm::Value *, 4> classicalRailMuxValues(llvm::Instruction *R);

// THE FENCE, the READ-ONLY CONTRACT, asked of a router-shaped `Mux` (pure
// analysis). The ROUTER CLOSURE is `Mux` plus every router-shaped operand,
// recursively; its LEAVES are the tainted non-router operands (instructions off
// every cycle, never a load or an argument). The ALIAS SET is the closure plus
// each leaf's wire names (the leaf and its chained-`cq_theta` arg-0 ancestry, the
// relation `lowerRotations` builds one rail from). True iff
//   (R1) no non-diagonal gate on any leaf wire (`findNonDiagonalWireGate`,
//        position-free, `CrossValueRouting` — so it walks THROUGH every router and
//        a rotation of the router itself counts) and no loop-owned in-place rail
//        op (`InPlaceRailOps`) reads a leaf or a router over it;
//   (R2) every user of every router READS it: a call, a still-unlowered tainted
//        op (it lowers to a template that reads it), a `ret`, or a further
//        router-shaped select/phi choosing it as a VALUE;
//   (R3) no measurement of an alias-set member can reach a non-measure read of
//        one (a measurement collapses the shared rail; measuring twice is fine);
//   (R4) no emitted gate WRITES a member: a gate whose `railOf` (ChainWalk) is the
//        member, a park `cqrt_cswap`, or a copy into it.
bool classicalRailMuxFenceHolds(llvm::Instruction *Mux, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CLASSICAL_RAIL_MUX_FENCE_H_
