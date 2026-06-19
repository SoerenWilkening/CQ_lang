// SelectMergeEmit.h — The mutating emitter for an accepted tainted-condition
// integer-data `select` (Phase 4.4 / PRD Part IV §16.3; IMPLEMENTATION-4.4 §4).
//
// A `select` is the SIMPLEST Phase-4 shape: one SSA instruction, no CFG diamond,
// no rail, no route `cqrt_cswap`, no `RegionFlatten`, no reverse-play. Its merge
// is the controlled-XOR copy: mint the flag from the condition compare, alloc a
// fresh |0> result rail, copy the TRUE operand into it on the flag and the FALSE
// operand on ¬flag (X-bracketed — the 4.1 convention), strip the flag, free it
// (the ONE free), then RAUW `%sel → %out`. Emitted before the select, in this
// EXACT order (the §5a contract; symbol order IS the contract):
//
//   1 mint        cq_template_icmp_<pred>_<Wc>_hl(q, k)            -> %f
//   2 rail        %out = cqrt_alloc_<Wd>(0)
//   3 true copy   cqrt_copy_<Wd>_controlled(%f, true,  %out)       (fires on f=1)
//   4 ¬flag copy  cqrt_x(%f) ; cqrt_copy_<Wd>_controlled(%f, false, %out) ; cqrt_x(%f)
//   5 strip+free  cq_template_icmp_<pred>_<Wc>_hl_inv(q, k) ; cqrt_free(%f)
//   6 rewire      RAUW %sel -> %out ; scrub ; erase (NO flatten — there is no CFG)
//
// The load-bearing correctness beyond the `dst=|0>` precondition (§16.3,
// verify-clean-invisible): the `cqrt_x` bracket must enclose ONLY the second
// copy. A mis-bracketed emitter (`x` before BOTH copies) double-writes a then b
// on the SAME basis branch yet produces the IDENTICAL symbol multiset — caught
// only by the §5a ordered FileCheck + the §8 two-row trace, never by `opt
// -verify`. A classical operand is materialized `%h = cqrt_alloc_<Wd>(v)`
// (option A, all-core ABI); a quantum-handle operand is the identity. Exactly
// ONE `cqrt_free` (the flag, provably |0> after the strip); `%out`, both
// operands, and any materialized scratch are LEFT ALLOCATED, never freed
// (freeing an operand entangled with `%out` via the copy is a hidden
// measurement — Rule 6/8). The merge is a COPY, not a route — it dephases a
// phase/superposition answer (Rule 7), which the §3.2 angle gate + §16.7
// coherent-operand gate fence out at detection.
//
// Dispatched from `SwapRouteEmit::lowerControlRegions` on `R.Kind ==
// SelectRegion`. Runs BEFORE `lowerRotations` (the select + operands still carry
// their real logical types, so `abiWidthFromType(Sel->getType())` is reliable —
// not the post-RAUW i32-laundering trap) and BEFORE `declineClassicalMuxes` (it
// is the SOLE owner of the tainted-condition select — it MUST RAUW + erase it
// here, else a surviving live select false-declines `classical select`, §1/§6.4).

#ifndef CQ_IRPASS_SELECT_MERGE_EMIT_H_
#define CQ_IRPASS_SELECT_MERGE_EMIT_H_

#include "llvm/ADT/Twine.h"        // llvm::Twine (default-arg conversion)
#include "llvm/IR/DerivedTypes.h"  // llvm::FunctionCallee
#include "llvm/IR/IRBuilder.h"     // llvm::IRBuilder

namespace llvm {
class DebugLoc;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Materialize a copy SOURCE operand into an i32 handle for a controlled-copy
// merge (the shared 4.4 select / 4.5 switch-datamux / 6.5 classical-call helper,
// C17 / Rule 14). A QUANTUM operand is already an i32 register — return it
// UNCHANGED (the identity, the §5b Q+Q case). A CLASSICAL operand (a compile-time
// constant OR a runtime classical value) is materialized `%h = cqrt_alloc_<Wd>(v)`
// (option A, PRD §16.4 — all-core ABI, no `_controlled` template). The caller's
// operand type equals the rail-width type (LLVM select/phi-incoming invariant), so
// `v` is already well-typed for the alloc. The scratch is left UNTAINTED so
// `uncompute` never selects it (a benign classical-valued leak, §16.5) — its only
// user is the copy and it is never freed. `Name` only spells the SSA name (the
// callers' fixtures capture it, so it is cosmetic): the select/classical-call path
// uses the default `selop`; the switch-datamux delta passes `delta`.
//
// Promoted from the file-local `static materialize` in SelectMergeEmit.cpp so the
// select emitter, `SwitchDataMuxEmit`, and `ClassicalCallArmEmit` share ONE
// implementation (Rule 14 — retires the SwitchDataMuxEmit:176 inline duplication).
llvm::Value *materializeCopySource(llvm::Value *V, llvm::FunctionCallee Alloc,
                                   const TaintSet &taint, llvm::IRBuilder<> &B,
                                   const llvm::DebugLoc &DL,
                                   const llvm::Twine &Name = "selop");

// Lower one accepted `SelectRegion` (`R.Merge` is the `SelectInst`, `R.Condition`
// its `CmpInst`) to the controlled-XOR copy merge stream above. Mutates the
// module IR and `taint` (inserts `%out`; scrubs the erased select + its now-dead
// condition compare). A malformed plan (non-select `Merge` / non-compare
// `Condition` / unsupported width past detection) declines LOUDLY and lowers
// nothing (Rule 1) — never a silent skip of quantum-controlled flow.
void emitSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SELECT_MERGE_EMIT_H_
