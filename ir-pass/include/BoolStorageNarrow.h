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
//        `zext iN → iK`, the low-bit test `icmp ne P, 0` / `icmp eq P, 1`, or
//        (bd dm7f.77, design D1) a BOOLEAN COMPARE `icmp eq/ne P, O` with `O`
//        itself provably 0 or 1 — a member of the same web, a `zext i1`, or the
//        constant 0/1 — reads whose result is a function of bit 0 alone given
//        (W1). A Boolean compare becomes `xor i1 P', o` (`ne`) or its `xor
//        …, true` (`eq`): dicke.c's `q2 ^= q1` arrives as `icmp ne i8 %q1.phi,
//        (zext i1 %q2 to i8)`;
//   (W3) at least one member is TAINTED (classical code is left byte-untouched);
//   (W4) no member's block is on a CFG cycle (the in-loop carried-handle
//        machinery owns loop φ, and is not widened here — a decline there stays
//        the decline it was).
// Then each member `P` becomes an `i1` φ `P'` with incoming `zext X` ↦ `X`,
// constant `k` ↦ `i1 k`, member `Q` ↦ `Q'`; a `trunc P` or a low-bit test is
// replaced by `P'`, a `zext P to iK` by `zext P' to iK`, and a Boolean compare
// with `o` by its xor form (`P != O` ⇔ `P' ^ o` when both are 0 or 1). Under (W1)
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
class Module;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Narrow every qualifying web in `F`. Returns true if anything changed; appends
// every created value to `Seeds`.
bool narrowBoolStoragePhis(llvm::Function &F, TaintSet &taint,
                           llvm::SmallVectorImpl<llvm::Value *> &Seeds);

// bd dm7f.77 (dm7f.51 step 2) — the same rewrite over every function, run ONCE
// more in BOTH entry points after the loop pre-passes and before the pre-pass
// window's guards (`declineStaleTaintSet`, the specializer, the escape guard and
// the EARLY stale-record slot). Why there too: the early slot is the only one
// that PLACES a stale pure read before its staling gate (bd 57ch.3), and a
// Boolean compare this rewrite turns into an `i1` xor (D1) is such a read in
// dicke.c (`q3 ^= q1` scheduled after q1's controlled Ry). Narrowing only at the
// peel left that read to `adjudicateTaintDelta`, which declines without placing.
// Idempotent: the peel's later call finds nothing left. The caller re-propagates
// in full (`taint = propagate(M, wd)`), the pre-pass house rule.
// bd 01po.19 S5: it also rewrites, in a function with a `!cq.railwindow` handle
// array, every `icmp eq/ne (zext i1 X), (zext i1 Y)` reached from a cell read
// into `xor i1 X, Y` (`eq`: its negation) — the `_Bool` spelling of `q[i] ^=
// q[j]` (design §4 interface (a)); see `boolCompareXor`.
bool narrowBoolStorageModule(llvm::Module &M, TaintSet &taint);

// THE ONE SPELLING of "`V` is the `_Bool` compare form of an `i1` xor":
// `icmp eq/ne (zext i1 X), (zext i1 Y)`. Fills `X`, `Y` and `Negated` (`eq`).
// Asked by the S5 rewrite above and by the window's needs list (RailWindow.h).
bool boolCompareXor(const llvm::Value *V, llvm::Value *&X, llvm::Value *&Y,
                    bool &Negated);

}  // namespace cq

#endif  // CQ_IRPASS_BOOL_STORAGE_NARROW_H_
