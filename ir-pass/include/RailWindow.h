// RailWindow.h — bd `test_C_libtooling-01po.19`, steps S1–S3 of the ROLLED
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
//       `Bank`/`BankRaw` (the rolled bank owns those, Q5).
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
//       provably distinct cells (`ScalarEvolution::isKnownNonZero` of the
//       address difference); otherwise the array needs S7's versioning (Q2).
//
// ── WHY EVERY WINDOW ARRAY STILL DECLINES (and loudly) ───────────────────────
//
// S4–S7 are not built yet (S4 the borrowed-root class in the uncompute spine,
// lane U; S5 in-place cell updates via dm7f.51 and S6 quantum control on cells,
// lane C; S7 alias versioning). Until they land a window array must not reach
// any lowering, so after S3 every claimed array is declined with ONE diagnostic
// naming exactly the steps it still needs (`kMsgWindowPending` + the list).
// The decline runs at the head of `markRailBankAllocas`, i.e. right after the
// `CQ_RAILBANK_DBG` dump of the promoter's (untouched) output and before every
// stage that adjudicates consumers of tainted values: nothing downstream ever
// sees a window array, so S1–S3 cannot lower a shape silently wrong.
// RETIREMENT TRIGGER: each of S4–S7 removes its own needs-flag from the list
// and owes an accept fixture with an analytic trace check; the decline goes
// away only when the list can be empty.
//
// Env lever `CQ_RAILWINDOW_DBG`: the plan of every claimed array and the
// function after promotion.

#ifndef CQ_IRPASS_RAIL_WINDOW_H_
#define CQ_IRPASS_RAIL_WINDOW_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"

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
class StoreInst;
class Type;
}  // namespace llvm

namespace cq {

struct TaintSet;

// S1–S3 plus the pending-step decline. Returns true iff it diagnosed (the
// first `DS_Error` ends the run, bd `br4a`).
bool declineRailWindowArrays(llvm::Module &M, const TaintSet &taint);

// The leaf accesses of one window array (S1's structural half).
struct RailWindowAccesses {
  llvm::AllocaInst *AI = nullptr;
  llvm::Type *CellTy = nullptr;
  llvm::SmallVector<llvm::LoadInst *, 16> Loads;
  llvm::SmallVector<llvm::StoreInst *, 16> Stores;
  // Whole-object initializers (memset / constant store) and lifetime markers.
  llvm::SmallVector<llvm::Instruction *, 4> Others;
};

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

// The pending-step decline text for one claimed array (S4 always; S5 if a
// cell store is an update or copy rather than the cell's own in-place chain;
// S6 if a branch/switch/select condition is quantum; S7 if two cell addresses
// in one window are not provably distinct), and the all-steps text.
std::string railWindowNeeds(llvm::Function &F, const RailWindowAccesses &Acc,
                            const TaintSet &taint, llvm::LoopInfo &LI,
                            llvm::ScalarEvolution &SE);
std::string railWindowAllNeeds();

}  // namespace cq

#endif  // CQ_IRPASS_RAIL_WINDOW_H_
