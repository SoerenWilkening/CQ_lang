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
                       void lowerNoreturn(LoweringContext &, llvm::CallBase &); }
namespace cq::invert { void lowerRegion(LoweringContext &, llvm::CallInst &begin, llvm::CallInst &end);
                       // I1 (cq-arch, cq-xjw2): the body of an _adj clone (S.adj): F's whole body (one void
                       // return) as one region; formals bound, preds computed, builder at the end of the
                       // clone's empty entry block; emits ret void and flushAtExit.
                       void lowerAdjointBody(LoweringContext &, llvm::Function &F); }
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
namespace cq::conc   { void lowerAtomic(LoweringContext &, llvm::Instruction &);
                       void lowerVolatile(LoweringContext &, llvm::Instruction &);
                       void lowerThreadCall(LoweringContext &, llvm::CallBase &);
                       void lowerSetjmp(LoweringContext &, llvm::CallBase &);
                       void lowerLongjmp(LoweringContext &, llvm::CallBase &); }
