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
//   3 true write  W(%f, true, %out)                                (fires on f=1)
//   4 ¬flag write cqrt_x(%f) ; W(%f, false, %out) ; cqrt_x(%f)
//   5 strip+free  cq_template_icmp_<pred>_<Wc>_hl_inv(q, k) ; cqrt_free(%f)
//   6 rewire      RAUW %sel -> %out ; scrub ; erase (NO flatten — there is no CFG)
//
// where W is the arm write (bd dm7f.81, MergeArmWrite.h): a quantum arm
// `cqrt_copy_<Wd>_controlled(%f, arm, %out)`, a classical arm
// `cqrt_xorc_<Wd>_controlled(%f, %out, arm)` with the value as a literal operand,
// and an all-zero classical arm nothing (step 4 then emits no bracket either).
//
// The load-bearing correctness beyond the `dst=|0>` precondition (§16.3,
// verify-clean-invisible): the `cqrt_x` bracket must enclose ONLY the second
// write. A mis-bracketed emitter (`x` before BOTH writes) double-writes a then b
// on the SAME basis branch yet produces the IDENTICAL symbol multiset — caught
// only by the §5a ordered FileCheck + the §8 two-row trace, never by `opt
// -verify`. A classical operand is never a rail (R13). Exactly
// ONE `cqrt_free` (the flag, provably |0> after the strip); `%out` and the
// quantum operands are LEFT ALLOCATED here, never freed
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
class Module;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Materialize a value into an i32 handle: a QUANTUM operand is already an i32
// register — return it UNCHANGED; a CLASSICAL one is loaded into a fresh rail
// `%h = cqrt_alloc_<Wd>(v)`, left UNTAINTED. bd dm7f.81 took every merge ARM off
// this path (a classical arm is now a literal operand of
// `cqrt_xorc_<W>_controlled`, MergeArmWrite.h, never a rail); its callers are the
// ones that need a REGISTER holding the value: the loop rail seed
// (LoopLowering) and a clone's classical-condition rail select
// (CloneRailSelect). `Name` only spells the SSA name. Implemented in
// MergeArmWrite.cpp beside the ledger it shares.
//
// bd test_C_libtooling-r2j3.14 — A CLASSICAL ANSWER IS A ROUND-1 ANSWER (L1).
// "Is `V` quantum?" is asked at the taint of the caller's round. A value that is
// classical when a round-1 region emits can become a register in round 2 (it
// derives from a 6.5 / 4.5 merge `%out`, or from a 7.4 break escape register),
// and then the alloc above loads the register's HANDLE ID as the value: a
// verify-clean wrong unitary (measured, control_select_reject_round2_copy_source.ll).
// So every classical load is RECORDED here — and since dm7f.81 every
// `cqrt_xorc_<W>_controlled` arm write whose immediate is not a Constant
// (`emitArmWrite`) — and re-asked at final taint by `declineQuantumCopySources`;
// a compile-time constant is never recorded (it cannot become quantum).
llvm::Value *materializeCopySource(llvm::Value *V, llvm::FunctionCallee Alloc,
                                   const TaintSet &taint, llvm::IRBuilder<> &B,
                                   const llvm::DebugLoc &DL,
                                   const llvm::Twine &Name = "selop");

// bd test_C_libtooling-r2j3.14 — THE L1 RE-ASK of every classical value
// `materializeCopySource` loaded or `emitArmWrite` passed as an immediate (its
// slot 2, bd dm7f.81), in the slot after the round-2 fixpoint where
// `declineQuantumCondLiterals` re-asks a condition literal, in BOTH entry points
// (the same record-and-re-ask pattern, for the data operand instead of the
// condition literal). A recorded load whose value is quantum at FINAL taint
// declines loudly ("classical copy source became quantum-derived"). Reads the
// record once and clears it. Returns true iff it declined. Lowering instead of
// declining would read the value's register as the copy source, which is what
// the emitter does for a value quantum at emission time (a gap, R1).
bool declineQuantumCopySources(llvm::Module &M, TaintSet &taint);

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
