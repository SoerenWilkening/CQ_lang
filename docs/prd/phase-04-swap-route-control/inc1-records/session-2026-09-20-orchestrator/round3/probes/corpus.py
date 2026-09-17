#!/usr/bin/env python3
"""4-way corpus A/B over ir-pass/test/*.ll.

Records, per fixture per binary: exit code, the first diagnostic string, and a
sha-256 of the lowered stdout (so a STREAM move on an accepting module is
visible -- the zujr session's own sweep.py used -o /dev/null and could not see
one; Rule-13 round 1 F-corroboration).

A COMPOSITION FINDING is a fixture whose (rc,msg,sha) on COMPOSED differs from
MAIN and where TU9QONLY-vs-BASE shows the same cell UNMOVED -- i.e. neither part
alone produces it.
"""
import hashlib, os, subprocess, sys, json

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0"
S = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad"
BINS = os.path.join(S, "bins")
TAGS = ["BASE", "MAIN", "TU9QONLY", "COMPOSED"]

files = sorted(f for f in os.listdir(os.path.join(W, "ir-pass/test")) if f.endswith(".ll"))
res = {}
for tag in TAGS:
    opt = os.path.join(BINS, "cq-opt." + tag)
    plug = os.path.join(BINS, "libCQPass.%s.so" % tag)
    rows = {}
    for i, f in enumerate(files):
        p = os.path.join(W, "ir-pass/test", f)
        try:
            r = subprocess.run([opt, "-load-pass-plugin", plug, "-passes=cq-lowering",
                                "-S", p], capture_output=True, timeout=120)
        except subprocess.TimeoutExpired:
            rows[f] = (-99, "TIMEOUT", "")
            continue
        err = r.stderr.decode("utf8", "replace")
        msg = ""
        for line in err.splitlines():
            if ": cq " in line:
                msg = line.split(": cq ", 1)[1].strip()
                break
        if not msg and err.strip():
            msg = err.strip().splitlines()[0][:90]
        sha = hashlib.sha256(r.stdout).hexdigest()[:16] if r.returncode == 0 else ""
        rows[f] = (r.returncode, msg, sha)
        if i % 300 == 0:
            print("  %s %d/%d" % (tag, i, len(files)), flush=True)
    res[tag] = rows
    print("DONE %s" % tag, flush=True)

json.dump({t: {f: list(v) for f, v in res[t].items()} for t in TAGS},
          open(os.path.join(S, "corpus4.json"), "w"))
print("=== fixtures: %d ===" % len(files))
print("\n== MAIN -> COMPOSED movers (adding tu9q P0P3 to main) ==")
mc = []
for f in files:
    if res["MAIN"][f] != res["COMPOSED"][f]:
        mc.append(f)
print("count", len(mc))
print("\n== BASE -> TU9QONLY movers (adding tu9q P0P3 to base) ==")
bt = [f for f in files if res["BASE"][f] != res["TU9QONLY"][f]]
print("count", len(bt))
print("\n== BASE -> MAIN movers (everything main added, incl. zujr) ==")
bm = [f for f in files if res["BASE"][f] != res["MAIN"][f]]
print("count", len(bm))
print("\n== COMPOSITION-ONLY: moved MAIN->COMPOSED but NOT BASE->TU9QONLY ==")
comp = [f for f in mc if f not in bt]
for f in comp:
    print("  %-66s M=%s  C=%s   | B=%s T=%s" % (
        f, res["MAIN"][f][0:2], res["COMPOSED"][f][0:2],
        res["BASE"][f][0], res["TU9QONLY"][f][0]))
print("composition-only count", len(comp))
print("\n== ALL MAIN->COMPOSED movers, detail ==")
for f in mc:
    print("  %-66s\n     MAIN=%s\n     COMP=%s" % (f, res["MAIN"][f], res["COMPOSED"][f]))
