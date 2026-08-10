// ChainWalk.cpp — see header. Terminal-handle detection + the shared per-gate
// predicates. The whole-DAG recovery itself lives in `DagTraversal` (WI-4); this
// module is the vocabulary both it and the uncompute driver consult.

#include "ChainWalk.h"

#include "TaintPropagation.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

bool isInPlaceGateOn(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // iw81.7: the GUARDED QRAM store `cqrt_qram_store_<W>_controlled(flag, arr, idx,
  // val)` — a VOID in-place mutation on its ARG-1 array handle (arg 0 is the path
  // predicate flag; the plain store has the array at arg 0). arg_size 4. Recognized
  // BEFORE the generic `_controlled` bail below (a controlled gate is normally NOT
  // an in-place gate, but this store IS on its array). The `_controlled_unc` twin
  // ends `_unc`, not `_controlled`, so it is EXCLUDED (it is the adjoint). The flag
  // (arg 0) is a borrowed tainted operand `DagTraversal` enqueues as a parent — its
  // producer (the flag-mint compare) reverses AFTER this gate's `_unc` (the strip).
  if (N.starts_with("cqrt_qram_store_") && N.ends_with("_controlled") &&
      G->arg_size() == 4 && G->getArgOperand(1) == H)
    return true;
  if (N.contains("_controlled"))
    return false;
  // Uncontrolled rotation `cqrt_ry/rz_<W>(H, θ)` — arg_size 2, arg 0 is the
  // handle. Mints no new value (void), so it belongs to `H`'s DAG link.
  if ((N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
      G->arg_size() == 2 && G->getArgOperand(0) == H)
    return true;
  // Phase 7.5 Inc 2: an uncontrolled QRAM store `cqrt_qram_store_<W>(arr, idx,
  // val)` — a VOID in-place mutation on its arg-0 ARRAY handle (mints no new
  // value, keeps the handle live), structurally the same in-place-gate shape as
  // a rotation but with two MORE borrowed tainted operands (idx, val) that
  // `DagTraversal` enqueues as parents. arg_size 3. The `_unc` twin is EXCLUDED
  // (it ends `_unc`) — it is the adjoint, never a forward in-place gate.
  if (N.starts_with("cqrt_qram_store_") && !N.ends_with("_unc") &&
      G->arg_size() == 3 && G->getArgOperand(0) == H)
    return true;
  return false;
}

bool isAllocMint(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // A qubit-register mint, OR (Phase 7.5 Inc 2) a QRAM array-handle mint: the
  // alloca-backed mutable array is an in-place-mutated register ROOT — its
  // stores are reversed (LIFO) but the array handle itself is a CLASSICAL
  // resource token, never freed (§2.9; Inc 1 "array-handle-never-freed"). Both
  // bottom out the DAG (no tainted parents to hop to — alloc takes a classical
  // count).
  return N.starts_with("cqrt_alloc_") || N.starts_with("cqrt_qram_alloc_");
}

bool isMeasureSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_measure_");
}

bool isOutputSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_tape_write_");
}

bool recordsIntoKeptCarrier(const CallInst *S, const Value *H) {
  // Tape-only and SLOT-BLIND — see the header for why both are load-bearing (the
  // controlled twin records its ctrl at arg 0 and its src at arg 2, and the tape
  // token is never a DAG rail so a blind scan cannot over-match).
  if (!isOutputSink(S))
    return false;
  for (const Use &A : S->args())
    if (A.get() == H)
      return true;
  return false;
}

bool isCopyOutSink(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // The UNCONTROLLED 2-arg basis copy `cqrt_copy_<W>(src, dst)` reading `H` as its
  // SOURCE (arg 0). Like a measure / tape-write sink it READS H without consuming
  // it, so the spine treats it as a benign terminal user; the copy DESTINATION
  // (dst) is the kept carrier. The 3-arg `_controlled` data-mux copy (4.4/6.5) and
  // any `_inv`/`_unc` twin fail. NOT a `recordsIntoKeptCarrier` — bd 8gi5 owns
  // whether this surface needs the 261j freeze (it has no live instance today).
  return N.starts_with("cqrt_copy_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc") && G->arg_size() == 2 &&
         G->getArgOperand(0) == H;
}

Value *railOf(CallInst *G) {
  // An in-place gate's rail is the operand it MUTATES, so ASK `isInPlaceGateOn`
  // — the single definition of that relation — instead of re-spelling its
  // arity/suffix tests here. Re-spelling them is exactly how the guarded QRAM
  // store came to be mis-attributed (bd test_C_libtooling-uow0): this function
  // returned the arg-0 FLAG of `cqrt_qram_store_<W>_controlled(flag, arr, idx,
  // val)` while `isInPlaceGateOn` correctly matched the arg-1 ARRAY of the very
  // same gate, so the two predicates disagreed about which register the gate
  // writes. Driving one from the other makes them agree BY CONSTRUCTION rather
  // than by two spellings being kept in sync (Rule 14).
  //
  // First match wins. That is unambiguous, not a tie-break: `isInPlaceGateOn`
  // matches exactly ONE argument position per callee shape, and when the same
  // SSA value is passed in two slots of one gate the answer is that value either
  // way.
  for (Value *Op : G->args())
    if (isInPlaceGateOn(G, Op))
      return Op;
  const Function *Callee = G->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // `cqrt_x` is self-inverse and acts on its arg-0 handle. `isInPlaceGateOn`
  // deliberately does not recognize it (the same reason it is absent from
  // `preservesBasisUnderRecord`), so the loop above never returns for it.
  //
  // REACHABILITY, stated exactly — an earlier draft of this comment said
  // "UNREACHABLE, a void call can never be a DAG handle" and that was WRONG
  // (measured in the bd uow0 Rule-13 round). The premise holds for the real
  // ABI symbol, which IS void; but `declineTaintEscapes` carves out `cqrt_*` by
  // NAME with no signature check, so a user-declared NON-void `@cqrt_x` is
  // recovered by the DAG walk's tainted-CallInst path and this arm does fire.
  // Behaviour there is identical to the pre-uow0 spelling (arg 0) and is the safe
  // direction (the fictional result is leaked, not freed). Kept because it AGREES
  // with the loop above — were `isInPlaceGateOn` ever taught `cqrt_x` it would
  // match this same arg-0 handle — so unlike the pre-uow0 spelling for the QRAM
  // store, this arm cannot contradict it.
  if (N == "cqrt_x" && G->arg_size() >= 1)
    return G->getArgOperand(0);
  // A reassigning producer (`cq_template_*`, `cqrt_qram_load_<W>`): the fresh
  // result IS the rail (PRD §2.11).
  return G;
}

bool isTerminalHandle(Value *Handle, const TaintSet &taint) {
  if (!taint.Tainted.count(Handle))
    return false;
  // Terminal iff EVERY user is benign: an in-place rotation on `Handle` (mints
  // no new value), a measurement sink, or a non-quantum read. ANY other gate
  // that takes `Handle` as an operand — a data/compare/cast template, a
  // controlled gate, a `_controlled`/teardown `_inv` — consumes the register
  // forward or keeps it live as control input, so `Handle` is NOT the terminal.
  for (User *U : Handle->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      continue;  // a classical/non-call read does not extend the quantum chain
    if (isInPlaceGateOn(CI, Handle) || isMeasureSink(CI) || isOutputSink(CI) ||
        isCopyOutSink(CI, Handle))
      continue;  // in-place rotation, measurement/output sink (7.6), or a method-B
                 // copy-out reading Handle as src (sxuk — preserves it)
    return false;  // any other gate consumes `Handle` ⇒ not the chain terminal
  }
  return true;
}

}  // namespace cq
