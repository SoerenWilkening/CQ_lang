#!/usr/bin/env python3
"""corpus.py — MAIN vs COMPOSED over every ir-pass/test/*.ll.

Records exit code, first diagnostic line, AND a sha-256 of the lowered stdout, so
a STREAM move on an accepting module is visible (a sweep with -o /dev/null is not).

⚠ BOUNDARY CONTROLS RUN FIRST, ON EVERY INVOCATION, BEFORE THE FIRST REAL
MEASUREMENT (session protocol item 1).  Last session a sweep reported "2065
movers of 2106" because `rc=$?` after a shell pipeline captured grep's status.
Here: (a) MAIN-vs-MAIN must yield ZERO movers; (b) a fixture known to move must
move.  Either control failing aborts the run.
"""
import hashlib, subprocess, sys, glob, os

R = "/Users/sorenwilkening/Desktop/Projects/CQ_lang"
BIN = {"MAIN": f"{R}/build/ir-pass/cq-opt",
       "COMPOSED": "/private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt"}

def run(binary, ll):
    p = subprocess.run([binary, "-passes=cq-lowering", "-S", ll, "-o", "-"],
                       capture_output=True, text=True)      # rc read directly, no pipeline
    if p.returncode != 0:
        first = next((l for l in p.stderr.splitlines() if "error:" in l), "")
        return ("D", p.returncode, first.split(": cq ")[-1][:70], "")
    return ("A", 0, "", hashlib.sha256(p.stdout.encode()).hexdigest()[:16])

def sweep(a, b, files, label):
    movers = []
    for i, ll in enumerate(files):
        ra, rb = run(BIN[a], ll), run(BIN[b], ll)
        if ra != rb:
            movers.append((os.path.basename(ll), ra, rb))
        if i % 200 == 0:
            print(f"  [{label}] {i}/{len(files)} …", flush=True)
    return movers

if __name__ == "__main__":
    files = sorted(glob.glob(f"{R}/ir-pass/test/*.ll"))
    print(f"corpus: {len(files)} fixtures", flush=True)
    for tag, path in BIN.items():
        h = hashlib.sha256(open(path, 'rb').read()).hexdigest()
        print(f"  {tag:9s} {h}", flush=True)

    print("\nBOUNDARY CONTROLS (before the first real measurement):", flush=True)
    ctl = files[:120]
    nil = sweep("MAIN", "MAIN", ctl, "null")
    print(f"  [{'ok ' if not nil else 'FAIL'}] NULL control: MAIN vs MAIN over {len(ctl)} = {len(nil)} movers (must be 0)")
    if nil:
        print("  ABORTING: the harness reports a difference where there is none."); sys.exit(2)
    known = [f for f in files if "loop_pairing_reject_round2_falsified" in f]
    pos = sweep("MAIN", "COMPOSED", known, "pos") if known else []
    print(f"  [{'ok ' if pos else 'FAIL'}] POSITIVE control: the branch's own declared mover moved = {len(pos)} (must be >=1)")
    if not pos:
        print("  ABORTING: the harness cannot see a move it is known to have."); sys.exit(2)

    print("\nreal sweep:", flush=True)
    movers = sweep("MAIN", "COMPOSED", files, "real")
    ad = [m for m in movers if m[1][0] == "A" and m[2][0] == "D"]
    da = [m for m in movers if m[1][0] == "D" and m[2][0] == "A"]
    ss = [m for m in movers if m[1][0] == "D" and m[2][0] == "D"]
    st = [m for m in movers if m[1][0] == "A" and m[2][0] == "A"]
    print(f"\n=== {len(files)} fixtures: {len(movers)} movers "
          f"| A->D {len(ad)} · D->A {len(da)} · D->D(string) {len(ss)} · A->A(stream) {len(st)}")
    for name, ra, rb in movers:
        print(f"  {name}\n      MAIN={ra}\n      COMP={rb}")
    sys.exit(1 if ad else 0)
