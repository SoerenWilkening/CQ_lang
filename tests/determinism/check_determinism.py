#!/usr/bin/env python3
"""The pass is deterministic (cq-fm68i, owner requirement): each named input is lowered twice, in two
processes with their own heap and library addresses, and the outputs must be byte-identical."""
import argparse
import difflib
import pathlib
import subprocess
import sys

EXAMPLES = ("27", "97", "153", "187", "211", "195")
MUSL = "wt/musl_sweep/libc_out/run/setlocale/L.ll"   # relative to the directory holding CQ_spec; optional


def lower(opt, plugin, ll):
    r = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", "-cq-k-default=4", "-S", str(ll), "-o", "-"],
                       capture_output=True)
    return r.returncode, r.stdout, r.stderr


def aslr_on():
    """Separate processes see different heap addresses; otherwise this test proves nothing."""
    probe = [sys.executable, "-c", "print(id(object()))"]
    return len({subprocess.run(probe, capture_output=True, text=True, check=True).stdout for _ in range(4)}) > 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--opt", required=True)
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--spec", required=True, type=pathlib.Path)
    a = ap.parse_args()
    if not aslr_on():
        print("FAIL: address randomization is off")
        return 1
    dirs = {d.name.split("_", 1)[0]: d for d in (a.spec / "examples").iterdir() if d.is_dir()}
    inputs = []
    for n in EXAMPLES:
        d = dirs[n]
        inputs.append((n, d / (d.name.split("_", 1)[1] + ".O1.ll")))
    musl = a.spec.resolve().parent / MUSL
    if musl.exists():
        inputs.append(("setlocale", musl))
    bad = 0
    for name, ll in inputs:
        rc1, o1, e1 = lower(a.opt, a.plugin, ll)
        rc2, o2, _ = lower(a.opt, a.plugin, ll)
        if rc1 or rc2:
            print(f"FAIL {name}: exit {rc1}, {rc2}\n{e1.decode(errors='replace')[-2000:]}")
            bad += 1
        elif o1 != o2:
            diff = difflib.unified_diff(o1.decode().splitlines(), o2.decode().splitlines(), "run1", "run2", lineterm="", n=0)
            print(f"FAIL {name}: outputs differ")
            print("\n".join(list(diff)[:40]))
            bad += 1
        else:
            print(f"ok {name} ({len(o1)} bytes)")
    print(f"{len(inputs) - bad}/{len(inputs)} byte-identical")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
