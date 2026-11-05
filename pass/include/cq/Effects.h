// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include <array>

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"

// Effects.h  (rules 16, 17, 23, 24)
namespace cq::tape   { void lowerHostEffect(LoweringContext &, llvm::CallBase &);
                       // Rule 19: main returning the rail r: the effect entry exit under an alloc_i1(true) seed.
                       void lowerMainExit(LoweringContext &, Operand r, llvm::Type *ty);
                       void lowerNoreturn(LoweringContext &, llvm::CallBase &);
                       // cq-a63l (CR rule 16, "a result the program reads"; amendment on cq-arch): before
                       // the final taint, a deferred printf/fprintf (a host effect of some specialization)
                       // whose count the program reads or whose format may hold %n gets the library's
                       // formatting body on a null buffer, snprintf(0, 0, fmt, args...), in front of it;
                       // the count's uses read that call (lifted by rule 18, or a rule 27 declared clone).
                       // True when the module changed (taint is then recomputed).
                       bool rewriteDeferredResults(llvm::Module &, const TaintInfo &);
                       // cq-lyzw (CR rule 24 at f684858): an observable volatile store with quantum data,
                       // the rule-16 effect entry `volatile_store` under the predicate: its address field
                       // (an i64, literal when classical), then the stored value's fields (its lanes).
                       void lowerVolatileStore(LoweringContext &, llvm::StoreInst &, Operand address); }
namespace cq::invert { // cq-4593 (cq-arch 2026-11-02, CR rule 17, §1.3): a __cq_invert_begin/_end call becomes
                       // cqrt_invert_begin/_end where the walker reaches it (the region's code is lowered as
                       // anywhere else); CQ.h's asm fence beside a marker (isMarkerFence) emits nothing.
                       void lowerMarker(LoweringContext &, llvm::CallInst &marker);
                       bool isMarkerFence(const llvm::Instruction &); }
namespace cq::fenv   { void lowerConstrained(LoweringContext &, llvm::CallBase &);
                       void lowerFenvCall(LoweringContext &, llvm::CallBase &);
                       // cq-xu2l (freeze amendment on cq-arch): after every lowered cq_measure, the
                       // rule 2 collapse of the rule 23 fenv state; a no-op without quantum fenv state.
                       void afterMeasure(LoweringContext &, llvm::CallInst &measure);
                       // cq-hzji (amendment on cq-arch; CR rule 23): at each return of an entry, with the
                       // builder where the return is emitted and before flushAtExit: the fenv state there is
                       // final (kept, or copied out when a merge or superseded on another path).
                       void atEntryReturn(LoweringContext &, llvm::ReturnInst &orig);
                       // E1 (cq-ibkc, freeze amendment on cq-arch; CR rule 23, 82): the clone ABI of the
                       // environment. Contract at the end of eff/fenv/Fenv.cpp: a clone of S that carries it
                       // takes (mode, flags) as two trailing i32 parameters and returns the new flags handle
                       // as its result's last field. Decided on the run's taint T (cq-xhv4: a callee reached
                       // by an ordinary classical call is the host's, not followed).
                       bool cloneCarriesEnv(const TaintInfo &T, const Specialization &S);
                       std::array<Operand, 2> envArgs(LoweringContext &, llvm::CallBase &site);
                       void afterCloneCall(LoweringContext &, llvm::CallBase &site, llvm::Value *flagsOut);
                       void bindCloneEnv(LoweringContext &, llvm::Argument *mode, llvm::Argument *flags);
                       llvm::Value *cloneExitFlags(LoweringContext &, llvm::ReturnInst &); }
namespace cq::conc   { void lowerVolatile(LoweringContext &, llvm::Instruction &);
                       void lowerThreadCall(LoweringContext &, llvm::CallBase &);
                       void lowerSetjmp(LoweringContext &, llvm::CallBase &);
                       void lowerLongjmp(LoweringContext &, llvm::CallBase &); }
