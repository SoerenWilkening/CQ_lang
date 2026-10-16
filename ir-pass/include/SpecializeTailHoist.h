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
// (SpecializeTailPlan.h) is moved to the caller, where main's in-place machinery
// decides it exactly as for the inlined body. The chain of `f` is its returned
// value read through xor/add/sub (`isQQStemOpcode`, the opcodes BOTH in-place
// families convert) down to its parameters, through nested calls whose own chain
// reaches their parameters (each substituted at its call). Every other value the
// chain reads is a LEAF, computed by a SOURCE function: a copy of `f` returning
// that leaf (`<f>__cqsrc<N>`), lifted like any callee. The call becomes
//     s = f__cqsrc0(t, a, ...)     (one per leaf; none for a parameter/constant)
//     r = t OP s ...               (the chain, stock opcodes, at the call)
// and `r` replaces the call's result. Lifted bodies are pure (`scanBody`), so each
// source re-runs `f` without observable effect; a chain with no leaf whose call
// may have an effect (`wouldInstructionBeTriviallyDead`, else a cycle or a
// side-effecting instruction) keeps one source returning zero. The source's
// unread parameters are dropped by the dead-argument drop that follows, and the
// caller's chain op gets its `!cq.qq.dead` record from `recordDeadQQOperands` on
// this IR, i.e. the record the inlined op would get. So every downstream answer —
// eligible, kept, both-dead (loud), self-dependent source (loud), the subtrahend
// (loud), the fence, a stale read — is main's answer, asked once (R12), not a
// second spelling of it. Where main's answer is loud, the hoisted call is loud.
//
// THE GATE. A call is rewritten only when it is a proven-Accept lift site
// (`isProvenSpecSite`) whose chain reaches a parameter receiving a TAINTED
// operand that is DEAD at the call (`qqDeadRecordBits` bit 1, the record's own
// question asked at the call's position) and a USER REGISTER's value: a
// `cq_theta` result, a φ the record proved one wire, or an xor/add/sub whose dead
// operand is one (`t ^= a; r = f(t, b)`). A live argument stays lifted: the
// clone's out-of-place result is the unitary main gives the inlined op. A derived
// dead argument (`t * 3`) stays lifted too: the spine returns it to |0> as it
// would the inlined op's operand, and hoisting would only trade the clone
// consumer the M-B plan reasons about for a template reader (a measured leak).
//
// THE SLOTS. Three, each followed by a re-`propagate` (no guard has run): before
// the dead-argument drop's slot A (both entry points); before slot B (both), for
// a site the gate-subroutine inliner's first phase exposed; after its
// CrossCallResults phase (`run` only; `runOnFunction` inlines nothing), whose
// sources' unread slots `resolvePhantomCloneArgReads` neutralises later.
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
// THE BACKSTOP. A site the hoist owed but never saw fails loudly, never silently
// out of place (below).
#ifndef CQ_IRPASS_SPECIALIZE_TAIL_HOIST_H_
#define CQ_IRPASS_SPECIALIZE_TAIL_HOIST_H_

namespace llvm {
class CallInst;
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// NOT IN THE PIPELINE (batch 055). The hoist crossed
// owner-ruling-lift-classical-only-2026-10-06 / R14 ("lifted, not inlined"; it
// would also move a `cqc`-lifted libm body's return chain into the caller); the
// owner ruled the shape must be LOWERED (owner-ruling-r2j3-37-lower-it-2026-10-16)
// and option (b), the CONSUMING CLONE (SpecializeConsume.h), was built instead:
// the site stays one call. The hoist is disabled in every slot (it only strips
// input tags) and kept in tree pending R11 on (b); RETIREMENT: delete it and its
// three slots once (b) clears review.
inline constexpr bool kLiftTailHoistEnabled = false;

// Rewrite every gated lifted call (see above). True if the module changed; the
// caller re-`propagate`s (no guard has run yet at its slot).
bool hoistLiftedTailChains(llvm::Module &M, const TaintSet &taint,
                           WidthDispatch &wd);

// THE TAG. `specialize()` tags each top-level lift site with a hoistable plan:
// `!cq.lift.tail.owed !{i64 Mask, i64 Phi, i64 Chain, consume entries...}` —
// the gate's argument mask (a tainted operand dead at the call and a user
// register's value), the dead-but-unproven-φ mask, every chain parameter, then
// one `!{k, reason, consumer}` per candidate (SpecializeConsume.h). The late
// in-place round decides each site with it (InPlaceQQConsume.cpp) and fails
// loudly with `kMsgLiftTailUnhoisted` for a site it owes and cannot lower.
// Input tags are stripped at every hoist slot (only `specialize()` writes one).
inline constexpr const char kLiftTailOwedTag[] = "cq.lift.tail.owed";
void tagUnhoistedLiftTail(llvm::CallInst &CI, const TaintSet &taint);

extern const char kMsgLiftTailUnhoisted[];

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_TAIL_HOIST_H_
