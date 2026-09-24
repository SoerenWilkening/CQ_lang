// SelectClassify.cpp — the §0 prove-or-decline ladder for a tainted-condition
// `select` (swap-route 4.4 WI-1; PRD Part IV §16; IMPLEMENTATION-4.4 §3).
//
// Pure analysis — NO IR is mutated (Rule 9). Every gate reads SSA-value
// identities that survive rotation lowering's later RAUW-to-handle: detection
// runs at the pipeline's `detectControlRegions` step (L83), the eventual
// `SelectMergeEmit` runs at `lowerControlRegions` (L84), and rotation lowering
// only at L110 — so the select and its operands still carry their real logical
// types here. See `SelectClassify.h` for the six-gate contract.

#include "SelectClassify.h"

#include "ArmAnalysis.h"     // comparePredLowerable, diagonalAliasHit, condProvenance
#include "CompareLowering.h" // compareFlagMintable (per-leaf width/scope fence)
#include "CondLiteral.h"     // condLiteralAdmissible (bd xdu2.13)
#include "ControlPlan.h"     // diagnoseUnderControl, ControlPlan, ControlRegion
#include "OpcodeSupport.h"   // abiWidthFromType
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"   // WidthDispatch (threaded to classifyAngleSelect)
#include "WireWalk.h"        // findNonDiagonalWireGate (gate 2c stale condition)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// TU-local name-prefix predicates (deliberately NOT exported — they collide with
// the same-named anonymous helpers in ArmClassify.cpp / WireWalk.cpp /
// RegionTreeDetect.cpp; ArmAnalysis.h header note).
bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}
// ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 (2026-09-05), AND DELIBERATELY
// KEPT (PRD `retire-swap-route-PRD.md` §6.2 row P6: "every 'Rz is diagonal and
// exempt' clause becomes VACUOUS rather than deleted").
//
// The 15-width `@cq_phi_<sfx>(x, angle)` family is RETIRED: `CQ.h` no longer
// declares it and `resolveSources` no longer resolves it, so no call this
// predicate can match exists in a module the pass lowers. It CANNOT accidentally
// match the register-free replacement, and that is a fact about the strings, not
// a hope: `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE — six characters
// against a seven-character prefix. The new call is recognized by EXACT
// membership instead (`TaintPropagation.h`'s `isRegisterFreePhaseCall`), which is
// also the project's standing accept-side discipline (never a name prefix — the
// `cq_theta_evil` hazard).
//
// KEEPING IT IS THE POINT: a `void(double)` call has no arg-0 WIRE and no arg-1
// ANGLE, so every clause below that follows `getArgOperand(0)` as a rail, or
// reads `getArgOperand(1)` as an angle, would be reading the wrong operand — or
// out of range — if this predicate were widened to admit it. Do not "fix" this by
// making it match `cq_phi`.
bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }
bool isRotationCall(const Value *V) { return isPhiCall(V) || isThetaCall(V); }

// GATE 3 (the §3.2 BLOCKER) — does `%sel`'s value reach a rotation's arg-1 ANGLE
// slot through value-preserving carriers? A NEW forward worklist walk: no
// existing helper walks FORWARD from a value to a rotation arg-1
// (`taintedAngleGate` walks arm spines backward; `condProvenance` walks operands
// backward; `findNonDiagonalWireGate` follows arg-0 handle wires). It reuses the
// carrier-set pattern from `WireWalk.cpp:105-113` (PHI/SelectInst value-operand
// routing) and the per-use arg-1 angle predicate from
// `TaintPropagation.cpp:300-303` (`getArgOperand(1)==V && getArgOperand(0)!=V`).
//
// The carriers are exactly the VALUE-PRESERVING subset of the ops
// `declineTaintEscapes` WHITELISTS as benign tainted-value users
// (`isa<CastInst>`/`PHINode`/`SelectInst`, plus — as of Phase-7.1 Increment B —
// `FreezeInst`): `fpext`/`fptrunc`/`bitcast` (value-preserving casts) + nested
// `select`/`phi` + `freeze`. This set need not — and must not — be larger:
//   * `freeze` is a VALUE-PRESERVING carrier (freeze of an already-defined value
//     is identity). Phase-7.1 Increment B makes `declineTaintEscapes` SKIP an
//     FP-typed tainted `freeze` (the integer case is folded as a basis identity)
//     so an `(q>5)?θa:θb`-style angle routed THROUGH a `freeze` no longer hits
//     the blunt kMsgOther backstop — it must reach a rotation arg-1 here and be
//     declined `rotation angle`. Hence the walk MUST cross `freeze`
//     (control_swap_reject_select_freeze.ll, now flipped to the GATE-3 brand,
//     pins exactly this). Omitting it would re-open the FP-angle leak the escape
//     guard no longer catches — a silent miscompile, not dead code. (This
//     supersedes the pre-7.1 "adding `isa<FreezeInst>` would be untestable dead
//     code" note, which was true only while the escape guard still declined every
//     freeze at kMsgOther.)
//   * a value-CHANGING op (arithmetic, an int<->fp domain cast `sitofp`/…) RE-
//     REALIZES the value into a NEW tainted SSA value, which `declineTaintedAngle`
//     (`taint.Tainted.count(arg1)`) catches when it lands in a rotation arg-1 —
//     so those are correctly NOT crossed (crossing them would only change a loud
//     WI-3 decline's string, never prevent a miscompile).
// A nested `select`/`phi` carries `%sel` onward only as a VALUE operand, never as
// the condition (the `CompareLowering.cpp:54-56` discriminator).
//
// The FAN-OUT rule (PRD §16.2): a single arg-1 reach declines the WHOLE select.
// `%sel` may be tainted-as-data AND feed an arg-1 angle at once (the arg-1
// exclusion is per-operand-use, not global), but splitting — merge for the data
// uses, rotate for the angle use — double-realizes the value (a silent
// miscompile). So ANY reach returns true; never split.
//
// ⚠ THE NAME NOW UNDER-DESCRIBES IT (bd test_C_libtooling-3qlq Inc 1). The
// register-free BRANCH PHASE `void @cq_phi(double)` carries its angle at arg
// **0**, because it has no register operand at all. It is renamed nothing and
// kept as one walk deliberately: the question this predicate asks is "does the
// select's value reach an ANGLE SLOT", and there are now two slot spellings for
// it. Missing the arg-0 one is not a decline — it is a MISS: gate 3 would not
// fire, the select would fall through to the data/mux gates, and the P2 accept
// (PRD §6.2) would be unreachable while the shape declined later, in
// `deleteGlobalPhases`, with a message about an angle nobody claimed (MEASURED
// before this clause: `cq rotation lowering: unsupported quantum-derived
// rotation angle`, in the wrong function).
bool selReachesRotationArg1(SelectInst *Sel, const TaintSet &taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Sel);
  Visited.insert(Sel);
  while (!Work.empty()) {
    Value *U = Work.pop_back_val();
    for (User *X : U->users()) {
      // arg-1 angle reach — the per-use predicate (the angle operand of a
      // cq_phi/cq_theta is classical; a value reaching it as data is the
      // f64/angle miscompile family).
      if (auto *CI = dyn_cast<CallInst>(X)) {
        if (isRotationCall(CI) && CI->arg_size() >= 2 &&
            CI->getArgOperand(1) == U && CI->getArgOperand(0) != U)
          return true;  // angle — decline the WHOLE select (fan-out rule).
        // ...and the register-free branch phase's arg-0 angle slot. EXACT
        // membership (`isRegisterFreePhaseCall`), never a name test.
        if (isRegisterFreePhaseCall(CI, taint) && CI->arg_size() == 1 &&
            CI->getArgOperand(0) == U)
          return true;
      }

      // value-preserving carriers only (do NOT cross arithmetic/compare).
      // `freeze` is value-preserving (Phase-7.1 Increment B); the escape guard no
      // longer backstops an FP-routed angle through it, so this walk must cross it.
      if (isa<FPExtInst>(X) || isa<FPTruncInst>(X) || isa<BitCastInst>(X) ||
          isa<FreezeInst>(X) || isa<PHINode>(X)) {
        if (Visited.insert(X).second)
          Work.push_back(X);
      } else if (auto *Inner = dyn_cast<SelectInst>(X)) {
        // a nested select carries U onward only as a VALUE operand (true/false),
        // not as the condition — a condition use is not a value-routing edge.
        if (U != Inner->getCondition() && Visited.insert(Inner).second)
          Work.push_back(Inner);
      }
    }
  }
  return false;
}

// GATE 5 (the §16.7 PHASE-CARRIER half — the WI-3 Rule-13 dephasing finding) — is
// the tainted value `Op` ITSELF a relative-phase (Rz) carrier? The controlled-XOR
// copy merge is a CNOT basis copy: it copies a basis LABEL, not a phase (Rule 7),
// so an operand whose backward lineage includes a `cq_phi` (Rz) — a non-basis,
// COMPLEX-phase superposition — is DEPHASED into a wrong %out (the 0.585->0.500
// family; verify-clean-invisible — the adversarial review's confirmed blocker). A
// `cq_theta` (Ry) result is a REAL-amplitude basis superposition (no relative
// phase) and IS the canonical accept, so the backward walk STOPS at theta (its
// operands are the classical seed + angle, untainted). Walks every tainted
// producer backward (the cq_phi arg-0 wire + arithmetic/cast data inputs);
// over-decline-safe (any phi in the lineage declines the whole select).
//
// This is the BACKWARD twin of `hasCoherentDownstreamUse` (which catches an
// operand whose lineage FEEDS a downstream rotation — channel B). Together they
// enforce the §16.7 "decline coherent operands" intent that the forward-only
// proxy alone missed. See [[select-merge-phase-operand-dephasing]].
//
// CROSS-MODULE INVARIANT (WI-5 Rule-13 clearance, the one non-material residual):
// the walk only recurses through `taint.Tainted` operands, so a `cq_phi` on a
// CLASSICAL operand (untainted result) is correctly NOT flagged — it carries no
// real relative phase because `RotationLowering` deletes a classical-operand
// `cq_phi` (Rz on a basis state is unobservable; Rule 3). If classical-`cq_phi`
// handling ever changes (its result becomes tainted, or it stops being deleted),
// this gate must be re-reviewed — a classical phase reaching the basis copy would
// otherwise leak. Holds at HEAD; flagged here per the §8.3 second-review note.
// Op's ROTATION ANCESTRY: Op itself plus the backward rotation-arg-0 chain —
// the in-place gates that PRODUCE Op's record (a chained `cq_theta`/`cq_phi`
// result denotes a record on its parent's physical wire; rotation lowering
// RAUWs the whole chain to ONE handle). Mirrors WireWalk's per-seed backward
// closure + on-ancestry exemption (WireWalk.h): the producing rotations
// precede the record and can never dephase/stale it, so gate 5 exempts them —
// flagging them would over-decline every chained-prep consumer.
void rotationAncestry(Value *Op, SmallPtrSetImpl<Value *> &A) {
  for (Value *V = Op;;) {
    A.insert(V);
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || !isRotationCall(CI) || CI->arg_size() < 1)
      break;  // the wire origin (template result / argument / classical seed).
    V = CI->getArgOperand(0);
  }
}

// E2 fence (kjd1 post-fix refute-default round; FP_SELECT_CLEARANCE.md
// addendum): does the tainted operand's backward lineage contain a
// FreezeInst? A tainted fp `freeze` survives the escape guard (7.1 Inc B
// skips it; the integer case is folded, the fp case is NOT) yet is
// UN-LAUNDERABLE by the emitter: rotation lowering later RAUWs the frozen
// theta result to its i32 handle, leaving `freeze double %h` ill-typed, and
// `opt` ABORTS on the broken module (SIGABRT — a crash on valid input, not a
// loud decline; Rule 1). Newly fp-reachable through the gate-4 un-staging
// (pre-kjd1 every fp select declined at the type gate). Over-decline-safe and
// type-agnostic (the sub-i32 integer widths have the same RAUW shape).
bool taintedLineageHasFreeze(Value *Op, const TaintSet &Taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (isa<FreezeInst>(V))
      return true;  // un-launderable under the RAUW-to-handle discipline.
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// ⚠ VACUOUS SINCE `main` a3c1513 (bd test_C_libtooling-3qlq Inc 1), MEASURED —
// and KEPT, per the predicate note above. Both `return true` sites below are
// `isPhiCall`, which tests the prefix `"cq_phi_"` that no shipped call carries
// (the register form is retired; `CQ.h` declares `void cq_phi(double)`), so this
// function now always returns false and gate 5's PHASE half has no subject.
// Recorded by the Inc-2 Rule-13 round-2 review as F-I2-4.
//
// WHY THAT IS SAFE — the guarded class is structurally gone, not merely
// unrepresented. The WI-3 hazard was "a select OPERAND whose backward lineage
// contains an Rz, CNOT-copied by the merge, which copies a basis LABEL and not a
// phase". A branch phase has NO REGISTER OPERAND (owner decision D1), so no
// value can have a `cq_phi` in its lineage at all; and an uncontrolled or
// classically-controlled one is DELETED as a global phase (D2).
//
// The successor shape — a register carrying relative phases IMPARTED by a
// kickback (`if (c(q)) cq_phi(θ)` leaves `q` in `Σ_x a_x e^{iθ[c(x)]}|x⟩`) — is
// NOT this hazard, and the round-2 review measured it: `q1k_disjoint_phase_then_value`
// (a kickback region followed by a value merge) ACCEPTS and is BYTE-IDENTICAL to
// its pre-hoisted select twin (finding F-I2-5). The argument is linearity — the
// merge is a permutation into a FRESH |0⟩ ancilla, so amplitudes AND relative
// phases ride the branch they belong to; a basis copy loses a phase only when the
// phase sits BETWEEN two branches carrying the SAME label, which a per-branch
// kickback never produces.
//
// So: do not delete this (freeze-time dead-code list), and do not RE-ARM it by
// teaching `isPhiCall` the new spelling — see the predicate note above for why
// that would read the wrong operand.
bool operandCarriesPhase(Value *Op, const TaintSet &Taint) {
  // WIRE-ANCHORED since the kjd1 Rule-13 implementation clearance (coherence-
  // lens blocker; FP_SELECT_CLEARANCE.md): the original walk was SSA-anchored
  // (backward through tainted OPERANDS only), so a `cq_phi` hanging off a
  // SIBLING SSA alias of the same physical wire — reachable after a chained
  // cq_theta rebased the wire onto a new SSA name — was invisible, and the
  // merge CNOT-copied a phased wire (the WI-3 dephasing family, verify-clean;
  // pinned by control_swap_reject_select_{fp_,}phase_sibling_alias*.ll). The
  // fix adds FORWARD WIRE EDGES: for each visited value V, a rotation-call
  // user r with r.arg0 == V continues V's physical wire (post-lowering RAUW
  // collapses the chain to one handle), so a phi user ANYWHERE on the wire —
  // ancestor or sibling, before or after the select (phase before the copy
  // dephases the copy; phase after is channel-B coherence) — declines.
  // Sibling thetas are WALKED (their users may hang phis); flagging an
  // OFF-ancestry theta itself (interference) is hasCoherentDownstreamUse's
  // job below.
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (isPhiCall(V))
      return true;  // an Rz (cq_phi) in the lineage — a relative-phase carrier.
    // forward wire edges: rotation users of V share V's physical register.
    for (User *U : V->users())
      if (auto *CI = dyn_cast<CallInst>(U))
        if (isRotationCall(CI) && CI->arg_size() >= 1 &&
            CI->getArgOperand(0) == V) {
          if (isPhiCall(CI))
            return true;  // sibling Rz — phase on the operand's wire.
          if (Visited.insert(CI).second)
            Work.push_back(CI);  // sibling/chained theta: the wire continues.
        }
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // an argument / constant root — basis, not a phase.
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// GATE 5 (the §16.7 conservative coherent-operand default, decidable v1 proxy) —
// does a tainted value `Op` have a QUANTUM use beyond this select: a downstream
// rotation (`cq_phi`/`cq_theta`) ON its wire (arg-0) whose interference would
// observe its coherence (the channel-B dephasing case)? Reads by the condition
// `icmp`, the select's own copy, a downstream `cq_measure`, or `ret` do NOT count
// (those are owned by the mint / select / measurement / caller — the §16.5
// operand-disposition matrix). A forward value walk: arithmetic/cast carriers are
// crossed (the operand's coherence is preserved through them) so a downstream
// rotation on a derived value is still caught; the arg-1 angle use is gate 3's
// domain, not gate 5's. Conservative (over-decline-safe) and accepts §15's
// canonical `(q>5)?q:x` / `(q>5)?q:q+1`; the exact coherent-vs-basis boundary is
// the binding Rule-13 clearance item (§8) — re-pin here if it moves.
bool hasCoherentDownstreamUse(Value *Op, SelectInst *Sel, TaintSet &Taint) {
  Value *Cond = Sel->getCondition();
  // The downstream-measurement allowlist is EXACT-MEMBERSHIP against
  // `Taint.MeasureCalls` (the recognized `@cq_measure_<sfx>` call sites), NOT the
  // old `starts_with("cq_measure_") || starts_with("cqrt_measure_")` prefix match
  // — mirrors `proveSwitchDataMux`'s sink test and the G10 scrutinee allowlist
  // (SwitchClassify.cpp). Prefix-on-accept is spoofable: an opaque `cq_measure_evil`
  // would confer false ownership of a live rail. For the `cq_measure_` family the
  // check is EQUIVALENT on reachable inputs: `Op` is ALWAYS tainted (the caller
  // gates on `taint.Tainted.count(Op)`), so `declineTaintEscapes` (L64, pre-
  // detection) has already rejected any unknown-callee `cq_measure_evil`. It is
  // STRICTLY STRICTER on the dropped `cqrt_measure_` arm (whitelisted by the escape
  // guard, so a hand-authored runtime-symbol measure reaches here) — the SAFE
  // over-decline direction; the frontend never emits `cqrt_measure_` pre-detection.
  // Consistency + defense-in-depth (Rule 14).
  SmallPtrSet<const CallInst *, 8> Sinks(Taint.MeasureCalls.begin(),
                                         Taint.MeasureCalls.end());
  // Rotation-ancestry exemption + LINEAGE-WIDE seeding (both kjd1 Rule-13
  // implementation clearance findings; FP_SELECT_CLEARANCE.md). Seeding: the
  // original walk started at Op alone, so a rotation (or a rotation on a
  // derived value) hanging off an ANCESTOR SSA alias of Op's wire — sibling
  // branches created by the chained-theta rebase — was invisible
  // (control_swap_reject_select_fp_theta_fork.ll). The walk now seeds from
  // Op's whole backward tainted lineage (the same closure operandCarriesPhase
  // visits), so every sibling branch of every ancestor is scanned. Exemption:
  // a rotation user that IS on Op's own producer chain (`rotationAncestry`)
  // precedes the record and cannot observe the copy — it is walked THROUGH,
  // not flagged, keeping the sanctioned chained-prep accept
  // (`select(c, theta(theta(q)), x)`).
  //
  // ⚠ THAT LAST CLAUSE IS EXACT ONLY WHEN `Op` **IS** THE ROTATION CALL, and the
  // sentence above is what a future reader would use to decide this gate is
  // exact, so read this first (bd test_C_libtooling-3qlq Inc 2, Rule-13 round-2
  // finding F-I2-2). `rotationAncestry` is seeded AT `Op` and stops immediately
  // unless `Op` is itself a rotation call — so for a DERIVED operand (the result
  // of `theta(q)` plus one arithmetic hop) `Ancestry` is the singleton `{Op}`,
  // the exemption is EMPTY, and the LINEAGE-WIDE seeding above then reaches the
  // base's own producing theta and flags it as "off-ancestry". MEASURED on all
  // three binaries (pre-3qlq oracle 52d7764, `main` a3c1513, branch
  // `3qlq-inc2`): `p = cq_theta(p,0.9)` before a 6-op arm ACCEPTS as a `br`
  // diamond and DECLINES `control flow` as the pre-hoisted select, while the
  // UNCHAINED spelling accepts both ways.
  //
  // It is a SEEDING ARTIFACT, not a proven hazard, and the round-2 review could
  // not construct a counterexample: the merge is two controlled-XOR copies into a
  // FRESH |0⟩ ancilla with the flag minted and stripped by an exact inverse pair
  // — a PERMUTATION, hence linear, hence correct for an arbitrary input
  // superposition. The genuine hazard this seeding was built for (the kjd1 fork,
  // `int a = p; int p1 = cq_theta(p,·); if (c) a = R(a);`) is caught on the `br`
  // path by the pass-wide `declineStaleRecordOps` — `cq opcode lowering: operand
  // predates a non-diagonal gate`, measured on all three binaries in all three
  // orderings. So this gate is CONSERVATIVE, as §16.7 says, and widening the
  // seeding is an OWNER item (a Rule-13-core accept-class change needing its own
  // red-green and lens), not a bug to fix in passing.
  SmallPtrSet<Value *, 8> Ancestry;
  rotationAncestry(Op, Ancestry);
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  // backward tainted lineage as additional seeds (data inputs + wire parents).
  {
    SmallVector<Value *, 8> Back;
    Back.push_back(Op);
    while (!Back.empty()) {
      auto *I = dyn_cast<Instruction>(Back.pop_back_val());
      if (!I)
        continue;
      for (Value *In : I->operands())
        if (Taint.Tainted.count(In) && Visited.insert(In).second) {
          Work.push_back(In);
          Back.push_back(In);
        }
    }
  }
  while (!Work.empty()) {
    Value *U = Work.pop_back_val();
    for (User *X : U->users()) {
      if (X == Sel || X == Cond)
        continue;  // the select's own copy / the flag mint — owned.
      if (auto *CI = dyn_cast<CallInst>(X)) {
        if (Sinks.count(CI))
          continue;  // a recognized measurement sink owns the handle.
        if (isRotationCall(CI)) {
          if (CI->arg_size() >= 1 && CI->getArgOperand(0) == U) {
            if (!Ancestry.count(CI))
              return true;  // a rotation ON a wire of the lineage — coherent.
            if (Visited.insert(CI).second)
              Work.push_back(CI);  // Op's own producer — exempt, walk through.
          }
          continue;  // arg-1 angle use is gate 3's domain, not coherence here.
        }
        // Any other surviving call: `declineTaintEscapes` (pre-detection)
        // declined unknown callees, so what survives is a CURATED producer
        // (libm / curated intrinsic / by-ref marker) whose result CONTINUES
        // the coherence lineage exactly like an arithmetic instruction — walk
        // its result (kjd1 clearance, angle-fence-lens major: the old bare
        // `continue` let `cbrt(%q)`'s result take a downstream Rz unseen —
        // control_swap_reject_select_fp_coherent_call_derived.ll). A void
        // result has no users; the push is then a no-op.
        if (Visited.insert(CI).second)
          Work.push_back(CI);
        continue;
      }
      if (isa<ReturnInst>(X))
        continue;  // escapes via ret — the caller owns the handle.
      // value carrier / arithmetic — keep walking forward to find a rotation.
      if (auto *I = dyn_cast<Instruction>(X))
        if (Visited.insert(I).second)
          Work.push_back(I);
    }
  }
  return false;
}

// GATE 6 (the §16.9 aliasing guard, conservative form) — do the two value
// operands resolve to the SAME post-lowering register? The dangerous alias is
// literal only AFTER rotation lowering RAUWs a `%qd = cq_phi(%q,·)` and its `%q`
// to one i32 handle, which pre-mutation SSA cannot see — so materialize `A`'s
// pre-region `cq_phi` arg-0 diagonal-alias closure and test `B` against it via
// `diagonalAliasHit` (which walks `B`'s own `cq_phi` arg-0 chain). A `Constant`
// operand never aliases a handle. A fresh out-of-place template result (`q+1` → a
// new `cq_template_add` handle distinct from `q`) has a disjoint closure →
// `(q>5)?q:q+1` accepts; the hoisted-in-place family (two `cq_phi`s of one base)
// intersects → decline.
// ⚠ ITS CLOSURE IS VACUOUS SINCE `main` a3c1513 (bd test_C_libtooling-3qlq
// Inc 1), MEASURED — and KEPT, per the predicate note above. The loop below
// extends `Closure` only through `isPhiCall` arg-0 links, and `diagonalAliasHit`
// (`ArmClassify.cpp`) walks `B`'s own `cq_phi` arg-0 chain; neither prefix
// matches any shipped call, so `Closure` degenerates to `{A}` and the whole gate
// degenerates to POINTER EQUALITY `A == B`. Recorded by the Inc-2 Rule-13
// round-2 review as F-I2-4.
//
// WHY THAT IS SAFE. The alias this closure was built for is "two `cq_phi`s of one
// base, RAUW'd to ONE i32 handle by rotation lowering" — a spelling that no
// longer exists (D1: `cq_phi` carries no register). The nearest LIVE analogue is
// the `cq_theta`-shaped alias, and it does not reach this gate: MEASURED on all
// three binaries (pre-3qlq oracle 52d7764, `main` a3c1513, this branch),
// `int t = cq_theta(q,0.9); p = (q>5) ? t : q;` DECLINES
// `cq controlled lowering: condition predates a non-diagonal gate under quantum
// control` at gate 2c — earlier than here, and identically before and after
// Inc 1/Inc 2 (round-2 review F-I2-4; re-measured by `fix_inc2_r2`, reproducer
// `$SP/progress/fix_inc2_r2_work/p/g6_theta_alias.c`). ANALYTIC, not measured
// (2c fires first, so the shape cannot be observed past it): a theta alias that
// survived 2c would be refused by gate 5's channel-B walk, which is NOT vacuous —
// asked of the `q` operand, `rotationAncestry(q)` is `{q, seed}` while the
// sibling `t = cq_theta(q,·)` is a rotation user of `q` OUTSIDE it, so
// `hasCoherentDownstreamUse` returns true.
//
// Read this as a gate whose subject was retired, not as a gate that was proven
// unnecessary: if a register-carrying diagonal rotation is ever reintroduced, the
// closure must be re-armed against ITS spelling, exactly as written here.
bool operandsAlias(Value *A, Value *B) {
  if (isa<Constant>(A) || isa<Constant>(B))
    return false;  // a classical literal never aliases a quantum handle.
  SmallPtrSet<Value *, 8> Closure;
  for (Value *V = A;;) {
    Closure.insert(V);
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || !isPhiCall(CI) || CI->arg_size() < 1)
      break;  // the wire origin (theta source / template result / argument).
    V = CI->getArgOperand(0);
  }
  return diagonalAliasHit(B, Closure) != nullptr;  // shared physical wire.
}

}  // namespace

// bd `boi6` (D-B) / Track M — RUNG 0 OF THE MERGE-φ LADDER, AND THE WHOLE PROOF.
// The region that will turn `P` into a single physical register, or null.
//
// ⚠ bd `3qps` / bd `4aiu` (Track P) — THIS LEFT THE ANONYMOUS NAMESPACE SO IT
// COULD STAY THE *ONE* SPELLING WHEN THE SECOND CONSUMER ARRIVED. The PHASE
// kickback (`ArmClassify::classifyPhaseKickback` step 5c) asks the identical
// question about the identical object; giving it a private copy is precisely the
// drbq Inc-3 (b′) defect (Rule 14 — a second spelling of a predicate the tree
// already owned). It is declared in `SelectClassify.h` beside
// `isCondRailPhiShape`, whose syntactic half it completes, and it is asked by
// CALLING it — never by re-deriving its conjuncts at a consumer.
//
// THIS FUNCTION RE-DERIVES NOTHING (Rule 14; the drbq Inc-3 (b′) defect was a
// SECOND SPELLING of a predicate the tree already owned). `ArmClassify`'s
// `classifyArms` is the ONE OWNER of "what this merge φ becomes": at its accept
// it COMMITS `ClassArm`/`ClassArmFalse = ArmClass::InPlaceRotation`, the single
// hoisted `cq_theta` in `Shadow`/`ShadowFalse`. We ask by reading exactly those
// fields, by SSA-value identity, with no walk of our own.
//
// WHY EACH CONJUNCT IS THERE (each one is the fence for a §4 decline row):
//   * `Kind == BranchRegion` — only a `br` diamond has a merge φ at all; a
//     `SelectRegion` sets no `Merge` φ, a `SwitchRegion`/kickback nest has a
//     different merge story.
//   * `Merge == P` — POINTER IDENTITY with the select's own condition. This is
//     what refuses a φ over two DISTINCT rails (probe `m29`: no single region's
//     `Merge` is that φ) and a φ whose region was never claimed at all (probe
//     `m20`/boi6 `p5`: its diamond declines, so it is in no plan).
//   * the arm class — `InPlaceRotation` is BOTH the controlled in-place Ry arm
//     and the controlled STATE PREP (`ControlPlan.h`: `ArmClass` has no separate
//     `StatePrep`; the two share the class and the emitter). A `Value` arm's
//     merge is a DATA MUX whose φ names no register — refused here, and bd
//     `fg9k` is the increment that would widen it. A 6.5/4.5 `%out` rail is
//     refused by the same conjunct (its producer is a `cqrt_alloc` handle, never
//     a theta, and no region commits it as an `InPlaceRotation` `Merge`).
//   * the arm's own `Shadow`/`ShadowFalse` NON-EMPTY, paired with the class that
//     owns it by FIELD identity (`ControlPlan.h`: `Shadow` is `Arm`'s content,
//     `ShadowFalse` is `ArmFalse`'s — by field, NOT by edge truth, since
//     `ArmNegated` carries the Rule-9 polarity). The hoisted theta is what M-β
//     will RAUW `P` to, so an empty content list means there is no register.
//
// ⚠ WHAT IS DELIBERATELY **NOT** A CONJUNCT, AND WHY — `RailLadderProven`.
// The first cut of this predicate also required it, on a "defence in depth"
// reading of `ControlPlan.h`'s caller-independent backstop. That was WRONG, and
// measuring it is what showed the mistake (orchestrator ruling, 2026-09-13):
// `classifyArms` sets that flag ONLY when the REGION'S OWN condition is a bare
// rail, so the conjunct silently refused every prep guarded by a COMPARE —
// `int b0 = cq_theta(0,.5); bool b1 = 0; if (b0 == 1) b1 = cq_theta(b1,.5);
// if (b1) a -= 3;`, a single-φ merge that never peels and so never meets F2
// (bd `rb9x`). MEASURED: that program reached rung 0 and was refused by this
// conjunct ALONE.
//
// The flag answers "did the RAIL ladder run for this region?", and that is not
// the question the select needs answered. What the select needs is "will this φ
// become ONE physical register?", which is exactly what the `InPlaceRotation`
// class verdict means — its emitter is the one that hoists the arm's theta and
// RAUWs the φ to it (M-β). A COMPARE-conditioned region reached that same
// verdict through `condWireDisposition`'s ladder instead; **whichever ladder
// proved it, the committed verdict is identical**, and the select re-asks its
// OWN rungs (i)/(ii)/(iii) on the φ regardless. Requiring the rail spelling of
// the proof was a claim about HOW the region was proved, not about WHAT was
// proved — and an over-decline of a valid circuit is a defect, not a margin
// (owner ruling 2026-09-11). Accept:
// `control_swap_accept_select_mergephi_cmp_cond_region.ll`; the class conjunct
// still fires on any OTHER claimed class
// (`control_swap_reject_select_mergephi_other_class.ll`).
//
// ⚠ ORDER, AND IT IS PROVEN NOT ASSUMED. `detectControlRegions` walks each block
// TERMINATOR FIRST (`handleBranchRegion`) and only then that block's `select`s,
// and the diamond's `br` lives in `Pred` while the select lives in the MERGE
// block — so by the time a merge-block select is classified, its region's verdict
// is already in `plan.Regions`. If that ever stops holding the outcome is a LOUD
// DECLINE, never a miscompile: this lookup simply finds no region and gate 2
// fires `control flow`. No assertion, by design (Release builds have assertions
// off and Release is what every gate here runs).
// Returns the region's INDEX in `plan.Regions`, or `ControlRegion::kNoParent`.
// An index rather than a pointer because the caller must RECORD it
// (`ControlRegion::PrepRegionIdx`) for `lowerControlRegions`' precedence edge —
// round-1 finding F-M1 — and the list is a `SmallVector` that reallocates.
unsigned preppedRailPhiRegionIdx(const PHINode *P, const ControlPlan &plan) {
  for (unsigned i = 0, e = plan.Regions.size(); i != e; ++i) {
    const ControlRegion &R = plan.Regions[i];
    if (R.Kind != ControlRegion::BranchRegion || R.Merge != P)
      continue;
    const bool TrueArm =
        R.ClassArm == ArmClass::InPlaceRotation && !R.Shadow.empty();
    const bool FalseArm =
        R.ClassArmFalse == ArmClass::InPlaceRotation && !R.ShadowFalse.empty();
    if (TrueArm || FalseArm)
      return i;
  }
  return ControlRegion::kNoParent;
}

// 3c6m.12 (L4) — the shared condition-tree walk (see SelectClassify.h). An
// explicit two-phase stack (a (value, childrenDone) pair) yields left-to-right
// post-order without recursion; `Seen` both dedupes SHARED subtrees (a leaf or
// node reachable from two tree positions collects ONCE — its flag/ancilla
// mints once, network controls are read-only) and bounds the walk (SSA is
// acyclic through pure i1 ops — no phi is ever crossed).
bool decomposeCondNode(Value *V, Instruction::BinaryOps &Opc, Value *&L,
                       Value *&R, bool AllowLogicalSelect) {
  // See SelectClassify.h for the grammar and for WHY the two logical-select
  // spellings are gated. This is the ONE place a node is taken apart: the walk
  // below and every `CondTree` emitter (`CondTreeEmit`) call it, so a node kind
  // cannot be admitted by the grammar and mis-read by an emitter (the bd
  // 3c6m.67 xor lesson — one grammar, and every emitter that reads it).
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (!BO->getType()->isIntegerTy(1))
      return false;
    const auto Op = BO->getOpcode();
    if (Op != Instruction::And && Op != Instruction::Or &&
        Op != Instruction::Xor)
      return false;
    Opc = Op;
    L = BO->getOperand(0);
    R = BO->getOperand(1);
    return true;
  }
  if (!AllowLogicalSelect)
    return false;  // off-grammar for this caller — see the header.
  auto *Sel = dyn_cast<SelectInst>(V);
  if (!Sel || !Sel->getType()->isIntegerTy(1))
    return false;
  Value *C = Sel->getCondition();
  Value *T = Sel->getTrueValue();
  Value *F = Sel->getFalseValue();
  // `select %C, %T, false` is `and(C,T)`; `select %C, true, %F` is `or(C,F)`.
  // A NON-constant condition and a NON-constant surviving arm are REQUIRED: the
  // network gives each child its own flag rail, so a `ConstantInt` child has no
  // rail and the emitter's `FlagOf.lookup` would hand a null control to a
  // `cqrt_toffoli`. Refusing here is the same fence the `xor X, 1` bail is.
  if (isa<Constant>(C))
    return false;
  if (auto *FC = dyn_cast<ConstantInt>(F); FC && FC->isZero() &&
                                           !isa<Constant>(T)) {
    Opc = Instruction::And;
    L = C;
    R = T;
    return true;
  }
  if (auto *TC = dyn_cast<ConstantInt>(T); TC && TC->isOne() &&
                                           !isa<Constant>(F)) {
    Opc = Instruction::Or;
    L = C;
    R = F;
    return true;
  }
  // Everything else is a general i1 combinator (incl. the two NOT-carrying
  // complements `select %C, false, %F` and `select %C, %T, true`) — off-grammar.
  return false;
}

bool isCondRailLeaf(const Value *V) {
  const auto *CI = dyn_cast_or_null<CallInst>(V);
  if (!CI || !CI->getType()->isIntegerTy(1))
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName() == "cq_theta_i1";
}

bool isCondRailPhiShape(const Value *V) {
  const auto *P = dyn_cast_or_null<PHINode>(V);
  return P && P->getType()->isIntegerTy(1) && P->getNumIncomingValues() == 2;
}

// bd `fn1q` increment 5a — `isCondRailPhiShape` REFINED to something a stage with
// NO `ControlPlan` can prove for itself.
//
// ⚠ WHY A SECOND PREDICATE RATHER THAN A WIDER FIRST ONE. `isCondRailPhiShape` is
// WEAK BY DESIGN — any 2-incoming `i1` φ — because its consumers finish the job
// with `preppedRailPhiRegionIdx`, which asks whether a CLAIMED state-prep region
// owns the φ. `PredMuxFlatten`'s E6 gate CANNOT ask that: PredMux runs at
// `CQLoweringPass.cpp:374/398/427` and `detectControlRegions` at `:582`, so no
// plan exists yet. And the obvious fallback — "is the φ's defining branch
// TAINTED?" — is REFUTED BY MEASUREMENT: the owner's own prep branch prints
// `condBr tainted=0` at that slot (its register is tainted only after the value
// region seeds it in round 2), so a taint test at E6 would refuse the very
// program this bead exists for.
//
// WHAT IS PROVABLE WITHOUT A PLAN AND WITHOUT TAINT: that every incoming is either
// a RAIL (`isCondRailLeaf` — a `cq_theta_i1` CALL, hence always tainted by Rule 3)
// or an `i1` CONSTANT (a known basis label on that edge). That is exactly the
// shape `promoteRailBankCells` manufactures for a `_Bool` bank cell — measured on
// the owner's program: `%cq.bank1 = phi i1 [ %31, %30 ], [ false, %23 ]`.
//
// ⚠ IT IS A NECESSARY CONDITION, NOT THE WHOLE PROOF, AND THAT IS DELIBERATE. A φ
// this admits may still be refused downstream by `preppedRailPhiRegionIdx` — a
// prep under a CLASSICAL condition is not a region at all, so it has no index.
// The VERDICT (decline) is preserved and no decline becomes silence.
// ⚠⚠ AND THAT SENTENCE WAS ITSELF MEASURED FALSE — Rule-13 ROUND 2 (R5aR2-1, P1).
// A DECLINE DID BECOME SILENCE: for a rail φ in a NON-ENTRY region block the flatten
// CONVERTS it by the select chain, `buildNegation`'s assertion-only
// `cast<ConstantInt>` returns a constant-FALSE predicate, the arm's cone is
// dead-swept, and the module compiled at exit 0 with 0 BYTES of stderr and a WRONG
// unitary where the oracle declined loudly. The placement conjunct at E6 is what
// makes the claim true again, and it was true only WITHIN ONE PASS until bd
// `test_C_libtooling-woa0` added the cross-claim RE-ASK
// (`declineConvertedRailPhiLeaves`). ⚠ THE CONJUNCT IS STILL POINT-IN-TIME —
// nothing here re-asks it — so do not read the re-ask as making this line
// total: what is total is the OUTCOME. Either this flatten does not convert
// the φ, or a later one does and the module declines LOUDLY at the re-ask
// instead of by `collectCondTree`'s accident. Say "the verdict is preserved",
// and if you need the mechanism say "because a conversion by a later flatten
// is OBSERVED and declined", never "because no later flatten converts it".
//
// ⚠ AN EARLIER DRAFT SAID "the SAME string and the SAME diagnostic", MEASURED ON
// ONE MODULE AT ONE POLARITY, AND THAT IS FALSE (Rule-13 round 1 F2): with a
// SECOND independent tainted region in the same function the string moves from
// `nested control flow` to `control flow`, because the flatten mutates the first
// region and the decline lands with a different owner. Rule 12 pins strings
// character-for-character, so say "verdict preserved", never "string preserved".
//
// What it costs besides is DETECT-BEFORE-MUTATE for that shape (the region is
// flattened first) — a real and filed cost, see the E6 call site.
bool isStructuralRailPhi(const Value *V) {
  const auto *P = dyn_cast_or_null<PHINode>(V);
  if (!isCondRailPhiShape(P))
    return false;
  for (const Value *In : P->incoming_values())
    if (!isCondRailLeaf(In) && !isa<ConstantInt>(In))
      return false;
  return true;
}

bool collectCondTree(Value *Root, CondTree &Tree, bool AllowLogicalSelect,
                     bool AllowRailPhi, function_ref<bool(Value *)> IsLiteral) {
  SmallPtrSet<Value *, 8> Seen;
  SmallVector<std::pair<Value *, bool>, 8> Stack;
  Stack.push_back({Root, false});
  while (!Stack.empty()) {
    auto [V, ChildrenDone] = Stack.pop_back_val();
    if (ChildrenDone) {
      Tree.Nodes.push_back(cast<Instruction>(V));  // post-order emit slot.
      continue;
    }
    if (!Seen.insert(V).second)
      continue;  // shared subtree — already collected once.
    // bd 3qlq.4 — a RAIL LEAF: the `_Bool` register itself as the condition, or
    // as a child of a logical node (`b && q == 5` → `select i1 %b, i1 %cmp,
    // i1 false`; `b == c` → `xor i1 %b, %c`). Disjoint from the compare test
    // below (a `CmpInst` is never a call). See the header's `RailLeaves` note
    // for the obligation this places on every consumer of the tree.
    if (isCondRailLeaf(V)) {
      Tree.RailLeaves.push_back(cast<CallInst>(V));
      continue;
    }
    // bd `boi6` (D-B) / Track M — A REGION-MERGE-φ RAIL LEAF. See the header for
    // why the test is weak (the proof is the classifier asking `plan.Regions`).
    // Disjoint from both tests around it: a `PHINode` is neither a `CallInst`
    // nor a `CmpInst`.
    //
    // bd `4aiu` (Track P) — THE `V == Root` CONJUNCT IS GONE: a φ is admitted at
    // ANY position of the `and`/`or`/`xor` tree, exactly like the `isCondRailLeaf`
    // rail leaf beside it (`b && q == 5` has been in-grammar for a RAIL since
    // 3qlq.4). Track M scoped it ROOT-ONLY because an interior φ had no probe
    // family and no measured emitter path; both now exist — the emitter path is
    // the SAME one an interior rail takes (`CondTreeEmit` maps the leaf to itself
    // and the node's `cqrt_toffoli` reads it as a read-only control), measured on
    // the ORACLE with the φ already RAUW'd (`trackP/probes/p18.ll`, 18 lines).
    // Every per-leaf gate below is already a LOOP over `RailPhiLeaves`, so an
    // interior φ is asked rung 0/(i)/(ii)/(iii) identically to a root one.
    if (AllowRailPhi && isCondRailPhiShape(V)) {
      Tree.RailPhiLeaves.push_back(cast<PHINode>(V));
      continue;
    }
    if (auto *Leaf = dyn_cast<CmpInst>(V)) {
      // NO ALIASED-OPERAND LEAF FENCE HERE, DELIBERATELY (bd big5, 2026-07-31 —
      // the revert of bd 7q3s / dd2c103). DO NOT RE-ADD ONE.
      //
      // A leaf whose two operands resolve to ONE post-lowering rail mints
      // `cq_template_icmp_slt_i32(i32 %h, i32 %h)` (+ its `_unc`). dd2c103
      // declined that on the premise that it is "an ill-formed physical gate no
      // backend can realize". THE PREMISE IS FALSE (owner ruling, same day):
      //
      //   CASE A — aliasing the INPUTS of an OUT-OF-PLACE gate whose output is a
      //   FRESH |0> rail. REALIZABLE, and the proof is a THEOREM rather than a
      //   list of lucky degeneracies: the generated ABI's out-of-place shape is
      //   `out(fresh |0>) ^= f(in0, in1)`, so aliasing the inputs gives
      //   `out ^= g(a)` with `g(a) := f(a,a)`, and `(a, 0) -> (a, g(a))` is the
      //   standard reversible embedding of a classical function — self-inverse
      //   and unitary for ANY `g`. Degeneracy only changes COST, never
      //   realizability. Cheap: `icmp_eq/sle/sge(a,a)` is constant TRUE (one X on
      //   the flag rail), `icmp_slt/sgt/ne(a,a)` is constant FALSE (nothing at
      //   all). Genuinely unary: `fcmp uno(a,a)` IS `isnan(a)`, every ORDERED
      //   fcmp on aliased operands is `!isnan(a)` or constant FALSE, `fmul(a,a)`
      //   is squaring. DO NOT write `fsub(a,a) == 0` or `fdiv(a,a) == 1` — both
      //   are NaN on inf/NaN (and `fdiv` also on ±0), which is precisely what
      //   tests/e2e/slice_libm_real_acos.c:98 `(x-x)/(x-x)` RELIES on; a backend
      //   implementing them as constants would turn acos(2.0) from NaN into 1.0.
      //   The generic fallback for a non-degenerate `g` is the copy sandwich:
      //   CNOT×W copy, gate, EXACT uncopy (the copy rail is a deterministic
      //   function of a source that STAYS LIVE), free at a provable |0>. Rule 8
      //   is untouched — it forbids freeing a SOURCE by copy+uncompute, not a
      //   COPY. So this is a PHASE-9 BACKEND OBLIGATION, not a compiler defect.
      //
      //   CASE B — an input aliasing a rail the gate WRITES (`cqrt_cnot(c,c)`
      //   erases; `cqrt_cswap(c,c,b)` is not unitary) is genuinely unrealizable.
      //   A compare leaf can never be Case B: its forward mint is an
      //   unconditional `CreateCall(Callee, {Lhs, Rhs}, "h_cmp")`
      //   (CompareLowering.cpp:262), so the flag rail is a NEW value whatever
      //   the operands are, and the `_unc` strip writes that same flag rail
      //   while reading the operands. Fence Case B where it can actually arise,
      //   not here. (A 2026-07-31 adversarial round checked the whole pass for
      //   Case B and found none EMITTED, at any mint site.)
      //
      // THE CONSISTENCY ARGUMENT, STATED AS MEASURED. 118 of 226 committed e2e
      // goldens already ship an aliased-operand forward template call —
      // slice_libm_real_acos.c:102 `z = x*x` -> `cq_template_fmul_f64(h0, h0)`.
      // Those goldens were GREEN WITH THE FENCE IN, because this walk inspects a
      // select CONDITION tree and never an arithmetic instruction. So the fence
      // did not CONTRADICT them — it was INCONSISTENT with them: the DATA path
      // has always emitted aliased Case-A mints unfenced, so the compiler already
      // depends on Case A being realizable, and fencing the CONDITION path
      // contradicted a premise the tree relies on. DO NOT restate this as "the
      // fence would have condemned 118 goldens", and DO NOT generalize it into
      // "if a fence would condemn a golden the fence is wrong" — this project
      // routinely accepts a shape as data and declines it under control (kjd1
      // accepts fp at the select and declines it at every non-select consumer).
      //
      // SOUNDNESS, not just realizability: the alias here is created by a
      // DIAGONAL gate (Rz), so both SSA names denote the same BASIS LABEL and
      // collapsing `icmp(a,a)` is the CORRECT answer. The NON-diagonal twin
      // (`r = cq_theta(q,·)`, an in-place Ry that also RAUWs to one rail but
      // CHANGES the basis) must NOT lower, and does not — it is owned by
      // ArmClassify's gate 2c (`findNonDiagonalWireGate`) and pinned by
      // control_swap_reject_select_theta_alias_cond.ll. That pairing is the
      // invariant; read the two fixtures together.
      //
      // Pinned by control_swap_accept_select_rail_alias_cond.ll (canonical, with
      // the measured per-site fence-coverage matrix),
      // control_swap_accept_select_aliased_leaf.ll, and
      // control_swap_accept_select_and_aliased_leaf.ll (the aliased leaf composed
      // with an `and i1` NODE — two leaves over one source rail still mint two
      // DISTINCT flag rails, which is what makes the retained node fence's
      // rationale below true).
      Tree.Leaves.push_back(Leaf);
      continue;
    }
    Instruction::BinaryOps NodeOpc;
    Value *NodeL = nullptr;
    Value *NodeR = nullptr;
    if (!decomposeCondNode(V, NodeOpc, NodeL, NodeR, AllowLogicalSelect))
      return false;  // off-grammar: freeze / i1-select / phi / trunc / …
    // *** XOR NODE — ADMITTED 2026-08-23 (bd 3c6m.67). ***
    //
    // This line used to read `!= And && != Or` with the bail commented
    // "off-grammar: xor / freeze / …", and NO RATIONALE FOR EXCLUDING XOR WAS
    // EVER RECORDED — one clause in an enumeration, in a function that argues
    // its other two fences at 25 and 20 lines apiece (bd big5). It read as an
    // ABSENCE OF A DECISION, not a decision against xor: the grammar was built
    // for 3c6m.12 "compound-condition select", i.e. exactly the &&/|| that C
    // short-circuit produces, and PredMux upstream normalizes NOT away by De
    // Morgan, so no two-operand xor was ever on the input distribution that
    // shaped it. (That inference is LABELLED as inference — nobody wrote a
    // reason down, and this comment must not be quoted as though they had.)
    //
    // NOTHING ABOUT THE CONSTRUCT IS HARD, and the measurement says so three
    // ways. `xor` is a first-class FROZEN opcode at every width including i1
    // (`tools/opcode_table.yaml`, variants fwd_qq/fwd_hl/inv/unc/controlled), so
    // `cq_template_xor_i1` and its adjoint already ship. The SAME `xor i1` of
    // the SAME two tainted compares already lowers as DATA
    // (`return cq_measure(a ^ b)` → exit 0) while declining as CONTROL — one
    // construct, two verdicts, decided by this whitelist and nothing else. And
    // the gate network is the OR node MINUS its toffoli (SelectMergeEmit §1/§5):
    // `cnot(L,G); cnot(Rv,G)` onto a fresh |0⟩ ancilla, strictly FEWER gates
    // than a node the emitter already ships, both CNOTs self-inverse, G back to
    // |0⟩ exactly. NO new frozen symbol, NO new primitive, NO new Rule-6 proof
    // obligation — it holds by the same argument as OR.
    //
    // WHAT IT BUYS, MEASURED BEFORE IT WAS BUILT (the Phase-0 gate on bd
    // 3c6m.67): FOUR census cells — `nextafterl.f80`, `nexttowardl.f80`,
    // `nexttoward.f64`, `nexttowardf.f32` — whose sole blocker is the
    // ulp-direction test `if((x>0.0) ^ (x<y))` at `src/s_nextafterl.c:55` /
    // `s_nexttoward.c:54` / `s_nexttowardf.c:45`. Rewriting ONLY that node at IR
    // level into an in-grammar and/or tree (complementary compare leaves, no xor
    // node anywhere) takes all four from a loud decline to census COMPILES, with
    // `free_pairing_check.py` clean. So the depth behind the xor is ZERO: it was
    // the only thing in the way, not the first of a stack.
    //
    // THE ADMISSION IS NARROW — TWO NON-CONSTANT i1 OPERANDS. A ConstantInt
    // child has no compare leaf and therefore no flag rail, so the emitter's
    // `FlagOf.lookup(child)` would resolve to null; `xor X, 1` (the logical NOT)
    // accordingly stays declined here exactly as before, and the deliberate
    // asymmetry with PredMux's E6 — which DOES admit `xor X, 1`, as the no-NOT
    // invariant's own negation spelling — is unchanged and is pinned by
    // control_swap_reject_select_xor_notform.ll.
    if (NodeOpc == Instruction::Xor &&
        (isa<Constant>(NodeL) || isa<Constant>(NodeR)))
      return false;
    // Self-operand node fence. `or/and i1 %c, %c` emits a toffoli whose two
    // CONTROL slots resolve to ONE rail (per-Value memo).
    //
    // ITS ORIGINAL JUSTIFICATION IS RETRACTED (bd big5, 2026-07-31). It read
    // "an ill-formed physical 3-qubit gate no backend can realize"; that premise
    // is FALSE — this is CASE A (aliased INPUTS, fresh |0> output rail `G`), and
    // `toffoli(c,c,G)` is exactly `cnot(c,G)` (owner ruling: AND of x with
    // itself is x). MEASURED here, and it is not even a peephole obligation —
    // the network as WRITTEN is already alias-correct, because the OR node is
    // `cnot(L,G); cnot(Rv,G); toffoli(L,Rv,G)` (XOR-XOR-AND), NOT an X-bracketed
    // De Morgan. With L == Rv: AND gives G = c∧c = c; OR gives
    // G = c ⊕ c ⊕ (c∧c) = c — both equal `c ∨ c` / `c ∧ c`, and the §5 reverse
    // strip returns G to |0> exactly, so Rule 6 holds. There is no defect here.
    //
    // THE FENCE IS KEPT ANYWAY, as a SCOPED conservative decline (Prime
    // Directive), and the distinction from the leaf axis above is deliberate:
    //   * the LEAF axis was reachable from four lines of plain C at the -O1 ship
    //     floor (via the `cq_phi` RAUW rail merge) AND its decline contradicted
    //     109 committed goldens — so fencing it was an actual defect;
    //   * this NODE axis is reachable from NEITHER. InstCombine folds x∨x / x∧x
    //     to x, and rail-aliasing cannot create it either (every leaf mints its
    //     OWN fresh flag rail via an independent `CreateCall`, so two distinct
    //     leaves are never one rail even when their OPERANDS alias — PINNED by
    //     control_swap_accept_select_and_aliased_leaf.ll, which composes exactly
    //     that: an aliased leaf feeding an `and i1` node, emitting
    //     `cqrt_toffoli(%h_cmp, %h_cmp1, %g)` over THREE distinct rails).
    // So widening here would buy nothing measurable while adding an unprobed
    // accept path. Tracked as a follow-on rather than done blind (bd big5).
    //
    // bd 3c6m.67 — THE FENCE NOW COVERS `xor i1 %c, %c` TOO, and by INHERITANCE
    // rather than by a new line: it sits after the opcode check, so admitting
    // Xor there admits it here. Kept deliberately, on the same reasoning and
    // with even less to lose — for XOR the aliased network is `cnot(c,G);
    // cnot(c,G)`, literally the identity, so G stays |0⟩, which IS the correct
    // value of `c ⊕ c`. Nothing is wrong with it; it is simply unreachable
    // (InstCombine folds `x ⊕ x` to false) and therefore unprobed.
    // Pinned by control_swap_reject_select_xor_selfdup.ll.
    if (NodeL == NodeR)
      return false;
    // bd `test_C_libtooling-xdu2.13` — a CLASSICAL LITERAL child of an `and`/
    // `or` node is recorded, not walked (see `CondLiteral.h`). Only when the
    // caller asks (`IsLiteral`), never at an `xor` (no mixed-xor probe family;
    // it keeps its per-leaf taint decline), and never both children.
    const bool LitL = IsLiteral && NodeOpc != Instruction::Xor && IsLiteral(NodeL);
    const bool LitR = IsLiteral && NodeOpc != Instruction::Xor && IsLiteral(NodeR);
    if (LitL && LitR)
      return false;
    for (auto [Lit, Sib] : {std::pair{LitL ? NodeL : nullptr, NodeR},
                            std::pair{LitR ? NodeR : nullptr, NodeL}})
      if (Lit) {
        if (!llvm::is_contained(Tree.LiteralLeaves, Lit))
          Tree.LiteralLeaves.push_back(Lit);
        Tree.LiteralNodes.push_back({cast<Instruction>(V), Lit, Sib});
      }
    Stack.push_back({V, true});  // node slot AFTER both children.
    if (!LitR)
      Stack.push_back({NodeR, false});
    if (!LitL)
      Stack.push_back({NodeL, false});  // left child visits first.
  }
  return !Tree.Leaves.empty() || !Tree.RailLeaves.empty() ||
         !Tree.RailPhiLeaves.empty();
}

void classifySelectRegion(SelectInst *Sel, TaintSet &taint,
                          WidthDispatch &wd, DominatorTree *DT,
                          LoopInfo *LI, ControlPlan &plan) {
  // GATE 1 — entry: only tainted-condition selects are ours. A classical-cond
  // select is `declineClassicalMuxes`'s domain (L96) and stays declined
  // untouched; the caller already guards this, re-checked here defensively.
  if (!taint.Tainted.count(Sel->getCondition()))
    return;  // not ours; leave for declineClassicalMuxes.

  // GATE 2 — lowerable condition TREE (3c6m.12 L4 widening; compound-cond-
  // select-PRD §2). The condition must be a `CmpInst` or an `and i1`/`or i1`
  // tree over `CmpInst` leaves (the clang -O1 `&&`/`||` fold; a bare compare is
  // the degenerate single-leaf tree — the pre-L4 path, byte-identical
  // emission). Any other tainted i1 (a `trunc`, `xor`, `freeze`, an i1-select
  // combinator, a phi, …) has no flag-mint shape; decline generic `control
  // flow` (a select has no straight-through edge, so the §3c clobber proof
  // obligation can never be met — never brand it `control condition has no
  // template`/clobber; IMPLEMENTATION-4.4 §0). Then PER LEAF:
  //   * an out-of-scope predicate declines (the pre-L4 gate 2);
  //   * an UNTAINTED (classical) compare leaf that reached `Tree.Leaves`
  //     declines — it has no quantum flag to mint, and promoting it would
  //     allocate a qubit for classical data (the §5.2 prohibition).
  //     bd `test_C_libtooling-xdu2.13` — BUT A CLASSICAL CHILD OF AN `and`/`or`
  //     NODE NO LONGER REACHES `Tree.Leaves`: the walk records it as a LITERAL
  //     (`condLiteralAdmissible`, `CondLiteral.h`) and the network mints the
  //     node as `cq_template_<op>_i1_hl(flag, literal)` — the mixed Q+C
  //     convention every other opcode already uses. bd xdu2.8's row-13 program
  //     (`predmux_guarded_vla_reject_row13_hybrid_select.ll`, kept under its old
  //     name per L8) now ACCEPTS through it. What still lands on this check is
  //     an untainted leaf the literal predicate REFUSED: under an `xor`, and —
  //     the load-bearing one — a PredMux E6 rule-(B) residue.
  //     *** bd q2wk, RE-DERIVED AS A RECORD RATHER THAN AN ARGUMENT. *** E6
  //     rule (B) (PRD §4.4b) admits a branch condition that is UNTAINTED now
  //     on the proof that the flatten will taint it; where that proof is
  //     over-wide the value survives as an untainted leaf of a tainted and-tree
  //     (the classical-mux guard cannot fire: every edge predicate is
  //     `and(BP, lit)` with a tainted BP). This check used to be its only
  //     backstop. The flatten now MARKS every such condition's i1 cone and
  //     every edge literal built from it (`!cq.predmux.predicted`, committed at
  //     the CLAIM), the literal predicate refuses a marked cone, and a
  //     residue therefore still falls through to THIS decline. ⚠ No residue
  //     could be CONSTRUCTED (the re-derivation found rule (B)'s prediction
  //     exact on every probe — see the E6 block in `PredMuxFlatten.cpp`), so
  //     that direction is defence in depth with no fixture; what is pinned is
  //     that a mark does not refuse an unrelated genuine literal
  //     (`condtree_classical_leaf_accept_predmux_ruleb.ll`);
  //   * GATE 2b — a Q+Q leaf (BOTH compare operands tainted) declines HERE in
  //     the CONTROL dialect rather than let the emitter's mint reach the
  //     data-path `no template` bail (the message would mis-brand as a
  //     straight-line lowering failure — WI-3 adversarial review NIT).
  //
  // bd `boi6` (D-B) / Track M — `AllowRailPhi = true`, THE ONE CALLER. The grammar
  // now admits a 2-incoming `i1` φ AS THE ROOT; everything that makes it an
  // accept is the §M.0 ladder below, not the walk. `AllowLogicalSelect` stays
  // FALSE (`control_swap_reject_select_i1sel_combinator.ll` is a shipped decline
  // for a data select and is a different construct's widening).
  CondTree Tree;
  if (!collectCondTree(
          Sel->getCondition(), Tree, /*AllowLogicalSelect=*/false,
          /*AllowRailPhi=*/true,
          [&taint](Value *V) { return condLiteralAdmissible(V, taint); }))
    return diagnoseUnderControl(Sel, "control flow");
  // bd `test_C_libtooling-xdu2.13` — a literal's tainted SIBLING must be a flag
  // the network MINTS (a compare leaf or a node ancilla), never a bare RAIL (a
  // `_Bool` register or a region-merge φ): the `_hl` template would then read
  // the user's register in its handle slot, a control read no rail ladder and
  // no spine predicate has been asked about. Declines, the safe direction.
  for (const CondTree::LiteralNode &LN : Tree.LiteralNodes)
    if (isCondRailLeaf(LN.Sibling) || isCondRailPhiShape(LN.Sibling))
      return diagnoseUnderControl(Sel, "control flow");
  // …and the literal is a DATA-select capability only: an ANGLE select (gate 3)
  // re-derives its own tree without literals, so it keeps the pre-xdu2.13
  // verdict and string, asked here before anything else can see the tree.
  if (!Tree.LiteralLeaves.empty() && selReachesRotationArg1(Sel, taint))
    return diagnoseUnderControl(Sel, "control flow");
  for (CmpInst *Leaf : Tree.Leaves) {
    if (!comparePredLowerable(Leaf))
      return diagnoseUnderControl(Sel, "control flow");
    if (!taint.Tainted.count(Leaf))
      return diagnoseUnderControl(Sel, "control flow");
    // bd adia (3c6m.55 Lever C): the categorical Q+Q-leaf decline is LIFTED — a Q+Q
    // leaf is now gated by compareFlagMintable's QQ branch below (shared
    // qqSelectLeafWidth derivation, in-scope predicate, QQ template grid).
    // Per-leaf WIDTH/scope fence (design-review MAJOR — the ziov.4
    // detect-before-mutate discipline): with one flag per leaf the emitter's
    // mint is no longer atomic, so an unmintable leaf (i128 compare, fp128 /
    // pointer / empty-width classical operand, out-of-scope post-flip
    // predicate) must decline HERE, before any sibling flag is emitted — a
    // mid-stream `diagnoseNoTemplate` bail would leave earlier flags and node
    // ancillas dangling (mutate-then-decline). Also sharpens the pre-L4
    // single-leaf emit-time `no template` bail into the control dialect
    // (control_swap_reject_select_fp128_cond.ll, re-pinned as its own comment
    // anticipated).
    if (!compareFlagMintable(Leaf, taint))
      return diagnoseUnderControl(Sel, "control flow");
    // i1-OPERAND leaf fence (design-review MINOR — the `icmp eq i1 %c, false`
    // NOT evasion): a compare OVER i1 values is non-canonical (InstCombine
    // rewrites i1 eq/ne to xor/not forms) and would smuggle a boolean-NOT
    // node past the tree grammar; its mint also passes a raw i1 into the i32
    // handle slot, sound only when the inner producer independently lowers.
    // Over-decline-safe: no -O1/O2 canonical shape lands here.
    if (Leaf->getOperand(0)->getType()->isIntegerTy(1))
      return diagnoseUnderControl(Sel, "control flow");
  }
  // bd 3qlq.4 — RAIL LEAVES (a `_Bool` register as the condition, or as a
  // child of the tree). Tainted by construction (`cq_theta_i1` IS the taint
  // source); re-asked as the same defence-in-depth the compare leaves get. A
  // rail leaf has no predicate, no template and no mint, so no other gate-2
  // clause applies to it. What DOES apply is gate 2c below (the rail is seeded
  // into `Prov` exactly like a compare's operands — a chained Ry on the
  // register between its def and the select would make the emitted control
  // read a moved basis) and the CONSUMER question: in this increment only the
  // Rz-stem ANGLE select lowers a rail condition; the 4.4 DATA select declines
  // it after the angle-select hand-off with `kBareRailCondReason` (follow-on
  // 1b-B — the copy merge controlled on the register itself).
  //
  // bd test_C_libtooling-r9e5 (1b-B.1) — THAT FOLLOW-ON IS THIS: the 4.4 DATA
  // select now LOWERS a rail-leaf condition, so the ladder a rail owes is asked
  // HERE and the trailing `kBareRailCondReason` decline is gone (see below).
  // PRD §14.3, mirroring §13.3's kickback ladder with the SELECT as the read
  // point (`SelectMergeEmit` inserts every gate immediately before it):
  //   (i)   tainted — by construction (`cq_theta_i1` IS the taint source),
  //         re-asked as defence in depth;
  //   (ii)  NOT measured before the SELECT — the mirror of the compare's
  //         `MeasuredEarly`. `railMeasuredBeforeReadPoint` (`ArmClassify`, the
  //         ONE spelling — Rule 14) is asked with `Sel` rather than a block
  //         terminator, which is the whole reason it takes a read point: the
  //         kickback's gate lands AT the branch so a same-block measure always
  //         precedes it, while this stream lands MID-BLOCK and a same-block
  //         measure AFTER the select is the ordinary downstream case
  //         (`control_swap_select_rail_measure_after.ll`, plain `-O1` C);
  //   (iii) the WIRE question — gate 2c below, with the DT prong for RAIL seeds.
  // Its OTHER users are ordinary (it is the user's register): no `hasOneUse`, no
  // `ShareCondFlag`, no "used outside the branch" fence — nothing is minted from
  // it that could outlive the region, and the merge writes only `%out`.
  for (CallInst *Rail : Tree.RailLeaves) {
    if (!taint.Tainted.count(Rail))
      return diagnoseUnderControl(Sel, "control flow");
    if (railMeasuredBeforeReadPoint(Rail, Sel, taint, DT))
      return diagnoseUnderControl(Sel,
                                  "condition measured before the control route");
  }

  // ── THE REGION-MERGE-φ RAIL LADDER (bd `boi6` D-B / Track M) ───────────────
  //
  // The §14.3 ladder above, one construct over: the condition is not a
  // `cq_theta_i1` CALL but the MERGE φ of a diamond that is ALREADY in the plan
  // as a controlled in-place Ry / state PREP. By emit time that φ no longer
  // exists — `emitInPlaceRotationRegion` hoists the arm's theta into `Pred` and
  // M-β RAUWs the φ to it (`SwapRouteEmit.cpp`) — so the EMITTED STREAM is the
  // r9e5 rail-root stream unchanged, byte for byte, and the ORACLE already prints
  // it for the hand-IR twin of this module (`control_swap_accept_select_rail_
  // after_prep{,_negated}.ll`, probes `m18`/`m19`). This widening adds an ACCEPT,
  // not a STREAM.
  //
  //   rung 0   the φ is some region's committed `InPlaceRotation` merge — asked
  //            by CALLING the one owner's verdict, never re-derived;
  //   rung (i) tainted — true by construction, re-asked as defence in depth;
  //   rung (ii) NOT measured before the SELECT — and it is asked over the φ's OWN
  //            PROVENANCE CLOSURE, not over the hoisted theta alone. THAT IS THE
  //            LOAD-BEARING PART (bd `boi6` H-2/H-4, measured): the user writes
  //            `cq_measure(b1)`, which after `-O1` names the **φ**, while
  //            `railWireNamesBackward` `break`s at the first non-call — so a
  //            closure seeded only from the theta is the singleton `{T}` and the
  //            measurement is INVISIBLE. `condProvenance(P)` is `{P, T}`, which is
  //            also EXACTLY the seed set rung (iii) walks below: ONE closure, two
  //            rungs (the 8h7d.5 F-1/F-3 lesson, L2 — "when you widen a set, ask
  //            what OTHER set was computed over the same closure"). Probe `m05`
  //            is the red-green program and flips from `control flow` to
  //            `condition measured before the control route`;
  //   rung (iii) the WIRE question — gate 2c below, seeded from the same closure.
  //
  // `railMeasuredBeforeReadPoint` takes a `const Value *` and is already total
  // over an arbitrary tainted name (Track A.1: "the caller supplies the species by
  // supplying the seed"), so asking it per closure member is the ONE spelling,
  // not a second one. A φ seed yields the singleton closure `{P}` with NO
  // per-activation barrier (the origin is not a source theta), i.e. the strictly
  // more conservative answer — which is the right default for a name that denotes
  // a different basis label on each incoming edge.
  // bd `4aiu` (Track P) — ONE INDEX PER ADMITTED LEAF, not one per tree. With the
  // ROOT-ONLY conjunct gone a tree may carry several φ leaves, each admitted by
  // its own prep region, and each owes `lowerControlRegions` its own precedence
  // edge. A scalar would keep the last and silently drop the rest (F-M1 again,
  // one construct over).
  SmallVector<unsigned, 2> PrepIdxs;
  for (PHINode *P : Tree.RailPhiLeaves) {
    const unsigned PrepIdx = preppedRailPhiRegionIdx(P, plan);
    if (PrepIdx == ControlRegion::kNoParent)
      return diagnoseUnderControl(Sel, "control flow");
    PrepIdxs.push_back(PrepIdx);
    if (!taint.Tainted.count(P))
      return diagnoseUnderControl(Sel, "control flow");
    SmallPtrSet<Value *, 16> PhiProv;
    condProvenance(P, taint, PhiProv);
    for (Value *Name : PhiProv)
      if (railMeasuredBeforeReadPoint(Name, Sel, taint, DT))
        return diagnoseUnderControl(
            Sel, "condition measured before the control route");
  }

  // RUNG (ii) FOR THE COMPARE LEAVES — Track A.1, bd test_C_libtooling-r10v.
  // THE PARITY REPAIR: the loop above has asked this of a RAIL leaf since
  // 1b-B.1, and the COMPARE leaf beside it was asked by nothing. The 4.4
  // classifier has no measured-before rung at all — `condDataUseDisposition`'s
  // `MeasuredEarly` is a `br`-path question about the FLAG's lineage and is not
  // even reached from here — so `int b = cq_theta(0,.5); for (i<3) { int a =
  // (b == 1) ? i : 5; acc += cq_measure(a) + cq_measure(b); }` (plain `clang
  // -O1`; the arm is loop-VARIANT so the select stays in the body) minted trips
  // 2 and 3's flag from a register trip 1 had COLLAPSED — `cqrt_measure_i32(h0)`
  // then `cq_template_icmp_eq_i32_hl(h0, 1)` — at `opt` exit 0, verify-clean and
  // STRICT-stage-2b clean. It is the RAIL half's own F-B1-1 one leaf species
  // over, and it is the same read point and the same helper (Rule 14): `Sel`,
  // because `SelectMergeEmit` emits its whole stream immediately BEFORE the
  // select, so a same-block measure AFTER the select is the ordinary downstream
  // case and only `isPotentiallyReachable` can tell the two apart (it answers
  // the same-block-on-a-cycle case itself, which IS the in-loop program above).
  if (condCmpMeasuredBeforeReadPoint(Tree.Leaves, Sel, taint, DT))
    return diagnoseUnderControl(Sel,
                                "condition measured before the control route");

  // GATE 2c — STALE-CONDITION wire guard (kjd1 Rule-13 implementation
  // clearance, fcmp-lens BLOCKER; FP_SELECT_CLEARANCE.md). SelectMergeEmit
  // mints the flag AT THE SELECT, so the flag reads the condition wire's basis
  // AFTER any gate between the compare and the select. A chained cq_theta (an
  // IN-PLACE, NON-DIAGONAL Ry on an existing handle — RotationLowering) in
  // that gap makes the minted flag encode the POST-Ry predicate while the SSA
  // condition denotes the pre-Ry record: the copies route %out on the wrong
  // predicate, verify-clean (the strip still cleans the flag). Both sibling
  // classifiers carry this guard (ArmClassify::condWireDisposition,
  // SwitchClassify); 4.4 shipped the select without it, and the hole became
  // fp-reachable through the kjd1 gate-4 un-staging. The select mirror, same
  // three prongs (Rule 14 — condProvenance + the shared WireWalk):
  //   (a) position-free: any OFF-ancestry theta on the condition's tainted
  //       provenance wire declines (the mint point is unrelated to the
  //       compare's own schedule, so no positional accept is possible).
  //       CrossValueRouting=TRUE — unlike the ArmClassify caller: the
  //       post-fix refute-default round (E1, FP_SELECT_CLEARANCE.md addendum)
  //       showed a chained theta whose arg-0 reaches the condition wire only
  //       through a one-register value-routing phi (the sanctioned lift
  //       shape, plain-C-reachable at -O1) evades the router-blind walk while
  //       sitting BEFORE the compare (outside prong (c)); a router forwards
  //       the same physical handle, so the walk must cross it. The
  //       pass-wide stale-record guard deliberately excludes select-condition
  //       compares (OpcodeLowering inLowerOpsScope), so there is NO backstop;
  //   (b) REVISED (9ymx owner decision 2026-07-03 — conditionals in loops are
  //       allowed): a cross-block compare no longer blanket-declines. The
  //       -O1-natural in-loop ternary LICM-hoists its loop-invariant compare
  //       into the guard/preheader block while the select stays in the body,
  //       so the first-cut "cannot bound the positional scan" decline
  //       mis-branded every theta-free loop conditional as stale. Dropping it
  //       is SOUND: prong (a) is position-free with NO window — any
  //       off-ancestry theta on the condition's provenance wire declines
  //       wherever it sits — and the positional prong only ever added
  //       OTHER-wire conservatism, which cannot stale this flag (a gate on
  //       another register does not move the condition wire's basis, so the
  //       per-iteration mint still equals the source compare). SSA dominance
  //       guarantees the compare executes before the select on every path;
  //       operand staleness is gate 5's (wire-anchored, position-free).
  //       Pinned by control_swap_select_inloop_hoisted_cond.ll + the
  //       slice_control_select_loop e2e golden;
  //   (c) positional, SAME-BLOCK only (the ArmClassify-mirror conservatism,
  //       kept where its window is bounded): any tainted-operand cq_theta
  //       between the compare and the select declines, even on another wire
  //       (over-decline is safe).
  // A diagonal gate (cq_phi/Rz) preserves the basis, so the mint still equals
  // the source compare — phase on the condition wire is gate 5's concern for
  // OPERANDS only, never a staleness (the rz-diag-flag-strip invariant).
  // Additionally (E2, same addendum): a tainted FreezeInst anywhere in the
  // condition's provenance declines — an fp freeze survives the escape guard
  // (7.1 Inc B skips it) but is un-launderable: the theta RAUW-to-handle
  // leaves `freeze double %h` ill-typed and opt ABORTS on the broken module
  // (a crash on valid input, not a loud decline). Newly fp-reachable through
  // the gate-4 un-staging; fenced here at detection, before any mutation.
  // 3c6m.12: the guard runs over the LEAF UNION — `condProvenance` accumulates
  // per leaf into ONE seed set (a walk seeded from only one leaf would accept
  // a chained theta staling the OTHER leaf's wire — pinned by
  // control_swap_reject_select_stale_leaf_onewire.ll); the positional prong
  // (c) scans per leaf. The tree NODES need no seeding of their own: an
  // `and`/`or` result carries no rotation wire, and its basis provenance is
  // exactly the union of its leaves'.
  //
  // bd test_C_libtooling-r9e5 (1b-B.1) — TWO SEED SETS, TWO QUESTIONS, and the
  // split is the whole widening. A COMPARE's seeds keep the POSITION-FREE walk
  // verbatim (prong (a) above: the mint point is unrelated to the compare's own
  // schedule, so no positional accept is possible), while a RAIL's seeds get the
  // DT PRONG that `railCondWireDisposition` gives the kickback (`ArmClassify`,
  // PRD §13.3 item 3): position-free CLEAN ⇒ accept; else no `DT` ⇒ decline
  // (Prime Directive — no tree, no proof); else re-ask with `EmitPoint = Sel`,
  // so a gate NOT provably after every execution of the select declines and one
  // PROVEN after it accepts. The P1 argument transfers exactly: the copies read
  // `b`'s basis label AT the select, the flag is minted and stripped and freed
  // inside the stream, and nothing of the region survives on `b` for a later
  // gate to invalidate — so `if (b) a -= 3; b = cq_theta(b, -0.5);` (the S†
  // spelling, probe `s04`) lowers, while a theta BETWEEN the rail's def and the
  // select, a SIBLING theta on the same physical rail (the F-1b-1 class, which
  // the walker's tainted-parent ancestry now sees), and any in-LOOP body theta
  // (the back edge defeats `provablyBefore`'s reachability half — probe `s18`)
  // all keep declining. With NO rail leaves `RailProv` is empty and `CmpProv` is
  // the pre-1b-B `Prov` insertion-for-insertion, so every compare-conditioned
  // select is byte-unchanged.
  {
    SmallPtrSet<Value *, 16> CmpProv;
    SmallPtrSet<Value *, 16> RailProv;
    for (CmpInst *Leaf : Tree.Leaves)
      condProvenance(Leaf, taint, CmpProv);
    for (CallInst *Rail : Tree.RailLeaves)
      condProvenance(Rail, taint, RailProv);  // bd 3qlq.4: the register's wire.
    // bd `boi6` (D-B) / Track M — RUNG (iii) FOR THE MERGE φ, into the SAME seed
    // set the rail leaves use, because it IS the same question about the same
    // kind of object: a physical register named by a value, whose wire must carry
    // no off-ancestry non-diagonal gate. `condProvenance` needs nothing new for a
    // φ (`ArmClassify`: it walks operand edges and stops at each `cq_theta`, so a
    // φ contributes `{φ, each incoming theta}` — exactly the wire), and the DT
    // prong that `RailProv` gets is exactly the prong a rail owes: position-free
    // CLEAN ⇒ accept, else no `DT` ⇒ decline, else re-ask at `EmitPoint = Sel`.
    // ⚠ OMITTING THIS WOULD BE THE WHOLE INCREMENT'S OVER-ACCEPT: a φ leaf
    // contributes to NEITHER `CmpProv` NOR `RailProv` by default, so gate 2c
    // would never look at the prepped register's wire at all.
    for (PHINode *P : Tree.RailPhiLeaves)
      condProvenance(P, taint, RailProv);
    for (const SmallPtrSet<Value *, 16> *S : {&CmpProv, &RailProv})
      for (Value *P : *S)
        if (isa<FreezeInst>(P))
          return diagnoseUnderControl(Sel, "control flow");
    SmallVector<Value *, 16> Seeds(CmpProv.begin(), CmpProv.end());
    if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/nullptr, /*DT=*/nullptr, &taint))
      return diagnoseUnderControl(Sel,
                                  "condition predates a non-diagonal gate");
    if (!RailProv.empty()) {
      SmallVector<Value *, 16> RailSeeds(RailProv.begin(), RailProv.end());
      if (findNonDiagonalWireGate(RailSeeds, /*CrossValueRouting=*/true,
                                  /*EmitPoint=*/nullptr, /*DT=*/nullptr,
                                  &taint) &&
          (!DT || findNonDiagonalWireGate(RailSeeds, /*CrossValueRouting=*/true,
                                          /*EmitPoint=*/Sel, DT, &taint)))
        return diagnoseUnderControl(Sel,
                                    "condition predates a non-diagonal gate");
    }
    for (CmpInst *Leaf : Tree.Leaves) {
      if (Leaf->getParent() != Sel->getParent())
        continue;
      for (const Instruction *I = Leaf->getNextNode(); I && I != Sel;
           I = I->getNextNode()) {
        const auto *CI = dyn_cast<CallInst>(I);
        if (!CI)
          continue;
        const Function *F = CI->getCalledFunction();
        if (F && F->getName().starts_with("cq_theta_") &&
            CI->arg_size() >= 1 && taint.Tainted.count(CI->getArgOperand(0)))
          return diagnoseUnderControl(
              Sel, "condition predates a non-diagonal gate");
      }
    }
  }

  // GATE 3 — the §3.2 BLOCKER: NOT an angle. FIRST among the type gates (the
  // FP-use fence precedes the width gate, exactly as ArmClassify.cpp:820 precedes
  // :834). There is NO downstream backstop, so the angle MUST be caught here.
  //
  // ⚠ "AN ANGLE SELECT MUST KEEP DECLINING" IS NO LONGER TRUE OF THE WHOLE CLASS
  // (bd test_C_libtooling-drbq Inc 2b, control-in-place-PRD §12.3). ONE angle
  // shape now LOWERS — a `double` select over two CLASSICAL angles whose SOLE
  // user is the arg-1 slot of a chained `cq_theta`/`cq_phi`, under a bare
  // single-user tainted compare, all three in one block. It is emitted BY
  // DIFFERENCE (`R(h,B); f = icmp; R_controlled(f,h,A−B); icmp_unc; free`), which
  // is exact IN REAL ARITHMETIC by angle additivity on one axis (in IEEE double
  // the realized true-arm angle is `B + fl(A-B)`, `|delta| <= 1/2 ulp(A-B)`, so
  // BOTH ARMS MUST BE `ConstantFP` and their evaluated residual must sit under a
  // placeholder 2^-40 rad; a RUN-TIME arm DECLINES right here, because the
  // synthesized `fsub` carries an error UNBOUNDED in absolute radians and can be
  // `inf`/`NaN` from two FINITE arms — round-1 Rule-13 review lens L7-F1,
  // both-halves wording from the round-2 one lens R1 item 1, constant-arms-only
  // narrowing from the CLEARANCE review, finding F-11 / owner option (2)) and is
  // byte-identical to the
  // manual by-difference twin the Inc-1/2a in-place diamond already lowers. That is
  // exactly the IR `clang -O1` makes of `if (q==5) r=cq_theta(r,A); else
  // r=cq_theta(r,B);` — SimplifyCFG merges the arms into ONE call with a select
  // on the ANGLE — so this is the shape that makes the C `if/else` with two
  // rotations on one register compile.
  //
  // WHAT DID NOT CHANGE, and it is the load-bearing half: `classifyAngleSelect`
  // returns `NotApplicable` for everything outside that one shape, and the
  // decline below then fires BYTE-IDENTICALLY to what it fired before. A tainted
  // A/B, a carrier (fpext/fptrunc/bitcast/freeze/phi/nested select), a second
  // consumer, a fanned-out data+angle select, a Q+Q or compound condition, a
  // classical arg-0 (state prep), a cross-block consumer — all still land here.
  // The `Declined` state exists because THREE refusals inside the accept class
  // have their own precise strings (`control flow inside a loop body`,
  // `rotation arm on a condition wire`, `stale rail record read past a
  // controlled Ry`) that `rotation angle` would MISLABEL.
  if (selReachesRotationArg1(Sel, taint)) {
    switch (classifyAngleSelect(Sel, Tree, taint, wd, DT, LI, plan)) {
    case AngleSelectDisp::Accepted:
    case AngleSelectDisp::Declined:
      return;  // pushed for AngleSelectEmit, or already diagnosed precisely.
    case AngleSelectDisp::NotApplicable:
      break;
    }
    return diagnoseUnderControl(Sel, "rotation angle");
  }
  // bd 3qlq.4 / bd test_C_libtooling-r9e5 (1b-B.1) — THE `kBareRailCondReason`
  // DECLINE THAT STOOD HERE IS GONE: the 4.4 DATA select with a rail-leaf
  // condition LOWERS (the rail ladder is above, the copy flag is
  // `CondTreeEmit`'s `CopyRailRoot`). Its position mattered and the successor
  // inherits it — the rail rungs are asked BEFORE the angle hand-off, so the
  // Rz-stem angle select on a rail still reaches `classifyAngleSelect` exactly
  // as it did (`control_angle_select_phase_rail.ll`), and the Ry stem still
  // declines `kBareRailCondReason` INSIDE that classifier (1b-C, bd
  // `test_C_libtooling-l4x4` — `control_angle_select_reject_rail_ry.ll`). The
  // string survives at every other consumer and is still a discriminator: the
  // value arm and the in-place-Ry/state-prep arms (`ArmClassify`, 1b-B.2 — bd
  // `test_C_libtooling-r9e5`, `control_swap_reject_value_rail_cond.ll`), and
  // `SelectMergeEmit`'s own drift guard is now the OPPOSITE assertion.
  //
  // Gates 4/5/6 below apply to a rail-conditioned select UNCHANGED: they ask
  // about the select's RESULT TYPE and its two ARM OPERANDS, never about the
  // condition. A rail CONDITION with a downstream rotation is fine, exactly as a
  // compare's register is — gate 5's coherence question is an OPERAND question
  // (bd memory [select-merge-phase-operand-dephasing]).

  // GATE 4 — ABI-width scalar result with a controlled copy (§16.9), AFTER the
  // FP-use fence. Accepts scalar integer {i1..i64} (`widthHasReversibleCopy`)
  // and — the §16.4 un-staging, fp-data-select-PRD §4.4 — scalar fp
  // {f16,f32,f64,f80} (`abiWidthHasControlledFpCopy`). The fp accept is safe
  // ONLY because gate 3 above already proved the select is DATA along every
  // value-preserving carrier, the escape guards own the memory/call routes,
  // and `declineTaintedAngle` backstops value-changing re-realizations (the §2
  // three-legged fence); gate ORDER (3 before 4) is the load-bearing
  // invariant. The fp accept is deliberately `isFloatingPointTy` (SCALAR-only
  // — fp vectors like `<2 x double>` keep declining; `isFPOrFPVectorTy` would
  // be wrong on the accept side). Still declines: fp vector, f128 (empty
  // width), pointer/aggregate, integer vector, and i128.
  // n0ui Tier-1: gate on the copy predicates, NOT `abiWidthFromType(T).empty()`
  // — i128 is a recognized (intermediate) width so `.empty()` is FALSE for it,
  // but it has NO `cqrt_copy_i128` (source/sink stay i64), so a tainted i128
  // data select must still DECLINE here, not slip through and mint a phantom.
  Type *T = Sel->getType();
  const bool IntData =
      T->isIntegerTy() && widthHasReversibleCopy(abiWidthFromType(T));
  const bool FpData =
      T->isFloatingPointTy() && abiWidthHasControlledFpCopy(abiWidthFromType(T));
  if (!IntData && !FpData)
    return diagnoseUnderControl(Sel, "control flow");

  // GATE 5 — conservative coherent-operand default (§16.7), BOTH halves. A
  // tainted value operand is declined if it (a) IS itself a relative-phase (Rz)
  // carrier — `operandCarriesPhase`, the WI-3 dephasing finding — or (b) FEEDS a
  // downstream rotation beyond the select — `hasCoherentDownstreamUse`, channel B.
  // Either makes the basis CNOT-copy merge produce a wrong/dephased %out. Declined
  // until the §8 Rule-13 clearance widens this.
  for (Value *Op : {Sel->getTrueValue(), Sel->getFalseValue()})
    if (taint.Tainted.count(Op) &&
        (taintedLineageHasFreeze(Op, taint) ||
         operandCarriesPhase(Op, taint) ||
         hasCoherentDownstreamUse(Op, Sel, taint)))
      return diagnoseUnderControl(Sel, "control flow");

  // GATE 6 — distinct operands / aliasing guard (§16.9). The two operands must
  // resolve to provably-disjoint post-lowering registers.
  if (operandsAlias(Sel->getTrueValue(), Sel->getFalseValue()))
    return diagnoseUnderControl(Sel, "control flow");

  // ACCEPT — all six gates pass. Push a `SelectRegion` for `SelectMergeEmit`
  // (WI-3, dispatched from `lowerControlRegions` on `Kind==SelectRegion`). No
  // `ControlPlan` field is added: `Kind::SelectRegion` + the `Instruction* Merge`
  // slot already hold a `SelectInst`, and the emitter reads `TrueValue`/
  // `FalseValue` off `cast<SelectInst>(R.Merge)` and the width off
  // `abiWidthFromType(Sel->getType())` (valid at emit time — L84 precedes
  // rotation lowering at L110). The block/depth fields stay null (a select has no
  // CFG diamond), which makes it inert to the cross-region pre-flight.
  ControlRegion R;
  R.Kind = ControlRegion::SelectRegion;
  R.Merge = Sel;  // a SelectInst fits the Instruction* Merge slot.
  R.Condition = Sel->getCondition();
  // bd r9e5 F-B1R1-2: a rail-carrying tree reached here through the §14.3 rail
  // ladder above; the emitter refuses one that arrives without this flag.
  // bd `boi6` (D-B) / Track M — a MERGE-φ tree came through the §M.0 ladder, and
  // by emit time its φ IS a `cq_theta_i1` call, so the emitter's
  // `!Tree.RailLeaves.empty() && !R.RailLadderProven` backstop will see a rail
  // leaf and MUST see the flag. Forgetting this `||` would refuse the very accept
  // the ladder above just created (the r9e5 round-1 F-B1R1-2 shape verbatim).
  R.RailLadderProven =
      !Tree.RailLeaves.empty() || !Tree.RailPhiLeaves.empty();
  // F-M1 — CARRY THE ORDER OBLIGATION, do not leave the emitter to re-derive it.
  // `PrepIdxs` is rung 0's own answer (one entry per φ leaf the loop above
  // admitted, and a φ leaf cannot reach here without one); `lowerControlRegions`
  // turns each into ONE precedence edge so this select is emitted AFTER every
  // region whose M-β rewrites part of its condition. EMPTY for a compare- or
  // rail-conditioned select, which needs no edge because nothing rewrites its
  // condition.
  R.PrepRegionIdxs = PrepIdxs;
  // bd `test_C_libtooling-xdu2.13` — COMMIT the literals this walk admitted. The
  // emitter re-derives its tree by MEMBERSHIP of this list, never by re-asking
  // taint (which the regions emitted before it can grow).
  for (Value *Lit : Tree.LiteralLeaves)
    R.CondLiterals.emplace_back(Lit);
  plan.Regions.push_back(R);
}

}  // namespace cq
