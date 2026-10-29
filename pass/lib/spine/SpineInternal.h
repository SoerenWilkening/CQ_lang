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
//  - lowerInstruction(ctx, I) (cq-ofn6) is dispatch for a loop module lowering its body: I is an
//    original non-phi, non-terminator instruction; for its duration the walker's per-instruction state
//    is set from I (the current instruction, for rule 2 dominance, and currentPredicate() = the quantum
//    part of preds().block(I.getParent())); both are restored on return, so after it the loop module
//    sees its unit's state again. No rule 6 (ruleSixAfter): inside a rule-14 trip the mirror reads
//    every old value. A cq_invert marker is an internal error (dispatch: the walker brackets regions).
//  - lowerInstruction(ctx, I, tripFlag) (cq-99f7) is the same dispatch under a rule-14 trip: tripFlag
//    is an i1 rail the loop module owns and recorded (its trip predicate a_j; nullptr = none, which is
//    the two-argument form). For the call, currentFlag() is tripFlag when the block predicate's quantum
//    part is top, else the conjunction tripFlag & flag(quantum part): a fresh i1 rail (alloc 0, and_i1)
//    the spine mints once per call at the first request and records in Uncompute (recordSeed,
//    recordCore), so it is torn down like any pred flag (rule 9 inner-arm phase, 152). A classical-angle
//    cq_phi is rz_i1 on currentFlag(): rule 12's global-phase deletion never applies under a trip.
//    currentPredicate() is unchanged (the block's quantum part): a consumer that tests it for top to
//    decide "uncontrolled" does not see the trip (cq-hmv1); currentFlag() is the control.
//  - lowerInstruction on an I that is already bound (cq-lx8f) replaces its binding: an unrolled
//    rule-14 trip re-lowers the body. The old rails stay recorded in Uncompute and flush normally.
//  - A quantum phi of a unit's exit block that is unbound when the unit starts and bound when the
//    loop module returns (cq-lx8f: an exit phi it identified with a carried value's final state) is
//    not merged by the walker; it keeps the loop module's binding. Any other phi bound before the
//    walker reaches it is an internal error (bound twice).
//  - rebind(orig, ops) (cq-ofn6) replaces orig's binding, which must exist (internal error
//    otherwise): a loop module rebinds each loop value read after the loop to its exit value (rule 14
//    case 1 copy-out, case 3 captured value). The kinds are the caller's; the old rails stay recorded.
//  - cq_invert: at __cq_invert_begin the spine calls invert::lowerRegion(begin, end), end being the
//    matching end in the same block or else the first __cq_invert_end of a later block of the linear
//    order; it skips every original instruction from begin to end (the region's blocks emit nothing of
//    their own and continue in the current output block).
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
  // Rule 10 state preparation: the original values lowered as a register's state (a classical-angle
  // cq_theta routed to rot::lowerControlledTheta, a phi routed to rot::lowerStatePrepMerge). A
  // quantum phi with one of them among its incomings is a state-prep merge, never a select (cq-gtcn).
  llvm::DenseSet<const llvm::Value *> statePreps;
  // Dominance over the original function(s): one tree per function read.
  std::map<const llvm::Function *, std::unique_ptr<llvm::DominatorTree>> dts;
  // The original instruction being lowered, and for an inlined callee the call it stands for.
  const llvm::Instruction *cur = nullptr;
  // cq-99f7: the loop module's trip rail for the lowerInstruction call in progress (nullptr = none),
  // and the conjunction flag minted for it (nullptr until currentFlag() asks under a non-top predicate).
  llvm::Value *tripFlag = nullptr;
  llvm::Value *tripConj = nullptr;
  std::vector<const llvm::CallBase *> inlineStack;
  // cq-s32y: a register's pre-rotation value read after its in-place rotation reads a copy taken
  // just before the Ry (PreRotation.cpp). orig -> (the cq_theta, the rotated rail h, the copy c, the
  // original blocks reachable from the cq_theta's end without redefining orig).
  struct PreRot {
    const llvm::Instruction *T = nullptr;
    llvm::Value *h = nullptr;
    llvm::Value *c = nullptr;
    llvm::DenseSet<const llvm::BasicBlock *> reach;
  };
  llvm::DenseMap<const llvm::Value *, PreRot> preRot;
  // cq-nvfi: every non-diagonal gate (ry, ry_qangle, controlled or not) on a rail, in emission order.
  llvm::DenseMap<const llvm::Value *, llvm::SmallVector<llvm::CallInst *, 2>> rotations;

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

// cq-s32y (PreRotation.cpp). Before a cq_theta on an existing rail h is lowered: when a use of its
// operand v (or of another value bound to h) is not before the rotation, h is copied into a fresh
// rail c (alloc 0, copy_<W>), returned for finishPreRotation, which rebinds v to c after the
// lowering emitted the Ry on h. A use is before the rotation when it is lowered already, or (a phi's
// incoming) its edge is not reachable from the cq_theta without passing v's definition.
struct PendingCopy {
  const llvm::Value *v = nullptr;
  Shared::PreRot rec;
};
std::optional<PendingCopy> beginPreRotation(LoweringContext &, llvm::CallInst &theta);
void finishPreRotation(LoweringContext &, std::optional<PendingCopy> &);
// The operand a phi being lowered (Shared::cur) reads for orig: a value copied before a rotation is
// the rotated rail itself on edges that are not after the rotation (the register a merge names).
Operand atPhiEdge(Shared &, const llvm::Value *orig, Operand bound);

// Binds orig to an operand with an explicit kind (classical collapse binds a quantum orig classically).
void bindOperand(LoweringContext &, const llvm::Value *orig, Operand op);

// The instruction dispatcher of the general construction (Dispatch.cpp). Terminators and phis of the
// walked function are the walker's; dispatch handles every other instruction.
void dispatch(LoweringContext &, llvm::Instruction &);

// Classical copy of an original instruction into the new IR, operands remapped (Dispatch.cpp).
llvm::Instruction *copyClassical(LoweringContext &, llvm::Instruction &);

// Rule 19 inline of an in-module entry callee returning an unmeasured quantum value (Dispatch.cpp).
void lowerInline(LoweringContext &, llvm::CallBase &, const Specialization &callee);

// Rule 20, _Bool cells (cq-sj2j): is this original load or store an access of a _Bool slot object,
// whose cells hold i1 rails behind i8 memory? The object's definition is mem-slots' (Slots.cpp,
// boolCells): the access goes to mem-slots (one slot object), and every load or store of that object
// in the function is an i8 load carrying !range [0, 2) or an i8 store of a zext from i1 or of the
// constant 0 / 1 (Dispatch.cpp).
bool boolCellAccess(LoweringContext &, const llvm::Instruction &access);

// Is v (an original value) quantum in this context's specialization?
bool isQ(LoweringContext &, const llvm::Value *v);
bool anyQuantumOperand(LoweringContext &, const llvm::Instruction &);

} // namespace cq::spine
