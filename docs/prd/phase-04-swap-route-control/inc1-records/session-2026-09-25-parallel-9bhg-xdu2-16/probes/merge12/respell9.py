#!/usr/bin/env python3
"""respell9.py FIXTURE CALLEE: the bd vsfp re-spell of a bd 9bhg fixture whose
library callee ignores its parameter 0.

1. The callee body gets bd vsfp's round-2 BRANCH-ONLY read on %0 (an `icmp` feeding
   an EMPTY diamond), which keeps the parameter LIVE for `dropDeadCallArguments`.
2. Every `%cq-opt` RUN invocation is prefixed `env CQ_DEADARG_DBG=1`, and every
   `%filecheck` invocation gets `--implicit-check-not=CQ_DEADARG_DBG`, so the file
   goes red the day the drop fires on it (L8).
3. A header note, after the title line.
Refuses (non-zero exit) if any pattern does not occur exactly as expected."""
import re
import sys

path, callee = sys.argv[1], sys.argv[2]
s = open(path).read()

body_re = re.compile(
    r"(define [^\n]*@" + re.escape(callee) + r"\(i32 noundef %0, i32 noundef %1\)[^\n]*\{\n)"
    r"(  %3 = add nsw i32 %1, 1\n  ret i32 %3\n\})")
m = body_re.search(s)
assert m, f"{path}: callee body not in the expected single-block form"
read = ("  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)\n"
        "  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join\n"
        "vsfp.arm:\n"
        "  br label %vsfp.join\n"
        "vsfp.join:\n")
s = s[:m.end(1)] + read + s[m.start(2):]

n_opt = len(re.findall(r"^; RUN: (not )?%cq-opt ", s, re.M))
assert n_opt >= 1, f"{path}: no %cq-opt RUN line"
s = re.sub(r"^(; RUN: (?:not )?)%cq-opt ", r"\1env CQ_DEADARG_DBG=1 %cq-opt ", s, flags=re.M)
# every %filecheck invocation gets the implicit-check-not
s, n_fc = re.subn(r"(%filecheck %s)", r"\1 --implicit-check-not=CQ_DEADARG_DBG", s)
assert n_fc >= 1, f"{path}: no %filecheck"

note = f"""; ⚠ bd test_C_libtooling-vsfp (merged into bd 9bhg 2026-09-27) — RE-SPELLED, and why.
; `@{callee}` IGNORED its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now
; replaces an argument whose callee parameter is DEAD under liveness
; (`DeadValueLiveness.h`) by a constant before any stage reads it — what `clang -O1` does
; to the hand-inlined twin — so that spelling never reaches the specializer: no
; specialization site, no provisional return, and this file's subject is GONE. Measured on
; the merged tree before this re-spell: `CQ_DEADARG_DBG: drop arg 0 of @{callee}`, and 4 of
; the 11 affected bd 9bhg fixtures still PASSED — for the hand-inlined twin's reason, not
; theirs (CLAUDE.md Rule 12(c)).
; The BRANCH-ONLY read now in `@{callee}` (`%vsfp.c` feeding an EMPTY diamond — bd vsfp's
; own round-2 spelling) keeps the parameter LIVE: a branch condition is a liveness root.
; So the drop does not fire (pinned: `env CQ_DEADARG_DBG=1` on the RUN line and
; `--implicit-check-not=CQ_DEADARG_DBG`), the specialization site exists at propagation as
; before, and the clone is built as before. The clone's own flatten then removes the
; branch, the specializer records slot 0 dead, and `resolvePhantomCloneArgReads` (last in
; the post-`specialize()` chain) neutralises that slot where the module gets that far.
; From C at -O1 this spelling is IR-ONLY: the library TU deletes an empty branch. The
; `Library TU` source below is the ORIGINAL; the module is hand-edited from it.
; RETIREMENT TRIGGER: a liveness predicate WITH control dependence (ADCE) makes this read
; dead too. The pin then turns red and the subject must be re-derived (L8).
"""
first_nl = s.index("\n") + 1
s = s[:first_nl] + note + s[first_nl:]
open(path, "w").write(s)
print(f"{path}: re-spelled ({n_opt} cq-opt RUN line(s), {n_fc} filecheck(s))")
