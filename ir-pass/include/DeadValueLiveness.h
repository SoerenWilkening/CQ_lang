// DeadValueLiveness.h — bd `test_C_libtooling-vsfp` round 2: THE ONE answer to
// "is this value read by anything that matters?", and the one deletion built on it.
//
// WHY IT EXISTS (Rule-13 rounds r1A/r1B on 5e56060b, both NOT-CLEAR). Round 1 asked
// "is the callee PARAMETER `use_empty()`?" in three places (the dead-argument drop,
// the phantom-read backstop, M-C arm (d0)) and cleaned the caller with a local
// "delete the trivially dead cone, never a call" walk. That is a SYNTACTIC answer to
// a SEMANTIC question (CLAUDE.md L5) and it lost the way L5 predicts: a dead
// `trunc` left by the fenv store erasure (`volatile char z = a;`) is a "use", a
// dead `llvm.smax`/`llvm.abs`/`llvm.ctpop` is a "call", a dead loop-carried value
// is a CYCLE with no `use_empty()` member — and in every one of those a which-path
// rail stayed alive across a later non-diagonal gate (bd a8q5, bd m1gi, r1A
// F-VA-3). The hand-inlined twin gets all of them right because `clang -O1` asks
// the semantic question (dead-code elimination by LIVENESS).
//
// THE PREDICATE — mark-from-roots liveness (the classic DCE argument): a value is
// LIVE iff it is a root or an operand of a live instruction; everything else is
// DEAD and has no observable effect. ROOTS (`isLivenessRoot`), in the order it
// asks them — the IDENTITY roots FIRST, so no rule below can override them:
//   * every TERMINATOR (so every branch condition is live — see LIMITS) and every
//     EH pad;
//   * every front-end intrinsic SITE (`cq_theta`/`cq_phi`/`cq_measure`) BY
//     MEMBERSHIP of `taint.{Theta,Phi,Phase,Measure}Calls`, never by attribute: a
//     module that DEFINES `cq_theta_si32` with `memory(none)` would otherwise make a
//     user's gate deletable (CLAUDE.md §4h/§4i: a user gate is never a stage's to
//     erase, whatever its use count);
//   * every call to a function the SPECIALIZER built (`taint.SpecHandleArgMask`,
//     its own record of clones and `_unc` twins — never the `__cq_q_` name);
//   * every call into the project's RESERVED namespaces (`cq_`, `__cq_`, `cqrt_`
//     name prefixes — the name used ONLY to ADD a root, the conservative
//     direction: a module that DEFINES a reserved symbol with a pure body must not
//     have its call deleted; measured, `spec_accept_dropped_arg_reserved_marker_kept.ll`);
//   * every instruction LLVM says `mayHaveSideEffects()` — stores, volatile or
//     atomic accesses, fences, and every call that may write memory, may throw or
//     may not return — EXCEPT a direct `call` to an exact, non-`naked`,
//     non-variadic definition whose BODY is side-effect-free and terminating
//     (`bodyIsSideEffectFree`: an acyclic CFG with no call of any kind, no
//     instruction that may have side effects, only `br`/`switch`/`ret`
//     terminators). The body rule exists because `-O1`'s inferred attributes can
//     be STALE here: the fenv stages erase a callee's volatile store after `-O1`
//     inferred `memory(inaccessiblemem: readwrite)` from it (r1B `v16`), and what
//     the twin gets after inlining is the body's semantics, not the attributes'
//     summary of it.
// A call LLVM proves side-effect-free (`memory(none)` + `nounwind` + `willreturn`,
// every pure LLVM intrinsic) is NOT a root: when its result is dead, the call is
// dead, exactly as `-O1` deletes it inside one TU.
//
// THE CALL-SLOT RULE — the only place the predicate is interprocedural. An argument
// in a slot the callee is RECORDED never to read (`isRecordedDeadSlot`: the
// specializer's `taint.SpecDeadArgMask`, written by `buildClone` with THIS
// predicate) does not become live through that call. Nothing else is looked up:
// before `specialize()` no record exists, so every slot of every call counts as a
// read — the dead-argument drop gets its interprocedural reach from its own
// fixpoint (it REWRITES a dead slot to a constant, which cannot be read).
//
// LIMITS, stated so a reader does not assume more (L7):
//   * No control dependence. A conditional branch is a root even when both of its
//     paths are dead, so its condition — and a parameter it reads — stays LIVE.
//     That is the CONSERVATIVE direction for every client: the drop drops less and
//     the backstop sees more. LLVM's ADCE would remove such a branch; `-O1`
//     removes it too (SimplifyCFG), so it arrives only in hand-written IR — and in
//     a CLONE after its scoped PredMux flatten, which is why the record is taken
//     after that flatten. `deleteDeadCones` folds the one CFG shape it creates
//     itself (an arm it emptied); see there.
//   * Loops are not special: a dead loop-carried value (a φ cycle nobody live
//     reads) is dead; the loop's own control (its exit test) is live because its
//     branch is a root.
//   * Pointers are values like any other; an `alloca` is live iff something live
//     (a store, a lifetime marker, a call) reads it.

#ifndef CQ_IRPASS_DEAD_VALUE_LIVENESS_H_
#define CQ_IRPASS_DEAD_VALUE_LIVENESS_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"

#include <cstdint>

namespace llvm {
class BasicBlock;
class CallBase;
class Function;
class Instruction;
class Use;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Is `I` a liveness ROOT? See the header comment for the complete list.
bool isLivenessRoot(const llvm::Instruction &I, const TaintSet &taint);

// Is argument slot `ArgNo` of call `CB` RECORDED as a slot its callee never reads?
// True only for a callee `buildClone` recorded (`taint.SpecDeadArgMask`) with bit
// `ArgNo` set; false for every other call, slot and callee (including a slot past
// the 64-bit mask).
bool isRecordedDeadSlot(const llvm::CallBase &CB, unsigned ArgNo,
                        const TaintSet &taint);

// THE ONE REWRITE of a recorded-dead slot (bd vsfp round 4; Rule 14 — three sites
// used to spell it): if `U` is an argument operand of a call in a slot
// `isRecordedDeadSlot` names, and it is not already a constant, set it to the null
// constant of the CALLEE PARAMETER's type (bd f061: after retargeting, an fp slot
// is an `i32` handle — never the operand's type) and strip `range`/`nofpclass` from
// the parameter and the call site (a null may violate them — the constraint DAE
// strips too). Returns true iff it rewrote. Callers: `resolvePhantomCloneArgReads`
// (a module-level call), `buildClone` (an inner clone call reading a dead
// PARAMETER directly) and `deleteDeadCones` step 3 (an inner clone call reading a
// dead INSTRUCTION) — so a nested clone call inherits the dead slot (bd sqjq).
bool rewriteRecordedDeadSlotUse(llvm::Use &U, const TaintSet &taint);

// The liveness of one function body, computed once at construction.
class FunctionLiveness {
public:
  FunctionLiveness(const llvm::Function &F, const TaintSet &taint);
  // `V` is an Instruction or Argument OF THIS FUNCTION; anything else (a
  // constant, a global, another function's value) answers false.
  bool isLive(const llvm::Value *V) const;

private:
  llvm::SmallPtrSet<const llvm::Value *, 32> Live;
};

// Bit i set ⇔ parameter i of `F` is DEAD under `FunctionLiveness`. Parameters at
// index ≥ 64 are reported LIVE (never droppable, never "phantom").
uint64_t deadParamMask(const llvm::Function &F, const TaintSet &taint);

// Delete the DEAD part of the backward cone of `Seeds` in `F`: every dead
// instruction reachable from a seed through operands of dead instructions, closed
// forward over dead users (every user of a dead instruction is dead, or it would be
// live), never a root (see `isLivenessRoot`). Then fold each conditional branch
// with an EMPTY arm whose arm or common successor this call touched — a block the
// deletion touched, or one of `Touched` (a block the CALLER emptied: the fenv
// stages erase stores themselves) — with SimplifyCFG's two empty-arm folds (see
// the definition), and delete the now-dead condition cone the same way. Arms with their address taken and the entry block are never touched.
// Returns the number of instructions deleted. `Stage` names the caller for the
// env-gated `CQ_DEADCONE_DBG` census line.
//
// ⚠ THE CALLER'S OBLIGATION — THIS FUNCTION CAN GROW THE TAINT SET (bd otam; bd
// vsfp Rule-13 r2A F-WA-1, retirement trigger per CLAUDE.md L8). The two-entry-φ
// fold creates `select Cond, vT, vF`; when `Cond` is tainted the select is a NEW
// tainted value (a φ of classical incomings is not tainted by data flow; the
// select is, through its condition), and so is every user it takes over. `taint`
// is read here only for the ROOT set (membership lists, the specializer record),
// never `taint.Tainted`, so this function itself is unaffected — but a caller
// that does not re-`propagate` after a call that changed the IR leaves
// `taint.Tainted` STALE for every later stage. Every caller is in the pre-guard
// window (the drop's two slots, the three volatile folds, the promotion) and
// re-`propagate`s when its stage returns true; `declineStaleTaintSet` re-derives
// the set before `detectSpecializations` so an omission is loud. A caller added
// AFTER the guards owes `adjudicateTaintDelta`, not just a `propagate` (L1). The
// one post-`specialize()` caller, `buildClone` (bd sqjq, round 4), runs on a clone
// body that `lowerCloneControl`'s backstop has already made ONE BLOCK, so the fold
// cannot fire there and no select is created — it only deletes.
//
// Round-4 contract items (bd vsfp Rule-13 r3A/r3B):
//   * the fold's condition seeds are `WeakTrackingVH`s (bd 1xp9): a seed that is
//     an `i1` φ in an earlier fold's merge block is erased by that block's merge
//     and the handle FOLLOWS its RAUW to the replacement, so the recursion never
//     reads freed memory and still deletes the replacement if it is dead;
//   * the two-entry-φ fold goes through `simplifySelectInst` first (`select %c,
//     i1 true, i1 false` IS `%c`), as SimplifyCFG's own fold does;
//   * a dead value that is an operand of a LIVE call in a slot the specializer
//     RECORDED dead (the call-slot rule) is replaced there by a null of the
//     CALLEE PARAMETER's type before deletion — an inner clone call inherits the
//     dead slot; unreachable before `specialize()`, whose record is empty.
unsigned deleteDeadCones(llvm::Function &F, llvm::ArrayRef<llvm::Value *> Seeds,
                         const TaintSet &taint, llvm::StringRef Stage,
                         llvm::ArrayRef<llvm::BasicBlock *> Touched = {});

}  // namespace cq

#endif  // CQ_IRPASS_DEAD_VALUE_LIVENESS_H_
