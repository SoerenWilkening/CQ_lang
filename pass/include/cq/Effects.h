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
                       // Rule 19 (BACKEND_ABI §1.11): the effect entry of a callee with no row of the clone table:
                       // a null name, the callee's address the first field, the actuals after it, under flag or an
                       // alloc_i1(true) seed. The result rails it returns are KEPT, none when the program reads none.
                       llvm::SmallVector<llvm::Value *, 2> lowerTableEffect(LoweringContext &, llvm::CallBase &,
                                                                            Operand callee, llvm::Value *flag);
                       // Rule 16 Signal table: raise's complement, the entry `raise` with its one actual as its field.
                       llvm::SmallVector<llvm::Value *, 2> lowerRaiseEffect(LoweringContext &, llvm::CallBase &,
                                                                            llvm::Value *flag);
                       // cq-a63l, owner ruling 2026-11-12 (rule 16): before the final taint, a deferred C library
                       // output call (a host effect of some specialization) whose result the program reads, or
                       // whose format may hold %n, gets in front of it the value musl's body returns when every
                       // write succeeds: a bundle result entry (__cq_count_*, lifted by rule 18) or a template
                       // over the arguments; the result's uses read that value and the effect has no result.
                       // True when the module changed (taint is then recomputed).
                       bool rewriteDeferredResults(llvm::Module &, const TaintInfo &);
                       // Owner ruling 2026-11-13 (CR rule 16 Results): the errno store that belongs to a computed
                       // failure value (fseek, fseeko: whence outside {0, 1, 2}; raise: sig outside [0, 64]), made
                       // at the call (an effect entry, or raise's signal-table call) by ordinary lowered code.
                       void storeFailureErrno(LoweringContext &, llvm::CallBase &); }
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
                       llvm::Value *cloneExitFlags(LoweringContext &, llvm::ReturnInst &);
                       // Owner 2026-11-12 (cq-a9ij3; CR §1.4, rule 23): a clone with a mode word (_rm, _rmq) that
                       // does not carry 82's environment takes the caller's mode as ONE trailing i32 after its
                       // formals (a classical FE_* value for _rm, the mode rail's handle for _rmq); the caller
                       // passes modeArg, the clone binds it at its entry (bindCloneMode). No flags either way.
                       bool cloneTakesMode(const TaintInfo &T, const Specialization &S);
                       Operand modeArg(LoweringContext &, llvm::CallBase &site, const Specialization &callee);
                       void bindCloneMode(LoweringContext &, llvm::Argument *mode); }
namespace cq::conc   { void lowerVolatile(LoweringContext &, llvm::Instruction &);
                       void lowerThreadCall(LoweringContext &, llvm::CallBase &);
                       void lowerSetjmp(LoweringContext &, llvm::CallBase &);
                       void lowerLongjmp(LoweringContext &, llvm::CallBase &); }
