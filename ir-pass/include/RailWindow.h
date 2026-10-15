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
//   S5  IN-PLACE CELL UPDATES (RailWindowInPlace.cpp, RailWindowPhiUndo.cpp).
//       `q[i] ^= q[j]` (also `+=`, `-=`, and the `_Bool` compare spelling) is
//       lowered by dm7f.51's quantum-source round as an in-place gate on the
//       overwritten cell's rail (interfaces (a) and (b) of design §4); a
//       refusal on a dead cell is loud there (c). -O1's header φ carrying a
//       cell across a back edge is re-materialized as a cell load first
//       (design Q6 (a), deferred from S3). A cell updated by a CLASSICAL
//       operand stays pending (S5 in the list).
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
//   S6  QUANTUM CONTROL ON CELLS (RailWindowArms.cpp; ArmClassify `CellCond`
//       and clause (d)). A cell read is a register condition (never minted,
//       stripped or freed); an arm's cell accesses are carried as SSA through a
//       diamond (`promoteRailWindowArms`) so the target cell is rotated in place
//       under control (`cqrt_ry_<W>_controlled`, then frozen), also in a loop
//       (the target is reloaded every trip); a window loop is Case B after its
//       regions flatten; a write-back φ of a classical merge is split per
//       predecessor (`splitRailWindowWritebacks`). Shapes the control chain does
//       not lower stay loud there (bd 01po.19.17–.20).
//
// ── WHAT STILL DECLINES (and loudly) ─────────────────────────────────────────
//
// S5's named sub-gaps (bd 01po.19.7/.13/.14). An array that needs one of them
// is declined with ONE diagnostic naming exactly the steps it still needs
// (`kMsgWindowPending` + the list), at the window slot, before every stage
// that adjudicates consumers of tainted values. RETIREMENT TRIGGER: each
// removes its own needs-flag from the list and owes an accept fixture with an
// analytic trace check. The S7 flag stays as the postcondition of versioning
// (unreachable unless a pair survives it).
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

// Design Q6 (a) (RailWindowPhiUndo.cpp): replace every loop-header φ that
// carries a cell of the handle array `W` across a back edge by a load of that
// cell (exact SCEV identity). Returns false after a loud diagnostic (a cell
// carrier whose cell cannot be named).
bool undoRailWindowHeaderPhis(llvm::Function &F, llvm::AllocaInst *W);

// S6 (RailWindowArms.cpp): put the cell accesses inside every region of a
// QUANTUM branch over the handle array `W` into the diamond the control
// emitters own — each cell class loaded once before the branch, carried as SSA
// through the arms, written back once at the merge. True if anything changed.
bool promoteRailWindowArms(llvm::Function &F, llvm::AllocaInst *W,
                           const TaintSet &taint);

// S6 (RailWindowArms.cpp): split every window write-back `store (phi …)` into
// one store per incoming at the end of its predecessor (the classical mux the
// taint guard refuses; contract at the definition). The caller re-propagates.
bool splitRailWindowWritebacks(llvm::Module &M, TaintSet &taint);

// S5 (RailWindowInPlace.cpp): is `V` an update `x OP y` (`xor`/`add`/`sub`, or
// the `_Bool` compare spelling of `xor`)? Fills both operands; `Sub` marks the
// directional `sub` (only the minuend `X` can be the overwritten cell).
bool railWindowInPlaceUpdate(llvm::Value *V, llvm::Value *&X, llvm::Value *&Y,
                             bool &Sub);

// S5 interface (b), the BORROWED-ROOT TARGET: is `P` a cell read (a rail the
// array owns: user data, never discharged by the spine) that dominates `Site`
// and is re-executed before every re-execution of `Site`? Then an in-place
// gate at `Site`, even inside a loop, rewrites exactly the rail the program's
// own reload names on that trip (InPlaceQQ's E2 and the M-C fence's G5).
bool railWindowSameTripTarget(const llvm::Instruction *Site,
                              const llvm::Value *P,
                              const llvm::DominatorTree &DT);
// S5 interface (b), WHICH cell an update overwrites — THE ONE PREDICATE (R12;
// asked by InPlaceQQ's E2 via `qqTargetIsUserData`, and by the stale-cell
// fence's gate set, and by the S5 needs list): may the update `U` (an `xor`/
// `add`/`sub`, its `_Bool` compare spelling, or its lowered template) be
// lowered IN PLACE on the rail of the cell at `CellPtr`? Iff (1) every store of
// `U`'s result (through casts and φs) is into that cell and the result escapes
// nowhere else — never a
// second cell (R7, review S5 A-F1), and (2) the write-back is a MUST: every
// path from `U` stores a value derived from `U` into that cell before any read
// of a cell that may be it, any other store into it, `U` again, or a return
// (review S5 C-F1: on a path that skips the write-back C keeps the old value).
bool railWindowWritesBack(const llvm::Instruction *U,
                          const llvm::Value *CellPtr);
// (`qqTargetIsUserData`, declared in InPlaceQQ.h, is defined beside these.)
// S6: `provablyBefore(X, Site)`, or — for an in-place gate whose target `P` is
// a same-trip cell read (`railWindowSameTripTarget`) — `X` earlier in the SAME
// trip: it dominates `Site` and every path from `Site` back to `X` reloads the
// cell first (the next trip's `X` reads the cell's updated value, which is the
// program's). Asked by the in-place fence's G6 and G7 (c′).
// bd 01po.19.17 (design §6, Q4): the members of `P`'s array family (`Family`)
// that are cell READS of a provably different cell than `P` in the same trip:
// loads in `P`'s innermost loop whose address SCEV differs from `P`'s by a
// known non-zero amount (`railWindowDistinct`). Sound only for a question asked
// within one activation of that loop (an in-body window: its opener dominates
// its discharge point, so no back edge lies between them).
void railWindowTripDistinctCells(const llvm::Value *P,
                                 llvm::ArrayRef<llvm::Value *> Family,
                                 const llvm::Instruction *First,
                                 const llvm::Instruction *At,
                                 llvm::SmallPtrSetImpl<const llvm::Value *> &Out);
bool railWindowBeforeInTrip(const llvm::Instruction *X,
                            const llvm::Instruction *Site, const llvm::Value *P,
                            const llvm::DominatorTree &DT);
// S6: is `V` computed (through non-call, non-load operands) from a cell read?
// Scopes the same-trip deadness of InPlaceQQRecord's `usersBefore`.
bool railWindowDerived(const llvm::Value *V);

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
