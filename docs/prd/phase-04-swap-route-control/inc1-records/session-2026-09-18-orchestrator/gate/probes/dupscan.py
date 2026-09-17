#!/usr/bin/env python3
"""L8 duplicate-body scan over ir-pass/test/*.ll.

sha-256 over NON-COMMENT lines; group by digest; for each group of >1, read the
CLAIMED VERDICT off the RUN lines and flag groups that MIX them (CLAUDE.md L8:
"a merge can resurrect a git mv'd fixture — one module under two names with
contradictory verdicts").

Self-attack: exits rc=2 on an empty universe rather than printing a clean
"0 duplicates" (a scan that checked nothing is a HOLE, not a pass).
"""
import sys, os, re, hashlib, glob, collections

def body_digest(path):
    out = []
    with open(path, 'r', errors='replace') as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            if s.startswith(';'):          # LLVM IR comment / lit RUN+CHECK lines
                continue
            out.append(s)
    return hashlib.sha256('\n'.join(out).encode()).hexdigest(), len(out)

RUN_RE = re.compile(r';\s*RUN:\s*(.*)')
def claimed_verdict(path):
    """ACCEPT / DECLINE / MIXED-IN-FILE / NONE, read off the RUN lines."""
    verdicts = set()
    with open(path, 'r', errors='replace') as f:
        for line in f:
            m = RUN_RE.search(line)
            if not m:
                continue
            cmd = m.group(1)
            if 'cq-opt' not in cmd and '%cq-opt' not in cmd:
                continue
            # a leading `not` before the opt invocation == the fixture claims a DECLINE
            if re.search(r'(^|\|\s*|&&\s*)not\s+%?\S*cq-opt', cmd) or re.search(r'\bnot\s+%cq-opt', cmd):
                verdicts.add('DECLINE')
            else:
                verdicts.add('ACCEPT')
    if not verdicts:
        return 'NONE'
    if len(verdicts) > 1:
        return 'MIXED-IN-FILE'
    return verdicts.pop()

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else 'ir-pass/test'
    files = sorted(glob.glob(os.path.join(root, '*.ll')))
    if not files:
        print(f"REFUSING: no fixtures found under {root!r} — nothing was checked, "
              f"which is a HOLE, not a pass", file=sys.stderr)
        return 2
    groups = collections.defaultdict(list)
    empty = []
    for p in files:
        d, n = body_digest(p)
        if n == 0:
            empty.append(p)          # a 0-body module ACCEPTS through the passthrough early-out
            continue
        groups[d].append(p)
    dups = {d: ps for d, ps in groups.items() if len(ps) > 1}
    contradictory = []
    print(f"{len(files)} fixtures scanned, {len(dups)} duplicate-body group(s)")
    if empty:
        print(f"⚠ {len(empty)} EMPTY-BODY module(s) (vacuity trap): {empty}")
    for d, ps in sorted(dups.items(), key=lambda kv: kv[1][0]):
        vs = {p: claimed_verdict(p) for p in ps}
        distinct = set(vs.values())
        flag = 'CONTRADICTORY' if len(distinct) > 1 else 'consistent'
        if len(distinct) > 1:
            contradictory.append((d, vs))
        print(f"\n  group {d[:16]} [{flag}] ({len(ps)} files)")
        for p, v in vs.items():
            print(f"    {v:14s} {os.path.basename(p)}")
    print(f"\nCONTRADICTORY-VERDICT GROUPS: {len(contradictory)}")
    return 1 if contradictory else 0

if __name__ == '__main__':
    sys.exit(main())
