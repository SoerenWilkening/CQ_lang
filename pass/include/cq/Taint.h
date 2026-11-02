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
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

// Taint.h  (rule 3; rule 20 classification; rule 21 provenance)
namespace cq {
struct Specialization { llvm::Function *F; Mask mask; bool ctl = false, pure = false, adj = false;
                        unsigned depth = 0; std::vector<uint64_t> bounds; bool isEntry() const;
                        // cq-qc70 (CR §1.4): boundFormals[i] is the formal index bounds[i] bounds (a clone's
                        // name spells only the values; the clone table is keyed by the fields).
                        std::vector<unsigned> boundFormals;
                        // cq-i9wk (CR rule 19): the clone of a callee reached with no quantum argument whose
                        // result is not frozen (calls makes it; taint publishes none): the in-place body as
                        // a clone, its still-allocated registers returned after its results. Taint answers
                        // for it as for the in-place specialization of F (same mask, no flags).
                        bool kept = false; };
using ObjectId = unsigned;                           // alloca, global, heap site, SROA field column
enum class ObjClass : uint8_t { Classical, Slot, Qram };   // QROM is a load kind on a Classical object
enum class OffsetKind : uint8_t { Classical, Quantum };
// T4 (cq-arch 2026-11-01, CR rule 21, §1.4; 190, 191): how a pointer formal of a clone crosses the call.
// Raw: the caller's pointer (31, 122); Triple: (object, tag, i32 idx) (191); TripleCount: the triple then
// the object's i32 cell count (190: the callee loads at a run-time offset into a slot or host object).
enum class PtrAbi : uint8_t { Raw, Triple, TripleCount };
struct PtrFormal {
  PtrAbi abi;
  ObjClass pointee;  // Classical = host cells, Slot = handle cells, Qram = the object is the i32 bus handle
  unsigned digits;   // this formal's mask digits (tag and idx included for a triple)
};
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
  // cq-s2zz (CR rule 19): every candidate taint lifted for an indirect call (or raise's handlers), in its
  // candidate order: the candidate function and its specialization (nullptr: the candidate's untainted,
  // in-place one, an ordinary call; a declaration's is its rule 27 declared clone).
  llvm::SmallVector<std::pair<llvm::Function *, const Specialization *>, 4>
  calleeCandidates(const llvm::CallBase &, const Specialization &caller) const;
  bool resultQuantum(const Specialization &, unsigned field) const;   // per-clone record (rule 18)
  // T2 (cq-arch 2026-11-01): the pointee cells (ascending cell indices of the object argNo points to) that
  // the clone `callee` may store a handle into (rules 18, 20); empty for a non-pointer formal.
  llvm::SmallVector<unsigned, 4> cellsWritten(const Specialization &callee, unsigned argNo) const;
  // T3 (cq-arch 2026-11-01, CR rules 5, 18, 20): the pointee cells (ascending cell indices of the object
  // argNo points to, at the size of the access) that the clone `callee` may apply a non-diagonal gate to
  // (cq_theta through the formal or a pointer derived from it); empty for a non-pointer formal.
  // Unimplemented: accesses of several sizes, an escape of the formal. cq-budv (117): an in-place
  // rotation at a variable offset may hit any cell: the answer is then {kAnyCell} alone.
  static constexpr unsigned kAnyCell = ~0u;
  // cq-4e6m (CR rules 18, 20, 21): does the store st through formal argNo of the clone `callee` lie past every
  // cell of every object that formal may point to (a typed pointee: an access past an object, undefined where it
  // runs, outside the domain)? Such a store writes no cell; cellsWritten counts none for it.
  bool writesPastPointee(const Specialization &callee, unsigned argNo, const llvm::StoreInst &st) const;
  llvm::SmallVector<unsigned, 4> cellsRotated(const Specialization &callee, unsigned argNo) const;
  // T5 (A-taint 2026-11-01, CR rules 18, 20; 109's put): the formal j whose handle the clone `callee` stores
  // UNCHANGED into cell `cell` (as cellsWritten counts it) of the object argNo points to, or -1. Exactly:
  // the clone's only write through argNo is one store, in its entry block, of formal j (a quantum scalar
  // whose only use is that store) at a constant offset from argNo; not a _ctl or _adj clone. The cell then
  // holds the caller's own rail after the call: no copy-out in the clone, no twin for it in the caller.
  int cellForward(const Specialization &callee, unsigned argNo, unsigned cell) const;
  // T4: pointer formal argNo of clone `callee` (non-pointer formal: internal error; pointee objects of
  // mixed class: unimplemented).
  PtrFormal pointerFormal(const Specialization &callee, unsigned argNo) const;
  ObjectId objectOf(const llvm::Value *siteOrGlobal) const;
  // cq-i9wk (CR rules 18, 19, 20): the object of a site as specialization S sees it. A function's own
  // alloca, heap or unknown-object site is one object in its in-place activation (the entry, or a callee
  // reached with no quantum argument) and another in its clones'; the one-argument form is only for a
  // site with one of them (a global, or a function reached in one context).
  ObjectId objectOf(const llvm::Value *siteOrGlobal, const Specialization &S) const;
  ObjClass classOf(ObjectId) const;
  bool mayHoldHandle(ObjectId) const;
  // cq-1c5j (CR rule 20): every cell of the object has one C scalar type (a scalar or an array of scalars, or
  // an object with no C type whose cells are its accesses'), so a slot object's cells are all handle cells
  // (homogeneous) whatever was written before a call; false for a struct (a record: per-field kinds, 163).
  bool uniformCells(ObjectId) const;
  OffsetKind offsetKind(const llvm::Instruction *access, const Specialization &) const;
  llvm::ArrayRef<ObjectId> provenance(const llvm::Value *ptr, const Specialization &) const;
  bool isFatPointer(const llvm::Value *ptr, const Specialization &) const;
  // T6 (cq-hfah, CR rule 20 per cell): ptr names only globals and bytes [off, off + bytes) past it hold a handle
  // in none of them (the per-cell answer the loads' taint uses): a host cell, every access of it classical.
  bool globalHostCell(const llvm::Value *ptr, int64_t off, uint64_t bytes, const Specialization &) const;
  void print(llvm::raw_ostream &) const;                               // -cq-dump-taint
  // K1: storage owned by module taint; computeTaint builds it.
private:
  struct Impl; std::shared_ptr<Impl> impl;
  friend TaintInfo computeTaint(llvm::Module &, const TaintOptions &);
};
TaintInfo computeTaint(llvm::Module &, const TaintOptions &);
}
