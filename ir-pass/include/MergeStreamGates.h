// MergeStreamGates.h — the gate vocabulary of a controlled-copy merge stream,
// shared by `MergeStreamPlan` and `MergeRailDischarge` (bd
// test_C_libtooling-r2j3.32; contract in MergeRailDischarge.h). Pure predicates.

#ifndef CQ_IRPASS_MERGE_STREAM_GATES_H_
#define CQ_IRPASS_MERGE_STREAM_GATES_H_

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
class CallInst;
class DominatorTree;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The called function's name, or "" (indirect call / null).
llvm::StringRef calleeName(const llvm::CallInst *C);

// `cqrt_copy_<W>_controlled(ctrl, src, dst)`, int or fp: void, arity 3.
bool isControlledCopy(const llvm::CallInst *C);

// The uncontrolled basis copy `cqrt_copy_<W>(src, dst)`: void, arity 2.
bool isPlainCopy(const llvm::CallInst *C);

// Does `C` WRITE the merge rail `Out` as a transversal-CNOT basis copy (an XOR
// involution) and touch it in no other slot? These are the only writes of a
// merge rail the replay can undo by re-emission.
bool isMergeWrite(const llvm::CallInst *C, const llvm::Value *Out);

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

// Does slot `I` of stream gate `C` read a REGISTER'S STATE (a handle slot), as
// opposed to a classical immediate (an alloc seed, a template's literal slot)?
// An immediate is immutable SSA whatever its value; only a state read needs
// the window. Exact for the stream allowlist; true for anything else.
bool readsState(const llvm::CallInst *C, unsigned I);

// Can `V` hold a runtime handle whose state a gate can change? FAILS CLOSED:
// everything but a Constant and a classical caller Argument (an untainted
// parameter of a function that is not a lifted `__cq_q_*` clone body).
bool isRegister(const llvm::Value *V, const TaintSet &taint);

// The ALIAS CLASS of a register: every SSA value that may carry the same handle
// at the same program point — closed over φ / select / cast / freeze, in both
// directions. One edge is pruned, exactly: a φ's incoming value that is a FRESH
// mint (`cqrt_alloc_*` / a forward `cq_template_*` producer) whose definition
// does not dominate the φ. Such a value is only ever in the φ's register on an
// earlier trip of a loop (a back edge); every gate that names it runs on its
// current, freshly minted instance, a different handle. Memory is crossed
// only through a proven rail bank (its parked rails and cell loads join the
// class); false when the handle reaches any other load or store, where no
// alias set is provable.
bool handleAliases(llvm::Value *X, const TaintSet &taint,
                   const llvm::DominatorTree &DT,
                   llvm::SmallPtrSetImpl<llvm::Value *> &Out);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_STREAM_GATES_H_
