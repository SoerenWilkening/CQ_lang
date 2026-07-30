#!/usr/bin/env python3
"""tools/core_abi_link_check.py — the LINK-layer witness for the hand-written
`cqrt_*` core ABI (bd qwcy; the residual of bd 0ktq).

bd 0ktq covered the 2880 YAML-GENERATED `cq_template_*` symbols via a generated
address-taking TU. It deliberately did NOT cover `cqrt_*`, which is hand-written
in `runtime/cq_runtime.h` — enumerating that from a YAML-driven emitter would
mean parsing a hand-written header from the wrong layer. This tool is that
missing half, kept OUT of `gen_templates.py` for exactly that reason.

WHY IT MATTERS: `cqrt_*` is FROZEN-DESIGNATE (CLAUDE.md names the 7.5 QRAM ABI
`cqrt_qram_*`, the 7.6 tape ABI `cqrt_tape_*`, and the kjd1 fp copy family
`cqrt_copy_f{16,32,64,80}_controlled` as freeze gates). Every e2e slice links the
archive and so already witnesses the COMMON core (alloc/free/measure/copy/x/ry)
more strongly than this does — the goldens see ARGUMENTS too. The gap this closes
is the RARE half: controlled twins and widths no committed slice happens to
reach, which are precisely the symbols a freeze should not take on trust.

WHAT PASSING PROVES, exactly: every `cqrt_*` DECLARED in the header is DEFINED in
libcq_runtime.a and resolves at link, and the archive exports nothing outside that
set. It is NOT a coverage number and NOT a correctness claim — the built binary
calls nothing. Measured at introduction: 173 declared / 173 defined / 0 mismatch
either way, so it passes on day one BY CONSTRUCTION. It is a REGRESSION gate.

SELF-VALIDATING BY DESIGN (and this is load-bearing, not decoration): the header
is hand-written, so any extractor over it is fragile — the first draft of this
check used a return-type alternation and silently missed `bool cqrt_measure_i1`
and `_Float16 cqrt_measure_f16`, i.e. it UNDER-COVERED while reporting success.
Comparing the extracted set against `nm` in BOTH directions turns that failure
mode loud: a DEFINED-NOT-DECLARED entry is either a real export leak or a bug in
the extractor, and both need a human. Never "fix" a mismatch by narrowing the
comparison.

Run:  python3 tools/core_abi_link_check.py --archive <libcq_runtime.a> [--cc cc]
      python3 tools/core_abi_link_check.py --archive <...> --selftest
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
HEADER = RUNTIME / "cq_runtime.h"


def declared_symbols(header_text: str) -> set[str]:
    """Every `cqrt_*` declared in the header, return type irrelevant.

    Comment-stripped first, then matched as `cqrt_NAME ( ... ) ;` — deliberately
    tolerant about the return type, because pinning an alternation of return-type
    spellings is exactly how the first draft under-covered.
    """
    text = re.sub(r"/\*.*?\*/", " ", header_text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
    return set(re.findall(r"\b(cqrt_[A-Za-z0-9_]+)\s*\([^;{]*\)\s*;", text))


def defined_symbols(archive: pathlib.Path) -> set[str]:
    r = subprocess.run(["nm", "-g", str(archive)], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"FATAL: nm failed on {archive}:\n{r.stderr[-1000:]}")
    # Accept any global definition kind; the leading underscore is the Mach-O
    # convention and is optional so the check also works on ELF.
    return set(re.findall(r"\s[TtSsDdBb]\s+_?(cqrt_[A-Za-z0-9_]+)$", r.stdout, re.M))


def emit_tu(syms: list[str]) -> str:
    """Address-taking TU. EXTERNAL linkage on the table is load-bearing: a
    `static` unreferenced table is discarded before the linker resolves anything,
    which would make the gate silently vacuous (measured under bd 0ktq, mutant M2
    of tools/link_smoke_selftest.py)."""
    lines = [
        "/* GENERATED AT TEST TIME by tools/core_abi_link_check.py - not committed. */\n",
        "#include \"cq_runtime.h\"\n\n",
        "typedef void (*cq_core_fn)(void);\n\n",
        "cq_core_fn const cq_core_abi_table[] = {\n",
    ]
    lines += [f"    (cq_core_fn) &{s},\n" for s in syms]
    lines += [
        "};\n\n",
        "const unsigned long cq_core_abi_count =\n"
        "    sizeof cq_core_abi_table / sizeof cq_core_abi_table[0];\n\n",
        "int main(void) { return cq_core_abi_count == "
        f"{len(syms)}UL ? 0 : 1; }}\n",
    ]
    return "".join(lines)


def run_check(archive: pathlib.Path, cc: str, header_text: str | None = None,
              quiet: bool = False) -> list[str]:
    """Returns a list of failure strings (empty == pass)."""
    text = header_text if header_text is not None else HEADER.read_text()
    decl = declared_symbols(text)
    defined = defined_symbols(archive)
    problems = []
    missing = sorted(decl - defined)
    extra = sorted(defined - decl)
    if missing:
        problems.append(
            f"{len(missing)} cqrt_* DECLARED but NOT DEFINED in {archive.name}: "
            f"{missing[:8]}{' ...' if len(missing) > 8 else ''} — the pass emits "
            "calls against the header, so these would be link errors in a real slice")
    if extra:
        problems.append(
            f"{len(extra)} cqrt_* DEFINED but NOT DECLARED: {extra[:8]}"
            f"{' ...' if len(extra) > 8 else ''} — either a real export leak, or "
            "declared_symbols() failed to parse a declaration form. BOTH need a "
            "human; do NOT narrow the comparison to silence it")
    if problems:
        return problems

    # The actual link witness.
    with tempfile.TemporaryDirectory() as td:
        work = pathlib.Path(td)
        shutil.copy(HEADER, work / "cq_runtime.h")
        tu = work / "cq_core_abi_smoke.c"
        tu.write_text(emit_tu(sorted(decl)))
        r = subprocess.run([cc, "-I", str(work), str(tu), str(archive),
                            "-o", str(work / "core_smoke")],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return [f"link FAILED for the {len(decl)}-symbol core-ABI TU:\n"
                    f"{r.stderr[-2000:]}"]
    if not quiet:
        print(f"core_abi_link_check: {len(decl)} cqrt_* symbols declared, defined "
              f"and resolved at link")
    return []


def selftest(archive: pathlib.Path, cc: str) -> int:
    """Mutants — a checker nobody has tried to fool is a checker nobody should
    trust (the tools/free_pairing_check_test.py discipline)."""
    failures = []
    base = HEADER.read_text()

    if run_check(archive, cc, quiet=True):
        failures.append("M0: the PRISTINE tree already fails the check")
    else:
        print("M0 control        : PASS (pristine tree passes)")

    # M1 — a declaration with no definition anywhere must be caught.
    m1 = base.replace("bool    cqrt_measure_i1 (int32_t handle);",
                      "bool    cqrt_measure_i1 (int32_t handle);\n"
                      "int32_t cqrt_phantom_symbol_m1(int32_t handle);")
    if m1 == base:
        failures.append("M1: could not inject the phantom declaration (anchor moved)")
    elif run_check(archive, cc, header_text=m1, quiet=True):
        print("M1 phantom decl   : PASS (declared-but-undefined is caught)")
    else:
        failures.append("M1: a declared-but-undefined cqrt_* was NOT caught")

    # M2 — an extractor that misses a declaration must be caught by the reverse
    # direction, not silently under-cover. Simulate by DELETING a declaration the
    # archive still defines.
    m2 = base.replace("bool    cqrt_measure_i1 (int32_t handle);", "")
    if m2 == base:
        failures.append("M2: could not remove the declaration (anchor moved)")
    elif run_check(archive, cc, header_text=m2, quiet=True):
        print("M2 under-coverage : PASS (defined-but-undeclared is caught, so an "
              "extractor gap cannot silently shrink the covered set)")
    else:
        failures.append("M2: a defined-but-undeclared cqrt_* was NOT caught — the "
                        "reverse direction of the comparison is not working, which "
                        "is the whole reason it exists")

    if failures:
        print("\nCORE-ABI LINK SELFTEST FAILED:")
        for f in failures:
            print("  * " + f)
        return 1
    print("\ncore_abi_link_check --selftest: 3/3 mutants behaved as designed")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", required=True)
    ap.add_argument("--cc", default="cc")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    archive = pathlib.Path(a.archive)
    if not archive.exists():
        sys.exit(f"FATAL: archive not found: {archive}")
    if a.selftest:
        return selftest(archive, a.cc)
    problems = run_check(archive, a.cc)
    if problems:
        print("CORE-ABI LINK CHECK FAILED:")
        for p in problems:
            print("  * " + p)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
