#!/usr/bin/env python3
"""Rulings Q2 probes (owner 2026-11-11; cq-auqs3). An input on which a bodiless callee receives a pointer into an
object that holds a QUANTUM cell at the call is not compared; the C program decides it (the real object, a cell
holding a rail), and the lowered run may only narrow it.

  q2_ext_read.c          probe: PASS (STRUCTURE ONLY) (exit 3), never PASS; with the _unc of x & 1 dropped (its rail freed
                         dirty where x is odd) FAIL (owner ruling 2026-11-12 "verdict for excluded inputs": the lowered
                         run alone is judged on excluded inputs); probe_classical: PASS.
  q2_global_neighbour.c  q2g (review R1 t4/q2g.c): the neighbouring global holds the rail, not sink's object: compared,
                         PASS; the mutant returning c*3 for c*2 FAILs (it was "PASS (225 compared)").
  q2_local_neighbour.c   q2s (a QUANTUM local beside the callee's array), q2h (a heap block beside the callee's): the
                         same, PASS and the mutant FAILs.

    CQ_BUILD_DIR=<build> python3 tests/eff-tape/q2/run_q2.py
"""
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MUT = ("shl nsw i32 %0, 1", "mul nsw i32 %0, 3")      # return c*2 -> c*3, in the entry's own body
UNC = ("  call void @cq_template_trunc_i32_to_i1_unc(", "  ; _unc dropped: call void @cq_template_trunc_i32_to_i1_unc(")
CASES = [  # (source, entry, mutation or False, wanted exit)
    ("q2_ext_read.c", "probe", False, 3),
    ("q2_ext_read.c", "probe", UNC, 1),
    ("q2_ext_read.c", "probe_classical", False, 0),
    ("q2_global_neighbour.c", "q2g", False, 0),
    ("q2_global_neighbour.c", "q2g", MUT, 1),
    ("q2_local_neighbour.c", "q2s", False, 0),
    ("q2_local_neighbour.c", "q2s", MUT, 1),
    ("q2_local_neighbour.c", "q2h", False, 0),
    ("q2_local_neighbour.c", "q2h", MUT, 1),
]


def lower(src: Path, d: Path) -> None:
    r = subprocess.run([sys.executable, str(ROOT / "driver" / "cqcc"), "-S", str(src), "--save-temps", str(d),
                        "-o", str(d / "out.ll")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"FAIL cqcc {src.name}: {r.stderr[-1500:]}")


def mutant(d: Path, entry: str, mut) -> Path:
    whole = (d / "lowered.ll").read_text()
    start = whole.index(f"define i32 @{entry}(")
    end = whole.index("\n}\n", start)
    body = whole[start:end]
    if body.count(mut[0]) != 1:
        raise SystemExit(f"FAIL the mutation no longer applies to @{entry}: {mut[0]!r} occurs {body.count(mut[0])} times")
    out = d / f"mutant_{entry}.ll"
    out.write_text(whole[:start] + body.replace(mut[0], mut[1]) + whole[end:])
    return out


def main() -> int:
    fails = []
    with tempfile.TemporaryDirectory(prefix="cq-q2-") as t:
        built = {}
        for src, entry, mut, want in CASES:
            d = Path(t) / Path(src).stem
            if src not in built:
                d.mkdir()
                lower(HERE / src, d)
                built[src] = d
            low = mutant(d, entry, mut) if mut else d / "lowered.ll"
            r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(d / "linked.ll"), "--lowered",
                                str(low), "--entry", entry, "--samples", "64"], cwd=ROOT / "checker",
                               capture_output=True, text=True)
            tag = f"{src}:{entry}{' (mutant)' if mut else ''}"
            if r.returncode != want:
                fails.append(f"{tag}: exit {r.returncode}, want {want}:\n{r.stdout[-1500:]}{r.stderr[-500:]}")
            elif want == 3 and "PASS (STRUCTURE ONLY)" not in r.stdout:
                fails.append(f"{tag}: exit 3 without PASS (STRUCTURE ONLY):\n{r.stdout[-800:]}")
            elif mut is UNC and "checked on the lowered run alone" not in r.stdout:
                fails.append(f"{tag}: rejected, but not by a check of the lowered run alone:\n{r.stdout[-800:]}")
            elif want == 0 and "not compared" in r.stdout:
                fails.append(f"{tag}: samples excluded where the C program's object holds no rail:\n{r.stdout[-800:]}")
            else:
                print(f"ok {tag}: exit {r.returncode}")
    for f in fails:
        print("FAIL", f)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
