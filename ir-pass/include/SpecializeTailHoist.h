// SpecializeTailHoist.h — the in-place question ACROSS a lifted call
// (bd test_C_libtooling-r2j3.37).
//
// THE DEFECT. A lifted call is a Bennett embedding |x>|y>|0> -> |x>|y>|f(x,y)>:
// the clone borrows its arguments and copies its result out (BennettWrap.h). So
// `r = f(t, a)` with `f(t,a){ t ^= a; return t; }` left the caller's `t` rail
// standing beside `r`, and the pair (t, r) records `a`: a later Ry on `a` is
// dephased (verify-clean, rc 0). The same body INLINED is `r = t ^ a` with `t`
// dead, which the in-place QQ round lowers onto `t`'s rail (owner ruling
// owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1, InPlaceQQ.h). The clone path never
// asks that question: its templates live in the clone's own taint, and no in-place
// gate inside a Bennett-wrapped body survives the wrap's own reverse anyway.
//
// THE MECHANISM. Before any stage reads the call, the lifted call's RETURN CHAIN
// is moved to the caller, where main's in-place machinery decides it exactly as
// for the inlined body. The chain of `f` is its returned value read through
// xor/add/sub (`isQQStemOpcode`, the opcodes BOTH in-place families convert) down
// to its parameters, through nested calls whose own chain reaches their
// parameters (each substituted at its call). Every other value the chain reads is
// a LEAF, computed by a SOURCE function: a copy of `f` returning that leaf
// (`<f>__cqsrc<N>`), lifted like any callee. The call becomes
//     s = f__cqsrc0(t, a, ...)     (one per leaf; none for a parameter/constant)
//     r = t OP s ...               (the chain, stock opcodes, at the call)
// and `r` replaces the call's result. Lifted bodies are pure (`scanBody`), so each
// source re-runs `f` without observable effect; a chain with no leaf whose call is
// not trivially dead keeps one source returning zero, so termination is kept.
// The source's unread parameters are then dropped by the dead-argument drop that
// runs right after (slot A), and the caller's chain op gets its `!cq.qq.dead`
// record from `recordDeadQQOperands` on this IR, i.e. the record the inlined op
// would get. So every downstream answer — eligible, kept, both-dead (loud),
// self-dependent source (loud), the fence, a LIVE argument staying out of place
// — is main's answer, asked once (R12), not a second spelling of it.
//
// THE GATE. A call is rewritten only when it is a proven-Accept lift site
// (`isProvenSpecSite`) whose chain reaches a parameter that receives a TAINTED
// operand the in-place record would call dead (or a dead φ not provably one wire)
// at the call (`qqDeadRecordBits`). A live argument would stay out of place in
// the caller too, where the clone's out-of-place result is the same unitary.
//
// REFERENCES (R12). Bennett.jl 824458d1 src/lowering/call.jl `lower_call!` CNOT-
// copies the caller's argument wires into the callee (compact=true: a Bennett-
// wrapped callee, its output on fresh wires) and never overwrites a caller
// argument; its exclusive-reader in-place target (src/lowering/operand.jl:182-221,
// `compute_inplace_targets`) is a CALLEE-LOCAL fact ("function-argument registers
// are restored by the reverse pass"). BennettVM.jl 23d28e6
// src/ir/call_transitions.jl `CallEnter` COPIES args (ADR 0019 Amendment A.1)
// and MOVEs only returns. Neither overwrites a dead caller argument: both model
// classical bits, where a standing old value is invisible. The hazard is the
// superposition CQ adds; the hoist puts the overwrite where CQ decides it.
//
// THE BACKSTOP. A site the hoist owed but never saw (a call whose argument taint
// arrives only in round 2) fails loudly, never silently out of place (below).
#ifndef CQ_IRPASS_SPECIALIZE_TAIL_HOIST_H_
#define CQ_IRPASS_SPECIALIZE_TAIL_HOIST_H_

namespace llvm {
class CallInst;
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// Rewrite every gated lifted call (see above). True if the module changed; the
// caller re-`propagate`s (no guard has run yet at its slot).
bool hoistLiftedTailChains(llvm::Module &M, const TaintSet &taint,
                           WidthDispatch &wd);

// THE BACKSTOP, in two halves. `specialize()` tags each top-level lift site
// whose chain reaches a tainted argument the record calls dead at the call
// (`!cq.lift.tail.owed`, the argument mask): the hoist owed it and never saw it.
// The late in-place round (`lowerInPlaceQQ`, after `lowerOps`) then asks main's
// own E2/E3 of each tagged argument — a USER-DATA rail (`qqTargetIsUserData`)
// beside a SURVIVING result (`qqResultSurvives`) — and fails loudly
// (`kMsgLiftTailUnhoisted`): the in-place round would not leave it out of place.
// A derived rail (a merge `%out`, a template) is a temporary the spine returns to
// |0>, as for the inlined op. Strips every tag.
inline constexpr const char kLiftTailOwedTag[] = "cq.lift.tail.owed";
void tagUnhoistedLiftTail(llvm::CallInst &CI, const TaintSet &taint);
bool declineUnhoistedLiftTails(llvm::Module &M, const TaintSet &taint);

extern const char kMsgLiftTailUnhoisted[];

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_TAIL_HOIST_H_
