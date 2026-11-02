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
  // CR §1.4 (95, 109): a variadic clone's variadic actuals (its parameters past the fixed formals),
  // a handle where the mask's digit is 1; calls::lowerVarargs spills them at llvm.va_start.
  llvm::SmallVector<Operand, 4> varargs;
  llvm::DenseMap<const llvm::BasicBlock *, llvm::BasicBlock *> blocks;
  llvm::DenseMap<const llvm::Value *, WalkedPtr> walked;   // cq-9w75: walked pointer phis of K-loops
  std::unique_ptr<Uncompute> unc;
  std::unique_ptr<PathPredicates> preds;
  std::optional<Pred> curPred;
  std::vector<std::vector<llvm::CallInst *>> gateLogs;   // open logs, by token
  std::vector<bool> gateLogOpen;
  // Rule 2: rail handle -> (the original cq_measure call, the classical outcome).
  llvm::DenseMap<const llvm::Value *, std::pair<const llvm::Instruction *, llvm::Value *>> measured;
  // cq-ihlt (Collapse.cpp): a rail passed to a rule 18 clone whose callee measures that formal. `call`
  // is the original call, `out` the emitted clone call (nullptr when it could not be identified),
  // `arg` the original actual, `always` whether the callee measures it on every path to a return,
  // `why` a non-empty reason when the re-read is not built for this call.
  struct CalleeMeasure {
    const llvm::Instruction *call = nullptr;
    llvm::CallInst *out = nullptr;
    const llvm::Value *arg = nullptr;
    bool always = false;
    std::string why;
  };
  llvm::DenseMap<const llvm::Value *, CalleeMeasure> calleeMeasured;
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
  // cq-0hhk: a quantum switch's case atoms (rule 13) are its scrutinee's value AT THE SWITCH; pred
  // mints them where a flag or a select reads them. When a cq_theta rotates the scrutinee's rail in
  // place inside the switch's region (PreRotation.cpp), the atoms read a copy taken just before the
  // Ry: scrutinee orig -> that copy. Cleared each time the walker lowers the switch.
  llvm::DenseMap<const llvm::Value *, llvm::Value *> switchSnap;
  // cq-nvfi: every non-diagonal gate (ry, ry_qangle, controlled or not) on a rail, in emission order.
  llvm::DenseMap<const llvm::Value *, llvm::SmallVector<llvm::CallInst *, 2>> rotations;
  // cq-5ajv: for each non-diagonal gate (rotations) and each in-place write (RailHist::writes), the
  // original instruction being lowered when it was emitted, then the inlined call sites outward.
  llvm::DenseMap<const llvm::CallInst *, llvm::SmallVector<const llvm::Instruction *, 2>> gateAt;
  // cq-su3p (Views.cpp): rule 3 representation views of a narrow register. A view phi (iN) merges
  // zexts of one iM register's states and constants: it names the register's rail (bits M) and has
  // no wide rail unless a user needs one (then `binds` holds a zext template of the rail, taken at
  // the phi). A skipped zext (narrowSkipped) has no binding: every user narrows it to its source.
  // A _Bool slot cell load (cq-nd2i) read by a narrowed compare is a view too (cell = true): an i8
  // naming its cell's i1 rail; its binding, when it has one, is mem-slots' zext_i1_to_i8 of the rail.
  // A cell view never takes part in a view phi.
  struct View {
    llvm::Value *rail = nullptr;
    unsigned bits = 0;
    bool cell = false;
  };
  llvm::DenseMap<const llvm::Value *, View> views;
  llvm::DenseSet<const llvm::Value *> narrowSkipped;
  // cq-0umd (Views.cpp): rule 26 packed integers. A value bound field-wise as the fields of an ABI
  // coercion (159: struct { int, int } as one i64) maps here to its field boundaries in bits, low
  // bits first ({0, c1, ..., N}); its binding holds one Operand per field (a handle, or a classical
  // value of the field's width, the constant 0 for a field the packing leaves zero).
  llvm::DenseMap<const llvm::Value *, llvm::SmallVector<unsigned, 4>> packs;
  // A narrowed icmp ne of i1 views, lowered as xor_i1: its two narrow operands (rule 6 reads them).
  llvm::DenseMap<const llvm::Value *, llvm::SmallVector<const llvm::Value *, 2>> narrowXor;
  // CR rule 6: the rails a clean-up was requested for (Opcode.cpp). A template rail reading one of them
  // is no longer garbage rule 5 can uncompute (cq-tmvo).
  llvm::DenseSet<const llvm::Value *> ruleSixCleaned;
  // cq-2ql9 (Opcode.cpp ruleSixRetry): an old value Y whose clean-up against I's image (yp) waits for the
  // garbage rails that still read Y (blockers) to be settled; ctx is the context that lowered I.
  struct PendingSix {
    LoweringContext *ctx;
    llvm::Value *Y;
    llvm::Instruction *I;
    Operand yp;
    llvm::SmallVector<llvm::Value *, 2> blockers;
    // cq-8101: run-time cell loads that may name Y's rail; their reads are noted as Y's uses first.
    llvm::SmallVector<const llvm::Instruction *, 2> loads;
  };
  std::vector<PendingSix> ruleSixPending;
  // cq-su3p (PreRotation.cpp): readers of a register's pre-rotation value that -O1 sank after the
  // cq_theta, lowered just before the rotation. The walker skips them when it reaches them and takes
  // hoistedDefs into the current block's definitions after the dispatch that hoisted them.
  llvm::DenseSet<const llvm::Instruction *> hoisted;
  std::vector<const llvm::Instruction *> hoistedDefs;
  // CR rule 24 (101, eff/conc/Setjmp.cpp): in an escaping clone, the escaped rail its longjmp copied out;
  // in a caller, the escaped rail of each lowered call of an escaping clone (original call -> rail).
  llvm::Value *cloneEscaped = nullptr;
  llvm::DenseMap<const llvm::CallBase *, llvm::Value *> escapedOut;

  Shared(llvm::Module &M, const loops::KOptions &KO) : M(M), KO(KO), B(M.getContext()) {}
  llvm::DominatorTree &dt(const llvm::Function &F);
  // Does the original instruction `def` dominate the instruction being lowered?
  bool dominatesCurrent(const llvm::Instruction *def);
};

// A context for an inlined callee: the same Shared state, the callee's specialization (Context.cpp).
std::unique_ptr<LoweringContext> childContext(LoweringContext &parent, const Specialization &S);
Shared &shared(LoweringContext &);
// cq-8un4 (Context.cpp): the walker brackets each loop unit's loops:: call; LoweringContext::loopUnit()
// reads the innermost one running.
void pushLoopUnit(LoweringContext &, const llvm::Loop &);
void popLoopUnit(LoweringContext &, const llvm::Loop &);
// CR rule 6 after an original instruction is lowered, or a quantum-join phi merged (Opcode.cpp).
void ruleSixAfter(LoweringContext &, llvm::Instruction &);
// cq-2ql9: rule 6 clean-ups ruleSixAfter deferred until the garbage rails reading the old value settle;
// called after every ruleSixAfter (Opcode.cpp).
void ruleSixRetry(LoweringContext &);
// cq-xivx (CR §1.4 _inv<c>, rule 18; Opcode.cpp): rule 6's inverse of one bijective update U of Y,
// the template and its forward operands computing Y from yp (U's value). operandOf resolves U's other
// operands, readsY tells whether one reads Y (then U is no bijection in Y). nullopt: no rule 6 bijection.
struct InverseStep { abi::TemplateSpec spec; llvm::SmallVector<Operand, 3> ops; };
std::optional<InverseStep> inverseStep(llvm::Instruction &U, llvm::Value *Y, Operand yp,
                                       llvm::function_ref<Operand(llvm::Value *)> operandOf,
                                       llvm::function_ref<bool(llvm::Value *)> readsY);

// Rule 2 classical collapse (Collapse.cpp, contract at its top). noteTemplate/noteCore keep the
// histories (called by emitTemplate/emitCore); collapse returns the classical value a rail holds at
// the builder's point when it depends only on measured rails and classical values, else nullptr.
void noteTemplate(Shared &, llvm::CallInst *fwd, const abi::TemplateSpec &, llvm::ArrayRef<Operand>,
                  const llvm::Value *orig);
void noteCore(Shared &, llvm::CallInst *call, const abi::CoreSpec &, llvm::ArrayRef<llvm::Value *>);
llvm::Value *outcomeAt(Shared &, llvm::Value *handle);
llvm::Value *collapse(LoweringContext &, llvm::Value *handle);
// cq-i962: the classical value a rail holds at the builder's point when it is a function of measured
// rails and classical values only, a rail built from classical seeds alone included (a value computed
// after a collapse, 'only from measured rails and classical values', rule 2); else nullptr. Used for
// cq_measure only (CR rule 2: a cq_measure of a value rule 2 made classical is a classical read):
// elsewhere a seeds-only rail stays the quantum control flow's representation.
llvm::Value *classicalRead(LoweringContext &, llvm::Value *handle);
// cq-ihlt (decision A on rule 2): after calls::lowerLifted emitted a clone call, note every rail
// passed to it whose formal the callee measures. calleeCollapse(h, at): when the rail h is classical
// only because a callee measured its quantum sources, emit for each such source a cqrt_measure on its
// rail right after the clone call (a classical re-read of the measured rail, CR rule 2), mark it
// measured, and return h's classical recomputation; nullptr when that does not make h classical.
// `start`/`before`: the output block and the instruction before the builder's point when the call's
// lowering began (nullptr: the block's start).
void noteCalleeMeasures(LoweringContext &, const llvm::CallBase &orig, llvm::BasicBlock *start,
                        llvm::Instruction *before);
llvm::Value *calleeCollapse(LoweringContext &, llvm::Value *handle, const llvm::Instruction &at);

// cq-s32y (PreRotation.cpp). Before a cq_theta on an existing rail h is lowered: when a use of its
// operand v (or of another value bound to h) is not before the rotation, h is copied into a fresh
// rail c (alloc 0, copy_<W>), returned for finishPreRotation, which rebinds v to c after the
// lowering emitted the Ry on h. A use is before the rotation when it is lowered already, or (a phi's
// incoming) its edge is not reachable from the cq_theta without passing v's definition.
// cq-xu07: when v is a load whose cell (or another holder of the cell's rail) may be read after the
// rotation, the Ry hits the copy instead (rotCopy): v is bound to c while the cq_theta is lowered and
// back to h after it, so the cell, v and every other holder keep the unrotated rail.
// cq-6qum: likewise (rotCopy) when the cq_theta is uncontrolled (rule 2, or rule 15: cq-r9j0), v is a
// rule 10 register state (Shared::statePreps) and v is read after the rotation: the register keeps h.
struct PendingCopy {
  const llvm::Value *v = nullptr;
  Shared::PreRot rec;
  bool rotCopy = false;
};
std::optional<PendingCopy> beginPreRotation(LoweringContext &, llvm::CallInst &theta, bool uncontrolled);
void finishPreRotation(LoweringContext &, std::optional<PendingCopy> &);
// The operand a phi being lowered (Shared::cur) reads for orig: a value copied before a rotation is
// the rotated rail itself on edges that are not after the rotation (the register a merge names).
Operand atPhiEdge(Shared &, const llvm::Value *orig, Operand bound);

// cq-su3p, rule 3 representation views (Views.cpp, contract at its top). viewMerge lowers a
// quantum phi that merges zexts of one register's states (rule 10 seen through a representation
// change) and returns true, or returns false when the phi is not one. lowerNarrow lowers a zext,
// trunc or icmp eq/ne that narrows (returns false otherwise). narrowUsers: does every use of v
// narrow (v of iN viewed at bits M)? narrowValue: the original narrow value behind v (its zext
// source, v itself for a view phi or a constant), or nullptr.
bool viewMerge(LoweringContext &, llvm::PHINode &);
bool lowerNarrow(LoweringContext &, llvm::Instruction &);
const llvm::Value *narrowValue(Shared &, const llvm::Value *v, unsigned &bits);
bool narrowUse(LoweringContext &, const llvm::Use &, unsigned bits);
// The uses that read v once skipped zexts are seen through (their users' uses instead).
void readingUses(Shared &, const llvm::Value *v, llvm::SmallVectorImpl<const llvm::Use *> &out);

// cq-0umd, rule 26 packed integers (Views.cpp, contract at its top). lowerPack lowers a quantum
// zext, shl or or-disjoint that packs fields, or a trunc or lshr of a packed value, and returns true;
// false when I is none of these. lowerNarrow calls it first. bindPacked binds orig (an iN) to the
// fields of `cuts` (bit boundaries {0, ..., N}, one Operand per field): field-wise when a field is a
// handle, else as one classical iN rebuilt from the fields (zext, shl, or) at the builder. packFields
// returns the fields of a packed value at the boundaries `cuts`, splitting zero and classical fields
// where needed (a handle field is never split: unimplemented); the value must be packed or classical.
bool lowerPack(LoweringContext &, llvm::Instruction &);
void bindPacked(LoweringContext &, const llvm::Value *orig, llvm::ArrayRef<unsigned> cuts,
                llvm::ArrayRef<Operand> fields);
llvm::SmallVector<Operand, 4> packFields(LoweringContext &, const llvm::Value *v, llvm::ArrayRef<unsigned> cuts);
// The field boundaries of a packed integer as its readers unpack it (a trunc to C bits, an lshr by C,
// a trunc of that lshr: 159's callee formal and caller result), {0, ..., N}; {0, N} when they cut
// nothing. Taint's mask for an integer formal splits it the same way.
llvm::SmallVector<unsigned, 4> unpackCuts(const llvm::Value *v);
// The field boundaries of a packed integer as its writer packs it (taint's resultQuantum reading of a
// returned coercion: or disjoint (shl (zext X), C), (zext Y)), {0, C, N}; {0, N} when it is no packing.
llvm::SmallVector<unsigned, 4> packedCuts(const llvm::Value *v);
// cq-0umd (166, rule 26): per scalar leaf of F's aggregate result type (depth first, as aggr flattens
// it), the field boundaries of that leaf as F's returns pack it (packedCuts of the integer each return's
// insertvalue chain puts there; {0, W} for an integer leaf no return packs, {} for a non-integer leaf).
// Empty when F's result is not an aggregate. Returns that pack a leaf differently: unimplemented.
llvm::SmallVector<llvm::SmallVector<unsigned, 4>, 4> resultLeafCuts(const llvm::Function &F);
// The result's fields in that order: each leaf's type, a packed integer leaf split into its fields.
llvm::SmallVector<llvm::Type *, 4> resultFieldTypes(const llvm::Function &F);

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
