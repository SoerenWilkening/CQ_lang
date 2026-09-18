#!/usr/bin/env python3
"""corpus5.py — MAIN vs COMPOSED over every ir-pass/test/*.ll, round 5.

Differs from round 3's sweep (which ran on a DIFFERENT base, main@00c36e93, and
therefore on a `promoteLoopCarriedHandleSeeds` without Rule-13 round 4's (P4)
crash fence) in three ways:

  1. it classifies a CRASH separately from a DECLINE.  Round 4's P1 was `opt`
     ABORTING at exit 134 where the oracle declined cleanly, and a sweep that
     buckets every non-zero exit as "D" cannot see one.
  2. it records the lowered-IR sha for accepting modules (a STREAM move).
  3. NULL-TAG BOUNDARY CONTROLS run on EVERY invocation before the first real
     measurement:
       (a) MAIN vs MAIN over a sample  -> MUST be 0 movers  (the null tag);
       (b) a fixture the two binaries are known to disagree on MUST move
           (if none is supplied the control is reported SKIPPED, loudly);
       (c) both binary hashes are printed and compared to the pinned values.
     A failing control aborts before any real number is produced.

`subprocess.run(...).returncode` is read DIRECTLY from the process object; there
is no shell and no pipeline, so the `rc=$?`-after-a-pipe defect that produced a
"2065 movers of 2106" false alarm last session cannot occur here.
"""
import hashlib, subprocess, sys, glob, os, random

R = "/Users/sorenwilkening/Desktop/Projects/CQ_lang"
BIN = {"MAIN": f"{R}/build/ir-pass/cq-opt",
       "COMPOSED": "/private/tmp/claude-501/cq-composed/build/ir-pass/cq-opt"}
PINNED = {
    "MAIN": "8280ea8d86bcaf4ed82cae92f65733fe8ae601086dfb721d58feeda55d8d9da2",
    "COMPOSED": "3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc",
}


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def run(binary, ll):
    p = subprocess.run([binary, "-passes=cq-lowering", "-S", ll, "-o", "-"],
                       capture_output=True, text=True)
    rc = p.returncode                       # read from the object; no pipeline
    if rc == 0:
        return ("A", 0, "", hashlib.sha256(p.stdout.encode()).hexdigest()[:16])
    if rc not in (1,):                      # 134 = abort, -11 = SIGSEGV, ...
        return ("CRASH", rc, (p.stderr.strip().splitlines() or [""])[-1][:80], "")
    first = next((l for l in p.stderr.splitlines() if "error:" in l), "")
    return ("D", rc, first.split(": cq ")[-1][:70], "")


def sweep(a, b, files, label, quiet=False):
    movers = []
    for i, ll in enumerate(files):
        ra, rb = run(BIN[a], ll), run(BIN[b], ll)
        if ra != rb:
            movers.append((os.path.basename(ll), ra, rb))
        if not quiet and i and i % 250 == 0:
            print(f"  [{label}] {i}/{len(files)} …", flush=True)
    return movers


def controls(files, known_mover):
    ok = True
    print("BOUNDARY CONTROLS (before the first real measurement):")
    for tag, path in BIN.items():
        s = sha(path)
        good = s == PINNED[tag]
        ok &= good
        print(f"  [{'ok ' if good else 'FAIL'}] {tag} sha256 {s}")
    sample = random.Random(5).sample(files, min(120, len(files)))
    null = sweep("MAIN", "MAIN", sample, "null", quiet=True)
    good = len(null) == 0
    ok &= good
    print(f"  [{'ok ' if good else 'FAIL'}] NULL TAG: MAIN vs MAIN over "
          f"{len(sample)} fixtures -> {len(null)} movers (must be 0)")
    if known_mover and os.path.exists(known_mover):
        m = sweep("MAIN", "COMPOSED", [known_mover], "pos", quiet=True)
        good = len(m) == 1
        ok &= good
        print(f"  [{'ok ' if good else 'FAIL'}] POSITIVE: "
              f"{os.path.basename(known_mover)} -> {len(m)} mover (must be 1)")
    else:
        print("  [SKIP] POSITIVE control: no known mover supplied — this run "
              "cannot distinguish 'no movers' from 'harness measuring nothing'.")
    return ok


if __name__ == "__main__":
    files = sorted(glob.glob(f"{R}/ir-pass/test/*.ll"))
    known = sys.argv[1] if len(sys.argv) > 1 else ""
    if not controls(files, known):
        print("!! CONTROLS FAILED — aborting before any real measurement.")
        sys.exit(2)
    print(f"\ncorpus: {len(files)} fixtures, MAIN vs COMPOSED\n", flush=True)
    movers = sweep("MAIN", "COMPOSED", files, "main")
    ad = [m for m in movers if m[1][0] == "A" and m[2][0] == "D"]
    da = [m for m in movers if m[1][0] == "D" and m[2][0] == "A"]
    cr = [m for m in movers if "CRASH" in (m[1][0], m[2][0])]
    ss = [m for m in movers if m[1][0] == "A" and m[2][0] == "A"]
    dd = [m for m in movers if m[1][0] == "D" and m[2][0] == "D"]
    print(f"\nMOVERS {len(movers)}: A->D {len(ad)} · D->A {len(da)} · "
          f"CRASH-involved {len(cr)} · stream-only {len(ss)} · "
          f"decline-string-only {len(dd)}")
    for n, a, b in movers:
        print(f"  {n}\n      MAIN={a}\n      COMP={b}")
    sys.exit(0)
