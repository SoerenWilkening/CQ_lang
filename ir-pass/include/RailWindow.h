// RailWindow.h — bd `test_C_libtooling-01po.19`, steps S1–S4 of the ROLLED
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
//       provably distinct cells (`railWindowDistinct`); a region with an
//       unproven pair is NOT promoted (review round 1 F1: forwarding across a
//       possibly-aliasing store changes memory semantics) and the array needs
//       S7's versioning (Q2).
//
//   S4  MATERIALIZATION + BORROWED ROOTS (RailWindowMaterialize.cpp,
//       RailWindowHandles.cpp). Every access dominated by Q is redirected to
//       a fresh HANDLE array `W` (`alloca <rail>, N`, retyped to `i32` cells
//       after `lowerRotations`); accesses not reachable from Q stay on the
//       original, classical object. At Q a rolled walk copies each cell's
//       classical value into `W`; a classical store into `W` is a REBIND
//       (`cqrt_alloc_<W>(v)`, the old rail abandoned, Q3), so the walk mints
//       every cell's rail (Q1, array-granular). A per-iteration object (F3 (a))
//       is re-materialized at its `lifetime.start` each trip (the previous
//       trip's rails left allocated). A whole-object initializer after Q is
//       split into per-cell rebinds, or refused loudly (addendum notes 1–2);
//       a quantum VLA extent is refused (note 3). `W` carries the compiler-
//       owned `!cq.railwindow` record (its rail width): a load from it is a
//       taint seed and a BORROWED ROOT (never freed, never reverse-played), a
//       store into it a KEPT-CARRIER sink.
//
// ── WHAT STILL DECLINES (and loudly) ─────────────────────────────────────────
//
// S5–S7 are not built yet (S5 in-place cell updates via dm7f.51 and S6
// quantum control on cells, lane C; S7 alias versioning). An array that needs
// one of them is declined with ONE diagnostic naming exactly the steps it
// still needs (`kMsgWindowPending` + the list), at the window slot, before
// every stage that adjudicates consumers of tainted values. RETIREMENT
// TRIGGER: each of S5–S7 removes its own needs-flag from the list and owes an
// accept fixture with an analytic trace check.
//
// Env lever `CQ_RAILWINDOW_DBG`: the plan of every claimed array and the
// function after promotion.

#ifndef CQ_IRPASS_RAIL_WINDOW_H_
#define CQ_IRPASS_RAIL_WINDOW_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"

#include <string>

namespace llvm {
class AllocaInst;
class BasicBlock;
class DominatorTree;
class Function;
class Instruction;
class LoadInst;
class LoopInfo;
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

// Are the two cell addresses provably DIFFERENT cells (S3/S7's one question,
// review round 1 F1: asked before promotion as well as for the needs list)?
bool railWindowDistinct(llvm::ScalarEvolution &SE, const llvm::SCEV *A,
                        const llvm::SCEV *B);

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
