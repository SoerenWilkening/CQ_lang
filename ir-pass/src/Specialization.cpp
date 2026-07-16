// Specialization.cpp — the Phase 6 specialization driver (step 14, DD-1).

#include "Specialization.h"

#include "BennettWrap.h"
#include "CompareLowering.h"
#include "ControlledSymbols.h"
#include "IntrinsicLowering.h"
#include "OpcodeLowering.h"
#include "OpcodeSupport.h"
#include "SpecializeClone.h"
#include "SpecializePlan.h"
#include "SpecializeReject.h"
#include "SpecializeSeed.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <string>
#include <utility>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// A forward `cq_template_*` data call minted into the clone (exclude the void
// `_unc` / fresh-minting `_inv` adjoint twins, though none exist at capture time
// — BennettWrap mints them after). Used to build the forward stream + scratch
// rails for the Bennett wrap.
bool isForwardTemplate(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return false;
  StringRef N = F->getName();
  return N.starts_with("cq_template_") && !N.ends_with("_unc") &&
         !N.ends_with("_inv");
}

// 5po2: lower each LIFTABLE tainted `select` in `Clone` to a 4.4 controlled-XOR
// copy, run in `buildClone` AFTER `seedClone`/the inner-clone drain and BEFORE
// `lowerOps` (so the fresh `cq_template_icmp` flag mint is an ordinary data
// template `lowerOps`/the wrap already understand, and the stock `icmp` feeding
// the select is consumed before `lowerOps` would lower a spurious dead compare).
//
// The accepted shape (`SpecializeReject::isLiftableSelect`) is
// `select(icmp(param, k), param, 0)`: condition and true arm share the SAME param,
// so they share taint. When that param is TAINTED this emits the reversible
// embedding `out = flag ? param : 0`:
//
//     flag = cq_template_icmp_<pred>_i32_hl(param, k)   ; kept LIVE (no local strip)
//     out  = cqrt_alloc_i32(0)                           ; the |0> result rail
//     cqrt_copy_i32_controlled(flag, param, out)         ; out = flag ? param : 0
//
// The flag is NOT stripped/freed here (unlike the top-level 4.4 emitter): the
// Bennett wrap reverses the forward stream `[flag-mint, controlled-copy]` — the
// self-inverse copy zeroes `out`, the `icmp _unc` zeroes `flag` — then frees both.
// `CopyOps` collects the void copies (ForwardStream-only) and `OutRails` the out
// allocs (ScratchRails-only) for the capture in `buildClone`.
//
// When the shared param is CLASSICAL the select is a plain classical mux (both
// arms/condition classical by the shape gate) — left UNTOUCHED for the backend,
// never promoted to a quantum controlled copy (Rule: taint is the only Q/C
// boundary). The gate's same-param requirement forecloses the mixed
// classical-flag-over-quantum-data case, so no loud decline is reachable there.
//
// kmdc adds the FP two-arm branch: a `select(icmp, <derived fp>, <derived fp>)`
// (`isLiftableFpSelect`) — the canonical fabs `(x<0)?-x:x`. It emits the full 4.4
// stream over an fp `cqrt_copy_f<W>_controlled` + an fp |0> rail: copy the TRUE
// arm on flag, then the ¬flag `cqrt_x`-bracketed copy of the FALSE arm. The two
// `cqrt_x` brackets are captured into `XBrackets` (ForwardStream-only) — WITHOUT
// this the Bennett reverse would silently drop them (`isForwardTemplate` matches
// only `cq_template_` names, not `cqrt_x`), replaying `[copy_F, copy_T]` at the
// wrong polarity and leaving `out = arm_T ^ arm_F ≠ 0` — a dirty free / hidden
// measurement (Rule 6), verify-clean (the kmdc CONFIRMED-hazard). SAFE without an
// angle fence: a clone body is rotation-free (see `isLiftableFpSelect`), so the fp
// value never reaches a rotation angle. Unlike the top-level 4.4 emitter this
// keeps the flag LIVE (no local strip/free) for the Bennett reverse.
void lowerCloneSelect(Function &Clone, TaintSet &cloneTaint, WidthDispatch &wd,
                      SmallPtrSetImpl<CallInst *> &CopyOps,
                      SmallPtrSetImpl<Value *> &OutRails,
                      SmallPtrSetImpl<CallInst *> &XBrackets) {
  ControlledSymbols csyms(*Clone.getParent(), wd);
  SmallVector<SelectInst *, 4> Selects;  // snapshot before mutation
  for (BasicBlock &BB : Clone)
    for (Instruction &I : BB)
      if (auto *SI = dyn_cast<SelectInst>(&I))
        Selects.push_back(SI);

  // Shared tail: mint the flag LIVE, alloc the |0> out rail (joins cloneTaint so
  // ReturnTainted holds), then let `emit` lay down the per-shape copies before the
  // select, RAUW the select to `out`, and erase the select + now-dead compare.
  for (SelectInst *SI : Selects) {
    auto *Cond = dyn_cast<ICmpInst>(SI->getCondition());
    if (!Cond)
      continue;  // not a lifted select shape (defensive — classify proved it).
    const bool IsFp = SI->getType()->isFloatingPointTy();

    // Per-shape taint re-proof (the SHAPE gate in SpecializeReject is taint-blind).
    if (!IsFp) {
      // Integer 5po2: true arm = the tainted param; classical → classical mux, leave.
      if (!isa<Argument>(SI->getTrueValue()) ||
          !cloneTaint.Tainted.count(SI->getTrueValue()))
        continue;
    } else {
      // FP kmdc two-arm: re-prove the condition AND BOTH arms tainted. All-tainted
      // → emit; whole-classical → leave for the backend; MIXED → loud decline (a
      // classical flag over quantum fp data, or vice versa, has no proven lowering).
      bool CondT = cloneTaint.Tainted.count(Cond->getOperand(0)) ||
                   cloneTaint.Tainted.count(Cond->getOperand(1));
      bool TrueT = cloneTaint.Tainted.count(SI->getTrueValue());
      bool FalseT = cloneTaint.Tainted.count(SI->getFalseValue());
      if (!CondT && !TrueT && !FalseT)
        continue;  // whole-classical fp select — leave for the backend.
      if (!(CondT && TrueT && FalseT)) {
        Clone.getContext().diagnose(DiagnosticInfoUnsupported(
            Clone,
            "cq specialization: mixed classical/quantum fp select under quantum "
            "lift",
            SI->getDebugLoc()));
        continue;  // loud decline (opt exits non-zero) — never a partial emit.
      }
    }

    StringRef Abi = abiWidthFromType(SI->getType());  // "i32" | "f32" | "f64"
    FunctionCallee Alloc = wd.allocFn(Abi);
    Type *RailTy = wd.llvmWidthType(Abi);
    FunctionCallee Copy =
        IsFp ? csyms.copyControlledFpFn(Abi) : csyms.copyControlledFn(Abi);
    if (!Alloc || !RailTy || !Copy)
      continue;  // unsupported width past the gate — leave for the loud backstop.
    const DebugLoc DL = SI->getDebugLoc();
    IRBuilder<> B(SI);  // every stream call lands immediately before the select.
    auto stamp = [&](CallInst *C) {
      if (DL)
        C->setDebugLoc(DL);
    };

    // 1. MINT the flag from the compare — kept LIVE (the Bennett reverse plays its
    //    `_unc`, NOT a local strip). Reuses `lowerCompareToFlag` (Rule 14).
    Value *Flag = lowerCompareToFlag(Cond, wd, cloneTaint, /*qqWidth=*/{},
                                     /*inverse=*/false, /*before=*/SI);
    if (!Flag)
      continue;  // lowerCompareToFlag already diagnosed.

    // 2. ALLOC the |0> out rail (i32 or fp). It joins `cloneTaint` so the RAUW'd
    //    select result classifies as a quantum handle / ReturnTainted holds.
    CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "cqq.sel");
    stamp(Out);
    cloneTaint.Tainted.insert(Out);
    cloneTaint.BirthOrder[Out] = cloneTaint.NextBirth++;
    OutRails.insert(Out);

    // 3. The controlled copies. Tainted arms are threaded AS-IS — the later
    //    (taint-gated) `lowerOps` RAUWs their fp producers (sitofp/fneg) to i32
    //    handles, so the copy's `src` operand becomes well-typed (the deferred-RAUW
    //    the top-level 4.4 emitter also relies on).
    if (!IsFp) {
      // out = flag ? param : 0 — one copy (false arm is const 0, no ¬flag bracket).
      CallInst *CC = B.CreateCall(Copy, {Flag, SI->getTrueValue(), Out});
      stamp(CC);
      CopyOps.insert(CC);
    } else {
      // out = flag ? T : F — copy T on flag, then the ¬flag `cqrt_x`-bracketed copy
      // of F. The bracket encloses ONLY the second copy (SelectMergeEmit §16.3
      // order); both `cqrt_x` are captured into `XBrackets` so the Bennett reverse
      // re-brackets them (the kmdc dropped-bracket hazard).
      CallInst *CopyT = B.CreateCall(Copy, {Flag, SI->getTrueValue(), Out});
      stamp(CopyT);
      CopyOps.insert(CopyT);
      CallInst *X1 = B.CreateCall(csyms.xFn(), {Flag});
      stamp(X1);
      XBrackets.insert(X1);
      CallInst *CopyF = B.CreateCall(Copy, {Flag, SI->getFalseValue(), Out});
      stamp(CopyF);
      CopyOps.insert(CopyF);
      CallInst *X2 = B.CreateCall(csyms.xFn(), {Flag});
      stamp(X2);
      XBrackets.insert(X2);
    }

    // 4. REWIRE + erase the select and its now-dead condition compare.
    SI->replaceAllUsesWith(Out);
    cloneTaint.Tainted.erase(SI);
    cloneTaint.BirthOrder.erase(SI);
    SI->eraseFromParent();
    if (Cond->use_empty()) {
      cloneTaint.Tainted.erase(Cond);
      cloneTaint.BirthOrder.erase(Cond);
      Cond->eraseFromParent();
    }
  }
}

// Erase `V` and its forward cone of consumers that lose ALL taint once `V` is
// scrubbed (§2.7 return-taint correction for a ReturnTainted=false clone). A
// consumer that still reads an independently-tainted operand keeps its taint.
void scrubForwardCone(Value *Root, TaintSet &taint,
                      const SmallPtrSetImpl<const Value *> &TaintedSources) {
  std::vector<Value *> Worklist;
  auto scrub = [&](Value *V) {
    taint.Tainted.erase(V);
    taint.BirthOrder.erase(V);
    if (auto *I = dyn_cast<Instruction>(V))
      taint.StaleDeclined.erase(I);
  };
  scrub(Root);
  Worklist.push_back(Root);
  while (!Worklist.empty()) {
    Value *V = Worklist.back();
    Worklist.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !taint.Tainted.count(I))
        continue;
      // A value that is its OWN taint source — a primary `cq_theta` result, or
      // another specialized-call result that legitimately carries taint — must
      // never be scrubbed transitively (its taint does NOT derive from the
      // scrubbed root). Stopping here also prunes its whole downstream cone from
      // the walk, so a fresh `cq_theta(%r, θ)` seeded from a scrubbed classical
      // `%r` keeps the qubit and every consumer of it tainted (the over-scrub
      // the Rule-13 axis-(g) probe caught). NOT `cq_phi`: a `cq_phi` on a
      // now-classical operand is deleted (Rule 3), so it is correctly scrubbed.
      if (TaintedSources.count(I))
        continue;
      bool HasOtherTaintedOperand = false;
      for (Value *Op : I->operands())
        if (taint.Tainted.count(Op)) {
          HasOtherTaintedOperand = true;
          break;
        }
      if (HasOtherTaintedOperand)
        continue;  // tainted via another path — keep.
      scrub(I);
      Worklist.push_back(I);
    }
  }
}

// Synthesize the void uncompute TWIN of a Bennett-wrapped clone (Phase 6.3).
// `Clone` realizes the reversible embedding `|x⟩|0⟩_out → |x⟩|f(x)⟩_out` (forward
// gates → `out = cqrt_alloc_<W>(0)` → `cqrt_copy(result, out)` → reverse → free
// scratch → `ret out`). Its adjoint, needed when `Clone` is called inside another
// clone, is the void `@<clone>_unc(i32 out, <clone params>)` that runs
// `out ^= f(x)` (recompute scratch → `cqrt_copy(result, out_param)` → reverse →
// free scratch → `ret void`): since the passed `out` already holds `f(x)`, the
// XOR-copy zeroes it, the borrowed inputs are read-only-preserved, and the
// twin's own scratch is allocated-and-freed internally. The twin is the wrapped
// `Clone` with exactly two edits — the internal `out` alloc is replaced by the
// new leading `out` parameter, and the `ret <handle>` becomes `ret void`. A
// nested clone call inside `Clone` rides along: its forward call + its own twin
// call (already emitted by `Clone`'s wrap) are cloned verbatim, so the adjoint
// composes to any depth. Only ever called for a `ReturnTainted` clone (the
// `out`-alloc is then guaranteed present, DD-3).
Function *synthUncomputeTwin(Function &Clone) {
  Module *M = Clone.getParent();
  LLVMContext &Ctx = Clone.getContext();

  SmallVector<Type *, 4> ParamTys;
  ParamTys.push_back(Clone.getReturnType());  // out: the clone's i32 return type.
  for (Argument &A : Clone.args())
    ParamTys.push_back(A.getType());
  FunctionType *FT =
      FunctionType::get(Type::getVoidTy(Ctx), ParamTys, /*isVarArg=*/false);
  Function *Twin = Function::Create(FT, GlobalValue::InternalLinkage,
                                    (Clone.getName() + "_unc").str(), M);

  // Map Clone's args → Twin's args[1..]; Twin arg0 is the new `out`.
  ValueToValueMapTy VMap;
  auto TwinArg = Twin->arg_begin();
  TwinArg->setName("out");
  ++TwinArg;
  for (Argument &A : Clone.args()) {
    TwinArg->setName(A.getName());
    VMap[&A] = &*TwinArg;
    ++TwinArg;
  }
  SmallVector<ReturnInst *, 1> Returns;
  CloneFunctionInto(Twin, &Clone, VMap,
                    CloneFunctionChangeType::LocalChangesOnly, Returns);
  // The twin inherits `Clone`'s attributes via the clone; `Clone` was already
  // stripped by `cloneFor`, but re-strip defensively (the twin is void/side-
  // effecting and must never be treated as a deletable pure call).
  stripStaleClassicalAttrs(Twin);

  // The wrapped clone returns its `out` alloc; in the twin, redirect that alloc
  // to the `out` parameter and drop it, then make the terminator `ret void`.
  ReturnInst *Ret = Returns.front();
  if (auto *OutAlloc = dyn_cast<CallInst>(Ret->getReturnValue())) {
    OutAlloc->replaceAllUsesWith(Twin->getArg(0));
    OutAlloc->eraseFromParent();
  }
  ReturnInst::Create(Ctx, /*retVal=*/nullptr, Ret);
  Ret->eraseFromParent();
  return Twin;
}

// Idempotently ensure `Clone`'s void uncompute twin exists (synthesize once,
// reuse across every outer clone that calls `Clone`). Always runs BEFORE the
// outer wrap's `emitInverseChain` mints the `@<clone>_unc` call, so the symbol
// resolves to this definition, never a dangling declaration.
void ensureTwin(Function *Clone) {
  std::string TName = (Clone->getName() + "_unc").str();
  if (Function *F = Clone->getParent()->getFunction(TName))
    if (!F->isDeclaration())
      return;
  synthUncomputeTwin(*Clone);
}

// Retarget `Site` to `Clone`. USUALLY `setCalledFunction` suffices — but when the
// clone's RETURN type differs from the call's own result type (an fp-tainted return
// rewritten to an i32 handle, bd 3c6m.54), the `CallInst`'s Value type is IMMUTABLE
// (`setCalledFunction` updates only the called operand + FunctionType), so a stale
// fp result would flow to the consumer (e.g. `cq_measure_f64` reads an fp, not an
// i32 handle). Replace the call with a fresh i32-returning one and cross-type RAUW
// the old fp result → the new i32 result (laundered by the downstream measure/op
// lowering, exactly like the theta handle RAUW). The arg operands are carried
// verbatim (a still-fp arg becomes its i32 handle later, via lowerRotations/
// lowerOps — the same transient-mismatch the plain `setCalledFunction` arg path
// already relies on). Updates `Site` in place to the live call.
void retargetSite(CallInst *&Site, Function *Clone) {
  if (Site->getType() == Clone->getReturnType()) {
    Site->setCalledFunction(Clone);
    return;
  }
  SmallVector<Value *, 8> Args(Site->args());
  IRBuilder<> B(Site);
  CallInst *NewCall = B.CreateCall(Clone, Args);
  if (DebugLoc DL = Site->getDebugLoc())
    NewCall->setDebugLoc(DL);
  Site->replaceAllUsesWith(NewCall);  // cross-type: old fp result → new i32 handle.
  NewCall->takeName(Site);
  Site->eraseFromParent();
  Site = NewCall;
}

// Forward decl — `buildClone` and `resolveSite` are mutually recursive (the
// depth-first transitive worklist).
SpecRecord buildClone(CallInst *&Site, Function *Callee, SpecMask Mask, Module &M,
                      WidthDispatch &wd, TaintSet &taint, SpecPlan &plan);

// Get-or-create the clone for `(Callee, Mask)`, retarget `Site` (updating it in
// place if the retarget rebuilt the call — see `retargetSite`), and return the
// FINALIZED record. A cache HIT reuses an existing clone (C7) — and because the
// drain is depth-first, every HIT reads a record whose `ReturnTainted` was
// finalized before the recursion returned (closing the 6.2 drain-ordering hazard
// the placeholder `ReturnTainted=false` would otherwise expose, [[6-3-drain-ordering-varargs-recheck]]).
SpecRecord resolveSite(CallInst *&Site, Function *Callee, SpecMask Mask, Module &M,
                       WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  SpecKey Key{Callee, Mask};
  auto It = plan.Cache.find(Key);
  if (It != plan.Cache.end()) {
    retargetSite(Site, It->second.Clone);
    return It->second;
  }
  return buildClone(Site, Callee, Mask, M, wd, taint, plan);
}

SpecRecord buildClone(CallInst *&Site, Function *Callee, SpecMask Mask, Module &M,
                      WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  SpecKey Key{Callee, Mask};
  Function *Clone = cloneFor(SpecCandidate{Site, Callee, Mask});
  // Insert the (incomplete) record up front so a self/dedup reference resolves.
  plan.Cache[Key] = SpecRecord{Clone, false};

  TaintSet cloneTaint = seedClone(Clone, Mask);

  // fp-ABI param HandleWidth (bd 3c6m.54): a tainted fp param rewritten to i32 in
  // `cloneFor` carries an fp logical width the clone body needs when a CAST reads
  // it directly (`getSrcTy()` reads the laundered i32; the width is recovered from
  // `HandleWidth`, exactly the theta-handle mechanism RotationLowering uses). Record
  // it here so `lowerOps` on the clone body resolves `fptrunc`/`bitcast fp<->i80`/…
  // off an fp param to the correct `cq_template_<op>_f<W>_...` rather than declining.
  for (unsigned i = 0, n = Callee->arg_size(); i < n; ++i) {
    StringRef OrigW = abiWidthFromType(Callee->getArg(i)->getType());
    if (Clone->getArg(i)->getType()->isIntegerTy(32) &&
        abiWidthHasReversibleFpCopy(OrigW))
      cloneTaint.HandleWidth[Clone->getArg(i)] = OrigW;
  }

  // Depth-first transitive worklist (3.3): specialize each inner tainted-arg call
  // INSIDE this clone — and synthesize its uncompute twin — BEFORE this clone's
  // own data lowering, stream capture, and Bennett wrap. So the inner retargeted
  // call is an ordinary handle op in this clone's forward stream, and its twin is
  // already defined when the wrap reverses it. Each level lowers under its OWN
  // disjoint `cloneTaint` (C-Taint), so no gate is double-adjointed (3.6).
  SmallPtrSet<CallInst *, 4> TaintedCloneCalls;
  SmallVector<CallInst *, 4> InnerCalls;  // snapshot before mutation
  for (BasicBlock &BB : *Clone)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I))
        InnerCalls.push_back(CI);
  for (CallInst *Inner : InnerCalls) {
    Function *InnerCallee = Inner->getCalledFunction();
    if (!InnerCallee)
      continue;  // indirect call with classical args — left as a classical subcall.
    // A curated reversible llvm.* idiom intrinsic (Phase 7.1-E) is a tainted
    // DATA OP lowered IN PLACE by the `lowerOps(M, …)` below (to a
    // `cq_template_<op>_<W>` producer the wrap then captures via
    // `isForwardTemplate`), NEVER a nested specialization candidate. Its callee
    // is an llvm INTRINSIC DECLARATION with no body, so it must be skipped here
    // BEFORE `classifyCandidate`/`scanBody` — those require a visible definition
    // (`!isDeclaration()`, see the SpecializeReject.h contract) and would
    // dereference a null entry block on the bodiless intrinsic. This is the FIRST
    // place a declaration-callee inner call can appear: pre-7.1-E-follow-up,
    // `scanBody` rejected any body containing a declaration-only call, so the
    // clone never held one; now that detection accepts a curated intrinsic in the
    // body, this loop must mirror that — lower it in place, do not recurse.
    // [[7-1-E-intrinsics-frozen-clearance]]
    if (isCuratedReversibleIntrinsic(Inner))
      continue;
    // p119: a DIRECT-libm call in a clone body is a LIBRARY function (removed from
    // recognition). It has no visible body, so it falls through to the loud
    // declaration-only "nested call" decline below — the correct outcome (it must
    // be source-injected to lower, never recognized by name).
    // The inner's taint mask is read from THIS clone's seeded `cloneTaint`, after
    // any earlier sibling's classical-result scrub (process in program order so a
    // downstream inner sees the corrected taint).
    SpecMask InnerMask = taintArgMask(Inner, cloneTaint);
    if (InnerMask == 0)
      continue;  // all-classical args — an ordinary classical subcall, not lifted.

    // Classify with the inner's REAL mask (the per-Site ABI + a re-walk of the
    // body/cycle). A non-Accept inner is a LOUD decline at its offending
    // instruction (opt exits non-zero, the module is rejected) — never a silent
    // un-retargeted handle call (Prime Directive).
    SpecCandidate InnerCand{Inner, InnerCallee, InnerMask};
    Instruction *Where = nullptr;
    std::string Kind;
    SpecReject Why = classifyCandidate(InnerCand, taint, wd, Where, Kind);
    if (Why != SpecReject::Accept) {
      diagnoseReject(Where, Why, Kind);
      continue;
    }

    CallInst *OldInner = Inner;
    StringRef InnerOrigW = abiWidthFromType(Inner->getType());  // pre-rebuild width.
    SpecRecord Rec =
        resolveSite(Inner, InnerCallee, InnerMask, M, wd, taint, plan);
    // fp-ABI intra-clone taint migration (bd 3c6m.54): if retargeting REBUILT the
    // inner call (an fp-tainted return rewritten to an i32 handle), the fresh
    // `CallInst` is a NEW value absent from THIS outer clone's `cloneTaint` —
    // `seedClone` tainted the OLD, now-erased call. Without migration the outer
    // body's ops read the inner result as UNTAINTED, so `ArithLowering` picks the
    // wrong template shape (an i32 handle lands in an fp literal slot → a broken
    // module, the Rule-13 finding). Mirror the module-level re-seed `specialize`
    // does for a top-level rebuilt result: erase the stale entry, register the new
    // call as a tainted i32 handle (carrying any `BirthOrder`), and record its fp
    // logical width in `HandleWidth` so a later outer op/cast off it resolves the
    // right `cq_template_*_f<W>`. The integer path never rebuilds
    // (`setCalledFunction` keeps the pointer), so this is inert there.
    if (Inner != OldInner) {
      cloneTaint.Tainted.erase(OldInner);
      if (auto BO = cloneTaint.BirthOrder.find(OldInner);
          BO != cloneTaint.BirthOrder.end()) {
        cloneTaint.BirthOrder[Inner] = BO->second;
        cloneTaint.BirthOrder.erase(OldInner);
      }
      cloneTaint.Tainted.insert(Inner);
      if (Rec.ReturnTainted && abiWidthHasReversibleFpCopy(InnerOrigW))
        cloneTaint.HandleWidth[Inner] = InnerOrigW;
    }
    if (Rec.ReturnTainted) {
      // A quantum-handle result, entangled with the borrowed inputs: the outer
      // wrap MUST uncompute it (via the twin) before freeing it, else freeing a
      // dirty rail collapses the caller's qubit (Rule 6/8). Include it in the
      // forward stream and guarantee the twin exists.
      ensureTwin(Rec.Clone);
      TaintedCloneCalls.insert(Inner);
    } else {
      // A classical-derived result (inner restored its own borrowed inputs and
      // left no quantum output): scrub it and its now-classical cone from
      // `cloneTaint` so its consumers stay classical (intra-clone §2.7). Roots
      // that must never be scrubbed: this clone's seeded params and any
      // already-tainted inner clone-call result.
      SmallPtrSet<const Value *, 8> Roots;
      for (Argument &A : Clone->args())
        if (cloneTaint.Tainted.count(&A))
          Roots.insert(&A);
      for (CallInst *T : TaintedCloneCalls)
        Roots.insert(T);
      scrubForwardCone(Inner, cloneTaint, Roots);
    }
  }

  // 5po2: lift any LIFTABLE tainted `select` in the clone body to a 4.4
  // controlled-XOR copy BEFORE `lowerOps` — so the fresh `cq_template_icmp` flag
  // mint is an ordinary data template the wrap captures/reverses, and the stock
  // `icmp` feeding the select is consumed before `lowerOps` would lower a dead
  // compare. `SelectCopyOps` (the void controlled copies) and `SelectOutRails`
  // (the out allocs) steer the Bennett capture below.
  SmallPtrSet<CallInst *, 4> SelectCopyOps;
  SmallPtrSet<Value *, 4> SelectOutRails;
  // kmdc: the fp two-arm select's ¬flag `cqrt_x` brackets — ForwardStream-only
  // reverse-only ops the Bennett reverse must re-play (they mint no rail). Held
  // separately because `isForwardTemplate` matches only `cq_template_` names, so
  // without this set the reverse would DROP them → dirty out-rail / hidden measure.
  SmallPtrSet<CallInst *, 4> SelectXBrackets;
  lowerCloneSelect(*Clone, cloneTaint, wd, SelectCopyOps, SelectOutRails,
                   SelectXBrackets);

  // Scoped data lowering: `lowerOps` walks all of `M` but lowers only the
  // instructions in `cloneTaint` (C25). Inner clone calls are not stock opcodes,
  // so they are untouched; already-lowered sibling clones are in disjoint
  // `cloneTaint`s, so they are untouched too.
  lowerOps(M, wd, cloneTaint);

  // Capture the forward stream + scratch rails in program order: data templates
  // AND the `ReturnTainted` inner clone calls (each a reversible rail the wrap
  // reverses via its twin and frees). 5po2 adds two off-1:1 kinds: a controlled
  // copy (`SelectCopyOps`) is a REVERSE-ONLY forward op (played self-inverse to
  // zero the out rail, mints no rail → ForwardStream only), and the select out
  // alloc (`SelectOutRails`) is a rail to FREE but not a forward op (zeroed by
  // that copy's reverse → ScratchRails only).
  SmallVector<CallInst *, 8> ForwardStream;
  SmallVector<Value *, 8> ScratchRails;
  for (BasicBlock &BB : *Clone)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (isForwardTemplate(CI) || TaintedCloneCalls.count(CI)) {
          ForwardStream.push_back(CI);
          ScratchRails.push_back(CI);
        } else if (SelectCopyOps.count(CI) || SelectXBrackets.count(CI)) {
          // A controlled copy OR an fp-select ¬flag `cqrt_x` bracket: reverse-only
          // (self-inverse, mints no rail) → ForwardStream, never ScratchRails.
          ForwardStream.push_back(CI);
        } else if (SelectOutRails.count(CI)) {
          ScratchRails.push_back(CI);
        }
      }

  auto *Ret = dyn_cast<ReturnInst>(Clone->getEntryBlock().getTerminator());
  Value *RV = Ret ? Ret->getReturnValue() : nullptr;
  bool ReturnTainted = RV && cloneTaint.Tainted.count(RV);
  Value *ResultRail = ReturnTainted ? RV : nullptr;
  // The copy-out width is the ORIGINAL callee return width (e.g. "f80"), NOT the
  // clone's declared return type: a tainted fp return had its clone signature
  // rewritten to i32 in `cloneFor`, so `Clone->getReturnType()` is i32, but the
  // ResultRail is an fp-width quantum value that must copy out via `cqrt_copy_f<W>`
  // (bd 3c6m.54). For an int/void return this equals the clone's own width.
  StringRef RetW = abiWidthFromType(Callee->getReturnType());

  // fp-ABI mispredict guard (bd 3c6m.54): `cloneFor` rewrote a reversible-fp
  // return to an i32 handle ONLY when `predictReturnTainted` (a sound over-approx)
  // said tainted. The single gap is a `predict==true`/`actual==false` mispredict —
  // an inner tainted-arg clone that returns classical, feeding the whole return
  // (unreachable in the always-inlined census cells: no inner calls). Then the
  // clone declares i32 but the return value is a classical fp — a broken module.
  // Decline LOUDLY, source-located, before any copy-out emission — never a silent
  // miscompile (and, absent this guard, LLVM's own verifier rejects the mistyped
  // `ret`; this house decline is the Rule-1 loud-and-located form). Over-decline
  // is safe (Prime Directive): a classical-fp-return-with-fp-args clone is outside
  // the shipped target shape.
  if (!ReturnTainted && Clone->getReturnType()->isIntegerTy(32) &&
      abiWidthHasReversibleFpCopy(RetW)) {
    Clone->getContext().diagnose(DiagnosticInfoUnsupported(
        *Clone,
        "cq specialization: floating-point return-taint could not be proven "
        "under quantum lift",
        Ret ? Ret->getDebugLoc() : DebugLoc()));
    // Retarget (keeping the call-site consistent so no SECONDARY crash precedes
    // the DS_Error) and return; opt exits non-zero on the diagnostic and the
    // module is rejected regardless of the clone's transient (broken `ret`) state.
    plan.Cache[Key].ReturnTainted = ReturnTainted;
    retargetSite(Site, Clone);
    return SpecRecord{Clone, ReturnTainted};
  }

  emitBennettWrap(*Clone, ForwardStream, ResultRail, ScratchRails, RetW, wd,
                  cloneTaint);

  // Finalize the record BEFORE returning — any later cache HIT (sibling or outer)
  // must read the true `ReturnTainted`, never the up-front placeholder.
  plan.Cache[Key].ReturnTainted = ReturnTainted;
  retargetSite(Site, Clone);
  // The rebuilt fp result's HandleWidth is recorded by the CALLER (the drain loop
  // for an inner call, into `cloneTaint`; `specialize` for a top-level call, into
  // module `taint` — covering the cache-hit path too), where the correct taint set
  // and the pre-retarget fp width are in scope. Not here: `buildClone`'s `taint` is
  // always the MODULE taint, wrong for an inner call.
  return SpecRecord{Clone, ReturnTainted};
}

}  // namespace

bool shouldSpecialize(const CallInst *CI, const SpecPlan &plan) {
  for (const SpecCandidate &C : plan.Pending)
    if (C.Site == CI)
      return true;
  return false;
}

void specialize(Module &M, WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  // Each retargeted TOP-LEVEL site + whether its clone returns a tainted handle
  // (read post-drain for the §2.7 return-taint re-seed). Inner sites live inside
  // clones (disjoint `cloneTaint`) and are NOT module-level — `buildClone` owns
  // their retargeting and intra-clone taint, so they never enter `Retargeted`.
  SmallVector<std::pair<CallInst *, bool>, 4> Retargeted;

  // Drain the proven-Accept top candidates. `resolveSite` recurses depth-first
  // into each clone's inner tainted-arg calls (the transitive worklist),
  // synthesizing each distinct `(callee, mask)` once via the shared cache (3.4)
  // and terminating on the finite key space of the acyclic accepted subset (3.6).
  // `Pending` holds only the module-level tops (the carve-out's membership domain)
  // and never grows here — inner specialization is the recursion, not a push.
  for (size_t i = 0; i < plan.Pending.size(); ++i) {
    SpecCandidate Cand = plan.Pending[i];
    StringRef OrigW = abiWidthFromType(Cand.Site->getType());  // pre-retarget width.
    SpecRecord Rec =
        resolveSite(Cand.Site, Cand.Callee, Cand.Mask, M, wd, taint, plan);
    Retargeted.push_back({Cand.Site, Rec.ReturnTainted});
    // fp-ABI result HandleWidth (bd 3c6m.54): a tainted fp return is an i32 handle
    // at the call site (`retargetSite` rebuilt the call to i32), but its logical
    // width is the ORIGINAL fp width captured above. Record it so a caller CAST off
    // the result — `(int)coshl(q)` → `fptosi f<W> %r to i32` — recovers the fp
    // source width (the theta-handle parity) instead of declining "no template for
    // fptosi i32". Recorded HERE (not in `buildClone`) so BOTH the build AND the
    // cache-HIT path are covered (a cache hit skips `buildClone` — the Rule-13
    // cache-hit gap). A caller fp ARITH / MEASURE reads the width from its own type
    // and never consults this; harmless there.
    if (Rec.ReturnTainted && abiWidthHasReversibleFpCopy(OrigW))
      taint.HandleWidth[Cand.Site] = OrigW;
  }

  // §2.7 return-taint re-seed. The original `propagate` conservatively tainted
  // EVERY specialized-call result (a call reading a tainted arg, :305-306). The
  // clone's post-lowering `ReturnTainted` is the precise verdict:
  //   * true  → the result is genuine quantum data; leave it tainted (already in
  //     `taint`, downstream already propagated) — the caller's `:115` uncompute
  //     owns it (C-Taint).
  //   * false → the conservative taint was wrong (the return derives from
  //     classical params only); scrub the result and the forward cone that loses
  //     all taint, so a downstream caller op stays CLASSICAL (WI-1.9).
  // Never-scrub roots: every value whose taint is INDEPENDENT of a scrubbed
  // call result — the primary `cq_theta` sources (a theta result is quantum
  // regardless of its arg-0 seed, Rule 3) and every genuinely-tainted
  // specialized-call result. The walk stops at these, pruning their downstream
  // cones (axis-(g) over-scrub fix). `cq_phi` is deliberately absent — it is
  // not a source, and a `cq_phi` on a now-classical operand must be scrubbed.
  SmallPtrSet<const Value *, 8> TaintedSources;
  for (auto &R : Retargeted)
    if (R.second)
      TaintedSources.insert(R.first);
  for (const CallInst *Theta : taint.ThetaCalls)
    TaintedSources.insert(Theta);
  for (auto &R : Retargeted) {
    CallInst *Site = R.first;
    bool ReturnTainted = R.second;
    if (ReturnTainted) {
      taint.Tainted.insert(Site);  // robustness; usually already present.
    } else if (taint.Tainted.count(Site)) {
      scrubForwardCone(Site, taint, TaintedSources);
    }
  }
}

}  // namespace cq
