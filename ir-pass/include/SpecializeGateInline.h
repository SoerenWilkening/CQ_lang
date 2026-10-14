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
// callee holding `cq_*`).
//
// THE MECHANISM: the call is replaced by the callee's body (LLVM's own
// `InlineFunction`), and the caller is then run through clang's `-O1` function
// simplification pipeline (the CGSCC inliner's per-function step). The result is
// the IR `clang -O1` emits when the helper is not marked `noinline`, which main's
// stage list already lowers: rotations rotate the caller's rails, a `cq_phi`
// meets the caller's tainted condition and lowers by kickback, a gate under the
// caller's quantum control is emitted controlled by that condition (or the
// control chain fails loudly), a by-value parameter rotated in place is the
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
//   (a) an argument is tainted (the specializer refuses the callee), or
//   (b) a pointer argument's underlying object receives a tainted store in the
//       caller, or the callee (closure) stores a tainted value (a quantum value
//       through memory; the store-escape guard refuses it), or
//   (c) the callee returns its OWN register (the backward tainted slice of a
//       returned value reaches a `cq_theta` of the callee, or of a gate callee
//       that itself returns its own register, without crossing any other call
//       result: that taint is propagation's conservative lift-site prediction,
//       settled only after the dead-argument drop's slot B) and the result is
//       used (the bd 3jru crossing) or the return is not `i32` (the non-i32
//       escape guard refuses a callee with a use), or
//   (d) it is control-dependent on a tainted conditional `br`/`switch` (the
//       control chain refuses an arm holding the call).
// Taint is round-1 taint, read after the dead-argument drop's slot A (the call
// is in CQLoweringPass.cpp, both entry points). A gate call that only round 2
// places under quantum control is not inlined here; the control chain refuses an
// arm holding a call with quantum effects (measured on the pre-change binary:
// `if (a) ph();` and `if (a) prep();` decline `control flow under quantum
// control`), which keeps it loud. Debug lever: `CQ_GATEINLINE_DBG` prints each
// caller after its simplification.
//
// WHAT IS NOT INLINED. A recursive gate subroutine (a non-trivial SCC of the
// direct-call graph, or a self call) and a call `InlineFunction` refuses are left
// in place for their existing loud owner (`scanBody`'s `callee contains a quantum
// primitive (cq_*)`); an indirect call is never inlined.
//
// A local-linkage gate subroutine left without a use is erased: its standalone
// body would otherwise be lowered with classical parameters (and a non-i32
// quantum return refused). An external-linkage one keeps its body as an export.
//
// Returns true iff it inlined anything; the caller re-`propagate`s, and loops to
// a fixpoint (an inlined body can expose a nested gate call).

#ifndef CQ_IRPASS_SPECIALIZE_GATE_INLINE_H_
#define CQ_IRPASS_SPECIALIZE_GATE_INLINE_H_

#include "TaintPropagation.h"

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

bool inlineGateSubroutines(llvm::Module &M, const TaintSet &taint);

// bd p3kd.21 / bd jx32 — A QUANTUM-RETURNING EXPORT. A defined function with no
// use in the module (every in-module caller of a gate subroutine was inlined
// above; what is left is an entry point or an export, `declineQuantumReturnCalls`'
// "existing Escaped contract") whose return type is a non-i32 integer or
// floating-point scalar. Its tainted `ret` carries the register's runtime handle,
// which is always `i32` (Rule 13 / NORTHSTAR principle 8), so the export returns
// that handle: `declineTaintEscapes` admits the non-i32 tainted `ret` of exactly
// these functions (asked by calling this predicate), and
// `retypeQuantumExportReturns` re-declares their return as `i32` once lowering
// has replaced every returned value by its handle. A function with an in-module
// use keeps the non-i32 decline (its callers would read an `iN`).
bool isQuantumReturnExport(const llvm::Function &F);

// The post-lowering half: every `isQuantumReturnExport` function whose `ret`s
// all carry an `i32` handle is re-declared with an `i32` return (same name,
// linkage, parameters and body; the return attributes are dropped, they described
// the `iN`). A `ret` still carrying a non-`i32` value fails loudly with the
// non-i32 escape string (nothing lowered it to a handle). Returns true iff it
// declined.
bool retypeQuantumExportReturns(llvm::Module &M);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_GATE_INLINE_H_
