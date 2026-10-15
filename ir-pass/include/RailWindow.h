// RailWindow.h — bd `test_C_libtooling-01po.19`, steps S1–S4 and S7 of the ROLLED
// quantum-array design (owner rulings `owner-ruling-01po19-rolled-not-unrolled-
// 2026-10-15` and `owner-ruling-01po19-rolled-design-2026-10-15`, Q1–Q6 all (a)).
//
// ── THE MODEL ────────────────────────────────────────────────────────────────
//
// A quantum array is a classical array of rail HANDLES. A classical (possibly
// runtime) index selects a handle; a cell load denotes that rail's quantum
// value (a BORROWED root: it names a rail, it mints none). The rolled one-store
// rail bank (`RailBankPromote.h`, `QramLowering.h` C1–C7) is the special case
// whose walk is its own materialization; it keeps its path byte-identically
// (Q5). Every other well-formed quantum array is a WINDOW array:
//
//   S1  CLAIM (pure analysis). A non-escaping local array of integer cells with
//       a reversible copy (`[N x iW]`, or a runtime extent `alloca iW, n` that
//       is allocated at most once per activation), every access a simple load
//       or store of the cell type through a GEP chain (LICM's hoisted
//       `gep %q, -2` base included: the address is its SCEV, never its
//       spelling), no tainted index (that is 7.5's QRAM axis), at least one
//       tainted store, and NO tainted store the one rail-bank verdict calls
//       `Bank`/`BankRaw` (the rolled bank owns those, Q5). Storage must be live
//       at every access: no access reaches a `lifetime.start` without passing a
//       `lifetime.end`, no `lifetime.end` reaches an access without a new
//       start, and no `stackrestore` lies between THIS object's allocation and
//       one of its accesses (per object, review round 1 F3 (b)). An object
//       declared inside a loop body (its one start re-executed, an end between
//       iterations, the start dominating every access) is a PER-ITERATION
//       object (F3 (a)): its quantization point is that start. Accesses are
//       kept in instruction order (F4).
//   S2  QUANTIZATION POINT (analysis; Q1 (a), array-granular allocation). The
//       one program point Q after which every access sees handles: the nearest
//       common dominator of the outermost-loop preheaders of the tainted
//       writes (a missing preheader is inserted first), hoisted until it
//       dominates every access reachable from it and lies in no cycle (an
//       irreducible cycle included). Accesses not reachable from Q are
//       classical. Such a Q always exists (the entry block qualifies).
//   S3  WINDOW PROMOTION (transform). A window is a single-entry acyclic region
//       of one loop body (sub-loops and back edges excluded) or of loop-free
//       code. Inside a window each cell CLASS (one address SCEV) is loaded once
//       at its dominating address and written back once at every window exit,
//       through `PromoteMemToReg` on a per-class scalar: one SSA name per cell,
//       memory only between windows. Two classes in one window must be
//       provably distinct cells (`railWindowPairProven`); a region with an
//       unproven pair is NOT promoted (review round 1 F1: forwarding across a
//       possibly-aliasing store changes memory semantics). S7's versioning
//       runs first and leaves none.
//
//   S4  MATERIALIZATION + BORROWED ROOTS (RailWindowMaterialize.cpp,
//       RailWindowHandles.cpp). Every access dominated by Q is redirected to
//       a fresh HANDLE array `W` (`alloca <rail>, N`, retyped to `i32` cells
//       after `lowerRotations`); accesses not reachable from Q stay on the
//       original, classical object. At Q a rolled walk copies each cell's
//       classical value into `W`; a classical store into `W` is a REBIND
//       (`cqrt_alloc_<W>(v)`, the old rail abandoned, Q3), so the walk mints
//       every cell's rail (Q1, array-granular). An object with NO pre-Q
//       classical writer at all (no cell store, memset, constant store or
//       constant memcpy before Q) is never initialized: every cell is seeded
//       |0> and the original is not read (review B-1, ruling
//       `ruling-01po19-s4-r1-qs-2026-10-15` Q1 — the undef-seed-is-zero rule
//       of bd z9t1). A PARTIALLY initialized object keeps the memory value of
//       every cell, written or not (C's indeterminate value; documented, not
//       fenced). A per-iteration object (F3 (a))
//       is re-materialized at its `lifetime.start` each trip (the previous
//       trip's rails left allocated). A whole-object initializer after Q is
//       split into per-cell rebinds, or refused loudly (addendum notes 1–2);
//       a quantum VLA extent is refused (note 3). `W` carries the compiler-
//       owned `!cq.railwindow` record (its rail width): a load from it is a
//       taint seed and a BORROWED ROOT (never freed, never reverse-played), a
//       store into it a KEPT-CARRIER sink.
//
//   S7  INDEX ALIAS VERSIONING (RailWindowVersion.cpp, RailWindowVersionPair
//       .cpp; owner Q2 (a)). Between S4 and S3 (addendum note 4): a window
//       region with a pair of classes SCEV cannot prove distinct is cloned on
//       the classical `&q[i] != &q[j]`; each copy is a window of its own. The
//       distinct copy is proven by the dominating guard (`railWindowDistinct`'s
//       context form), the aliased copy names both classes through one
//       address, and after S3 its `x ^= x` folds to a classical rebind.
//       Control == target and more than 8 copies of one window are loud.
//
// ── WHAT STILL DECLINES (and loudly) ─────────────────────────────────────────
//
// S5–S6 are not built yet (S5 in-place cell updates via dm7f.51 and S6
// quantum control on cells, lane C). An array that needs one of them is
// declined with ONE diagnostic naming exactly the steps it still needs
// (`kMsgWindowPending` + the list), at the window slot, before every stage
// that adjudicates consumers of tainted values. RETIREMENT TRIGGER: each of
// S5–S6 removes its own needs-flag from the list and owes an accept fixture
// with an analytic trace check. The S7 flag stays as the postcondition of
// versioning (unreachable unless a pair survives it).
//
// Env lever `CQ_RAILWINDOW_DBG`: the plan of every claimed array and the
// function after promotion.

#ifndef CQ_IRPASS_RAIL_WINDOW_H_
#define CQ_IRPASS_RAIL_WINDOW_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"

#include <optional>
#include <string>

namespace llvm {
class AllocaInst;
class BasicBlock;
class DominatorTree;
class Function;
class ICmpInst;
class Instruction;
class LoadInst;
class LoopInfo;
class PostDominatorTree;
class Module;
class ScalarEvolution;
class SCEV;
class StoreInst;
class Type;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// S1–S4 plus the pending-step decline. Returns true iff it diagnosed (the
// first `DS_Error` ends the run, bd `br4a`). `Changed` is set when an array
// was materialized; the caller then re-`propagate`s (the taint GROWTH of the
// new `!cq.railwindow` loads, discharged by order exactly as the rail bank's
// mint: this runs above every stage that adjudicates tainted consumers).
bool lowerRailWindowArrays(llvm::Module &M, const TaintSet &taint,
                           bool &Changed);

// ── S4's handle array (RailWindowHandles.cpp) ────────────────────────────────
// The compiler-owned `!cq.railwindow` record, minted by `lowerRailWindowArrays`
// and nothing else (an input that carries it is a loud reserved-name decline).
bool isRailWindowAlloca(const llvm::AllocaInst *AI);
// The handle array `P` points into, or null (LLVM's `getUnderlyingObject`).
llvm::AllocaInst *railWindowOfPointer(const llvm::Value *P);
// The record's rail type (`i1` for a `_Bool` array, else the cell type).
llvm::Type *railWindowRailType(const llvm::AllocaInst *AI);
// Is `V` a cell read of a handle array (a BORROWED root: it names a rail the
// array owns, it mints none)?
bool isRailWindowCellRead(const llvm::Value *V);
// Is `H` stored into a handle-array cell (a KEPT-CARRIER sink: the cell owns
// the rail, so the whole-DAG spine neither adjoints nor frees it)?
bool railStoredToRailWindow(const llvm::Value *H);
// THE MEMORY HOP, ARRAY-GRANULAR (Q4). If `V` is a rail of a handle array — a
// cell read, or a value stored into a cell — append to `Out` every cell read
// of that array and every value stored into it (the rails a later gate on
// "the same cell" may be spelled through; a runtime index cannot be told
// apart, so the whole array is one family) and return true. A fence that asks
// "is this borrowed rail moved?" must ask it of every member.
bool railWindowFamily(const llvm::Value *V,
                      llvm::SmallVectorImpl<llvm::Value *> &Out);
// Mint the record (rail width) on a materialized handle array.
void markRailWindowAlloca(llvm::AllocaInst *W, llvm::Type *RailTy);
// Reserved-name fence for the record; returns true after diagnosing.
bool declineForeignRailWindowRecords(llvm::Module &M);
// Retype every handle array to `i32` cells (the rail-bank piece-2 slot,
// between `lowerRotations` and `lowerOps`): a load becomes the `i32` handle
// (its logical width recorded in `HandleWidth`), and a CLASSICAL stored value
// becomes a fresh `cqrt_alloc_<W>(v)` rail (a rebind).
void rewriteRailWindowCellTypes(llvm::Module &M, WidthDispatch &wd,
                                TaintSet &taint);

// The leaf accesses of one window array (S1's structural half).
struct RailWindowAccesses {
  llvm::AllocaInst *AI = nullptr;
  llvm::Type *CellTy = nullptr;
  llvm::SmallVector<llvm::LoadInst *, 16> Loads;
  llvm::SmallVector<llvm::StoreInst *, 16> Stores;
  // Whole-object initializers (memset / constant store) and lifetime markers.
  llvm::SmallVector<llvm::Instruction *, 4> Others;
  // A per-iteration object (declared inside a loop body: its one
  // `lifetime.start` is re-executed, every access lies between it and a
  // `lifetime.end`): that start is the object's quantization point (F3 (a)).
  llvm::Instruction *ScopeStart = nullptr;
};

// S2: the quantization point of a claimed array (RailWindowQ.cpp): the one
// program point after which every access sees handles (see S2 above). Null
// only for an array with no tainted store.
llvm::Instruction *railWindowQuantizationPoint(const RailWindowAccesses &Acc,
                                               const TaintSet &taint,
                                               llvm::DominatorTree &DT,
                                               llvm::LoopInfo &LI);

// Are the two cell addresses provably DIFFERENT cells (S3/S7's one question,
// review round 1 F1: asked before promotion as well as for the needs list)?
// Without `Ctx`, everywhere (SCEV `isKnownNonZero(A - B)`); with it, at that
// instruction, also under a dominating `A != B`: S7's versioning guard, or a
// user test that `railWindowCompareIsCellEquality` accepts as exactly the
// cell test (same address difference, or index difference times a power of
// two that cannot wrap to 0 — an unmasked i64 `i != j` over 4-byte cells is
// NOT one). `isKnownPredicateAt` first, then the dominating-edge walk over
// `DT` (a dominating `!=` edge wins over an `==` one: such a context is dead).
bool railWindowDistinct(llvm::ScalarEvolution &SE, const llvm::SCEV *A,
                        const llvm::SCEV *B,
                        const llvm::Instruction *Ctx = nullptr,
                        llvm::DominatorTree *DT = nullptr);
// Does the equality compare `C` test exactly "the two cells are one" for the
// cell-address difference `AB` (pointer offsets, or integer indices scaled by
// a power of two that cannot wrap)?
bool railWindowCompareIsCellEquality(llvm::ScalarEvolution &SE,
                                     const llvm::ICmpInst *C,
                                     const llvm::SCEV *AB);
// The dominating-equality fact on two cell addresses at `Ctx`: true when an
// edge asserting `A != B` dominates it, false when one asserting `A == B`
// does, none otherwise (the one dominating-edge walk of S7).
std::optional<bool> railWindowEdgeFact(llvm::ScalarEvolution &SE,
                                       llvm::DominatorTree &DT,
                                       const llvm::Instruction *Ctx,
                                       const llvm::SCEV *A,
                                       const llvm::SCEV *B);
// Two cell classes of one window may be promoted side by side iff they are
// distinct everywhere, or at every access of one of them.
bool railWindowPairProven(llvm::ScalarEvolution &SE, llvm::DominatorTree &DT,
                          const llvm::SCEV *A, const llvm::SCEV *B,
                          llvm::ArrayRef<llvm::Instruction *> AccA,
                          llvm::ArrayRef<llvm::Instruction *> AccB);
// S3's promotion plan for ONE class (accesses `Uses`, region `Entry`): the one
// dominating address, the seed point `At` and the exiting blocks that get the
// write-back. False (and `At` null) when the class is not promoted.
struct RailWindowClassPlan {
  llvm::Value *Addr = nullptr;
  llvm::Instruction *At = nullptr;
  llvm::SmallVector<llvm::BasicBlock *, 4> Exiting;
  bool HasStores = false;
  llvm::BasicBlock *Entry = nullptr;
  bool Inside = false;  // the address is defined inside the region
};
// The plan's seed insertion point, asked on the IR as it is now.
llvm::Instruction *railWindowPlanSeedPoint(const RailWindowClassPlan &P);
bool railWindowClassPlan(
    llvm::Function &F, llvm::DominatorTree &DT,
    const llvm::DenseMap<llvm::BasicBlock *, llvm::BasicBlock *> &R,
    llvm::BasicBlock *Entry, llvm::ArrayRef<llvm::Instruction *> Uses,
    RailWindowClassPlan &P);
// The program points the plan itself touches the cell at (the seed and each
// write-back): the alias proof must hold there too (R11 S7 A-F1).
void railWindowPlanPoints(const RailWindowClassPlan &P,
                          llvm::SmallVectorImpl<llvm::Instruction *> &Out);
// One unproven pair: two classes of window region `E` (address SCEVs `A`,
// `B`; their accesses in instruction order).
struct RailWindowPair {
  llvm::BasicBlock *E = nullptr;
  const llvm::SCEV *A = nullptr, *B = nullptr;
  llvm::SmallVector<llvm::Instruction *, 8> AccA, AccB;
};
// THE alias question of S3/S7 (the one spelling): the first pair of classes
// in one window region that `railWindowPairProven` cannot prove distinct.
bool railWindowUnprovenPair(llvm::Function &F, const RailWindowAccesses &Acc,
                            llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                            llvm::ScalarEvolution &SE, RailWindowPair &Out);
// CONTROL == TARGET (S7, RailWindowAlias.cpp): a quantum branch/switch/select
// condition (`QD`) reading one class of `P` that controls a store to the
// other. In the aliased copy that gate is controlled by its own target, which
// is not unitary (owner Q2 ruling: loud). Returns the store, or null.
llvm::Instruction *
railWindowSelfControl(llvm::Function &F, const RailWindowAccesses &Acc,
                      const llvm::SmallPtrSetImpl<llvm::Value *> &QD,
                      const RailWindowPair &P, llvm::ScalarEvolution &SE,
                      llvm::DominatorTree &DT, llvm::PostDominatorTree &PDT);

// S1's structural half (RailWindow.cpp): collect the leaf accesses of `AI`,
// or refuse it.
bool railWindowCollectAccesses(llvm::AllocaInst *AI, const TaintSet &taint,
                               llvm::ScalarEvolution &SE,
                               RailWindowAccesses &Acc);

// ── S7: index alias versioning (RailWindowVersion.cpp) ───────────────────────
// After S4's materialization of handle array `W`, before S3's promotion
// (addendum note 4: structural order), then the round-2 checks: version every
// window region with an unproven pair on the classical `A != B`, promote,
// fold the aliased copies and assert their postcondition, and compute the
// pending-step text (`Msg`), the stale-cell offender (`Stale`) and the cell
// copy offender (`Copy`). Returns false after a loud diagnostic.
bool railWindowVersionPromoteCheck(llvm::Function &F, llvm::AllocaInst *W,
                                   const TaintSet &taint, unsigned &Promoted,
                                   std::string &Msg,
                                   llvm::Instruction *&Stale,
                                   llvm::Instruction *&Copy,
                                   RailWindowAccesses &AccW);

// One S7 versioning of pair `P` (RailWindowVersionPair.cpp): the aliased-copy
// blocks join `Alias`, every block it creates or copies gets `Origin` = `O`
// (the copy count is per ORIGINAL window). False after a loud diagnostic.
bool railWindowVersionPair(
    llvm::Function &F, llvm::AllocaInst *W, const RailWindowPair &P,
    llvm::SmallPtrSetImpl<llvm::BasicBlock *> &Alias,
    llvm::DenseMap<llvm::BasicBlock *, llvm::BasicBlock *> &Origin,
    llvm::BasicBlock *O);

// Window regions (S3): block -> its region's entry block. A region is the
// single-entry, back-edge-free part of one loop body (sub-loops excluded) or of
// loop-free code; a block whose predecessors lie in different regions, or
// outside its loop body, starts a region of its own.
llvm::DenseMap<llvm::BasicBlock *, llvm::BasicBlock *>
computeWindowRegions(llvm::Function &F, llvm::LoopInfo &LI);

// S3's transform over one claimed array (RailWindowPromote.cpp): promotes each
// cell class of each region that is read after being written, or read twice,
// to one SSA name. Returns the number of classes promoted. `Acc` is stale on
// return; the caller re-collects.
unsigned promoteRailWindows(llvm::Function &F, RailWindowAccesses &Acc);

// The pending-step decline text for one claimed array (S5 if a cell store is
// an update or copy rather than the cell's own in-place chain; S6 if a
// branch/switch/select condition is quantum; S7 if two cell addresses in one
// window are not provably distinct), empty when nothing is pending, and the
// all-steps text.
std::string railWindowNeeds(llvm::Function &F, const RailWindowAccesses &Acc,
                            const TaintSet &taint, llvm::LoopInfo &LI,
                            llvm::ScalarEvolution &SE);
std::string railWindowAllNeeds();

// Can `From` execute and then `To` on a path that executes none of
// `Barriers` in between (an exact block walk; RailWindowFence.cpp)?
bool railWindowReachesAvoiding(
    const llvm::Instruction *From, const llvm::Instruction *To,
    const llvm::SmallPtrSetImpl<const llvm::Instruction *> &Barriers);

// The values quantum through the taint set or through the array's own cell
// reads (forward closure; a `cq_measure` result is classical).
void railWindowQuantum(llvm::Function &F, const RailWindowAccesses &Acc,
                       const TaintSet &taint,
                       llvm::SmallPtrSetImpl<llvm::Value *> &QD);

// THE STALE-CELL FENCE (RailWindowFence.cpp): a use of a cell rail through a
// name that a gate through ANOTHER spelling of the same array has since moved
// (array-granular, except two provably distinct cells of one window), or a
// gate through a parked rail's own name that a later cell read can observe.
// Returns the offending instruction, or null.
llvm::Instruction *
railWindowStaleUse(llvm::Function &F, const RailWindowAccesses &AccW,
                   const llvm::SmallPtrSetImpl<llvm::Value *> &Quantum,
                   llvm::ScalarEvolution &SE,
                   const llvm::DenseMap<llvm::BasicBlock *, llvm::BasicBlock *>
                       &Regions);

// S4, addendum notes 1–2 (RailWindowInit.cpp): split every whole-object
// initializer dominated by `Q` into per-cell rebind stores into `W` (rail type
// `RT`), refusing loudly what is not exact; one reachable from `Q` without
// being dominated by it is refused. `ScopeInit` (a per-iteration object's own
// initializer, copied by the walk) is skipped. False after a diagnostic.
bool railWindowSplitInits(RailWindowAccesses &Acc, llvm::Instruction *Q,
                          llvm::Instruction *ScopeInit, llvm::AllocaInst *W,
                          llvm::Type *RT, llvm::DominatorTree &DT);
// A cell value narrowed to its rail (`zext` looked through, else a `trunc`
// proven exact by known bits); null when it does not fit.
llvm::Value *railWindowNarrow(llvm::Value *V, llvm::Type *RailTy,
                              llvm::IRBuilder<> &B,
                              const llvm::DataLayout &DL);
const char *railWindowStoreWidthMsg();
// The cell's rail type: `i1` for a `_Bool` array (`i8` storage) witnessed by
// every post-Q load's `!range [0, 2)`, or by loads read only through a `trunc`
// to `i1` (zext-i1 stores when there is no load); else the cell type.
llvm::Type *railWindowRailTypeFor(const RailWindowAccesses &Acc,
                                  llvm::ArrayRef<llvm::LoadInst *> PostLoads,
                                  llvm::ArrayRef<llvm::StoreInst *> PostStores);

// Review C-F1 (RailWindowFence.cpp): the first store of a cell rail into
// memory other than the handle array (a cell copy into another array), or
// null; and its decline text (kMsgWindowPending + the copy-on-read clause).
llvm::StoreInst *railWindowCellCopy(llvm::Function &F,
                                    const RailWindowAccesses &AccW);
std::string railWindowCopyNeeds();

// S4's value-domain transform (RailWindowMaterialize.cpp): redirect the
// accesses dominated by `Q` to a fresh handle array, split post-Q whole-object
// initializers into per-cell rebinds, and insert the materialization walk at
// Q. Returns the handle array, or null after a loud diagnostic. `Acc` is stale
// on return.
llvm::AllocaInst *materializeRailWindow(llvm::Function &F,
                                        RailWindowAccesses &Acc,
                                        llvm::Instruction *Q);

}  // namespace cq

#endif  // CQ_IRPASS_RAIL_WINDOW_H_
