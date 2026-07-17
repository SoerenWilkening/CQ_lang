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
// `promoteFp80Union` finishes what SROA will not (MULTI-BLOCK since Inc 3, bd
// 3vdz): it CANONICALIZES every union access onto a fresh promotable
// `alloca x86_fp80` — each `load iN @ off` becomes `load x86_fp80` +
// `bitcast -> i80` + `[lshr] + trunc [+ zext]` (padding read as 0); each LIVE
// integer field-insert store-back becomes `load x86_fp80` + `bitcast -> i80` +
// and-clear + `zext`/`shl`/`or` + `bitcast -> x86_fp80` + `store x86_fp80`
// (inserted bits landing at storage positions >= 80 drop into the modelled-zero
// padding); full-width fp80 stores/reloads retarget in place — then hands the
// fresh alloca to LLVM's own PromoteMemToReg to build the SSA. Merge phis are
// therefore `phi x86_fp80`, NEVER i80 (the i80 extract/insert stays local
// around each access by construction; a post-promotion `phi i80` scan
// LOUD-declines defensively). The original union memory is erased and a
// dominance CSE restores the one-bitcast-per-value relabel shape. The i80 ops
// lower as reversible relabels/permutations (the shipped and/lshr/or/shl/icmp/
// trunc/zext/bitcast i80 surface). This mirrors Bennett.jl (sroa/mem2reg
// preprocess + bitcast = identity relabel + arbitrary widths). Runs in the
// early rewrite zone (after foldVolatileConstGlobalLoads, before
// flattenPredMuxRegions) so PredMux and every downstream guard see a
// store/load-free region; the caller re-propagates.
//
// FENCE (§4.1, the central silent-miscompile guard): modelling padding as 0 is
// sound ONLY where no padding-derived bit can reach an observable. A per-bit
// padding-taint walk (see Fp80Union.cpp header) follows every straddle-read bit
// through the integer dataflow — masks clear, carries taint upward, field-insert
// landings below bit 80 taint the union content — and LOUD-declines
// (`kMsgFp80Padding`) if a diverged bit reaches an icmp/branch/call/return/fp80
// reload or any op the walk cannot model. An off-pattern union (escaping
// address, non-constant gep offset, integer-seeded pack, runtime-classical
// seed, off-grid width, ...) is left byte-untouched and falls to the existing
// kMsgStore decline. A classical (const-seed) union promotes to constant-folded
// loads (isnan(0.5L) -> dead branch).

#ifndef CQ_FP80UNION_H
#define CQ_FP80UNION_H

namespace llvm {
class Function;
class Module;
}

namespace cq {

struct TaintSet;

// Promote every provable x86_fp80 bit-pattern union in `M` (a quantum module —
// the caller's passthrough early-out guarantees this) whose seed is tainted or a
// constant. Returns true if any union was promoted (caller re-propagates). Emits
// the loud padding diagnostic for a matched-but-unsound union.
bool promoteFp80Union(llvm::Module &M, TaintSet &taint);

// bd adia (3c6m.55 Lever C): exported wrapper over the internal constant-cone/branch
// fold (ConstantFoldInstruction fixpoint + ConstantFoldTerminator +
// removeUnreachableBlocks). Semantics-preserving and taint-safe: it touches
// ONLY all-constant instructions, and a theta-derived value is never a
// Constant. PredMux runs it after each successful flatten so fold residues
// (a constant-operand compare materialized by a select-chain fold) collapse
// before the next claim's E6 walk reads the region. Callers must re-derive
// taint after a `true` return (blocks may have been erased).
bool foldConstantConesInFunction(llvm::Function &F);

}  // namespace cq

#endif  // CQ_FP80UNION_H
