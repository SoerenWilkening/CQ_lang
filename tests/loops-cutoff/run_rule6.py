#!/usr/bin/env python3
"""tests/loops-cutoff rule 6 probes (cq-41v2): CR rule 6 on carried values of a K-cutoff loop (rule 14 case 2).

For probes/rule6.O1.ll it checks, and fails on:
  - cq-lower exits 0 and plain cq-verify accepts the output;
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle);
  - on every sample, the kept rails (role, width) are exactly the table below: no old value of the carried update;
  - k_xr: the Ry after the loop follows every uncompute and free (no old rail is live under it).
Outputs go to build/tests/loops-cutoff/out/.
"""
import argparse
import collections
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBE = Path(__file__).parent / "probes" / "rule6.O1.ll"
# The straight-line rule 6 multiset plus rule 14's overflow flag (q_c, no bound known).
KEPT = {"k_xq": [("frozen", "i32"), ("garbage", "i1"), ("measured", "i32")],
        "k_sub": [("frozen", "i32"), ("garbage", "i1"), ("measured", "i32")],
        "k_xr": [("frozen", "i32"), ("garbage", "i1"), ("measured", "i32")]}
RY_LAST = ["k_xr"]


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def kept(lowered: Path, entry: str, want) -> str:
    sys.path.insert(0, str(ROOT / "checker"))
    from cqcheck import run, sampling, user
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        lowp = work / f"user_{entry}.lowered.ll"
        lowp.write_text(lowered.read_text())
        spec, exdir = user.build_spec(PROBE.read_text(), entry, work, user.handle_cell_params(lowp, entry))
        c_module = next(exdir.glob("*.O1.ll"))
        ss = sampling.sample_set(spec, exdir, exempt_baseline=False)
        hist = collections.Counter()
        for r in run.run_samples(lowp, spec, ss.samples[:48], "ours", 4, c_module=c_module):
            hist[tuple(sorted((k.get("role"), k.get("w")) for k in (r.kept or [])))] += 1
        if set(hist) != {tuple(sorted(want))}:
            return "kept rails " + str(dict(hist)) + ", want " + str(sorted(want))
    return ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "loops-cutoff" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / "rule6.lowered.ll"
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(PROBE), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower: " + r.stderr.strip())
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify: " + v.stderr.strip())
        return 1
    text = lowered.read_text()
    failures = 0
    for e, want in KEPT.items():
        why = []
        b = body(text, e)
        if not b:
            why.append("no lowered body")
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(PROBE), "--lowered", str(lowered),
                            "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        if e in RY_LAST:
            lines = b.splitlines()
            ry = max((i for i, l in enumerate(lines) if "@cqrt_ry_" in l), default=-1)
            late = [l.strip() for l in lines[ry + 1:] if "@cqrt_free(" in l or "_unc(" in l]
            if ry < 0 or late:
                why.append("an uncompute or free follows the Ry after the loop: " + (late[0] if late else "no Ry"))
        k = kept(lowered, e, want)
        if k:
            why.append(k)
        print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
