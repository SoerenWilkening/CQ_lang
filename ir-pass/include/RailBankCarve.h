// RailBankCarve.h — bd `xdu2` / L-1a: THE RAIL-BANK CARVE VERDICT.
//
// ⚠⚠ THIS HEADER AND ITS ONE IMPLEMENTATION FILE (`RailBankCarveShim.cpp`) ARE A
// TEMPORARY TRACK-B STAND-IN FOR TRACK A'S SHIPPED CLASSIFIER, AND THEY ARE
// BUILT TO FAIL LOUDLY RATHER THAN TO SURVIVE. ⚠⚠
//
// Track A shipped the classifier on branch `railbank-carve` (tip `44ba3345`),
// declared in `ir-pass/include/QramLowering.h` beside `qramCarveVerdict` and
// defined in `QramLowering.cpp` — where it can call the file-local
// `walkPtrOrigin`, `isDirectOriginPtr` and `matchAddressGep` without exporting
// them (`SCOPE_L1a.md` §0 H4). Track B is developed in a parallel worktree that
// does not have that branch, so the promoter would otherwise have nothing to
// call. **The declarations below are transcribed VERBATIM from Track A's
// published `trackA/SIGNATURE.md`** — not from the strawman, which they replaced.
//
// ── L8 RETIREMENT TRIGGER, character-for-character as the thing that fires ───
//
// *** WHEN TRACK A'S BRANCH IS MERGED, THIS HEADER AND `RailBankCarveShim.cpp`
// ARE DELETED, BOTH LINES ARE REMOVED FROM `ir-pass/CMakeLists.txt`, AND
// `RailBankPromote.cpp`'s `#include "RailBankCarve.h"` BECOMES
// `#include "QramLowering.h"`.  NOTHING ELSE IN `RailBankPromote.cpp` CHANGES:
// it is written against the signature below and reads its facts out of
// `RailBankShape`. ***
//
// It is not possible to forget, and that is the design rather than a hope:
//   * Track A defines `cq::railBankCarveVerdict` with this signature, so leaving
//     the shim in place is a DUPLICATE SYMBOL link error — in `libCQPass.so` and
//     in `cq-opt` both, since they share one source list;
//   * `enum class RailBankCarve` and `struct RailBankShape` are declared in
//     `QramLowering.h` too, so any TU that sees both headers fails to compile on
//     a REDEFINITION — and the DEFAULT ARGUMENT `outShape = nullptr` appears in
//     both declarations, which is its own hard error;
//   * if the shipped signature ever moves again, deleting the shim leaves
//     `RailBankPromote.cpp`'s one call site unresolved.
// All three are loud. What is NOT possible is the two spellings quietly
// co-existing, which is the failure mode Rule 14 names (the drbq Inc-3 (b')
// defect, filed by name).
//
// ── WHAT THE PROMOTER TAKES FROM THE VERDICT ────────────────────────────────
//
// `outShape` exists FOR THE PROMOTER (Track A's deviation (1)): it hands back the
// alloca, the loop, the raw index, the cell type, the ABI string, `N` and the
// proven trip count. **The promoter re-derives NONE of it** — that is exactly the
// Rule-14 discipline, and re-spelling the origin walk is the defect above.
//
// ⚠ TWO FACTS ABOUT THE SHIPPED ACCEPT SURFACE THAT THE PROMOTER DEPENDS ON, AND
// WHICH IT DOES NOT RE-ASK (so they are recorded here instead):
//
//   (a) THE WALK LOOP IS OUTERMOST (`Loop::getParentLoop() == nullptr`), added by
//       Track A's adversarial self-attack AFTER 18 green fixtures, a clean
//       2096-row corpus sweep and a 29/29 injection matrix. `for (k…) for (i…)
//       b[i] = …` is `RejectIndex`, not `Bank`. ⚠ THE HAZARD IS THE PROMOTER'S,
//       NOT THE CARVE'S: an enclosing loop re-executes the whole cell walk, so
//       the SECOND OUTER TRIP'S SEED LOAD READS A PREVIOUSLY-STORED HANDLE and
//       the promotion would forward it as a classical zero — a hidden `|0>`
//       assertion on an entangled rail that no fence in the tree can see
//       (`SCOPE_L1a.md` §4.1: the rail/wire/uncompute machinery is MEMORY-BLIND
//       by construction). **The promoter's own B-clauses do NOT refuse this
//       shape** — B1 only refuses an access in a SUB-loop — so this conjunct is
//       load-bearing for the promoter's soundness and is deliberately not
//       duplicated (a second spelling is the (b') defect).
//       RETIREMENT TRIGGER: the day the carve admits a non-outermost walk loop,
//       the promoter needs a clause of its own or it is an over-accept.
//       Pinned by `railbank_promote_reject_nested_outer_loop.ll`.
//   (b) C4 DELIBERATELY ADMITS THE READ-MODIFY-WRITE CELL ADDRESS, where
//       `matchQramAccess`'s `hasOneUse()` would refuse it (Track A's deviation
//       (3)). That is what lets ONE predicate serve both tracks: the promoter
//       runs inside the `-O1`-repair normaliser fixpoint and sees the RAW shape
//       (`%9 = gep; %10 = load i8, ptr %9; … store i8 %13, ptr %9`), while the
//       carve runs after it and sees the PROMOTED shape where the gep has exactly
//       one use. Both measure `Bank`. So the promoter must NOT expect
//       `hasOneUse` on its input and must not add it.
//
// ⚠ `isRailBankAlloca` / `railStoredToRailBank` ARE NOT SHIPPED and are not
// declared here. They are the FREEZE's membership record (`SCOPE_L1a.md` §4.3)
// and the freeze is in the deferred half; `!cq.railbank` is the TYPE REWRITER's
// to mint next session. **The promoter therefore mints no metadata**, and its
// fixpoint terminates on clause B8 instead — see `RailBankPromote.h`.
//
// Design of record: `docs/prd/phase-04-swap-route-control/inc1-records/
// session-2026-09-14-orchestrator/trackL/SCOPE_L1a.md` §2; this session's
// `trackA/SIGNATURE.md` (the authority for everything below) and
// `trackB/{BRIEF_B,IMPL_B}.md`.

#ifndef CQ_IRPASS_RAILBANKCARVE_H
#define CQ_IRPASS_RAILBANKCARVE_H

#include "llvm/ADT/StringRef.h"

#include <cstdint>

namespace llvm {
class AllocaInst;
class DominatorTree;
class Loop;
class LoopInfo;
class ScalarEvolution;
class StoreInst;
class Type;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// ── bd xdu2 / L-1a: the rail-bank CARVE CLASSIFIER ─────────────────────────────
enum class RailBankCarve {
  NotBank,          // not a rail-bank cell write — fall through to the existing owners
  Bank,             // C1-C4, C2', C6 all hold. ⚠ STILL FALLS THROUGH TO kMsgStore (staging)
  RejectShape,      // C1  — provenance / escape / mixed access / non-zero initializer
  RejectIndex,      // C2' — index is not an injective {0,+,1} over the enclosing loop
  RejectWidth,      // C3  — cell width has no reversible copy
  RejectAlias,      // C4  — the cell address has aliasing fan-out
  RejectTotality,   // C6  — N != the proven trip count, or a cell no iteration writes
};

// The resolved bank on a `Bank` verdict — so no consumer re-derives it (Rule 14).
struct RailBankShape {
  llvm::AllocaInst *Alloca = nullptr;  // the bank object
  llvm::Loop *L = nullptr;             // the loop whose {0,+,1} index walks the cells
  llvm::Value *RawIndex = nullptr;     // the store gep's trailing (classical) index
  llvm::Type *CellTy = nullptr;        // the cell scalar type
  llvm::StringRef ElemAbi;             // "i1"/"i8"/"i16"/"i32"/"i64"
  uint64_t Count = 0;                  // N
  uint64_t Trips = 0;                  // the proven constant trip count (== Count on Bank)
};

RailBankCarve railBankCarveVerdict(const llvm::StoreInst *SI, const TaintSet &taint,
                                   llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                                   llvm::ScalarEvolution &SE, const char *&outMsg,
                                   RailBankShape *outShape = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_RAILBANKCARVE_H
