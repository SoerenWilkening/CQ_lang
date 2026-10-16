// SpecializeConsume.h — the CONSUMING CLONE: in place across a lifted call
// (bd test_C_libtooling-r2j3.37.1; owner-ruling-r2j3-37-lower-it-2026-10-16;
// the design of record is the bd issue).
//
// A lifted call is a Bennett embedding |t>|a>|0> -> |t>|a>|f(t,a)>, so
// `r = f(t, a)` with `t` DEAD after the call left the old `t` rail beside `r`
// (r2j3.37). When `f`'s return chain (SpecializeTailPlan.h) is LINEAR in `t`
// — `t` appears once, and every xor/add/sub on the path from the returned value
// down to `t` has `t` in a slot the in-place gates overwrite (xor/add either,
// sub the minuend) — the call can instead be ONE call to a consuming clone
//     call void @__cq_q_f_<mask>_c<k>(args...)      (k = t's slot)
// which maps |t>|a> -> |f(t,a)>|a> on `t`'s own rail; `r` is then `t`'s handle.
// The site stays one call (R14: lifted, not inlined).
//
// THE BODY. For each op on the path, inner to outer, the op's OTHER operand is
// its SOURCE: a parameter (passed through), a constant, or a SOURCE CLONE — a
// copy of `f` returning that operand, lifted by the specializer like any callee
// (its own Bennett embedding |args>|0> -> |args>|s>). The op itself is the gate
// the in-place rounds mint: a quantum source -> `wd.qqInPlaceFn` (`cqrt_{xor,
// add,sub}_<W>`, i1 `cqrt_cnot`, tagged `!cq.inplace.qq`); a classical one ->
// `emitInPlaceImmediateGate` (`cqrt_{addc,xorc}_<W>`). Every minted source is
// then uncomputed by its clone's twin (`emitInverseCall`, the clone-call
// recipe) and freed, in reverse. Sound because no source reads `t` (each source
// clone's own dead-slot record has `t`'s slot dead; otherwise the op is
// self-dependent and fails loudly): the in-place group is a basis permutation
// of `t` controlled by values that are restored, Bennett.jl's exclusive-reader
// construction (src/lowering/operand.jl:182-221 @824458d1; the in-place group
// is reversed before the target's defining group). The twin `..._c<k>_unc` is
// the same sources around the in-place gates' adjoints (`emitInverseCall`) in
// reverse order. Both carry `cq-consume-dst`=k (`isConsumingCloneCall`).
//
// WHEN. `buildConsumingCandidates` runs in `specialize()` on each top-level lift
// site the gate tags (SpecializeTailHoist.h), after the site is retargeted, and
// builds one candidate per handle slot of the chain (the slot that is consumed
// is decided late), appending each to the site's `!cq.lift.tail.owed` tag as
// `!{i32 k, i32 reason, ptr consumer-or-null}`. The DECISION is the in-place
// round's (`lowerConsumingLiftedCalls`, InPlaceQQConsume.cpp), on lowered IR,
// with the inlined twin's predicates.
#ifndef CQ_IRPASS_SPECIALIZE_CONSUME_H_
#define CQ_IRPASS_SPECIALIZE_CONSUME_H_

#include "SpecializePlan.h"

#include "llvm/ADT/STLFunctionalExtras.h"

namespace llvm {
class CallInst;
class Function;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// Why a candidate slot cannot be consumed (the loud message the late round
// gives when the slot is the one the inlined twin would overwrite).
enum class ConsumeReason : unsigned {
  Ok = 0,
  SelfDependent = 1,  // kMsgInPlaceQQSelfDependent
  NotInPlace = 2,     // kMsgInPlaceQQRefused (subtrahend; no in-place symbol)
  Unsupported = 3,    // kMsgLiftTailUnhoisted (a chain shape not built)
};

// Every function this builds (consumers, twins, sources, source clones) carries
// this attribute; the late round erases each one left without a use.
inline constexpr const char kConsumeAuxAttr[] = "cq-consume-aux";

using ConsumeResolveFn =
    llvm::function_ref<SpecRecord(llvm::CallInst *&, llvm::Function *, SpecMask)>;
using ConsumeTwinFn = llvm::function_ref<void(llvm::Function *, SpecMask)>;

// Mint the gates of a consumer `C` and its twin from the steps recorded at build
// (idempotent). False if a gate has no in-place symbol at the width.
bool materializeConsumer(llvm::Function &C, const TaintSet &taint,
                         WidthDispatch &wd);

void buildConsumingCandidates(llvm::CallInst &Site, llvm::Function *OrigCallee,
                              TaintSet &taint, WidthDispatch &wd,
                              ConsumeResolveFn Resolve, ConsumeTwinFn EnsureTwin);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_CONSUME_H_
