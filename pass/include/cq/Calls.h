// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Module.h"

// Calls.h  (rules 16 classification, 18, 19, 27; classify is spine-owned)
namespace cq::calls {
enum class Class : uint8_t { Classical, Theta, Measure, Phi, InvertBegin, InvertEnd, Lift, Indirect,
  Declared, Asm, HostEffect, Noreturn, Alloc, Dealloc, Realloc, MemIntrinsic, TemplateIntrinsic,
  LibmIntrinsic, Fenv, Thread, Setjmp, Longjmp, Varargs, Atomic };
Class classify(const llvm::CallBase &, const TaintInfo &, const Specialization &);
llvm::Function *materialize(llvm::Module &, const Specialization &);
void lowerLifted(LoweringContext &, llvm::CallBase &);
void lowerIndirect(LoweringContext &, llvm::CallBase &);
void lowerDeclared(LoweringContext &, llvm::CallBase &);
void lowerVarargs(LoweringContext &, llvm::Instruction &);
void lowerAsm(LoweringContext &, llvm::CallBase &);
void emitTwin(LoweringContext &, llvm::CallBase &lowered);
void finalize(llvm::Module &);
}
