// SpecializeGateInline.h — gate subroutines are compiled at their call site
// (bd test_C_libtooling-p3kd.21).
//
// A GATE SUBROUTINE is a defined function whose body applies a front-end quantum
// primitive (`cq_theta`, `cq_phi`, `cq_measure`; exact `taint.{Theta,Phase,
// Measure}Calls` membership, never a name prefix) or calls, directly, another
// gate subroutine. It is not a classical function with tainted inputs: its
// rotations act on the caller's registers, so it cannot be Bennett-lifted (the
// wrap would reverse-play the rotation, and a by-value parameter rotated in
// place is the caller's rail). Lifting stays classical-callee-only (bd memory
// owner-ruling-lift-classical-only-2026-10-06; `scanBody` still refuses a
// callee holding `cq_*`, pinned by spec_reject_gate_sub_weak_{primitive,measure}.ll).
//
// THE MECHANISM (APPROVED: owner ruling, bd memory
// owner-ruling-p3kd21-gate-subroutines-2026-10-14): the call is replaced by the
// callee's body (LLVM's own
// `InlineFunction`), and the caller is then run through the `-O1` function
// simplification pipeline built with the PipelineTuningOptions clang uses at
// `-O1` (no loop unrolling, interleaving or vectorization; R11 r1 item 2). That
// is clang's per-function step after inlining, with one disclosed difference:
// cq-opt links no target, so the pipeline has no TargetMachine and its cost
// models (TTI) are the target-independent defaults, where clang has the x86 ones
// (affects heuristics such as SimplifyCFG speculation, never legality). Main's
// stage list then lowers the result: rotations rotate the caller's rails, a
// `cq_phi` meets the caller's tainted condition and lowers by kickback, a gate
// under the caller's quantum control is emitted controlled by that condition (or
// the control chain fails loudly), a by-value parameter rotated in place is the
// caller's register read through its SSA name (the stale-reader fences apply as
// they do to the hand-inlined twin), and a by-pointer cell is promoted by SROA.
// Bennett.jl's non-compact `lower_call!` is the same construction
// (src/lowering/call.jl:169-185: the callee's forward gates are inserted into the
// caller's wire space and the caller's own uncompute owns cleanup).
//
// WHICH CALLS. Only a call the standalone path cannot compile is inlined, so a
// program that compiles today is untouched (the noinline-helper idiom of the e2e
// slices keeps its separately lowered body; bd memory
// e2e-uncompute-slice-noinline-keepalive). A call to a gate subroutine is
// inlined iff
//   (a) an argument is tainted, or can be tainted by a later round (the
//       specializer refuses the callee), or
//   (b) a pointer argument's underlying object receives a store of a value that
//       is or can become tainted in the caller, or the callee (closure) stores a
//       tainted value (the store-escape guard refuses it), or
//   (c) the callee returns its OWN register (the backward tainted slice of a
//       returned value reaches a `cq_theta` of the callee, or of a gate callee
//       that itself returns its own register) and the result is used (the bd
//       3jru crossing) or the return is not `i32` (the non-i32 escape guard
//       refuses a callee with a use). The slice crosses another call's RESULT
//       only in the `CrossCallResults` phase, after the dead-argument drop's
//       slot B: before it, that taint is propagation's conservative lift-site
//       prediction (`w` in slice_spec_dropped_arg_musttail_return returns
//       `h2(p, k + z)`, classical once slot B nulls the dead `musttail` slot), or
//   (d) it is control-dependent on a conditional `br`/`switch` whose condition
//       is or can become tainted (the control chain refuses an arm holding it).
// "Can become tainted" is `LaterTaintOracle` (`makeLaterTaintQuery`), the
// propagation drain's own over-approximation of round-2 growth (L1). The
// question is RE-ASKED after the round-2 fixpoint (`declineMissedGateSubroutines`,
// both entry points): a site it now names is loud, never lowered as a call.
// Debug lever: `CQ_GATEINLINE_DBG` prints each caller after its simplification.
//
// WHAT IS NOT INLINED, each left to its existing loud owner: a recursive gate
// subroutine (a non-trivial SCC of the direct-call graph, or a self call); an
// interposable callee (`weak`, `linkonce`: the linked body may differ); a site
// `InlineFunction` refuses; an indirect call; and a site produced by inlining the
// same callee (the INLINE HISTORY, LLVM's `InlineHistory` rule: a call that
// devirtualizes into a self-call after inlining must not be inlined again, R11 r1
// item 1). Rounds are also capped (`kMaxRounds`) as a termination backstop.
//
// A gate subroutine left without a use after inlining is erased when it has
// local linkage, or when the module defines `main` (a whole program: cqc
// llvm-links every TU before the pass, so nothing else can call it): its
// standalone body would otherwise be lowered with classical parameters. An
// external one in a module without `main` keeps its body as an export.
//
// Returns true iff it inlined anything; the caller re-`propagate`s, and loops to
// a fixpoint (an inlined body can expose a nested gate call).

#ifndef CQ_IRPASS_SPECIALIZE_GATE_INLINE_H_
#define CQ_IRPASS_SPECIALIZE_GATE_INLINE_H_

#include "TaintPropagation.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/ValueMap.h"

#include <functional>

namespace llvm {
class CallBase;
class Function;
class Module;
class ReturnInst;
class Value;
}  // namespace llvm

namespace cq {

// State carried across every inlining round of one pass run.
struct GateInlineState {
  // The inline history: for a call site produced by inlining, the callees whose
  // inlining produced it. `ValueMap` drops an erased site and follows a RAUW.
  llvm::ValueMap<llvm::CallBase *, llvm::SmallVector<llvm::Function *, 2>>
      History;
  unsigned Rounds = 0;
};

bool inlineGateSubroutines(llvm::Module &M, const TaintSet &taint,
                           GateInlineState &St, bool CrossCallResults);

// The L1 re-ask, after the round-2 fixpoint: a direct call to a gate subroutine
// that the triggers name on the CURRENT taint, and that is not left to another
// owner (recursive, interposable, inline-history), was missed by round 1. Loud
// (`cq specialization: gate subroutine call became quantum after call-site
// compilation`). Returns true iff it declined.
bool declineMissedGateSubroutines(llvm::Module &M, const TaintSet &taint,
                                  const GateInlineState &St);

// bd p3kd.21 / bd jx32 — A QUANTUM-RETURNING EXPORT: a defined function with no
// use in the module (an export, `declineQuantumReturnCalls`'
// Escaped contract) whose return type is an integer WIDER than 32 bits. Its
// tainted `ret` carries the register's runtime handle (always `i32`, Rule 13),
// zero-extended to the declared width by `widenQuantumExportReturns`, so the C
// signature is unchanged and a caller reads the handle in the register it reads
// an `iN` from. `declineTaintEscapes` admits the tainted `ret` of exactly these
// functions (asked by calling this predicate). A narrower integer (`_Bool`,
// `char`, `short`) cannot carry the handle and a floating-point return is read
// from another register (xmm0), so both keep the non-i32 decline
// (owner ruling owner-ruling-p3kd21-gate-subroutines-2026-10-14: the widening is
// approved for integer returns of 32 bits or wider ONLY), as does a function with
// an in-module use.
// `main` is never one: its return is the process exit status, and a register
// returned there fails loudly (`declineTaintedMainReturns`, R11 r2 F1).
bool isQuantumReturnExport(const llvm::Function &F);

// The program entry point: an externally visible definition named `main`.
bool isProgramEntryPoint(const llvm::Function &F);

// The post-lowering half: in every `isQuantumReturnExport` function, a `ret`
// carrying an `i32` handle returns its zero-extension. A `ret` carrying anything
// else beside such a one fails loudly with the non-i32 string (backstop: the
// pre-lowering mixed-return decline in `declineTaintEscapes` speaks first).
// Returns true iff it declined.
bool widenQuantumExportReturns(llvm::Module &M);

// Defined in TaintPropagation.cpp (bd p3kd.21 R11 r2 F1): the main-return
// question. `isTaintedMainRet` is THE predicate. `declineTaintEscapes` lets a hit
// through untouched (a `continue`: no clause there declines or admits it), and
// `declineTaintedMainReturns`, after `specialize()` in both entry points (taint is
// final there; before it a lift-site result is tainted by prediction), is loud iff
// a `ret` of `main` is still tainted. Returns true iff it declined.
bool isTaintedMainRet(const llvm::ReturnInst &R, const TaintSet &taint);
bool declineTaintedMainReturns(llvm::Module &M, const TaintSet &taint);

// Defined in TaintPropagation.cpp: `LaterTaintOracle::mayGain` over `taint`.
std::function<bool(llvm::Value *)> makeLaterTaintQuery(const TaintSet &taint);
// Defined in TaintPropagation.cpp: the ONE spelling of the non-i32 string.
const char *nonI32ReturnMessage();

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_GATE_INLINE_H_
