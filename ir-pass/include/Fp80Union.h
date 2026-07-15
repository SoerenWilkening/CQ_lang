// Fp80Union.h — the x86_fp80 union-promotion peephole (bd 3c6m.51).
//
// The long-double (ld80) libm cells extract sign/exponent/mantissa from an
// x86_fp80 through the `union IEEEl2bits` bit-pattern type-pun:
//
//     %u   = alloca {x86_fp80}, align 16
//     store x86_fp80 %seed, ptr %u
//     %lo  = load i64, ptr %u                       ; offset 0  (bits [0,64))
//     %hi  = load i64, ptr (getelementptr i8, %u, 8) ; offset 8 (bits [64,128))
//     %e   = and i64 %hi, 32767                      ; masks bits >= 16 (padding)
//
// LLVM (even at -O3) cannot promote the offset-8 `load i64` to a register: it
// straddles the undefined padding bytes [10,16) of the 80-bit value in its
// padded 16-byte slot, so SROA correctly refuses to invent the value. The union
// therefore stays in MEMORY at CQ's -O1 floor and a tainted seed store declines
// at `declineTaintEscapes` (kMsgStore).
//
// `promoteFp80Union` finishes what SROA will not: it rewrites the union into
// register-resident form — `bitcast x86_fp80 %seed to i80` once, then each
// `load iN @ off` becomes `[lshr i80] + trunc i80 -> iN` (or `+ zext` for a word
// that straddles the padding, modelling the padding bits as 0) — and erases the
// store / dead masked store-backs / geps / lifetime markers / alloca. The i80
// ops lower as reversible relabels/permutations (the shipped and/lshr/icmp/trunc/
// bitcast i80 surface). This mirrors Bennett.jl (SROA-preprocess + bitcast=
// identity relabel + arbitrary widths). Runs in the early rewrite zone (after
// foldVolatileConstGlobalLoads, before flattenPredMuxRegions) so PredMux and
// every downstream guard see a store/load-free region; the caller re-propagates.
//
// FENCE (§4.1, the central silent-miscompile guard): modelling padding as 0 is
// sound ONLY where the body masks the padding bits off. If a padding-straddle
// word has a user that observes a padding bit unmasked, the peephole LOUD-declines
// (`kMsgFp80Padding`) rather than promote. An off-pattern union (escaping address,
// non-constant gep offset, live RMW store-back, multi-block accesses, ...) is left
// byte-untouched and falls to the existing kMsgStore decline. A classical (const-
// seed) union promotes to constant-folded loads (isnan(0.5L) -> dead branch).

#ifndef CQ_FP80UNION_H
#define CQ_FP80UNION_H

namespace llvm {
class Module;
}

namespace cq {

struct TaintSet;

// Promote every provable x86_fp80 bit-pattern union in `M` (a quantum module —
// the caller's passthrough early-out guarantees this) whose seed is tainted or a
// constant. Returns true if any union was promoted (caller re-propagates). Emits
// the loud padding diagnostic for a matched-but-unsound union.
bool promoteFp80Union(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_FP80UNION_H
