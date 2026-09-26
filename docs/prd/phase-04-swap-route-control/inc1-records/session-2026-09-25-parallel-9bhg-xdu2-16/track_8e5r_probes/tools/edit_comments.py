#!/usr/bin/env python3
"""Step 4 — COMMENTS ONLY (Rule-13 r1A F-EA-3 / F-EA-5 / F-EA-8, r1B F-EB-5).
Every replacement is inside a comment; asserted by the caller with a
comment-stripped diff (tools: strip_diff.py)."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/"


def rep(path, a, b):
    p = W + path
    s = open(p).read()
    assert s.count(a) == 1, (path, a[:80], s.count(a))
    open(p, "w").write(s.replace(a, b))


# ---- F-EA-3: LoopLowering.cpp:~5218 InPlaceRailOps "NOTHING SCRUBS" --------
rep("ir-pass/src/LoopLowering.cpp",
    """// ⚠ RESIDUAL, STATED RATHER THAN MITIGATED AWAY (bd `test_C_libtooling-f8eu`
// family / round 1β caution (a)): `taint.InPlaceRailOps` is a raw `Instruction *`
// set that NOTHING SCRUBS on erase, so in principle a recycled allocation could
// make a NEW instruction test as marked. The shape precondition is the only thing
// standing in front of that — a recycled address would have to land on a tainted,
// dtzb-shaped (`add`/`xor` + exactly one tainted operand + integer <= 64) binop
// whose recorded index still names the right operand. That is a corroboration and
// NOT a proof. The proper close is to scrub `InPlaceRailOps`/`InPlaceRailIdx`
// alongside `Tainted` at the erase sites; it is deliberately NOT done here
// because it changes what `lowerOps` and `railValueConsumerDisposition` see for
// every module in the tree and belongs in its own red-green increment.""",
    """// ⚠ RESIDUAL — CLOSED BY CONSTRUCTION SINCE bd 8e5r (was: bd
// `test_C_libtooling-f8eu` family / round 1β caution (a)). This used to say that
// `taint.InPlaceRailOps` was a raw `Instruction *` set NOTHING SCRUBBED on erase,
// so a recycled allocation could make a NEW instruction test as marked, with only
// the dtzb shape precondition standing in front of it, and that "the proper close
// is to scrub `InPlaceRailOps`/`InPlaceRailIdx` alongside `Tainted`". That close
// has LANDED, totally: both are self-cleaning (`ScrubOnDelete.h`) — a deleted key
// is dropped by LLVM's own `~Value()` callback, and a fresh object at its address
// is NOT a member. The shape precondition is now defence in depth, not the defence
// (Rule-13 r1A F-EA-3, corrected at the source — L7).""")

# ---- F-EA-3: LoopLowering.cpp:~6247 IterationLocalBlocks "raw ... nothing scrubs"
rep("ir-pass/src/LoopLowering.cpp",
    """// ⚠ It is asked on a FRESHLY BUILT `LoopInfo` rather than on
// `taint.IterationLocalBlocks`, on purpose: that set is a raw `BasicBlock *` set
// nothing scrubs, and a stale-TRUE there would be the GRANTING direction here.""",
    """// ⚠ It is asked on a FRESHLY BUILT `LoopInfo` rather than on
// `taint.IterationLocalBlocks`, on purpose: a stale-TRUE there would be the
// GRANTING direction here. (The set is no longer raw — bd 8e5r made it
// self-cleaning, `ScrubOnDelete.h` — so the stale-TRUE this comment feared cannot
// arise from an erased block any more; the fresh `LoopInfo` stays, as the
// independent answer. Corrected, r1A F-EA-3.)""")

# ---- F-EA-3: LoopLowering.cpp:~6652 InPlaceRailOps "NEVER scrubbed" ---------
rep("ir-pass/src/LoopLowering.cpp",
    """      // 2, finding F-W2-4, 2026-09-14). `taint.InPlaceRailOps` is a
      // `SmallPtrSet<Instruction *>` whose only removal is
      // `invariantRegisterRoots`' rollback: it is NEVER scrubbed when an
      // instruction is erased, and this consumer uses MEMBERSHIP TO SUPPRESS A
      // SAFETY CHECK — the ACCEPT direction, which is F-W1-1's shape one
      // container over (there the dangling key was a `Loop *`). A recycled
      // `Instruction *` would silently exclude a REAL discharge candidate.""",
    """      // 2, finding F-W2-4, 2026-09-14). `taint.InPlaceRailOps` WAS a raw
      // `SmallPtrSet<Instruction *>` whose only removal was
      // `invariantRegisterRoots`' rollback — NEVER scrubbed when an instruction
      // was erased — and this consumer uses MEMBERSHIP TO SUPPRESS A SAFETY
      // CHECK, the ACCEPT direction (F-W1-1's shape one container over, where the
      // dangling key was a `Loop *`): a recycled `Instruction *` would silently
      // have excluded a REAL discharge candidate. ⚠ Since bd 8e5r the set is
      // self-cleaning (`ScrubOnDelete.h`), so a recycled address is no longer a
      // member at all; this conjunct is now defence in depth (r1A F-EA-3).""")
rep("ir-pass/src/LoopLowering.cpp",
    """      // covering every `BinaryOperator` member, the second half of the argument
      // goes with them and this set needs a real scrub (`WeakTrackingVH`, or an
      // erase-site scrub) instead.""",
    """      // covering every `BinaryOperator` member, the second half of the argument
      // goes with them. (The "real scrub" this trigger used to ask for has
      // landed — bd 8e5r's self-cleaning containers — so the recycled-address
      // half is closed by construction; the tripwire half still stands.)""")

# ---- F-EA-3: LoopLowering.cpp:~7176-7211 IterationLocalBlocks ---------------
rep("ir-pass/src/LoopLowering.cpp",
    """      // ⚠ `taint.IterationLocalBlocks` IS A RAW `BasicBlock *` SET THAT NOTHING
      // EVER SCRUBS (`grep -rn 'IterationLocalBlocks\\.\\(erase\\|clear\\)'` finds
      // nothing) AND THIS READ IS IN THE ACCEPT DIRECTION — a stale pointer that
      // matched a live block would keep `Marked` true for a block never marked,
      // which is F-W1-1's shape one container over. It is asked and answered
      // here rather than assumed (review round 2, finding F-W2-4, 2026-09-14).""",
    """      // ⚠ HISTORY, CLOSED BY CONSTRUCTION SINCE bd 8e5r (r1A F-EA-3): this read
      // is in the ACCEPT direction, and `taint.IterationLocalBlocks` USED TO BE a
      // raw `BasicBlock *` set nothing ever scrubbed — a stale pointer that
      // matched a live block would have kept `Marked` true for a block never
      // marked (F-W1-1's shape one container over; review round 2, F-W2-4,
      // 2026-09-14). It is now self-cleaning (`ScrubOnDelete.h`): a BasicBlock IS
      // a Value, its deletion notifies the set, and a fresh block at a dead
      // block's address is NOT a member. The analysis below — why no block is
      // CREATED in the window — was the defence before; it is kept as the
      // record of why the old raw set never fired.""")
rep("ir-pass/src/LoopLowering.cpp",
    """      // An address freed here can therefore only be re-occupied by a NON-block
      // allocation, which `L->blocks()` never yields. No scrub is needed and a
      // `WeakTrackingVH` would not even apply (it tracks `Value`s, and a
      // `BasicBlock` erase does not null one held in a `SmallPtrSet` key).
      // ⚠ RETIREMENT TRIGGER, and it is a SHORT list to re-check: the day any
      // block-creating stage is moved (or added) between `lowerLoops` and
      // `declineUnmarkedRolledIterLocal` in EITHER entry point, this read needs
      // a real scrub at the erase sites in `RegionFlatten.cpp`.
      // ⚠ NOT A CLEAN BILL FOR THE SET ITSELF: its OTHER consumers, `FreePoint`
      // and `Uncomputation`, run at `uncompute` — AFTER `lowerBreakReversePlay`
      // creates blocks — and read it in the same relaxing direction ("a block
      // NOT in this set keeps both guards"). That exposure is PRE-EXISTING, is
      // not this stage's, and is filed rather than silently inherited.""",
    """      // An address freed here could therefore only be re-occupied by a
      // NON-block allocation, which `L->blocks()` never yields.
      // ⚠ CORRECTED (r1A F-EA-3, L7): this comment used to add that "a
      // `WeakTrackingVH` would not even apply (it tracks `Value`s …)". A
      // `BasicBlock` IS a `Value`, and bd 8e5r's `CallbackVH`-hooked set is the
      // counterexample. Its RETIREMENT TRIGGER ("the day a block-creating stage
      // moves into the window, this read needs a real scrub at the erase sites")
      // is DISCHARGED — the scrub is total now, at deletion, whoever erases — and
      // so is the "NOT A CLEAN BILL" exposure it named for the set's other
      // consumers (`FreePoint` / `Uncomputation`, which run after
      // `lowerBreakReversePlay` creates blocks): a recycled block address is no
      // longer a member for them either.""")

# ---- F-EA-3: ClaimedRailRoots trigger (TaintPropagation.h) -----------------
import re
p = W + "ir-pass/include/TaintPropagation.h"
s = open(p).read()
i = s.find("ClaimedRailRoots;")
j = s.rfind("RETIREMENT", 0, i)
assert j > 0
print("ClaimedRailRoots trigger context:\n" + s[j - 1200:i + 20])
