#!/usr/bin/env python3
"""r1B_9bhg alias families on the FINAL merged binaries.

For every scratchpad/alias9/<family>/*.s1.ll:
  * N runs under the system allocator      (frozen cq-opt.final),
  * N runs under CQ_OPT_DEBUG_ALLOC=lifo   (frozen cq-opt-debugalloc.final),
  * N runs under CQ_OPT_DEBUG_ALLOC=nofree (frozen cq-opt-debugalloc.final).
REFERENCE = the first nofree run (no address reuse, so no aliasing is possible).
Each run is (exit code, sha256 of stdout); a run is WRONG if it differs from the
reference in either. Prints a per-family table (module x mode -> wrong/total), every
module with a non-zero count, and the reference's r1B-comparable hash
(sha256(stdout with trailing newlines stripped)[:10], as r1B's multi.sh computed it)
so it can be matched against r1B's recorded no-reuse references.

  run_alias.py N [family ...]
"""
import collections
import hashlib
import os
import pathlib
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
A = S / "alias9"
SYS = S / "frozen/cq-opt.final"
DBG = S / "frozen/cq-opt-debugalloc.final"
N = int(sys.argv[1])
fams = sys.argv[2:] or ["alias_gen", "alias_gen2", "alias_gen3", "alias_gen5", "alias_gen6"]


def run(mode, f):
    env = dict(os.environ)
    if mode == "sys":
        b = SYS
        env.pop("CQ_OPT_DEBUG_ALLOC", None)
    else:
        b = DBG
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True, env=env)
    return (r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16],
            hashlib.sha256(r.stdout.decode(errors="replace").rstrip("\n").encode()).hexdigest()[:10],
            r.stderr.decode(errors="replace"))


jobs = []
for fam in fams:
    for f in sorted((A / fam).glob("*.s1.ll")):
        for mode in ("nofree", "lifo", "sys"):
            for k in range(N):
                jobs.append((fam, f, mode, k))
with ThreadPoolExecutor(8) as ex:
    res = list(ex.map(lambda j: (j, run(j[2], j[1])), jobs))

by = collections.defaultdict(dict)
for (fam, f, mode, k), out in res:
    by[(fam, f.name[:-len(".s1.ll")])].setdefault(mode, []).append(out)

tot = collections.Counter()
bad_rows = []
refs = {}
for (fam, m), modes in sorted(by.items()):
    ref = modes["nofree"][0]
    refs[(fam, m)] = ref
    row = {}
    for mode in ("sys", "lifo", "nofree"):
        wrong = sum(1 for o in modes[mode] if (o[0], o[1]) != (ref[0], ref[1]))
        row[mode] = wrong
        tot[(fam, mode, "wrong")] += wrong
        tot[(fam, mode, "runs")] += len(modes[mode])
    if any(row.values()):
        bad_rows.append((fam, m, row))
    tot[(fam, "modules")] += 1
    tot[(fam, "ref_accept")] += (ref[0] == 0)

print(f"runs per module per mode: {N}")
for fam in fams:
    print(f"{fam}: {tot[(fam, 'modules')]} modules, reference ACCEPTS {tot[(fam, 'ref_accept')]}; "
          + "; ".join(f"{mode} wrong {tot[(fam, mode, 'wrong')]}/{tot[(fam, mode, 'runs')]}"
                      for mode in ("sys", "lifo", "nofree")))
print(f"modules with ANY wrong run: {len(bad_rows)}")
for fam, m, row in bad_rows:
    print(f"  {fam}/{m}: {row}")
out = A / f"refs_N{N}.tsv"
with open(out, "w") as fh:
    for (fam, m), r in sorted(refs.items()):
        first_err = next((l for l in r[3].splitlines() if "error:" in l), "")
        fh.write(f"{fam}\t{m}\t{r[0]}\t{r[2]}\t{first_err}\n")
print(f"references written to {out}")
