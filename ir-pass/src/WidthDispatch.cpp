// WidthDispatch.cpp — i32/si32-only symbol/type resolver. See header for
// the contract and the M13 evolution path.

#include "WidthDispatch.h"

#include "llvm/IR/DerivedTypes.h"

using namespace llvm;

namespace cq {

WidthDispatch::WidthDispatch(Module &mod)
    : M(mod), I32(Type::getInt32Ty(mod.getContext())) {}

Function *WidthDispatch::initFn() const { return M.getFunction("cq_init_si32"); }

Function *WidthDispatch::measureFn() const {
  return M.getFunction("cq_measure_si32");
}

FunctionCallee WidthDispatch::allocFn() const {
  return M.getOrInsertFunction("cqrt_alloc_i32",
                               FunctionType::get(I32, {I32}, false));
}

FunctionCallee WidthDispatch::measureRtFn() const {
  return M.getOrInsertFunction("cqrt_measure_i32",
                               FunctionType::get(I32, {I32}, false));
}

FunctionCallee WidthDispatch::addTemplate(bool isHL) const {
  // Q+Q (`cq_template_add_i32`) and Q+C (`..._hl`) are distinct C symbols
  // because C lacks overloading; both lower to the same trace prefix at
  // the runtime side (the bare-int vs `h%d` format disambiguates). The
  // signatures are identical at the i32 ABI: handle, handle/literal → handle.
  const char *Name = isHL ? "cq_template_add_i32_hl" : "cq_template_add_i32";
  return M.getOrInsertFunction(Name, FunctionType::get(I32, {I32, I32}, false));
}

bool WidthDispatch::isMidStruct(StructType *ST) const {
  if (!ST)
    return false;
  // Phase 2 M15 will generalize to the 14-struct table; for M12 only
  // `qint_mid_t` is recognized. Identified-struct name comparison is
  // what the rewriter+Clang emit, so a literal/anonymous struct never
  // matches (intentional — those aren't mid-structs).
  return ST->hasName() && ST->getName() == "qint_mid_t";
}

ArrayRef<StringRef> WidthDispatch::frontEndIntrinsicNames() const {
  static const StringRef Names[] = {"cq_init_si32", "cq_measure_si32"};
  return Names;
}

}  // namespace cq
