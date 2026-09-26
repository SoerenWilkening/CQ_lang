#!/usr/bin/env python3
"""Step 4 part 4 — COMMENTS ONLY: the lower-priority scrub rationales (r1A F-EA-3
tail) that still present the explicit scrub as THE defence."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/"


def rep(path, a, b):
    p = W + path
    s = open(p).read()
    assert s.count(a) == 1, (path, a[:80], s.count(a))
    open(p, "w").write(s.replace(a, b))


NOTE = "belt-and-braces since bd 8e5r: every TaintSet table drops a deleted key by itself, `ScrubOnDelete.h`"
rep("ir-pass/src/ArithLowering.cpp",
    """// compare (a verify-clean miscompile). The erase happens UNCONDITIONALLY (even
// when `handleWidth` is empty) so no stale `orig` record survives.""",
    """// compare (a verify-clean miscompile). The erase happens UNCONDITIONALLY (even
// when `handleWidth` is empty) so no stale `orig` record survives. (Now
// """ + NOTE + """ — so this erase is no longer the only thing between a
// reused address and a wrong width.)""")
rep("ir-pass/src/SelectMergeEmit.cpp",
    """  // width waiting to happen. Vacuous for today's erased classes; closed by
  // construction.""",
    """  // width waiting to happen. Vacuous for today's erased classes; closed by
  // construction. (All of this function is now """ + NOTE + """.)""")
rep("ir-pass/src/TaintPropagation.cpp",
    """    // scrubTaint / freeze-fold precedent — a later allocation could alias the
    // address). The operand keeps its own BirthOrder/HandleWidth; a fold mints no""",
    """    // scrubTaint / freeze-fold precedent — a later allocation could alias the
    // address; """ + NOTE + """). The operand keeps its own BirthOrder/HandleWidth; a fold mints no""")
rep("ir-pass/src/TaintPropagation.cpp",
    """  // precedent — a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it), and erase. The downstream measure/return/uncompute""",
    """  // precedent — a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it; """ + NOTE + """), and erase. The downstream measure/return/uncompute""")
rep("ir-pass/src/TaintPropagation.cpp",
    """  // a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it), and erase.
  //
  // Witness that a lift OCCURRED""",
    """  // a freed Instruction* must not linger in `Tainted` where a later
  // allocation could alias it; """ + NOTE + """), and erase.
  //
  // Witness that a lift OCCURRED""")
print("ok part 4")
