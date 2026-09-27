#!/usr/bin/env python3
"""respell2b.py FILE... : fix the round-2 header notes respell2.py left imprecise."""
import re
import sys

OLD_NOTE = re.compile(r"; ⚠ ROUND 2 \(bd vsfp, Rule-13 r1A/r1B\): round 1's dead `mul` stopped keeping the\n"
                      r"(;.*\n)*?; control dependence \(ADCE\) retires this subject: the pin below turns red\.\n")
NEW_NOTE = """; ⚠ ROUND 2 (bd vsfp, Rule-13 r1A/r1B): round 1's DEAD `mul` read no longer keeps the
; parameter used — the drop now asks LIVENESS (`DeadValueLiveness.h`), and a value that
; reaches no root is dead. The read is therefore a BRANCH-ONLY one now: `%vsfp.c` and an
; EMPTY diamond on it. A branch condition is a liveness ROOT (the predicate has no
; control dependence — see its LIMITS), so the parameter is LIVE in the original callee,
; the drop does not fire (the NODROP / CHECK-NOT pin below), and the clone is built as
; before; the clone's own flatten then removes the branch and the specializer records
; the slot dead. Where this module ACCEPTS, its operand is a `cq_theta` result (the
; phantom-read backstop's one exemption); where it DECLINES, the owner named here fires
; before the backstop is asked. A predicate WITH control dependence (ADCE) retires this
; subject — the pin below then turns red and the subject must be re-derived (L8).
"""
OLD_ONE = re.compile(r"The ONE added line in `(@[\w.]+)`, `%vsfp\.read`, is a DEAD READ that keeps\s*\n?;?\s*the\s*\n?;?\s*parameter used,")
NEW_ONE = r"The added lines in `\1` (a branch-only read — see ROUND 2 below) keep the parameter live,"
for f in sys.argv[1:]:
    s = open(f).read()
    s2, n1 = OLD_NOTE.subn(NEW_NOTE, s)
    s2, n2 = OLD_ONE.subn(NEW_ONE, s2)
    s2 = s2.replace("(Its forward/adjoint template pair now sits in the CLONE body; the\n; caller-side checks below are unchanged.)",
                    "(The clone's own flatten removes the read, so the clone body carries no\n; template for it; the caller-side checks below are unchanged.)")
    open(f, "w").write(s2)
    print(f, n1, n2)
