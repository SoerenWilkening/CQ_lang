#!/usr/bin/env python3
"""dup_body_scan.py — CLAUDE.md L8's post-merge duplicate-body scan: sha-256 over
each ir-pass/test/*.ll fixture's NON-COMMENT lines (comment lines, RUN/CHECK
headers and blank lines stripped). Two fixtures with one body are either a
resurrected `git mv` or a deliberate twin; each group is printed for a human to
adjudicate. Denominator printed. Its null/positive controls run first."""
import collections, glob, hashlib, os, sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"


def body(text):
    keep = [l.rstrip() for l in text.splitlines() if l.strip() and not l.lstrip().startswith(";")]
    return hashlib.sha256("\n".join(keep).encode()).hexdigest()


assert body("; x\nret\n") == body("; y\n\nret\n"), "null control failed"
assert body("ret 1\n") != body("ret 2\n"), "positive control failed"
files = sorted(glob.glob(f"{W}/ir-pass/test/*.ll"))
groups = collections.defaultdict(list)
for f in files:
    groups[body(open(f).read())].append(os.path.basename(f))
dups = [g for g in groups.values() if len(g) > 1]
print(f"dup_body_scan: {len(files)} fixtures, {len(groups)} distinct bodies, {len(dups)} groups with >1 member")
for g in sorted(dups):
    print("  " + "  ==  ".join(g))
