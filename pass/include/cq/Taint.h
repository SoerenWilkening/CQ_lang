// Frozen interface (cq-arch, with owner amendment A1 of 2026-10-27 and freeze bead cq-k1w).
// Changes only under cq-arch's freeze rule.
#pragma once

#include <memory>
#include <vector>

#include "cq/Abi.h"
#include "cq/Common.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

// Taint.h  (rule 3; rule 20 classification; rule 21 provenance)
namespace cq {
struct Specialization { llvm::Function *F; Mask mask; bool ctl = false, pure = false, adj = false;
                        unsigned depth = 0; std::vector<uint64_t> bounds; bool isEntry() const; };
using ObjectId = unsigned;                           // alloca, global, heap site, SROA field column
enum class ObjClass : uint8_t { Classical, Slot, Qram };   // QROM is a load kind on a Classical object
enum class OffsetKind : uint8_t { Classical, Quantum };
struct TaintOptions { std::vector<abi::CloneSpec> roots; }; // library-build and stress roots
class TaintInfo {
public:
  bool isQuantum(const llvm::Value *, const Specialization &) const;
  llvm::SmallVector<bool, 4> fieldMask(const llvm::Value *, const Specialization &) const;
  bool isTainted(const llvm::Function &) const;
  // A1: control dependence on tainted terminators is taint's answer (rules 3, 9, 20).
  bool controlTainted(const llvm::BasicBlock *, const Specialization &) const;
  llvm::ArrayRef<Specialization> specializations() const;
  const Specialization *calleeSpecialization(const llvm::CallBase &, const Specialization &caller) const;
  bool resultQuantum(const Specialization &, unsigned field) const;   // per-clone record (rule 18)
  // T2 (cq-arch 2026-11-01): the pointee cells (ascending cell indices of the object argNo points to) that
  // the clone `callee` may store a handle into (rules 18, 20); empty for a non-pointer formal.
  llvm::SmallVector<unsigned, 4> cellsWritten(const Specialization &callee, unsigned argNo) const;
  // T3 (cq-arch 2026-11-01, CR rules 5, 18, 20): the pointee cells (ascending cell indices of the object
  // argNo points to, at the size of the access) that the clone `callee` may apply a non-diagonal gate to
  // (cq_theta through the formal or a pointer derived from it); empty for a non-pointer formal.
  // Unimplemented: a variable offset, accesses of several sizes, an escape of the formal.
  llvm::SmallVector<unsigned, 4> cellsRotated(const Specialization &callee, unsigned argNo) const;
  ObjectId objectOf(const llvm::Value *siteOrGlobal) const;
  ObjClass classOf(ObjectId) const;
  bool mayHoldHandle(ObjectId) const;
  OffsetKind offsetKind(const llvm::Instruction *access, const Specialization &) const;
  llvm::ArrayRef<ObjectId> provenance(const llvm::Value *ptr, const Specialization &) const;
  bool isFatPointer(const llvm::Value *ptr, const Specialization &) const;
  void print(llvm::raw_ostream &) const;                               // -cq-dump-taint
  // K1: storage owned by module taint; computeTaint builds it.
private:
  struct Impl; std::shared_ptr<Impl> impl;
  friend TaintInfo computeTaint(llvm::Module &, const TaintOptions &);
};
TaintInfo computeTaint(llvm::Module &, const TaintOptions &);
}
