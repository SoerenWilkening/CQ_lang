// SpecializeReject.h — the single authoritative accept predicate for Phase 6
// call-graph specialization (function lifting), plus the `kMsg*` family the
// negative fixtures mirror char-for-char (Rule 12).
//
// `classifyCandidate` is the ONLY place a specialization candidate is
// adjudicated (Rule 14 — no parallel classifier). It is consulted by BOTH
// `detectSpecializations` (the pre-`:64`/`:154` pure-analysis pre-pass that
// fills `SpecPlan.Pending` with proven-Accept sites only — C-Plan) AND the
// `Specialization` driver. A candidate that classifies `Accept` is provably
// liftable; anything else returns a rejecting reason + the offending
// `Instruction*` (for the `!dbg` source location) and is LEFT OUT of the plan,
// so the `TaintPropagation.cpp:419` carve-out still fires `kMsgUnknownCallee`
// (decline-by-default).
//
// Accepted body set (the open Rule-13 item, IMPLEMENTATION_PLAN §8): a VISIBLE,
// PURELY-CLASSICAL, NON-RECURSIVE value function — no `cq_*` primitive, no
// measurement, in-body control only of the kinds the clone's PredMux flatten and
// main's control chain (bd p3kd.7.8) collapse to straight-line (`br`/`switch`/`unreachable`
// terminators, `phi`/`select` muxes; a shape they leave declines loudly at the
// clone, bd p3kd.7.1), no fp/i128/vector/half quantum ABI, no
// non-reversibilizable construct, every forward gate `isInverseEmittable`, and
// (bd 3p2a) a RETURNED VALUE that actually denotes a value — the whitelist scans
// instruction OPCODES and used to `continue` past every terminator, so a body of
// just `ret i32 poison` passed VACUOUSLY.

#ifndef CQ_IRPASS_SPECIALIZE_REJECT_H_
#define CQ_IRPASS_SPECIALIZE_REJECT_H_

#include "SpecializePlan.h"

#include "llvm/ADT/StringRef.h"

#include <string>

namespace llvm {
class Instruction;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// The reject reasons. `Accept` is the only specializable verdict; every other
// value names a proven-unliftable shape whose loud decline keeps the carve-out
// declining by default (Prime Directive). The `kMsg*` strings below pin the
// rendered diagnostic for each (the non-reversibilizable family embeds the
// construct kind so the negatives distinguish asm/atomic/volatile/EH/setjmp/
// vector/syscall).
enum class SpecReject {
  Accept,
  Recursion,
  FpAbi,
  QuantumPrimitive,
  Measurement,
  NonReversibilizable,
  InBodyControl,
  ArityOverflow,
  Interposable,
  UndefReturn,
};

// Pinned diagnostic strings (Rule 12; the negative fixtures mirror each
// char-for-char). `kMsgNonRevizPrefix` is completed with a `(<kind>)` suffix by
// `nonRevizKindMsg` so each construct-kind fixture mirrors its own message.
constexpr char kMsgRecursion[] =
    "cq specialization: recursive callee has no static depth bound";
constexpr char kMsgFpAbi[] =
    "cq specialization: floating-point quantum argument or return has no "
    "reversible copy";
constexpr char kMsgQuantumPrimitive[] =
    "cq specialization: callee contains a quantum primitive (cq_*); only "
    "classical functions are lifted";
constexpr char kMsgMeasurement[] =
    "cq specialization: callee measures under quantum lift";
constexpr char kMsgInBodyControl[] =
    "cq specialization: callee contains tainted control flow under quantum lift";
constexpr char kMsgArityOverflow[] =
    "cq specialization: callee arity exceeds the 64-parameter specialization "
    "mask limit";
// bd gxhi: a callee whose body the pass may not lift. Since bd p3kd.2 the
// question is `calleeBodyTrusted` (CalleeBody.h): the TOP callee of a candidate
// is refused only when INTERPOSABLE (weak/linkonce/common/extern_weak, or not
// dso_local under SemanticInterposition: the linker may bind an ARBITRARY body),
// while a weak_odr/linkonce_odr/available_externally top callee is lifted (its
// call runs the clone of the body analyzed). A NESTED callee must still be exact,
// because a nested call the clone does not taint runs the LINKED body, twice once
// the uncompute twin copies the clone (`scanBody` (0-pre)). The text is unchanged
// so the existing negatives keep mirroring it.
constexpr char kMsgInterposable[] =
    "cq specialization: callee has a non-link-exact definition "
    "(interposable/derefinable linkage); the linker may bind a different body";
// bd 3p2a: a callee whose RETURNED VALUE is derived from a literal
// `undef`/`poison`, so it computes no function of its arguments at all. See
// `returnDerivesFromUndef` (SpecializeReject.cpp) for the full argument and for
// why the walk is scoped to the RETURN CONE rather than the whole body.
constexpr char kMsgUndefReturn[] =
    "cq specialization: callee return value denotes no value (undef/poison)";

// The single authoritative accept predicate. Returns `SpecReject::Accept` iff
// `Cand` is provably liftable; otherwise the rejecting reason and, in
// `WhereOut`, the offending instruction (for the loud diagnostic's `!dbg`). For
// a `NonReversibilizable` reject, `KindOut` carries the construct-kind string
// (`inline assembly` / `atomic` / `volatile` / `exception handling` /
// `setjmp/longjmp` / `syscall` / `vector SIMD` / `pointer cast` /
// `unsupported width` / `unsupported cast` / `unsupported compare predicate` /
// `nested call` / …) the `(<kind>)` message suffix renders; it is empty for
// every other reason.
// Pure analysis — no IR mutation. `Cand.Callee` is assumed non-null and a
// definition (`!isDeclaration()`); a declaration-only / indirect / non-`CallInst`
// site is filtered earlier (it is "not a candidate", never reaches the
// classifier — the DD-2 no-IR contract), so it never enters the plan and the
// carve-out fires `kMsgUnknownCallee`.
SpecReject classifyCandidate(const SpecCandidate &Cand, const TaintSet &taint,
                             WidthDispatch &wd, llvm::Instruction *&WhereOut,
                             std::string &KindOut);

// Render the loud `DiagnosticInfoUnsupported(DS_Error)` for a reject. `Where`
// supplies the function context and `!dbg`; the message is the `kMsg*` for `Why`
// (the non-reversibilizable kind `Kind` is folded into the `(<kind>)` suffix).
// Defined in `SpecializeReject.cpp`.
void diagnoseReject(llvm::Instruction *Where, SpecReject Why, llvm::StringRef Kind);

// The construct-kind string for a `NonReversibilizable` reject (so the fixture
// mirrors `… (inline assembly)` / `… (atomic)` / …). Empty for every other
// reason. Filled by `classifyCandidate` into the `KindOut` it returns alongside
// the reason; exposed for the driver's diagnostic.
constexpr char kMsgNonRevizPrefix[] =
    "cq specialization: callee contains a non-reversibilizable construct under "
    "quantum lift";

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_REJECT_H_
