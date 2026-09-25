#!/usr/bin/env python3
"""ab.py A B LISTFILE OUT.tsv [-j N]
A, B are BIN:MODE with MODE in {system, lifo, nofree}. Runs each module of
LISTFILE (one path per line) through A and B and classifies the pair:
  same | A2D (A accepts, B declines) | D2A | STREAM (both accept, output differs)
  | STRING (both decline, first error differs) | CRASH (either rc not in {0,1}).
Prints the DENOMINATOR first, then the counts."""
import hashlib, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

def run(spec, f):
    b, mode = spec.rsplit(":", 1)
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None)
    if mode != "system":
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], env=env,
                       capture_output=True)
    h = hashlib.sha256(r.stdout).hexdigest()[:12]
    err = ""
    for line in r.stderr.decode("utf-8", "replace").splitlines():
        if "error:" in line:
            err = line.split("error:", 1)[1].strip()[:160]
            # drop the source location prefix variability (none expected)
            break
    return r.returncode, h, err

def main():
    a, b, lst, out = sys.argv[1:5]
    j = int(sys.argv[6]) if len(sys.argv) > 6 and sys.argv[5] == "-j" else 8
    files = [l.strip() for l in open(lst) if l.strip()]
    print(f"denominator: {len(files)} modules   A={a}   B={b}", flush=True)
    def one(f):
        ra = run(a, f); rb = run(b, f)
        if ra == rb:
            c = "same"
        elif ra[0] not in (0, 1) or rb[0] not in (0, 1):
            c = "CRASH"
        elif ra[0] == 0 and rb[0] != 0:
            c = "A2D"
        elif ra[0] != 0 and rb[0] == 0:
            c = "D2A"
        elif ra[0] == 0:
            c = "STREAM"
        else:
            c = "STRING"
        return (f, c, ra, rb)
    with ThreadPoolExecutor(j) as ex:
        res = list(ex.map(one, files))
    counts = {}
    with open(out, "w") as o:
        for f, c, ra, rb in res:
            counts[c] = counts.get(c, 0) + 1
            o.write(f"{os.path.basename(f)}\t{c}\t{ra[0]}\t{rb[0]}\t{ra[1]}\t{rb[1]}\t{ra[2]}\t{rb[2]}\n")
    print("counts:", " ".join(f"{k}={v}" for k, v in sorted(counts.items())), f"(total {len(res)})")
    for f, c, ra, rb in res:
        if c != "same":
            print(f"  {c}\t{os.path.basename(f)}\trc {ra[0]}->{rb[0]}\t{ra[2][:70]!r} -> {rb[2][:70]!r}")

main()
