import pathlib
W = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8')
p = W / 'ir-pass/src/Specialization.cpp'
s = p.read_text()
i = s.index('// bd `test_C_libtooling-vsfp` — see Specialization.h. Mirrored\n// character-for-character by `spec_reject_phantom_arg_read*.ll`.')
j = s.index('void specialize(Module &M, WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {')
new = r'''// bd `test_C_libtooling-vsfp` — see Specialization.h. Mirrored
// character-for-character by `spec_reject_phantom_arg_read*.ll`.
static constexpr char kMsgPhantomArgRead[] =
    "cq specialization: quantum argument to a parameter the lifted callee never "
    "reads";

namespace {

// Is `V` a caller-side QUANTUM value at this slot: tainted, or a rail a control
// emitter minted and recorded (the round-1 and round-2 `%out` rails are in
// `Tainted` too — r1B measured it; the rail sets are asked as well so the answer
// does not depend on that).
bool isQuantumCallerValue(const Value *V, const TaintSet &taint) {
  Value *NV = const_cast<Value *>(V);
  return taint.Tainted.count(NV) || taint.ControlOwnedRails.count(NV) ||
         taint.UntaintedMergeRails.count(NV) || taint.OutputRails.count(NV);
}

// A rail a CONTROL EMITTER minted (a 4.4/6.5/4.5 `%out`, a loop rail): the
// emitter's own runtime calls on it (the controlled copies INTO it) are its
// construction, not a user READ of it.
bool isControlEmittedRail(const Value *V, const TaintSet &taint) {
  Value *NV = const_cast<Value *>(V);
  return taint.ControlOwnedRails.count(NV) ||
         taint.UntaintedMergeRails.count(NV) || taint.OutputRails.count(NV);
}

bool isRuntimeCall(const CallBase &CB) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
}

// Does the USER PROGRAM read `V` — i.e. does the hand-inlined twin compute `V`
// too? Asked AFTER every recorded-dead slot was neutralised, so no phantom read
// is left among `V`'s uses. Asked positively (Prime Directive direction: a use we
// cannot name as a reader is NOT one, so the answer errs toward declining).
// A READER is: a front-end `cq_measure`, or a `cq_theta` taking `V` as arg-0 (by
// membership — the user reads it); a READ slot of a clone call; a `ret`; a
// control-emitted runtime call reading a USER value (`V` not itself an emitter's
// rail — the compare a tainted condition mints, which the twin mints too); or a
// LIVE instruction under the liveness predicate. ⚠ NOT a reader: a runtime call
// on a rail a control emitter minted (the emitter's own copies INTO its `%out` —
// telling a read from a write there needs the runtime ABI's slot semantics, so
// every such call is treated as construction; a `%out` a later control-emitted
// compare genuinely reads is therefore an over-decline, named, not constructed).
// ⚠ THE ROUND-2 VERSION OF THIS PREDICATE WAS UNSOUND AS AN ACCEPT (bd tzfa; bd
// vsfp Rule-13 r2B F-WB-1): it asked "is `V` live for a reason of its own?" while
// the phantom read was still IN the use list, and a live `V` was accepted with the
// phantom read left in place — the uncompute spine then saw an extra CONSUMER of
// `V`'s template rail and did not discharge it (r2B `k19`: `h1 = 3q` never
// uncomputed, `q` fully dephased across the phase oracle). It is only sound now
// because the phantom read is GONE before the question is asked.
bool userProgramReads(const Value *V, const FunctionLiveness &L,
                      const TaintSet &taint) {
  const bool EmitterRail = isControlEmittedRail(V, taint);
  for (const Use &U : V->uses()) {
    const auto *UI = dyn_cast<Instruction>(U.getUser());
    if (!UI)
      continue;  // not a reader we can name.
    if (const auto *CB = dyn_cast<CallBase>(UI)) {
      if (const auto *CI = dyn_cast<CallInst>(CB)) {
        if (taint.MeasureCalls.contains(CI))
          return true;
        if (taint.ThetaCalls.contains(CI) && CI->arg_size() >= 1 &&
            CI->getArgOperand(0) == V)
          return true;
      }
      if (const Function *Callee = CB->getCalledFunction())
        if (taint.SpecHandleArgMask.count(Callee))
          return true;  // a READ slot of a clone (dead slots were neutralised).
      if (isRuntimeCall(*CB)) {
        if (EmitterRail)
          continue;  // the emitter's own traffic on its rail: construction.
        return true;
      }
    }
    if (isa<ReturnInst>(UI))
      return true;
    if (L.isLive(UI))
      return true;
  }
  return false;
}

}  // namespace

bool resolvePhantomCloneArgReads(Module &M, const TaintSet &taint) {
  // 1. NEUTRALISE. Every recorded-dead slot of every call to a clone in a
  //    non-clone function gets a null constant, exactly the drop's rewrite (and
  //    its `range`/`nofpclass` strip), asked with the SAME predicate's record
  //    (`isRecordedDeadSlot`). From here on no stage — the uncompute spine's
  //    terminal selection and free points, M-C, M-A's hop walk, stage 2b — can
  //    see a read the clone never performs: the operand's consumer set is the
  //    hand-inlined twin's. One rewrite at the one point the record exists, rather
  //    than a `isRecordedDeadSlot` exemption in every consumer (Rule 14; L3's
  //    mirror — a consumer that forgot the exemption would re-open bd tzfa).
  struct Neutralised {
    Function *F;
    CallBase *CB;
    Value *Op;
  };
  SmallVector<Neutralised, 8> Done;
  for (Function &F : M) {
    if (F.isDeclaration() || taint.SpecHandleArgMask.count(&F))
      continue;  // a clone / `_unc` twin body: its own Bennett wrap discharges.
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || !taint.SpecDeadArgMask.count(Callee))
          continue;
        // EVERY slot the record calls dead, not only the detection mask's.
        for (unsigned A = 0, E = CB->arg_size(); A < E; ++A) {
          if (!isRecordedDeadSlot(*CB, A, taint))
            continue;
          Value *Op = CB->getArgOperand(A);
          if (isa<Constant>(Op))
            continue;
          if (A < Callee->arg_size())
            for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass}) {
              Callee->removeParamAttr(A, K);
              CB->removeParamAttr(A, K);
            }
          CB->setArgOperand(A, Constant::getNullValue(Op->getType()));
          Done.push_back({&F, CB, Op});
        }
      }
  }
  // 2. DECLINE what the spine still cannot discharge like the twin. A neutralised
  //    QUANTUM operand the user program still reads is computed by the twin too,
  //    and now has the twin's consumer set — the spine discharges it (or keeps
  //    it) exactly as the twin's. One the user program does NOT read is a
  //    computation the twin does not have: a control-emitted rail minted for the
  //    phantom (a 4.4 `%out` — a which-path rail no stage uncomputes) or a dead
  //    tainted op (lowered as a forward template; a dead chain is not reliably
  //    uncomputed — CLAUDE.md fenv, bd vsfp §R2.6). Declined.
  //    The one exemption is a `cq_theta` RESULT: the user's own register, which
  //    the twin computes and keeps too (`cq_theta` is never deleted; validated by
  //    Rule-13 r1B on nine shapes, mutant B2).
  DenseMap<Function *, std::unique_ptr<FunctionLiveness>> Live;
  for (const Neutralised &N : Done) {
    if (!isQuantumCallerValue(N.Op, taint))
      continue;  // a classical value costs nothing: no rail, no entanglement.
    if (auto *OpCI = dyn_cast<CallInst>(N.Op);
        OpCI && taint.ThetaCalls.contains(OpCI))
      continue;
    auto &L = Live[N.F];
    if (!L)
      L = std::make_unique<FunctionLiveness>(*N.F, taint);
    if (userProgramReads(N.Op, *L, taint))
      continue;
    N.F->getContext().diagnose(DiagnosticInfoUnsupported(
        *N.F, kMsgPhantomArgRead, N.CB->getDebugLoc()));
    return true;
  }
  return false;
}

'''
s = s[:i] + new + s[j:]
p.write_text(s)

h = W / 'ir-pass/include/Specialization.h'
t = h.read_text()
i = t.index('// bd `test_C_libtooling-vsfp` (P1) — THE PHANTOM-READ POSTCONDITION, the observing')
j = t.index('bool declinePhantomCloneArgReads(llvm::Module &M, const TaintSet &taint);')
j2 = j + len('bool declinePhantomCloneArgReads(llvm::Module &M, const TaintSet &taint);')
newh = '''// bd `test_C_libtooling-vsfp` (P1) / bd `tzfa` (P1) — THE PHANTOM READ, RESOLVED
// (bd vsfp round 3). The observing half of `dropDeadCallArguments`
// (SpecializeDetect.h): after `specialize()`, the specializer's record
// (`isRecordedDeadSlot`: `taint.SpecDeadArgMask`, taken by `buildClone` with the
// pass's ONE liveness predicate, `DeadValueLiveness.h`) names the slots each built
// clone never reads. A call in a NON-clone function that passes a value in such a
// slot is a read only the compiler performs.
//
// (1) It NEUTRALISES every one: the operand becomes a null constant (the drop's
// rewrite, `range`/`nofpclass` stripped), so no later stage can see the phantom
// read. That is the fix for bd tzfa: the read did not keep the operand's rail
// ALIVE, it kept the uncompute SPINE from DISCHARGING it — an extra consumer of a
// template rail the twin uncomputes (r2B `k19`: `h1 = 3q` left dirty across a
// phase oracle, `q` fully dephased). With the read gone, the spine sees the
// hand-inlined twin's consumer set.
//
// (2) It DECLINES (`cq specialization: quantum argument to a parameter the lifted
// callee never reads`, DS_Error on the call, returns true) when a neutralised
// operand is QUANTUM (tainted, or a control-emitted rail) and the user program no
// longer reads it: the twin never computes such a value, and what the pass
// already built for it cannot be taken back — a 4.4 `%out` minted for the
// phantom is a which-path rail no stage uncomputes, and a dead tainted op is not
// reliably uncomputed. The one exemption is a `cq_theta` RESULT (the user's own
// register; Rule-13 r1B, nine shapes, mutant B2). "Reads" is asked positively —
// see `userProgramReads` in Specialization.cpp for the list, and for the one
// named over-decline it leaves (a `%out` read only by a later control-emitted
// compare).
//
// ⚠ WHAT IT IS NOT (L7). Not "TOTAL" (round 1): it acts on phantom reads THROUGH
// A CLONE CALL; a dead operand kept alive by something else (a dead intrinsic, a
// dead φ cycle) is the drop's (`deleteDeadCones`). And not round 2's "a value
// kept alive elsewhere adds nothing" — that exemption was accepted with the
// phantom still in the use list, which was bd tzfa. What reaches this point at
// all is a slot the CLONE's own pipeline made dead (its scoped PredMux flatten)
// that the drop could not predict from the original callee, or one a drop
// precondition refused. Clone BODIES are not scanned: every rail an inner call
// there could keep is uncomputed by the enclosing Bennett wrap.
//
// THE SLOT (both entry points): last in the post-`specialize()` decline chain,
// before `lowerRotations` (which RAUWs every `cq_theta` result to its handle), so
// the neutralisation happens before every stage that builds a consumer set.
bool resolvePhantomCloneArgReads(llvm::Module &M, const TaintSet &taint);'''
t = t[:i] + newh + t[j2:]
h.write_text(t)

c = W / 'ir-pass/src/CQLoweringPass.cpp'
u = c.read_text()
assert u.count('if (declinePhantomCloneArgReads(M, taint))') == 2
u = u.replace('if (declinePhantomCloneArgReads(M, taint))', 'if (resolvePhantomCloneArgReads(M, taint))')
c.write_text(u)
print('ok')
