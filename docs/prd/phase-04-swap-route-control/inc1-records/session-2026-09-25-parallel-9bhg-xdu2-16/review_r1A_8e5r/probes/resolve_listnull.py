#!/usr/bin/env python3
"""resolve_listnull.py BIN LOGDIR RESULTS.tsv — aggregate LISTNULL deleter backtraces:
resolve every return address with atos (unslid, the binary is PIE at 0x100000000),
name each event by its first `cq::` frame (the DELETER), and count per deleter and
per module. Owners (lowerRotations/lowerMeasures/deleteGlobalPhases) are expected."""
import collections, glob, os, re, subprocess, sys
b, logdir, res = sys.argv[1:4]
mods = {}
for line in open(res):
    f = line.rstrip('\n').split('\t'); mods[f[0]] = os.path.basename(f[1])
events = []
addrs = set()
for p in glob.glob(f"{logdir}/*.log"):
    i = os.path.basename(p)[:-4]
    for line in open(p):
        if line.startswith("LISTNULL"):
            a = line.split()[1:]
            events.append((i, a)); addrs.update(a)
addrs = sorted(addrs)
sym = {}
for k in range(0, len(addrs), 400):
    chunk = addrs[k:k+400]
    out = subprocess.run(["atos", "-o", b, "-l", "0x100000000", *chunk], capture_output=True, text=True).stdout.splitlines()
    for a, s in zip(chunk, out):
        sym[a] = re.sub(r"\(in [^)]*\)", "", s).strip()
per = collections.Counter(); permod = collections.defaultdict(set)
for i, a in events:
    fr = [sym.get(x, x) for x in a]
    cq = [s for s in fr if s.startswith("cq::") and "keyDeleted" not in s and "scrub::" not in s]
    d = cq[0].split("(")[0] if cq else "?"
    d2 = cq[1].split("(")[0] if len(cq) > 1 else ""
    per[(d, d2)] += 1; permod[(d, d2)].add(mods.get(i, i))
print(f"LISTNULL events: {len(events)} in {len(set(i for i,_ in events))} modules")
for (d, d2), n in per.most_common():
    ms = sorted(permod[(d, d2)])
    print(f"{n:6d}  {d}  <- {d2}   [{len(ms)} modules; e.g. {', '.join(ms[:3])}]")
