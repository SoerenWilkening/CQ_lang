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
  LibmIntrinsic, Fenv, Thread, Setjmp, Longjmp, Varargs, Atomic, Signal, Raise };
Class classify(const llvm::CallBase &, const TaintInfo &, const Specialization &);
llvm::Function *materialize(llvm::Module &, const Specialization &);
void lowerLifted(LoweringContext &, llvm::CallBase &);
void lowerIndirect(LoweringContext &, llvm::CallBase &);
void lowerDeclared(LoweringContext &, llvm::CallBase &);
void lowerVarargs(LoweringContext &, llvm::Instruction &);
void lowerAsm(LoweringContext &, llvm::CallBase &);
// Rule 16 Signal table: signal is the bus load of the cell and the bus store of the handler; raise loads the cell and
// calls through the loaded address rail by rule 19.
void lowerSignal(LoweringContext &, llvm::CallBase &);
void lowerRaise(LoweringContext &, llvm::CallBase &);
// Rule 14, §1.4: the counter of a _ctl clone's live activations and the cut at K, on the clone just constructed. Nothing
// for a clone that is no _ctl clone or a function neither on a call cycle nor with a table clone.
void insertActivationCounter(LoweringContext &);
// Rule 19 extra results: the registers of a clone with a twin, which the twin must not mint again and which come to it instead.
// mintSites: in order, S's cq_theta calls outside a loop and, for a call of a callee that rotates, each register that call hands
// back (a by-name clone's extras) or its own symbol's result rail, when a twin of S runs. noteMint, after the spine lowered a
// cq_theta (`before`: the instruction before its code, or null): tags its code for the twin. mintHandle: at a return, the
// rail, else handle 0 (§1.1). A by-name clone returns them after its results; a table clone pushes them. A table clone with no
// twin (§1.4; its registers may be per trip) lists them as they are minted; pushListedMints, at its return, pushes the list.
struct MintSlot {
  const llvm::CallBase *site;
  unsigned sub;   // the register's index in the call
};
llvm::ArrayRef<MintSlot> mintSites(const TaintInfo &, const Specialization &);
void noteMint(LoweringContext &, llvm::CallInst &site, llvm::BasicBlock *startBlock, llvm::Instruction *before);
llvm::Value *mintHandle(LoweringContext &, const MintSlot &);
void pushListedMints(LoweringContext &);
// The K of the caller's enclosing function (§0): a table clone passes down the K it received.
llvm::Value *enclosingK(LoweringContext &);
// C1 (cq-arch 2026-11-01, CR rule 24; 106): site lowered as a direct call of T.calleeSpecialization(site, S),
// formal k = site operand argMap[k] (pthread_create(t, attr, f, p): argMap = {3}); M1, recordCall and the
// twin as for a plain clone call. site's own result is not bound (the consumer binds it). Consumer: eff-conc.
void lowerLiftedVia(LoweringContext &, llvm::CallBase &site, llvm::ArrayRef<unsigned> argMap);
void finalize(llvm::Module &);
// The run's TaintInfo for materialize, read at the start of each construct().
void noteRun(LoweringContext &);
// Rule 18: the clone of S has a twin: no memory write, no tainted measurement, no effect result read, no register per trip
// (rulings3 F).
bool hasTwin(const TaintInfo &, const Specialization &);
}
