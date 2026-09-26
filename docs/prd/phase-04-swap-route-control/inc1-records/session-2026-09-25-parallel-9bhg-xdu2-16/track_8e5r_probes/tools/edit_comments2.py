#!/usr/bin/env python3
"""Step 4 part 2 — COMMENTS ONLY: ClaimedRailRoots triggers, "~180" -> 133,
"cannot move" -> "measured not to move", F-EA-5 precondition, F-EA-8 empty()
semantics, F-EB-5 "maximal reuse" scope in the fixture/CMake/e2e comments."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/"


def rep(path, a, b):
    p = W + path
    s = open(p).read()
    assert s.count(a) == 1, (path, a[:80], s.count(a))
    open(p, "w").write(s.replace(a, b))


TP = "ir-pass/include/TaintPropagation.h"
rep(TP, """  // ⚠ RETIREMENT TRIGGER: if a stage that erases a `cq_theta` is ever placed
  // between `lowerLoops` and the round-2 collapse, this set needs a
  // `WeakTrackingVH` or a re-validation, because a recycled address matching a
  // live peel root would SKIP a candidate that must be judged — the over-accept
  // direction, not the leak direction.""",
    """  // ⚠ RETIREMENT TRIGGER — DISCHARGED BY bd 8e5r (r1A F-EA-3): it said that if
  // a stage that erases a `cq_theta` were ever placed between `lowerLoops` and
  // the round-2 collapse, this set would need a handle or a re-validation,
  // because a recycled address matching a live peel root would SKIP a candidate
  // that must be judged. The set is now a `scrub::PairSet`: a pair is DROPPED
  // when EITHER half is deleted, so a recycled address can no longer match.""")
rep(TP, """  // `claimedHERE=1`), but a stage that ever erases a loop header here wants a
  // `WeakTrackingVH` or a re-validation on BOTH halves of the key.""",
    """  // `claimedHERE=1`). ⚠ DISCHARGED BY bd 8e5r: the "handle or re-validation on
  // BOTH halves" this sentence asked for is what `scrub::PairSet` does — a pair
  // dies with its root OR its header, so no recycled address can match.""")
rep(TP, """// NOT a member. Before this, ~180 erase sites each had to remember to scrub each""",
    """// NOT a member. Before this, the 133 IR-deleting sites in `ir-pass/src/`
// (measured: 121 `eraseFromParent` + 12 LLVM utilities; 63 of them scrubbed
// something nearby, the rest nothing) each had to remember to scrub each""")
rep(TP, """//   * A deleted key is only MARKED dead, never physically removed, so surviving
//     keys keep the slots and the iteration order they had before (the emitted
//     stream cannot move), and a loop may erase the instruction it is visiting.""",
    """//   * A deleted key is only MARKED dead, never physically removed, so surviving
//     keys keep the slots and the iteration order they had before, and a loop may
//     erase the instruction it is visiting. ⚠ "The stream does not move" is
//     MEASURED, not guaranteed by construction (r1A F-EA-3): the hooks themselves
//     allocate, so absolute addresses — and `Tainted`'s address order — differ
//     from the unfixed binary. Measured: 0 stream movers on the shipped corpus vs
//     the oracle, and allocator-independence across system / LIFO / no-reuse /
//     scribble / 3 shuffle seeds (TRACK_8E5R.md §6.3, r1A I2/I3).
//   * PRECONDITION (r1A F-EA-5): never INSERT a pointer to an already-deleted
//     Value. Arming a key's `CallbackVH` reads the Value (`getContext()`), so a
//     dead-pointer insert is a use-after-free — a raw container merely stored it.
//     No insert site in the pass does this (r1A I1: 0 dead inserts over the
//     corpus); a future table filled from a RAW record (a local snapshot, a
//     `ControlRegion` field) must check liveness first.
//   * `empty()` / `size()` count LIVE keys (r1A F-EA-8). A set used as an EVENT
//     WITNESS ("a lift occurred": `LiftedConsumers`; "a region was emitted":
//     `InLoopFlattenedPreds`, `UntaintedMergeRails`) now reads "a live member
//     remains", not "it was ever recorded". Argued not to flip at any of its
//     three readers (nothing erases a recorded member in those windows; r1A I1:
//     0 flips) — a new erasing stage inside one of those windows must re-ask it.""")

SC = "ir-pass/include/ScrubOnDelete.h"
rep(SC, """// scrub every table first. There are ~180 erase sites in `ir-pass/src/` plus
// the LLVM utilities that delete internally, and at least seven of them did not""",
    """// scrub every table first. There are 133 IR-deleting sites in `ir-pass/src/`
// (measured: 121 `eraseFromParent` + 12 LLVM utilities that delete internally),
// and dynamically 29 producer functions deleted a key nobody scrubbed; the
// Rule-13 r1B detector had named seven of them — they did not""")
rep(SC, """// the ITERATION ORDER of the surviving keys — and several emitters walk these
//       tables in order. With deferred removal the surviving keys keep EXACTLY
//       the slots and the order they had on the unfixed binary; the only""",
    """// the ITERATION ORDER of the surviving keys — and several emitters walk these
//       tables in order. With deferred removal the surviving keys keep EXACTLY
//       the slots and the order they had on the unfixed binary UNDER THE SAME
//       ALLOCATION SEQUENCE (the hooks allocate, so absolute addresses differ —
//       "the stream does not move" is MEASURED, r1A F-EA-3); the only""")
rep(SC, """// Cost: one heap-allocated `CallbackVH` per distinct key per container, and a
// dead-set probe on each query (skipped when nothing has died).""",
    """// ⚠ PRECONDITION (Rule-13 r1A F-EA-5): never INSERT (or `operator[]`) a pointer
// to an ALREADY-DELETED Value. Arming the key's `CallbackVH` reads the Value
// (`AddToUseList` -> `getContext()`), so that is a use-after-free that also
// registers a handle on freed memory; a raw container merely stored the pointer.
// No insert site in the pass does it (0 dead inserts measured over the corpus);
// fill a table from a RAW record only after a liveness check.
//
// ⚠ `empty()` / `size()` COUNT LIVE KEYS (r1A F-EA-8): a set used as an EVENT
// WITNESS means "a live member remains", not "something was ever recorded".
//
// Cost: one heap-allocated `CallbackVH` per distinct key per container, and a
// dead-set probe on each query (skipped when nothing has died). Measured +1.2%
// ± 0.35% CPU per `cq-opt` invocation, all of it LAUNCH cost (r1B §6).""")

SR = "ir-pass/include/SwapRouteEmit.h"
rep(SR, """//      defence — and the ~180 erase sites that never scrubbed are covered too); then""",
    """//      defence — and the other IR-deleting sites, most of which never scrubbed,
//      are covered too: 133 static sites, 29 dynamic unscrubbed producers); then""")

# F-EA-8 at the three readers
rep("ir-pass/src/OpcodeLowering.cpp", "LiftedConsumers.empty()", "LiftedConsumers.empty()")  # presence check
open("/dev/null", "w")
print("ok part 2 (OpcodeLowering site to be annotated by hand)")
