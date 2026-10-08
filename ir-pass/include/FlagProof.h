// FlagProof.h — bd dm7f.21: can an instruction CREATE poison from non-poison
// operands, once each poison-generating flag it carries is proven (or not) from
// facts about its OPERANDS?
//
// clang -O1 stamps flags that hold by construction: `uitofp nneg` on a popcount,
// `zext nneg` on an 8-bit ctlz, `trunc nuw nsw` / `shl nuw nsw` around a 64-bit
// popcount, `ctlz(x | 1, is_zero_poison=true)`. LLVM's own answer
// (`canCreateUndefOrPoison(I)`) counts every such flag as a poison source, so
// the hoist owners (the 6.5 poison dataflow, PredMux's strict total-call walk)
// declined ordinary C. This is the one place that asks the precise question.
//
// THE RULE THE PROOFS OBEY: never route an instruction's own flag through itself.
// `computeKnownBits(I)` on a `zext nneg` already assumes the sign bit is clear,
// so every proof asks about the OPERANDS, with `UseInstrInfo=false`, no context
// instruction, no dominator tree and no assumption cache (a dominating guard is
// exactly the source path the hoist removes). Operand facts are "hold, or the
// operand is poison": sound only for a caller that tracks every poison source in
// the operand cone, including an unproven `range` / `returned` attribute that
// `computeKnownBits` trusts even with `UseInstrInfo=false` (bd memory
// llvm19-attribute-facts-and-noundef-poison). Both callers do.
//
// A body with a CFG cycle gets no flag proof (`AllowProofs=false`): through a
// loop-carried PHI an operand's known bits can depend on the instruction itself.
#ifndef CQ_FLAG_PROOF_H
#define CQ_FLAG_PROOF_H

namespace llvm {
class Instruction;
}

namespace cq {

// Every poison-generating flag on `I` holds whenever its operands are not
// poison: nneg (zext/uitofp), nuw/nsw (add/sub/mul/shl/trunc), disjoint (or),
// exact (lshr/ashr). Anything else (fast-math flags, gep, udiv/sdiv exact) is
// unproven. The whitelist is checked by LLVM itself: the proven flags are
// cleared on a detached clone and `hasPoisonGeneratingFlags()` must be false.
bool poisonFlagsProven(const llvm::Instruction &I);

// Can `I` (a non-terminator; for a call, an intrinsic call) yield poison when
// none of its operands is poison? `canCreateUndefOrPoison(I, flags off)`,
// poison-generating metadata, and every unproven flag. For ctlz/cttz/abs the
// poison immarg is proven from a non-zero / non-INT_MIN operand, and LLVM's
// "no poison" for a NOUNDEF call (it counts that as UB) is never trusted
// (`curatedIntrinsicCanBePoison`). A call's own return attributes are the
// caller's question (`callSiteReturnHolds`), not this one.
bool createsPoison(const llvm::Instruction &I, bool AllowProofs);

}  // namespace cq

#endif  // CQ_FLAG_PROOF_H
