#!/usr/bin/env python3
"""L8 duplicate-body scan: sha-256 over each fixture's non-comment lines,
grouped; each duplicate's CLAIMED VERDICT read off its own RUN lines; groups
that MIX verdicts are FLAGGED."""
import hashlib, os, re, sys, glob
from collections import defaultdict

ROOT = "/Users/sorenwilkening/Desktop/CQ_VERIFY"
files = sorted(glob.glob(os.path.join(ROOT, "ir-pass/test/*.ll")))
if not files:
    sys.exit("FATAL: no fixtures found -- vacuous scan")

def norm(path, mode):
    out = []
    for ln in open(path, encoding="utf-8", errors="replace"):
        s = ln.strip()
        if not s:
            continue
        if s.startswith(";"):
            continue                       # comments AND RUN/CHECK lines
        if mode >= 1:
            s = re.sub(r"\s+", " ", s)
        if mode >= 2:
            s = re.sub(r'^; ModuleID.*|^source_filename.*', "", s)
        if not s:
            continue
        out.append(s)
    return hashlib.sha256("\n".join(out).encode()).hexdigest()

def verdict(path):
    """ACCEPT / DECLINE / MIXED-RUN / NONE, read off the file's own RUN lines."""
    acc = dec = 0
    for ln in open(path, encoding="utf-8", errors="replace"):
        s = ln.strip()
        if "RUN:" not in s:
            continue
        body = s.split("RUN:", 1)[1]
        if re.search(r"\bnot\s+%cq-opt", body) or re.search(r"\bnot\s+.*cq-opt", body):
            dec += 1
        elif "%cq-opt" in body:
            acc += 1
    if acc and dec: return "MIXED-RUN"
    if dec: return "DECLINE"
    if acc: return "ACCEPT"
    return "NONE"

total_flagged = 0
for mode, label in ((0, "exact-noncomment"), (1, "whitespace-normalised"), (2, "ws+moduleid")):
    groups = defaultdict(list)
    for f in files:
        groups[norm(f, mode)].append(f)
    dups = {k: v for k, v in groups.items() if len(v) > 1}
    mixed = []
    for k, v in dups.items():
        vs = {verdict(p) for p in v}
        if len(vs) > 1:
            mixed.append((k, v, vs))
    print(f"[{label}] fixtures={len(files)} duplicate-groups={len(dups)} "
          f"files-in-groups={sum(len(v) for v in dups.values())} MIXED-VERDICT-GROUPS={len(mixed)}")
    for k, v, vs in mixed:
        total_flagged += 1
        print(f"  !! MIXED {sorted(vs)}")
        for p in v:
            print(f"     {os.path.relpath(p, ROOT)}  -> {verdict(p)}")
    # show duplicate groups (they are informational at mode 0)
    if mode == 0 and dups:
        for k, v in sorted(dups.items(), key=lambda x: -len(x[1])):
            print(f"   group({len(v)}) verdicts={sorted({verdict(p) for p in v})}: "
                  + ", ".join(os.path.relpath(p, ROOT) for p in v))
print(f"TOTAL MIXED-VERDICT GROUPS ACROSS ALL NORMALISATIONS: {total_flagged}")
