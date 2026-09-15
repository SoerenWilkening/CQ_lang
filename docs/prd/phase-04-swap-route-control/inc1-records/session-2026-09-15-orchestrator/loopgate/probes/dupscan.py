#!/usr/bin/env python3
"""L8 duplicate-body fixture scan (CLAUDE.md L8 + the 2026-09-14 erratum).

sha-256 over each fixture's NON-COMMENT lines, grouped; for every group with >1
member it reads each member's CLAIMED VERDICT off its own RUN lines and flags
groups that MIX them.  The verdict-mixing half is the part that earns its keep:
"a merge can resurrect a `git mv`'d fixture — one module under two names with
contradictory verdicts, invisible to every review that ran before the merge."
"""
import hashlib, pathlib, re, sys, collections

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'ir-pass/test')
files = sorted(root.glob('*.ll'))
if not files:
    print("REFUSE: no fixtures found under", root); sys.exit(2)

def body(p):
    out = []
    for ln in p.read_text(errors='replace').splitlines():
        s = ln.strip()
        if not s or s.startswith(';'):     # comments AND all RUN/CHECK directives
            continue
        out.append(s)
    return '\n'.join(out)

def verdict(p):
    """DECLINE iff any RUN line inverts with `not`; ACCEPT otherwise. A file with
    BOTH is reported as MIXED-IN-FILE, which is legitimate (an env-gated pin) and
    is printed so it is never silently read as a contradiction."""
    runs = [l for l in p.read_text(errors='replace').splitlines()
            if re.match(r'^\s*;\s*RUN:', l)]
    if not runs: return 'NO-RUN'
    neg = any(re.search(r'\bnot\s+%cq-opt\b', l) for l in runs)
    pos = any(re.search(r'(?<!not )%cq-opt', l) and not re.search(r'\bnot\s+%cq-opt\b', l)
              for l in runs)
    if neg and pos: return 'MIXED-IN-FILE'
    return 'DECLINE' if neg else 'ACCEPT'

groups = collections.defaultdict(list)
empty = 0
for p in files:
    b = body(p)
    if not b.strip():
        empty += 1; continue
    groups[hashlib.sha256(b.encode()).hexdigest()].append(p)

dups = {h: v for h, v in groups.items() if len(v) > 1}
contradictory = 0
for h, v in sorted(dups.items()):
    vs = {p.name: verdict(p) for p in v}
    core = {x for x in vs.values() if x != 'MIXED-IN-FILE'}
    mix = len(core) > 1
    if mix: contradictory += 1
    print(f"{'⚠ CONTRADICTORY ' if mix else ''}GROUP {h[:12]} n={len(v)}")
    for p in v:
        print(f"    {vs[p.name]:14s} {p.name}")
print(f"\nscanned {len(files)} fixtures ({empty} with an empty non-comment body), "
      f"{len(dups)} duplicate-body group(s), {contradictory} with CONTRADICTORY verdicts")
sys.exit(1 if contradictory else 0)
