// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module uncompute (cq-w0-uncompute).
#include "cq/Uncompute.h"

namespace cq {
RailId Uncompute::recordTemplate(llvm::CallInst *, const abi::TemplateSpec &, llvm::ArrayRef<Operand>) { unimplemented("uncompute: Uncompute::recordTemplate"); }
RailId Uncompute::recordCore(llvm::CallInst *, const abi::CoreSpec &, llvm::ArrayRef<Operand>, RailId) { unimplemented("uncompute: Uncompute::recordCore"); }
RailId Uncompute::recordSeed(llvm::CallInst *) { unimplemented("uncompute: Uncompute::recordSeed"); }
RailId Uncompute::recordExternal(llvm::Value *, Role) { unimplemented("uncompute: Uncompute::recordExternal"); }
RailId Uncompute::idOf(llvm::Value *) const { unimplemented("uncompute: Uncompute::idOf"); }
void Uncompute::setRole(RailId, Role) { unimplemented("uncompute: Uncompute::setRole"); }
void Uncompute::noteUse(RailId, llvm::Instruction *) { unimplemented("uncompute: Uncompute::noteUse"); }
void Uncompute::noteNonDiagonal(RailId, llvm::Instruction *) { unimplemented("uncompute: Uncompute::noteNonDiagonal"); }
void Uncompute::cleanupBijective(RailId, const abi::TemplateSpec &, llvm::ArrayRef<Operand>) { unimplemented("uncompute: Uncompute::cleanupBijective"); }
void Uncompute::flushBefore(llvm::Instruction *) { unimplemented("uncompute: Uncompute::flushBefore"); }
void Uncompute::flushAtExit(llvm::ReturnInst *) { unimplemented("uncompute: Uncompute::flushAtExit"); }
unsigned Uncompute::openScope() { unimplemented("uncompute: Uncompute::openScope"); }
void Uncompute::closeScope(unsigned) { unimplemented("uncompute: Uncompute::closeScope"); }
llvm::ArrayRef<Record> Uncompute::scopeRecords(unsigned) const { unimplemented("uncompute: Uncompute::scopeRecords"); }
void Uncompute::emitMirror(unsigned, llvm::IRBuilder<> &) { unimplemented("uncompute: Uncompute::emitMirror"); }
} // namespace cq
