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

// Taint.h  (rule 3; rule 20 Host-resident)
namespace cq {
struct Specialization { llvm::Function *F; Mask mask; bool ctl = false, pure = false;
                        std::vector<uint64_t> bounds; bool isEntry() const;
                        // cq-qc70 (CR §1.4): boundFormals[i] is the formal index bounds[i] bounds (a clone's
                        // name spells only the values; the clone table is keyed by the fields).
                        std::vector<unsigned> boundFormals; };
struct TaintOptions { std::vector<abi::CloneSpec> roots; }; // library-build and stress roots
class TaintInfo {
public:
  bool isQuantum(const llvm::Value *, const Specialization &) const;
  llvm::SmallVector<bool, 4> fieldMask(const llvm::Value *, const Specialization &) const;
  bool isTainted(const llvm::Function &) const;   // Q2: F is rewritten (not its own lowering)
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
  // Rule 20 Host-resident (a)/(b), per specialization (asked per clone): `obj` is an alloca of S.F or a global.
  bool hostResident(const llvm::Value *obj, const Specialization &) const;
  // The host-resident object `access`'s pointer operand reaches through getelementptrs with untainted indices only,
  // else nullptr (rule 20: no pointer is otherwise resolved).
  const llvm::Value *hostObjectOf(const llvm::Instruction &access, const Specialization &) const;
  const llvm::Value *hostObjectOf(const llvm::Value *ptr, const Specialization &) const;
  // Rule 16 Ordinary host call: is the call `called after an event` or preceded by one (least fixpoint)?
  bool afterEvent(const llvm::CallBase &, const Specialization &) const;
  // Rule 19: _ctl needed (anything but templates on SSA values, itself or through callees).
  bool needsCtl(const llvm::Function &) const;
  void print(llvm::raw_ostream &) const;                               // -cq-dump-taint
  // K1: storage owned by module taint; computeTaint builds it.
private:
  struct Impl; std::shared_ptr<Impl> impl;
  friend TaintInfo computeTaint(llvm::Module &, const TaintOptions &);
};
TaintInfo computeTaint(llvm::Module &, const TaintOptions &);
}
