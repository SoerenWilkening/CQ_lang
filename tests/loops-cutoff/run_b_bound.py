#!/usr/bin/env python3
"""tests/loops-cutoff cq-zge7: a clone's _b bound below SCEV's constant maximum trip count (CR §1.4, rule 14).

For probes/b_bound_i32.O1.ll it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - the _b3 clone of f runs min(K, 3) = 3 trips (three forward mul templates) and frees every rail it defines
    but the one it returns (its a_3 included: B = 3 < K keeps no a_K);
  - the _b7 clone runs K = 4 trips;
  - bb_i32 is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
Outputs go to build/tests/loops-cutoff/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBE = Path(__file__).parent / "probes" / "b_bound_i32.O1.ll"


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "loops-cutoff" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / "b_bound_i32.lowered.ll"
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(PROBE), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
        return 1
    mod = lowered.read_text()
    why = []
    b3 = re.search(r"^define [^\n]*@(__cq_q_f_[01]+_b3_\d+)\(", mod, re.M)
    b7 = re.search(r"^define [^\n]*@(__cq_q_f_[01]+_b7_\d+)\(", mod, re.M)
    if not b3 or not b7:
        why.append("no _b3 or _b7 clone of f")
    else:
        c3, c7 = body(mod, b3.group(1)), body(mod, b7.group(1))
        n3 = len(re.findall(r"@cq_template_mul_i32_hl\(", c3))
        n7 = len(re.findall(r"@cq_template_mul_i32_hl\(", c7))
        if n3 != 3:
            why.append(f"the _b3 clone runs {n3} trips, not 3")
        if n7 != 4:
            why.append(f"the _b7 clone runs {n7} trips, not K = 4")
        ret = re.search(r"^\s*ret i32 (%\d+)", c3, re.M)
        defined = re.findall(r"^\s*(%\d+) = call i32 @(?:cqrt_alloc|cq_template)\w*\(", c3, re.M)
        freed = set(re.findall(r"@cqrt_free\(i32 (%\d+)\)", c3))
        kept = [d for d in defined if d not in freed and (not ret or d != ret.group(1))]
        if kept:
            why.append("the _b3 clone keeps " + ", ".join(kept))
    c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(PROBE), "--lowered", str(lowered),
                        "--entry", "bb_i32"], capture_output=True, text=True, cwd=ROOT / "checker")
    if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
        why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
    print(("FAIL " if why else "ok   ") + "bb_i32" + ("" if not why else ": " + "; ".join(why)))
    return 1 if why else 0


if __name__ == "__main__":
    sys.exit(main())
