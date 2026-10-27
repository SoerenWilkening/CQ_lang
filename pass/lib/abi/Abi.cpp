// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module abi (cq-w0-abi): Abi.h and Common.h's type helpers.
#include "cq/Abi.h"
#include "cq/Common.h"

namespace cq {
RailType railTypeOf(llvm::Type *) { unimplemented("abi: railTypeOf"); }
llvm::Type *irTypeOf(llvm::LLVMContext &, RailType) { unimplemented("abi: irTypeOf"); }
llvm::IntegerType *handleTy(llvm::LLVMContext &) { unimplemented("abi: handleTy"); }
} // namespace cq

namespace cq::abi {
std::string name(const TemplateSpec &, bool) { unimplemented("abi: name(TemplateSpec)"); }
llvm::FunctionCallee declare(llvm::Module &, const TemplateSpec &, bool) { unimplemented("abi: declare(TemplateSpec)"); }
std::optional<TemplateSpec> parseTemplate(llvm::StringRef, bool *) { unimplemented("abi: parseTemplate"); }
std::string name(const CoreSpec &) { unimplemented("abi: name(CoreSpec)"); }
llvm::FunctionCallee declare(llvm::Module &, const CoreSpec &) { unimplemented("abi: declare(CoreSpec)"); }
std::optional<CoreSpec> parseCore(llvm::StringRef) { unimplemented("abi: parseCore"); }
std::string name(const CloneSpec &) { unimplemented("abi: name(CloneSpec)"); }
std::optional<CloneSpec> parseClone(llvm::StringRef) { unimplemented("abi: parseClone"); }
std::string asmCloneFn(const llvm::InlineAsm &) { unimplemented("abi: asmCloneFn"); }
} // namespace cq::abi
