#!/usr/bin/env python3
"""tests/loops-cutoff rule 6 probes (cq-41v2): CR rule 6 on carried values of a K-cutoff loop (rule 14 case 2).

For probes/rule6.O1.ll it checks, and fails on:
  - cq-lower exits 0 and plain cq-verify accepts the output;
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle);
  - on every sample, the kept rails (role, width) are exactly the table below: no old value of the carried update;
  - k_xr: the Ry after the loop follows every uncompute and free (no old rail is live under it): on no control-flow
    path of the lowered function does a cqrt_free or an _unc follow the last Ry (one with no Ry after it on any path),
    whether the trips are K static copies or one rolled trip with a reverse loop placed later in the text (cq-9kcq).
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
# The straight-line rule 6 multiset plus rule 14's overflow flag a_K (q_c, no bound known). The checker names a kept
# overflow predicate by its own role a_K since cq-1leyz (run.kept_ak_module, compare _KEPT_ROLES); before that it was
# the i1 "garbage" rail the leak rule allowed on capped samples.
KEPT = {"k_xq": [("frozen", "i32"), ("a_K", "i1"), ("measured", "i32")],
        "k_sub": [("frozen", "i32"), ("a_K", "i1"), ("measured", "i32")],
        "k_xr": [("frozen", "i32"), ("a_K", "i1"), ("measured", "i32")]}
RY_LAST = ["k_xr"]
# The RY_LAST walk's own mutant (kept permanent): the exit compare's uncompute and free moved below the last Ry must be
# reported, in either form of the loop.
RY_MUTANT = (r"(  call void @cq_template_icmp_sgt_i32_hl_unc\([^\n]*\n  call void @cqrt_free\(i32 (%\d+)\)\n)"
             r"(  call void @cqrt_ry_i32\(i32 %\d+, double %\d+\)\n)", r"\3\1")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def blocks(fn_body: str):
    """The basic blocks of one lowered function: [(label, [instruction lines], [successor labels])] in text order."""
    out = []
    for line in fn_body.splitlines()[1:]:
        m = re.match(r"^([-\w.$]+):", line)
        if m or not out:
            out.append([m.group(1) if m else "<entry>", [], []])
            if m:
                continue
        if line.startswith("}"):
            break
        if line.strip():
            out[-1][1].append(line)
    for b in out:
        for line in b[1]:
            b[2].extend(re.findall(r"label %([-\w.$]+)", line))
    return out


def after_last_ry(fn_body: str):
    """The cqrt_free / _unc lines control flow can reach after a last Ry (an @cqrt_ry_ call from which no Ry, itself
    again included, is reachable), and the number of such last Ry. Text order plays no part: a reverse loop placed
    after the Ry's block in the file but run before it is not reached from it."""
    bl = blocks(fn_body)
    succ = {b[0]: b[2] for b in bl}
    lines = {b[0]: b[1] for b in bl}

    def reach(label, start):
        """The instruction lines run after position start of block label: its rest, then every reachable block."""
        seen, todo, got = set(), list(succ.get(label, [])), list(lines[label][start:])
        while todo:
            x = todo.pop()
            if x in seen or x not in lines:
                continue
            seen.add(x)
            got.extend(lines[x])
            todo.extend(succ[x])
        return got

    last, late = 0, []
    for b in bl:
        for i, l in enumerate(b[1]):
            if "@cqrt_ry_" not in l:
                continue
            after = reach(b[0], i + 1)
            if any("@cqrt_ry_" in x for x in after):
                continue
            last += 1
            late.extend(x.strip() for x in after if "@cqrt_free(" in x or "_unc(" in x)
    return late, last


def kept(lowered: Path, entry: str, want) -> str:
    sys.path.insert(0, str(ROOT / "checker"))
    from cqcheck import run, sampling, user
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        lowp = work / f"user_{entry}.lowered.ll"
        lowp.write_text(lowered.read_text())
        spec, exdir = user.build_spec(PROBE.read_text(), entry, work)
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
            late, last = after_last_ry(b)
            if not last or late:
                why.append("an uncompute or free follows the Ry after the loop: " + (late[0] if late else "no Ry"))
            mb = re.sub(RY_MUTANT[0], RY_MUTANT[1], b, count=1)
            if mb == b or not after_last_ry(mb)[0]:
                why.append("the RY_LAST walk does not report its mutant (a free moved below the Ry)")
        k = kept(lowered, e, want)
        if k:
            why.append(k)
        print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
