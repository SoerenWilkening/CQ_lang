#!/usr/bin/env python3
"""Add the bd um24 deterministic-allocator RUN line to the four fixtures whose
decline the unfixed `lowerLoops` prescan turned into a SIGSEGV."""
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/ir-pass/test/"
NOTE = (
    "; bd test_C_libtooling-um24 — the SAME decline under the no-reuse test allocator\n"
    "; (`CQ_OPT_DEBUG_ALLOC=nofree`, cq-opt only). The unfixed `lowerLoops` prescan\n"
    "; called `getFunction()` on a `taint.Tainted` key an earlier stage had ERASED;\n"
    "; with no reuse the dead object's parent is null, so the unfixed binary SIGSEGVs\n"
    "; here DETERMINISTICALLY (measured on oracle `def1b088` + the test allocator), and\n"
    "; `not` fails on a crash. The system allocator hid it by reusing the memory.\n"
)
EDITS = {
    "iosink_reject_mux_literal_callee.ll": (
        "; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\\n; RUN:   | %filecheck %s\n",
        "; RUN: env CQ_OPT_DEBUG_ALLOC=nofree not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\\n; RUN:   | %filecheck %s\n"),
    "lowering_reject_break_uncollected_clone.ll": (
        "; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s\n",
        "; RUN: env CQ_OPT_DEBUG_ALLOC=nofree not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s\n"),
    "lowering_reject_inplace_rail_stale_w1_xor_bareout.ll": (
        "; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s\n",
        "; RUN: env CQ_OPT_DEBUG_ALLOC=nofree not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s\n"),
    "lowering_reject_inplace_rail_stale_w1_xor_derived.ll": (
        "; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s\n",
        "; RUN: env CQ_OPT_DEBUG_ALLOC=nofree not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s\n"),
}
for f, (old, new) in EDITS.items():
    p = W + f
    s = open(p).read()
    assert s.count(old) == 1, (f, s.count(old))
    assert "CQ_OPT_DEBUG_ALLOC" not in s, f
    s = s.replace(old, old + NOTE + new, 1)
    open(p, "w").write(s)
    print("edited", f)
