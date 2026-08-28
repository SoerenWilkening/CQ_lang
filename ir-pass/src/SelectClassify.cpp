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
#include "ControlPlan.h"     // diagnoseUnderControl, ControlPlan, ControlRegion
#include "OpcodeSupport.h"   // abiWidthFromType
#include "TaintPropagation.h"  // TaintSet
#include "WireWalk.h"        // findNonDiagonalWireGate (gate 2c stale condition)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
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
bool selReachesRotationArg1(SelectInst *Sel) {
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
      if (auto *CI = dyn_cast<CallInst>(X))
        if (isRotationCall(CI) && CI->arg_size() >= 2 &&
            CI->getArgOperand(1) == U && CI->getArgOperand(0) != U)
          return true;  // angle — decline the WHOLE select (fan-out rule).

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

// 3c6m.12 (L4) — the shared condition-tree walk (see SelectClassify.h). An
// explicit two-phase stack (a (value, childrenDone) pair) yields left-to-right
// post-order without recursion; `Seen` both dedupes SHARED subtrees (a leaf or
// node reachable from two tree positions collects ONCE — its flag/ancilla
// mints once, network controls are read-only) and bounds the walk (SSA is
// acyclic through pure i1 ops — no phi is ever crossed).
bool collectCondTree(Value *Root, CondTree &Tree) {
  SmallPtrSet<Value *, 8> Seen;
  SmallVector<std::pair<Value *, bool>, 8> Stack;
  Stack.push_back({Root, false});
  while (!Stack.empty()) {
    auto [V, ChildrenDone] = Stack.pop_back_val();
    if (ChildrenDone) {
      Tree.Nodes.push_back(cast<BinaryOperator>(V));  // post-order emit slot.
      continue;
    }
    if (!Seen.insert(V).second)
      continue;  // shared subtree — already collected once.
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
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (!BO || !BO->getType()->isIntegerTy(1) ||
        (BO->getOpcode() != Instruction::And &&
         BO->getOpcode() != Instruction::Or &&
         BO->getOpcode() != Instruction::Xor))
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
    if (BO->getOpcode() == Instruction::Xor &&
        (isa<Constant>(BO->getOperand(0)) || isa<Constant>(BO->getOperand(1))))
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
    if (BO->getOperand(0) == BO->getOperand(1))
      return false;
    Stack.push_back({V, true});  // node slot AFTER both children.
    Stack.push_back({BO->getOperand(1), false});
    Stack.push_back({BO->getOperand(0), false});  // left child visits first.
  }
  return !Tree.Leaves.empty();
}

void classifySelectRegion(SelectInst *Sel, TaintSet &taint, ControlPlan &plan) {
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
  //   * an UNTAINTED (classical) leaf declines — it has no quantum flag to
  //     mint, and promoting it would allocate a qubit for classical data (the
  //     §5.2 prohibition); a hybrid classical∧quantum conjunction is out of
  //     scope this increment.
  //     *** LOAD-BEARING FOR bd q2wk — READ BEFORE LIFTING THIS. *** PredMux's
  //     E6 rule (B) (PRD §4.4b) admits a branch condition that is currently
  //     UNTAINTED on the proof that the flatten will taint it. Where that proof
  //     is over-wide, the value survives the flatten as an untainted COMPARE
  //     LEAF inside a tainted and-tree — and THIS check, not
  //     `declineClassicalMuxes`, is what declines it (the classical-mux guard
  //     provably cannot fire: every edge predicate is `and(BP, lit)` with a
  //     tainted BP, so every PredMux-minted select condition is tainted). If
  //     the hybrid conjunction is ever supported here, rule (B)'s taint
  //     argument must be re-derived first — it is currently backstopped by
  //     this decline;
  //   * GATE 2b — a Q+Q leaf (BOTH compare operands tainted) declines HERE in
  //     the CONTROL dialect rather than let the emitter's mint reach the
  //     data-path `no template` bail (the message would mis-brand as a
  //     straight-line lowering failure — WI-3 adversarial review NIT).
  CondTree Tree;
  if (!collectCondTree(Sel->getCondition(), Tree))
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
  {
    SmallPtrSet<Value *, 16> Prov;
    for (CmpInst *Leaf : Tree.Leaves)
      condProvenance(Leaf, taint, Prov);
    for (Value *P : Prov)
      if (isa<FreezeInst>(P))
        return diagnoseUnderControl(Sel, "control flow");
    SmallVector<Value *, 16> Seeds(Prov.begin(), Prov.end());
    if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true))
      return diagnoseUnderControl(Sel,
                                  "condition predates a non-diagonal gate");
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
  if (selReachesRotationArg1(Sel))
    return diagnoseUnderControl(Sel, "rotation angle");

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
  plan.Regions.push_back(R);
}

}  // namespace cq
