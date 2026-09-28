#!/usr/bin/env python3
"""fmt3 option (A) population: run the FMT3-PROBE prototype cq-opt (CQ_FMT3_PROBE=1 makes
it REPORT, never act on, the coarse-fence variants A1/A2 at every literal state prep that
passes F2) over a module list, and cross it with the verdict.

A module whose verdict is ACCEPT and that prints `A1=1` is an A->D mover under option A1
(likewise A2).  The prototype's verdict is byte-identical to the oracle (the probe only
prints), which the NULL CONTROL checks: every module is also run through the ORACLE and
exit code + stdout sha must agree for ALL of them.

Usage: sweep_probe.py PROTO_CQ_OPT MODULE_LIST_FILE [-j N]"""
import hashlib, subprocess, sys, os, re
from concurrent.futures import ThreadPoolExecutor
ORA = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
       "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646")
args = sys.argv[1:]
J = 4
if "-j" in args:
    i = args.index("-j"); J = int(args[i + 1]); del args[i:i + 2]
PROTO, LST = args[0], args[1]
mods = [l.strip() for l in open(LST) if l.strip()]
def run(opt, m, env=None):
    e = dict(os.environ)
    if env: e.update(env)
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", m], capture_output=True, timeout=600, env=e)
    err = p.stderr.decode(errors="replace")
    first = [l for l in err.splitlines() if "error:" in l]
    return p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16], (first[0].split("error:", 1)[1].strip()[:140] if first else ""), err
def one(m):
    if os.path.getsize(m) == 0:
        return m, None
    o = run(ORA, m)
    s = run(PROTO, m, {"CQ_FMT3_PROBE": "1"})
    probes = [l for l in s[3].splitlines() if l.startswith("FMT3-PROBE")]
    return m, (o[:3], s[:3], probes)
with ThreadPoolExecutor(J) as ex:
    res = list(ex.map(one, mods))
ok = [(m, r) for m, r in res if r is not None]
print(f"denominator: {len(mods)} modules listed, {len(ok)} non-empty and run on BOTH binaries")
nullmov = [(m, r) for m, r in ok if r[0] != r[1]]
print(f"NULL CONTROL (oracle vs prototype-with-probe, verdict+stdout): {len(nullmov)} movers")
for m, r in nullmov:
    print(f"  NULLMOVE {m} ORA={r[0]} PROTO={r[1]}")
sites = [(m, r) for m, r in ok if r[2]]
acc = [(m, r) for m, r in sites if r[0][0] == 0]
print(f"modules with >=1 literal prep that PASSES F2: {len(sites)} (of which ACCEPT: {len(acc)}, DECLINE later: {len(sites) - len(acc)})")
for tag in ("A1", "A2"):
    hit = [(m, r) for m, r in ok if any(f"{tag}=1" in p for p in r[2])]
    ad = [(m, r) for m, r in hit if r[0][0] == 0]
    print(f"{tag}: would fire in {len(hit)} modules; ACCEPT->DECLINE movers: {len(ad)}")
    for m, r in ad:
        w = [p for p in r[2] if f"{tag}=1" in p][0]
        wit = re.search(r"w%s=\[(.*?)\]" % tag[1], w)
        print(f"  {tag}-A->D\t{os.path.basename(m)}\twitness: {wit.group(1).strip() if wit else '?'}")
for m, r in acc:
    if not any("A2=1" in p for p in r[2]):
        print(f"  SURVIVES-A2\t{os.path.basename(m)}")
