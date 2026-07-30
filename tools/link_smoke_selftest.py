#!/usr/bin/env python3
"""tools/link_smoke_selftest.py — mutant validation for the bd 0ktq link gate.

A checker nobody has tried to fool is a checker nobody should trust. The
`runtime_link_smoke` ctest entry passes today by construction (2880 generated
symbols declared, 2880 defined), so a GREEN result proves nothing about whether
the gate can still FAIL. This self-test constructs archives that SHOULD break it
and asserts that they do — the same discipline `tools/free_pairing_check_test.py`
applies to the Rule-6 free-pairing checker.

Mutants:
  M0 (control)  pristine archive                      -> MUST link
  M1            one symbol's DEFINITION removed        -> MUST fail to link
  M2            table made `static` and unreferenced,  -> MUST fail to link
                compiled -O2, against the M1 archive      (i.e. the gate must NOT
                                                           be vacuous)

M2 is the load-bearing one and is why `emit_smoke` gives the table EXTERNAL
linkage. MEASURED 2026-07-30: with a `static` unreferenced table at -O2 the
compiler discards the whole table before the linker ever looks the symbols up, so
the link SUCCEEDS despite a missing definition — the gate silently becomes
vacuous. M2 pins that a future "tidy up the unused global" refactor cannot quietly
delete the gate's teeth. If M2 ever reports that the static form still catches the
missing symbol, the toolchain changed; re-derive the design note in emit_smoke
rather than deleting this test.

Run: python3 tools/link_smoke_selftest.py [--cc cc]
"""
from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
RUNTIME = REPO / "runtime"
SOURCES = ["cq_templates.c", "cq_intrinsic_templates.c", "cq_libm_templates.c",
           "cq_runtime.c"]
# A symbol whose definition M1 removes. Any generated symbol works; this one is
# the first row of the opcode table and is stable across regenerations.
VICTIM = "cq_template_add_i1"


def build_archive(work: pathlib.Path, cc: str, label: str) -> pathlib.Path:
    objs = []
    for src in SOURCES:
        obj = work / (src[:-2] + f".{label}.o")
        r = subprocess.run([cc, "-c", "-I", str(work), str(work / src), "-o", str(obj)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit(f"FATAL: could not compile {src} for {label}:\n{r.stderr[-2000:]}")
        objs.append(str(obj))
    arch = work / f"lib{label}.a"
    subprocess.run(["ar", "rcs", str(arch)] + objs, check=True)
    return arch


def try_link(work: pathlib.Path, cc: str, smoke: pathlib.Path,
             arch: pathlib.Path, out: str, extra: list[str]) -> bool:
    """True iff the link SUCCEEDS."""
    r = subprocess.run([cc, "-I", str(work)] + extra + [str(smoke), str(arch),
                       "-o", str(work / out)], capture_output=True, text=True)
    return r.returncode == 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cc", default="cc")
    args = ap.parse_args()

    smoke_src = RUNTIME / "cq_link_smoke.c"
    if not smoke_src.exists():
        sys.exit("FATAL: runtime/cq_link_smoke.c missing — regenerate with "
                 "`python3 tools/gen_templates.py --output-dir runtime --targets smoke`")

    failures = []
    with tempfile.TemporaryDirectory() as td:
        work = pathlib.Path(td)
        for f in SOURCES + ["cq_runtime.h", "cq_templates.h",
                            "cq_intrinsic_templates.h", "cq_libm_templates.h",
                            "cq_link_smoke.c"]:
            shutil.copy(RUNTIME / f, work / f)

        # ---- M0: control. The pristine archive must link. ----
        pristine = build_archive(work, args.cc, "pristine")
        if try_link(work, args.cc, work / "cq_link_smoke.c", pristine, "m0", []):
            print("M0 control      : PASS (pristine archive links)")
        else:
            failures.append("M0: the PRISTINE archive failed to link — the gate is "
                            "broken independently of any mutant")

        # ---- M1: remove one definition. The link must FAIL. ----
        tmpl = work / "cq_templates.c"
        src = tmpl.read_text()
        m = re.search(r"\n[A-Za-z_][A-Za-z0-9_ ]*\b" + VICTIM + r"\([^)]*\)\s*\{.*?\n\}\n",
                      src, re.S)
        if not m:
            sys.exit(f"FATAL: could not locate the definition of {VICTIM} to mutate; "
                     "update VICTIM or the regex")
        tmpl.write_text(src[:m.start()] + f"\n/* M1: {VICTIM} definition removed */\n"
                        + src[m.end():])
        mutant = build_archive(work, args.cc, "mutant")
        if try_link(work, args.cc, work / "cq_link_smoke.c", mutant, "m1", []):
            failures.append(f"M1: the link SUCCEEDED with {VICTIM} undefined — the gate "
                            "does not actually witness resolution")
        else:
            print(f"M1 missing def  : PASS (link fails when {VICTIM} is undefined)")

        # ---- M2: the vacuity trap. `static` + unreferenced + -O2. ----
        stat_src = (work / "cq_link_smoke.c").read_text()
        stat_src = stat_src.replace("\ncq_link_smoke_fn const cq_link_smoke_table[]",
                                    "\nstatic cq_link_smoke_fn const cq_link_smoke_table[]")
        stat_src = re.sub(r"const unsigned long cq_link_smoke_count =\s*\n\s*sizeof"
                          r" cq_link_smoke_table / sizeof cq_link_smoke_table\[0\];",
                          "const unsigned long cq_link_smoke_count = 0UL;", stat_src)
        stat_src = re.sub(r"return cq_link_smoke_count == \d+UL \? 0 : 1;",
                          "return 0;", stat_src)
        (work / "smoke_static.c").write_text(stat_src)
        if try_link(work, args.cc, work / "smoke_static.c", mutant, "m2", ["-O2"]):
            print("M2 vacuity trap : PASS (a `static` unreferenced table IS discarded, "
                  "so external linkage is load-bearing — as emit_smoke documents)")
        else:
            failures.append("M2: a `static` unreferenced table still caught the missing "
                            "symbol. The toolchain changed; re-derive the external-linkage "
                            "design note in gen_templates.py::emit_smoke rather than "
                            "deleting this check")

    if failures:
        print("\nLINK-SMOKE SELFTEST FAILED:")
        for f in failures:
            print("  * " + f)
        return 1
    print("\nlink_smoke_selftest: 3/3 mutants behaved as designed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
