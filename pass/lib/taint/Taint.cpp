// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module taint (cq-w0-taint).
#include "cq/Taint.h"

namespace cq {
bool Specialization::isEntry() const { unimplemented("taint: Specialization::isEntry"); }
bool TaintInfo::isQuantum(const llvm::Value *, const Specialization &) const { unimplemented("taint: TaintInfo::isQuantum"); }
llvm::SmallVector<bool, 4> TaintInfo::fieldMask(const llvm::Value *, const Specialization &) const { unimplemented("taint: TaintInfo::fieldMask"); }
bool TaintInfo::isTainted(const llvm::Function &) const { unimplemented("taint: TaintInfo::isTainted"); }
bool TaintInfo::controlTainted(const llvm::BasicBlock *, const Specialization &) const { unimplemented("taint: TaintInfo::controlTainted"); }
llvm::ArrayRef<Specialization> TaintInfo::specializations() const { unimplemented("taint: TaintInfo::specializations"); }
const Specialization *TaintInfo::calleeSpecialization(const llvm::CallBase &, const Specialization &) const { unimplemented("taint: TaintInfo::calleeSpecialization"); }
bool TaintInfo::resultQuantum(const Specialization &, unsigned) const { unimplemented("taint: TaintInfo::resultQuantum"); }
ObjectId TaintInfo::objectOf(const llvm::Value *) const { unimplemented("taint: TaintInfo::objectOf"); }
ObjClass TaintInfo::classOf(ObjectId) const { unimplemented("taint: TaintInfo::classOf"); }
bool TaintInfo::mayHoldHandle(ObjectId) const { unimplemented("taint: TaintInfo::mayHoldHandle"); }
OffsetKind TaintInfo::offsetKind(const llvm::Instruction *, const Specialization &) const { unimplemented("taint: TaintInfo::offsetKind"); }
llvm::ArrayRef<ObjectId> TaintInfo::provenance(const llvm::Value *, const Specialization &) const { unimplemented("taint: TaintInfo::provenance"); }
bool TaintInfo::isFatPointer(const llvm::Value *, const Specialization &) const { unimplemented("taint: TaintInfo::isFatPointer"); }
void TaintInfo::print(llvm::raw_ostream &) const { unimplemented("taint: TaintInfo::print"); }
TaintInfo computeTaint(llvm::Module &, const TaintOptions &) { unimplemented("taint: computeTaint"); }
} // namespace cq
