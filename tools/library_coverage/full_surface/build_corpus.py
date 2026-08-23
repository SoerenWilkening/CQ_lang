#!/usr/bin/env python3
"""build_corpus.py — build the openlibm bitcode corpus the census measures.

*** THIS SCRIPT IS THE RECIPE. *** It replaces the hand-copied shell block that
used to live in README.md "Reproduce" step 1/1b. That block was prose, so nothing
executed it and nothing checked it — and it shipped a defect for the whole
campaign (bd `3c6m.63`, below). The README now points HERE; if the two ever
disagree, this file is the one that ran.

--------------------------------------------------------------------------
THE DEFECT THIS FILE EXISTS TO PREVENT (bd `test_C_libtooling-3c6m.63`)
--------------------------------------------------------------------------
The old recipe globbed

    for c in $OLA/src/*.c $OLA/bsdsrc/*.c $OLA/ld80/*.c
        -> bc/$(basename ${c%.c}).bc          # ld80 LAST

and **TEN basenames exist in both `src/` and `ld80/`**, so all ten resolved to
the `ld80` body — which **openlibm's own build EXCLUDES on every target**. The
census was therefore measuring, for those ten, a program that ships nowhere.
Measured effect when corrected: injection coverage **100/120 -> 97/120**
(`nextafterl.f80`, `nexttoward.f64`, `nexttowardf.f32` all flip COMPILES ->
decline), and `s_truncl.bc` — which did not exist at all, because the failing
ld80 build DESTROYED the src build's output slot — appears.

That is the retired `165/174` error class in a new place: **a number measuring a
program that ships nowhere.** No gate saw it. The old README preflight
(`251 .bc -> 409 syms`, missing-list empty) passed on BOTH corpora.

--------------------------------------------------------------------------
THE FIX, AND WHY IT IS A DERIVATION AND NOT A LIST
--------------------------------------------------------------------------
An `ld80/X.c` for which `src/X.c` also exists is **not built by openlibm** and is
skipped here. That rule is checked against openlibm's OWN build configuration
rather than trusted, by two independent derivations that must agree exactly
(`_derive_ld80_exclusions`):

  (i)  BASENAME COLLISION — `src/X.c` exists, so the shared-output-slot hazard is
       present by construction.
  (ii) `ld80/Make.files` — openlibm lists the ld80 files it builds in
       `$(CUR_SRCS) +=`; everything else in `ld80/` is excluded. (Eight of the
       ten sit in that file's commented-out block; `s_nexttoward.c` and
       `s_nexttowardf.c` are simply absent from it. `CMakeLists.txt` names
       `src/` for every one — lines 174/275/280/284/289/293/297/298/307/309.)

A DISAGREEMENT IS A LOUD FAILURE, not a warning. If a future openlibm bump moves
a file between the two directories, the census must stop rather than silently
measure the other body — which is the entire lesson of `3c6m.63`. Hard-coding
the ten names would have re-created the original defect one refactor later.

Note the ORDER-INDEPENDENCE this buys: the fix is deliberately NOT "glob src/
last so it wins". Last-write-wins is silent in the wrong direction too — if
`src/X.c` ever failed to build while `ld80/X.c` succeeded, the ld80 body would be
inherited with no signal. Here a src-side failure leaves NO body, which
`full_census.py`'s bd-`keol` check reports as `no-body` and never as a blocker.

--------------------------------------------------------------------------
WHAT THIS DOES *NOT* CLAIM (read before quoting it)
--------------------------------------------------------------------------
  * It does not make the corpus byte-equal to a real `libopenlibm.a`. On amd64
    openlibm also builds hand-written assembly (`amd64/e_fmodl.S`,
    `amd64/s_remquol.S`, `amd64/e_sqrtl.S`, `amd64/s_rintl.S`, `amd64/s_logbl.S`,
    …) which has no C source to inject and which this corpus does not model.
    Rule 18 measures SOURCE injection, so a C body openlibm builds is the right
    unit here; but "the corpus is now faithful" means *faithful about which C
    body*, and nothing stronger.
  * It does not re-measure the Rule-18 keep-set. `wprobe.keep_shims()` owns that,
    at the defmap.
  * The blanket `-fno-builtin` is CORRECT and must stay: a libm source built with
    builtins ON self-recurses (clang recognizes `s_floor.c`'s body as `floor`).
    It does not defeat the keep-set for INNER calls — `keep_shims()` re-applies
    the ship-floor fold at the defmap (bd `3c6m.60`).
  * `-I "$OLA"` (the openlibm ROOT) is LOAD-BEARING (bd `20xt`): ld80 files
    include root-relative `"ld80/invtrig.h"` paths.
  * Failures are REPORTED, never swallowed. The old recipe sent stderr to
    /dev/null, which is how five corpus/bucket measurement errors reached the
    record (bd `tegx`: check rc AND the error count, never rc alone).

Usage:
    build_corpus.py --openlibm <src-tree> --out <bc-dir> [--clang <path>]
                    [--expect-bc N] [--keep-going] [-q]
Exit 0 = corpus built and every self-check passed
     1 = a self-check failed (the corpus is NOT usable for a census)
     2 = the script could not run (bad paths, missing clang)
"""
from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import sys

DEFAULT_CLANG = "/usr/local/opt/llvm@19/bin/clang"
DEFAULT_DIS = "/usr/local/opt/llvm@19/bin/llvm-dis"

# The BSD constants several openlibm TUs use without declaring. Applied to the
# named files only, exactly as the old recipe did — a blanket define would change
# bodies that compile fine today.
BSD_PI = ["-DM_PI=3.14159265358979323846",
          "-DM_PI_2=1.57079632679489661923",
          "-DM_PI_4=0.78539816339744830962"]
# Rebuilt with BSD_PI. src/s_{cos,sin,tan}{l,f}.c hit an undeclared M_PI_2 at
# their first constant; without this they drop out of the corpus and the trig
# cells mis-census as a spurious "unknown callee" instead of their REAL blocker,
# the Payne-Hanek reduction (bd `tkju`, 2026-07-27 — this masked cosf/sinf/tanf
# for the whole campaign).
PI_REBUILD = ["s_cosl", "s_sinl", "s_tanl", "s_cosf", "s_sinf", "s_tanf"]

# Public names openlibm mints through build-level symbol aliasing, which a raw
# `-emit-llvm -c` corpus does not reproduce (bd `3c6m.50` Step 0c). NB the
# module-asm `.set` aliases are handled generically by `wprobe._synth_alias_shim`
# (bd `vuy6`) and are deliberately NOT duplicated here.
LGAMMA_PUBLIC_SHIM = """\
extern double lgamma_r(double,int*); extern float lgammaf_r(float,int*);
extern long double lgammal_r(long double,int*); int signgam;
double lgamma(double x){return lgamma_r(x,&signgam);}
float lgammaf(float x){return lgammaf_r(x,&signgam);}
long double lgammal(long double x){return lgammal_r(x,&signgam);}
"""
LDEXP_SHIM = """\
extern double scalbn(double,int); extern float scalbnf(float,int);
extern long double scalbnl(long double,int);
double ldexp(double x,int n){return scalbn(x,n);}
float ldexpf(float x,int n){return scalbnf(x,n);}
long double ldexpl(long double x,int n){return scalbnl(x,n);}
"""

# TUs that do not build under this flag set and are KNOWN-ABSENT from the corpus.
# Listed so a reader can tell a tolerated gap from a regression: an unexpected
# failure is reported as an ERROR, one of these as a NOTE. None is a math.h
# census cell today — `e_lgamma*` are superseded by LGAMMA_PUBLIC_SHIM, the
# `s_c*` files are <complex.h>, and `e_jn`/`s_sincosf` are non-C-standard.
# *** This is a tolerance list, NOT a claim that the gaps are harmless. *** If a
# future MATHH_SPEC row needs one of these bodies, `full_census.py`'s bd-`keol`
# check reports it as `no-body` — that is the gate, not this comment.
KNOWN_UNBUILDABLE = {
    "e_jn": "calls undeclared j0/j1/y0/y1 (openlibm_math.h does not declare the Bessel set)",
    "e_jnf": "same as e_jn, float",
    "e_lgamma": "calls undeclared lgamma_r/signgam — superseded by the lgamma public shim",
    "e_lgammaf": "same as e_lgamma, float",
    "e_lgammal": "same as e_lgamma, long double",
    "s_cacos": "<complex.h>: undeclared M_PI_2",
    "s_cacosf": "<complex.h>: undeclared M_PI_2",
    "s_casin": "<complex.h>: undeclared M_PI_2",
    "s_casinf": "<complex.h>: undeclared M_PI_2",
    "s_catan": "<complex.h>: undeclared M_PI_2",
    "s_catanf": "<complex.h>: undeclared M_PI_2",
    "s_ctan": "<complex.h>: undeclared M_PI_2",
    "s_ctanf": "<complex.h>: undeclared M_PI_2",
    "s_sincosf": "undeclared M_PI_2 (non-C-standard sincosf)",
}


def _fail(msg: str, code: int = 1) -> None:
    print(f"\n!! {msg}", file=sys.stderr)
    sys.exit(code)


def _make_files_sources(path: pathlib.Path) -> set[str]:
    """The set of `.c` basenames a `Make.files` fragment adds to `$(CUR_SRCS)`.

    Commented lines are dropped FIRST, which is the whole point: openlibm records
    the ld80 bodies it does not build as an `#`-commented block, and reading them
    as built would silently restore the 3c6m.63 defect."""
    out: set[str] = set()
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0]
        if "$(CUR_SRCS)" not in line and not out and "+=" not in line:
            # allow continuation lines only once a `$(CUR_SRCS)` line has opened
            pass
        for m in re.finditer(r"([A-Za-z0-9_]+)\.c\b", line):
            out.add(m.group(1))
    return out


def _derive_ld80_exclusions(ola: pathlib.Path) -> set[str]:
    """ld80 `.c` stems openlibm does NOT build — derived twice, cross-checked.

    (i) basename collides with `src/`; (ii) absent from `ld80/Make.files`
    `$(CUR_SRCS)`. Disagreement is fatal: see the module docstring."""
    ld80 = {p.stem for p in (ola / "ld80").glob("*.c")}
    src = {p.stem for p in (ola / "src").glob("*.c")}
    by_collision = ld80 & src
    mk = ola / "ld80" / "Make.files"
    if not mk.exists():
        _fail(f"ld80/Make.files not found under {ola} — cannot derive the exclusion "
              f"set. Refusing to guess (bd 3c6m.63).", 2)
    by_makefile = ld80 - _make_files_sources(mk)
    if by_collision != by_makefile:
        only_c = sorted(by_collision - by_makefile)
        only_m = sorted(by_makefile - by_collision)
        _fail("ld80 EXCLUSION DERIVATIONS DISAGREE — refusing to build a corpus "
              "whose faithfulness cannot be established (bd 3c6m.63).\n"
              f"   collides with src/ but IS in ld80/Make.files: {only_c}\n"
              f"   in neither src/ nor ld80/Make.files:          {only_m}\n"
              "   openlibm's layout has changed. Re-derive which body each name "
              "resolves to (CMakeLists.txt + ld80/Make.files) before re-running.")
    return by_collision


def _compile(clang: str, inc: list[str], src: pathlib.Path, out: pathlib.Path,
             extra: list[str] | None = None) -> tuple[int, int, str]:
    """Returns (rc, error_count, stderr). Never redirects stderr away — bd `tegx`:
    five corpus measurement errors reached the record by trusting rc alone."""
    cmd = [clang, "-g", "-O1", "-fno-builtin"] + (extra or []) + \
          ["-emit-llvm", "-c"] + inc + [str(src), "-o", str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, r.stderr.count("error:"), r.stderr


def _source_filename(dis: str, bc: pathlib.Path) -> str | None:
    r = subprocess.run([dis, str(bc), "-o", "-"], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    m = re.search(r'^source_filename = "([^"]*)"', r.stdout, re.M)
    return m.group(1) if m else None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--openlibm", required=True, help="openlibm source tree")
    ap.add_argument("--out", required=True, help="output bitcode dir (RECREATED)")
    ap.add_argument("--clang", default=DEFAULT_CLANG,
                    help="LLVM-19 clang (a newer clang writes bitcode LLVM-19 "
                         "llvm-dis cannot read)")
    ap.add_argument("--llvm-dis", default=DEFAULT_DIS)
    ap.add_argument("--expect-bc", type=int, default=None,
                    help="fail unless exactly N .bc files are produced")
    ap.add_argument("-q", "--quiet", action="store_true")
    a = ap.parse_args()

    ola = pathlib.Path(a.openlibm).resolve()
    bc = pathlib.Path(a.out).resolve()
    if not (ola / "src").is_dir() or not (ola / "ld80").is_dir():
        _fail(f"{ola} does not look like an openlibm tree (no src/ + ld80/)", 2)
    if not pathlib.Path(a.clang).exists():
        _fail(f"clang not found: {a.clang}", 2)

    inc = []
    for d in ("", "include", "src", "amd64", "bsdsrc", "ld80"):
        inc += ["-I", str(ola / d) if d else str(ola)]

    excluded = _derive_ld80_exclusions(ola)
    say = (lambda *x: None) if a.quiet else (lambda *x: print(*x))
    say(f"openlibm : {ola}")
    say(f"output   : {bc}")
    say(f"ld80 bodies openlibm does NOT build ({len(excluded)}), skipped: "
        f"{' '.join(sorted(excluded))}")

    if bc.exists():
        shutil.rmtree(bc)
    bc.mkdir(parents=True)

    # ---- step 1: every buildable TU, one .bc per basename -------------------
    planned: dict[str, pathlib.Path] = {}
    for d in ("src", "bsdsrc", "ld80"):
        for c in sorted((ola / d).glob("*.c")):
            if d == "ld80" and c.stem in excluded:
                continue
            if c.stem in planned:
                # Cannot happen given the exclusion above, but this is the exact
                # defect 3c6m.63 was, so it is asserted rather than assumed.
                _fail(f"OUTPUT SLOT COLLISION: {c} and {planned[c.stem]} both map "
                      f"to {c.stem}.bc. Two bodies, one slot — this is bd 3c6m.63.")
            planned[c.stem] = c

    unexpected_fail, tolerated_fail, built = [], [], 0
    for stem, c in sorted(planned.items()):
        extra = BSD_PI if stem in PI_REBUILD else None
        rc, nerr, err = _compile(a.clang, inc, c, bc / f"{stem}.bc", extra)
        if rc != 0 or nerr:
            (bc / f"{stem}.bc").unlink(missing_ok=True)
            if stem in KNOWN_UNBUILDABLE:
                tolerated_fail.append(stem)
            else:
                unexpected_fail.append((stem, str(c), nerr,
                                        err.strip().splitlines()[:2]))
        else:
            built += 1

    # ---- step 1b: bodies openlibm mints via build-level aliasing ------------
    # b_tgamma needs the BSD constants; it is in bsdsrc so it was attempted above
    # without them. Rebuild rather than special-case the loop, so the loop stays
    # a plain "one TU -> one .bc".
    rc, nerr, err = _compile(a.clang, inc, ola / "bsdsrc" / "b_tgamma.c",
                             bc / "b_tgamma.bc", BSD_PI)
    if rc != 0 or nerr:
        _fail(f"b_tgamma.c failed to build ({nerr} errors) — the tgamma cells would "
              f"mis-census as 'unknown callee'.\n{err.strip()[:400]}")
    if "b_tgamma" in [f[0] for f in unexpected_fail]:
        unexpected_fail = [f for f in unexpected_fail if f[0] != "b_tgamma"]
        built += 1

    # Compiled from STDIN, deliberately. Writing the .c anywhere real embeds that
    # path in `source_filename`, which makes the corpus non-reproducible between two
    # output directories — measured, and it was the ONLY byte difference between two
    # otherwise identical builds. `<stdin>` is stable.
    for name, text in (("lgamma_public_shim", LGAMMA_PUBLIC_SHIM),
                       ("ldexp_shim", LDEXP_SHIM)):
        r = subprocess.run(
            [a.clang, "-g", "-O1", "-fno-builtin", "-x", "c", "-emit-llvm", "-c"]
            + inc + ["-", "-o", str(bc / f"{name}.bc")],
            input=text, capture_output=True, text=True)
        if r.returncode != 0 or r.stderr.count("error:"):
            _fail(f"{name} failed to build:\n{r.stderr.strip()[:400]}")
        built += 1

    # ---- self-check: every .bc came from the .c we intended -----------------
    # The 3c6m.63 defect was invisible precisely because the FILE NAME was right
    # and only the BODY was wrong, so the check has to read `source_filename`.
    wrong_body = []
    for stem, c in sorted(planned.items()):
        p = bc / f"{stem}.bc"
        if not p.exists():
            continue
        sf = _source_filename(a.llvm_dis, p)
        if sf is None:
            wrong_body.append((stem, "<unreadable>", str(c)))
        elif pathlib.Path(sf).resolve() != c.resolve():
            wrong_body.append((stem, sf, str(c)))

    n_bc = len(list(bc.glob("*.bc")))
    say(f"\nbuilt {built} TUs -> {n_bc} .bc")
    if tolerated_fail:
        say(f"\nNOTE — {len(tolerated_fail)} TU(s) do not build under this flag set "
            f"and are KNOWN-ABSENT (none is a math.h census cell today):")
        for s in tolerated_fail:
            say(f"    {s:16s} {KNOWN_UNBUILDABLE[s]}")

    bad = False
    if unexpected_fail:
        bad = True
        print(f"\n!! {len(unexpected_fail)} UNEXPECTED BUILD FAILURE(S) — the census "
              f"would report these as a fake 'unknown callee' or `no-body`:",
              file=sys.stderr)
        for stem, path, nerr, lines in unexpected_fail:
            print(f"    {stem:16s} {nerr} error(s)  {path}", file=sys.stderr)
            for l in lines:
                print(f"        {l}", file=sys.stderr)
        print("   Add it to KNOWN_UNBUILDABLE with a reason, or fix the flags. Do "
              "NOT redirect the error away (bd tegx).", file=sys.stderr)
    if wrong_body:
        bad = True
        print(f"\n!! {len(wrong_body)} .bc CAME FROM THE WRONG SOURCE — this is bd "
              f"3c6m.63 recurring:", file=sys.stderr)
        for stem, got, want in wrong_body:
            print(f"    {stem}.bc  from {got}\n        expected {want}", file=sys.stderr)
    if a.expect_bc is not None and n_bc != a.expect_bc:
        bad = True
        print(f"\n!! CORPUS SIZE {n_bc} != expected {a.expect_bc}. A corpus of the "
              f"wrong size measures a different program; re-derive the expected "
              f"count before overriding it.", file=sys.stderr)

    if bad:
        return 1
    say("\nOK — every .bc traced back to the source openlibm builds.")
    say("Next: run the defmap preflight (README 'Reproduce'), then full_census.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
