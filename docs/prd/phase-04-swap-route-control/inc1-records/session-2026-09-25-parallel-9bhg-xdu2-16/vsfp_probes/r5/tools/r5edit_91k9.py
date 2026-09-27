W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'


def sub(path, old, new, n=1):
    p = W + path
    s = open(p).read()
    assert s.count(old) == n, (path, s.count(old), old[:70])
    s = s.replace(old, new)
    open(p, 'w').write(s)


# ---- SpecializeDetect: export the drop's slot eligibility as ONE composed predicate
sub('ir-pass/src/SpecializeDetect.cpp', '''bool dropEligibleParam(const Argument &P) {
  Type *Ty = P.getType();
  if (!Ty->isIntegerTy() && !Ty->isFloatingPointTy())
    return false;
  return !P.hasAttribute(Attribute::Returned) && !P.hasSwiftErrorAttr() &&
         !P.hasPassPointeeByValueCopyAttr();
}

}  // namespace
''', '''bool dropEligibleParam(const Argument &P) {
  Type *Ty = P.getType();
  if (!Ty->isIntegerTy() && !Ty->isFloatingPointTy())
    return false;
  return !P.hasAttribute(Attribute::Returned) && !P.hasSwiftErrorAttr() &&
         !P.hasPassPointeeByValueCopyAttr();
}

}  // namespace

bool dropEligibleSlot(const CallBase &CB, unsigned A) {
  const Function *Callee = CB.getCalledFunction();
  if (!dropEligibleCallee(Callee) || CB.getFunctionType() != Callee->getFunctionType())
    return false;
  if (const auto *CI = dyn_cast<CallInst>(&CB); CI && CI->isMustTailCall())
    return false;
  if (A >= Callee->arg_size())
    return false;
  return dropEligibleParam(*Callee->getArg(A)) &&
         dropEligibleParamAttrs(Callee->getAttributes().getParamAttrs(A)) &&
         dropEligibleParamAttrs(CB.getAttributes().getParamAttrs(A));
}
''')
# the drop's own per-parameter check calls the composed predicate (one spelling)
sub('ir-pass/src/SpecializeDetect.cpp', '''        Argument *P = Callee->getArg(A);
        if (!dropEligibleParam(*P) ||
            !dropEligibleParamAttrs(Callee->getAttributes().getParamAttrs(A)) ||
            !dropEligibleParamAttrs(CI->getAttributes().getParamAttrs(A)))
          continue;''', '''        Argument *P = Callee->getArg(A);
        if (!dropEligibleSlot(*CI, A))
          continue;''')

sub('ir-pass/include/SpecializeDetect.h', '''bool dropDeadCallArguments(llvm::Module &M, const TaintSet &taint);
''', '''bool dropDeadCallArguments(llvm::Module &M, const TaintSet &taint);

// THE DROP'S SLOT ELIGIBILITY, as one predicate (bd vsfp round 5, bd `91k9`): may
// argument slot `A` of `CB` be rewritten to a constant? True only when the callee is
// a direct, exact, non-`naked`, non-variadic definition called with its own function
// type and not `musttail`, and the parameter is an integer or floating-point scalar
// with no `returned`/`swifterror`/`byval`/`inalloca`/`preallocated` and only
// `noundef`/`signext`/`zeroext`/`inreg`/`range`/`nofpclass` on it and on the call
// site's slot. A POINTER slot is never eligible (so neither is `byref`/`sret`/
// `nonnull`/`dereferenceable`). Called by the drop's loop and by
// `rewriteRecordedDeadSlotUse` (DeadValueLiveness.h) — the post-`specialize()`
// rewrite, which rewrote pointer and `byval` slots to `null` without it (a plain-C
// program compiled clean and its executable SIGSEGVed, r4A F-YA-1).
bool dropEligibleSlot(const llvm::CallBase &CB, unsigned A);
''')
s = open(W + 'ir-pass/include/SpecializeDetect.h').read()
if 'class CallBase;' not in s:
    print('NOTE: SpecializeDetect.h has no CallBase forward decl')

# ---- DeadValueLiveness: the rewritable dead slot, in liveness AND the rewrite
sub('ir-pass/src/DeadValueLiveness.cpp', '''bool rewriteRecordedDeadSlotUse(Use &U, const TaintSet &taint) {
  auto *CB = dyn_cast<CallBase>(U.getUser());
  if (!CB || !CB->isArgOperand(&U) || isa<Constant>(U.get()))
    return false;
  unsigned A = CB->getArgOperandNo(&U);
  if (!isRecordedDeadSlot(*CB, A, taint))
    return false;''', '''bool isRewritableDeadSlot(const CallBase &CB, unsigned ArgNo,
                          const TaintSet &taint) {
  return isRecordedDeadSlot(CB, ArgNo, taint) && dropEligibleSlot(CB, ArgNo);
}

bool rewriteRecordedDeadSlotUse(Use &U, const TaintSet &taint) {
  auto *CB = dyn_cast<CallBase>(U.getUser());
  if (!CB || !CB->isArgOperand(&U) || isa<Constant>(U.get()))
    return false;
  unsigned A = CB->getArgOperandNo(&U);
  if (!isRewritableDeadSlot(*CB, A, taint))
    return false;''')
sub('ir-pass/src/DeadValueLiveness.cpp', '''      // Operands of a call: the argument slots the callee is RECORDED never to
      // read do not propagate; the called operand and bundle operands do.
      for (const Use &U : CB->operands()) {
        if (CB->isArgOperand(&U) &&
            isRecordedDeadSlot(*CB, CB->getArgOperandNo(&U), taint))
          continue;''', '''      // Operands of a call: the argument slots the callee is RECORDED never to
      // read AND that the one rewrite may null (`isRewritableDeadSlot`) do not
      // propagate; the called operand, bundle operands and every other slot do.
      // ⚠ bd `91k9` (round 5): an INELIGIBLE recorded-dead slot (a pointer, a
      // `byval`, an attribute outside the drop's allowlist) is never rewritten, so
      // its operand stays a use of the call — counting it as a read keeps
      // `deleteDeadCones` step 3 from deleting a value that call still uses.
      for (const Use &U : CB->operands()) {
        if (CB->isArgOperand(&U) &&
            isRewritableDeadSlot(*CB, CB->getArgOperandNo(&U), taint))
          continue;''')
if '#include "SpecializeDetect.h"' not in open(W + 'ir-pass/src/DeadValueLiveness.cpp').read():
    sub('ir-pass/src/DeadValueLiveness.cpp', '#include "TaintPropagation.h"\n',
        '#include "SpecializeDetect.h"  // dropEligibleSlot (bd 91k9: the drop\'s ONE slot rule)\n#include "TaintPropagation.h"\n')

sub('ir-pass/include/DeadValueLiveness.h', '''// THE ONE REWRITE of a recorded-dead slot (bd vsfp round 4; Rule 14 — three sites
// used to spell it): if `U` is an argument operand of a call in a slot
// `isRecordedDeadSlot` names, and it is not already a constant, set it to the null
// constant of the CALLEE PARAMETER's type (bd f061: after retargeting, an fp slot
// is an `i32` handle — never the operand's type) and strip `range`/`nofpclass` from
// the parameter and the call site (a null may violate them — the constraint DAE
// strips too). Returns true iff it rewrote.''', '''// A recorded-dead slot that the one rewrite may also NULL: `isRecordedDeadSlot` AND
// the pre-`specialize()` drop's own eligibility (`dropEligibleSlot`,
// SpecializeDetect.h — an int/fp scalar, no `byval`/`returned`/`swifterror`/…, only
// allowlisted attributes). The liveness call-slot rule asks THIS, not the bare
// record, so an ineligible slot's operand — which stays in place — is a read.
bool isRewritableDeadSlot(const llvm::CallBase &CB, unsigned ArgNo,
                          const TaintSet &taint);

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
// now applies the drop's eligibility (`dropEligibleSlot`), and on an eligible slot
// the only attributes that can be present are the allowlist, of which `range` /
// `nofpclass` are the only ones a null can violate — hence exactly that strip.
// An ineligible slot is left alone (a classical pointer there costs nothing; a
// QUANTUM operand there is declined by `resolvePhantomCloneArgReads`). Returns
// true iff it rewrote.''')

# ---- the "only deletes" comment (F-YA-3)
sub('ir-pass/include/DeadValueLiveness.h', '''// cannot fire there and no select is created — it only deletes.''',
    '''// cannot fire there and no select is created. ⚠ Not "it only deletes" (round 4's
// wording, r4A F-YA-3): step 3 also REWRITES the operand of a live inner call in a
// rewritable recorded-dead slot to a constant (the inherit). A rewrite to a
// constant shrinks the taint set and never grows it, so the conclusion stands —
// no select, no taint growth, no adjudication owed.''')

# ---- Specialization: resolve declines a QUANTUM operand in an ineligible slot
sub('ir-pass/src/Specialization.cpp', '''          if (!rewriteRecordedDeadSlotUse(CB->getArgOperandUse(A), taint))
            continue;  // already a constant.
          Done.push_back({&F, CB, Op});''', '''          if (isa<Constant>(Op))
            continue;  // already a constant.
          if (!rewriteRecordedDeadSlotUse(CB->getArgOperandUse(A), taint)) {
            // An INELIGIBLE slot (bd `91k9`, round 5: a pointer, a `byval`, an
            // attribute outside the drop's allowlist) is left in place. A
            // classical value there is harmless — no rail, no consumer set, no
            // spine. A QUANTUM one would stay a phantom read, exactly bd `tzfa`'s
            // extra consumer, so it declines (the same string as step 2).
            if (!isQuantumCallerValue(Op, taint))
              continue;
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F, kMsgPhantomArgRead, CB->getDebugLoc()));
            return true;
          }
          Done.push_back({&F, CB, Op});''')
sub('ir-pass/src/Specialization.cpp', '''  // 1. NEUTRALISE. Every recorded-dead slot of every call to a clone in a
  //    non-clone function gets a null constant, exactly the drop's rewrite (and
  //    its `range`/`nofpclass` strip), asked with the SAME predicate's record
  //    (`isRecordedDeadSlot`).''', '''  // 1. NEUTRALISE. Every recorded-dead slot of every call to a clone in a
  //    non-clone function that the drop's own eligibility admits (an int/fp scalar
  //    with allowlisted attributes — `dropEligibleSlot`) gets a null constant with
  //    the drop's `range`/`nofpclass` strip, asked with the SAME predicate's record
  //    (`isRecordedDeadSlot`). ⚠ Round 4 said "exactly the drop's rewrite" and
  //    applied none of the drop's eligibility — it nulled pointer and `byval`
  //    slots (bd `91k9`, r4A F-YA-1); an ineligible slot is now left in place, and
  //    declined when its operand is quantum.''')
sub('ir-pass/src/CQLoweringPass.cpp', '''  // module-level clone call (a null constant, the drop's rewrite), so the''',
    '''  // module-level clone call that the drop's eligibility admits (a null constant —
  // bd `91k9`: never a pointer or `byval` slot; a quantum operand in such an
  // ineligible slot declines instead), so the''')
sub('ir-pass/include/Specialization.h', '''// PARAMETER'S TYPE (the drop's rewrite, `range`/`nofpclass` stripped; bd f061 —''',
    '''// PARAMETER'S TYPE (on a slot the drop's eligibility admits — bd `91k9`: never a
// pointer, `byval`/`byref`/`sret`/`inalloca`/`preallocated` or non-allowlisted slot;
// a QUANTUM operand in such a slot declines instead — `range`/`nofpclass` stripped; bd f061 —''')
print('ok')
