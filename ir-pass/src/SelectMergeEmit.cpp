// SelectMergeEmit.cpp — see header. The mutating controlled-XOR copy merge for an
// accepted tainted-condition integer-data `select` (Phase 4.4 / PRD Part IV
// §16.3; IMPLEMENTATION-4.4 §4). NO work rail, NO route `cqrt_cswap`, NO
// `RegionFlatten`, NO reverse-play (the br-diamond value arm reuses it via
// `emitValueRegion`). Reuses `lowerCompareToFlag` (mint/strip), `allocFn`/
// `freeFn` (rail + the one free), `copyControlledFn` (the merge primitive), and
// `xFn` (the ¬flag bracket) verbatim (Rule 14); the only original logic is the
// six-step ordering, which IS the §5a contract.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2):
// with `%out` allocated to |0>, `copy_c(f, a, out)` writes a iff f=1 and the
// X-bracketed `copy_c(f, b, out)` writes b iff f=0, so `%out = f ? a : b` with no
// double-write on either basis branch — provided the `cqrt_x` encloses ONLY the
// second copy (the §16.3 bracket-order hazard, invisible to a count-only CHECK;
// pinned by the §5a ordered FileCheck). The flag is stripped by `icmp_inv` (q is
// untouched — the copies write `out`, never q — so q == q0 and the strip is
// valid) and freed; q, `%out`, and both operands are left allocated (Rule 6/8).

#include "SelectMergeEmit.h"

#include "CompareLowering.h"    // lowerCompareToFlag (mint + _inv strip)
#include "ControlPlan.h"        // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // copyControlledFn / xFn / cnotFn / toffoliFn
#include "OpcodeSupport.h"      // abiWidthFromType
#include "CondTreeEmit.h"       // emitCondNetwork / stripCondNetwork (3qlq P3)
#include "SelectClassify.h"     // CondTree / collectCondTree (the shared walk)
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"      // allocFn / freeFn / llvmWidthType

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>
#include <vector>  // copySourceLedger (bd r2j3.14)

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1 — the dangling-work-list SIGSEGV). A per-TU
// mirror of `SwapRouteEmit::scrubTaint` (the house style for trivial taint-set
// maintenance, cf. the duplicated `isMeasureSink`). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  // 3c6m.12 design-review NIT: mirror the Phase-7.1 scrub — step 6 now erases
  // a new instruction class (condition-tree nodes/leaves), and a lingering
  // HandleWidth entry on a freed Instruction* is an address-reuse phantom
  // width waiting to happen. Vacuous for today's erased classes; closed by
  // construction. (All of this function is now belt-and-braces since bd 8e5r: every TaintSet table drops a deleted key by itself, `ScrubOnDelete.h`.)
  taint.HandleWidth.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase_value(CI);
  }
}

}  // namespace

// Shared copy-source materializer (promoted from the former file-local `static
// materialize`; see SelectMergeEmit.h for the contract). Now consumed by the
// select merge below, `SwitchDataMuxEmit`, and `ClassicalCallArmEmit` (Rule 14).
namespace {
// bd r2j3.14 — the classical copy sources loaded so far, for the final-taint
// re-ask. A function-local static, the pattern of `exitDischargeObligations` (no
// new `TaintSet` field). `WeakVH`: a load erased since is nothing to re-ask, and
// the handle must NOT follow a RAUW (it names the load, whose operand is read).
std::vector<WeakVH> &copySourceLedger() {
  static std::vector<WeakVH> Ledger;
  return Ledger;
}
}  // namespace

Value *materializeCopySource(Value *V, FunctionCallee Alloc,
                             const TaintSet &taint, IRBuilder<> &B,
                             const DebugLoc &DL, const Twine &Name) {
  if (taint.Tainted.count(V))
    return V;  // already an i32 quantum handle.
  CallInst *H = B.CreateCall(Alloc, {V}, Name);
  if (DL)
    H->setDebugLoc(DL);
  if (!isa<Constant>(V))
    copySourceLedger().emplace_back(H);  // re-asked at final taint (r2j3.14).
  return H;
}

bool declineQuantumCopySources(Module &M, TaintSet &taint) {
  (void)M;  // module-wide record; each load names its own function.
  std::vector<WeakVH> Ledger;
  Ledger.swap(copySourceLedger());  // read once: the next module starts empty.
  for (const WeakVH &H : Ledger) {
    auto *Load = dyn_cast_or_null<CallInst>(static_cast<Value *>(H));
    if (!Load || !Load->getFunction() || Load->arg_size() != 1)
      continue;  // erased or detached: no load left to read.
    if (taint.Tainted.count(Load->getArgOperand(0))) {
      diagnoseUnderControl(Load, "classical copy source became quantum-derived");
      return true;
    }
  }
  return false;
}

void emitSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint) {
  auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
  // 3c6m.12 (L4): the condition is a `CmpInst` or an `and i1`/`or i1` TREE
  // over `CmpInst` leaves — re-derived here via the SAME `collectCondTree`
  // walk the classifier accepted with (SelectClassify.h; the walk cannot
  // drift). A bare compare is the degenerate single-leaf tree whose emission
  // below is byte-identical to the pre-L4 stream.
  //
  // ── bd `boi6` (D-B) / Track M, HAZARD H-1: `R.Condition` IS A RAW `Value *`
  // AND BY NOW IT CAN BE FREED MEMORY. Read the condition off the SELECT. ──────
  //
  // `ControlRegion::Condition` (`ControlPlan.h`) is a plain `Value *`, not a
  // `WeakTrackingVH`, and `classifySelectRegion` filled it with
  // `Sel->getCondition()` at DETECTION time. Since Track M that condition may be
  // the MERGE φ of a controlled state-prep / in-place-Ry diamond, and that
  // region's `emitInPlaceRotationRegion` ends in
  // `MergePhi->replaceAllUsesWith(Gates.back().first); MergePhi->
  // eraseFromParent(); flattenRegion(...)`. So once the prep has emitted, the φ
  // this region recorded is DESTROYED: dereferencing `R.Condition` here is a
  // use-after-free on the ACCEPT path.
  //
  // ⚠ AND "THE PREP IS EMITTED FIRST" IS **NOT** FREE — THIS SENTENCE USED TO
  // CLAIM IT WAS, AND THAT WAS FALSE (round-1 finding F-M1, measured on plain C
  // by `r03_order_third_region.c`). `lowerControlRegions` does NOT emit in plan
  // order: it Kahn-sorts the bd `hcrg` precedence graph, and a `SelectRegion` has
  // all-null block fields, so it is INERT there — it aliases nothing, nothing
  // aliases it, `Pending == 0`. A following `PhaseKickback` whose `Pred` IS the
  // prep's `MergeBB` takes the sanctioned `sequentialChainAlias` edge
  // `Precedes[kickback] = {prep}`, which schedules the prep LAST — AFTER this
  // select. The order is now an explicit OBLIGATION, carried by
  // `ControlRegion::PrepRegionIdx` (recorded by rung 0) and discharged by ONE
  // edge in that graph. Read the two together; neither is decoration.
  //
  // THE FIX IS NOT A SMART POINTER. Making `Condition` a `WeakTrackingVH` would
  // silently FOLLOW M-β's RAUW and thereby HIDE the ordering premise instead of
  // checking it. The select owns its own condition, so re-reading it is both
  // correct by construction (M-β rewrote that very operand) and Rule-14-clean —
  // one owner, asked rather than cached. `R.Condition` is never dereferenced
  // again in this function.
  //
  // AND THE BACKSTOP IS THE GRAMMAR'S DEFAULT, NOT A NEW CHECK. `collectCondTree`
  // is called here WITHOUT `AllowRailPhi`, so if the re-read condition is still a
  // φ — i.e. M-β did not run, the ordering premise failed, or a future emitter
  // pushed a `SelectRegion` on a φ without a prep region behind it — the walk
  // returns false and the existing LOUD `control flow` decline below fires before
  // anything is emitted (detect-before-mutate, Rule 1). A rail-leaf re-read is
  // admitted by the pre-existing `RailLeaves` path; a compare tree is unchanged.
  //
  // ⚠ HOW THE RAW POINTER WAS SHOWN TO BE GONE — MEASURED BY COUNTERFACTUAL, not
  // argued (Release has no ASan, so there is no sanitizer to ask). With this one
  // line reverted to `R.Condition` and nothing else changed, the owner's own
  // program and both its polarity twins go from ACCEPT to
  // `control flow under quantum control`, exit 1, deterministically over three
  // runs — i.e. `collectCondTree` walked the ERASED φ's memory and the walk
  // failed. ⚠ DO NOT READ THAT AS "the old code was safe": the observable is
  // whatever the freed object's bytes happen to decode to under this allocator on
  // this run. The fix turns an undefined read into a defined one; the loud decline
  // it happened to produce is not a property anything may rely on. THE DIRECTION
  // matters too — it silently LOSES a proven accept rather than emitting a wrong
  // stream, which is exactly why no golden and no `opt -verify` could ever have
  // caught it.
  //
  // The positive witness is `control_swap_accept_select_mergephi_rail*.ll` and
  // `tests/e2e/slice_control_cascade_two_bools.c`: they emit the T1 stream, which
  // is only reachable if the re-read value is the hoisted `cq_theta_i1` CALL
  // (`CondTreeEmit`'s `CopyRailRoot` keys on `isCondRailLeaf`, and a `PHINode` is
  // not a `CallInst`).
  //
  // ⚠ THE φ-STILL-PRESENT BRANCH IS THE "A SEVENTH EMITTER FORGOT THE EDGE"
  // TRIPWIRE. DO NOT DELETE IT. This comment used to say the branch had "NO
  // SUBJECT today", and round-1 finding F-M1 proved otherwise: `r03` reached it
  // through the `hcrg` Kahn reorder and took this decline on ordinary `-O1` C.
  // That hole is closed by `ControlRegion::PrepRegionIdx` + its precedence edge,
  // so the branch is unreachable AGAIN — but it is unreachable because ANOTHER
  // FILE keeps an obligation, which is precisely the configuration CLAUDE.md L3
  // warns about: the day a new `SelectRegion` producer forgets to set
  // `PrepRegionIdx` (or a new region kind rewrites a select's condition), this is
  // the only thing between that and a walk over freed φ memory. Its correctness
  // does not depend on being reachable. The counterfactual is recorded in
  // `FIX_M_R1.md` the way H-1's was: revert the edge and `r03` declines here
  // again, deterministically.
  CondTree Tree;
  Value *Cond = Sel ? Sel->getCondition() : nullptr;
  // bd `test_C_libtooling-xdu2.13` — the classifier's committed LITERALS, asked
  // by membership (the walk cannot drift); each must still be untainted HERE,
  // since a region emitted before this one may have grown the taint set.
  auto IsLit = [&](Value *V) {
    return !taint.Tainted.count(V) &&
           llvm::any_of(R.CondLiterals,
                        [V](const WeakTrackingVH &H) { return H == V; });
  };
  if (!Sel || !Cond ||
      !collectCondTree(Cond, Tree, /*AllowLogicalSelect=*/false,
                       /*AllowRailPhi=*/false,
                       R.CondLiterals.empty()
                           ? function_ref<bool(Value *)>()
                           : function_ref<bool(Value *)>(IsLit),
                       /*AllowRegRoot=*/R.RailLadderProven) ||
      Tree.LiteralLeaves.size() != R.CondLiterals.size()) {
    // Detection guarantees the shape (SelectClassify pushes only a SelectInst
    // Merge + a tree-shaped Condition); if it ever fails to hold, bail LOUDLY —
    // a silently skipped accepted region leaves the tainted select to the
    // backend as classical control over quantum state (the unforgivable
    // outcome, Rule 1).
    if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    return;
  }
  // bd test_C_libtooling-r9e5 (1b-B.1) — A RAIL LEAF NOW LOWERS HERE, and the
  // guard this replaces was its `kBareRailCondReason` decline. The stream below
  // is UNCHANGED, instruction for instruction: what changes is where the FLAG
  // comes from. A NON-ROOT rail (a rail inside an `and`/`or`/`xor` tree) needs
  // nothing at all — the root is a node ancilla and the rails are read-only
  // controls of its cnots/toffoli — while a BARE RAIL ROOT is the user's
  // REGISTER, which step 4 would `cqrt_x`-bracket. So the network is asked for a
  // bracket-able ancilla instead (`CopyRailRoot`, below), and the guard is
  // INVERTED: if a rail root ever reaches step 3 still being the register, bail
  // LOUDLY (Rule 1 — never silently), because the only alternative is a
  // non-diagonal gate on a user register (bd memory
  // [diagonal-only-on-user-registers-3qlq4]). See after the mint.
  //
  // Rule-13 round-1 item F-B1R1-2 — THE CALLER-INDEPENDENT BACKSTOP, RESTORED.
  // The guard this file used to carry refused a rail tree for ALL THREE callers
  // of this emitter; its `RootIsRail` re-ask below is dead code (with
  // `CopyRailRoot` the network never hands a rail root back). What is
  // load-bearing is that ONLY `classifySelectRegion` asks the §14.3 rail ladder,
  // while `SwapRouteEmit::emitValueRegion` builds its own `SelectRegion` and
  // calls here directly — safe today only because `classifyArms` is
  // `CmpInst`-only, and bd `fg9k` is the increment that widens it. So the plan
  // must SAY the ladder was asked (`ControlRegion::RailLadderProven`, set at the
  // classifier's accept), and a rail-carrying tree without it is refused with
  // the original string, before anything is emitted (detect-before-mutate).
  if ((!Tree.RailLeaves.empty() || !Tree.RegLeaves.empty()) &&
      !R.RailLadderProven) {
    diagnoseUnderControl(Sel, kBareRailCondReason);
    return;
  }

  Value *Tru = Sel->getTrueValue();
  Value *Fls = Sel->getFalseValue();

  // Result-width (Wd) source (§4, the resolved gotcha): read at emit time, which
  // runs BEFORE `lowerRotations` launders handles to i32 — so the select still
  // carries its real logical type. NEVER a post-RAUW i32 read. Detection's gate 4
  // already proved a scalar ABI width with a reversible/controlled copy (integer
  // {i1..i64} or, since the §16.4 un-staging, scalar fp {f16..f80} —
  // fp-data-select-PRD §4.4), so a null here is a malformed plan — decline
  // LOUDLY, lower nothing (Rule 1). The copy minter is selected by result type:
  // integer → the shared `copyControlledFn` (whose integer-only null is the 6.5
  // classical-call arm's live classifier and must not be relaxed — DD-7), scalar
  // fp → the select-local `copyControlledFpFn` (§4.2). The fp rail alloc
  // `Constant::getNullValue(RailTy)` yields `double 0.0`/`half 0xH0000`/…,
  // matching the fp `cqrt_alloc_f<W>` signatures.
  StringRef Abi = abiWidthFromType(Sel->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy = Abi.empty() ? FunctionCallee()
                        : Sel->getType()->isFloatingPointTy()
                            ? csyms.copyControlledFpFn(Abi)
                            : csyms.copyControlledFn(Abi);
  if (!RailTy || !Alloc || !Copy) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  const DebugLoc DL = Sel->getDebugLoc();
  IRBuilder<> B(Sel);  // every stream call lands immediately before the select.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. MINT the condition NETWORK (3c6m.12; compound-cond-select-PRD §3) —
  //    left-to-right post-order over the tree, the SAME traversal
  //    `collectCondTree` used: each leaf mints its flag via
  //    `lowerCompareToFlag` (`cq_template_(i|f)cmp_<pred>_<Wc>_hl(q, k)`; Wc
  //    resolved internally) at FIRST visit — a shared leaf mints ONCE — and
  //    each `and`/`or`/`xor` node computes onto a fresh `|0⟩` i1 ancilla:
  //      AND: toffoli(l, r, g)                        g = l∧r
  //      OR : cnot(l, g); cnot(r, g); toffoli(l,r,g)  g = l⊕r⊕lr = l∨r
  //      XOR: cnot(l, g); cnot(r, g)                  g = l⊕r   (bd 3c6m.67)
  //    Controls are READ-ONLY (no transient X on shared rails — safe under
  //    sharing by construction). Ancillas/flags are NOT added to
  //    `taint.Tainted`: their only users are `cqrt_*` calls, so `uncompute`
  //    never selects them (the same treatment as the pre-L4 single flag). A
  //    bare-compare tree mints exactly the pre-L4 single flag — no ancilla,
  //    byte-identical stream.
  //
  // bd test_C_libtooling-3qlq Inc 1 part B — THE NETWORK ITSELF NOW LIVES IN
  // `CondTreeEmit` (one forward emitter, one exact-LIFO strip), because the
  // register-free BRANCH PHASE (PRD §6.2 row P3) needs the identical network on
  // a `br` condition and copying it a third time is the duplicated-lowering
  // prohibition (Rule 14). THIS CALL IS THE PRE-LIFT CODE, MOVED:
  // `AllowQQLeaves = true` keeps the bd adia Q+Q leaf policy and every `Neg*`
  // stays false (a data select has no polarity — it always means "the true value
  // when the flag is 1"), so the traversal, the emitted symbols, the operand
  // order, the `!dbg` stamping and the ancilla NAME (`g`) are unchanged. The 4.4
  // fixtures and goldens are the witness that the lift is a refactor.
  //
  // bd test_C_libtooling-r9e5 (1b-B.1) — `CopyRailRoot = true`, THE ONLY CHANGE
  // AT THIS CALL. It is inert unless the root is a bare rail leaf, in which case
  // the network mints `f = cqrt_alloc_i1(0); cqrt_cnot(h_rail, f)` and hands `f`
  // back as `Net.Root` (the strip un-copies and frees it, LIFO-first). Analytic
  // argument, NOT `opt -verify` (Rule 2): after the copy the pair is
  // `Σ α_x |x⟩_b |x⟩_f`; `copy_c(f, T, out)` writes T iff x=1, the X-bracketed
  // `copy_c(f, F, out)` writes F iff x=0, and `b` is untouched throughout (the
  // copies write `out`; the brackets act on `f`), so `out = b ? T : F` with one
  // write per basis branch and the second cnot returns `f` to |0> on every
  // branch. That is the SAME unitary the compare stream realizes with
  // `c(x) = b`, which is why every §5a invariant below — the bracket SCOPE, the
  // `cqrt_x` COUNT, the single free — carries over unchanged.
  CondNetwork Net;
  // (Track A.1, F-A1R2-1) `LeafWireRuled` — `classifySelectRegion` ran gate 2c
  // (`findNonDiagonalWireGate` over the leaves' `condProvenance` union) before
  // this region was ever pushed, so a round-1 wire disposition WAS taken for
  // every compare leaf here. `emitValueRegion` (3qlq Inc 2) reaches this same
  // emitter with a synthesized `SelectRegion`, and its region came through
  // `classifyArms` → `condWireDisposition`: ruled either way.
  // `Cond`, not `R.Condition` — see H-1 at the top of this function.
  switch (emitCondNetwork(Cond, Tree, wd, csyms, taint, /*Before=*/Sel,
                          DL, /*AllowQQLeaves=*/true, Net,
                          /*CopyRailRoot=*/true, /*LeafWireRuled=*/true)) {
  case CondNetDisp::Ok:
    break;
  case CondNetDisp::MintDiagnosed:
    // A leaf mint failed and `lowerCompareToFlag` was ALREADY loud — return
    // SILENTLY, exactly as the pre-lift `if (!F) return;` did. Adding a second
    // `control flow under quantum control` here would change what every existing
    // select decline fixture reads on stderr.
    return;
  case CondNetDisp::Malformed:
    // No i1 ancilla allocator, or a node the grammar admitted that the emitter
    // cannot decompose. The pre-lift code declined loudly for the first of those
    // in exactly this place; the second is detection/emission drift and gets the
    // same treatment (Rule 1 — never silently skip an accepted region).
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  // bd test_C_libtooling-r9e5 (1b-B.1) — THE INVERTED DRIFT GUARD. `Net.Root` is
  // about to be `cqrt_x`-bracketed in step 4, so it MUST be an ancilla this
  // emitter owns. `RootIsRail` still true here means the `CopyRailRoot` request
  // did not fire (emission drift): bail LOUDLY rather than bracket the user's
  // register. Nothing of this emitter's has been emitted yet — for a bare rail
  // root the copy IS the network's only emission and it did not happen — so this
  // is still a detect-before-mutate bail (the ziov.4 discipline).
  if (Net.RootIsRail) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }
  Value *Flag = Net.Root;  // the ROOT rail gates the copies.

  // 2. ALLOC the |0> result rail (Wd). It joins `taint.Tainted` (+BirthOrder) so
  //    downstream consumers of the RAUW'd select keep classifying it as a quantum
  //    handle; its only users are cqrt_*/template calls, so `uncompute` never
  //    selects it as a terminal (isTerminalHandle is false — §16.5) and it is
  //    never freed (the live result, owned by the user's measure / ret).
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);  // DD-4: Phase-4 owns this merge out-rail
  taint.BirthOrder[Out] = taint.NextBirth++;
  // bd p119.6: record the out-rail's LOGICAL ABI width (= the select's data width,
  // `Abi`), the same invariant every other producer upholds (theta/arith/cast).
  // Without it, a DOWNSTREAM cast/Q+Q-compare off the RAUW'd merge reads the
  // laundered i32 (getSrcTy after RAUW) instead of the real width and declines —
  // the `n = (int)select(cond,a,b)` branchless range-reduction shape declining
  // `no template for opcode 'fptosi i32'`. `Abi` is non-empty here (the `!RailTy`
  // guard above returned otherwise) and is exactly `abiWidthFromType(Sel->getType())`.
  taint.HandleWidth[Out] = Abi;

  // 3. COPY the TRUE value on the flag (materialize if classical) — fires on f=1.
  Value *TrueSrc = materializeCopySource(Tru, Alloc, taint, B, DL);
  stamp(B.CreateCall(Copy, {Flag, TrueSrc, Out}));

  // 4. COPY the FALSE value on ¬flag, X-bracketed (the 4.1 self-inverse cqrt_x
  //    convention). The bracket encloses ONLY this second copy: a mis-bracket
  //    (x before BOTH copies) yields the identical symbol multiset yet writes a
  //    then b on one basis branch = wrong %out (§16.3, the load-bearing hazard).
  stamp(B.CreateCall(csyms.xFn(), {Flag}));
  Value *FalseSrc = materializeCopySource(Fls, Alloc, taint, B, DL);
  stamp(B.CreateCall(Copy, {Flag, FalseSrc, Out}));
  stamp(B.CreateCall(csyms.xFn(), {Flag}));

  // 5. STRIP — exact LIFO (compound-cond-select-PRD §3). Reverse node order:
  //    the self-inverse network (AND: the same toffoli; OR: the toffoli, then
  //    the cnots in reverse) returns each ancilla to |0> while its children's
  //    rails are STILL ALLOCATED (reverse post-order — a parent uncomputes
  //    before its children), then frees it. Then reverse leaf-MINT order: the
  //    `_inv` compare strip (reads the leaf's ORIGINAL operands — MUST precede
  //    any erase of the tree, step 6) then the flag free. Structurally valid
  //    outright: the merge never wrote any leaf's condition lineage (the
  //    copies write `%out`, never q), so every rail un-computes to |0> exactly
  //    and every free is a proven-|0> free (Rule 6). The single-leaf tree
  //    degenerates to the pre-L4 `_inv` + free pair, byte-identical.
  // bd urlv audit — NO KEPT-CARRIER RECORD REACHES THE NODE RAILS OR LEAF FLAGS
  // FREED BELOW. Each is minted BY THIS EMITTER at |0> and returned to |0> by its
  // own toffoli/cnot undo or `_inv` strip on the line above its free. They are
  // never an operand of a gate writing a carrier the reversal does not touch: the
  // controlled copies write the fresh `%out` and never a leaf's condition lineage,
  // and this module mints NO `cqrt_tape_write_*` (only `IOSinkLowering` and
  // `AbortParkEmit` do). The bd 261j(a) freeze is not owed here and is deliberately
  // not duplicated (bd memory [record-freeze-invariant-2026-08-10]).
  //
  // bd test_C_libtooling-3qlq Inc 1 part B — the strip is `CondTreeEmit`'s
  // `stripCondNetwork`, the exact-LIFO mirror of the mint above, lifted with it
  // so the forward and its adjoint cannot drift apart in two files. Same
  // `AllowQQLeaves = true`, same insert point, same stream.
  stripCondNetwork(Net, wd, csyms, taint, /*Before=*/Sel, DL,
                   /*AllowQQLeaves=*/true);

  // 6. REWIRE — RAUW %sel -> %out, scrub, erase. NO flatten (there is no CFG).
  //    The user's measure/ret on the select becomes one on %out (no measurement
  //    is added — Rule 5).
  Sel->replaceAllUsesWith(Out);
  scrubTaint(Sel, taint);
  Sel->eraseFromParent();

  // The condition tree is now (in the canonical single-use case) dead: the
  // mint/strip built FRESH templates from the leaves' operands
  // (lowerCompareToFlag does not consume them), so the root has lost its only
  // user. Cascade-erase ROOT-FIRST (reverse post-order nodes, then leaves) so
  // each child's use count drops before it is tested; scrub + erase so
  // `lowerOps` (L111) does not lower a spurious dead compare/or into the
  // trace. A SHARED node or leaf (also read as data — clang -O1 CSEs
  // `int f=(q>5)` with the select condition — or feeding a second select)
  // keeps its other users; leave it for `lowerOps`/the sibling region (the
  // shared-compare discipline verbatim).
  for (Instruction *N : llvm::reverse(Tree.Nodes))
    if (N->use_empty()) {
      scrubTaint(N, taint);
      N->eraseFromParent();
    }
  for (CmpInst *Leaf : llvm::reverse(Tree.Leaves))
    if (Leaf->use_empty()) {
      scrubTaint(Leaf, taint);
      Leaf->eraseFromParent();
    }
}

}  // namespace cq
