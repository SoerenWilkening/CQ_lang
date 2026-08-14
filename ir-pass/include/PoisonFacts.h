//===- PoisonFacts.h - facts that hold only MODULO POISON -----------------===//
//
// bd s6ao. ONE question, asked by two consumers that must never drift apart
// (Rule 14): *is a known-bits fact about this value conditional on poison?*
//
// *** WHY THIS HEADER EXISTS AT ALL — READ BEFORE TOUCHING EITHER CONSUMER. ***
//
// `llvm::computeKnownBits` is a MODULO-POISON analysis. Its guarantee is "these
// bits hold, OR the value is poison". Most consumers want exactly that, because
// they are themselves allowed to assume poison-freedom. TWO consumers in this
// pass are NOT:
//
//   1. `qromIndexKnownInBounds` (QramLowering.cpp) proves a QROM index is in
//      bounds for a read the PredMux flatten SPECULATES onto EVERY BASIS STATE.
//      Its obligation is TOTAL. A bound that holds "unless poison" is a bound
//      that holds only on the paths the SOURCE executes — i.e. exactly the
//      originally-guarded path the speculation removes.
//   2. `coneDefinedAfterFlagDrop` (PredMuxFlatten.cpp) proves a poison-shielded
//      short-circuit may be canonicalized to a plain `and`/`or`, which OBSERVES
//      the shielded operand on basis states the original never did.
//
// `UseInstrInfo=false` closes only part of channel 1, and the part it closes is
// not the part anyone would guess. MEASURED against LLVM 19's
// `InstrInfoQuery` (SimplifyQuery.h:25-59), which wraps EXACTLY five accessors:
// `getMetadata`, `hasNoUnsignedWrap`, `hasNoSignedWrap`, `isExact`,
// `hasNoSignedZeros`. So `UseInstrInfo=false` gates `nuw`, `nsw`, `exact` and
// ALL metadata (including `!range`) — and NOTHING ELSE. It structurally cannot
// gate `nneg`, `disjoint`, or `CallBase::getRange()`, because there is no
// accessor for those on `InstrInfoQuery` at all. That asymmetry is invisible at
// the call site and cost this project a Rule-13 BLOCK.
//
// The channels below therefore need an EXPLICIT walk. They fall in three groups,
// and the third is the one that catches people out because it involves no
// annotation whatsoever:
//
//   (A) NOT gated by `UseInstrInfo`: `nneg` (zext/uitofp), `disjoint` (or), and
//       the `range(lo,hi)` RETURN/PARAM ATTRIBUTE. Note LLVM 19 MIGRATED call
//       `!range` metadata to the `range` attribute, so gating `UseInstrInfo`
//       closes the RETIRED spelling and leaves the CURRENT one open.
//   (B) INHERENT poison — an operation that is poison on some inputs with NO
//       flag to drop: an out-of-range or non-constant shift amount, `div`/`rem`
//       by a non-provably-nonzero divisor, `fptosi`/`fptoui`.
//   (C) A POISON-GENERATING IMMARG: `llvm.ctlz`/`cttz(x, is_zero_poison=true)`
//       and `llvm.abs(x, is_int_min_poison=true)`. This is an ORDINARY CALL
//       OPERAND, not an annotation, so no flag-stripping API touches it — and
//       Rule 15's width-only ABI DISCARDS it, so the emitted gate is byte-
//       identical whether it is `true` or `false`. The bound then describes a
//       value the circuit does not compute. This channel has a REAL C WITNESS:
//       `__builtin_ctzll` into a 64-entry lookup table, the single most
//       idiomatic bit-scan idiom, emitted a QROM read at index 64 of a 64-cell
//       table on the basis state `bits == 0`.
//
//===----------------------------------------------------------------------===//

#ifndef CQ_POISON_FACTS_H
#define CQ_POISON_FACTS_H

#include "llvm/IR/Instructions.h"

namespace cq {

// Can this call to a CURATED reversible intrinsic return poison?
//
// LIFTED VERBATIM out of `PredMuxFlatten.cpp`'s anonymous namespace (bd
// 3c6m.14.2 wrote it there; bd s6ao lifted it) so the shielded-cone definedness
// proof and the QROM bounds proof consume ONE answer and cannot drift — the same
// discipline, and the same reason, as the `LiteralIntegrity` lift.
//
// Only `ctlz`/`cttz`/`abs` carry a poison-generating immarg. Every OTHER member
// of the curated set is genuinely total: bswap/bitreverse/ctpop,
// smin/smax/umin/umax, the four `*_sat`, fshl/fshr (the rotate amount is taken
// modulo the width), and the p119 hardware fp survivors (which return NaN, never
// poison). `intrinsicStem` in IntrinsicLowering.cpp is the authoritative set —
// these lists are coupled with nothing mechanical holding them together, so
// re-read it when either moves.
//
// A null callee returns TRUE (refuse): an indirect call is unprovable.
bool curatedIntrinsicCanBePoison(const llvm::CallInst *CI);

// bd s6ao — must the caller REFUSE `RawIndex`'s in-bounds bound for a table of
// `Count` cells? True means refuse; the caller then falls back to a sound mask
// (pow2) or declines loudly. Both are safe; an accepted unmasked read is not.
//
// *** IT ASKS THE CONVERSE OF WHAT ITS NAME SUGGESTS, AND THAT IS THE DESIGN. ***
// It does NOT scan for poison-conditional facts. It computes the largest value
// the index can take using OPCODES AND CONSTANT OPERANDS ALONE — no annotation,
// no metadata, no attribute, no poison assumption — and refuses unless that
// fact-free bound is already below `Count`. Formally:
//
//     indexBoundIsPoisonConditional(V, N)  ==  NOT (unconditionalMax(V) < N)
//
// If a fact-free bound exists, every annotation in the cone is irrelevant BY
// CONSTRUCTION; if none exists, the answer is refuse regardless of which channel
// the missing fact would have arrived through. That is what makes the verdict
// independent of the ENUMERATION in the file comment above — and the enumeration
// is precisely what LLVM keeps moving (19 migrated call `!range` metadata to the
// `range` attribute mid-stream). A scan keyed on that list would have to be
// re-audited at every LLVM bump; this does not.
//
// AN EARLIER DRAFT DID SCAN FOR PRESENCE, and it was wrong in the expensive
// direction: `clang -O1` stamps `nneg` on `zext` routinely (49 corpus sites, none
// load-bearing, because the real bound is an `and` further down), so refusing on
// presence regressed nine committed libm goldens plus both spec-qram slices.
// Do not reintroduce a presence test.
//
// `Count` is the table's cell count and is used in exactly one place — the final
// `Max < Count` comparison. The walk itself is `Count`-independent; there is no
// early termination keyed on it.
//
// COST: the walk is ITERATIVE with a memo (see the implementation). Both
// properties are correctness requirements rather than optimisations — the
// recursive draft overflowed the stack on a 20,000-node cone and the crash
// PRE-EMPTED the loud decline, and an unmemoised draft was exponential on a DAG.
bool indexBoundIsPoisonConditional(const llvm::Value *RawIndex, uint64_t Count);

}  // namespace cq

#endif  // CQ_POISON_FACTS_H
