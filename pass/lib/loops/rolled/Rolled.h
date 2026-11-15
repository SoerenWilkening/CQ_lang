// Module loops-rolled (cq-9kcq, step S1): the rolled region of CR rule 14, shared by loops-classical (and, from
// step S3 on, loops-cutoff's rolled K-loop). A Region owns the forward output blocks of a rolled loop (and its
// nested loops) as segments, flushes each trip's trip-local rails in their own trip, and emits the reverse loop.
// The walk that fills the segments is the caller's (Classical.cpp's Unit).
//
//  Per-trip uncompute (rule 5, as early as allowed). Before the reverse, each segment is flushed at
//  its terminator (Uncompute::flushBefore) with the region's back edges cut, so a rail made and last
//  read within one segment is undone in its own trip (60: the Toffoli flag of q[j] && q[i]); only a
//  path that re-executes the record could put another segment's gate between them. Rule 5's
//  invariant across trips: if the region has a non-diagonal gate (Ry, quantum-angle Ry) on a rail
//  that is not made by a record of the region, and the reverse loop still undoes anything, a later
//  trip's gate may touch a rail an earlier trip's record read: cq::unimplemented. Likewise (cq-vqid)
//  a non-diagonal gate on a rail that an item undone by the reverse loop reads (a merge read: each
//  arm), on a path after that item's forward record that does not make the rail again (later in
//  the same trip, or a later trip on a rail the trip does not remake): cq::unimplemented.
//
//  Deferred reverse (cq-fx3s, CR rule 14: 153, 178). A quantum value read after the outermost loop
//  whose exit rail is made by a record of the loop (a trip's template, a seed of the entry) is read in
//  place (no copy-out), and the reverse is an Uncompute deferred item (recordDeferred) placed after its
//  readers: the loop's exit block X branches to a fresh continuation, and the item, wherever Uncompute
//  places it, starts with a classical branch on "X was passed" (an SSA value: false at the function's
//  entry, true at X), so a path where the loop did not run (the zero-trip guard's skip edge, 178) skips
//  it; the values from before the region it reads are read through phis that name them where the loop
//  ran (poison elsewhere). A value whose exit rail is not the loop's own (an alias of a carried value, a
//  rail from before the loop) is still copied out first; with no deferred value the reverse runs at X.
//
//  Segments. Every forward output block is a segment with its own Uncompute scope (sequential, never
//  nested). After the outermost loop exits, each other quantum value read after the loop is copied out
//  (alloc + copy, Role::Output) and rebound to the copy; then the reverse runs: one reverse block
//  R(F) per segment F, holding emitMirror(scope of F), whose operands defined in the forward region
//  are replaced by pops; F pushes exactly those values before its terminator (i32 words, a wider
//  value low word first, §1.3), so every classical per-trip value is pushed rather than recomputed.
//  A segment with several predecessors pushes a come-from index first, and R(F) pops it last and
//  goes to the reverse of that predecessor: the reverse replays the forward path backwards (loop
//  headers included: come-from "entry" ends that loop's reverse). The reverse of the entry edge is
//  the block Z, where the seeds allocated in E are released (emitMirror of E's scope); the builder
//  is left at the end of Z, where the loop's exit block continues.
#pragma once

#include <functional>
#include <memory>
#include <utility>
#include <vector>

#include "cq/Lowering.h"
#include "cq/Uncompute.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

namespace cq::loops::rolled {

// cq-r8-d (185): the SSA value at the end of `at` of a variable that is `v` at the end of block D and
// `dflt` at the entry (and at the end of `reset`, when given), with phis at the joins over the real predecessors. The construction is still
// filling its own phis' incomings when a deferred reverse is placed, and SSAUpdater reads a block's
// predecessors through its leading phi: an empty one hides them, and the value came out poison (a
// `br i1 poison` guard, a free of poison). Uncompute's carryTo, for the loop's guard and reads.
llvm::Value *carryTo(llvm::BasicBlock *at, llvm::BasicBlock *D, llvm::Value *v, llvm::Value *dflt,
                     const llvm::Twine &name, llvm::BasicBlock *reset = nullptr);

// The push/pop stack (CR §1.3: i32 words, a wider value low word first). Every first-class type a per-trip
// value can have: a scalar (integer of any width, floating point, pointer) is its bits in words; a vector,
// struct or array is its elements in order (popped in reverse).
unsigned scalarBits(llvm::Type *t, const llvm::DataLayout &DL);
void pushValue(llvm::IRBuilder<> &B, llvm::FunctionCallee push, llvm::Value *v, const llvm::DataLayout &DL);
llvm::Value *popValue(llvm::IRBuilder<> &B, llvm::FunctionCallee pop, llvm::Type *t, const llvm::DataLayout &DL);

// cq-9kcq S12 (ROLLED_DESIGN.md §4; CR rules 14, 23): does a trip of the quantum-exit loop L change the quantum part of the
// floating-point environment (eff-fenv's FLAGS or MODE)? In a rolled body that state is loop-carried: a header phi over
// handles, the latch's incoming, and a copy-out of the exit state before the reverse loop, none of them built yet (cq-v1fu
// for the classically bounded loops). Until they are, such a K-loop keeps its static copies, where each trip's change is a
// straight-line change under the trip predicate (eff-fenv requirePlaced). Defined in eff/fenv/Fenv.cpp, beside the
// classification it reads.
bool changesFenvState(const llvm::Loop &L);

// Is v read after the loop `top` only by what keeps its rail (rule 5, §6 item 1): a measurement, a return, the value of a store?
bool readersKeep(LoweringContext &ctx, const llvm::Loop &top, const llvm::Value *v);

class Region {
public:
  Region(LoweringContext &ctx, llvm::Function &Out) : ctx(ctx), Mod(ctx.M), Out(Out), U(ctx.unc()) {}
  virtual ~Region() = default;

  llvm::BasicBlock *newBlock() { return llvm::BasicBlock::Create(Mod.getContext(), "", &Out); }

  void closeSeg() {
    if (segOpen)
      ctx.unc().closeScope(segs.back().scope);
    segOpen = false;
  }
  void startSeg(llvm::BasicBlock *bb) {
    closeSeg();
    segIdx[bb] = segs.size();
    segs.push_back({bb, ctx.unc().openScope(), bb});
    segOpen = true;
    cur = bb;
    ctx.B().SetInsertPoint(bb);
  }

  // cq-kk46l (rule 8 in a nested K-loop's trips, exits::lowerNestedCutoff's segHook): a block a classical branch of the
  // nested unit makes is a segment like any block of this walk's classical branches: the open segment first takes the
  // block the builder is in (it ends with the branch, or the jump into the join), then bb starts its own.
  void branchSeg(llvm::BasicBlock *bb) {
    if (llvm::BasicBlock *now = ctx.B().GetInsertBlock(); cur && now != cur) {
      segIdx[now] = segs.size() - 1;
      segs.back().bb = now;
    }
    startSeg(bb);
  }
  std::function<void(llvm::BasicBlock *)> segHook() {
    return [this](llvm::BasicBlock *bb) { branchSeg(bb); };
  }

  // A loop of the region: its output header H, entered from `from` (every other predecessor of H is a back edge).
  void addHead(llvm::BasicBlock *H, llvm::BasicBlock *from) { heads.push_back({H, from}); }

  void flushTrips();
  // The reverse from B's block (unterminated); leaves B at the end of an unterminated block. guarded:
  // B's block may be reached on a path where the loop did not run (cq-fx3s): branch around on that.
  void reverse(llvm::IRBuilder<> &B, llvm::BasicBlock *X, unsigned seedScope, bool guarded);

  // cq-9kcq S3b: the setup a caller other than loops-classical's Unit gives the region (loops-cutoff's rolled K-loop).
  // The block the builder is in becomes the last block of the open segment, which is closed (the latch's segment).
  void endSeg() {
    if (llvm::BasicBlock *now = ctx.B().GetInsertBlock(); cur && now != cur) {
      segIdx[now] = segs.size() - 1;
      segs.back().bb = now;
    }
    closeSeg();
  }
  void setOwnSeedScope(unsigned sc) { ownSeedScope = sc; }
  void addExternalInit(llvm::Value *h) { externalInits.push_back(h); }
  void setDiagAt(const llvm::Instruction *at) { diagAt = at; }
  bool hasCopyScope() const { return copyScope != ~0u; }

  // The exit of the outermost loop at its exit block T (the builder there), after the trips (cq-fx3s, cq-h5uj; moved from
  // loops-classical's Unit::lowerLoop). wireExits: every quantum value read after the loop (out, with its rail type
  // outW) is read in place when its exit rail is a record of the loop, else copied out (in the copy scope when
  // scopedOf(v): undone by the reverse first); put rebinds it. finishExits: the reverse at T when nothing is read in
  // place, else an Uncompute deferred item after the readers; returns whether it was deferred (the builder is left
  // where the loop continues).
  struct ExitWiring {
    std::vector<unsigned> scs;
    llvm::DenseSet<const llvm::Value *> ownedH;
    std::vector<RailId> exits;
  };
  ExitWiring wireExits(unsigned seedScope, llvm::ArrayRef<std::pair<const llvm::Value *, Operand>> out,
                       llvm::ArrayRef<RailType> outW, llvm::Value *stopCur,
                       const llvm::DenseSet<const llvm::Value *> &keptFinal,
                       llvm::function_ref<bool(const llvm::Value *)> scopedOf,
                       llvm::function_ref<void(const llvm::Value *, Operand)> put);
  bool finishExits(llvm::BasicBlock *T, unsigned seedScope, const ExitWiring &w, bool keptInPlace,
                   const llvm::Instruction *latchTerm, std::shared_ptr<Region> self);

protected:
  LoweringContext &ctx;   // only while lowerClassical runs: a deferred reverse (cq-fx3s) uses Mod, Out, U
  llvm::Module &Mod;
  llvm::Function &Out;
  Uncompute &U;
  const llvm::Instruction *diagAt = nullptr;   // the instruction the region's diagnostics name (the loop's header terminator)

  struct Seg {
    llvm::BasicBlock *bb;
    unsigned scope;
    llvm::BasicBlock *head;   // bb unless a body instruction branched inside the trip (rule 5's Readers test)
  };
  std::vector<Seg> segs;
  llvm::DenseMap<const llvm::BasicBlock *, unsigned> segIdx;
  bool segOpen = false;
  llvm::BasicBlock *cur = nullptr;   // the open output block, null after a real branch
  llvm::BasicBlock *E = nullptr;     // the outermost loop's entry block (outside the region)
  std::vector<llvm::Value *> externalInits;   // handles defined outside the region read through header phis
  std::vector<std::pair<llvm::BasicBlock *, llvm::BasicBlock *>> heads;   // every loop's output header H and its entry block

  // Trip-local sub-loops (CR rules 5, 14; 176): a classically bounded sub-loop whose quantum values read
  // after it die within the parent's trip is its own unit, with its own reverse loop placed in the
  // parent's trip after the readers of its exit values (the deferred reverse of cq-fx3s, one per trip).
  // nested: this unit is such a sub-loop; resetAt: the parent's output header (where "the sub-loop ran"
  // is false again). The parent finishes it (flushTrips, the deferred item) inside its own flushTrips,
  // after flushing the segment the sub-loop is entered from.
  bool nested = false;
  llvm::BasicBlock *resetAt = nullptr;
  unsigned copyScope = ~0u;   // cq-h5uj: the copies of exit values a per-trip loop reads in place
  bool reversed = false;
  llvm::BasicBlock *revAt = nullptr;   // where this unit's reverse begins (a trip-local sub-loop: inside the parent's trip)
  std::function<void()> finish;
  unsigned ownSeedScope = ~0u;
  std::vector<unsigned> hostScopes;   // the enclosing units' scopes (Uncompute F2)
  struct Sub {
    std::shared_ptr<Region> unit;
    unsigned entrySeg;
    llvm::BasicBlock *cont;   // the sub-unit's continuation (its forward exit into the parent)
  };
  std::vector<Sub> subs;
  llvm::DenseMap<const llvm::BasicBlock *, llvm::BasicBlock *> throughSub;   // a sub-unit's continuation -> the parent segment entering it
  llvm::DenseSet<const llvm::BasicBlock *> subBlocks;                  // the blocks of the sub-units' regions
  std::vector<std::pair<llvm::Instruction *, unsigned>> entering;   // per segment, an entering edge (flushTrips)
  // cq-bqbty, cq-d4c4m: a rule-6 old rail and the last instruction its clean-up follows (latchNexts): flushTrips places the
  // clean-up in that instruction's block.
  std::vector<std::pair<RailId, llvm::Instruction *>> lateR6;

  // cq-j5mq: a loop with several classical exit edges into one exit block. T's phi naming the edge taken, and per edge
  // the segment block it leaves from: the reverse starts at that segment.
  llvm::PHINode *exitIndex = nullptr;
  std::vector<llvm::BasicBlock *> exitSegs;
  // cq-v0a5c: per exit edge, the scope of the edge's copies of exit values something undoes after the loop (~0u: none), and
  // their rails. The reverse is deferred after their readers and starts by un-copying the edge's.
  std::vector<unsigned> exitEdgeScope;
  std::vector<RailId> exitEdgeRails;
};

} // namespace cq::loops::rolled
