#!/usr/bin/env python3
"""keepset_vendor_check.py — the bd tkju prevention gate (Rule 18).

WHAT IT ENFORCES.  A Rule-18 HARDWARE KEEP has **no injectable body**: at the
ship floor (`clang -O1`, builtins on) the call folds to an `@llvm.<fn>`
intrinsic *before codegen*, and `cq-lowering` rewrites that to
`cq_template_<fn>_<W>`.  An e2e slice that vendors openlibm's SOFTWARE body for
such a function therefore models a program the ship floor never compiles: it
over-tests (a bit-twiddle ladder under quantum control) while under-testing the
actual keep route.  That is a FAITHFULNESS defect, not a miscompile — the
vendored C is correct and the pass lowers it correctly; what it corrupts is what
the slice PROVES.  bd 3c6m.60 fixed this class at the CENSUS level; bd tkju
fixed the 52 slices that still carried it; this gate stops the copy-paste from
reintroducing it silently.

WHAT IT DOES **NOT** WITNESS (read before quoting it — these limits were
established by an adversarial round that succeeded in fooling earlier drafts):
  * It does not re-measure the keep-set.  Rule 18's keep test is empirical
    (`clang -O1` on `T f(T x){return <fn>(x);}` must fold to `@llvm.<fn>`, AND
    Bennett.jl must ship a reversible sequence for that construct).  This gate
    only checks that no slice vendors a body for a function the PASS already
    curates as a keep.
  * It matches DEFINITIONS by name.  A software keep body vendored under a name
    outside PREFIXES x stem x width (`bit_abs`, `vendor_fabs`, `myfloor`, or the
    bare `double fabs(double)`) slips through.  The bare name is deliberately
    NOT matched: no `-fno-builtin-*` reaches these slices, so at -O1 the call
    folds to the intrinsic and the vendored body goes dead — unfaithful clutter
    rather than an exercised ladder — and matching it risked false positives
    that were not proven safe.
  * These DEFINITION SHAPES defeat the scanner and are known misses: a K&R
    definition (`double olm_trunc(x) double x; {`), the `#ifdef __STDC__`
    preprocessor-split declarator fdlibm uses, and a macro-generated name
    (`#define OLM(n) olm_##n` … `OLM(fabs)`).  The corpus uses none of them
    today.
  * It says nothing about whether a slice's *call sites* are spelled correctly —
    a slice may call a genuine library function that happens to share a stem,
    and nothing here enforces the `__builtin_` spelling.

The keep list is DERIVED from the pass itself (both curated-intrinsic
predicates in `ir-pass/src/IntrinsicLowering.cpp`) rather than duplicated here,
so the gate cannot drift away from what the compiler actually curates.  Only
`case` labels that fall through to `return true` are harvested — an explicitly
DECLINING arm (`case Intrinsic::pow: return false;`) must not be read as a keep,
or the gate would flag a legitimate Rule-18 library injection.  If the parse
yields nothing the gate FAILS LOUDLY rather than silently passing — a checker
that quietly matches zero names is a checker that proves nothing.

Usage:  keepset_vendor_check.py [--root <repo-root>] [-q]
Exit 0 = clean, 1 = vendored keep body found, 2 = the gate could not run.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

# Intrinsic::<id> -> the C/math.h stem a vendored body would be named after.
# (minnum/maxnum carry the C99 spelling; fma and fmuladd share the `fma` stem —
# mirrors the intrinsicStem() mapping in IntrinsicLowering.cpp.)
ID_TO_STEM = {
    "minnum": "fmin",
    "maxnum": "fmax",
    "fmuladd": "fma",
}
# Naming conventions a vendored corpus body has actually appeared under.
# `__ieee754_` is the corpus's OWN name for several keeps (__ieee754_sqrt) and is
# cited by name in a dozen slice headers, so it must be here explicitly — the
# bare `__` prefix does not cover it.
PREFIXES = ("olm_", "soft_", "__ieee754_", "__", "_")
WIDTH_SUFFIXES = ("", "f", "l")

# Both curated-intrinsic predicates in the pass.  isCuratedFpIntrinsic carries the
# same-width fp family; isCrossWidthLibmIntrinsic carries lrint/llrint, which are
# Rule-18 keeps too (CLAUDE.md lists 14 stems: these 12 + those 2) and would
# otherwise be invisible here — one letter from lround/llround, which are NOT
# keeps and are correctly vendored as source in this very corpus.
CURATED_FNS = ("isCuratedFpIntrinsic", "isCrossWidthLibmIntrinsic")


def _accepting_cases(body: str) -> list[str]:
    """Case labels that fall through to `return true` — never a declining arm."""
    ids, pending = [], []
    for tok in re.finditer(r"case\s+Intrinsic::(\w+)\s*:|return\s+(true|false)\s*;", body):
        if tok.group(1):
            pending.append(tok.group(1))
        else:
            if tok.group(2) == "true":
                ids.extend(pending)
            pending = []
    return ids


def keep_stems(root: pathlib.Path) -> set[str]:
    """Parse the pass's curated-intrinsic switches into math.h stems."""
    src = root / "ir-pass" / "src" / "IntrinsicLowering.cpp"
    if not src.is_file():
        sys.stderr.write(f"keepset_vendor_check: cannot read {src}\n")
        sys.exit(2)
    text = src.read_text()
    ids: list[str] = []
    for fn in CURATED_FNS:
        m = re.search(r"bool\s+" + fn + r"\s*\([^)]*\)\s*\{(.*?)\n\}", text, re.S)
        if not m:
            sys.stderr.write(
                f"keepset_vendor_check: could not locate {fn}() in {src} — "
                "the gate cannot derive the keep-set and refuses to guess.\n")
            sys.exit(2)
        found = _accepting_cases(m.group(1))
        if not found:
            sys.stderr.write(
                f"keepset_vendor_check: {fn}() parsed to ZERO accepting ids — "
                "refusing to pass vacuously.\n")
            sys.exit(2)
        ids.extend(found)
    return {ID_TO_STEM.get(i, i) for i in ids}


CHAR_LIT = re.compile(r"'(?:\\.|[^'\\\n])'")


def strip_comments_and_strings(text: str) -> str:
    """Blank out //, /* */, "..." and well-formed char literals so prose can
    never trip the gate.

    `'` is consumed ONLY when it opens a well-formed char literal.  Treating
    every apostrophe as a delimiter desynchronises on ordinary English inside a
    #error / #if-0 block ("don't vendor keeps") and silently blanks the rest of
    the file — an adversarial probe used exactly that to hide an `olm_sqrt`
    body from an earlier draft of this gate.
    """
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r"[^\n]", " ", text[i:j]))
            i = j
        elif c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == "\n":  # unterminated — do not swallow the file
                    break
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
            out.append(re.sub(r"[^\n]", " ", text[i:j]))
            i = j
        elif c == "'":
            m = CHAR_LIT.match(text, i)
            if m:
                out.append(" " * (m.end() - i))
                i = m.end()
            else:
                out.append(" ")  # a bare apostrophe: drop it, consume nothing else
                i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def vendored_names(stems: set[str]) -> set[str]:
    names = set()
    for stem in stems:
        for w in WIDTH_SUFFIXES:
            for p in PREFIXES:
                names.add(p + stem + w)
    return names


def scan(path: pathlib.Path, names: set[str]) -> list[tuple[int, str]]:
    """Return [(line, name)] for every FUNCTION DEFINITION of a keep name."""
    text = strip_comments_and_strings(path.read_text())
    hits = []
    for m in re.finditer(r"\b([A-Za-z_]\w*)\s*\(", text):
        name = m.group(1)
        if name not in names:
            continue
        # a definition = balanced arg list, then optional ws, then '{'
        i, depth = m.end() - 1, 0
        while i < len(text):
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        j = i + 1
        while j < len(text) and text[j] in " \t\n\r":
            j += 1
        if j < len(text) and text[j] == "{":
            hits.append((text.count("\n", 0, m.start()) + 1, name))
    return hits


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=None)
    ap.add_argument("-q", "--quiet", action="store_true")
    args = ap.parse_args()
    root = pathlib.Path(args.root) if args.root else pathlib.Path(__file__).resolve().parent.parent
    stems = keep_stems(root)
    names = vendored_names(stems)
    # Scan every C source/header the e2e slices can pull in, recursively, and
    # include the parked `*.c.DECLINED` convention — a body hidden in a header
    # or behind a renamed extension is still preprocessed into the slice, and an
    # adversarial probe defeated an earlier `tests/e2e/*.c`-only glob that way.
    e2e = root / "tests" / "e2e"
    srcs = sorted({p for pat in ("**/*.c", "**/*.h", "**/*.c.*", "**/*.h.*")
                   for p in e2e.glob(pat) if p.is_file()})
    if not srcs:
        sys.stderr.write(f"keepset_vendor_check: no sources under {e2e}\n")
        return 2
    bad = 0
    for p in srcs:
        for line, name in scan(p, names):
            bad += 1
            sys.stderr.write(
                f"{p.relative_to(root)}:{line}: error: vendored SOFTWARE body "
                f"`{name}` for the Rule-18 HARDWARE KEEP `{name.lstrip('_').split('_')[-1]}`.\n"
                f"    A keep has no injectable body: spell the call "
                f"`__builtin_<fn>` and delete this body (bd tkju).\n")
    if bad:
        sys.stderr.write(
            f"keepset_vendor_check: FAIL — {bad} vendored keep body/bodies in "
            f"{len(srcs)} e2e source(s). Keep-set derived from "
            f"IntrinsicLowering.cpp::{'/'.join(CURATED_FNS)}: "
            f"{' '.join(sorted(stems))}\n")
        return 1
    if not args.quiet:
        print(f"keepset_vendor_check: {len(srcs)} e2e source(s), "
              f"{len(stems)} curated keep stem(s), 0 vendored keep bodies")
    return 0


if __name__ == "__main__":
    sys.exit(main())
