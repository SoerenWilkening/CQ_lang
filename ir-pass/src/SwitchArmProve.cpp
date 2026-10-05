// SwitchArmProve.cpp — the per-class G6 proofs for a tainted `switch`
// (swap-route 4.5 WI-1; PRD Part V §20.7; IMPLEMENTATION-4.5 §3.1).
// See SwitchArmProve.h for the contract.
//
// Pure SSA/CFG analysis — NO IR is mutated (Rule 9). Detection runs at the
// pipeline's `detectControlRegions` step (L83), before rotation lowering's
// RAUW-to-handle (L110), so each arm's `cq_phi`/`cq_theta` calls and the case
// literals still carry their real logical identity.
//
// Reuse note (Rule 14 + IMPLEMENTATION-4.5 open-Q-8 fallback): the lineage WALKS
// are the exported `walkPhaseSpine`/`walkValueChain`/`taintedAngleGate`
// (ArmAnalysis.h). The tiny opcode predicate `isValueChangingOp` and the
// pure-spine / pure-chain block scans are re-derived TU-local here (they are
// TU-local statics in ArmClassify.cpp / anon mirrors in ArmHomogeneity.cpp, and
// collide if promoted — the established house style; ArmAnalysis.h note).

#include "SwitchArmProve.h"

#include "ArmAnalysis.h"     // walkPhaseSpine, walkValueChain, taintedAngleGate
#include "ControlPlan.h"     // diagnoseUnderControl, SwitchClass
#include "TaintPropagation.h"  // TaintSet
#include "WireWalk.h"          // findNonDiagonalWireGate (shared-base wire staleness)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// TU-local intrinsic-call predicates (NOT exported — they collide with the
// same-named anon helpers in ArmClassify.cpp / SelectClassify.cpp / WireWalk.cpp;
// ArmAnalysis.h note).
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

// Re-derived mirror of ArmClassify.cpp / ArmHomogeneity.cpp's anonymous
// `isValueChangingOp`: a leaf (Argument/Constant), a `cq_theta` (Ry source), or a
// retired `cq_phi_<sfx>` (`isPhiCall`, vacuous) is NOT value-changing; ANY other
// instruction (add/mul/cast/shl/…) defining a new computational-basis value IS.
// Classified by OPCODE, never by defining block.
bool isValueChangingOp(const Value *Base) {
  const auto *I = dyn_cast<Instruction>(Base);
  if (!I)
    return false;
  if (isThetaCall(I) || isPhiCall(I))
    return false;
  return true;
}

// Re-derived mirror of ArmClassify::armBlockIsPureSpine / ArmHomogeneity::
// innerArmIsPureSpine: every non-terminator instruction in `ArmBB` must lie on the
// linear spine of `ArmIncoming` (retired `cq_phi_<sfx>` calls, following arg-0).
// A fan-out sibling or a stray op the emitter would silently drop on flatten
// makes the arm impure (Rule 5 / Rule 8).
bool armPureSpine(const BasicBlock *ArmBB, const Value *ArmIncoming) {
  SmallPtrSet<const Value *, 8> Spine;
  for (const Value *V = ArmIncoming; isPhiCall(V);) {
    Spine.insert(V);
    const auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  for (const Instruction &I : *ArmBB) {
    if (I.isTerminator())
      continue;
    if (!Spine.count(&I))
      return false;
  }
  return true;
}

// Re-derived mirror of ArmClassify::valueArmIsPureChain: the arm block must hold
// nothing beyond the linear value chain, and the chain must be linear (each link's
// sole user is the next link; the last link's sole user is the merge phi). Fan-out
// double-uncomputes the shared prefix (use-after-free + double-free, Rule 8).
bool valuePureChain(const BasicBlock *ArmBB, ArrayRef<Instruction *> ChainOps,
                    const PHINode *MergePhi) {
  SmallPtrSet<const Instruction *, 8> OnChain(ChainOps.begin(), ChainOps.end());
  for (const Instruction &I : *ArmBB) {
    if (I.isTerminator())
      continue;
    if (!OnChain.count(&I))
      return false;  // stray op / DAG sibling silently dropped on flatten.
  }
  for (size_t i = 0; i < ChainOps.size(); ++i) {
    const Instruction *I = ChainOps[i];
    const Value *Expected =
        (i + 1 < ChainOps.size()) ? static_cast<const Value *>(ChainOps[i + 1])
                                  : static_cast<const Value *>(MergePhi);
    if (!I->hasOneUse() || *I->user_begin() != Expected)
      return false;  // fan-out — non-linear lineage.
  }
  return true;
}

}  // namespace

// G5 — per-case content class (open-Q-8 fallback composition).
SwitchClass caseArmClass(Value *Incoming, BasicBlock *Block) {
  if (isa<ConstantInt>(Incoming))
    return SwitchClass::DataMux;
  if (!Block)
    return SwitchClass::Phase;  // empty case (straight-through); not content.
  Value *Base = walkPhaseSpine(Incoming, Block);
  if (Base != Incoming) {
    // The spine consumed ≥1 retired `cq_phi_<sfx>`; an in-arm value-changing
    // base is the mixed `q=q*7; rz(q)` lineage (Value; `mixed` fires later).
    if (auto *BI = dyn_cast<Instruction>(Base);
        BI && BI->getParent() == Block && isValueChangingOp(Base))
      return SwitchClass::Value;
    return SwitchClass::Phase;
  }
  // Spine consumed nothing: the arm incoming is the base itself (a leaf — empty
  // phase arm) or the top of a value chain (`p = p + 3`).
  return isValueChangingOp(Base) ? SwitchClass::Value : SwitchClass::Phase;
}

// G6 PHASE — the merge-φ ladder's phase proof, written for the RETIRED register
// form: each content arm a `cq_phi_<sfx>` gate whose arg-0 `clang -O1` folded to
// the case literal, a pure spine, and a classical angle. That form now declines
// in `resolveSources`, and a register-free phase switch has no merge φ and is
// accepted by `classifyPhaseKickbackSwitch` instead, so on a valid module this
// proof only declines (e.g. a distinct tainted incoming, MUX-EXCH).
bool proveSwitchPhase(const SwitchShape &S, TaintSet &Taint) {
  // The phase model is single-rail on the SCRUTINEE: the default/straight-through
  // edge carries q itself (pre-3qlq, the emitter routed q and RAUWed the merge to
  // q). A straight-through that is a DIFFERENT tainted rail %b would be silently
  // dropped while the case arms are muxed against an unrelated wire — an
  // over-accept. Require the straight-through to BE the scrutinee. This also
  // forces the case-literal and arm-const WIDTHS to be structurally equal, so the
  // per-arm width guard below is belt-and-suspenders defense-in-depth.
  if (S.StraightThrough != S.SI->getCondition()) {
    diagnoseUnderControl(S.SI, "control flow");
    return false;
  }
  bool SawContent = false;
  for (const SwitchCase &C : S.Cases) {
    if (C.Incoming == S.StraightThrough)
      continue;  // passthrough/empty case — carries the scrutinee, no gate.
    Value *Base = C.Block ? walkPhaseSpine(C.Incoming, C.Block) : C.Incoming;
    auto *BaseConst = dyn_cast_or_null<ConstantInt>(Base);
    // The const-fold re-anchor signature (D4 — by APInt/WIDTH equality): the in-arm
    // phase spine must bottom at THIS case's literal, at the SAME width. The arm
    // const takes the merge-phi width while the case literal takes the scrutinee
    // width; clang -O1 can make them differ (narrow scrutinee, wider rail). The
    // `getType()` guard MUST precede the `getValue()` compare — APInt::operator==
    // on mismatched widths asserts (asserts-on build: crash) or raw-word-compares
    // (NDEBUG: e.g. APInt(8,0xFF)==APInt(32,255) wrongly true → a width-divergent
    // over-accept). A distinct tainted handle here is a quantum multiplexer
    // (MUX-EXCH) — no copy-safe phase lowering (Rule 8). Either way decline.
    if (!C.Block || !BaseConst || BaseConst->getType() != C.Value->getType() ||
        BaseConst->getValue() != C.Value->getValue()) {
      diagnoseUnderControl(S.SI, "control flow");
      return false;
    }
    if (!armPureSpine(C.Block, C.Incoming)) {
      diagnoseUnderControl(S.SI, "impure phase arm");
      return false;
    }
    if (taintedAngleGate(C.Incoming, C.Block, Base, Taint)) {
      diagnoseUnderControl(S.SI, "rotation angle");
      return false;
    }
    SawContent = true;
  }
  if (!SawContent) {
    diagnoseUnderControl(S.SI, "control flow");  // identity/no-op switch.
    return false;
  }
  return true;  // clean homogeneous phase switch (would-be-accept).
}

// G6 VALUE — each content arm is a pure value chain bottoming at the SHARED base
// `p` = the straight-through (default-edge) incoming, with `p != q` (C2 anchor;
// writing the scrutinee would clobber the eq-flags). WI-1 established the
// base-identity / purity floor; WI-3 completes the proof into a faithful mirror of
// the diamond value path (ArmClassify.cpp): the §3c clobber (G7), the shared-base
// wire-staleness guard, and the derived-base own-angle guard all land here beside
// the value emitter, each PRE-MUTATION (Rule 9 detect-before-mutate) so no
// off-pattern shape is ever emitted+flattened before a downstream abort.
bool proveSwitchValue(const SwitchShape &S, TaintSet &Taint) {
  Value *P = S.StraightThrough;
  if (!P || P == S.SI->getCondition()) {
    diagnoseUnderControl(S.SI, "value-arm swap-route");  // C2 mis-anchor.
    return false;
  }

  // G7 §3c clobber (WI-3) — the shared base `p` must be DISJOINT from the
  // SCRUTINEE's transitive taint provenance. Rewriting a register the
  // scrutinee reads clobbers the very wire the eq-flags are minted from: the
  // flag-strip premise `icmp_inv(q, c_i)` reads the same basis as the mint, and
  // that premise dies with the rewrite (information-theoretically impossible to
  // both keep `p`'s answer and disentangle the scrutinee — §3c). `condProvenance`
  // seeds the scrutinee-read set (its arg-1 angle exclusion intact); a value arm
  // over `p` while the scrutinee reads `p`'s diagonal-alias closure (pre-3qlq
  // register form: RAUW collapsed `%qd = cq_phi_si32(%q,·)` and `%q` to ONE
  // handle, so SSA-value disjointness was NOT wire disjointness) is the miscompile.
  // The PERMANENT string fires on the proven identity (`p` itself is read); a
  // mere shared-wire alias declines GENERIC `control flow` — the flat-path
  // Defect-2 discipline (never brand a shape information-theoretically impossible
  // on unproven evidence). Mirrors the diamond value clobber (ArmClassify.cpp).
  SmallPtrSet<Value *, 16> Prov;
  condProvenance(S.SI->getCondition(), Taint, Prov);
  if (Value *Hit = diagonalAliasHit(P, Prov)) {
    diagnoseUnderControl(S.SI, Hit == P ? "arm rewrites a condition operand"
                                        : "control flow");
    return false;
  }

  // Shared-base WIRE staleness (WI-3 Rule-13 clearance) — the shared base `p`'s
  // physical wire (with its diagonal-alias closure, the retired `cq_phi_<sfx>`
  // arg-0 chain) must gain NO non-diagonal (Ry/`cq_theta`) in-place gate. A
  // chained theta reaching the wire through a SIBLING SSA name
  // (`%p2 = cq_theta(%p,·)`) is invisible to the §3c clobber
  // scan above (`condProvenance` stops AT a theta source, never entering its
  // tainted arg-0) and to G10 (which seeds only the SCRUTINEE `q`, never `p`) —
  // yet post-RAUW the preload copy and the hoisted chain read the POST-Ry wire
  // while the chain names the PRE-Ry RECORD: the stale-record family, a
  // verify-clean wrong unitary. Position-free walk — ANY theta on the wire
  // declines (over-decline is safe). Mirrors the diamond value twin
  // (ArmClassify.cpp:928) so the switch shares the diamond's primary guard rather
  // than relying on the `valuePureChain` / `declineStaleRecordOps` backstop
  // coincidence (Rule 14).
  // CrossValueRouting=TRUE since bd tayx (uniform router posture; Rule 14): a
  // router phi forwards the same physical handle. For this value path the
  // flip is belt-and-braces — the router spelling's arm ops read the stale
  // wire and the pre-detect `declineStaleRecordOps` declines it first (pinned
  // by control_swap_reject_switch_value_router_base_backstop.ll) — exactly
  // the backstop coincidence this guard exists not to rely on (see above).
  if (CallInst *Gate = findNonDiagonalWireGate(P, /*CrossValueRouting=*/true,
                                               /*EmitPoint=*/nullptr,
                                               /*DT=*/nullptr, &Taint)) {
    diagnoseUnderControl(Gate, "routed base predates a non-diagonal gate");
    return false;
  }

  // A DERIVED shared base's OWN angle must be classical — the arg-1 parallel of
  // criterion 3 (Rule 3), written for a `cq_phi_<sfx>(x, θ)` base. VACUOUS since
  // 3qlq: that register form declines in `resolveSources`, so `isPhiCall` matches
  // nothing on a valid module (kept, see `isPhiCall`). Pre-3qlq, without it the
  // region was EMITTED and FLATTENED before `RotationLowering`'s angle guard
  // fired (mutate-then-decline), and the forward G3 walk cannot see an angle
  // UPSTREAM of the straight-through incoming. Mirrors the diamond value twin
  // (ArmClassify.cpp:944).
  if (auto *BaseCI = dyn_cast<CallInst>(P);
      BaseCI && isPhiCall(BaseCI) && BaseCI->arg_size() >= 2 &&
      Taint.Tainted.count(BaseCI->getArgOperand(1))) {
    diagnoseUnderControl(BaseCI, "rotation angle");
    return false;
  }

  bool SawContent = false;
  for (const SwitchCase &C : S.Cases) {
    if (C.Incoming == P)
      continue;  // passthrough case.
    if (!C.Block) {
      diagnoseUnderControl(S.SI, "control flow");
      return false;
    }
    ValueChain Chain = walkValueChain(C.Incoming, C.Block, Taint, P);
    if (Chain.MixedPhi) {
      diagnoseUnderControl(Chain.MixedPhi, "mixed phase/value arm");
      return false;
    }
    if (Chain.Base != P) {  // bottoms anywhere but the shared base.
      diagnoseUnderControl(S.SI, "value-arm swap-route");
      return false;
    }
    if (Chain.HasQQ) {
      // A Q+Q link (a SECOND tainted operand, `p op r` with r an independent
      // tainted register) is deferred per PRD §8.3, mirroring the flat if/else
      // value twin (ArmClassify.cpp). The recorded reason is pre-3qlq: the
      // route's method-B reverse-play threaded a single operand and could not
      // disentangle r (Rule 8 no-cloning / linear lineage).
      diagnoseUnderControl(S.SI, "value-arm swap-route");
      return false;
    }
    if (!valuePureChain(C.Block, Chain.Ops, S.Merge)) {
      diagnoseUnderControl(S.SI, "impure value arm");
      return false;
    }
    SawContent = true;
  }
  if (!SawContent) {
    diagnoseUnderControl(S.SI, "control flow");
    return false;
  }
  return true;
}

// G6 DATA-MUX — every merge incoming (cases + the straight-through default) is a
// `ConstantInt` (a compile-time multiplexer: preload + per-case XOR-delta). A
// tainted (non-constant) incoming is a quantum multiplexer (MUX-EXCH) — no
// compile-time XOR delta, and freeing superposed sources needs cswap (Rule 8) —
// decline generic.
bool proveSwitchDataMux(const SwitchShape &S, TaintSet &Taint) {
  // (MUX-EXCH / G8 — distinct tainted-handle incomings — needs no operandsAlias
  // closure here: a tainted handle is not a ConstantInt, so caseArmClass classifies
  // such an arm PHASE and proveSwitchPhase declines it (base is not a case-literal
  // const). The all-incomings-ConstantInt requirement below is precisely what keeps
  // a coherent/tainted operand out of the data-mux class.)
  if (S.StraightThrough && !isa<ConstantInt>(S.StraightThrough)) {
    diagnoseUnderControl(S.SI, "control flow");
    return false;
  }
  for (const SwitchCase &C : S.Cases) {
    if (!isa<ConstantInt>(C.Incoming)) {
      diagnoseUnderControl(S.SI, "control flow");
      return false;
    }
    // A data-mux arm contributes a compile-time CONSTANT to the merge, so a
    // well-formed arm body is EMPTY (the edge just reaches the merge). Any in-arm
    // instruction is a stray side-effecting op — a gate/measure on a sibling
    // handle the G10 scrutinee-scan does not see — that the flatten would silently
    // drop or hoist unconditionally (Rule 5/8). The phase/value proofs scan their
    // arm blocks (armPureSpine / valuePureChain); data-mux must too. Over-decline.
    if (C.Block)
      for (const Instruction &I : *C.Block)
        if (!I.isTerminator()) {
          diagnoseUnderControl(S.SI, "control flow");
          return false;
        }
  }

  // MERGE-OUT ESCAPE adjudication (was the 8mld G6 gate here; MOVED post-emit by
  // dugh, Phase 4×6). The all-ConstantInt data-mux merge is ALWAYS data-untainted,
  // so the FIRST forward propagation never saw `%out`'s onward consumers — the very
  // reason 8mld required the merge result be consumed only by a measure sink or an
  // i32 `ret` HERE (its angle backstop, non-i32-ret backstop, and handle-leak
  // backstop all in one). dugh instead re-seeds a SECOND propagation from the
  // emitted `%out` (`repropagateControlMerges`, run right after
  // `lowerControlRegions`) and re-runs the existing taint-gated nets on the now-
  // tainted onward flow:
  //   * onward QUANTUM flow (`z = rm + 1; measure z`) is re-tainted and LOWERS — the
  //     (A2) subset this bead accepts;
  //   * a `(double)(rm != k) ? a : b` ANGLE is now tainted, so the taint-gated
  //     `declineTaintedAngle` fires (the carrier-independent successor to G3);
  //   * an onward CLASSICAL escape declines via the precise `declineTaintEscapes`
  //     net (`kMsgStore` / `kMsgUnknownCallee` — including the spoof `cq_measure_evil`
  //     as an unknown callee — / `kMsgNonI32Return` for the non-i32 ret);
  //   * a NEW tainted-condition br/switch/select on `rm` declines via
  //     `declineReClassifiedControl`.
  // A measure sink / i32 `ret` (the two shapes 8mld allowed) lowers exactly as
  // before. So the detection-time G6 merge-out gate is retired: accept the data-mux
  // and let the post-emit net adjudicate its onward flow.
  (void)Taint;
  return true;  // clean constant data-mux (would-be-accept).
}

}  // namespace cq
