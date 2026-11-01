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
// CR §1.4, rule 20 (95, 109): a load of the variadic save area lowerVarargs spilled handles into (a read
// by -O1's va_arg code): the slot's handle, recorded as a cell load over the actuals' rails; true when
// ld reads such an area. Consumer: mem-slots lowerSlotLoad.
bool lowerVaAreaLoad(LoweringContext &, llvm::LoadInst &);
// Is o a variadic save area lowerVarargs spilled handles into (real host memory holding handles: its
// address arithmetic is classical and copied, 95)? Consumer: spine Dispatch.
bool isVaArea(LoweringContext &, ObjectId o);
void lowerAsm(LoweringContext &, llvm::CallBase &);
void emitTwin(LoweringContext &, llvm::CallBase &lowered);
// C1 (cq-arch 2026-11-01, CR rule 24; 106): site lowered as a direct call of T.calleeSpecialization(site, S),
// formal k = site operand argMap[k] (pthread_create(t, attr, f, p): argMap = {3}); M1, recordCall and the
// twin as for a plain clone call. site's own result is not bound (the consumer binds it). Consumer: eff-conc.
void lowerLiftedVia(LoweringContext &, llvm::CallBase &site, llvm::ArrayRef<unsigned> argMap);
void finalize(llvm::Module &);
// cq-nqa6 (CR §1.4 _ctl, rule 10; 117): a string function attribute a _ctl clone carries when its lowering
// relied on its entry flag (formal 0) naming no rail the clone reaches otherwise (rot-cry: a controlled Ry
// on a cell or formal under it). finalize checks that at every call site (the flag a rail minted and kept
// to gate calls, a cell of a local slot array whose address does not escape and whose rails no other
// actual names, or a marked caller's own entry flag), cq::unimplemented otherwise, and removes it.
inline constexpr const char *kCtlDistinctAttr = "cq-ctl-distinct";
}
