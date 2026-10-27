// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module spine (cq-w0-construct): Lowering.h, loops::classify, calls::classify.
#include "cq/Calls.h"
#include "cq/Lowering.h"
#include "cq/Loops.h"
#include "cq/Predicate.h"

namespace cq {
LoweringContext::LoweringContext(llvm::Module &M, const TaintInfo &T, const Specialization &S) : M(M), T(T), S(S) { unimplemented("spine: LoweringContext::LoweringContext"); }
llvm::Function &LoweringContext::out() { unimplemented("spine: LoweringContext::out"); }
llvm::IRBuilder<> &LoweringContext::B() { unimplemented("spine: LoweringContext::B"); }
Operand LoweringContext::operand(const llvm::Value *) { unimplemented("spine: LoweringContext::operand"); }
llvm::Value *LoweringContext::rail(const llvm::Value *) { unimplemented("spine: LoweringContext::rail"); }
llvm::SmallVector<Operand, 4> LoweringContext::fields(const llvm::Value *) { unimplemented("spine: LoweringContext::fields"); }
void LoweringContext::bind(const llvm::Value *, llvm::Value *) { unimplemented("spine: LoweringContext::bind"); }
void LoweringContext::bindFields(const llvm::Value *, llvm::ArrayRef<Operand>) { unimplemented("spine: LoweringContext::bindFields"); }
llvm::BasicBlock *LoweringContext::block(const llvm::BasicBlock *) { unimplemented("spine: LoweringContext::block"); }
llvm::Value *LoweringContext::emitTemplate(const abi::TemplateSpec &, llvm::ArrayRef<Operand>, const llvm::Value *) { unimplemented("spine: LoweringContext::emitTemplate"); }
llvm::CallInst *LoweringContext::emitCore(const abi::CoreSpec &, llvm::ArrayRef<llvm::Value *>) { unimplemented("spine: LoweringContext::emitCore"); }
PathPredicates &LoweringContext::preds() { unimplemented("spine: LoweringContext::preds"); }
Uncompute &LoweringContext::unc() { unimplemented("spine: LoweringContext::unc"); }
const Pred &LoweringContext::currentPredicate() const { unimplemented("spine: LoweringContext::currentPredicate"); }
llvm::Value *LoweringContext::currentFlag() { unimplemented("spine: LoweringContext::currentFlag"); }
unsigned LoweringContext::beginGateLog() { unimplemented("spine: LoweringContext::beginGateLog"); }
std::vector<llvm::CallInst *> LoweringContext::endGateLog(unsigned) { unimplemented("spine: LoweringContext::endGateLog"); }
unsigned LoweringContext::K(const llvm::Loop *) const { unimplemented("spine: LoweringContext::K"); }
void construct(llvm::Module &, const TaintInfo &, const Specialization &) { unimplemented("spine: construct"); }
void lowerOpcode(LoweringContext &, llvm::Instruction &) { unimplemented("spine: lowerOpcode"); }
void lowerTheta(LoweringContext &, llvm::CallInst &) { unimplemented("spine: lowerTheta"); }
void lowerMeasure(LoweringContext &, llvm::CallInst &) { unimplemented("spine: lowerMeasure"); }
} // namespace cq

namespace cq::loops {
Case classify(const llvm::Loop &, const TaintInfo &, const Specialization &) { unimplemented("spine: loops::classify"); }
} // namespace cq::loops

namespace cq::calls {
Class classify(const llvm::CallBase &, const TaintInfo &, const Specialization &) { unimplemented("spine: calls::classify"); }
} // namespace cq::calls
