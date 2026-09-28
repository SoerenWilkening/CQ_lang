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
// predicate) does not become live through that call when the slot is REWRITABLE
// (null-safe), or when it is an int/fp UNREAD SCALAR slot and the operand is a
// function ARGUMENT (bd `nlfd`; see `isUnreadScalarSlot`). Nothing else is looked
// up: before `specialize()` no record exists, so every slot of every call counts
// as a read — the dead-argument drop gets its interprocedural reach from its own
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

// A recorded-dead slot that the one rewrite may also NULL: `isRecordedDeadSlot` AND
// `nullSafeSlot` (SpecializeDetect.h — an int/fp scalar, no `byval`/`returned`/
// `swifterror`/…, only allowlisted attributes). ⚠ NOT the drop's whole eligibility
// (`dropEligibleSlot`): round 5 asked that, and its `musttail` POLICY conservatism
// turned an inner dead slot into a read, one clone level up into a LIVE outer slot,
// and bd `tzfa`'s wrong unitary back (bd `w7nm`, r5 F-Z-1). THE ONE SLOT QUESTION
// (Rule 14): the rewrite, M-C arm (d0) (ArithLowering.cpp) and M-A's
// `cloneArgReachesResult` (RotationLowering.cpp) ask THIS; the liveness call-slot
// rule asks it AND `isUnreadScalarSlot` (below — bd `nlfd`); `resolvePhantomClone
// ArgReads` also asks the bare record, because it is the stage that resolves the
// difference at module level (a recorded-dead, not null-safe slot: kept when its
// operand is classical, declined when quantum). A slot this calls "read" but the
// record calls dead is treated as READ by the rewrite, M-C and M-A. ⚠ That is NOT
// "the conservative direction for each consumer", which round 6 wrote here (bd vsfp
// Rule-13 r6: F-R6-1 / bd `nlfd`, F-R6-2 / bd `x8ut`). Per consumer:
//   * M-C (d0): conservative — "not settled" falls to the out-of-place path.
//   * LIVENESS: was NOT conservative (bd `nlfd`, P2, IR-only) and no longer asks
//     this alone. A read counted there propagates one clone level up through
//     `deadParamMask`: a recorded-dead inner slot that is not null-safe made the
//     enclosing clone's parameter LIVE, the outer (null-safe) phantom slot was
//     never neutralised, and bd `tzfa`'s wrong unitary was back (r6 `sa1.ll`: a
//     string attribute on the inner slot; exit 0, warned, the ORACLE's stream).
//     Since bd `nlfd` an ARGUMENT in an unread scalar slot is not a read, and an
//     INSTRUCTION there that keeps a HANDLE parameter alive declines in
//     `buildClone` (see `isUnreadScalarSlot`).
//   * M-A (`cloneArgReachesResult`): NOT conservative — its one caller,
//     `reachesObservingSink`, is the clause-3 EXEMPTION walk, where a hop EXEMPTS
//     a record. It is UNREACHABLE today: M-A gates are rotations, which occur only
//     in non-clone functions (`scanBody` declines `cq_theta` in a clone), and there
//     `resolvePhantomCloneArgReads` step 1 DECLINES a quantum operand in a
//     recorded-dead, not-null-safe slot before `lowerRotations` runs.
//     RETIREMENT TRIGGER (L8): the day that decline is relaxed or moved after
//     `lowerRotations`, or a rotation can occur inside a clone body, M-A must go
//     back to the bare `isRecordedDeadSlot` (its honest question is "does the
//     clone's result depend on this argument?", not "is a null safe here?").
bool isRewritableDeadSlot(const llvm::CallBase &CB, unsigned ArgNo,
                          const TaintSet &taint);

// bd `test_C_libtooling-nlfd` — an UNREAD SCALAR slot: `isRecordedDeadSlot` AND the
// slot is an integer or floating-point scalar (by the call's function type). No
// VALUE placed there is observed: the callee never reads it (the record is exact
// for the built clone, bd sqjq) and a scalar is not dereferenced by the call (a
// `byval`/`inalloca`/`preallocated` slot is a pointer and copies its pointee AT
// THE CALL — never this). It is the premise LLVM's own DAE rests on when it puts
// `poison` in a dead slot whatever the slot's other attributes; the only way a value
// here can still matter is a VALUE CONSTRAINT on the slot (`noundef`: a real value
// never violates it; `range`/`nofpclass`: stripped by
// `stripUnreadSlotValueConstraints` wherever a null can now arrive). `returned` and
// `allocalign` cannot bite: clones carry no `returned` (`stripStaleClassicalAttrs`)
// and never return a pointer (SpecializeReject's ABI-return clause).
// ⚠ It is NOT a licence to WRITE a constant there — that is `nullSafeSlot`'s
// question, whose attribute allowlist is a POLICY (the drop leaves a string or
// unknown attribute alone). Its two uses are the liveness call-slot rule (an
// ARGUMENT operand of such a slot is not a read — the value reaching it is decided
// one level up, where the slot IS null-safe) and `SlotReads::Value`.
bool isUnreadScalarSlot(const llvm::CallBase &CB, unsigned ArgNo,
                        const TaintSet &taint);

// Strip the two VALUE CONSTRAINTS a null can violate — `range` and `nofpclass` —
// from parameter `ArgNo` of `CB`'s callee and from the call site's slot. Part of the
// one rewrite (`rewriteRecordedDeadSlotUse`), and asked on its own by `buildClone`
// for an unread scalar slot whose operand is a parameter the record calls dead: the
// caller's neutralised `0` arrives there through that parameter (bd `nlfd`).
void stripUnreadSlotValueConstraints(llvm::CallBase &CB, unsigned ArgNo);

// THE ONE REWRITE of a recorded-dead slot (bd vsfp round 4; Rule 14 — three sites
// used to spell it): if `U` is an argument operand of a call in a slot
// `isRewritableDeadSlot` names, and it is not already a constant, set it to the null
// constant of the CALLEE PARAMETER's type (bd f061: after retargeting, an fp slot
// is an `i32` handle — never the operand's type) and strip `range`/`nofpclass` from
// the parameter and the call site. ⚠ bd `91k9` (round 5; r4A F-YA-1): round 4's
// text said this was "the drop's rewrite" and that the strip was "the constraint DAE
// strips too" — FALSE: the drop never rewrites a pointer, a `byval`/`inalloca`/
// `preallocated` slot or a slot with an attribute outside its allowlist, and this
// rewrite nulled all of them (a `byval` struct slot → `ptr byval null`: the plain-C
// executable SIGSEGVed; `ptr nonnull dereferenceable(16) null` — immediate UB). It
// now asks `nullSafeSlot` (round 5 asked the drop's whole eligibility — bd `w7nm`),
// and on a null-safe slot
// the only attributes that can be present are the allowlist, of which `range` /
// `nofpclass` are the only ones a null can violate — hence exactly that strip.
// An ineligible slot is left alone (a classical pointer there costs nothing; a
// QUANTUM operand there is declined by `resolvePhantomCloneArgReads`). Returns
// true iff it rewrote. Callers: `resolvePhantomCloneArgReads`
// (a module-level call), `buildClone` (an inner clone call reading a dead
// PARAMETER directly) and `deleteDeadCones` step 3 (an inner clone call reading a
// dead INSTRUCTION) — so a nested clone call inherits the dead slot (bd sqjq).
bool rewriteRecordedDeadSlotUse(llvm::Use &U, const TaintSet &taint);

// Which call-slot operands a recorded-dead slot keeps alive (the call-slot rule).
//   * Existence (the default, every client but one): must this value still EXIST?
//     A rewritable slot's operand does not (the rewrite nulls it); an unread scalar
//     slot's ARGUMENT operand does not (an argument is never deleted); an unread
//     scalar slot's INSTRUCTION operand that the rewrite may not null DOES (it is
//     still a use of the call).
//   * Value: is this value's VALUE ever observed? No unread scalar slot observes
//     its operand. Asked only by `buildClone` (bd `nlfd`): a HANDLE parameter live
//     under Existence and dead under Value is kept alive only by a computation
//     whose result nothing reads — a phantom read the caller's slot cannot shed.
enum class SlotReads { Existence, Value };

// The liveness of one function body, computed once at construction.
class FunctionLiveness {
public:
  FunctionLiveness(const llvm::Function &F, const TaintSet &taint,
                   SlotReads Mode = SlotReads::Existence);
  // `V` is an Instruction or Argument OF THIS FUNCTION; anything else (a
  // constant, a global, another function's value) answers false.
  bool isLive(const llvm::Value *V) const;

private:
  llvm::SmallPtrSet<const llvm::Value *, 32> Live;
};

// Bit i set ⇔ parameter i of `F` is DEAD under `FunctionLiveness` in `Mode`.
// Parameters at index ≥ 64 are reported LIVE (never droppable, never "phantom").
uint64_t deadParamMask(const llvm::Function &F, const TaintSet &taint,
                       SlotReads Mode = SlotReads::Existence);

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
// cannot fire there and no select is created. ⚠ Not "it only deletes" (round 4's
// wording, r4A F-YA-3): step 3 also REWRITES the operand of a live inner call in a
// rewritable recorded-dead slot to a constant (the inherit). A rewrite to a
// constant shrinks the taint set and never grows it, so the conclusion stands —
// no select, no taint growth, no adjudication owed.
//
// Round-4 contract items (bd vsfp Rule-13 r3A/r3B):
//   * the fold's condition seeds are `WeakTrackingVH`s (bd 1xp9): a seed that is
//     an `i1` φ in an earlier fold's merge block is erased by that block's merge
//     and the handle FOLLOWS its RAUW to the replacement, so the recursion never
//     reads freed memory and still deletes the replacement if it is dead;
//   * the two-entry-φ fold goes through `simplifySelectInst` first (`select %c,
//     i1 true, i1 false` IS `%c`). ⚠ NOT "as SimplifyCFG's own fold does" (round
//     4's wording, bd `w9xe`): SimplifyCFG builds with `IRBuilder<NoFolder>`; the
//     `-O1` twin loses the select in InstCombine;
//   * a dead value that is an operand of a LIVE call in a slot the specializer
//     RECORDED dead (the call-slot rule) is replaced there by a null of the
//     CALLEE PARAMETER's type before deletion — an inner clone call inherits the
//     dead slot; unreachable before `specialize()`, whose record is empty.
unsigned deleteDeadCones(llvm::Function &F, llvm::ArrayRef<llvm::Value *> Seeds,
                         const TaintSet &taint, llvm::StringRef Stage,
                         llvm::ArrayRef<llvm::BasicBlock *> Touched = {});

}  // namespace cq

#endif  // CQ_IRPASS_DEAD_VALUE_LIVENESS_H_
