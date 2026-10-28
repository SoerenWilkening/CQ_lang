// Module spine (cq-w0-construct): private declarations shared by the spine's files.
//
// CONTRACT of LoweringContext (Lowering.h is frozen, so what its callers may rely on is stated here)
//
//  - Values. operand(orig) maps a value of the ORIGINAL function to the new IR: a rail handle
//    (Operand::handle) or a classical value. Constants map to themselves. A quantum value whose rail
//    was measured at a point that dominates the instruction being lowered maps to the classical
//    outcome (rule 2: dominated uses of the measured value denote the outcome). bind(orig, v) binds
//    one field; v is a handle iff taint says orig is quantum. bindFields binds several.
//  - emitTemplate(spec, ops, orig) declares the template (abi::declare), emits the forward call at
//    the builder, RECORDS it in Uncompute (recordTemplate), appends it to every open gate log and
//    binds orig (when given) to the fresh rail. Its result is the fresh rail's handle.
//  - emitCore(spec, args) declares and emits a core gate and appends it to every open gate log. It
//    records NOTHING: the caller records reversible core gates itself (recordSeed, recordCore) and
//    notes non-diagonal ones (noteNonDiagonal).
//  - Uncompute is driven in the OUTPUT point space: noteUse consumers and flushBefore points are
//    instructions of out(). The spine calls flushBefore before a block's real terminator only where
//    no later original instruction can read a rail defined in that block, and flushAtExit at every
//    return of an entry function.
//  - currentPredicate() is the quantum part of the block predicate of the original block being
//    lowered; currentFlag() is preds().flag() of it, nullptr when it is top.
//  - The walker (Construct.cpp) linearizes quantum branches: a br/switch on a quantum condition is
//    handed to pred (lowerBranch) or switch (sw::lowerSwitch), which emit NO terminator; the spine
//    then falls through to the next block of the linear order. Classical terminators stay classical
//    branches with their successors redirected along that order.
//  - A loop that is not purely classical is dispatched as a unit (loops::lowerClassical /
//    loops::lowerCutoff) at its header. On return the builder must sit in the block where the loop's
//    single exit block continues.
//  - cq_invert: at __cq_invert_begin the spine calls invert::lowerRegion(begin, end) and skips the
//    instructions up to and including the matching end (same block).
#pragma once

#include <map>
#include <memory>
#include <optional>
#include <vector>

#include "cq/Calls.h"
#include "cq/Lowering.h"
#include "cq/Loops.h"
#include "cq/Predicate.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"

namespace cq::spine {

// Rule 2 classical collapse: the basis-value history of one rail minted by emitTemplate or by an
// emitCore alloc. `def` is the minting call. A template rail is f(ops) of its record (orig, when the
// template stands for exactly that original instruction, gives the classical recomputation); a seed is
// its alloc literal. `writes` are the in-place XOR-type core gates on it since (not_i1, xor_i1,
// and_i1, or_i1, copy, xorc, controlled forms), in emission order. A non-diagonal gate on it
// (ry, ry_qangle) makes it opaque: its value is no function of basis values.
struct RailHist {
  llvm::CallInst *def = nullptr;
  bool tmpl = false;
  abi::TemplateSpec spec;
  llvm::SmallVector<Operand, 3> ops;
  const llvm::Value *orig = nullptr;
  llvm::Value *seed = nullptr;
  struct Write { abi::CoreSpec spec; llvm::SmallVector<llvm::Value *, 3> args; llvm::CallInst *call; };
  std::vector<Write> writes;
  bool opaque = false;
};

// What every LoweringContext of one construct() run shares (an inlined callee's context included).
struct Shared {
  llvm::Module &M;
  const loops::KOptions &KO;
  llvm::Function *orig = nullptr;      // S.F of the construct() run
  llvm::Function *out = nullptr;       // where the new IR goes
  llvm::IRBuilder<> B;
  llvm::DenseMap<const llvm::Value *, llvm::SmallVector<Operand, 4>> binds;
  llvm::DenseMap<const llvm::BasicBlock *, llvm::BasicBlock *> blocks;
  std::unique_ptr<Uncompute> unc;
  std::unique_ptr<PathPredicates> preds;
  std::optional<Pred> curPred;
  std::vector<std::vector<llvm::CallInst *>> gateLogs;   // open logs, by token
  std::vector<bool> gateLogOpen;
  // Rule 2: rail handle -> (the original cq_measure call, the classical outcome).
  llvm::DenseMap<const llvm::Value *, std::pair<const llvm::Instruction *, llvm::Value *>> measured;
  // Rule 2 classical collapse (Collapse.cpp): how each rail the spine's emitters minted got its
  // basis value, and the classical recomputations already emitted.
  llvm::DenseMap<const llvm::Value *, RailHist> hist;
  llvm::DenseMap<const llvm::Value *, llvm::Value *> collapsed;
  // Dominance over the original function(s): one tree per function read.
  std::map<const llvm::Function *, std::unique_ptr<llvm::DominatorTree>> dts;
  // The original instruction being lowered, and for an inlined callee the call it stands for.
  const llvm::Instruction *cur = nullptr;
  std::vector<const llvm::CallBase *> inlineStack;

  Shared(llvm::Module &M, const loops::KOptions &KO) : M(M), KO(KO), B(M.getContext()) {}
  llvm::DominatorTree &dt(const llvm::Function &F);
  // Does the original instruction `def` dominate the instruction being lowered?
  bool dominatesCurrent(const llvm::Instruction *def);
};

// A context for an inlined callee: the same Shared state, the callee's specialization (Context.cpp).
std::unique_ptr<LoweringContext> childContext(LoweringContext &parent, const Specialization &S);
Shared &shared(LoweringContext &);
// CR rule 6 after an original instruction is lowered (Opcode.cpp).
void ruleSixAfter(LoweringContext &, llvm::Instruction &);

// Rule 2 classical collapse (Collapse.cpp, contract at its top). noteTemplate/noteCore keep the
// histories (called by emitTemplate/emitCore); collapse returns the classical value a rail holds at
// the builder's point when it depends only on measured rails and classical values, else nullptr.
void noteTemplate(Shared &, llvm::CallInst *fwd, const abi::TemplateSpec &, llvm::ArrayRef<Operand>,
                  const llvm::Value *orig);
void noteCore(Shared &, llvm::CallInst *call, const abi::CoreSpec &, llvm::ArrayRef<llvm::Value *>);
llvm::Value *outcomeAt(Shared &, llvm::Value *handle);
llvm::Value *collapse(LoweringContext &, llvm::Value *handle);

// Binds orig to an operand with an explicit kind (classical collapse binds a quantum orig classically).
void bindOperand(LoweringContext &, const llvm::Value *orig, Operand op);

// The instruction dispatcher of the general construction (Dispatch.cpp). Terminators and phis of the
// walked function are the walker's; dispatch handles every other instruction.
void dispatch(LoweringContext &, llvm::Instruction &);

// Classical copy of an original instruction into the new IR, operands remapped (Dispatch.cpp).
llvm::Instruction *copyClassical(LoweringContext &, llvm::Instruction &);

// Rule 19 inline of an in-module entry callee returning an unmeasured quantum value (Dispatch.cpp).
void lowerInline(LoweringContext &, llvm::CallBase &, const Specialization &callee);

// Is v (an original value) quantum in this context's specialization?
bool isQ(LoweringContext &, const llvm::Value *v);
bool anyQuantumOperand(LoweringContext &, const llvm::Instruction &);

} // namespace cq::spine
