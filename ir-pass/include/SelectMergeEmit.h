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

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

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
