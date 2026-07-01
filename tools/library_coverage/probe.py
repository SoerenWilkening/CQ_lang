#!/usr/bin/env python3
"""math.h quantum-coverage probe harness — the CQ language demonstrator.

For every function declared in <math.h>, generate a minimal program that taints
the inputs through `cq_theta` and sinks the result through `cq_measure`, then run
the full CQ pipeline (clang -O1 -> opt cq-lowering -> link -> run) on every
applicable classical/quantum (C/Q) argument *mixture*. Record, per cell:

  * did stage-1 (clang -O1) build the tainted IR?           (else: cannot SOURCE the type)
  * did stage-2 (opt cq-lowering) accept or loud-DECLINE?   (capture the diagnostic kMsg)
  * did stage-3 link?                                       (else: template body missing)
  * did stage-4 run, and does the trace match a GOLDEN?     (verified vs accepted)

A function counts as **Covered (verified)** only when *every* applicable C/Q
mixture lowers, links, runs, AND matches a committed golden trace. A loud decline
is a *correct* (just uncovered) outcome — never papered over to inflate the badge.
This is the Prime Directive: over-accepting is the one unforgivable silent
miscompile; this harness measures verified coverage, not exit-zero.

Single source of truth: `results.json`. The markdown table (COVERAGE.md) and the
README badge are both rendered from it — never hand-maintained (no doc drift).

Usage:
  python3 tools/math_coverage/probe.py run        # probe everything, write results + render
  python3 tools/math_coverage/probe.py render     # re-render table/README from results.json
  python3 tools/math_coverage/probe.py run --filter sin,pow,sqrt
"""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
LLVM = Path("/usr/local/opt/llvm@19/bin")
CLANG = LLVM / "clang"
OPT = LLVM / "opt"
PASS = ROOT / "build/ir-pass/libCQPass.so"
TPL = ROOT / "build/runtime/libcq_templates.a"
RT = ROOT / "build/runtime/libcq_runtime.a"
INC = ROOT / "include"
RESULTS = HERE / "results.json"
COVERAGE_MD = HERE / "COVERAGE.md"
COVERAGE_DIR = HERE / "coverage"
GOLDENS = HERE / "goldens"
README = ROOT / "README.md"
TIMEOUT = 40

# ---------------------------------------------------------------------------
# The authoritative <math.h> spec.  EDIT THIS LIST to change what "all of
# math.h" means.  Each base entry expands into its real-floating variants
# (f / (double) / l) unless `variants` overrides it.
#
# arg/ret kinds:  "fp"  real-floating (expands per variant: float|double|long double)
#                 "int" / "long"            taintable integer
#                 "fp*" / "int*"            by-ref pointer out-param (NOT value-taintable)
#                 "str"                     const char* (NOT taintable)
# flags:  errno   sets errno (clang -O1 may keep it a direct call as an errno fence)
#         byref   writes a second result through a pointer (needs 7.5 Shadow routing)
#         macro   a <math.h> macro, not a real call (expands to builtins/bitops)
# ---------------------------------------------------------------------------
def B(base, cat, args, ret="fp", flags=(), variants=("f", "", "l")):
    return dict(base=base, cat=cat, args=list(args), ret=ret,
                flags=set(flags), variants=list(variants))

MATHH_SPEC = [
    # --- trigonometric ---
    B("cos", "trig", ["fp"], flags=("errno",)),
    B("sin", "trig", ["fp"], flags=("errno",)),
    B("tan", "trig", ["fp"], flags=("errno",)),
    B("acos", "trig", ["fp"], flags=("errno",)),
    B("asin", "trig", ["fp"], flags=("errno",)),
    B("atan", "trig", ["fp"]),
    B("atan2", "trig", ["fp", "fp"], flags=("errno",)),
    # --- hyperbolic ---
    B("cosh", "hyperbolic", ["fp"], flags=("errno",)),
    B("sinh", "hyperbolic", ["fp"], flags=("errno",)),
    B("tanh", "hyperbolic", ["fp"]),
    B("acosh", "hyperbolic", ["fp"], flags=("errno",)),
    B("asinh", "hyperbolic", ["fp"]),
    B("atanh", "hyperbolic", ["fp"], flags=("errno",)),
    # --- exponential / logarithmic ---
    B("exp", "exp_log", ["fp"], flags=("errno",)),
    B("exp2", "exp_log", ["fp"], flags=("errno",)),
    B("expm1", "exp_log", ["fp"], flags=("errno",)),
    B("log", "exp_log", ["fp"], flags=("errno",)),
    B("log10", "exp_log", ["fp"], flags=("errno",)),
    B("log2", "exp_log", ["fp"], flags=("errno",)),
    B("log1p", "exp_log", ["fp"], flags=("errno",)),
    B("logb", "exp_log", ["fp"]),
    B("ilogb", "exp_log", ["fp"], ret="int"),
    B("ldexp", "exp_log", ["fp", "int"]),
    B("scalbn", "exp_log", ["fp", "int"]),
    B("scalbln", "exp_log", ["fp", "long"]),
    B("frexp", "exp_log", ["fp", "int*"], flags=("byref",)),
    B("modf", "exp_log", ["fp", "fp*"], flags=("byref",)),
    # --- power ---
    B("pow", "power", ["fp", "fp"], flags=("errno",)),
    B("sqrt", "power", ["fp"], flags=("errno",)),
    B("cbrt", "power", ["fp"]),
    B("hypot", "power", ["fp", "fp"]),
    # --- error / gamma ---
    B("erf", "error_gamma", ["fp"]),
    B("erfc", "error_gamma", ["fp"], flags=("errno",)),
    B("tgamma", "error_gamma", ["fp"], flags=("errno",)),
    B("lgamma", "error_gamma", ["fp"], flags=("errno",)),
    # --- nearest integer ---
    B("ceil", "nearest_int", ["fp"]),
    B("floor", "nearest_int", ["fp"]),
    B("trunc", "nearest_int", ["fp"]),
    B("round", "nearest_int", ["fp"]),
    B("nearbyint", "nearest_int", ["fp"]),
    B("rint", "nearest_int", ["fp"]),
    B("lrint", "nearest_int", ["fp"], ret="long"),
    B("llrint", "nearest_int", ["fp"], ret="long"),
    B("lround", "nearest_int", ["fp"], ret="long"),
    B("llround", "nearest_int", ["fp"], ret="long"),
    # --- remainder ---
    B("fmod", "remainder", ["fp", "fp"], flags=("errno",)),
    B("remainder", "remainder", ["fp", "fp"], flags=("errno",)),
    B("remquo", "remainder", ["fp", "fp", "int*"], flags=("byref",)),
    # --- manipulation ---
    B("copysign", "manipulation", ["fp", "fp"]),
    B("nextafter", "manipulation", ["fp", "fp"], flags=("errno",)),
    B("fdim", "manipulation", ["fp", "fp"], flags=("errno",)),
    B("fmax", "manipulation", ["fp", "fp"]),
    B("fmin", "manipulation", ["fp", "fp"]),
    B("fma", "manipulation", ["fp", "fp", "fp"]),
    B("nan", "manipulation", ["str"]),
    # --- classification / comparison macros ---
    B("fpclassify", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",)),
    B("isfinite", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",)),
    B("isinf", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",)),
    B("isnan", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",)),
    B("isnormal", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",)),
    B("signbit", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",)),
    B("isgreater", "classify_macro", ["fp", "fp"], ret="int", flags=("macro",), variants=("",)),
    B("isless", "classify_macro", ["fp", "fp"], ret="int", flags=("macro",), variants=("",)),
    B("isunordered", "classify_macro", ["fp", "fp"], ret="int", flags=("macro",), variants=("",)),
]

# ---------------------------------------------------------------------------
# Library registry. ADD A LIBRARY by appending a Lib(...) with its own SPEC
# list (built the same way as MATHH_SPEC). Everything else — probing, the
# per-library goldens/<slug>/ dir, the detail page, the README badge row —
# generalizes for free.
# ---------------------------------------------------------------------------
def Lib(name, include, slug, blurb, fit, spec):
    return dict(name=name, include=include, slug=slug, blurb=blurb, fit=fit, spec=spec)

# A STATIC spec entry: a function the prober cannot meaningfully run (non-measurable
# return — struct/pointer/void — or a buffer/string operation), classified by a
# STRUCTURAL fact about its signature. This is honest: it never claims the function
# compiles (the dangerous direction); it records *why it cannot yet*, with the gap named.
# status ∈ {needs-shadow, needs-aggregate, by-design}; the first two are fixable future
# work (the QRAM/Shadow memory model, aggregate decomposition), by-design is "no quantum
# meaning" (noreturn / nondeterministic / callback registration).
def St(name, cat, sig, status, reason):
    return dict(static=True, name=name, cat=cat, sig=sig, status=status, reason=reason)

STDLIB_SPEC = [
    # PROBED (empirical): the integer-abs island -> @llvm.abs.iN -> curated reversible
    # template (the integer analog of math.h's fabs).
    B("abs", "integer", ["int"], ret="int", variants=("",)),
    B("labs", "integer", ["long"], ret="long", variants=("",)),
    B("llabs", "integer", ["llong"], ret="llong", variants=("",)),
    St("div", "integer", "div_t div(int, int)", "needs-aggregate",
       "returns a struct (div_t) — needs aggregate (NTuple/extractvalue) decomposition"),
    St("ldiv", "integer", "ldiv_t ldiv(long, long)", "needs-aggregate",
       "returns a struct (ldiv_t) — needs aggregate decomposition"),
    St("lldiv", "integer", "lldiv_t lldiv(long long, long long)", "needs-aggregate",
       "returns a struct (lldiv_t) — needs aggregate decomposition"),
    # string -> number conversion: the meaningful input is a char* buffer (Shadow territory)
    St("atof", "conversion", "double atof(const char *)", "needs-shadow",
       "string input (const char*) — needs the Shadow memory model"),
    St("atoi", "conversion", "int atoi(const char *)", "needs-shadow", "string input — needs Shadow"),
    St("atol", "conversion", "long atol(const char *)", "needs-shadow", "string input — needs Shadow"),
    St("atoll", "conversion", "long long atoll(const char *)", "needs-shadow", "string input — needs Shadow"),
    St("strtod", "conversion", "double strtod(const char *, char **)", "needs-shadow",
       "string input + char** out-param — needs Shadow"),
    St("strtof", "conversion", "float strtof(const char *, char **)", "needs-shadow",
       "string input + char** out-param — needs Shadow"),
    St("strtold", "conversion", "long double strtold(const char *, char **)", "needs-shadow",
       "string input; long double result (also needs f80/f128) — needs Shadow"),
    St("strtol", "conversion", "long strtol(const char *, char **, int)", "needs-shadow",
       "string parser; meaningful input is the char* (needs Shadow) — only the int base is a scalar"),
    St("strtoll", "conversion", "long long strtoll(const char *, char **, int)", "needs-shadow",
       "string parser — needs Shadow"),
    St("strtoul", "conversion", "unsigned long strtoul(const char *, char **, int)", "needs-shadow",
       "string parser — needs Shadow"),
    St("strtoull", "conversion", "unsigned long long strtoull(const char *, char **, int)", "needs-shadow",
       "string parser — needs Shadow"),
    # pseudo-random
    St("rand", "random", "int rand(void)", "by-design",
       "no input and nondeterministic — not a reversible function"),
    St("srand", "random", "void srand(unsigned)", "by-design",
       "void; seeds global RNG state (stateful) — no quantum meaning"),
    # memory management -> the Shadow memory model
    St("malloc", "memory", "void *malloc(size_t)", "needs-shadow",
       "returns a pointer — needs the Shadow memory model"),
    St("calloc", "memory", "void *calloc(size_t, size_t)", "needs-shadow", "returns a pointer — needs Shadow"),
    St("realloc", "memory", "void *realloc(void *, size_t)", "needs-shadow", "pointer in/out — needs Shadow"),
    St("aligned_alloc", "memory", "void *aligned_alloc(size_t, size_t)", "needs-shadow",
       "returns a pointer — needs Shadow"),
    St("free", "memory", "void free(void *)", "needs-shadow",
       "void; frees a pointer — part of the Shadow memory model"),
    # environment / process control
    St("getenv", "environment", "char *getenv(const char *)", "needs-shadow",
       "string key -> string value (pointers) — needs Shadow"),
    St("system", "environment", "int system(const char *)", "needs-shadow",
       "string command (pointer) — needs Shadow"),
    St("abort", "environment", "void abort(void)", "by-design", "noreturn control; no input, no result"),
    St("exit", "environment", "void exit(int)", "by-design",
       "noreturn; terminates the program — no measurable quantum result"),
    St("_Exit", "environment", "void _Exit(int)", "by-design", "noreturn — no measurable result"),
    St("quick_exit", "environment", "void quick_exit(int)", "by-design", "noreturn — no measurable result"),
    St("atexit", "environment", "int atexit(void (*)(void))", "by-design",
       "registers a callback (function pointer) — no taintable data"),
    St("at_quick_exit", "environment", "int at_quick_exit(void (*)(void))", "by-design",
       "registers a callback — no taintable data"),
    # search / sort -> array/pointer operations
    St("bsearch", "search_sort", "void *bsearch(const void *, const void *, size_t, size_t, ...)",
       "needs-shadow", "array search over pointers; returns a pointer — needs Shadow"),
    St("qsort", "search_sort", "void qsort(void *, size_t, size_t, ...)", "needs-shadow",
       "in-place array sort over pointers — needs Shadow"),
    # multibyte / wide character
    St("mblen", "multibyte", "int mblen(const char *, size_t)", "needs-shadow", "string/buffer op — needs Shadow"),
    St("mbtowc", "multibyte", "int mbtowc(wchar_t *, const char *, size_t)", "needs-shadow", "buffer op — needs Shadow"),
    St("wctomb", "multibyte", "int wctomb(char *, wchar_t)", "needs-shadow", "buffer op — needs Shadow"),
    St("mbstowcs", "multibyte", "size_t mbstowcs(wchar_t *, const char *, size_t)", "needs-shadow", "buffer op — needs Shadow"),
    St("wcstombs", "multibyte", "size_t wcstombs(char *, const char *, size_t)", "needs-shadow", "buffer op — needs Shadow"),
]

LIBRARIES = [
    Lib("math.h", "math.h", "mathh",
        "The C standard math library — the flagship demonstrator: pure, mostly-total "
        "numerical functions with clean scalar in/out, ideal for taint-driven reversible lowering.",
        "good-early", MATHH_SPEC),
    Lib("stdlib.h", "stdlib.h", "stdlib",
        "The C general-utilities header, full surface. Only the integer-`abs` island "
        "(`abs`/`labs`/`llabs`, the integer analog of `fabs`) lowers and golden-verifies today; "
        "the rest is classified by structural disposition — `div_t` struct returns need aggregate "
        "decomposition, the alloc/string/buffer families need the Shadow memory model, and the "
        "noreturn/RNG/callback functions have no quantum meaning by design.",
        "mixed", STDLIB_SPEC),
]

# C type for an arg/ret kind given the real-floating width of this variant.
FP_TYPE = {"f": "float", "": "double", "l": "long double"}

def c_type(kind, fpty):
    return {"fp": fpty, "int": "int", "long": "long", "llong": "long long",
            "fp*": fpty + " *", "int*": "int *", "str": "const char *"}[kind]

# A position is "mixable" (we attempt to taint it) iff it is a scalar value arg.
# long double is mixable-in-principle but has no cq_theta yet -> stage-1 fails ->
# classified as a future-gap reason, exactly as intended.
def is_mixable(kind):
    return kind in ("fp", "int", "long", "llong")

def sample_literal(kind, fpty):
    return {"fp": "1.5", "int": "2", "long": "2L", "llong": "2LL",
            "fp*": None, "int*": None, "str": '""'}[kind]

# ---------------------------------------------------------------------------
# Variant + mixture expansion
# ---------------------------------------------------------------------------
def expand_variants(spec):
    """Yield (name, args_c, ret_c, flags, cat, base, variant_suffix) per real-type variant."""
    for suf in spec["variants"]:
        fpty = FP_TYPE[suf]
        name = spec["base"] + suf
        args_c = [c_type(a, fpty) for a in spec["args"]]
        ret_c = c_type(spec["ret"], fpty) if spec["ret"] == "fp" else \
            {"int": "int", "long": "long", "llong": "long long"}[spec["ret"]]
        yield dict(name=name, args_kind=spec["args"], args_c=args_c, ret_c=ret_c,
                   flags=spec["flags"], cat=spec["cat"], base=spec["base"], suf=suf)

def mixtures(args_kind):
    """All non-all-classical H/L assignments over mixable positions (>=1 H).
    Returns list of tuples like ('H',) or ('H','L'); non-mixable positions omitted."""
    pos = [i for i, k in enumerate(args_kind) if is_mixable(k)]
    if not pos:
        return []  # no taintable input -> no quantum mixture exists
    out = []
    for mask in range(1, 1 << len(pos)):  # skip 0 (all classical)
        combo = {}
        for bit, p in enumerate(pos):
            combo[p] = "H" if (mask >> bit) & 1 else "L"
        out.append(combo)
    return out

def mixture_label(args_kind, combo):
    """Compact label e.g. 'H', 'HL', 'QQ' (HH shown as QQ for the both-quantum form)."""
    pos = [i for i in range(len(args_kind)) if i in combo]
    s = "".join(combo[i] for i in pos)
    if len(s) >= 2 and set(s) == {"H"}:
        return "QQ" if len(s) == 2 else "Q" * len(s)
    return s if s else "-"

# ---------------------------------------------------------------------------
# Program generation
# ---------------------------------------------------------------------------
def gen_program(variant, combo, include):
    name = variant["name"]
    args_kind = variant["args_kind"]
    args_c = variant["args_c"]
    ret_c = variant["ret_c"]
    lines = [f"#include <{include}>", "", f"{ret_c} probe(void) {{"]
    call_args = []
    byref_decls = []
    byref_cells = []  # (index, pointee C type) — the SECOND results to measure
    angle = 0.5
    for i, (k, ct) in enumerate(zip(args_kind, args_c)):
        if k in ("fp*", "int*"):
            # Pointee C type per VARIANT (int* -> int; fp* -> float/double/long
            # double), taken from args_c so f32/f80 spellings pass the right
            # pointer type (a hardcoded `double` mis-typed modff/frexpl).
            pointee = ct.rsplit("*", 1)[0].strip()
            byref_decls.append(f"    {pointee} _br{i} = 0;")
            byref_cells.append((i, pointee))
            call_args.append(f"&_br{i}")
        elif k == "str":
            call_args.append('""')
        else:
            lines.append(f"    {ct} a{i} = {sample_literal(k, ct)};")
            if combo.get(i) == "H":
                lines.append(f"    a{i} = cq_theta(a{i}, {angle:.2f});")
                angle += 0.1
            call_args.append(f"a{i}")
    lines.extend(byref_decls)
    lines.append(f"    {ret_c} r = {name}({', '.join(call_args)});")
    # bd g387: measure each by-ref out-param (the SECOND result) in its NATIVE
    # type, so a by-ref fn is COVERED only when its secondary producer is actually
    # exercised — never ignored (an unread out-param would inflate coverage to the
    # primary result alone; Prime Directive, honest coverage). Native type also
    # sidesteps the orthogonal f80<->int cross-domain cast (bd 3c6m.5).
    for i, pointee in byref_cells:
        lines.append(f"    volatile {pointee} _s{i} = cq_measure(_br{i});")
        lines.append(f"    (void) _s{i};")
    lines.append("    return cq_measure(r);")
    lines.append("}")
    lines.append("int main(void) {")
    lines.append(f"    volatile {ret_c} s = probe();")
    lines.append("    (void) s;")
    lines.append("    return 0;")
    lines.append("}")
    return "\n".join(lines) + "\n"

# ---------------------------------------------------------------------------
# Pipeline runner
# ---------------------------------------------------------------------------
def _run(cmd, **kw):
    try:
        return subprocess.run([str(c) for c in cmd], capture_output=True,
                              text=True, timeout=TIMEOUT, **kw)
    except subprocess.TimeoutExpired:
        class R:  # noqa
            returncode = 124
            stdout = ""
            stderr = "TIMEOUT"
        return R()

def first_error(text):
    for ln in (text or "").splitlines():
        s = ln.strip()
        if "error:" in s:
            return s
    return (text or "").strip().splitlines()[0] if (text or "").strip() else ""

def classify(stage, variant, combo, stderr):
    """Map a failure to a short, stable reason category + the raw diagnostic."""
    raw = first_error(stderr)
    low = (stderr or "").lower()
    if stage == "stage1":
        if "long double" in " ".join(variant["args_c"]) or variant["ret_c"] == "long double":
            return ("needs long double (f80/f128) source — future gap", raw)
        if "cq_measure" in low:
            return ("result type not sinkable yet", raw)
        if "cq_theta" in low or "_generic" in low:
            return ("cannot source this input type yet", raw)
        return ("clang -O1 build failed", raw)
    if stage == "stage2":
        byref = "byref" in variant["flags"]
        if "under quantum control" in low:
            return ("tainted-control limitation", raw)
        if "angle" in low or "rotation" in low:
            return ("math-result-as-angle hazard", raw)
        if byref:
            return ("by-ref out-param → needs 7.5 Shadow routing", raw)
        if "unknown callee" in low or ("unknown" in low and "call" in low):
            return ("needs curated libm entry + Phase 9 template", raw)
        if "no template for opcode" in low:
            return ("needs opcode/template support for this expansion", raw)
        return ("declines (opt cq-lowering)", raw)
    if stage == "stage3":
        if "undefined" in low or "symbol" in low:
            return ("template body missing (needs Phase 9 template)", raw)
        return ("link failed", raw)
    if stage == "stage4":
        return ("runtime crash", raw)
    return ("unknown", raw)

def probe_cell(variant, combo, include, golden_dir, keep=False):
    src = gen_program(variant, combo, include)
    name = variant["name"]
    lbl = mixture_label(variant["args_kind"], combo)
    tmp = Path(tempfile.mkdtemp(prefix=f"cqlib_{name}_{lbl}_"))
    res = {"status": "?", "reason": "", "raw": "", "trace": ""}
    try:
        cpath = tmp / "probe.c"
        cpath.write_text(src)
        s1 = _run([CLANG, "-I", INC, "-include", "CQ.h", "-O1", "-emit-llvm",
                   "-S", cpath, "-o", tmp / "s1.ll"])
        if s1.returncode != 0:
            res["status"] = "blocked"
            res["reason"], res["raw"] = classify("stage1", variant, combo, s1.stderr)
            return res
        s2 = _run([OPT, "-load-pass-plugin", PASS, "-passes=cq-lowering", "-S",
                   tmp / "s1.ll", "-o", tmp / "s2.ll"])
        if s2.returncode != 0:
            res["status"] = "declined"
            res["reason"], res["raw"] = classify("stage2", variant, combo, s2.stderr)
            return res
        s3 = _run([CLANG, tmp / "s2.ll", TPL, RT, "-o", tmp / "exe"])
        if s3.returncode != 0:
            res["status"] = "linkfail"
            res["reason"], res["raw"] = classify("stage3", variant, combo, s3.stderr)
            return res
        s4 = _run([tmp / "exe"])
        if s4.returncode != 0:
            res["status"] = "runfail"
            res["reason"], res["raw"] = classify("stage4", variant, combo, s4.stderr)
            return res
        res["trace"] = s4.stdout
        golden = golden_dir / f"{name}__{lbl}.log"
        if golden.exists():
            res["status"] = "verified" if golden.read_text() == s4.stdout else "trace-mismatch"
            if res["status"] == "trace-mismatch":
                res["reason"] = "trace differs from committed golden"
        else:
            res["status"] = "accepted"
            res["reason"] = "lowers+links+runs; golden not yet committed"
        return res
    finally:
        if not keep:
            for p in sorted(tmp.rglob("*"), reverse=True):
                p.unlink(missing_ok=True) if p.is_file() else p.rmdir()
            tmp.rmdir()

# Per-variant rollup: Covered only if ALL applicable mixtures verified.
def rollup(cells):
    if not cells:
        return "no-taintable-input"
    sts = [c["res"]["status"] for c in cells]
    if all(s == "verified" for s in sts):
        return "verified"
    if all(s in ("verified", "accepted") for s in sts):
        return "accepted"
    if any(s in ("verified", "accepted") for s in sts):
        return "partial"
    return cells[0]["res"]["status"]

# ---------------------------------------------------------------------------
# Run + render  (multi-library)
# ---------------------------------------------------------------------------
def static_row(spec):
    """A row for a non-probed function, classified by a structural signature fact."""
    return {
        "name": spec["name"], "base": spec["name"], "cat": spec["cat"], "suf": "",
        "ret": "", "sig": spec["sig"], "flags": [],
        "cells": [{"mixture": "—", "res": {"status": spec["status"],
                                           "reason": spec["reason"], "raw": "", "trace": ""}}],
        "rollup": spec["status"],
    }

def probe_library(lib, filter_names=None, keep=False):
    gdir = GOLDENS / lib["slug"]
    gdir.mkdir(parents=True, exist_ok=True)
    rows = []
    for spec in lib["spec"]:
        if spec.get("static"):
            if not filter_names or spec["name"] in filter_names:
                print(f"  [{lib['name']}] {spec['name']:14s} [—] ... {spec['status']} (static)")
                rows.append(static_row(spec))
            continue
        for variant in expand_variants(spec):
            base = variant["base"]
            if filter_names and base not in filter_names and variant["name"] not in filter_names:
                continue
            cells = []
            for combo in mixtures(variant["args_kind"]):
                lbl = mixture_label(variant["args_kind"], combo)
                print(f"  [{lib['name']}] {variant['name']:14s} [{lbl}] ...", end="", flush=True)
                r = probe_cell(variant, combo, lib["include"], gdir, keep=keep)
                print(f" {r['status']}")
                cells.append({"mixture": lbl, "res": r})
            rows.append({
                "name": variant["name"], "base": base, "cat": variant["cat"],
                "suf": variant["suf"], "ret": variant["ret_c"],
                "sig": f"{variant['ret_c']} {variant['name']}({', '.join(variant['args_c'])})",
                "flags": sorted(variant["flags"]),
                "cells": cells, "rollup": rollup(cells),
            })
    return rows

def run(lib_filter=None, filter_names=None, keep=False):
    for tool in (PASS, TPL, RT):
        if not tool.exists():
            sys.exit(f"missing build artifact: {tool}\n  run: cmake --build build")
    libs_out = []
    for lib in LIBRARIES:
        if lib_filter and lib["name"] not in lib_filter and lib["slug"] not in lib_filter:
            continue
        print(f"\n=== {lib['name']} ===")
        rows = probe_library(lib, filter_names=filter_names, keep=keep)
        meta = {k: lib[k] for k in ("name", "include", "slug", "blurb", "fit")}
        libs_out.append({**meta, "rows": rows})
    if filter_names:
        print("\n(--filter set: debug run; results.json NOT updated)")
        return
    if lib_filter and RESULTS.exists():  # keep libraries this run did not touch
        have = {l["slug"] for l in libs_out}
        for pl in json.loads(RESULTS.read_text()).get("libraries", []):
            if pl["slug"] not in have:
                libs_out.append(pl)
    libs_out.sort(key=lambda l: l["name"])
    data = {"libraries": libs_out, "generated_by": "tools/library_coverage/probe.py"}
    RESULTS.write_text(json.dumps(data, indent=2))
    print(f"\nwrote {RESULTS}")
    render(data)

EMOJI = {"verified": "✅", "accepted": "🟢", "partial": "🟠", "declined": "🟡",
         "blocked": "🟡", "linkfail": "🟡", "runfail": "⚠️", "trace-mismatch": "⚠️",
         "needs-shadow": "🟡", "needs-aggregate": "🟡",
         "no-taintable-input": "⛔", "by-design": "⛔"}

# Statuses that count as "cannot at all (by design)" — no quantum meaning, never fixable.
BY_DESIGN = ("no-taintable-input", "by-design")

def summarize(rows):
    total = len(rows)
    verified = sum(1 for r in rows if r["rollup"] == "verified")
    accepted = sum(1 for r in rows if r["rollup"] == "accepted")
    partial = sum(1 for r in rows if r["rollup"] == "partial")
    out_design = sum(1 for r in rows if r["rollup"] in BY_DESIGN)
    # "cannot at the moment" (fixable) = everything not verified/accepted/by-design
    not_yet = total - verified - accepted - out_design
    longdouble = sum(1 for r in rows if r["suf"] == "l" and r["rollup"] == "blocked")
    compiles = verified + accepted  # lowers + links + runs (golden-verified or pending)
    pct_verified = (100.0 * verified / total) if total else 0.0
    pct_compiles = (100.0 * compiles / total) if total else 0.0
    return dict(total=total, verified=verified, accepted=accepted, partial=partial,
                compiles=compiles, not_yet=not_yet, out_design=out_design,
                longdouble=longdouble, pct_verified=pct_verified, pct_compiles=pct_compiles)

def bucket_table(s):
    return [
        "| Bucket | Count | Meaning |",
        "|---|---|---|",
        f"| ✅ Verified | {s['verified']} | lowers + links + runs + matches a committed golden trace |",
        f"| 🟢 Compiles (golden pending) | {s['accepted']} | lowers + links + runs; golden not yet blessed |",
        f"| 🟠 Partial | {s['partial']} | some C/Q mixtures compile, others decline (not fully covered) |",
        f"| 🟡 Cannot **at the moment** (fixable) | {s['not_yet']} | declines loudly today; future work"
        f" ({s['longdouble']} are `long double` → one f80/f128 width gap) |",
        f"| ⛔ Cannot **at all** (by design) | {s['out_design']} | no taintable quantum input |",
    ]

def category_tables(rows):
    out = ["Legend: ✅ verified · 🟢 accepted (golden pending) · 🟠 partial · "
           "🟡 not-yet (fixable) · ⚠️ error · ⛔ out-by-design", ""]
    by_cat = {}
    for r in rows:
        by_cat.setdefault(r["cat"], []).append(r)
    for cat in dict.fromkeys(r["cat"] for r in rows):
        out += [f"### {cat}", "",
                "| Function | Signature | Mixtures (C/Q) | Status | Reason |",
                "|---|---|---|---|---|"]
        for r in by_cat[cat]:
            cell_str = " ".join(f"{c['mixture']}:{EMOJI.get(c['res']['status'], '?')}"
                                for c in r["cells"]) or "—"
            reason = ""
            for c in r["cells"]:
                if c["res"]["status"] not in ("verified", "accepted"):
                    reason = c["res"]["reason"]
                    break
            if not reason and r["rollup"] == "no-taintable-input":
                reason = "no taintable scalar input"
            if not reason and r["rollup"] == "accepted":
                reason = "lowers+links+runs; golden pending"
            flag_str = (" `" + "` `".join(r["flags"]) + "`") if r["flags"] else ""
            out.append(f"| `{r['name']}`{flag_str} | `{r['sig']}` | {cell_str} | "
                       f"{EMOJI.get(r['rollup'], '?')} {r['rollup']} | {reason} |")
        out.append("")
    return out

def write_library_page(lib, s):
    lines = [f"# `{lib['name']}` quantum-coverage", "",
             "> Auto-generated by `tools/library_coverage/probe.py` — do not edit by hand.", "",
             lib["blurb"], "",
             f"**Compiles: {s['compiles']}/{s['total']} ({s['pct_compiles']:.1f}%)** — of which "
             f"**golden-verified: {s['verified']}/{s['total']} ({s['pct_verified']:.1f}%)**.", ""]
    lines += bucket_table(s)
    lines.append("")
    lines += category_tables(lib["rows"])
    (COVERAGE_DIR / f"{lib['slug']}.md").write_text("\n".join(lines))

def aggregate(per_lib):
    keys = ("total", "verified", "accepted", "partial", "compiles", "not_yet", "out_design")
    agg = {k: sum(s[k] for _, s in per_lib) for k in keys}
    agg["pct_verified"] = 100.0 * agg["verified"] / agg["total"] if agg["total"] else 0.0
    agg["pct_compiles"] = 100.0 * agg["compiles"] / agg["total"] if agg["total"] else 0.0
    return agg

def render(data=None):
    if data is None:
        data = json.loads(RESULTS.read_text())
    libs = data["libraries"]
    COVERAGE_DIR.mkdir(parents=True, exist_ok=True)
    per_lib = []
    for lib in libs:
        s = summarize(lib["rows"])
        per_lib.append((lib, s))
        write_library_page(lib, s)
    agg = aggregate(per_lib)
    write_index(per_lib, agg)
    update_readme(per_lib, agg)
    print(f"wrote {COVERAGE_MD} + {len(libs)} library page(s)")

def write_index(per_lib, agg):
    L = ["# Standard-library Quantum-Coverage — CQ demonstrators", "",
         "> Auto-generated by `tools/library_coverage/probe.py` — **do not edit by hand.**",
         "> Regenerate: `python3 tools/library_coverage/probe.py run`", "",
         f"**All libraries — compiles: {agg['compiles']}/{agg['total']} ({agg['pct_compiles']:.1f}%)** "
         f"· golden-verified: {agg['verified']}/{agg['total']} ({agg['pct_verified']:.1f}%).", "",
         "**Covered** = *every* applicable classical/quantum (C/Q) argument mixture lowers, links, "
         "runs, **and** matches a committed golden trace. A loud decline is a *correct* (uncovered) "
         "outcome — never papered over to inflate the number (Prime Directive). Exit-zero is not "
         "verification (Rule 2).", "",
         "| Library | Fit | Compiles | Verified | Cannot-yet | By-design | Detail |",
         "|---|---|---|---|---|---|---|"]
    for lib, s in per_lib:
        L.append(f"| `{lib['name']}` | {lib['fit']} | {s['compiles']}/{s['total']} ({s['pct_compiles']:.0f}%) "
                 f"| {s['verified']}/{s['total']} ({s['pct_verified']:.0f}%) | {s['not_yet']} | "
                 f"{s['out_design']} | [detail](coverage/{lib['slug']}.md) |")
    L += ["", "## Adding a library", "",
          "Append a `Lib(name, include, slug, blurb, fit, SPEC)` entry to `LIBRARIES` in "
          "`probe.py` (define its `SPEC` list like `MATHH_SPEC`), then run "
          "`python3 tools/library_coverage/probe.py run`. The summary table, the per-library "
          "detail page, the `goldens/<slug>/` dir, and the README badge all regenerate "
          "automatically. After an adversarial correctness audit (Rule 13), commit goldens with "
          "`python3 tools/library_coverage/probe.py bless --lib <name>`.", "",
          "Scoped-but-not-yet-wired candidate headers are in "
          "[`SCOPED-CANDIDATES.md`](SCOPED-CANDIDATES.md)."]
    COVERAGE_MD.write_text("\n".join(L))

README_START = "<!-- LIBRARY-COVERAGE:START -->"
README_END = "<!-- LIBRARY-COVERAGE:END -->"

def update_readme(per_lib, agg):
    if not README.exists():
        return
    L = [f"**Standard-library quantum-coverage — compiles: {agg['compiles']}/{agg['total']} "
         f"({agg['pct_compiles']:.1f}%)** &nbsp;·&nbsp; golden-verified: {agg['verified']}/{agg['total']} "
         f"({agg['pct_verified']:.1f}%).", "",
         "| Library | Compiles | Golden-verified | Cannot-yet (fixable) | By-design |",
         "|---|---|---|---|---|"]
    for lib, s in per_lib:
        L.append(f"| [`{lib['name']}`](tools/library_coverage/coverage/{lib['slug']}.md) "
                 f"| {s['compiles']}/{s['total']} ({s['pct_compiles']:.0f}%) "
                 f"| {s['verified']}/{s['total']} ({s['pct_verified']:.0f}%) | {s['not_yet']} | {s['out_design']} |")
    L += ["", "Full tables: [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) "
          "(regenerate: `python3 tools/library_coverage/probe.py run`)."]
    badge = README_START + "\n" + "\n".join(L) + "\n" + README_END
    txt = README.read_text()
    if README_START in txt and README_END in txt:
        README.write_text(txt.split(README_START)[0] + badge + txt.split(README_END)[1])
        print("updated README badge")

def bless(lib_filter=None):
    """Write goldens for every currently-'accepted' cell from its captured trace, then
    re-probe so they promote accepted -> verified.

    REVIEW GATE (procedural, non-negotiable): run only AFTER an adversarial correctness
    audit has cleared the accepted cells (Rule 13). A golden asserts the gate sequence is
    the correct reversible lowering. Bulk-blessing un-audited traces is the over-accept trap.
    """
    data = json.loads(RESULTS.read_text())
    n = 0
    for lib in data["libraries"]:
        if lib_filter and lib["name"] not in lib_filter and lib["slug"] not in lib_filter:
            continue
        gdir = GOLDENS / lib["slug"]
        gdir.mkdir(parents=True, exist_ok=True)
        for r in lib["rows"]:
            for c in r["cells"]:
                if c["res"]["status"] == "accepted" and c["res"].get("trace"):
                    (gdir / f"{r['name']}__{c['mixture']}.log").write_text(c["res"]["trace"])
                    n += 1
    print(f"blessed {n} goldens from captured traces; re-probing to confirm + promote...")
    run(lib_filter=lib_filter)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["run", "render", "bless"])
    ap.add_argument("--lib", default="", help="comma-separated library names/slugs (default: all)")
    ap.add_argument("--filter", default="", help="comma-separated base function names (debug; not persisted)")
    ap.add_argument("--keep", action="store_true", help="keep tmp dirs")
    a = ap.parse_args()
    libf = set(x.strip() for x in a.lib.split(",") if x.strip()) or None
    names = set(x.strip() for x in a.filter.split(",") if x.strip()) or None
    if a.cmd == "render":
        render()
    elif a.cmd == "bless":
        bless(lib_filter=libf)
    else:
        run(lib_filter=libf, filter_names=names, keep=a.keep)

if __name__ == "__main__":
    main()
