// TaintPropagation.cpp — Forward taint propagation from quantum rotation
// returns. The source set spans every `@cq_theta_<sfx>` declared in the
// module (14-suffix enumeration via `WidthDispatch::allSuffixes()`);
// `@cq_phi_<sfx>` is collected for lowering but is not a source;
// `@cq_measure_<sfx>` is the sink. Propagation rules are unchanged from the
// original source-collection version — only the source predicate moved to
// the `@cq_theta_<sfx>` rotation family.

#include "TaintPropagation.h"

#include "WidthDispatch.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <optional>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Set of front-end intrinsic Function*s. `SmallPtrSet` because membership
// lookups happen once per CallInst during the BB walk; pointer-keyed and
// small (≤14 thetas, ≤14 phis, ≤14 measures) makes it a perfect fit.
using FnSet = SmallPtrSet<Function *, 16>;

// Per-function pass: collect theta/phi/measure call sites in BB order and
// seed the propagation work-list with theta RESULT SSA values. Iterating
// per-function (rather than via `F->users()`) preserves the BB-order
// semantics — `RotationLowering` assigns `BirthOrder` to alloc handles in
// this same order, which `OpcodeLowering` reads back for stable Q+Q operand
// canonicalization. Phi calls are collected unconditionally but NOT seeded:
// a phi propagates taint through a tainted operand (reached as an ordinary
// user) but never introduces it, and a phi on a classical operand must
// still be collected so the lowering can delete it.
void collectAndSeed(Function &F, const FnSet &ThetaFns, const FnSet &PhiFns,
                    const FnSet &MeasureFns, TaintSet &out,
                    std::vector<Value *> &Worklist) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      Function *Callee = CI->getCalledFunction();
      if (!Callee)
        continue;
      if (ThetaFns.contains(Callee)) {
        out.ThetaCalls.push_back(CI);
        if (out.Tainted.insert(CI).second)
          Worklist.push_back(CI);
      } else if (PhiFns.contains(Callee)) {
        out.PhiCalls.push_back(CI);
      } else if (MeasureFns.contains(Callee)) {
        out.MeasureCalls.push_back(CI);
      }
    }
  }
}

// Is `I` a taint sink? Any front-end `@cq_measure_<sfx>` intrinsic in
// `MeasureFns` and the runtime lowering targets `@cqrt_measure_<W>` stop
// propagation. The runtime-name check is defensive: at propagation time
// only `@cq_measure_<sfx>` exists in the IR, but accepting both keeps the
// rule honest if a future re-entrant pass invokes propagation after
// measure lowering. The `cqrt_measure_` prefix match covers all 7 ABI
// widths uniformly (i1, i8, i16, i32, i64, f32, f64).
bool isMeasureSink(Instruction *I, const FnSet &MeasureFns) {
  auto *CI = dyn_cast<CallInst>(I);
  if (!CI)
    return false;
  Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  if (MeasureFns.contains(Callee))
    return true;
  return Callee->getName().starts_with("cqrt_measure_");
}

// Resolve every declared `@cq_theta_<sfx>` / `@cq_phi_<sfx>` /
// `@cq_measure_<sfx>` into the three FnSets. Suffixes whose intrinsic isn't
// declared in `M` are skipped — that's the early-out cue the per-function
// walk uses to leave a purely-classical module untouched. Order doesn't
// matter: `collectAndSeed` walks call sites in BB order, not symbol order.
void resolveSources(WidthDispatch &wd, FnSet &ThetaFns, FnSet &PhiFns,
                    FnSet &MeasureFns) {
  for (StringRef Sfx : wd.allSuffixes()) {
    if (Function *F = wd.thetaFn(Sfx))
      ThetaFns.insert(F);
    if (Function *F = wd.phiFn(Sfx))
      PhiFns.insert(F);
    if (Function *F = wd.measureFn(Sfx))
      MeasureFns.insert(F);
  }
}

}  // namespace

TaintSet propagate(Module &M, WidthDispatch &wd) {
  TaintSet out;
  FnSet ThetaFns;
  FnSet PhiFns;
  FnSet MeasureFns;
  resolveSources(wd, ThetaFns, PhiFns, MeasureFns);

  // No front-end intrinsics anywhere in the module → nothing to do.
  // The passthrough_no_quantum LIT fixture pins this early-out path:
  // the pass must leave a purely classical module byte-identical, and
  // crucially must NOT leak `cqrt_*` / `cq_template_*` decls.
  if (ThetaFns.empty() && PhiFns.empty() && MeasureFns.empty())
    return out;

  std::vector<Value *> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    collectAndSeed(F, ThetaFns, PhiFns, MeasureFns, out, Worklist);
  }

  // Forward taint propagation. Each tainted SSA value's user instructions
  // become tainted, except measure sinks. The work-list discipline
  // (insert-then-push) means each value is processed exactly once. A
  // tainted-operand phi is reached here as a normal user, so its result
  // taints and propagates onward — correct (Rz preserves the value).
  while (!Worklist.empty()) {
    Value *V = Worklist.back();
    Worklist.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (isMeasureSink(I, MeasureFns))
        continue;
      // WP10/R9 angle taint-discipline: the angle operand (arg 1) of a
      // cq_theta/cq_phi is a classical scalar, never a quantum handle. If `V`
      // reaches a rotation ONLY as its angle (arg 1) and not as the arg-0
      // handle, do NOT propagate taint through that edge — an angle-derived
      // value (e.g. an `if(q){rz(u,a)}else{rz(u,b)}` angle select) must stay
      // classical so it lowers as a rotation-angle choice, not quantum data.
      // Excluding only the arg-1 operand-use (not `V` globally) keeps a value
      // that is ALSO used as a handle elsewhere tainted (risk R9).
      if (auto *CI = dyn_cast<CallInst>(I)) {
        Function *Callee = CI->getCalledFunction();
        if (Callee && (ThetaFns.contains(Callee) || PhiFns.contains(Callee)) &&
            CI->arg_size() >= 2 && CI->getArgOperand(1) == V &&
            CI->getArgOperand(0) != V)
          continue;  // V is used here only as the classical angle; skip edge.
      }
      if (out.Tainted.insert(I).second)
        Worklist.push_back(I);
    }
  }

  return out;
}

namespace {

// The exact diagnostic strings the taint-escape guard owns
// (test_C_libtooling-bxv). The negative fixtures mirror each one
// CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_taint_escape_opaque_call.ll    → kMsgUnknownCallee
//   * lowering_reject_taint_escape_deep_arg.ll       → kMsgUnknownCallee
//   * lowering_reject_taint_escape_inmodule_body.ll  → kMsgUnknownCallee
//   * lowering_reject_taint_escape_indirect_call.ll  → kMsgUnknownCallee
//   * lowering_reject_taint_escape_store_global.ll   → kMsgStore
//   * lowering_reject_taint_escape_gep.ll            → kMsgOther
constexpr char kMsgUnknownCallee[] =
    "cq taint escape: tainted value consumed by an unknown callee";
constexpr char kMsgStore[] = "cq taint escape: tainted value stored to memory";
constexpr char kMsgOther[] =
    "cq taint escape: tainted value reaches an unsupported instruction";

// Loud `DiagnosticInfoUnsupported(DS_Error)` with the offending instruction's
// `!dbg` — the one diagnostic surface the whole pass speaks (same idiom as
// FreePoint::diagnose and RotationLowering::diagnoseUnsupported); `opt` exits
// non-zero, which the negative LIT fixtures invert with `RUN: not`.
void diagnoseEscape(Instruction *I, StringRef Msg) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(), Msg, I->getDebugLoc()));
}

// Does `I` read at least one tainted SSA value? Operand-level test (not
// result-taint): the escape is the EDGE from a quantum value into a consumer
// the lowering cannot rewrite. For a CallBase, `operands()` includes the
// called operand, so an indirect call THROUGH a tainted pointer also trips.
bool readsTaintedValue(const Instruction &I, const TaintSet &taint) {
  for (const Value *Op : I.operands())
    if (taint.Tainted.count(const_cast<Value *>(Op)))
      return true;
  return false;
}

}  // namespace

void declineTaintEscapes(Module &M, const TaintSet &taint) {
  // Exact membership for the collected front-end intrinsic call sites —
  // never name-prefix matching on the ACCEPT side (a user function named
  // `cq_theta_evil` must not slip through). `propagate` collected precisely
  // the calls whose callee resolved through WidthDispatch's 42-name surface.
  SmallPtrSet<const CallInst *, 32> IntrinsicCalls;
  IntrinsicCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  IntrinsicCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  IntrinsicCalls.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());

  // BB-order walk (deterministic diagnostic order, like
  // OpcodeLowering::declineStaleRecordOps). One diagnostic per offending
  // instruction. The KNOWN-CONSUMER list below is everything a later stage
  // provably owns — each entry cites its owner; ANYTHING else that reads a
  // tainted value is an unproven shape and declines loudly (Prime Directive:
  // over-declining is always safe, over-accepting is a silent miscompile).
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // 1. Calls/invokes FIRST (an InvokeInst is also a terminator — it must
        //    not fall through to the terminator skip below).
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          // 1a. Front-end intrinsic call sites: arg-0 handle slot is lowered
          //     (RotationLowering / MeasureLowering); the arg-1 ANGLE slot is
          //     OWNED by RotationLowering::declineTaintedAngle and
          //     ArmClassify::taintedAngleGate (test_C_libtooling-659) — both
          //     run later and still fire, so this guard skips the whole call.
          if (auto *CI = dyn_cast<CallInst>(CB))
            if (IntrinsicCalls.count(CI))
              continue;
          const Function *Callee = CB->getCalledFunction();
          StringRef N = Callee ? Callee->getName() : StringRef();
          // 1b. The pass's own runtime symbols. At guard time (pre-lowering)
          //     none should exist; accepting them anyway keeps the rule honest
          //     for a re-entrant caller (same defensive stance as
          //     `isMeasureSink`'s `cqrt_measure_` prefix above) and for the
          //     `runOnFunction` unit shim run after a sibling was lowered.
          // 1c. `cq_invert_*`: the Phase-7 manual-inversion handoff — a
          //     RECOGNIZED escape, the same set FreePoint silently skips
          //     (isRecognizedEscapeUser; pinned ACCEPT fixture
          //     lowering_uncompute_escape_invert.ll).
          if (N.starts_with("cqrt_") || N.starts_with("cq_template_") ||
              N.starts_with("cq_invert_"))
            continue;
          // 1d. Everything else — opaque extern, in-module body (Phase 6
          //     clone-on-taint is NOT implemented; a visible body is exactly
          //     as un-lowered as a declaration), llvm.* intrinsic (e.g. the
          //     -O1 `llvm.smin` min/max idiom), or indirect (null callee) —
          //     is an UNKNOWN callee: after RAUW it would read the i32
          //     runtime handle tag, verify-clean.
          if (readsTaintedValue(I, taint))
            diagnoseEscape(&I, kMsgUnknownCallee);
          continue;
        }
        // 2. The four lowerOps instruction classes — owned by Arith/Compare/
        //    CastLowering, whose drivers diagnose their own unsupported
        //    members loudly ("no template for opcode ... in tainted context",
        //    e.g. the inttoptr probe; fixture lowering_icmp_qq_negative.ll).
        if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) ||
            isa<CmpInst>(I) || isa<CastInst>(I))
          continue;
        // 3. Control-flow value merges/muxes — owned by ControlDetect (a
        //    tainted-condition select/switch/branch accepts as a swap-route
        //    region or declines "... under quantum control") and, for the
        //    CLASSICAL-condition leftovers, by `declineClassicalMuxes`, which
        //    runs after `lowerControlRegions` (test_C_libtooling-wi5 — the
        //    Phase-5 FreePoint net is NOT an owner: its "unrecognized user"
        //    reject is bypassed when the base handle is Measured / Escaped /
        //    `main`-resident or non-terminal). Declining them here would
        //    re-own the tainted-condition shapes whose fixtures pin the
        //    "... under quantum control" diagnostics character-for-character.
        if (isa<PHINode>(I) || isa<SelectInst>(I))
          continue;
        // 4. Terminators: a tainted `br`/`switch` condition is ControlDetect's;
        //    `ret` of a tainted handle is FreePoint's RECOGNIZED Escaped case —
        //    the caller owns the handle (pinned ACCEPT fixtures
        //    lowering_uncompute_escape_return.ll, control_swap_ifelse_escape.ll).
        if (I.isTerminator())
          continue;
        if (!readsTaintedValue(I, taint))
          continue;
        // 5. Unowned readers of a tainted value. A store exits the SSA-only
        //    taint domain into memory (a later load reads the handle tag,
        //    untainted); everything else (getelementptr, atomicrmw, freeze,
        //    va_arg, ...) has no reversible-lowering story at all. Both are
        //    bypassed by the Phase-5 net when the handle is ALSO measured
        //    (FreePoint returns Measured before its FirstUnrecognized check),
        //    so the decline must happen HERE, pre-lowering.
        diagnoseEscape(&I, isa<StoreInst>(I) ? kMsgStore : kMsgOther);
      }
    }
  }
}

namespace {

// The exact diagnostic strings the classical-mux guard owns
// (test_C_libtooling-wi5). The negative fixtures mirror each one
// CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_classical_mux_select_measured.ll     → kMsgClassicalSelect
//   * lowering_reject_classical_mux_select_escape.ll       → kMsgClassicalSelect
//   * lowering_reject_classical_mux_select_alltainted_main.ll
//                                                          → kMsgClassicalSelect
//   * lowering_reject_classical_mux_phi_measured.ll        → kMsgClassicalPhi
constexpr char kMsgClassicalSelect[] =
    "cq taint escape: tainted value muxed by a classical-condition select";
constexpr char kMsgClassicalPhi[] =
    "cq taint escape: tainted value muxed by a classical-condition phi";

// ───────────────────────────────────────────────────────────────────────────
// One-register merge-phi lift (test_C_libtooling-5j5).
//
// The natural "classical if around a quantum gate" program
//     if (classical_c) q = cq_phi(q, theta);  ...use(q)...
// survives `clang -O1` as a merge phi whose two incomings are DISTINCT SSA
// values denoting the SAME physical register:
//     merge: %p = phi i32 [ %q2, %arm ], [ %q, %entry ]   ; %q2 = cq_phi(%q,θ)
// (verified 2026-06-10 on both the `if` and the ternary form — clang cannot
// speculate the opaque cq_phi call, so BOTH compile to this branch+phi shape,
// never to a select). Rotation lowering is IN PLACE: `RotationLowering` emits
// the gate at the call's position ON THE OPERAND HANDLE and RAUWs the result
// to that same operand (cqrt_rz for cq_phi; ry-only on the existing handle for
// a tainted-operand chained cq_theta). So after lowering, EVERY incoming of
// such a phi is the same i32 handle — the phi is a pure SSA renaming that
// never touches the register. RAUW'ing it to the wire's base SSA value and
// erasing it reduces the module to the phi-less form the pipeline ALREADY
// accepts (verified: gate-in-classical-arm + use-of-base lowers to
// rz-inside-the-arm + measure-on-handle, in both main and non-main).
//
// Rule-13 trace/statevector clearance (the accept argument): the condition is
// CLASSICAL — each shot executes exactly one path; no superposed control, no
// flag, no routing, no cloning. The lift adds, moves, and removes NO gate;
// only an SSA name disappears. Per-shot the emitted trace is exactly the gate
// stream of the executed source path (gate fires iff its arm runs), which is
// what the user wrote. The only hazard is a RECORD mismatch — an edge whose
// incoming SSA value denotes a register history that some path entering the
// merge through that edge does not physically have. The predicate below
// makes that impossible:
//   (3) every incoming resolves through the in-place gate wire (arg-0 of
//       COLLECTED cq_theta/cq_phi call sites — exact CallInst membership,
//       never name matching, this is an ACCEPT predicate) to ONE common base;
//       a classical-operand theta MINTS a fresh register, so the walk stops
//       there; template results (add/mul/...) mint fresh rails
//       (`ArithLowering` RAUWs to the template CALL result) and never resolve
//       — a derived-value arm stays declined;
//   (6) every chain gate sits in ITS edge's incoming block, so entering via
//       that edge implies the chain ran, this traversal, in order;
//   (7a) no chain gate can reach the OTHER edge's terminator — kills every
//       path that fires the gate and then enters the merge claiming a record
//       without it (the loop-iteration-2 stale-base path, fixture
//       lowering_reject_classical_mux_phi_loop.ll);
//   (7b) the gate's own edge, once taken, can never lead back to the gate —
//       every cycle through the gate exits its block through the checked
//       terminator, so no path applies the chain twice while the incoming
//       claims one application.
// A SELECT is categorically NOT liftable: SSA forces a select's operands to
// dominate it, so a gate-call incoming has ALREADY FIRED unconditionally when
// the select executes — the "untaken" incoming names a pre-gate record the
// physical register no longer holds (undoing an applied rotation on the one
// register is non-unitary; it would need cloning). Accepting it would compile
// "rotate iff c" IR semantics to "always rotate": the exact verify-clean
// silent-miscompile class. Pinned: lowering_reject_classical_mux_select_onereg.ll.
// ───────────────────────────────────────────────────────────────────────────

// The backward in-place-gate wire resolution: peel collected cq_theta/cq_phi
// call sites through their arg-0 handle while that handle is tainted (a
// tainted-operand rotation is in-place — its result RAUWs to its operand).
// Stops at a classical-operand theta (the register's mint point — the call
// itself is the base), at any non-gate value (phi/select/template/argument),
// and never steps through another mux (nested diamonds resolve to distinct
// phi bases and decline — conservative, documented).
struct WireChain {
  Value *Base = nullptr;
  // Gate calls peeled, incoming-value-first. Empty when the incoming IS the
  // base (the pre-gate straight edge, or the degenerate same-value merge).
  SmallVector<CallInst *, 4> Gates;
};

WireChain resolveWireBase(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                          const TaintSet &taint) {
  WireChain Chain;
  while (auto *CI = dyn_cast<CallInst>(V)) {
    if (!GateCalls.count(CI))
      break;  // not a collected rotation call site — V is the base.
    Value *Handle = CI->getArgOperand(0);
    if (!taint.Tainted.count(Handle))
      break;  // classical-operand theta: the mint point IS the base.
    Chain.Gates.push_back(CI);
    V = Handle;
  }
  Chain.Base = V;
  return Chain;
}

// Defensive ownership check on a terminator: the lift only fires under
// CLASSICAL control. Every tainted-condition br/switch/select was adjudicated
// by ControlDetect before this guard runs (accept → SwapRouteEmit erased the
// merge phi; decline → opt already exited at that DS_Error), so under `opt`
// this never sees a tainted condition — but an in-process host that continues
// past a ControlDetect decline must NOT have this lift mutate a shape another
// owner declined (same defensive stance as the tainted-condition `continue`
// on the select branch below). Exotic terminators (invoke/indirectbr/...)
// are unproven shapes — not acceptable.
bool terminatorIsClassical(const Instruction *T, const TaintSet &taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return !BI->isConditional() || !taint.Tainted.count(BI->getCondition());
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return !taint.Tainted.count(SI->getCondition());
  return false;
}

// Try the one-register lift on a LIVE tainted-reading phi. Returns true iff
// the phi was PROVEN a pure renaming of one register's per-path current
// record, RAUW'd to the wire base, scrubbed from the taint set, and erased —
// the caller then has nothing to diagnose. Any unproven branch returns false
// and the caller declines loudly, exactly as before the lift (Prime
// Directive: over-declining is always safe).
bool liftOneRegisterMergePhi(PHINode *Phi, TaintSet &taint,
                             const SmallPtrSetImpl<CallInst *> &GateCalls,
                             std::optional<DominatorTree> &DT) {
  // (1) Exactly the canonical 2-incoming diamond/if-else join (the -O1 shape;
  //     ControlDetect's `soleMergePhi` carries the same discipline). N-ary
  //     classical switch merges are per-edge provable by the same argument
  //     but unfixtured — deliberate conservatism, lift later if needed.
  if (Phi->getNumIncomingValues() != 2)
    return false;
  // (2) Every incoming tainted. A mixed tainted/untainted mux
  //     ("handle-or-literal-5") is a real data mux on the handle domain and
  //     stays declined (pinned: lowering_reject_classical_mux_phi_measured.ll).
  for (Value *V : Phi->incoming_values())
    if (!taint.Tainted.count(V))
      return false;
  // (3) Both incomings resolve to ONE base. Taint only ever holds
  //     Instructions, so a matching base is an Instruction; the Phi-as-its-own
  //     -base degenerate (self-incoming cycle) is rejected explicitly.
  WireChain C0 = resolveWireBase(Phi->getIncomingValue(0), GateCalls, taint);
  WireChain C1 = resolveWireBase(Phi->getIncomingValue(1), GateCalls, taint);
  if (C0.Base != C1.Base || C0.Base == Phi)
    return false;  // two registers (or a derived fresh rail) — real mux.
  auto *BaseI = dyn_cast<Instruction>(C0.Base);
  if (!BaseI)
    return false;
  // (4) Dominator tree — built lazily, once per function (same idiom as
  //     `declineStaleRecordOps`).
  Function &F = *Phi->getFunction();
  if (!DT)
    DT.emplace(F);
  // (5) Defensive ownership: the join's deciding branch (the merge's
  //     immediate dominator) and both incoming preds' terminators must be
  //     classical (see terminatorIsClassical). Unreachable merge → decline.
  DomTreeNode *Node = DT->getNode(Phi->getParent());
  if (!Node || !Node->getIDom())
    return false;
  if (!terminatorIsClassical(Node->getIDom()->getBlock()->getTerminator(),
                             taint))
    return false;
  for (unsigned i = 0; i < 2; ++i)
    if (!terminatorIsClassical(Phi->getIncomingBlock(i)->getTerminator(),
                               taint))
      return false;
  // RAUW validity: base must dominate every current phi user. SSA already
  // implies it (base dominates each incoming edge's use point, hence every
  // path into the merge), but the explicit check is cheap insurance.
  if (!DT->dominates(BaseI, Phi))
    return false;
  // (6)+(7) Per-edge conditional-execution proof — see the block comment.
  const WireChain *Chains[2] = {&C0, &C1};
  for (unsigned i = 0; i < 2; ++i) {
    BasicBlock *Self = Phi->getIncomingBlock(i);
    BasicBlock *Other = Phi->getIncomingBlock(1 - i);
    for (CallInst *G : Chains[i]->Gates) {
      // (6) Single-block arm: the whole chain lives in this edge's pred, so
      //     taking the edge implies the chain ran (block-local SSA order).
      //     A chain call OUTSIDE the pred (a pre-branch gate on the wire)
      //     makes the other edge's base record stale — decline (pinned:
      //     lowering_reject_classical_mux_phi_crossblock_chain.ll).
      if (G->getParent() != Self)
        return false;
      // (7a) No path may fire this gate and then enter the merge through the
      //      OTHER edge, whose incoming claims a record without it (the
      //      classical-loop iteration-2 staleness; pinned:
      //      lowering_reject_classical_mux_phi_loop.ll).
      if (isPotentiallyReachable(G, Other->getTerminator(), nullptr, &*DT))
        return false;
      // (7b) Once this edge is taken the gate must never re-fire: every cycle
      //      through G leaves its block via this terminator, so this check
      //      closes the applied-twice/recorded-once path.
      if (isPotentiallyReachable(Self->getTerminator(), G, nullptr, &*DT))
        return false;
    }
  }
  // ACCEPT. The phi is a no-op on the handle domain: RAUW to the base (after
  // rotation lowering every incoming IS this base's i32 handle), scrub the
  // erased value from the taint set (`SwapRouteEmit::scrubTaint` precedent —
  // a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it), and erase. Downstream stages now see the
  // already-accepted phi-less shape; every later guard (tainted-angle,
  // FreePoint post-dominator discipline, stale-skip) still adjudicates it.
  Phi->replaceAllUsesWith(C0.Base);
  taint.Tainted.erase(Phi);
  Phi->eraseFromParent();
  return true;
}

}  // namespace

void declineClassicalMuxes(Module &M, TaintSet &taint) {
  // BB-order walk, one diagnostic per offending mux (deterministic order,
  // same discipline as declineTaintEscapes). Runs AFTER `lowerControlRegions`:
  // every tainted-condition construct has already been adjudicated by
  // ControlDetect (declined → opt exited at that first DS_Error; accepted →
  // SwapRouteEmit RAUW'd + erased + taint-scrubbed the merge phi), so a
  // surviving select/phi over tainted data is CLASSICALLY conditioned, and no
  // later stage owns it — decline loudly (Prime Directive). Confirmed silent
  // pre-guard for all five bypass shapes: base-also-measured, base-escaped
  // (`ret`), `main`-resident, non-terminal base, and the all-tainted
  // distinct-handle mux (which rules out the "mixed-incomings-only" variant
  // of this guard — see the wi5 trail).
  //
  // ONE deliberate accept (test_C_libtooling-5j5): the live merge PHI that is
  // a proven pure renaming of ONE register's per-path current record — the
  // natural `if (classical_c) q = cq_phi(q, θ); use(q)` shape — is RAUW'd to
  // its wire base and erased (see liftOneRegisterMergePhi above for the full
  // predicate and the Rule-13 clearance). Selects are NEVER lifted: a select's
  // gate-call incoming dominates it, so the gate has already fired
  // unconditionally and the untaken incoming names a record the register no
  // longer holds.
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily, only when a lift candidate exists in `F` (same idiom as
    // declineStaleRecordOps).
    std::optional<DominatorTree> DT;
    for (BasicBlock &BB : F) {
      // early-inc: an accepted phi is erased mid-walk.
      for (Instruction &I : llvm::make_early_inc_range(BB)) {
        if (auto *Sel = dyn_cast<SelectInst>(&I)) {
          // Tainted condition → ControlDetect's, never ours (defensive: under
          // opt the earlier "select under quantum control" decline already
          // exited; an in-process host that continues past it must still not
          // see a second owner claim the same shape).
          if (taint.Tainted.count(Sel->getCondition()))
            continue;
          if (taint.Tainted.count(Sel->getTrueValue()) ||
              taint.Tainted.count(Sel->getFalseValue()))
            diagnoseEscape(Sel, kMsgClassicalSelect);
          continue;
        }
        if (auto *Phi = dyn_cast<PHINode>(&I)) {
          // A DEAD phi is a pure live-range extender (no reader → no mux →
          // nothing downstream can read the wrong value): FreePoint's pinned
          // benign-merge domain (isBenignLiveRangePhi; ACCEPT fixture
          // lowering_uncompute_branch_botharms.ll).
          if (Phi->use_empty())
            continue;
          if (!readsTaintedValue(*Phi, taint))
            continue;
          // The one-register renaming lifts (RAUW + erase); every other live
          // tainted-reading phi — mixed handle/literal, distinct registers,
          // derived fresh-rail incomings, cross-block chains, loop-reachable
          // merges — is declined: its record/uncompute story is
          // path-dependent and unproven.
          if (liftOneRegisterMergePhi(Phi, taint, GateCalls, DT))
            continue;
          diagnoseEscape(Phi, kMsgClassicalPhi);
          continue;
        }
      }
    }
  }
}

}  // namespace cq
