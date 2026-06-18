// SpecializePlan.h — Shared data shapes for Phase 6 call-graph specialization
// (function lifting). The `ControlPlan.h` analog: nothing in the specializer
// concern (`SpecializeDetect` / `SpecializeReject` / `SpecializeClone` /
// `SpecializeSeed` / `BennettWrap` / `Specialization`) compiles without this
// vocabulary, so it is the gate for every other Phase-6 module (PRD §3.1,
// IMPLEMENTATION_PLAN §3.1 + DD-5).
//
// Phase 6 lifts a direct call to a VISIBLE, PURELY-CLASSICAL, NON-RECURSIVE body
// with ≥1 tainted argument into a quantum-reversible CLONE: at the site, compute
// the per-parameter taint MASK, look up `(callee, mask)` in the specialization
// cache, miss → clone + mangle `__cq_q_<callee>_<mask>` + internal linkage +
// seed taint on the tainted params + lower the clone to `cqrt_*`/`cq_template_*`
// + Bennett compute-copy-uncompute wrap, retarget via `setCalledFunction`
// (PRD §2.2/§2.8/§2.9, "Path 2 — clone-on-taint").
//
// Two pinned contracts shape these types (epic, IMPLEMENTATION_PLAN §1):
//   * C-Plan — decline-by-default. Detection (`detectSpecializations`) is a
//     PURE-ANALYSIS pre-pass that runs BEFORE `declineTaintEscapes`; ONLY
//     proven-Accept sites enter `SpecPlan.Pending` (plan membership ⇔ proven
//     specializable). The `TaintPropagation.cpp:418` taint-escape carve-out is
//     then a thin `shouldSpecialize` membership test — it never re-classifies.
//   * C-Taint — the clone's seeded taint is a DISJOINT `cloneTaint`, NEVER
//     unioned into the original module `taint`. That disjointness (not a
//     rail-ownership set) is what prevents the double-uncompute of a shared
//     prefix. Return-taint is the one bit re-marked into the ORIGINAL `taint`,
//     and only AFTER the clone is lowered (`SpecRecord.ReturnTainted`).
//
// DD-5 (mask / mangle / key), pinned char-for-char by the WI-2 fixtures:
//   * MASK — `uint64_t`, bit i = arg i tainted, LSB = param 0. Computed from
//     `taint.Tainted` membership at DETECTION (pre-RAUW; argument-only — return
//     taint is post-lowering and so is NOT in the key). `mask == 0` is not a
//     candidate and never reaches the cache key.
//   * MANGLE — `__cq_q_<callee>_<binary>`, `<binary>` zero-padded MSB-first to
//     `callee->arg_size()`, param 0 the RIGHTMOST char (so
//     `ipow(tainted, classical)` → `01` → `__cq_q_ipow_01`). Unpadded would
//     collide `0b001` and `0b1` both as "1" — distinct-arity clones aliased
//     under `llvm-link`.
//   * KEY — a TYPED `SpecKey{Function*, mask}` with a custom
//     `DenseMapInfo<SpecKey>` composing the stock `Function*` + `uint64_t`
//     infos. NOT the prototype's `Function*`-only key, which silently collapses
//     two distinct taint signatures of the same callee onto one clone (C7 — the
//     over-accept class). Arity is capped at `kSpecMaxArity` (64); a wider
//     callee loudly rejects (a 65th bit would truncate and alias two
//     signatures).
//
// Header-only (no paired `.cpp`): the structs + the `DenseMapInfo`
// specialization live here; `mangleSpecName` / `taintArgMask` are DECLARED here
// and DEFINED in the specializer `.cpp` modules (WI-2), exactly as
// `ControlPlan.h` declares `detectControlRegions` whose body lives in
// `ControlDetect.cpp`.

#ifndef CQ_IRPASS_SPECIALIZE_PLAN_H_
#define CQ_IRPASS_SPECIALIZE_PLAN_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseMapInfo.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

#include <cstdint>
#include <string>

namespace llvm {
class CallInst;
class Function;
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The per-parameter taint signature: bit i set ⇔ argument i is tainted,
// LSB = param 0 (DD-5). A plain `uint64_t` keeps the cache key trivially
// hashable; the 64-bit width is exactly the `kSpecMaxArity` cap.
using SpecMask = uint64_t;

// Hard cap on `callee->arg_size()` for a specialization candidate. A 64-bit
// `SpecMask` holds one bit per parameter; a 65th parameter would truncate and
// silently alias two distinct signatures (the over-accept class), so a wider
// callee is a LOUD reject (WI-2.3), never a masked-to-64 accept.
static constexpr unsigned kSpecMaxArity = 64;

// The specialization cache / dedup key: a clone is unique per `(callee, mask)`
// (PRD §2.8/§2.9). TYPED (not the prototype's `Function*`-only key) so two
// distinct taint signatures of the same callee never collapse onto one clone
// (C7). Return-taint is deliberately ABSENT from the key — it is unknown until
// the clone is lowered (recorded later in `SpecRecord`).
struct SpecKey {
  llvm::Function *Callee = nullptr;
  SpecMask Mask = 0;
};

// One proven-Accept specialization site, recovered by `detectSpecializations`
// (pure analysis, SSA identity). `Site` is the direct `CallInst` to retarget;
// `Callee` its resolved `getCalledFunction()`; `Mask` the §2.2 taint signature.
struct SpecCandidate {
  llvm::CallInst *Site = nullptr;
  llvm::Function *Callee = nullptr;
  SpecMask Mask = 0;
};

// The cache entry for a `(callee, mask)`: the lowered `Clone` and whether its
// return value carries taint. `ReturnTainted` is filled POST-lowering (§2.7);
// `specialize()` reads it to decide whether to re-mark each retargeted call
// result into the ORIGINAL module `taint.Tainted` (C-Taint). It is NOT part of
// `SpecKey` — it cannot be known at detection time, when the key is formed.
struct SpecRecord {
  llvm::Function *Clone = nullptr;
  bool ReturnTainted = false;
};

}  // namespace cq

namespace llvm {

// Compose the stock `Function*` and `uint64_t` infos (the `std::pair` idiom,
// `DenseMapInfo.h`). The empty / tombstone sentinels are the stock `Function*`
// empty / tombstone pointers (which name no real function) paired with the
// `uint64_t` sentinels; since a real key never has an empty/tombstone callee
// (and never `mask == 0`), no candidate can collide with a sentinel.
template <>
struct DenseMapInfo<cq::SpecKey> {
  using FnInfo = DenseMapInfo<Function *>;
  using MaskInfo = DenseMapInfo<cq::SpecMask>;

  static inline cq::SpecKey getEmptyKey() {
    return {FnInfo::getEmptyKey(), MaskInfo::getEmptyKey()};
  }
  static inline cq::SpecKey getTombstoneKey() {
    return {FnInfo::getTombstoneKey(), MaskInfo::getTombstoneKey()};
  }
  static unsigned getHashValue(const cq::SpecKey &K) {
    return detail::combineHashValue(FnInfo::getHashValue(K.Callee),
                                    MaskInfo::getHashValue(K.Mask));
  }
  static bool isEqual(const cq::SpecKey &L, const cq::SpecKey &R) {
    return FnInfo::isEqual(L.Callee, R.Callee) &&
           MaskInfo::isEqual(L.Mask, R.Mask);
  }
};

}  // namespace llvm

namespace cq {

// The whole specialization plan, threaded through the pipeline (the
// `ControlPlan` analog). `Pending` is the proven-Accept worklist
// `detectSpecializations` populates and `specialize()` drains (C-Plan:
// membership ⇔ proven specializable); `Cache` dedups clones by `(callee, mask)`
// across sites AND across the transitive worklist (a clone re-scanned for inner
// tainted-arg calls reuses an existing entry rather than re-cloning).
//
// Defined AFTER `DenseMapInfo<SpecKey>` above: the `DenseMap<SpecKey, …>` member
// instantiates the trait, so the specialization must already be visible.
struct SpecPlan {
  llvm::SmallVector<SpecCandidate, 4> Pending;
  llvm::DenseMap<SpecKey, SpecRecord> Cache;

  // Call sites that `detectSpecializations` already LOUDLY declined with a
  // specialization-specific message (a `cq_*` body, a measurement, in-body
  // tainted control, recursion, an fp/i128 ABI, an over-wide arity — every
  // shape that passed the direct-`CallInst` + non-null + `!isDeclaration()`
  // SHAPE filter yet failed `classifyCandidate`). The `:419` carve-out
  // suppresses its generic `kMsgUnknownCallee` for these too, so a classified
  // reject renders exactly ONE diagnostic (its precise specialization message),
  // not a confusing pair. A SHAPE reject (declaration-only / indirect / invoke /
  // callbr) is NEVER recorded here — it is "not a candidate", stays silent in
  // detection, and the carve-out fires `kMsgUnknownCallee` for it (DD-2, C6).
  llvm::SmallPtrSet<const llvm::CallInst *, 4> Diagnosed;
};

// `__cq_q_<callee>_<binary>` (DD-5): `<binary>` is `Mask` rendered MSB-first,
// zero-padded to `Callee->arg_size()`, param 0 the RIGHTMOST char. Defined in
// the specializer `.cpp` (WI-2). The padding is load-bearing — an unpadded mask
// aliases different-arity clones under `llvm-link`.
std::string mangleSpecName(const llvm::Function *Callee, SpecMask Mask);

// The §2.2 taint signature of a call site: bit i set ⇔ `Site->getArgOperand(i)`
// is in `taint.Tainted` (LSB = param 0). The helper does NO extra filtering — it
// is a pure membership test; the per-use arg-1-angle exclusion (Rule 3) is
// already reflected in `taint.Tainted` upstream (a value used ONLY as a rotation
// angle never entered the set). Defined in the specializer `.cpp` (WI-2); the
// `kSpecMaxArity` cap is enforced at its call site (a wider callee loudly rejects
// before masking).
SpecMask taintArgMask(const llvm::CallInst *Site, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_PLAN_H_
