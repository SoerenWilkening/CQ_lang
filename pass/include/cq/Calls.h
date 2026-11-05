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
// C1 (cq-arch 2026-11-01, CR rule 24; 106): site lowered as a direct call of T.calleeSpecialization(site, S),
// formal k = site operand argMap[k] (pthread_create(t, attr, f, p): argMap = {3}); M1, recordCall and the
// twin as for a plain clone call. site's own result is not bound (the consumer binds it). Consumer: eff-conc.
void lowerLiftedVia(LoweringContext &, llvm::CallBase &site, llvm::ArrayRef<unsigned> argMap);
void finalize(llvm::Module &);
// Rule 18: the clone of S has a twin: no memory write, no tainted measurement, no effect result read.
bool hasTwin(const TaintInfo &, const Specialization &);
}
