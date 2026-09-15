#!/usr/bin/env python3
"""ARM group gate — the L8 DUPLICATE-BODY fixture scan (2026-09-15).

CLAUDE.md L8: *"a merge can resurrect a `git mv`'d fixture — one module under two
names with contradictory verdicts, invisible to every review that ran before the
merge. Run a duplicate-body scan (sha-256 over each fixture's non-comment lines)
after any merge that renames fixtures."*

And the 2026-09-14 gate's correction, adopted here: the scan is worth more when
it reads each duplicate's **CLAIMED VERDICT off its RUN lines** and flags groups
that **MIX** them. Two copies of one module that both accept are a tidiness
question; two copies that disagree are the defect L8 is about.

VERDICT is read from the RUN lines, not from a filename convention:
  * any `RUN:` line containing ` not %cq-opt` / `not %cq-opt` -> claims DECLINE
  * otherwise, a `RUN:` line invoking `%cq-opt`               -> claims ACCEPT
A file claiming both (a decline RUN plus an accept RUN) is reported as MIXED-SELF
rather than silently collapsed — that is a legal shape (two functions, two
invocations) and the group logic must not read it as agreement.

Normalisations, four, because one is not enough (a single normalisation lets a
rename hide behind a whitespace or metadata-id reflow):
  N1 non-comment lines, whitespace-collapsed
  N2 N1 with all `!<n>` metadata ids renumbered to `!N`
  N3 N1 with LOCAL SSA names (`%name`) canonicalised positionally. ⚠ NOT
     `@name`: a global/function name is SEMANTIC, and canonicalising it makes
     `lowering_intrinsic_sqrt_f64.ll` and `lowering_reject_libm_direct_cbrt_
     no_inject.ll` collapse into one "MIXED" group — measured, a FALSE POSITIVE
     that would have read as an L8 defect. An instrument that cries wolf is an
     instrument people stop reading (L10).
  N4 N2 + N3 together
Exit code 1 iff any group MIXES verdicts.
"""
import glob
import hashlib
import re
import sys
from collections import defaultdict

ROOT = "/Users/sorenwilkening/Desktop/CQ_ARM"
COMMENT = re.compile(r"^\s*;")
WS = re.compile(r"\s+")
MDID = re.compile(r"![0-9]+")
NAME = re.compile(r"%([A-Za-z0-9_.$\-]+|\"[^\"]*\")")


def body(path):
    out = []
    for line in open(path, encoding="utf-8", errors="replace"):
        if COMMENT.match(line) or not line.strip():
            continue
        out.append(WS.sub(" ", line.strip()))
    return out


def canon_names(lines):
    seen, nxt = {}, [0]

    def sub(m):
        k = m.group(0)
        if k not in seen:
            seen[k] = f"%V{nxt[0]}"
            nxt[0] += 1
        return seen[k]
    return [NAME.sub(sub, l) for l in lines]


def verdict(path):
    acc = dec = False
    for line in open(path, encoding="utf-8", errors="replace"):
        if "RUN:" not in line:
            continue
        if "%cq-opt" not in line:
            continue
        if re.search(r"\bnot\s+%cq-opt", line):
            dec = True
        else:
            acc = True
    if acc and dec:
        return "MIXED-SELF"
    if dec:
        return "DECLINE"
    if acc:
        return "ACCEPT"
    return "NO-RUN"


def main():
    files = sorted(glob.glob(f"{ROOT}/ir-pass/test/*.ll"))
    print(f"fixtures scanned: {len(files)}")
    norms = {"N1": lambda b: b,
             "N2": lambda b: [MDID.sub("!N", l) for l in b],
             "N3": canon_names,
             "N4": lambda b: canon_names([MDID.sub("!N", l) for l in b])}
    bodies = {f: body(f) for f in files}
    verdicts = {f: verdict(f) for f in files}
    bad = 0
    for nm, fn in norms.items():
        groups = defaultdict(list)
        for f in files:
            h = hashlib.sha256(
                "\n".join(fn(bodies[f])).encode()).hexdigest()
            groups[h].append(f)
        dups = {h: g for h, g in groups.items() if len(g) > 1}
        mixed = {h: g for h, g in dups.items()
                 if len({verdicts[x] for x in g}) > 1}
        print(f"  {nm}: {len(dups)} duplicate-body group(s), "
              f"{len(mixed)} with MIXED verdicts")
        for h, g in sorted(dups.items()):
            tag = "MIXED" if h in mixed else "agree"
            print(f"    [{tag}] " + "  ".join(
                f"{x.split('/')[-1]}={verdicts[x]}" for x in g))
        bad += len(mixed)
    # L8's second half: the git-mv'd fixtures must not have been resurrected.
    print("\nself-mixed (a file whose own RUN lines claim both):")
    n = 0
    for f in files:
        if verdicts[f] in ("MIXED-SELF", "NO-RUN"):
            print(f"    {verdicts[f]}: {f.split('/')[-1]}")
            n += 1
    print(f"    {n} file(s)")
    print("\nRESULT:", "FAIL — a duplicate group mixes verdicts" if bad
          else "PASS — no duplicate-body group mixes verdicts")
    sys.exit(1 if bad else 0)


main()
