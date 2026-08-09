// LiteralIntegrity.cpp — see header for the full argument. Two guards, one
// invariant: an emitted gate's LITERAL operands must denote the value the source
// specified, identically at every site the lowering copies them to.
//
//   GUARD 1  declineUnpairedUndefLiterals  (bd xy9n)  — the poison PAIRING break
//   GUARD 2  declineAddressTakenBlocks     (bd 7udx)  — the blockaddress -> i32 1
//
// Neither is visible to `opt -verify` or to `free_pairing_check.py`.

#include "LiteralIntegrity.h"

#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Transforms/Utils/Local.h"  // removeUnreachableBlocks

using namespace llvm;

namespace cq {

namespace {

// Rule-12 mirrors, character-for-character:
//   * lowering_reject_undef_literal_paired_dead_chain.ll     (NO control at all)
//   * lowering_reject_undef_literal_paired_undef_spelling.ll (the `undef` spelling)
//   * lowering_reject_undef_literal_paired_rz_angle.ll       (rotation-angle slot,
//       the negated-angle re-emission an `_unc` name test would miss)
//   * control_swap_reject_select_undef_literal_paired.ll     (bd xy9n's own 4.4
//       select exhibit — covered BY the module-wide guard, not by a select gate)
//   * lowering_reject_undef_literal_paired_alias_unc.ll      (the ONLY row pinning
//       `isEmittedRuntimeCallee`'s called-OPERAND test — the hole that shipped the
//       full xy9n break through a `GlobalAlias` adjoint)
// THREE accept controls, each the sole guard against re-widening a decision this
// change paid for:
//   * lowering_accept_undef_literal_single_slot.ll      the THRESHOLD (2, not 1) —
//       what keeps `tests/e2e/slice_libm_real_nexttoward`'s committed golden green
//   * lowering_accept_undef_literal_two_functions.ll    the PER-FUNCTION scope
//   * lowering_accept_undef_literal_global_init_pad.ll  the GlobalValue-address skip
constexpr char kMsgUndefPaired[] =
    "cq literal integrity: undef/poison literal reaches two emitted gate "
    "operands";

// Rule-12 mirrors, character-for-character — one per distinct CALL SITE, because
// each site passes its own doomed-block set and a site that stops calling the
// predicate must go red somewhere:
//   * control_predmux_reject_blockaddress_inregion.ll   (PredMux claim)
//   * control_swap_reject_blockaddress_diamond_arm.ll   (`flattenRegion`)
//   * control_swap_reject_blockaddress_nested_mid.ll    (`flattenRegionTree`)
//   * control_swap_reject_blockaddress_switch_arm.ll    (`flattenSwitchRegion`)
//   * control_swap_reject_blockaddress_abort_arm.ll     (AbortParkEmit)
//   * lowering_qram_reject_blockaddress_guarded_arm.ll  (GuardedStoreArmEmit)
//   * the `removeUnreachableBlocks` site takes THREE rows, each pinning a different
//     property of it, because the first two do not cover the third:
//       - lowering_fp80_reject_blockaddress_unreachable.ll        it is guarded AT ALL
//       - lowering_fp80_reject_blockaddress_markalive.ll          the guard OBSERVES
//           the deletion set rather than predicting it
//       - lowering_fp80_reject_blockaddress_markalive_entry.ll    the `!dbg` anchor
//           survives the mutating call (an earlier draft SIGSEGV'd here)
// SCOPE is pinned by the accept control
// control_swap_accept_blockaddress_outside_region.ll — a `blockaddress` naming a
// SURVIVING block still lowers, with its address intact.
constexpr char kMsgAddressTakenBlock[] =
    "cq literal integrity: address-taken block erased under quantum control";

// Loud `DiagnosticInfoUnsupported(DS_Error)` with the offending instruction's
// `!dbg` — the one diagnostic surface the whole pass speaks (same idiom as
// `TaintPropagation::diagnoseEscape`, `FreePoint::diagnose` and
// `RotationLowering::diagnoseUnsupported`); `opt` exits non-zero, which the
// negative LIT fixtures invert with `RUN: not`.
void diagnose(const Instruction *I, StringRef Msg) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(), Msg, I->getDebugLoc()));
}

}  // namespace

namespace {

// The shared walk. `SkipGlobals` is the ONLY difference between the two exported
// predicates, and it is load-bearing — see `slotCarriesUndef`.
bool carriesUndefImpl(const Constant *C,
                      SmallPtrSetImpl<const Constant *> &Seen,
                      bool SkipGlobals) {
  if (isa<UndefValue>(C))
    return true;
  // A `GlobalValue`'s operands are its INITIALIZER, while the value under test is
  // the global's ADDRESS — which is defined no matter what it is initialised to.
  if (SkipGlobals && isa<GlobalValue>(C))
    return false;
  if (!Seen.insert(C).second)
    return false;
  for (const Value *Op : C->operands())
    if (const auto *CO = dyn_cast<Constant>(Op))
      if (carriesUndefImpl(CO, Seen, SkipGlobals))
        return true;
  return false;
}

}  // namespace

bool constantCarriesUndef(const Constant *C,
                          SmallPtrSetImpl<const Constant *> &Seen) {
  return carriesUndefImpl(C, Seen, /*SkipGlobals=*/false);
}

bool valueCarriesUndef(const Value *V) {
  const auto *C = dyn_cast<Constant>(V);
  if (!C)
    return false;
  SmallPtrSet<const Constant *, 8> Seen;
  return constantCarriesUndef(C, Seen);
}

bool slotCarriesUndef(const Value *V) {
  const auto *C = dyn_cast<Constant>(V);
  if (!C)
    return false;
  SmallPtrSet<const Constant *, 8> Seen;
  return carriesUndefImpl(C, Seen, /*SkipGlobals=*/true);
}

bool isEmittedRuntimeCallee(const CallBase *CB) {
  // *** TEST THE CALLED OPERAND, NOT THE RESOLVED `Function`. ***
  // `Module::getOrInsertFunction(Name, FT)` returns
  // `FunctionCallee{FT, getNamedValue(Name)}` — the GlobalValue under that name,
  // which need NOT be a `Function`. `EmitInverse` mints every `_unc` twin through
  // exactly that call, so if the INPUT module defines e.g.
  // `@cq_template_add_i32_hl_unc = internal alias void (i32,i32,i32), ptr @body`,
  // the adjoint's called operand is a `GlobalAlias` and
  // `CallBase::getCalledFunction()` (a `dyn_cast_or_null<Function>`) returns null.
  // An earlier draft used `getCalledFunction()` and the Rule-13 round shipped the
  // full xy9n break through that hole with `opt` exit 0 — the adjoint slot was
  // simply not counted, so the module read 1 slot instead of 2.
  //
  // And do NOT reach for `stripPointerCasts()`: that RESOLVES the alias to
  // `@body`, whose name carries no family prefix, and the hole stays open. The
  // operand's OWN name is the right test, and it covers `Function`, `GlobalAlias`
  // and `GlobalIFunc` uniformly. A genuinely indirect call has a non-GlobalValue
  // operand and is not an emitted gate.
  const auto *GV = dyn_cast<GlobalValue>(CB->getCalledOperand());
  if (!GV)
    return false;
  StringRef N = GV->getName();
  return N.starts_with("cqrt_") || N.starts_with("cq_template_") ||
         N.starts_with("__cq_q_");
}

const Instruction *findUndefOperandInBody(const Function &F) {
  // TRANSITIVE over directly-called DEFINED callees, not just `F`'s own body.
  //
  // An earlier draft scanned only `F`, and the Rule-13 delta round showed the hole:
  // put the undef-bearing computation in a classical helper that the clone CALLS,
  // and the twin duplicates the CALL rather than the computation — two distinct
  // static call sites reading one shared callee body, whose single `undef` slot is
  // then read twice DYNAMICALLY and may differ. The round could not exhibit a
  // divergence at the shipped `-O1` stage 1 (which inlines such a helper, collapsing
  // it back into the caught form), but a `noinline` helper survives, and
  // over-declining is the safe direction.
  //
  // TERMINATION AND COST: a `Seen` set over `Function*`, so each function body is
  // walked at most once and the whole walk is bounded by the module's function
  // count. Cycles terminate structurally. This is not a new reachability
  // assumption — every callee a Phase-6 clone can reach is already proven pure and
  // acyclic by `SpecializeReject::scanBody` before a clone is minted at all.
  SmallPtrSet<const Function *, 8> Seen;
  SmallVector<const Function *, 8> Work;
  Work.push_back(&F);
  while (!Work.empty()) {
    const Function *G = Work.pop_back_val();
    if (!G || G->isDeclaration() || !Seen.insert(G).second)
      continue;
    for (const Instruction &I : instructions(*G)) {
      for (const Use &U : I.operands())
        if (slotCarriesUndef(U.get()))
          return &I;
      // Only a DIRECT call to a visible definition can share a body with the twin.
      // An indirect or declared callee has no body to duplicate a read of.
      if (const auto *CB = dyn_cast<CallBase>(&I))
        Work.push_back(CB->getCalledFunction());
    }
  }
  return nullptr;
}

bool declineUnpairedUndefLiterals(Module &M) {
  // The FIRST offending site is remembered but not diagnosed. A lone slot has no
  // ADJOINT — every adjoint CQ emits is a fresh static call (`EmitInverse`'s
  // `CreateCall`/`CreateFNeg`/`CreateNeg`, `BreakReversePlay`'s `clone()`), never
  // a re-execution of the forward site — so nothing claims to invert it and no
  // `cqrt_free` asserts `|0⟩` on its behalf. (Do NOT restate this as "one slot is
  // one materialisation": that is measurably false inside a rolled loop, where one
  // static slot is read once per trip. See LiteralIntegrity.h.) The measured
  // real-code instance is `slice_libm_real_nexttoward` — 985 emitted calls, one
  // undef-bearing slot, rail never freed.
  //
  // The SECOND slot is the pairing channel, and it is where the diagnostic fires:
  // it is normally the adjoint, the more informative of the two sites.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // PER FUNCTION, not per module. An earlier draft counted module-wide, to catch
    // the Phase-6 clone/twin pair that lives in two separate functions — and the
    // Rule-13 round measured the cost of that: a TU holding TWO libm cells, each
    // with its own `clang -O1` dead-edge `select i1 %c, double undef, double %v`,
    // has two independent `cqrt_alloc_<W>(undef)` slots in two different functions
    // and DECLINED, even though each one is individually the shape
    // `lowering_accept_undef_literal_single_slot.ll` certifies as sound and neither
    // rail is ever freed. Two libm cells in one TU is an ordinary multi-slice.
    //
    // Per-function is sound ONLY because the cross-function pairing has its own
    // fence: a literal baked into a Phase-6 clone body is caught by
    // `findUndefOperandInBody` at `synthUncomputeTwin`, BEFORE the twin is cloned
    // (that scan covers call-argument literals too). The other conceivable
    // cross-function shape — a `__cq_q_f(poison)` forward and its
    // `__cq_q_f_unc(out, poison)` adjoint — has BOTH calls in the CALLER, so a
    // per-function count still sees two. Every other adjoint the pass emits (the
    // whole-DAG spine, the control emitters' compare strips, the loop reverse-play)
    // is emitted into the same function as its forward.
    //
    // RESIDUAL, deliberately accepted: two INDEPENDENT single-slot occurrences in
    // ONE function still decline. Direction is safe and the measured population is
    // zero (no TU in 966 fixtures + 257 e2e + 251 openlibm modules has two
    // undef-bearing gate slots in one function). Do NOT "fix" it by keying on
    // `Constant` identity: `undef`/`poison` are UNIQUED PER TYPE, so every
    // `double undef` in a module is the SAME `Constant *` and identity-keying
    // would decline the two-cell TU all over again.
    const Instruction *First = nullptr;
    for (Instruction &I : instructions(F)) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB || !isEmittedRuntimeCallee(CB))
        continue;
      // Slots rather than calls, but note this is currently a DISTINCTION WITHOUT
      // A DIFFERENCE, and an earlier comment here justified it with a shape that
      // does not exist. Every emitted symbol has at most ONE non-handle operand —
      // `cqrt_alloc_<W>(value)`, `cqrt_ry/rz_<W>(handle, angle)`,
      // `cqrt_xorc/addc_<W>(handle, imm)`, and the `_hl`/`_lh` template grammar
      // (`_qq` has none) — so no single call can carry two literal slots today and
      // the Rule-13 round measured that no fixture can pin the difference. Counting
      // slots is kept because it is the formulation that stays correct if a
      // two-literal symbol is ever added; it is NOT load-bearing now.
      for (const Use &A : CB->args()) {
        // `slotCarriesUndef`, NOT `valueCarriesUndef`: the global-ADDRESS skip is
        // required here. `clang -O1` really emits
        // `@v = global { i32, [12 x i8] } { i32 3, [12 x i8] undef }` for a
        // partially-initialised `union { long double f; int i; }` — the exact fp80
        // union idiom this project is built on — and `ptrtoint (ptr @v to i32)` in
        // a gate slot reads as an undef leaf without the skip. That is a
        // WELL-DEFINED program (one uniqued relocation, forward and adjoint agree),
        // and the Rule-13 round measured this guard declining it. The PredMux cone
        // predicate keeps the un-skipped `valueCarriesUndef` byte-for-byte as
        // shipped — there, the over-decline is pre-existing and removing it would
        // be an accept widening (bd ajw7).
        if (!slotCarriesUndef(A.get()))
          continue;
        if (!First) {
          First = &I;
          continue;
        }
        diagnose(&I, kMsgUndefPaired);
        return true;
      }
    }
  }
  return false;
}

bool declineAddressTakenBlocks(ArrayRef<BasicBlock *> Blocks,
                               Instruction *At) {
  for (BasicBlock *BB : Blocks) {
    if (!BB || !BB->hasAddressTaken())
      continue;
    // *** `hasAddressTaken()` IS A REFCOUNT, NOT A USE TEST — and that difference
    // is a real over-decline, measured by the Rule-13 round. ***
    //
    // `llvm::CloneFunctionInto` deliberately does, for every block of the source
    // function whose address is taken,
    //     VMap[BlockAddress::get(OldFunc, &BB)] = BlockAddress::get(NewFunc, CBB);
    // (its own comment: "we want to map block addresses from the old function to
    // block addresses in the clone"). CONSTRUCTING that second `BlockAddress`
    // bumps the CLONE block's refcount, so `hasAddressTaken()` is true on a Phase-6
    // clone block even though the constant lives only in the mapper's table and has
    // ZERO users. The `~BasicBlock()` RAUW then rewrites nothing, so erasing such a
    // block corrupts nothing — yet the first draft of this guard declined a module
    // the pre-change plugin lowered correctly, with the real `blockaddress` intact.
    //
    // Test whether anything can OBSERVE the address. `BlockAddress::lookup` returns
    // the existing constant for this block (uniqued per (F, BB), so at most one) or
    // null. `use_empty()` alone is NOT the right question: a `BlockAddress` referenced
    // only from METADATA has no Uses, yet the erase still rewrites that reference —
    // so `isUsedByMetadata()` is part of the test. (The delta round could not turn the
    // metadata channel into an executable divergence, and every realistic runtime
    // carrier — `@llvm.used`, a GlobalVariable initializer, `indirectbr`,
    // `select`/`store` of the address — IS a real Use that already declined. The
    // clause is here because the guard's stated invariant is "nothing can observe the
    // erase", and metadata observes it.) This cannot re-open the `CloneFunctionInto`
    // over-decline: its VMap-only `BlockAddress` is neither used NOR
    // metadata-referenced.
    const BlockAddress *BA = BlockAddress::lookup(BB);
    if (!BA || (BA->use_empty() && !BA->isUsedByMetadata()))
      continue;
    // Anchor the `!dbg` on a still-live instruction. `At` is the caller's
    // choice (a region's branch or condition); fall back to the offending
    // block's own terminator, which is still valid — nothing has been erased
    // yet, because every caller invokes this BEFORE its first erase.
    const Instruction *Anchor = At;
    if (!Anchor)
      Anchor = BB->getTerminator();
    // `&*BB->begin()` on an EMPTY block dereferences `end()`, which is UB — so
    // the emptiness test comes FIRST, not as an afterthought on the result.
    if (!Anchor && !BB->empty())
      Anchor = &*BB->begin();
    if (!Anchor)
      continue;  // an empty, terminator-less block cannot carry a `!dbg`.
    diagnose(Anchor, kMsgAddressTakenBlock);
    return true;
  }
  return false;
}

bool removeUnreachableBlocksChecked(Function &F, Instruction *At) {
  // *** DO NOT MODEL LLVM'S DELETION SET — OBSERVE IT. ***
  //
  // An earlier draft predicted the set with a plain depth-first walk from the
  // entry and checked the complement, on the reading that
  // `llvm::removeUnreachableBlocks` deletes exactly the DFS-unreachable blocks.
  // The Rule-13 round MEASURED that WRONG: LLVM 19's `removeUnreachableBlocks`
  // first runs `markAliveBlocks`, which MUTATES the function — a `store` to a
  // null pointer, a call to a `noreturn` callee, or an `llvm.assume(false)` is
  // rewritten to `unreachable`, which orphans blocks that WERE DFS-reachable a
  // moment earlier. So the true deletion set is a strict SUPERSET of the
  // prediction, and the round shipped the `blockaddress`→`i32 1` miscompile
  // through that gap with `opt` exit 0 on three independent triggers.
  //
  // Any predictive model of a mutating LLVM utility is a hole waiting to open on
  // the next LLVM release. So: watch every block whose address is genuinely used,
  // run the real utility, and decline if a watched block actually died. There is
  // nothing left to get wrong, and it tracks LLVM 19 -> 20 for free.
  SmallVector<WeakTrackingVH, 8> Watched;
  for (BasicBlock &BB : F) {
    if (!BB.hasAddressTaken())
      continue;
    // Same observability test as `declineAddressTakenBlocks`, metadata clause
    // included — a refcount bumped only by `CloneFunctionInto`'s VMap entry is
    // neither used nor metadata-referenced, so it is not watched.
    const BlockAddress *BA = BlockAddress::lookup(&BB);
    if (BA && (!BA->use_empty() || BA->isUsedByMetadata()))
      Watched.push_back(&BB);
  }
  // Fast path, and the path every module in every corpus takes today.
  if (Watched.empty())
    return removeUnreachableBlocks(F);

  // *** THE ANCHOR MUST BE A WEAK HANDLE, NOT A RAW POINTER. ***
  // An earlier draft held `At` as a raw `Instruction *` across the call below and
  // the Rule-13 judge found a DETERMINISTIC SIGSEGV (exit 139, 3/3 runs) on two of
  // the three markAlive triggers. `markAliveBlocks` reaches
  // `changeToUnreachable(I)`, which ERASES `I` — and `Fp80Union` passes the entry
  // block's FIRST instruction, which is exactly that instruction whenever the
  // trigger is a store-to-null or an `llvm.assume(false)` at the top of the entry
  // block. Diagnosing through the freed pointer then crashes `opt` on valid input.
  // (The `noreturn` trigger did NOT crash — there `changeToUnreachable` is applied
  // to the call's SUCCESSOR — so any change here must be re-tested against the
  // store-to-null and assume spellings specifically.)
  WeakTrackingVH AnchorVH(At);
  bool Changed = removeUnreachableBlocks(F);
  for (WeakTrackingVH &H : Watched) {
    if (H.pointsToAliveValue())
      continue;
    // Re-derive the anchor AFTER the mutation. The caller's choice if it survived,
    // else the post-call entry terminator, which is live by construction (the entry
    // block is never deleted, and `markAliveBlocks` leaves it terminated).
    const auto *Anchor = dyn_cast_or_null<Instruction>(AnchorVH.operator Value *());
    if (!Anchor)
      Anchor = F.getEntryBlock().getTerminator();
    if (Anchor) {
      diagnose(Anchor, kMsgAddressTakenBlock);
    } else {
      // No instruction left to hang a `!dbg` on. Diagnose ANYWAY, without a
      // location: returning "declined" silently over an already-corrupted module
      // would be a guard with a quiet-success path, which is the one shape this
      // whole file exists to prevent.
      F.getContext().diagnose(
          DiagnosticInfoUnsupported(F, kMsgAddressTakenBlock));
    }
    return true;
  }
  return Changed;
}

}  // namespace cq
