"""bd vsfp final (post-round-6) COMMENT/RECORD-ONLY edits: x8ut, xmew, nlfd, landing."""
W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
T = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md'


def sub(path, old, new, n=1):
    p = W + path
    s = open(p).read()
    assert s.count(old) == n, (path, s.count(old), old[:80])
    s = s.replace(old, new)
    open(p, 'w').write(s)


# ---- x8ut + nlfd: the "conservative for each consumer" sentence, at the source
sub('ir-pass/include/DeadValueLiveness.h', '''// slot: kept when its operand is classical, declined when quantum). A slot this
// calls "read" but the record calls dead is treated as READ everywhere — the
// conservative direction for each consumer (d0: not settled → the out-of-place
// path; M-A: a hop → more records; liveness: the operand survives).''', '''// slot: kept when its operand is classical, declined when quantum). A slot this
// calls "read" but the record calls dead is treated as READ everywhere. ⚠ That is
// NOT "the conservative direction for each consumer", which round 6 wrote here
// (bd vsfp Rule-13 r6: F-R6-1 / bd `nlfd`, F-R6-2 / bd `x8ut`). Per consumer:
//   * M-C (d0): conservative — "not settled" falls to the out-of-place path.
//   * LIVENESS: NOT conservative (bd `nlfd`, OPEN, P2, IR-only). A read counted
//     here propagates one clone level up through `deadParamMask`: a recorded-dead
//     inner slot that is not null-safe makes the enclosing clone's parameter LIVE,
//     the outer (null-safe) phantom slot is never neutralised, and bd `tzfa`'s
//     wrong unitary is back (r6 `sa1.ll`: a string attribute on the inner slot;
//     exit 0, warned, the ORACLE's stream). IR-only as far as measured: clang-19
//     `-O1` emits only allowlisted attributes on int/fp parameters, and `musttail`
//     (the one C-reachable reason, bd `w7nm`) is no longer a null-safety reason.
//   * M-A (`cloneArgReachesResult`): NOT conservative — its one caller,
//     `reachesObservingSink`, is the clause-3 EXEMPTION walk, where a hop EXEMPTS
//     a record. It is UNREACHABLE today: M-A gates are rotations, which occur only
//     in non-clone functions (`scanBody` declines `cq_theta` in a clone), and there
//     `resolvePhantomCloneArgReads` step 1 DECLINES a quantum operand in a
//     recorded-dead, not-null-safe slot before `lowerRotations` runs.
//     RETIREMENT TRIGGER (L8): the day that decline is relaxed or moved after
//     `lowerRotations`, or a rotation can occur inside a clone body, M-A must go
//     back to the bare `isRecordedDeadSlot` (its honest question is "does the
//     clone's result depend on this argument?", not "is a null safe here?").''')

sub('ir-pass/src/RotationLowering.cpp', '''// WHAT THE TEST IS, PRECISELY (bd vsfp round 3; round 6): the specializer's RECORD —
// the slot is read iff the callee is a clone `buildClone` recorded and the record
// does not call the slot dead AND null-safe (`isRewritableDeadSlot`, the one slot
// question liveness, the rewrite and M-C (d0) ask — Rule 14; round 3–5 asked the
// bare `isRecordedDeadSlot` here).''', '''// WHAT THE TEST IS, PRECISELY (bd vsfp round 3; round 6): the specializer's RECORD —
// the slot is read iff the callee is a clone `buildClone` recorded and the record
// does not call the slot dead AND null-safe (`isRewritableDeadSlot`, the one slot
// question liveness, the rewrite and M-C (d0) ask — Rule 14; round 3–5 asked the
// bare `isRecordedDeadSlot` here). ⚠ NOT CONSERVATIVE HERE (bd `x8ut`, r6 F-R6-2):
// this predicate's one caller is `reachesObservingSink`, the clause-3 EXEMPTION
// walk, so a hop EXEMPTS a record; round 6 moved a recorded-dead, not-null-safe
// slot from "no hop" to "hop" — the exempting direction — and called it
// conservative. It is UNREACHABLE today, and that is the whole argument: M-A gates
// are rotations, rotations occur only in non-clone functions (`scanBody` declines
// `cq_theta` in a clone), and there `resolvePhantomCloneArgReads` step 1 DECLINES a
// quantum operand in a recorded-dead, not-null-safe slot before `lowerRotations`.
// RETIREMENT TRIGGER (L8): if that decline is relaxed or moved after
// `lowerRotations`, or a rotation can occur inside a clone body, revert this test
// to the bare `isRecordedDeadSlot` — the honest question here is "does the clone's
// result depend on this argument?", whatever null-safety says.''')
sub('ir-pass/src/RotationLowering.cpp', '''      return true;  // a read, or a recorded-dead slot that is not null-safe (kept).''',
    '''      return true;  // a read, or a recorded-dead, not-null-safe slot (kept) — the
                    // EXEMPTING direction; unreachable today (bd x8ut, see above).''')

# ---- xmew: the naked retirement note at nullSafeSlot
sub('ir-pass/include/SpecializeDetect.h', '''// `byval` slot compiled clean and the executable SIGSEGVed. This is the ONLY slot
// question the post-`specialize()` rewrite and the liveness call-slot rule ask
// (`isRewritableDeadSlot`, DeadValueLiveness.h).
bool nullSafeSlot(const llvm::CallBase &CB, unsigned A);''', '''// `byval` slot compiled clean and the executable SIGSEGVed. This is the ONLY slot
// question the post-`specialize()` rewrite and the liveness call-slot rule ask
// (`isRewritableDeadSlot`, DeadValueLiveness.h).
// ⚠ IT ASKS NO CALLEE CONJUNCT, and that admits `naked` clones (bd `xmew`, r6
// F-R6-3): `CloneFunction` copies `naked` onto the clone, so round 6 rewrites a
// naked clone's dead slot where round 5 declined (an unannounced D→A, IR-only probe
// `nk5.ll`). The other callee conjuncts are vacuous for a clone (a definition,
// internal, never variadic, `getCalledFunction()` is null on a type mismatch).
// `naked` is SOUND today for two facts nothing here asks: the verifier forbids any
// use of a naked function's arguments, and `scanBody` declines inline asm, so no
// clone body can observe the slot. bd ctz4's hazard (inline asm reading the
// argument REGISTERS) is therefore held off ONLY by `scanBody`'s inline-asm decline.
// RETIREMENT TRIGGER (L8): the day `scanBody` admits any inline asm, this predicate
// must refuse a `naked` callee, or ctz4's wrong value comes back through the rewrite.
bool nullSafeSlot(const llvm::CallBase &CB, unsigned A);''')

# ---- TRACK §R6.2: mark the falsified sentence and the W2 instrument gap
sub(T, '''READ everywhere — the conservative direction for each consumer (d0: not settled → out of place; M-A: a hop
→ more records; liveness: the operand survives). The comment in `DeadValueLiveness.h` states this.''',
    '''READ everywhere — the conservative direction for each consumer (d0: not settled → out of place; M-A: a hop
→ more records; liveness: the operand survives). The comment in `DeadValueLiveness.h` states this.
⚠ **FALSE for two of the three (Rule-13 r6, `review_r6_vsfp/REVIEW.md`; corrected at the source, §R7):**
d0 holds; **liveness** is not conservative — a read propagates one clone level up and a not-null-safe inner
dead slot brings bd `tzfa` back (F-R6-1, bd `nlfd`, OPEN, IR-only); **M-A** is not conservative — its one
caller is the clause-3 EXEMPTION walk, where a hop EXEMPTS a record (F-R6-2, bd `x8ut`), unreachable today
only because `resolvePhantomCloneArgReads` step 1 declines a quantum operand in such a slot first.''')
sub(T, '''byte-identically under the SUBJECT and W2. W2 went 0/2405 on the suite. The change is uniformity (Rule 14),
not a stream change.''', '''byte-identically under the SUBJECT and W2. W2 went 0/2405 on the suite. The change is uniformity (Rule 14),
not a stream change. ⚠ **The probe was the wrong instrument** (r6 F-R6-1): `w2probe.ll`'s inner-slot operand
is ALSO read live in `h` (`%u = add %p, %t`), so there was no phantom read to expose, and it was compared
against W2, never against a twin. The shape that matters is the one where the not-null-safe inner slot is
the outer parameter's ONLY reader (r6 `sa1.ll`).''')
print('ok')
