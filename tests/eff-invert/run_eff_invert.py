#!/usr/bin/env python3
"""tests/eff-invert (cq-w1-eff-invert, cq-4593): rule 17 probes through the real cq-lower plugin.

Rule 17 (CQ_spec f684858) is the run-time pair cqrt_invert_begin()/cqrt_invert_end() (CR §1.3, BACKEND_ABI
1.13): the bracketed code is lowered as anywhere else and the backend reverses and inverts the gates recorded
between the two calls. For each probe file in CHECKED it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call and no asm fence is left in any entry, and every __cq_invert_begin/_end of the
    entry's .O1.ll became one cqrt_invert_begin/_end call;
  - no _adj clone exists (§1.4: retired);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`: the evaluator records the gates
    of a region and replays them reversed and inverted at its end; the C oracle reads the region's sites
    reversed with their angles negated).
The probes cover a flat region, quantum arms, nesting, regions around and between calls, classical branches
and loops in a region, clone calls (with phases, several returns, rotating a register a region template
reads: clone_rot), seeds a region prepares,
a quantum arm under a classical guard (guard), clone calls and region code sharing memory (mem_clone_*), a bus store
and an effect entry as flush points, the in-place form and a load un-copied inside a region (invert_mem, rule 17 Memory),
and a region whose value is read after it (region_output: the rail outlives the region, rule 17), and a
measurement inside a region (invert_measure: the backend flushes the gates before it forward).
Markers in quantum arms (CR rule 17, 2026-11-02, cq-asfn; CQ.h makes them noduplicate): dup_begin and dup_end
(the shapes -O1 made by duplicating a marker before the attribute, now one marker in the join), invert_arm (a
pair in one arm; a begin in an arm with its end after the join; an end in an arm with its begin before the
branch; a begin in a nested arm).
The examples' acceptance is `python3 -m cqcheck run 44 61 126 --oracle both` (cq-4593).
Outputs go to build/tests/eff-invert/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
CHECKED = {"invert.O1.ll": ["p_flat", "p_arms", "p_nest", "p_around", "p_two"],
           "invert2.O1.ll": ["p_inplace", "p_cbr", "p_reg", "p_cswitch"],
           "invert_loop.O1.ll": ["p_cloop"],
           "invert_adj.O1.ll": ["p_adj"],
           "invert_barrier.O1.ll": ["p_barrier"],
           "invert_seed.O1.ll": ["p_seedin", "p_seedtrip", "p_seedarm"],
           "invert_ret.O1.ll": ["p_adjret"],
           "invert_retq.O1.ll": ["p_adjretq"],
           "invert_calls.O1.ll": ["p_between", "p_nested"],
           "clone_rot.O1.ll": ["p12"],
           "invert_measure.O1.ll": ["p_meas"],
           "guard.O1.ll": ["p_guard"],
           "mem_clone_global.O1.ll": ["i12"],
           "mem_clone_pair.O1.ll": ["i11"],
           "mem_clone_qrom.O1.ll": ["i10"],
           "invert_mem.O1.ll": ["p_store_flush", "p_inplace_cell", "p_load_inside", "p_effect_flush"],
           "region_output.O1.ll": ["p_out"],
           "dup_begin.O1.ll": ["p_dup"],
           "dup_end.O1.ll": ["p_dupend"],
           "invert_arm.O1.ll": ["p_armpair", "p_armbegin", "p_armend", "p_armnest"]}
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(|call void asm")
ERRORS = {}
MARKER = re.compile(r"call void @(?:__cq|cqrt)_invert_(begin|end)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def lower(a, src: Path, dest: Path):
    return subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(src), "-o",
                           str(dest)], capture_output=True, text=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "eff-invert" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0

    for name, text in ERRORS.items():
        r = lower(a, PROBES / name, out / ("err_" + name))
        ok = r.returncode != 0 and text in r.stderr
        failures += not ok
        print(f"{'ok' if ok else 'FAIL':4} {name}" + ("" if ok else "\n     expected: " + text + "\n     got: " +
                                                        (r.stderr.strip() or "exit 0")))

    for name, entries in CHECKED.items():
        probe = PROBES / name
        lowered = out / name.replace(".O1.ll", ".lowered.ll")
        r = lower(a, probe, lowered)
        if r.returncode != 0:
            failures += 1
            print(f"FAIL cq-lower {name}: " + r.stderr.strip())
            continue
        v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                            str(lowered)], capture_output=True, text=True)
        if v.returncode != 0:
            failures += 1
            print(f"FAIL cq-verify {name}: " + v.stderr.strip())
            continue
        text = lowered.read_text()
        src = probe.read_text()
        if re.search(r"@__cq_q_\w*_adj\b", text):
            failures += 1
            print(f"FAIL {name}: an _adj clone (retired, CR §1.4)")
        for e in entries:
            if a.entry and e not in a.entry:
                continue
            b = body(text, e)
            why = []
            if not b:
                why.append("no lowered body")
            if SURFACE.search(b):
                why.append("a CQ.h surface call or an asm fence is left")
            if sorted(MARKER.findall(b)) != sorted(MARKER.findall(body(src, e))):
                why.append("the cqrt_invert_begin/_end calls are not the entry's markers")
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered",
                                str(lowered), "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("cqcheck user: " + (c.stdout + c.stderr).strip()[-2000:])
            failures += bool(why)
            print(f"{'ok' if not why else 'FAIL':4} {e}" + "".join("\n     " + x for x in why))
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
