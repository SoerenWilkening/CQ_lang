// CR rule 24: setjmp and longjmp by attribute and name, and the one pairing by operand (Setjmp.cpp; the C oracle).
#pragma once

#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstrTypes.h"

namespace cq::conc {

inline bool isLongjmpCall(const llvm::CallBase &CB) {
  const llvm::Function *G = CB.getCalledFunction();
  if (!G || !G->isDeclaration() || CB.arg_size() != 2 || !CB.getArgOperand(0)->getType()->isPointerTy() ||
      !CB.getArgOperand(1)->getType()->isIntegerTy())
    return false;
  llvm::StringRef n = G->getName();
  return n == "longjmp" || n == "_longjmp" || n == "siglongjmp" || n == "__longjmp_chk";
}

// setjmp, _setjmp, sigsetjmp, __sigsetjmp: returns_twice, the jmp_buf its first argument, an int result.
inline bool isSetjmpCall(const llvm::CallBase &CB) {
  const llvm::Function *G = CB.getCalledFunction();
  return (CB.hasFnAttr(llvm::Attribute::ReturnsTwice) || (G && G->hasFnAttribute(llvm::Attribute::ReturnsTwice))) &&
         !CB.isInlineAsm() && CB.arg_size() >= 1 && CB.getArgOperand(0)->getType()->isPointerTy() &&
         CB.getType()->isIntegerTy();
}

// G internal, exactly one setjmp with G as its operand, and every other use of G in the module the operand of a longjmp.
inline bool isPairedJmpBuf(const llvm::GlobalVariable &G) {
  if (!G.hasLocalLinkage())
    return false;
  unsigned setjmps = 0;
  for (const llvm::Use &U : G.uses()) {
    auto *CB = llvm::dyn_cast<llvm::CallBase>(U.getUser());
    if (!CB || U.getOperandNo() != 0)
      return false;
    if (isSetjmpCall(*CB))
      ++setjmps;
    else if (!isLongjmpCall(*CB))
      return false;
  }
  return setjmps == 1;
}

} // namespace cq::conc
