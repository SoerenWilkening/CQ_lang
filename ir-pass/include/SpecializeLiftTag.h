// SpecializeLiftTag.h — the lift-site record the in-place question across a
// lifted call is decided from (bd test_C_libtooling-r2j3.37 / r2j3.37.1).
//
// A lifted call is a Bennett embedding |x>|y>|0> -> |x>|y>|f(x,y)>, so
// `r = f(t, a)` with `t` a DEAD user register beside a kept result would leave
// the old `t` rail standing (r2j3.37, the r2j3.33 hazard through a call). The
// consuming clone (SpecializeConsume.h) lowers it in place as one call; the
// decision is the in-place round's (InPlaceQQConsume.cpp).
//
// THE TAG. `specialize()` tags each top-level lift site whose callee's return
// reaches a parameter through the in-place family (`chainReachSlots`,
// SpecializeTailPlan.h — a property of the SITE, whether or not a plan exists):
//     !cq.lift.tail.owed !{i64 Chain, !{i32 k, i32 reason, ptr consumer}...}
// one entry per consumer candidate `buildConsumingCandidates` built. A slot in
// Chain that the late round finds owed (dead user register, kept result) with no
// buildable candidate fails loudly with `kMsgLiftTailUnhoisted` (R1: never the
// old rail left standing). Only `specialize()` writes the tag, and only the
// consuming-clone builder writes `cq-consume-dst` / `cq-consume-aux`: input IR
// carrying either is stripped at pass entry (`stripForgedConsumeMarks`, the bd
// r2j3.22 forged-tag lesson).
//
// HISTORY. The batch-055 first answer, a return-chain HOIST into the caller
// (`SpecializeTailHoist`), crossed owner-ruling-lift-classical-only-2026-10-06 /
// R14 ("lifted, not inlined") and was deleted when the owner ruled (b), the
// consuming clone (owner-ruling-r2j3-37-lower-it-2026-10-16).
#ifndef CQ_IRPASS_SPECIALIZE_LIFT_TAG_H_
#define CQ_IRPASS_SPECIALIZE_LIFT_TAG_H_

namespace llvm {
class CallInst;
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

inline constexpr const char kLiftTailOwedTag[] = "cq.lift.tail.owed";
void tagLiftSite(llvm::CallInst &CI, const TaintSet &taint);
void stripForgedConsumeMarks(llvm::Module &M);

extern const char kMsgLiftTailUnhoisted[];

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_LIFT_TAG_H_
