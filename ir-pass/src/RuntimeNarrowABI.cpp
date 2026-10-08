// RuntimeNarrowABI.cpp — see RuntimeNarrowABI.h (bd test_C_libtooling-r2j3.20).

#include "RuntimeNarrowABI.h"

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

// `bool` → zeroext, `int8_t`/`int16_t` → signext; every other type: none.
Attribute::AttrKind narrowExt(const Type *T) {
  if (T->isIntegerTy(1))
    return Attribute::ZExt;
  if (T->isIntegerTy(8) || T->isIntegerTy(16))
    return Attribute::SExt;
  return Attribute::None;
}

bool isRuntimeSymbol(const Function &F) {
  const StringRef N = F.getName();
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
}

}  // namespace

void annotateRuntimeNarrowABI(Module &M) {
  for (Function &F : M) {
    if (!F.isDeclaration() || !isRuntimeSymbol(F))
      continue;
    FunctionType *FT = F.getFunctionType();
    for (unsigned I = 0, E = FT->getNumParams(); I != E; ++I) {
      const Attribute::AttrKind K = narrowExt(FT->getParamType(I));
      if (K != Attribute::None && !F.hasParamAttribute(I, Attribute::ZExt) &&
          !F.hasParamAttribute(I, Attribute::SExt))
        F.addParamAttr(I, K);
    }
    const Attribute::AttrKind K = narrowExt(FT->getReturnType());
    if (K != Attribute::None && !F.hasRetAttribute(Attribute::ZExt) &&
        !F.hasRetAttribute(Attribute::SExt))
      F.addRetAttr(K);
  }
}

}  // namespace cq
