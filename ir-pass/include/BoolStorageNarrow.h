// BoolStorageNarrow.h — bd `test_C_libtooling-dm7f.53`: THE `_Bool` STORAGE-WIDTH
// φ NARROWING.
//
// An ACCEPT-ONLY IR-to-IR normalisation, run as the first step of
// `peelIndependentMergePhis` (so it runs immediately before EVERY
// `detectControlRegions` call, both rounds — the MergePhiPeel.h rule). It mints
// NO gate, emits NO runtime symbol and NEVER diagnoses.
//
// ── WHY IT EXISTS ────────────────────────────────────────────────────────────
//
// A C `_Bool` lives in memory as an `i8`. When `clang -O1` keeps one in a φ that
// crosses TWO diamonds (`bool t = 0; if (a) cq_theta(&t,.3); if (!a)
// cq_theta(&t,.7);`) it keeps the φ at the STORAGE width and brackets every i1
// use with casts: the arm becomes `%x = trunc i8 %phi to i1; %r = cq_theta_i1(%x,
// θ); %z = zext i1 %r to i8`, and the merge is `phi i8 [%z, arm], [%phi, pred]`.
// The in-place controlled-Ry clause (`inPlaceRotationArmTheta`) demands that the
// theta be the WHOLE arm and feed the merge φ directly, so the casts turned every
// such region into `value-arm swap-route` (docs/CQ_FINDINGS.md F3). With ONE
// diamond `-O1` emits the `i1` φ (`phi i1 [%r, arm], [false, pred]`) and the
// region has lowered since drbq Inc 4. The two programs differ only in how many
// times the variable is conditionally written.
//
// ── THE REWRITE AND WHY IT IS EXACT ─────────────────────────────────────────
//
// A WEB is a maximal set of same-typed integer φ (width > 1) connected by φ→φ
// incoming edges. It is narrowed to `i1` iff
//   (W1) every incoming of every member is a member, a `zext i1 → iN`, or the
//        constant 0 or 1 — so every member provably holds 0 or 1 on every path;
//   (W2) every user of every member is a member, a `trunc iN → i1`, a
//        `zext iN → iK`, or the low-bit test `icmp ne P, 0` / `icmp eq P, 1`
//        — reads whose result is a function of bit 0 alone given (W1);
//   (W3) at least one member is TAINTED (classical code is left byte-untouched);
//   (W4) no member's block is on a CFG cycle (the in-loop carried-handle
//        machinery owns loop φ, and is not widened here — a decline there stays
//        the decline it was).
// Then each member `P` becomes an `i1` φ `P'` with incoming `zext X` ↦ `X`,
// constant `k` ↦ `i1 k`, member `Q` ↦ `Q'`; a `trunc P` or a low-bit test is
// replaced by `P'` and a `zext P to iK` by `zext P' to iK`. Under (W1)
// `P ∈ {0,1}`, so `trunc P = (P != 0) = P'` and `zext P = zext P'`
// bit-for-bit, on every path: the rewrite
// is the identity on values and therefore on the unitary — it only removes
// cast TEMPLATES that would have copied a 1-bit register into an 8-bit rail
// (Bennett.jl `lower_cast!`, src/lowering/arith.jl:630, is that CNOT copy).
// The narrowed module is exactly the one `-O1` emits for the single-diamond
// spelling of the same program.
//
// Taint: a narrowed φ inherits its predecessor's membership, a new `zext` is
// tainted iff its operand is; erased values are dropped from `Tainted` before
// they die. Every value created is returned in `Seeds` for the caller's
// `propagateFromSeeds` (the MergePhiPeel taint-growth discipline, bd b6ap
// F-B6-1).

#ifndef CQ_IRPASS_BOOL_STORAGE_NARROW_H_
#define CQ_IRPASS_BOOL_STORAGE_NARROW_H_

#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Function;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Narrow every qualifying web in `F`. Returns true if anything changed; appends
// every created value to `Seeds`.
bool narrowBoolStoragePhis(llvm::Function &F, TaintSet &taint,
                           llvm::SmallVectorImpl<llvm::Value *> &Seeds);

}  // namespace cq

#endif  // CQ_IRPASS_BOOL_STORAGE_NARROW_H_
