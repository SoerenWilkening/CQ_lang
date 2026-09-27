W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
T = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md'


def sub(path, old, new, n=1):
    p = W + path
    s = open(p).read()
    assert s.count(old) == n, (path, s.count(old), old[:80])
    s = s.replace(old, new)
    open(p, 'w').write(s)


# ---- (1) w7nm: split dropEligibleSlot into NULL-SOUNDNESS and the drop's POLICY
sub('ir-pass/src/SpecializeDetect.cpp', '''bool dropEligibleSlot(const CallBase &CB, unsigned A) {
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
}''', '''bool nullSafeSlot(const CallBase &CB, unsigned A) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee || A >= Callee->arg_size())
    return false;
  return dropEligibleParam(*Callee->getArg(A)) &&
         dropEligibleParamAttrs(Callee->getAttributes().getParamAttrs(A)) &&
         dropEligibleParamAttrs(CB.getAttributes().getParamAttrs(A));
}

bool dropEligibleSlot(const CallBase &CB, unsigned A) {
  const Function *Callee = CB.getCalledFunction();
  if (!dropEligibleCallee(Callee) || CB.getFunctionType() != Callee->getFunctionType())
    return false;
  if (const auto *CI = dyn_cast<CallInst>(&CB); CI && CI->isMustTailCall())
    return false;  // POLICY, not soundness: a constant changes no signature.
  return nullSafeSlot(CB, A);
}''')

sub('ir-pass/include/SpecializeDetect.h', '''// THE DROP'S SLOT ELIGIBILITY, as one predicate (bd vsfp round 5, bd `91k9`): may
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
bool dropEligibleSlot(const llvm::CallBase &CB, unsigned A);''', '''// NULL-SOUNDNESS of argument slot `A` of `CB` (bd vsfp round 6, bd `w7nm`): is a
// null constant in this slot well-defined whatever the callee does with it, given
// the callee never reads it? True only when the callee is direct and the parameter
// is an integer or floating-point scalar with no `returned`/`swifterror`/`byval`/
// `inalloca`/`preallocated` and only `noundef`/`signext`/`zeroext`/`inreg`/`range`/
// `nofpclass` on it and on the call site's slot (`range`/`nofpclass` are the two a
// null can violate; the rewrite strips them). A POINTER slot is never null-safe (so
// neither is `byref`/`sret`/`nonnull`/`dereferenceable`) — bd `91k9`: a nulled
// `byval` slot compiled clean and the executable SIGSEGVed. This is the ONLY slot
// question the post-`specialize()` rewrite and the liveness call-slot rule ask
// (`isRewritableDeadSlot`, DeadValueLiveness.h).
bool nullSafeSlot(const llvm::CallBase &CB, unsigned A);

// THE DROP'S SLOT ELIGIBILITY: `nullSafeSlot` AND the drop's POLICY conservatisms —
// a direct, exact, non-`naked`, non-variadic callee called with its own function
// type, and not `musttail`. Asked ONLY by the pre-`specialize()` drop's loop.
// ⚠ Round 5 made the rewrite and the liveness rule ask this whole predicate, so the
// `musttail` conservatism became load-bearing for CORRECTNESS: an inner `musttail`
// dead slot counted as a READ, the enclosing clone's parameter became live, the
// outer phantom slot was never neutralised, and bd `tzfa`'s wrong unitary came back
// (r5 F-Z-1, bd `w7nm`, probe `mt1`: exit 0, the ORACLE's wrong stream). A constant in
// a `musttail` slot changes no signature and is what round 4 emitted, verify-clean.
bool dropEligibleSlot(const llvm::CallBase &CB, unsigned A);''')

sub('ir-pass/src/DeadValueLiveness.cpp', '''  return isRecordedDeadSlot(CB, ArgNo, taint) && dropEligibleSlot(CB, ArgNo);''',
    '''  return isRecordedDeadSlot(CB, ArgNo, taint) && nullSafeSlot(CB, ArgNo);''')
sub('ir-pass/src/DeadValueLiveness.cpp', '''#include "SpecializeDetect.h"  // dropEligibleSlot (bd 91k9: the drop's ONE slot rule)''',
    '''#include "SpecializeDetect.h"  // nullSafeSlot (bd 91k9 / w7nm: the ONE null-soundness rule)''')
sub('ir-pass/src/DeadValueLiveness.cpp', '''      // ⚠ bd `91k9` (round 5): an INELIGIBLE recorded-dead slot (a pointer, a
      // `byval`, an attribute outside the drop's allowlist) is never rewritten, so
      // its operand stays a use of the call — counting it as a read keeps
      // `deleteDeadCones` step 3 from deleting a value that call still uses.''',
    '''      // ⚠ bd `91k9` (round 5): a recorded-dead slot that is NOT NULL-SAFE (a
      // pointer, a `byval`, an attribute outside the allowlist) is never rewritten,
      // so its operand stays a use of the call — counting it as a read keeps
      // `deleteDeadCones` step 3 from deleting a value that call still uses.
      // ⚠ bd `w7nm` (round 6): the question is NULL-SOUNDNESS only, never the
      // drop's policy (`musttail`, callee conjuncts). A read counted here is NOT
      // local: through `deadParamMask` it makes the enclosing clone's parameter
      // LIVE one level up, where the outer slot is null-safe and would otherwise
      // be neutralised — round 5 asked `dropEligibleSlot` here, an inner `musttail`
      // dead slot became a read, and tzfa's phantom read came back (r5 `mt1`).''')

sub('ir-pass/include/DeadValueLiveness.h', '''// A recorded-dead slot that the one rewrite may also NULL: `isRecordedDeadSlot` AND
// the pre-`specialize()` drop's own eligibility (`dropEligibleSlot`,
// SpecializeDetect.h — an int/fp scalar, no `byval`/`returned`/`swifterror`/…, only
// allowlisted attributes). The liveness call-slot rule asks THIS, not the bare
// record, so an ineligible slot's operand — which stays in place — is a read.''',
    '''// A recorded-dead slot that the one rewrite may also NULL: `isRecordedDeadSlot` AND
// `nullSafeSlot` (SpecializeDetect.h — an int/fp scalar, no `byval`/`returned`/
// `swifterror`/…, only allowlisted attributes). ⚠ NOT the drop's whole eligibility
// (`dropEligibleSlot`): round 5 asked that, and its `musttail` POLICY conservatism
// turned an inner dead slot into a read, one clone level up into a LIVE outer slot,
// and bd `tzfa`'s wrong unitary back (bd `w7nm`, r5 F-Z-1). THE ONE SLOT QUESTION
// (Rule 14): the liveness call-slot rule, the rewrite, M-C arm (d0)
// (ArithLowering.cpp) and M-A's `cloneArgReachesResult` (RotationLowering.cpp) all
// ask THIS; only `resolvePhantomCloneArgReads` also asks the bare record, because
// it is the stage that resolves the difference (a recorded-dead, not null-safe
// slot: kept when its operand is classical, declined when quantum). A slot this
// calls "read" but the record calls dead is treated as READ everywhere — the
// conservative direction for each consumer (d0: not settled → the out-of-place
// path; M-A: a hop → more records; liveness: the operand survives).''')
sub('ir-pass/include/DeadValueLiveness.h', '''// now applies the drop's eligibility (`dropEligibleSlot`), and on an eligible slot''',
    '''// now asks `nullSafeSlot` (round 5 asked the drop's whole eligibility — bd `w7nm`),
// and on a null-safe slot''')

# ---- (2) Rule 14: M-C (d0) and M-A ask the same question
sub('ir-pass/src/ArithLowering.cpp', '''  // (d0) — a call that passes `P` only in slots the specializer RECORDED as dead
  // in the built clone (bd vsfp / bd hgwx; see above). Asked by CALLING the one
  // owner, `isRecordedDeadSlot`: a slot the clone reads — spec-quantum or any
  // real read — falls through to (d) unchanged.''', '''  // (d0) — a call that passes `P` only in slots the specializer RECORDED as dead
  // in the built clone (bd vsfp / bd hgwx; see above). Asked by CALLING the one
  // owner of the slot question, `isRewritableDeadSlot` (bd vsfp round 6, Rule 14 —
  // the question liveness and the rewrite ask; round 5 left this on the bare
  // `isRecordedDeadSlot`, two answers for one slot, r5 "not attacked"): a slot the
  // clone reads — spec-quantum or any real read — or a recorded-dead slot that is
  // not null-safe (its operand stays a use) falls through to (d) unchanged, the
  // conservative direction.''')
sub('ir-pass/src/ArithLowering.cpp', '''      if (!isRecordedDeadSlot(*CI, A, taint)) {
        ReadsP = true;
        break;
      }''', '''      if (!isRewritableDeadSlot(*CI, A, taint)) {
        ReadsP = true;
        break;
      }''')
sub('ir-pass/src/RotationLowering.cpp', '''    if (!isRecordedDeadSlot(*CI, K, taint))
      return true;
  }
  return false;
}''', '''    if (!isRewritableDeadSlot(*CI, K, taint))
      return true;  // a read, or a recorded-dead slot that is not null-safe (kept).
  }
  return false;
}''')
s = open(W + 'ir-pass/src/RotationLowering.cpp').read()
old = '''// WHAT THE TEST IS, PRECISELY (bd vsfp round 3): the specializer's RECORD — the
// slot is read iff the callee is a clone `buildClone` recorded and the record
// does not call the slot dead (`isRecordedDeadSlot`, taken with the liveness
// predicate on the clone's stock-opcode body).'''
new = '''// WHAT THE TEST IS, PRECISELY (bd vsfp round 3; round 6): the specializer's RECORD —
// the slot is read iff the callee is a clone `buildClone` recorded and the record
// does not call the slot dead AND null-safe (`isRewritableDeadSlot`, the one slot
// question liveness, the rewrite and M-C (d0) ask — Rule 14; round 3–5 asked the
// bare `isRecordedDeadSlot` here).'''
assert s.count(old) == 1
s = s.replace(old, new)
open(W + 'ir-pass/src/RotationLowering.cpp', 'w').write(s)

# resolve: its own use of the bare record, and its comment
sub('ir-pass/src/Specialization.cpp', '''  // 1. NEUTRALISE. Every recorded-dead slot of every call to a clone in a
  //    non-clone function that the drop's own eligibility admits (an int/fp scalar
  //    with allowlisted attributes — `dropEligibleSlot`) gets a null constant with
  //    the drop's `range`/`nofpclass` strip,''', '''  // 1. NEUTRALISE. Every recorded-dead slot of every call to a clone in a
  //    non-clone function that is NULL-SAFE (an int/fp scalar with allowlisted
  //    attributes — `nullSafeSlot`; never the drop's `musttail` policy, bd `w7nm`)
  //    gets a null constant with the `range`/`nofpclass` strip,''')
sub('ir-pass/src/Specialization.cpp', '''            // An INELIGIBLE slot (bd `91k9`, round 5: a pointer, a `byval`, an
            // attribute outside the drop's allowlist) is left in place.''', '''            // A slot that is not NULL-SAFE (bd `91k9`, round 5: a pointer, a
            // `byval`, an attribute outside the allowlist) is left in place. This
            // is the one consumer that asks both the bare record and the rewritable
            // question — it is where their difference is resolved.''')

# ---- (3) ad35: the implicit section is refused conservatively
sub('ir-pass/src/QramLowering.cpp', '''    // Not in a NAMED SECTION — explicit (`section "…"`) OR IMPLICIT (the
    // `bss-section`/`data-section`/`rodata-section`/`relro-section` attributes
    // `#pragma clang section` sets, which the backend honours and `hasSection()`
    // does not see: bd `qce6`, r4B F-YB-1, an MMIO `static volatile int STATUS;`
    // under the pragma folded to its initializer)''', '''    // Not in a NAMED SECTION — explicit (`section "…"`) OR IMPLICIT (the
    // `bss-section`/`data-section`/`rodata-section`/`relro-section` attributes
    // `#pragma clang section` sets and `hasSection()` does not see: bd `qce6`, r4B
    // F-YB-1, an MMIO `static volatile int STATUS;` under the pragma folded to its
    // initializer). ⚠ CONSERVATIVE, not exact (bd `ad35`, r5 F-Z-2): LLVM honours
    // such an attribute only when the object's section KIND matches
    // (`TargetLoweringObjectFile::SectionForGlobal`: `bss-section` only for a BSS
    // object, `rodata-section` only for a read-only one), so `bss=` on an
    // INITIALIZED `static volatile int K = 7;` actually lands in `__DATA,__data` and
    // is refused here anyway — an over-decline the owner prefers to a fold of
    // reachable-looking memory (deciding the kind exactly needs a TargetMachine).
    // Round 5's comment said these attributes are ones "the backend honours" —
    // false for a kind mismatch.''')
sub('ir-pass/include/QramLowering.h', '''// F-YB-1). Since round 5 the gate is: explicit section, implicit section
// (`hasImplicitSection()`), absolute symbol, and — owner decision 2026-09-27,''', '''// F-YB-1). Since round 5 the gate is: explicit section, implicit section
// (`hasImplicitSection()` — CONSERVATIVE: any pragma attribute, whether or not the
// object's section kind makes the backend honour it, bd `ad35`), absolute symbol,
// and — owner decision 2026-09-27,''')
sub(T, '''which the backend honours and `hasSection()` misses: an MMIO-style `static volatile int STATUS;` under the
pragma folded to its initializer in a quantum branch''', '''which the backend honours and `hasSection()` misses: an MMIO-style `static volatile int STATUS;` under the
pragma folded to its initializer in a quantum branch [⚠ CORRECTED round 6, bd `ad35` / r5 F-Z-2: the backend
honours the attribute only when the object's section KIND matches, so the refusal is CONSERVATIVE — any
pragma attribute, whether or not the kind matches (`bss=` on an initialized `K = 7` lands in `__DATA,__data`
and is refused anyway; the owner prefers that over-decline)]''')
sub(T, '''**Fix.** The pre-`specialize()` drop's own slot eligibility is now ONE exported predicate,
`dropEligibleSlot(CB, A)`''', '''**Fix.** [⚠ Round 6 (bd `w7nm`, r5 F-Z-1): the rewrite and the liveness rule asking the WHOLE
`dropEligibleSlot` below was itself a P1 — its `musttail` policy made an inner dead slot a read and brought
bd `tzfa` back; round 6 splits out `nullSafeSlot` for them, §R6.1.] The pre-`specialize()` drop's own slot
eligibility is now ONE exported predicate, `dropEligibleSlot(CB, A)`''')
print('ok')
