#!/usr/bin/env python3
"""fixnote.py [--apply]: in each re-spelled 9bhg fixture, the vsfp note was inserted
after LINE 1; where the title continues on line 2 (a comment line that does not start a
new paragraph), the note split the title. Report each file's title lines around the note,
and with --apply move the note to after the full title (the first blank `;` line)."""
import pathlib
import sys

W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
FIX = ["taint_accept_spec_classical_return", "taint_accept_spec_classical_return_arith",
       "taint_accept_spec_classical_return_branch", "taint_accept_spec_classical_return_clone_arg",
       "taint_reject_scrubbed_handle_clone_arg", "taint_reject_scrubbed_handle_clone_arg_mixed",
       "taint_reject_scrubbed_handle_clone_arg_layout", "taint_reject_quantum_return_mixed_spec",
       "taint_reject_quantum_return_spec_seeded_theta", "taint_reject_quantum_return_mixed_rets",
       "taint_reject_quantum_return_lift_owner_order"]
START = "; ⚠ bd test_C_libtooling-vsfp (merged into bd 9bhg 2026-09-27) — RE-SPELLED, and why."
END = "; dead too. The pin then turns red and the subject must be re-derived (L8).\n"
apply = "--apply" in sys.argv
for f in FIX:
    p = W / "ir-pass/test" / f"{f}.ll"
    lines = p.read_text().splitlines(keepends=True)
    i = next(k for k, l in enumerate(lines) if l.startswith(START))
    j = next(k for k in range(i, len(lines)) if lines[k] == END)
    note = lines[i:j + 1]
    rest = lines[:i] + lines[j + 1:]
    # the title ends at the first line that is exactly ";" (blank comment) after line 0
    t = next(k for k, l in enumerate(rest) if l.strip() == ";")
    split = t > 1
    print(f"{f}: note at line {i + 1}, title ends at line {t} -> {'SPLIT' if split else 'ok'}")
    if apply and split:
        new = rest[:t] + note + rest[t:]
        p.write_text("".join(new))
        print("   moved")
