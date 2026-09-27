W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
p = W + 'ir-pass/include/DeadValueLiveness.h'
s = open(p).read()
old = '''// re-`propagate`s when its stage returns true; `declineStaleTaintSet` re-derives
// the set before `detectSpecializations` so an omission is loud. A caller added
// AFTER the guards owes `adjudicateTaintDelta`, not just a `propagate` (L1).'''
new = '''// re-`propagate`s when its stage returns true; `declineStaleTaintSet` re-derives
// the set before `detectSpecializations` so an omission is loud. A caller added
// AFTER the guards owes `adjudicateTaintDelta`, not just a `propagate` (L1). The
// one post-`specialize()` caller, `buildClone` (bd sqjq, round 4), runs on a clone
// body that `lowerCloneControl`'s backstop has already made ONE BLOCK, so the fold
// cannot fire there and no select is created — it only deletes.
//
// Round-4 contract items (bd vsfp Rule-13 r3A/r3B):
//   * the fold's condition seeds are `WeakTrackingVH`s (bd 1xp9): a seed that is
//     an `i1` φ in an earlier fold's merge block is erased by that block's merge
//     and the handle FOLLOWS its RAUW to the replacement, so the recursion never
//     reads freed memory and still deletes the replacement if it is dead;
//   * the two-entry-φ fold goes through `simplifySelectInst` first (`select %c,
//     i1 true, i1 false` IS `%c`), as SimplifyCFG's own fold does;
//   * a dead value that is an operand of a LIVE call in a slot the specializer
//     RECORDED dead (the call-slot rule) is replaced there by a null of the
//     CALLEE PARAMETER's type before deletion — an inner clone call inherits the
//     dead slot; unreachable before `specialize()`, whose record is empty.'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

p = W + 'ir-pass/src/Specialization.cpp'
s = open(p).read()
old = '''  // stock-opcode body, where every read is still visible as a stock use.
  if (DeadSlots) {'''
new = '''  // stock-opcode body, where every read is still visible as a stock use. The clone
  // is ONE BLOCK here (`lowerCloneControl`'s backstop), so `deleteDeadCones`' arm
  // fold cannot fire and no tainted value is created: the call only deletes dead
  // instructions, whose `cloneTaint` keys self-scrub (`ScrubOnDelete.h`), and none
  // of them is in `TaintedCloneCalls` (a clone call is a liveness root).
  if (DeadSlots) {'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
