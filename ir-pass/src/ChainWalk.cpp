// ChainWalk.cpp — see header. Terminal-handle detection + the shared per-gate
// predicates. The whole-DAG recovery itself lives in `DagTraversal` (WI-4); this
// module is the vocabulary both it and the uncompute driver consult.

#include "ChainWalk.h"
#include "CloneProducer.h"    // isCloneProducer (bd p3kd.13)
#include "RailBankPromote.h"  // railStoredToRailBank (bd `xdu2` W1 D1)
// `cloneCallPreservesArg` (bd rhk5) lives in ClonePreserves.cpp since bd p3kd.13.
#include "TaintPropagation.h"
#include "TemplateName.h"   // isHandleSlot / isUncHandleSlot — the ONE slot table

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"   // is_contained
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Metadata.h"

#include <utility>

using namespace llvm;

namespace cq {

// The BRANCH-PHASE (KICKBACK) GATE RECORD — see the header for the whole
// argument (bd 3qlq Inc 1 part A, Rule-13 round-1 finding F-L7-1). ONE spelling
// of the tag string, used by the writer and the reader, so the two cannot drift.
static constexpr const char *kBranchPhaseTag = "cq.branchphase";

void markBranchPhaseGate(CallInst *G) {
  if (!G)
    return;
  G->setMetadata(kBranchPhaseTag, MDNode::get(G->getContext(), {}));
}

bool isBranchPhaseGate(const CallInst *G) {
  return G && G->getMetadata(kBranchPhaseTag) != nullptr;
}

bool isAbiQramStore(const CallInst *G) {
  const Function *Callee = G ? G->getCalledFunction() : nullptr;
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  if (!N.starts_with("cqrt_qram_store_"))
    return false;
  // The `_unc` adjoint twins (`..._unc`, `..._controlled_unc`) are never a FORWARD
  // store — they are what the spine EMITS, not what it recognizes.
  if (N.ends_with("_unc"))
    return false;
  // VOID IS THE LOAD-BEARING TEST, NOT THE ARITY (bd 1fim Rule-13 round, 2026-08-11).
  // "A store MINTS NO RAIL" is the semantic property this whole predicate stands on:
  // it is the ONLY reason `emitInverseCall` may adjoint a store with a SAME-ARGS
  // `_unc` instead of the out-first form every rail-minting producer gets. Arity is
  // merely a proxy for it, and an INCOMPLETE one — the first draft of this fix checked
  // arity alone, and three reviewers independently reproduced the ORIGINAL defect at
  // the FROZEN arity by flipping only the return type:
  //     %s = call i32 @cqrt_qram_store_i32(i32 %h, i32 3, i32 4)  ; arity 3, NON-void
  //     call void @cqrt_qram_store_i32_unc(i32 %h, i32 3, i32 4)  ; cannot name %s
  //     call void @cqrt_free(i32 %h)                              ; freed anyway
  // `opt` rc=0, verify-clean, and `free_pairing_check.py` reports "2 verified, 0
  // violation(s)". Test the property itself; do not proxy it again.
  if (!G->getType()->isVoidTy())
    return false;
  // EVERY OPERAND IS AN `i32` HANDLE, at every width — Rule 15 ("a runtime handle is
  // always `i32` regardless of width"), and the header is uniform on it:
  // `void cqrt_qram_store_<W>(int32_t arr, int32_t idx, int32_t val)` for all nine
  // widths (runtime/cq_runtime.h:541-549), plus a leading `int32_t pred` on the
  // guarded twin. THE THIRD AXIS, added after a Rule-13 verifier built
  // `declare void @cqrt_qram_store_i32(i32, i32, double)` — VOID and arity 3, so the
  // void+arity draft ACCEPTED it — and the pass then minted an `_unc` whose signature
  // does not match the frozen body. That is not caught at link: C symbols carry no
  // signature, so the name resolves to the real 3×i32 body and the call runs with a
  // reinterpreted operand. With this test the predicate matches the frozen PROTOTYPE,
  // not a proxy for it.
  for (const Use &A : G->args())
    if (!A.get()->getType()->isIntegerTy(32))
      return false;
  // The two frozen forward shapes, and their EXACT arities:
  //   plain      `cqrt_qram_store_<W>(arr, idx, val)`              — 3
  //   guarded    `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` — 4
  if (N.ends_with("_controlled"))
    return G->arg_size() == 4;
  // A name that CONTAINS `_controlled` without ending in it is an off-pattern
  // spelling of neither frozen form — decline rather than fall through to the
  // plain-arity test (the Prime Directive; over-declining is the safe direction).
  if (N.contains("_controlled"))
    return false;
  return G->arg_size() == 3;
}

bool isInPlaceGateOn(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  // ---- THE BRANCH-PHASE (KICKBACK) GATE IS OPAQUE, ASKED FIRST (bd 3qlq Inc 1
  // part A, Rule-13 round-1 F-L7-1 / F-L1-1 — a CONFIRMED silent miscompile).
  //
  // `cqrt_rz_i1(f, θ)` emitted by a kickback region is not a step in `f`'s
  // reversible chain, it is THE PROGRAM'S ANSWER phase-kicked onto the control
  // ancilla. Admitting it here made it a member of `D.Calls`, so `emitDagReversal`
  // emitted `cqrt_rz_i1(f, -θ)` and CANCELLED it EXACTLY (both gates diagonal in
  // the same label, the copy between them moves no label): the emitted circuit was
  // the circuit for the same program with the `cq_phi` deleted. Refusing it here
  // is the SAME move Inc 2a made one stem over for `cqrt_rz_<W>_controlled` —
  // `isTerminalHandle` false, `isInteriorConsumer` false, `DagTraversal` closure
  // `NotClosed` — so the flag rail is LEFT ALLOCATED (Rule-6 safe, and
  // byte-for-byte the pre-3qlq oracle's disposition on the same source).
  //
  // ASKED BEFORE THE NAME ROWS AND BEFORE `H` IS EVEN LOOKED AT, deliberately:
  // the gate is opaque for EVERY candidate handle, not only for the flag, so no
  // later row can re-admit it through a different slot.
  //
  // WHY THIS FIXES BOTH POLARITIES BY DESIGN (F-L1-1's measurement). Before it,
  // the NEGATED arm survived only because its `cqrt_x(f)` bracket made `f` carry
  // an unrecognized consumer, and the un-negated arm did not — i.e. whether the
  // user's phase survived depended on the branch polarity `clang -O1` happened to
  // canonicalize to. That is an accident, not a fence. Membership is neither.
  if (isBranchPhaseGate(G))
    return false;
  StringRef N = Callee->getName();
  // iw81.7 / Phase 7.5 Inc 2: a QRAM store is a VOID in-place mutation on its ARRAY
  // handle — arg 1 for the GUARDED form `cqrt_qram_store_<W>_controlled(flag, arr,
  // idx, val)` (arg 0 is the path-predicate flag), arg 0 for the plain
  // `cqrt_qram_store_<W>(arr, idx, val)`. Recognized BEFORE the generic
  // `_controlled` bail below (a controlled gate is normally NOT an in-place gate,
  // but this store IS on its array). The borrowed tainted operands (flag / idx /
  // val) are enqueued as DAG parents by `DagTraversal`; the flag-mint compare
  // reverses AFTER this gate's `_unc` (the strip).
  //
  // The ABI-shape test is `isAbiQramStore` — the ONE definition, shared with
  // `EmitInverse::isInverseEmittable` (bd test_C_libtooling-1fim). That predicate
  // used to re-spell the match as a bare PREFIX test with no arity check, so an
  // off-ABI-arity store was invertible over there and not an in-place gate over
  // here: two predicates, one gate, different answers — the same defect shape as
  // the `railOf` mis-attribution below (bd uow0). Driving both from one definition
  // makes them agree BY CONSTRUCTION rather than by two spellings being kept in
  // sync (Rule 14).
  if (isAbiQramStore(G))
    return N.ends_with("_controlled") ? G->getArgOperand(1) == H
                                      : G->getArgOperand(0) == H;
  // CONTROL-IN-PLACE ROTATION `cqrt_ry_<W>_controlled(f, H, θ)` — bd
  // test_C_libtooling-drbq. VOID, arity EXACTLY 3, the ROTATED HANDLE at arg 1
  // (arg 0 is the control flag, arg 2 the classical angle). Recognized BEFORE
  // the generic `_controlled` bail below for the same reason the guarded QRAM
  // store above is: a controlled gate is normally not an in-place gate, but
  // THIS one is — it relabels `H` in place on the `f=1` branch and mints
  // nothing.
  //
  // WHO ACTUALLY NEEDS THIS ROW — corrected by the round-1 Rule-13 review (lens
  // L5 §5) after the first draft named a consumer that cannot reach it, and
  // then re-MEASURED by deleting the row and re-running the family:
  //
  //   * `railCarriesControlledRotation` (this file) — THE SHARP END. The whole
  //     freeze is derived from this row: it asks `isInPlaceGateOn` and then
  //     restricts to the `_controlled` rotation spelling, so the two predicates
  //     cannot disagree about which slot is the rail (the bd uow0
  //     mis-attribution, one family over — `railOf` is derived here too, and
  //     without this row would attribute the gate to the FLAG at arg 0).
  //   * `Uncomputation`'s moved-anchor scan and `ChainWalk::isInteriorConsumer`
  //     — both key on this predicate to decide whether an in-place
  //     basis-relabelling gate sits between a forward gate and its adjoint.
  //   * `RotationLowering::warnLiveRecordRotations` — the ONE consumer with a
  //     DISTINGUISHING fixture (`control_inplace_ry_warn_live_record.ll`; the
  //     measurement below is what proves it is the only one).
  //
  // MEASURED, so the claim is not an argument: deleting this row and re-running
  // the `control_inplace` family (53 fixtures when this was measured at the end
  // of round 1; 55 today) reddens EXACTLY ONE —
  // `..._warn_live_record.ll`. The freeze fixtures stay green because a gate
  // this predicate cannot see becomes an UNRECOGNIZED consumer, which marks the
  // DAG `NotClosed` and leaks the whole thing: a SECOND route to the same
  // Rule-6-safe outcome. Say that rather than "the DagTraversal one is the sharp
  // end", which the first draft said and which is false — with the freeze
  // working, `DagTraversal`'s freeze cut fires BEFORE its users loop, so the
  // `D.Calls` path the sentence described is unreachable.
  //
  // The VOID + EXACT-ARITY-3 pair is the bd 1fim fence, verbatim: a non-void or
  // off-arity same-named fake mints a value this recipe cannot account for and
  // must stay an unrecognized consumer (`NotClosed` ⇒ Rule-6 safe leak).
  // `ends_with("_controlled")`, never `contains`, keeps the `_controlled_inv`
  // reserve (a different family, different adjoint) out.
  //
  // ⚠ WHO ELSE DEPENDS ON THIS ROW STAYING NARROW — six emitters, none of which
  // consumes this predicate directly (bd drbq round-2 review, lens A §7). Each
  // relies IN WRITING on `isTerminalHandle` being FALSE for a rail *because it
  // has a `_controlled` consumer*, so that the whole-DAG spine never claims a
  // rail the emitter owns: `SelectMergeEmit.cpp:224`, `SwitchValueEmit.cpp:196`,
  // `SwitchDataMuxEmit.cpp:31`/`:140`, `SwapRouteEmit.cpp:342` (pre-3qlq route),
  // `ClassicalCallArmEmit.cpp:205`, `LoopLowering.cpp:1442`. They survive THIS
  // widening only because their consumers are `cqrt_copy_<W>_controlled` /
  // `cqrt_cswap`, which the generic `if (N.contains("_controlled")) return
  // false;` bail below still catches. NOTHING PINS THAT. The next `_controlled`
  // stem admitted here flips all six from "not a terminal" to "a terminal" with
  // no diagnostic anywhere — so a new row is a Rule-13 change to six emitters,
  // not a local one, and it must also be classified explicitly in
  // `railCarriesControlledRotation` (whose stem restriction is a WHITELIST: a
  // new shape falls outside it silently).
  //
  // ⚠ THE `ry` STEM ONLY — THE STEMS WERE SPLIT BY bd drbq **Inc 2a**, AND THE
  // SPLIT IS THE POINT OF THAT INCREMENT, NOT AN OPTIMIZATION. Inc 1 admitted
  // BOTH `cqrt_ry_<W>_controlled` and `cqrt_rz_<W>_controlled` here, at a time
  // when `emitRz`'s controlled arm had no caller so the `rz` half was inert. Inc
  // 2a gave it one (every FLAT phase region then emitted it in place of the
  // five-line route; since 3qlq nothing mints it), and admitting it HERE would
  // have been a silent miscompile of exactly the finding-A shape, one stem over:
  //
  //   * as a DAG LINK the gate joins `D.Calls`, so `emitDagReversal` emits its
  //     adjoint — `cqrt_rz_<W>_controlled(f, h, -θ)` naming a flag the region
  //     already `cqrt_free`d (a use-after-free), and then frees a register the
  //     spine believes it zeroed;
  //   * and because `preservesBasisUnderRecord` calls the `rz` spelling
  //     basis-preserving, the M-B INTERIOR partition would have claimed a
  //     template rail carrying one (pre-3qlq register form: `r = p*5; if (q==5)
  //     r = cq_phi(r,θ); s = r*3;`) and discharged it, which the route NEVER did.
  //
  // The route was the oracle for what this gate must look like to the spine, and
  // under the route the register's only users were `cqrt_cswap`s — which this
  // predicate refuses, making them UNRECOGNIZED consumers. Refusing the
  // controlled `rz` reproduces that exactly: `isTerminalHandle` is false,
  // `isInteriorConsumer` is false, `DagTraversal`'s closure scan sets
  // `NotClosed`, and `railCarriesControlledRotation` (derived from this
  // predicate) answers "not frozen" — the four verdicts the route produced. It
  // is a DIAGONAL gate, so nothing is lost by treating it as opaque: it moves no
  // basis, and the register's own chain is reversed and freed exactly as it was
  // after a routed region (PRD §12.1; bd `drbq-freeze-vs-261j-reconciled`).
  //
  // WHAT ELSE WAS COMPUTED OVER THIS CLOSURE, asked because this is a set
  // NARROWING and the 8h7d.5 F-1/F-3 lesson cuts both ways: (i)
  // `railCarriesControlledRotation` — derived, moves WITH this, deliberately;
  // (ii) `preservesBasisUnderRecord`'s `cqrt_rz_` row — its `_controlled` arm is
  // now UNREACHABLE (membership in `D.Calls` goes through this predicate) and is
  // kept as the fail-safe answer with that fact recorded at its site;
  //
  // (iii) the six `isTerminalHandle` dependants named below — the VERDICT IS THE
  // ROUTE'S, and the verdict MOVES to get there. Do not read this row as "both
  // readings agree": an in-place gate is a BENIGN user (`continue` — `H` may
  // still be the terminal), an unrecognized consumer FORCES `false`, so the
  // narrowing takes the `rz` spelling from possibly-terminal to never-terminal.
  // That is the RIGHT move because the oracle was the ROUTE, where the register's
  // users were `cqrt_cswap`s — unrecognized — so `H` was never a terminal there
  // either; and it is the SAFE direction (a non-terminal is not freed: a leak,
  // Rule 6, never a dirty free). MEASURED: no `cqrt_free` appears or disappears
  // anywhere in the corpus beyond the collapsed quintuple. (The `.h` note (1) on
  // `railCarriesControlledRotation` states this correctly; an earlier spelling of
  // this row claimed both readings gave `false` and was wrong — round-1 review
  // L1 F-2.)
  //
  // (iv) `Uncomputation::preservesBorrowedParent` — IT DID **NOT** STAY AS IT
  // WAS. It gained **clause (1b)** in THIS increment and now treats
  // `cqrt_rz_<W>_controlled(f, P, θ)` as READ-ONLY on `P` at arg 1. That was
  // REQUIRED, not opportunistic: MEASURED, without it nine modules lost their
  // whole M-B interior discharge (`lowering_mc_late_sub_after.ll` &c). The reason
  // is that the route's exemption was a GROUP property — the `cqrt_cswap` pair
  // was individually a mutation and was exempted one level up by
  // `routeGroupFullyInside` (clause (d2), `TaintSet::RestoringRoutes`) — and
  // control-in-place emits no group, so the licence moved to the GATE, where
  // diagonality makes it STRONGER (`P`'s basis label is not restored after being
  // moved; it is never moved). The `ry` twin is still refused there and must
  // stay refused — it relabels `P` on `f=1`. See `Uncomputation.cpp` clause (1b)
  // and the Inc-2a notes §4(a). (An earlier spelling of this row said the
  // exclusion "must KEEP excluding" the `_controlled` spelling — following it
  // would delete clause (1b) and reintroduce that measured nine-module
  // regression, whose only outward sign is a new M-A warning on an rc-0 module;
  // round-1 review L1 F-0.)
  if (N.starts_with("cqrt_ry_") && N.ends_with("_controlled") &&
      G->getType()->isVoidTy() && G->arg_size() == 3 &&
      G->getArgOperand(1) == H)
    return true;
  // ⚠ THIS BAIL IS WHAT KEEPS THE SPINE OFF AN l4x4.b CONTROL REGISTER — the
  // clause above matched only `getArgOperand(1)`, the ROTATED rail, so a
  // bare-`_Bool` register appearing as arg-0 (the CONTROL) falls to here and
  // becomes an unrecognized consumer: `isTerminalHandle` false, the DAG
  // `NotClosed`, the register LEFT ALLOCATED (Rule 6's required direction,
  // `Ry(θ)|0⟩ ≠ |0⟩`). ⚠ BUT DO NOT READ IT AS THE ONLY REASON: a rail leaf is a
  // `cq_theta_i1` result, so its register always carries an UNCONTROLLED
  // `cqrt_ry_i1`, which `preservesBasisUnderRecord` refuses INDEPENDENTLY of
  // every row in this list — the second, stronger exclusion, written out at that
  // function's header (l4x4.b round-1 Rule-13 review, item H-9).
  if (N.contains("_controlled"))
    return false;
  // Uncontrolled rotation `cqrt_ry/rz_<W>(H, θ)` — arg_size 2, arg 0 is the
  // handle. Mints no new value (void), so it belongs to `H`'s DAG link.
  if ((N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
      G->arg_size() == 2 && G->getArgOperand(0) == H)
    return true;
  // Issue dtzb / bd test_C_libtooling-6uqc (M-C): the IN-PLACE VALUE gates
  // `cqrt_addc_<W>(H, imm)` / `cqrt_xorc_<W>(H, imm)` — VOID, arg_size 2, arg 0
  // is the handle, arg 1 the CLASSICAL immediate (Rule 15: the handle is i32 at
  // every width; the immediate carries the logical width). Like a rotation they
  // MUTATE the one rail and mint nothing, so they belong to `H`'s DAG link.
  //
  // WHY THIS ENTRY EXISTS ONLY NOW, and why it is REQUIRED rather than tidy.
  // Before M-C these gates were minted ONLY by the 7.3/7.4 loop path, where the
  // rail is loop-carried and the whole-DAG spine leaks it anyway — so the
  // omission was inert. M-C emits them on STRAIGHT-LINE rails the spine must
  // reverse and free, and every consumer of this predicate then needs them:
  //   * `isTerminalHandle` — an addc user is benign (it mints no handle), so the
  //     rail stays its own chain's terminal. Without this the chain has NO
  //     terminal at all and is never recovered.
  //   * `DagTraversal` step 1 — the addc joins `D.Calls`, so `emitDagReversal`
  //     emits its adjoint (`cqrt_addc_<W>(H, -imm)`; `EmitInverse` already knows
  //     the recipe) and the rail returns to its BIRTH state — |0> for a template
  //     rail or a null-seeded root, which is then freed; a seeded root returns to
  //     |seed> and is kept (bd 5c5b, `BirthFreeze`).
  //   * `DagTraversal` step 3 closure — an addc user no longer reads as an
  //     unowned consumer that marks the whole DAG `NotClosed`.
  //   * `railOf` — DERIVED from this predicate (bd uow0), so the gate is
  //     attributed to the register it writes rather than to itself.
  //   * clause (d) (`Uncomputation.cpp`'s moved-anchor scan, and reverse program
  //     order generally) — an in-place basis-relabelling gate this predicate
  //     cannot see is precisely the "invisible write between forward and
  //     adjoint" that clause (d) exists to forbid.
  // VOID IS THE LOAD-BEARING TEST, NOT THE ARITY (the `isAbiQramStore` lesson,
  // bd 1fim, restated here because the first draft of this row proxied it with
  // arity alone and the Rule-13 round demonstrated the regression: a hand-written
  // NON-void same-named fake at the frozen arity closed the DAG, got a same-args
  // "adjoint" emitted for a rail-MINTING call, and a `cqrt_free` of a chain with
  // an unaccounted mint — verify-clean, free-pairing-clean, wrong). A non-void
  // fake must stay an unrecognized consumer (`NotClosed` => Rule-6 safe leak).
  if ((N.starts_with("cqrt_addc_") || N.starts_with("cqrt_xorc_")) &&
      G->getType()->isVoidTy() && G->arg_size() == 2 &&
      G->getArgOperand(0) == H)
    return true;
  // (The plain QRAM store is handled by the `isAbiQramStore` arm above, together
  // with its guarded twin — one definition for both frozen shapes.)
  return false;
}

// See the header for the full argument (bd test_C_libtooling-drbq Inc 1,
// round-1 review L3 §1 / L5 §1). ONE spelling of "is this rail frozen by a
// controlled rotation", derived from `isInPlaceGateOn` so the two cannot drift:
// that predicate ALREADY answers arg-1 for exactly this symbol shape (VOID,
// arity 3, `cqrt_ry_<W>_controlled`), so all this adds is the `_controlled`
// restriction — an uncontrolled `cqrt_ry_<W>(H, θ)` is reversible by the spine
// and must stay so.
bool railCarriesControlledRotation(const Value *H) {
  if (!H)
    return false;
  for (const User *U : H->users()) {
    const auto *G = dyn_cast<CallInst>(U);
    if (!G || !isInPlaceGateOn(G, H))
      continue;
    const Function *Callee = G->getCalledFunction();
    if (!Callee)
      continue;
    // THE `ry` STEM ONLY. Two exclusions, for two different reasons:
    //
    //  * `cqrt_qram_store_<W>_controlled(flag, H, idx, val)` — the iw81.7 guarded
    //    store, which `isInPlaceGateOn` also admits at arg 1 — is NOT frozen: its
    //    `..._controlled_unc` adjoint is emitted by the spine while its flag is
    //    still live (the GuardedStoreArm path does not strip the flag inside the
    //    region — see `ControlRegion::GuardedStoreArm`), so freezing it would leak
    //    every Shadow rail 7.5 reverses today.
    //  * `cqrt_rz_<W>_controlled` is NOT frozen either (bd drbq Inc 2a, PRD
    //    §12.1): a controlled Rz is diagonal on BOTH branches, so it relabels
    //    nothing and the register's chain is reversed and freed exactly as it was
    //    after a swap-routed phase region. The stem is UNREACHABLE here anyway —
    //    `isInPlaceGateOn` no longer admits it, and this predicate is derived from
    //    that one — but the whitelist is written to say `ry` rather than to rely
    //    on the derivation, because a whitelist that names the wrong set and is
    //    saved by ANOTHER predicate is exactly the justification-gone-stale shape
    //    this file keeps finding (bd 8h7d.5 F-1). Change both or neither.
    StringRef N = Callee->getName();
    if (N.starts_with("cqrt_ry_") && N.ends_with("_controlled"))
      return true;  // arg 1 IS `H` — `isInPlaceGateOn` just proved it.
  }
  return false;
}

bool isAllocMint(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // A qubit-register mint, OR (Phase 7.5 Inc 2) a QRAM array-handle mint: the
  // alloca-backed mutable array is an in-place-mutated register ROOT — its
  // stores are reversed (LIFO) but the array handle itself is a CLASSICAL
  // resource token, never freed (§2.9; Inc 1 "array-handle-never-freed"). Both
  // bottom out the DAG (no tainted parents to hop to — alloc takes a classical
  // count).
  return N.starts_with("cqrt_alloc_") || N.starts_with("cqrt_qram_alloc_");
}

// ── HOISTED FROM `DagTraversal`'s ANONYMOUS NAMESPACE (bd
// test_C_libtooling-6uqc Inc 5a) ────────────────────────────────────────────
// Both bodies below moved VERBATIM. They are gate VOCABULARY — exactly what
// this module exists to hold — and the M-B interior partition is now their
// third consumer beside `DagTraversal` and `Uncomputation`. Re-spelling either
// one in a third TU is the `railOf`/`isAbiQramStore` drift hazard (Rule 14).

// A reassigning template producer (`cq_template_<op>_<W>…`) — its result is a
// fresh rail the DAG must zero and free. (Rotations are in-place; allocs are
// roots; controlled forms / `_inv`/`_unc` twins are not forward data producers.)
bool isTemplateProducer(const CallInst *G) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // Phase 7.5: a QRAM load result is also a fresh rail the DAG must zero (via its
  // `_unc`) and free — and, crucially, must be CLOSURE-CHECKED here so a load whose
  // value fans out to a consumer OUTSIDE the recovered DAG marks the DAG NotClosed
  // (a Rule-8 safe-leak), never a use-after-free of a freed cell-copy.
  if (N.starts_with("cqrt_qram_load_") && !N.ends_with("_unc"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc");
}

// bd 261j(a) — does gate `G` keep its rail a BASIS PERMUTATION OF LIVE CONDITIONS,
// so that re-emitting the adjoint still returns the rail to |0⟩ even though the
// rail was RECORDED into a carrier the reversal never touches?
//
// THE INVARIANT (owner ruling 2026-08-10). Let R be a rail, W its forward chain,
// cond(W) the non-R SSA operands W reads, and C a record of R taken by a kept
// carrier. Freeing R is Rule-6-legal iff (a) R starts at |0⟩; (b) on the reachable
// subspace W(|0⟩_R ⊗ |c⟩_cond) = |g(c)⟩_R ⊗ |c⟩_cond — W is a basis permutation of
// cond(W) up to a label-diagonal phase; (c) the emitted reversal is W†; and (d)
// every register in cond(W) still holds its forward value when W† fires. Then
// W† C W (|0⟩_R ⊗ |ψ⟩) = |0⟩_R ⊗ (D ^= g(cond)) for ARBITRARILY many kept records.
//
// (a) WAS UNCHECKED FOR ROOTS until bd test_C_libtooling-5c5b (libcqops vmz9): a
// `cqrt_alloc_<W>(seed)` root starts at |seed⟩, and the spine freed it after
// `Ry†` with or without a record. `BirthFreeze` (`DagTraversal` step 3d) asks it
// now, of every rail.
//
// (d) IS DELICATE — it is the clause that made the first implementation of this
// ruling a silent miscompile, so read it precisely. "Still holds its forward
// value" means the value the register held WHEN THE FORWARD GATE RAN, not its
// value at the end of the forward stream. Those differ whenever a later
// non-diagonal gate writes the same register. Reverse program order delivers (d)
// for free — but ONLY because `emitDagReversal` adjoints EVERY recovered gate,
// including the gates of frozen rails; the freeze suppresses `cqrt_free`, never
// an adjoint. Any future change that skips an adjoint breaks (d) for every
// surviving reader of that register (MEASURED: see the Uncomputation.cpp note).
//
// DECISIVE COROLLARY: cond(W) = ∅ ⇒ R is freeable only if W is trivial on |0⟩.
// `cqrt_ry_<W>(H, θ)` has cond = ∅ (its only other operand is a CLASSICAL angle,
// Rule 3) and is NOT trivial on |0⟩ — it is the gate that mints the superposition.
// That, not any "redundancy" argument, is why the shipped slice_io free was a
// hidden measurement: `Ry† (CNOT-onto-kept-tape) Ry |0⟩` is not |0⟩.
//
// ⚠ THE SAME COROLLARY IS THE SECOND — AND STRONGER — REASON THE SPINE NEVER
// CLAIMS A BARE-`_Bool` CONTROL REGISTER (bd `test_C_libtooling-l4x4`
// sub-increment l4x4.b, round-1 Rule-13 review item H-9; recorded here because
// the increment's own record rested on the WEAKER of the two arguments).
// l4x4.b emits `cqrt_ry_<W>_controlled(h_b, h_r, θ)` with the USER'S `_Bool`
// register `h_b` as arg-0, the control. Two independent exclusions keep the
// whole-DAG spine off `h_b`, and only the first is about the `_controlled` list:
//
//   (1) `isTerminalHandle(h_b)` is FALSE — the `ry`-stem row above requires
//       `getArgOperand(1) == H`, so a CONTROL operand is not an in-place gate on
//       `h_b`, and the generic `if (N.contains("_controlled")) return false;`
//       bail refuses arg-0 outright. That argument is a property of THIS
//       FUNCTION'S LIST, and a future row admitted there could move it.
//
//   (2) `h_b` can never be an M-B INTERIOR candidate either, and THIS argument
//       is a property of what a rail leaf IS, not of any list. A rail leaf is BY
//       DEFINITION a `cq_theta_i1` result (`isCondRailLeaf`), so its register
//       ALWAYS carries an UNCONTROLLED `cqrt_ry_i1(h_b, θ)` — the very gate the
//       corollary above names: cond = ∅ and not trivial on |0⟩, hence NOT a
//       basis permutation, hence `false` HERE, hence `isInteriorConsumer` arm
//       (a) refuses it. NO ENTRY IN THE `_controlled` LIST CAN CHANGE THAT.
//
// Write it that way — and keep it written — because (2) is what survives a
// widening of (1): the day someone admits a new `_controlled` stem above, the
// six emitters named there need re-reading, and a bare-`_Bool` control does not,
// because its Ry is what disqualifies it. (The Rule-6 disposition that follows
// is the REQUIRED direction, not a shortfall: `Ry(θ)|0⟩ ≠ |0⟩`, so `h_b` is LEFT
// ALLOCATED and never freed — freeing it would be a hidden measurement.)
//
// FAILS CLOSED: anything not named here — including anything a future increment
// adds to the recovered gate set — is treated as NOT basis-preserving, which
// freezes the rail (a leak, the safe direction). `cqrt_x` is deliberately ABSENT:
// `isInPlaceGateOn` never recovers it today, so an entry would be an inert
// unverified claim; if it is ever recovered it must fail closed here.
//
// APPLIED PER GATE, NEVER TO THE COMPOSED CHAIN — deliberate, and it over-freezes.
// A rail whose gate sequence happens to COMPOSE to a basis permutation (the
// textbook case is `ry(θ)` then `ry(-θ)`, i.e. the identity) still freezes, because
// each factor is judged alone. Recognizing cancellation would mean reasoning about
// products of rotations, which is exactly the kind of "it must cancel" argument
// this ticket's history says not to trust; the cost is a leaked rail on a shape no
// emitter produces, and the alternative risks an under-freeze.
bool preservesBasisUnderRecord(const CallInst *G) {
  // ---- THE BRANCH-PHASE (KICKBACK) GATE, ASKED FIRST (bd 3qlq Inc 1 part A,
  // F-L7-1). DEFENCE IN DEPTH, and say which kind: at HEAD this arm CANNOT FIRE,
  // because every route into this function (`isInteriorConsumer`'s clause (a),
  // `DagTraversal`'s `D.Calls` scan, `Uncomputation`'s interior-group adjoint
  // gate) reaches it only for a gate `isInPlaceGateOn` already ACCEPTED, and that
  // predicate now refuses this one. It is written anyway — rather than left to
  // the `cqrt_rz_` row two screens down, which answers `true` — because `true`
  // here means "basis-preserving, hence not frozen, hence FREEABLE and
  // ADJOINTABLE", which is the one answer that must never be given about a gate
  // carrying the program's answer. The `cqrt_rz_` row's argument ("a diagonal gate
  // relabels nothing") is the right argument for the FREE and no argument at all
  // for the ADJOINT; that gap is exactly what F-L7-1 fell through.
  if (isBranchPhaseGate(G))
    return false;
  // A reassigning producer — `cq_template_*` (out = f(parents), the embedded
  // permutation) and `cqrt_qram_load_<W>` (a cell copy conditioned on arr/idx).
  // Both are permutations of their PARENTS, so (b) holds. (d) holds because
  // `emitDagReversal` adjoints every recovered gate in reverse program order,
  // which restores each parent to its producer-time value before this gate's
  // `_unc` fires. Say it that way and not "the DAG keeps the parents live": LIVE
  // is not enough, they must be at the RIGHT value, and an earlier draft of this
  // freeze falsified exactly that by skipping frozen rails' adjoints.
  // NOTE the spelling matters: `railOf` returns the gate ITSELF for a producer,
  // so writing this whitelist as {rz, qram_store} with producers closed would
  // freeze every template rail and collapse into the blunt DAG-global rule.
  if (isTemplateProducer(G))
    return true;
  const Function *Callee = G->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // Rz is DIAGONAL: trivial on |0⟩ (condition (b) with g = identity), and the
  // label-diagonal phase it applies commutes with, and cancels against, a
  // basis-label record.
  //
  // THE PREFIX DELIBERATELY COVERS `cqrt_rz_<W>_controlled` TOO (bd drbq
  // audit; nothing mints that symbol since 3qlq). Matched incidentally before it
  // had an emitter, it is now matched ON PURPOSE, and it is correct:
  // a controlled Rz is `f=0 → I`, `f=1 → diag(1, e^{iθ})`, diagonal on BOTH
  // branches, so it relabels nothing whatever the flag holds. Its NON-diagonal
  // twin `cqrt_ry_<W>_controlled` is NOT matched here and must never be — a
  // controlled Ry relabels its target on the `f=1` branch, so a rail carrying
  // one stays FROZEN (not freed) under the bd 261j(a) record rule, which is the
  // Rule-6 conservative direction.
  //
  // THE VOID + ARITY FENCE ON THE `_controlled` SPELLING IS THE bd 1fim ONE, and
  // it is here for SYMMETRY WITH `isInPlaceGateOn`, which carries it (round-1
  // Rule-13 review, lens L5 §6). `true` on this path is the UNSAFE direction —
  // basis-preserving ⇒ not frozen ⇒ FREED — and a bare prefix is a proxy for the
  // property, not the property (the lesson the guarded-store row below spells
  // out). Today an off-arity or non-void `@cqrt_rz_<W>_controlled` fake cannot
  // reach this function (membership in `D.Calls` goes through `isInPlaceGateOn`,
  // which fences both axes), so this is a derivation, not a live hole — and
  // resting on a DERIVATION from another predicate's fence is exactly what bd
  // 1fim showed goes stale. Two predicates, one gate, one answer.
  //
  // ⚠ THE CONTRADICTION WITH `railCarriesControlledRotation` IS RESOLVED, AND IT
  // RESOLVED IN THIS PREDICATE'S FAVOUR — BUT THE `_controlled` ARM IS NOW
  // UNREACHABLE (bd drbq Inc 2a; the round-2 review, lens A §4, is what recorded
  // the contradiction, and notes §10.3 is what handed the decision to Inc 2).
  //
  // The history, because both halves matter to anyone changing this: Inc 1 had
  // `railCarriesControlledRotation` FREEZE any `cqrt_{ry,rz}_<W>_controlled` rail
  // while this predicate called the `rz` spelling basis-preserving, i.e. NOT
  // frozen, i.e. FREEABLE. One gate, two answers; the freeze won because it is
  // asked first. Inc 2a SPLIT THE STEMS — `isInPlaceGateOn` now admits only the
  // `ry` spelling — so the freeze no longer claims a controlled Rz, and its
  // verdict and this one agree: NOT frozen.
  //
  // The reachability, stated exactly rather than left as "so this goes live":
  // this function is only ever asked about a member of `D.Calls` / an
  // `isInteriorConsumer` candidate, and membership in BOTH goes through
  // `isInPlaceGateOn`, which now REFUSES `cqrt_rz_<W>_controlled`. So the
  // `_controlled` arm below CANNOT FIRE at HEAD. It is kept — rather than
  // deleted — because `true` is the physically correct answer for a diagonal gate
  // and because deleting it would make the fail-closed default (`false` =
  // frozen) the answer for a shape that is not frozen, which is the wrong claim
  // to leave behind for whoever re-admits the stem. If anyone does re-admit it to
  // `isInPlaceGateOn`, this arm goes live and becomes the only opinion on whether
  // that rail may be freed — re-read the Inc-2a note there FIRST.
  if (N.starts_with("cqrt_rz_")) {
    if (N.ends_with("_controlled"))
      return G->getType()->isVoidTy() && G->arg_size() == 3;
    return true;
  }
  // A QRAM store is a permutation of its array conditioned on idx/val (and, in
  // the guarded form, a flag) — all borrowed parents, restored to their
  // producer-time values by the same every-gate reverse-play as above (NOT merely
  // "kept live"; a rotated index reaching `cqrt_qram_store_<W>_unc` pops the wrong
  // cell, which is what the skip-the-adjoint draft actually did).
  //
  // ASK `isAbiQramStore` — this was the THIRD live spelling of that relation and the
  // only one whose bare-prefix form answered in the UNSAFE direction (bd 1fim
  // Rule-13 round): `true` here means basis-preserving, hence NOT frozen, hence
  // FREED. An off-ABI store — wrong arity, or the frozen arity with a non-void
  // return that mints a rail — is not a permutation of its parents at all, and
  // claiming it is would clear a rail for freeing that the reversal never zeroed.
  // The other two consumers (`isInPlaceGateOn`, `isInverseEmittable`) now share the
  // one definition; this makes it three of three (Rule 14).
  if (isAbiQramStore(G))
    return true;
  // Issue dtzb / bd test_C_libtooling-6uqc (M-C Inc 2a) — the IN-PLACE VALUE
  // gates `cqrt_addc_<W>(R, imm)` / `cqrt_xorc_<W>(R, imm)`. DECIDED, not left
  // to the fail-closed default, because M-C made them RECOVERABLE: before it,
  // `isInPlaceGateOn` never returned them and an entry here would have been the
  // "inert unverified claim" the `cqrt_x` note below warns about. They are
  // recovered now, so the claim has to be made and argued.
  //
  // TRUE, and the ground is (b) — a BASIS PERMUTATION, not (a) triviality on
  // |0>. `R := R + imm (mod 2^W)` and `R := R ^ imm` are bijections of the
  // computational basis whose only other operand is a CLASSICAL immediate, so
  // cond(W) is empty in the quantum sense and W maps |x> to a single basis
  // label — never a superposition. Every record a kept carrier takes of R is
  // therefore a copy of a definite label that is a function of R's own
  // conditions, and `W† C W (|0>_R ⊗ |ψ>) = |0>_R ⊗ (D ^= g(cond))` goes through
  // exactly as it does for a `cq_template_*` producer, which is the SAME
  // category of object (a permutation of its inputs) — that is the row this
  // belongs beside, NOT the diagonal `cqrt_rz_` row.
  //
  // SAY WHY THE "DECISIVE COROLLARY" ABOVE DOES NOT REACH THESE. Read literally
  // ("cond(W) = ∅ ⇒ R is freeable only if W is trivial on |0>") it would exclude
  // an addc, whose W|0> = |imm> ≠ |0>. But the corollary's argument is about
  // MINTING SUPERPOSITION — `Ry|0>` is not a basis state at all, so a record of
  // it is entanglement no adjoint can undo. An addc's |imm> IS a basis state, a
  // classical constant, so the record it feeds carries no which-path information
  // and the adjoint (`imm -> -imm`; `xorc` self-inverse — `EmitInverse` already
  // ships both) returns R to |0>. The corollary is stated for the gate that
  // motivated it; the invariant above is the general test, and these pass it.
  //
  // Clause (d) is delivered by reverse program order, the same way it is for a
  // template producer: the M-C addc joins the very DAG that walks R (it is an
  // in-place gate ON R), so its adjoint always fires before any earlier gate's
  // `_unc` re-reads R. VOID is the load-bearing test, mirroring
  // `isInPlaceGateOn`'s row (bd 1fim: arity is an incomplete proxy — a non-void
  // same-named fake is not this gate and must fail closed to `NotClosed`).
  if ((N.starts_with("cqrt_addc_") || N.starts_with("cqrt_xorc_")) &&
      G->getType()->isVoidTy() && G->arg_size() == 2)
    return true;
  return false;  // `cqrt_ry_<W>` lands here — and so does anything new.
}

// See the header (bd r2j3.21). Derived from the two predicates above, never
// re-spelt: an in-place gate on `P` that is not a basis permutation.
bool isNonPermutationMove(const CallInst *M, const Value *P) {
  return M && isInPlaceGateOn(M, P) && !preservesBasisUnderRecord(M);
}

bool isQramArrayHandle(const Value *V) {
  const auto *CI = dyn_cast_or_null<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_qram_alloc_");
}

bool isMeasureSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_measure_");
}

bool isOutputSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_tape_write_");
}

bool recordsIntoKeptCarrier(const CallInst *S, const Value *H) {
  // THE COPY-OUT SURFACE (bd test_C_libtooling-5pio, owner ruling 2026-08-11). A
  // method-B `cqrt_copy_<W>(src, dst)` records `src`'s basis label onto `dst`, and
  // `dst` is a KEPT carrier the whole-DAG reversal never touches — structurally the
  // same relation to the reversal as a tape write, so it seeds the same freeze.
  //
  // SLOT-AWARE here, unlike the tape arm below: `isCopyOutSink` matches only when
  // `H` is arg 0, the SOURCE.
  //
  // STATE THE REASON CORRECTLY, because the tempting one is FALSE. A draft of this
  // comment said a blind scan "would seed the destination and freeze the very
  // register the copy exists to produce". That harm CANNOT occur, and a Rule-13
  // reviewer measured it three ways: a freeze suppresses only a `cqrt_free`, never
  // an adjoint, and a copy DESTINATION is never freeable in the first place — in the
  // destination role it is not a benign closure user, so it falls through to
  // `D.NotClosed = true` and the whole DAG is left allocated, and it fails
  // `isTerminalHandle` for the same reason. Seeding it would change nothing; if it
  // ever did, it would be a leak — the safe direction, exactly as the tape arm's own
  // slot-BLINDNESS argues four lines below.
  //
  // So the asymmetry is sound, but it is sound because of that `NotClosed`
  // compensation, not because of any harm avoided. Written down here because the
  // compensation is what a future over-decline-reduction would remove: make the
  // destination slot benign for closure and this arm silently needs to become
  // slot-blind. (bd 5pio Rule-13 round; CLAUDE.md's warning about agent-authored
  // justifications hardening by repetition is exactly what this replaces.)
  //
  // WHY THIS AND NOT A PREDICATE ON THE DESTINATION. bd 5pio asked whether to admit
  // the copy sink only when `dst` is provably measured. Bennett.jl — the project's
  // standing ground truth for the compute/copy-out/uncompute model — requires
  // NOTHING of a copy destination: not measured (it has no measurement concept), not
  // kept, not even fresh or zero, and it ships three kernels that copy out and then
  // uncompute-and-free the SOURCE into a live register, an accumulator and a scratch
  // checkpoint respectively. A dst-measured rule would break all three. Bennett puts
  // the entire reclamation license on the SOURCE's own chain, which is what this
  // seed hands to `preservesBasisUnderRecord`. Note also what a dst-measured guard
  // could not have caught: it says nothing about the source's correlation with its
  // own ANCESTORS, which is exactly what the backward walk over `AncEdges` models.
  // (bd memory [bennett-copyout-destination-2026-08-11].)
  //
  // CAUTION, because Bennett's own discipline does NOT discriminate CQ's hazard:
  // `ry(%h); copy(%h,%dst); ry(-%h); free(%h)` SATISFIES it completely — exact whole
  // -chain adjoint, copy strictly between — and the unitary is still wrong. The
  // discrimination is `preservesBasisUnderRecord`'s rotation test, which is CQ's own
  // and has no Bennett counterpart (Bennett's gate universe is closed at three basis
  // permutations, so the invariant is vacuous there).
  if (isCopyOutSink(S, H))
    return true;
  // Tape-only and SLOT-BLIND — see the header for why both are load-bearing (the
  // controlled twin records its ctrl at arg 0 and its src at arg 2, and the tape
  // token is never a DAG rail so a blind scan cannot over-match).
  if (!isOutputSink(S))
    return false;
  for (const Use &A : S->args())
    if (A.get() == H)
      return true;
  return false;
}

bool isCopyOutSink(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // The UNCONTROLLED 2-arg basis copy `cqrt_copy_<W>(src, dst)` reading `H` as its
  // SOURCE (arg 0). Like a measure / tape-write sink it READS H without consuming
  // it, so the spine treats it as a benign terminal user; the copy DESTINATION
  // (dst) is the kept carrier. The 3-arg `_controlled` data-mux copy (4.4/6.5) and
  // any `_inv`/`_unc` twin fail.
  //
  // IT IS ALSO A `recordsIntoKeptCarrier` (bd 5pio, owner ruling 2026-08-11), so
  // this predicate is now load-bearing for the 261j record FREEZE and not only for
  // closure. This comment used to read "NOT a `recordsIntoKeptCarrier` — bd 8gi5
  // owns whether this surface needs the 261j freeze"; that ticket ruled.
  //
  // SRC AND DST MUST BE DISTINCT. `cqrt_copy_<W>(%x, %x)` is rejected, and the
  // reason is that BOTH readers of this predicate — the closure scan
  // (`DagTraversal`) and `isTerminalHandle` — `continue` on the FIRST match, so a
  // value passed in both slots would be read purely as a preserved SOURCE and its
  // WRITE role would vanish: the spine then frees a rail a CNOT wrote, with that
  // write never adjointed (`opt` rc=0, verify-clean; stage 2b does catch it, as
  // `VIOLATION B1-input-aliases-written-rail`). `railOf` already reasons explicitly
  // about the same-value-in-two-slots case for in-place gates; this predicate never
  // got that treatment until bd 5pio's Rule-13 round found it. Declining the aliased
  // form is the over-declining direction and no emitter mints it.
  return N.starts_with("cqrt_copy_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc") && G->arg_size() == 2 &&
         G->getArgOperand(0) == H && G->getArgOperand(0) != G->getArgOperand(1);
}

Value *railOf(CallInst *G) {
  // An in-place gate's rail is the operand it MUTATES, so ASK `isInPlaceGateOn`
  // — the single definition of that relation — instead of re-spelling its
  // arity/suffix tests here. Re-spelling them is exactly how the guarded QRAM
  // store came to be mis-attributed (bd test_C_libtooling-uow0): this function
  // returned the arg-0 FLAG of `cqrt_qram_store_<W>_controlled(flag, arr, idx,
  // val)` while `isInPlaceGateOn` correctly matched the arg-1 ARRAY of the very
  // same gate, so the two predicates disagreed about which register the gate
  // writes. Driving one from the other makes them agree BY CONSTRUCTION rather
  // than by two spellings being kept in sync (Rule 14).
  //
  // First match wins. That is unambiguous, not a tie-break: `isInPlaceGateOn`
  // matches exactly ONE argument position per callee shape, and when the same
  // SSA value is passed in two slots of one gate the answer is that value either
  // way.
  for (Value *Op : G->args())
    if (isInPlaceGateOn(G, Op))
      return Op;
  const Function *Callee = G->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // `cqrt_x` is self-inverse and acts on its arg-0 handle. `isInPlaceGateOn`
  // deliberately does not recognize it (the same reason it is absent from
  // `preservesBasisUnderRecord`), so the loop above never returns for it.
  //
  // REACHABILITY, stated exactly — an earlier draft of this comment said
  // "UNREACHABLE, a void call can never be a DAG handle" and that was WRONG
  // (measured in the bd uow0 Rule-13 round). The premise holds for the real
  // ABI symbol, which IS void; but `declineTaintEscapes` carves out `cqrt_*` by
  // NAME with no signature check, so a user-declared NON-void `@cqrt_x` is
  // recovered by the DAG walk's tainted-CallInst path and this arm does fire.
  // Behaviour there is identical to the pre-uow0 spelling (arg 0) and is the safe
  // direction (the fictional result is leaked, not freed). Kept because it AGREES
  // with the loop above — were `isInPlaceGateOn` ever taught `cqrt_x` it would
  // match this same arg-0 handle — so unlike the pre-uow0 spelling for the QRAM
  // store, this arm cannot contradict it.
  if (N == "cqrt_x" && G->arg_size() >= 1)
    return G->getArgOperand(0);
  // A reassigning producer (`cq_template_*`, `cqrt_qram_load_<W>`): the fresh
  // result IS the rail (PRD §2.11).
  return G;
}

bool isTerminalHandle(Value *Handle, const TaintSet &taint) {
  if (!taint.Tainted.count(Handle))
    return false;
  // ── bd `xdu2` / L-1a W1 (D1) — A RAIL PARKED IN A BANK CELL IS THE BANK'S.
  //
  // The scan below `continue`s on a non-`CallInst` user, so a `StoreInst` is
  // SILENTLY SKIPPED and a rail whose value was written into a rail-bank cell
  // is nominated as a DEAD terminal. What happens next is decided in
  // `computeFreePoint` and both outcomes are wrong for a bank:
  //   * inside `main` it short-circuits to `Escaped` — right answer, by
  //     accident, and an accident that covers almost nothing: measured over an
  //     80-slice sample of `tests/e2e/slice_*.c`, **76 of 80** carry quantum
  //     work OUTSIDE `main`;
  //   * outside `main` the store falls to `FirstUnrecognized` and the module
  //     LOUD-DECLINES `cq uncompute: tainted handle reaches an unrecognized
  //     user` — an over-decline of the canonical W1 slice, written in the
  //     ordinary house style (`slice()` called from `main`);
  //   * and if anything ever DELETES the store, the rail is genuinely dead and
  //     the spine ADJOINTS AND FREES IT. MEASURED (`probes/b14_bank_nonmain.c`
  //     under `probes/emulate_piece3.sh`): `ry(+0.5); ry(-0.5); cqrt_free` per
  //     cell — the spine un-prepares and frees the three qubits the user is
  //     about to measure — at `opt` exit 0 with stage 2b reporting
  //     `1 verified, 0 violation(s), 0 unproven`.
  //
  // So the nomination is stopped AT SOURCE. The rail is LEFT ALLOCATED, which
  // is Rule 6's accepted leak and is byte-identical in the emitted stream to
  // what the flat twin produces for a measured rail (`Measured` ⇒ no adjoint,
  // no free).
  //
  // ⚠ ASKED STRUCTURALLY OF THE HANDLE'S USERS AT ASK TIME, never as a
  // `Value *`-keyed owner set — that spelling is recorded in
  // `TaintPropagation.h` as a shipped silent miscompile (a set keyed on a
  // pre-`lowerOps` SSA value the lowering then erases for every derived base).
  if (railStoredToRailBank(Handle))
    return false;
  // Terminal iff EVERY user is benign: an in-place rotation on `Handle` (mints
  // no new value), a measurement sink, or a non-quantum read. ANY other gate
  // that takes `Handle` as an operand — a data/compare/cast template, a
  // controlled gate, a `_controlled`/teardown `_inv` — consumes the register
  // forward or keeps it live as control input, so `Handle` is NOT the terminal.
  for (User *U : Handle->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      continue;  // a classical/non-call read does not extend the quantum chain
    if (isInPlaceGateOn(CI, Handle) || isMeasureSink(CI) || isOutputSink(CI) ||
        isCopyOutSink(CI, Handle))
      continue;  // in-place rotation, measurement/output sink (7.6), or a method-B
                 // copy-out reading Handle as src (sxuk — preserves it)
    return false;  // any other gate consumes `Handle` ⇒ not the chain terminal
  }
  return true;
}

// ── M-B INTERIOR MODE (bd test_C_libtooling-6uqc Inc 5a) — see the header ────

bool isInteriorConsumer(const CallInst *C, const Value *R,
                        const TaintSet &taint, bool AdmitCloneCalls) {
  // (a) an IN-PLACE gate on the rail itself. It mints nothing, so it belongs to
  //     R's own DAG link and is adjointed with it — but ONLY if it is a basis
  //     permutation. `cqrt_ry_<W>` is the one in-place gate that is not, and a
  //     rail carrying one can never be returned to |0⟩ by an adjoint once
  //     anything downstream recorded it (`preservesBasisUnderRecord`'s "decisive
  //     corollary"). A rail with an `Ry` on it is therefore NOT an interior
  //     candidate at all — safe-leak, exactly as its alloc-minted cousin is.
  if (isInPlaceGateOn(C, R))
    return preservesBasisUnderRecord(C);
  // (b) a FORWARD reassigning producer that READS the rail. This is the whole
  //     point of "interior": the consumer is not in the recovered set (its own
  //     result may be measured, taped, or simply another chain's business), and
  //     the rail is discharged only once the driver has PROVEN that consumer
  //     already executed and never re-reads (`provablyBefore`). The structural
  //     half is just "it is a plain forward producer".
  //
  //     `isTemplateProducer` also admits `cqrt_qram_load_<W>`, which is correct
  //     for a CONSUMER: a load that reads the rail as its index has read it and
  //     moved on. It is only as a PRODUCER (i.e. as the rail itself) that Inc 5
  //     excludes the QRAM surface — that exclusion lives in
  //     `isInteriorTerminalHandle`, not here.
  //
  //     …AND THE RAIL MUST BE READ IN A HANDLE SLOT (bd test_C_libtooling-4p7j
  //     Rule-13 round, finding F5). "Is a template producer" says the call has
  //     no mutating slot; it does not say the rail reached a QUANTUM operand.
  //     `cq_template_add_i32_hl(%h, %rail)` reads the rail in the CLASSICAL
  //     literal slot, and at width i32 both slots are `i32` in the IR — only
  //     the symbol's shape suffix distinguishes them, so the test is
  //     `TemplateName::isHandleSlot`, the inverse of the one table that spells
  //     that suffix (Rule 14 — a second slot table here is the `railOf` drift
  //     hazard). No emitter in the pass can mint such a call (`ArithLowering`
  //     chooses `_hl`/`_lh` precisely to put the handle in the handle slot and a
  //     `Constant` in the other), so this refuses only hand-written IR — the
  //     leak direction, pinned by
  //     lowering_uncompute_interior_leak_literal_slot.ll.
  if (isTemplateProducer(C)) {
    StringRef CN = C->getCalledFunction()->getName();
    // `cqrt_qram_load_<W>(arr, idx)` is the one admitted non-`cq_template_`
    // producer and BOTH its operands are handles (an array token and an index
    // rail) — the frozen 7.5 ABI, `runtime/cq_runtime.h`.
    if (CN.starts_with("cqrt_qram_load_"))
      return true;
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == R && !isHandleSlot(CN, I))
        return false;
    return true;
  }
  // (b″) A FORWARD QRAM STORE reading the rail in any slot but its ARRAY (bd
  //      test_C_libtooling-r2j3.1). The load above has been an interior consumer
  //      since Inc 5 for the reason (b) gives: it READS its index and moves on.
  //      A store does the same with every operand except its array: it is in
  //      place on the ARRAY only (`isInPlaceGateOn` matches that slot alone, and
  //      (a) above has already answered it); the index selects a cell, the cell
  //      receives a copy of `val`, and the guarded form's path flag only gates
  //      the write — all three are preserved. Before this row a store
  //      disqualified the rail, so a COMPUTED index (`arr[q&7]` →
  //      `and_i32_hl(h,7)`), a computed value (`arr[p] = q+1`) or a guarded
  //      store's flag (`icmp_slt(h,3)`) of a store that is never reversed stood
  //      allocated as a live CNOT copy of its source across every later gate on
  //      it: `ry(h,-0.5)` then rotated a register entangled with the copy (the
  //      source measured q at random where it should read its initial basis
  //      value; `opt` exit 0, stage 2b clean, one M-A warning).
  //
  //      THE STORE'S OWN REVERSAL IS WHY THIS IS SAFE, NOT A HOLE. A store the
  //      dead-terminal spine reverses re-reads flag/idx/val in its `_unc`; that
  //      spine walks those operands as DAG parents (`DagTraversal`), so the rail
  //      is in its `ReversedRails` and the interior partition, which runs after
  //      it, never takes it (and a rail read by both a reversed and an
  //      unreversed store makes the reversed DAG `NotClosed`, so it emits
  //      nothing). The M-C prediction withholds the same superset
  //      (`planInteriorDischarges`). So this row only ever governs a store that is
  //      NOT reversed — one that reads the rail once and never again — exactly
  //      the load's situation. For the GUARDED store's flag that is the case the
  //      arm emitter's "the strip rides the same LIFO as the store" did not
  //      cover: with no store reversal there was no strip at all.
  if (isAbiQramStore(C)) {
    bool Reads = false;
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (C->getArgOperand(I) == R)
        Reads = true;
    return Reads;  // the array slot never reaches here: (a) answered it.
  }
  // (b′) A PHASE-6 CLONE CALL that reads the rail and provably never writes it
  //      (bd test_C_libtooling-rhk5). The same role as (b): a consumer that reads
  //      `R`, mints a FRESH result rail, and is finished with `R` once it has run —
  //      the hand-inlined twin puts a `cq_template_*` producer exactly here, and
  //      (b) admits that. What (b) gets from the symbol grammar ("a producer has
  //      no mutating slot") a clone call cannot, so it is PROVEN from the callee
  //      body by `cloneCallPreservesArg`, keyed on the specializer's record and
  //      failing closed. (b)'s F5 fence — the rail must reach a QUANTUM slot — is
  //      the record's HANDLE-slot mask here, which the predicate already requires
  //      of every slot `R` is passed in.
  //
  //      THE POSITIONAL HALF IS UNCHANGED AND STILL THE DRIVER'S: that the call
  //      has already executed at the discharge point and never re-reads `R` is
  //      `useCompleteBeforeDischarge`'s proof, exactly as for a template reader.
  //
  //      Before this row a clone call DISQUALIFIED the rail (the list below said
  //      so), which left a chain rail the hand-inlined twin discharges allocated
  //      and entangled — `s = h(m, p)` against `s = p + 1`, measured in
  //      TRACK_RHK5.md.
  //
  //      GATED BY `AdmitCloneCalls` (bd rhk5 round 2, bd `kyy1`): widening this
  //      set widens the COMPONENT and moves its discharge point, and the interior
  //      driver needs the pre-rhk5 answer too, to prove it never loses a discharge
  //      that answer made (see `Uncomputation::collectInteriorPlans`).
  if (AdmitCloneCalls && cloneCallPreservesArg(C, R, taint))
    return true;
  // (c) AN EMITTER-RECORDED PHASE-4 FLAG STRIP, reading the rail in a SHIFTED
  //     HANDLE SLOT (bd test_C_libtooling-160a, M-B Increment 6 — clause (d2)).
  //
  //     The strip is the void out-first `cq_template_<cmp>_<W>_hl_unc(flag,
  //     operands…)` a control emitter mints to return its condition flag to |0⟩
  //     (bd `8txa`). For the CHAIN rails it names in slots 1.. it is a pure
  //     READ: it recomputes the compare and XORs the result onto the flag,
  //     leaving every operand exactly as the forward mint found it. That makes
  //     it an interior consumer in the same sense as a forward producer — the
  //     rail is dead once it has run — and admitting it is what moves the
  //     partition's `dagInsertPoint` PAST the strip, which is the only place a
  //     derived condition's chain may legally be discharged.
  //
  //     THREE FENCES, EACH LOAD-BEARING:
  //
  //     * MEMBERSHIP, NOT A NAME TEST. The uncompute spine's own `_unc`s and the
  //       7.4 reverse-play wear the same suffix; admitting those would let this
  //       partition discharge a rail another partition's adjoint still reads
  //       (Rule 8's shared prefix, from the other side). Only a strip a control
  //       emitter recorded AT ITS EMISSION SITE — long before `uncompute` runs —
  //       is in `DischargedFlagGates`.
  //     * SLOT 0 IS REFUSED (`isUncHandleSlot`). That slot is the FLAG the strip
  //       zeroes and the emitter frees on the next line: a rail Phase 4 owns.
  //       (The flag is already excluded by its `cqrt_free` user, which this
  //       function refuses; this is the second, structural statement of it.)
  //     * A LITERAL SLOT IS REFUSED, for the same reason as the forward case
  //       (finding F5): at width i32 nothing but the symbol distinguishes the
  //       slots.
  //
  //     WHAT THIS DOES **NOT** SAY is that the rail may be discharged HERE. The
  //     positional half — that the strip has already run and never reads the
  //     rail again — is the driver's `provablyBefore` proof, exactly as it is
  //     for a forward producer.
  //
  //     The membership-and-slot test itself is `isRecordedStripReaderOf`, the
  //     one spelling `Uncomputation::preservesBorrowedParent` asks too (bd 7xsh).
  //     A recorded strip that does NOT read `R` purely still answers here, with
  //     `false` — no fall-through to the list below, exactly as before.
  if (taint.DischargedFlagGates.count(C))
    return isRecordedStripReaderOf(C, R, taint);
  // Everything else DISQUALIFIES the rail, and the list of what "everything
  // else" contains is the point: `cqrt_measure_*` (observed), a
  // `cqrt_tape_write_*` / `cqrt_copy_*` (recorded into a kept carrier the
  // reversal never touches — bd 261j(a)/5pio), any `_controlled` gate or route
  // (`cqrt_cswap`/`cqrt_x`/`cqrt_cnot`/`cqrt_toffoli` — Phase-4 owns the rail),
  // a `__cq_q_*` clone call whose body (b′) could NOT prove read-only on `R`
  // (until bd rhk5 this said "a clone call", unqualified — every clone call
  // disqualified the rail), a `cqrt_free`, and every `_inv`/`_unc` twin. Each
  // is a Rule-6 SAFE LEAK here, never a diagnostic: M-B is leak-first and the
  // late M-A guard owns loudness for a record that is still standing at a
  // non-diagonal gate.
  return false;
}

// See the header. Moved VERBATIM out of `isInteriorConsumer`'s clause (c) (bd
// 7xsh) so its second customer asks it rather than re-spelling it (Rule 12).
bool isRecordedStripReaderOf(const CallInst *C, const Value *R,
                             const TaintSet &taint) {
  if (!taint.DischargedFlagGates.count(C))
    return false;
  StringRef CN = C->getCalledFunction() ? C->getCalledFunction()->getName()
                                        : StringRef();
  bool ReadsInHandleSlot = false;
  for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
    if (C->getArgOperand(I) == R) {
      if (!isUncHandleSlot(CN, I))
        return false;  // slot 0 (the flag it WRITES), a literal slot, or a
                       // layout `isUncHandleSlot` cannot read — fail closed.
      ReadsInHandleSlot = true;
    }
  return ReadsInHandleSlot;
}

bool isInteriorTerminalHandle(Value *Handle, const TaintSet &taint,
                              bool AdmitCloneCalls) {
  if (!taint.Tainted.count(Handle))
    return false;
  auto *H = dyn_cast<CallInst>(Handle);
  if (!H)
    return false;
  // (I1) the rail's own PRODUCER. An uncontrolled `cq_template_*`, or (bd
  //      p3kd.13) an owned Phase-6 clone result, whose adjoint is its Bennett twin
  //      (`isCloneProducer`, CloneProducer.h — the lift bd ln16 named).
  //  * `cqrt_alloc_<W>` is excluded: not a producer here — its value comes from a
  //    `cqrt_ry_<W>`, NOT a basis permutation, so an interior discharge of it would
  //    be a hidden measurement (it is entangled with whatever downstream record
  //    made it "interior"). It stays a BORROWED parent.
  //  * `cqrt_qram_load_<W>` is excluded BY SCOPE, not by physics: it passes
  //    `preservesBasisUnderRecord` and its `_unc` is out-first like any other,
  //    but its parents are an ARRAY handle whose in-place mutations are QRAM
  //    stores, and Inc 5 deliberately leaves the 7.5 Shadow surface alone
  //    (severance class 4 is the ruled-deferred class at the M-A guard too).
  //    Pinned by lowering_uncompute_interior_leak_qram_load.ll.
  const Function *Callee = H->getCalledFunction();
  if (!isCloneProducer(H, taint) &&
      (!isTemplateProducer(H) || !preservesBasisUnderRecord(H) || !Callee ||
       !Callee->getName().starts_with("cq_template_")))
    return false;
  // (I2) ONE OWNER PER RAIL. A dead terminal belongs to the existing whole-DAG
  //      partition; adjointing it from both would double-uncompute the shared
  //      prefix (use-after-free + double free — Rule 8, and the exact hazard
  //      WI-4 was built to avoid).
  if (isTerminalHandle(Handle, taint))
    return false;
  // (I3)/(I4) every user vetted, at least one forward consumer.
  bool HasForwardConsumer = false;
  for (User *U : Handle->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      return false;  // `ret`, a φ/select router, a `store`, a classical `icmp` —
                     // none of them is a gate whose execution the driver can
                     // prove, and a `ret` is an escape outright.
    if (!isInteriorConsumer(CI, Handle, taint, AdmitCloneCalls))
      return false;
    // (I4) counts only a FORWARD producer. An in-place gate mints nothing, and
    // a recorded flag strip is an adjoint READ — a rail whose ONLY user were the
    // strip would mean the forward mint had already been erased, a shape no
    // emitter produces; requiring a real forward consumer keeps that hypothetical
    // out of the partition rather than trusting it.
    if (!isInPlaceGateOn(CI, Handle) && !taint.DischargedFlagGates.count(CI))
      HasForwardConsumer = true;
  }
  return HasForwardConsumer;
}

}  // namespace cq
