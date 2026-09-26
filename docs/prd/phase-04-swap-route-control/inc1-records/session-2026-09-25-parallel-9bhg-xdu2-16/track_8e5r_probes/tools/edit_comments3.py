#!/usr/bin/env python3
"""Step 4 part 3 — the remaining COMMENT edits (ScrubOnDelete.h order + the
precondition/empty()/cost paragraph, SwapRouteEmit.h, the three empty() readers,
F-EB-5 scope wording in the fixture/CMake comments)."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/"


def rep(path, a, b):
    p = W + path
    s = open(p).read()
    assert s.count(a) == 1, (path, a[:80], s.count(a))
    open(p, "w").write(s.replace(a, b))


SC = "ir-pass/include/ScrubOnDelete.h"
rep(SC, """//       tables in order. With deferred removal the surviving keys keep EXACTLY
//       the slots and the order they had on the unfixed binary; the only""",
    """//       tables in order. With deferred removal the surviving keys keep EXACTLY
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

rep("ir-pass/include/SwapRouteEmit.h",
    """//      defence — and the ~180 erase sites that never scrubbed are covered too); then""",
    """//      defence — and the other IR-deleting sites, most of which never scrubbed,
//      are covered too: 133 static sites, 29 dynamic unscrubbed producers); then""")

# ---- F-EA-8 at the three event-witness readers ----------------------------
rep("ir-pass/src/OpcodeLowering.cpp", """  if (taint.LiftedConsumers.empty())""",
    """  // ⚠ `empty()` counts LIVE members only (bd 8e5r, r1A F-EA-8): this asks "a
  // lift occurred and a recorded consumer is still alive". Argued equal to "a
  // lift occurred" here — nothing erases between `declineClassicalMuxes` and
  // this re-sweep, and a lifted φ that was itself a recorded consumer contributes
  // its own consumers. An erasing stage placed in that window must re-ask it.
  if (taint.LiftedConsumers.empty())""")
rep("ir-pass/src/LoopLowering.cpp", """  if (taint.InLoopFlattenedPreds.empty())
""", """  // ⚠ `empty()` counts LIVE Preds only (bd 8e5r, r1A F-EA-8): "a region was
  // emitted into a block that still exists". A recorded Pred survives its own
  // flatten (it is the block the diamond splices INTO), so this equals "a region
  // was emitted" today; an erasing stage between the flatten and here re-asks it.
  if (taint.InLoopFlattenedPreds.empty())
""")
rep("ir-pass/src/TaintPropagation.cpp", """  if (taint.UntaintedMergeRails.empty())
    return;  // no 6.5 classical-call arm / 4.5 switch data-mux region emitted.""",
    """  // ⚠ `empty()` counts LIVE rails only (bd 8e5r, r1A F-EA-8): it is empty here
  // only if every recorded `%out` is gone — and then there is nothing left to
  // re-propagate FROM, so the early return is still right.
  if (taint.UntaintedMergeRails.empty())
    return;  // no 6.5 classical-call arm / 4.5 switch data-mux region emitted.""")

# ---- F-EB-5: scope the "maximal reuse" wording ------------------------------
rep("ir-pass/test/spec_scrub_dangling_key_clone_classical_mul.ll",
    """;   lifo   — maximal exact-class address reuse: the unfixed binary is WRONG""",
    """;   lifo   — exact-class LIFO address reuse for the blocks the test allocator
;            manages (non-aligned new/delete: IR objects, hooks, std nodes —
;            see cq_debug_alloc.cpp's SCOPE): the unfixed binary is WRONG""")
rep("tests/e2e/CMakeLists.txt",
    """# `cq-opt-debugalloc` (cq-opt's own objects + ir-pass/tools/cq_debug_alloc.cpp)
# in the test allocator's maximal-reuse mode: the unfixed""",
    """# `cq-opt-debugalloc` (cq-opt's own objects + ir-pass/tools/cq_debug_alloc.cpp)
# in the test allocator's exact-class LIFO reuse mode (non-aligned new/delete
# only — the IR-object population this defect lives in): the unfixed""")
print("ok part 3")
