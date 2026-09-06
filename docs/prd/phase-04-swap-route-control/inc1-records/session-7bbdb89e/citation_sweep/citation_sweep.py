#!/usr/bin/env python3
"""Citation sweep for branch `eqpx-fix` (bd test_C_libtooling-eqpx; round-2 lens item F-E2-2).

Every `LoopLowering(.cpp)?:<n>` / `ArithLowering(.cpp)?:<n>` / `OpcodeLowering(.cpp)?:<n>` citation
(plus the bare `` `:<n>` `` CONTINUATIONS those docs write, attributed to the last file named on the
same line) in the notes, the PRD, CLAUDE.md, ROADMAP.md, the three edited sources and the 16 new
fixtures. For each it prints what line <n> holds on the SUBJECT, what it held on `<base>`, and where
`<base>`'s line n moved to — enough for the operator to adjudicate "does line n contain what the
citation NAMES?".

Adjudication is BY HAND and lives in `$W/citation_verdicts.txt` (one `<file>:<line> <FILE>:<n> =
OK|MISS-INTRODUCED|MISS-PREEXISTING` per line); pass it as argv[3] and the script prints the counts.
"""
import re, subprocess, sys, difflib, os

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
BASE = sys.argv[2] if len(sys.argv) > 2 else "main"
VERD = sys.argv[3] if len(sys.argv) > 3 else None

SRCS = {"LoopLowering": "ir-pass/src/LoopLowering.cpp",
        "ArithLowering": "ir-pass/src/ArithLowering.cpp",
        "OpcodeLowering": "ir-pass/src/OpcodeLowering.cpp"}

def sh(*a):
    return subprocess.run(a, cwd=ROOT, capture_output=True, text=True).stdout

subj, basev, fwd = {}, {}, {}
for k, p in SRCS.items():
    subj[k] = open(os.path.join(ROOT, p)).read().splitlines()
    basev[k] = sh("git", "show", f"{BASE}:{p}").splitlines()
    sm = difflib.SequenceMatcher(None, basev[k], subj[k], autojunk=False)
    m = {}
    for a, b, n in sm.get_matching_blocks():
        for i in range(n):
            m[a + i + 1] = b + i + 1
    fwd[k] = m

DOCS = ["docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md",
        "docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md",
        "CLAUDE.md", "ROADMAP.md"] + list(SRCS.values())
DOCS += sorted(sh("git", "diff", "--name-only", f"{BASE}..HEAD", "--", "ir-pass/test").split())

# file-qualified citation, or a bare `:<n>` / `:<n>-<n>` continuation
TOK = re.compile(r"\b(LoopLowering|ArithLowering|OpcodeLowering)(?:\.cpp)?:(\d+)(?:-(\d+))?"
                 r"|(?<![\w.])[:](\d+)(?:-(\d+))?(?=`)")

def base_has_line(path, text):
    """Is the citing line itself present verbatim in the BASE version of its file?"""
    b = sh("git", "show", f"{BASE}:{path}")
    return text in b

rows = []
for d in DOCS:
    fp = os.path.join(ROOT, d)
    if not os.path.exists(fp):
        continue
    basetext = sh("git", "show", f"{BASE}:{d}")
    for ln, line in enumerate(open(fp).read().splitlines(), 1):
        last = None
        pre = (line.strip() in basetext)
        for m in TOK.finditer(line):
            if m.group(1):
                last = m.group(1)
                ns = [int(m.group(2))] + ([int(m.group(3))] if m.group(3) else [])
            else:
                if last is None:
                    continue                      # bare `:N` with no file on this line
                ns = [int(m.group(4))] + ([int(m.group(5))] if m.group(5) else [])
            f = last
            for nn in ns:
                S, B, F = subj[f], basev[f], fwd[f]
                s_txt = S[nn - 1].strip() if nn <= len(S) else "<past EOF>"
                b_txt = B[nn - 1].strip() if nn <= len(B) else "<past EOF>"
                rows.append((d, ln, f, nn, F.get(nn), s_txt, b_txt, line.strip(), pre))

verdicts = {}
if VERD and os.path.exists(VERD):
    for l in open(VERD):
        l = l.split("#")[0].strip()
        if not l:
            continue
        key, v = l.rsplit(None, 1)
        verdicts[key] = v

miss_i = miss_p = ok = quoted = unk = 0
for d, ln, f, nn, moved, s_txt, b_txt, sent, pre in rows:
    key = f"{d}:{ln} {f}:{nn}"
    v = verdicts.get(key, "UNADJUDICATED")
    if v == "OK": ok += 1
    elif v == "MISS-INTRODUCED": miss_i += 1
    elif v == "MISS-PREEXISTING": miss_p += 1
    elif v == "QUOTED": quoted += 1
    else: unk += 1
    if v in ("OK", "QUOTED"):
        continue
    print(f"[{v}] {key}   (citing line pre-exists on {BASE}: {pre})")
    print(f"    SUBJECT {f}:{nn} = {s_txt[:140]}")
    print(f"    {BASE:7s} {f}:{nn} = {b_txt[:140]}")
    if moved and moved != nn:
        print(f"    {BASE}'s {nn} now lives at SUBJECT:{moved}")
    print(f"    sentence: {sent[:200]}")
    print()
print("=== SUMMARY ===")
print(f"citations scanned    {len(rows)}")
print(f"OK                   {ok}")
print(f"MISS-INTRODUCED      {miss_i}")
print(f"MISS-PREEXISTING     {miss_p}")
print(f"QUOTED               {quoted}")
print(f"UNADJUDICATED        {unk}")
