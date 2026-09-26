W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
p = W + 'ir-pass/src/Specialization.cpp'
s = open(p).read()
old = '''  // calls, which are roots, and would make every parameter live. A slot recorded
  // here is one the built clone never reads — the question the phantom-read
  // backstop and M-C arm (d0) ask, by CALLING `isRecordedDeadSlot`.'''
new = '''  // calls, which are roots, and would make every parameter live. A slot recorded
  // here is one no LIVE ROOT of the clone reads — and, since bd vsfp round 4 (bd
  // sqjq), one the built clone never reads at all, because the dead cone below is
  // deleted right after the record (⚠ round 3 wrote "never reads" of the record
  // alone, and a dead-but-lowered op on the slot falsified it, r3A F-XA-2). It is
  // the question the phantom-read resolution and M-C arm (d0) ask, by CALLING
  // `isRecordedDeadSlot`.'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

p = W + 'ir-pass/include/Specialization.h'
s = open(p).read()
old = '''// pass's ONE liveness predicate, `DeadValueLiveness.h`) names the slots each built
// clone never reads. A call in a NON-clone function that passes a value in such a
// slot is a read only the compiler performs.'''
new = '''// pass's ONE liveness predicate, `DeadValueLiveness.h`) names the slots each built
// clone never reads — EXACTLY since bd vsfp round 4: `buildClone` deletes the dead
// cone of every recorded-dead parameter right after taking the record (bd sqjq;
// round 3's record left a dead-but-lowered op on the slot, which then read runtime
// handle h0 once the caller's slot was a constant, r3A F-XA-2). A call in a
// NON-clone function that passes a value in such a slot is a read only the
// compiler performs.'''
assert s.count(old) == 1
s = s.replace(old, new)
old = '''// (1) It NEUTRALISES every one: the operand becomes a null constant (the drop's
// rewrite, `range`/`nofpclass` stripped), so no later stage can see the phantom
// read.'''
new = '''// (1) It NEUTRALISES every one: the operand becomes a null constant OF THE CALLEE
// PARAMETER'S TYPE (the drop's rewrite, `range`/`nofpclass` stripped; bd f061 —
// round 3 took the caller operand's fp type for an `i32` handle slot and the
// verifier aborted), so no later stage can see the phantom read.'''
assert s.count(old) == 1
s = s.replace(old, new)
old = '''// operand is QUANTUM (tainted, or a control-emitted rail) and the user program no
// longer reads it:'''
new = '''// operand is QUANTUM (tainted, or a control-emitted rail) and the user program no
// longer reads it (every use but the DESTINATION slot of a basis copy is a read —
// bd xh17):'''
if s.count(old) == 1:
    s = s.replace(old, new)
else:
    print('WARN: decline sentence not found verbatim')
open(p, 'w').write(s)

p = W + 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md'
s = open(p).read()
old = '''it re-opens bd tzfa with no diagnostic). Soundness rests on the record: the clone never reads the slot
(r2B verified the record and that no later clone pass adds a read), so the constant is unobservable
— including through the clone's `_unc` twin, a verbatim copy of the same body.'''
new = '''it re-opens bd tzfa with no diagnostic). Soundness rests on the record: the clone never reads the slot
(r2B verified the record and that no later clone pass adds a read), so the constant is unobservable
— including through the clone's `_unc` twin, a verbatim copy of the same body. ⚠ **FALSE AS WRITTEN
(Rule-13 r3A F-XA-2, bd sqjq):** the record says no LIVE ROOT reads the slot, not that no instruction
does — a dead-but-lowered op on it (the chain of a compare the clone's flatten deleted, or `a+1` passed
into an inner clone's dead slot) read runtime handle h0 once the slot was 0. Made true in round 4
(§R4.3) by deleting that dead cone after the record.'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
