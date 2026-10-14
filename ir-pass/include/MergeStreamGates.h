// MergeStreamGates.h — the gate vocabulary of a controlled-copy merge stream,
// shared by `MergeStreamPlan` and `MergeRailDischarge` (bd
// test_C_libtooling-r2j3.32; contract in MergeRailDischarge.h). Pure predicates.

#ifndef CQ_IRPASS_MERGE_STREAM_GATES_H_
#define CQ_IRPASS_MERGE_STREAM_GATES_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
class CallInst;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The called function's name, or "" (indirect call / null).
llvm::StringRef calleeName(const llvm::CallInst *C);

// `cqrt_copy_<W>_controlled(ctrl, src, dst)`, int or fp: void, arity 3 — the one
// gate allowed to WRITE a merge rail (a transversal-CNOT basis copy, an
// involution).
bool isControlledCopy(const llvm::CallInst *C);

// Is `C` merge-stream traffic (the allowlist), and which argument slots does it
// WRITE? Every other slot is a pure read. Fails closed.
bool streamGateWrites(const llvm::CallInst *C,
                      llvm::SmallVectorImpl<unsigned> &W);

// The control slots of the stream's controlled gates (cnot 0, toffoli 0/1,
// controlled copy 0).
llvm::SmallVector<unsigned, 2> controlSlots(const llvm::CallInst *C);

// Does `C` only READ register `X` — never write, measure, record or escape it?
bool onlyReads(const llvm::CallInst *C, const llvm::Value *X,
               const TaintSet &taint);

// Can a gate change `V`'s state? Every call result, a tainted Argument, and
// every Argument of a lifted `__cq_q_*` clone body.
bool isRegister(const llvm::Value *V, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_STREAM_GATES_H_
