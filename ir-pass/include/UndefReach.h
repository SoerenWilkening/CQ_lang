// UndefReach.h — does an `undef`/`poison` PHI INCOMING reach a returned value?
// (bd p3kd.8; the phi-incoming refinement of the bd 3p2a return-cone fence in
// SpecializeReject.cpp, `returnDerivesFromUndef`).
//
// THE QUESTION. `scanBody` certifies that a lifted callee computes a function of
// its arguments. bd 3p2a asked it SYNTACTICALLY: an undef/poison constant anywhere
// in the backward data cone of a `ret` declined `callee return value denotes no
// value`. That is exact for an undef in an ordinary operand slot (`xor i32 undef,
// 7` feeding the return is read on every execution of the xor), but not for a PHI
// INCOMING: the incoming exists only on executions that take its edge, and clang
// -O1 emits exactly that shape for a variable left uninitialized on a path that
// never reads it. openlibm log1p/log1pf leave the correction `c` uninitialized
// when `k == 0` and read it only when `k != 0`:
//
//     %80 = phi i32    [ %70, %68 ], [ 0, %33 ]       ; k
//     %81 = phi double [ %55, %68 ], [ undef, %33 ]   ; c
//
// so acosh/asinh/atanh/log1p (f32, f64) declined although every returned value is
// well defined.
//
// THE ANSWER. `undefIncomingReachesReturn(PN, K)` evaluates the function FORWARD
// from the phi's block under the assumption that control arrived over the undef's
// edge `Pred -> B`: each phi of B takes its `Pred` incoming (a constant there is an
// EXACT value on every such execution), the path condition into the edge is known
// (the edge's own two-way `br`, and the `br` above each block of the
// single-predecessor chain ending at `Pred`: exp2's undef scale is read only behind
// a second test of the condition that chose its arm), constants are folded with LLVM's own
// folder (`ConstantFoldInstOperands`, non-deterministic results refused), a branch
// or switch whose condition folds keeps only the taken successor, and a value is
// flagged "undef-derived" when any operand it reads on an executable edge is
// (every undef/poison constant counts, not only this incoming). A `select` whose
// condition folds reads only the chosen arm. It answers TRUE iff some executable
// `ret` returns an undef-derived value. On log1p the sibling phi `k` is 0 on the
// edge, so every reader of `c` sits behind a `k != 0` test that folds false.
//
// WHY THIS IS SOUND (the argument a reviewer should attack).
//   * Paths: an executable edge set that keeps every successor of an unfolded
//     condition over-approximates the executions through `Pred -> B`; a folded
//     condition is exact, because it is computed from constants that hold on
//     every such execution (B's phis are assigned once per execution: the region
//     reachable from B must be ACYCLIC, otherwise the evaluation answers TRUE).
//     A path condition holds on every such execution because a block with one
//     predecessor is entered only from it, so the execution's last steps before
//     B are exactly the chain, and each condition is an SSA value defined above
//     its branch that nothing re-defines afterwards (re-entering the chain would
//     put B on a cycle). A contradictory path condition answers TRUE.
//   * Data: the flag over-approximates dependence (any undef-derived operand
//     taints the result), with one exception — a select with a folded condition,
//     which is exact.
//   * Control: a `br`/`switch` on an undef-derived condition explores BOTH
//     successors rather than declining. LangRef: branching on undef or poison is
//     immediate undefined behaviour, so no defined execution takes such a branch,
//     and the returned value never denotes undef on a defined execution. (The bd
//     3p2a cone walk never followed a branch condition either, so this keeps
//     `main`'s verdict: spec_accept_undef_phi_controls_branch_ub.ll.)
//   * Monotone: a TRUE here implies the undef reached a `ret` operand through
//     operand edges only, all of which the bd 3p2a cone walk also follows, so this
//     refinement never declines a callee the walk accepted (a pure widening). Every
//     bail-out (a cycle, an unknown terminator) answers TRUE: the walk's verdict.
//
// WHAT IT DOES NOT CLAIM. It never substitutes a value. The clone pipeline's
// PredMux flatten (`convertPhis`) freezes the incoming to the type's zero, a
// deterministic refinement of `undef`, so the forward clone and any uncompute twin
// compute one function. `convertPhis` freezes only a whole-value `isa<UndefValue>`
// incoming, so the caller refines only that spelling (R1 review F1: an incoming
// that merely carries undef inside a ConstantExpr is not frozen and stays a
// decline). This predicate is what proves that function equals the
// source's on every defined execution (the return never reads the frozen value).
// A return that DOES denote undef on a feasible path still declines: never
// replace a reachable undef return with zero (bd p3kd.8 notes; Bennett.jl
// test/test_yd4f_undef_phi_cells.jl GATE 2 at 824458d1).

#ifndef CQ_IRPASS_UNDEF_REACH_H_
#define CQ_IRPASS_UNDEF_REACH_H_

namespace llvm {
class PHINode;
}  // namespace llvm

namespace cq {

// True iff the `K`-th incoming of `PN` — a whole-value `undef`/`poison`
// (`isa<UndefValue>`, the incoming PredMux's `convertPhis` freezes; the caller in
// SpecializeReject.cpp keeps declining an incoming that only CARRIES undef inside a
// ConstantExpr or aggregate) — can reach a value some `ret` of `PN`'s function returns on
// a defined execution that enters `PN`'s block over that incoming's edge. TRUE is
// also the conservative answer for any shape the evaluation does not model (a
// cycle reachable from the block, an unmodelled terminator). Pure analysis.
bool undefIncomingReachesReturn(const llvm::PHINode &PN, unsigned K);

}  // namespace cq

#endif  // CQ_IRPASS_UNDEF_REACH_H_
