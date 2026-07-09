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
INJECTION_SUMMARY = HERE / "injection_summary.json"   # written by inject_census.py
TIMEOUT = 40

# The hardware-backed RECOGNITION keep-set (Rule 18; bd libm-coverage-source-injection-rule).
# These codegen to a HW instruction with no libcall, so they are lowered by NAME-recognition
# and have NO injectable body. This is a FIXED FLOOR — never injection progress.
HARDWARE_KEEP_SET = ("sqrt fabs copysign floor ceil trunc round rint nearbyint "
                     "fmin fmax fma lrint llrint")

def _injection_scoreboard():
    """Read the committed injection scoreboard (inject_census.py) if present."""
    try:
        return json.loads(INJECTION_SUMMARY.read_text())
    except Exception:
        return None

def two_scoreboard_lines(short=False, census_link="tools/library_coverage/INJECTION-CENSUS.md"):
    """The DISJOINT two-scoreboard note (owner, emphatic 2026-07-09; never a merged headline;
    bd libm-scoreboard-two-numbers). Emitted into the README badge, COVERAGE.md, and the
    math.h detail page — `census_link` is the INJECTION-CENSUS.md path RELATIVE to each."""
    inj = _injection_scoreboard()
    if inj is not None:
        n, m = inj["injection_compiles"], inj["injection_candidates"]
        injnum = (f"**{n}/{m}**" + (" (an honest floor)" if n == 0 else ""))
    else:
        injnum = "**see the source-injection census**"
    census = census_link
    head = ("> **Two DISJOINT coverage scoreboards (bd `libm-scoreboard-two-numbers`) — "
            "never merged.**")
    if short:
        return [f"{head} The `math.h` `Lowers`/`Verified` columns are the **recognition "
                f"floor** — fns that lower because `clang -O1` emits a hardware-backed "
                f"intrinsic the pass recognizes (`{HARDWARE_KEEP_SET}` + variants) — a *fixed "
                f"floor, not injection progress*. **Injection-covered** — genuine library "
                f"bodies compiled by source injection (Rule 18), the number the libm campaign "
                f"actually moves — is {injnum} of the `math.h` double surface "
                f"([source-injection census]({census})). The two sets are disjoint; a library "
                f"function that declines under injection stays declined (and ticketed), never "
                f"counted via recognition."]
    return [
        head, "",
        f"1. **Recognition-covered** — the hardware keep-set (`{HARDWARE_KEEP_SET}` + "
        "variants): functions that lower because `clang -O1` emits a hardware-backed intrinsic "
        "the pass recognizes (they have no injectable transcendental body, Rule 18). This is "
        "the **`Lowers`/`Verified` number in the table below** — a *fixed floor*, not injection "
        "progress.",
        f"2. **Injection-covered** — genuine library bodies compiled by **source injection** "
        f"(the real libm-campaign number): {injnum} of the `math.h` double surface "
        f"([source-injection census]({census})).",
        "",
        "The two sets are **disjoint** (a fn is counted in at most one). A library function "
        "that declines under injection stays declined — and is ticketed (bd `3c6m.9`) — until "
        "its *injected body* lowers; recognition is **never** a fallback for a hard injection. "
        "A single merged headline (the retired `165/174` 95%-overclaim) is treated as a bug.",
    ]

# ---------------------------------------------------------------------------
# The BACKEND axis (bd e4jv). Three static tiers classifying whether a correct
# REVERSIBLE IMPLEMENTATION of a function's emitted templates exists / is
# obtainable — a level ABOVE "does it lower" (the trace-only runtime never runs
# a real unitary, so the golden proves the lowering, not the backend). Ordered
# most- to least-available. `n/a` is the fourth, non-tier value: a function with
# no reversible-function question at all (no taintable input / non-numeric).
#   standard      — reduces to stock reversible arithmetic / bit-ops that the
#                   existing runtime templates already conceptually cover
#                   (sign/exponent bit-field manip, compare-select, modulo,
#                   integer abs). A correct reversible routine is DIRECTLY
#                   obtainable — a Bennett compute→copy→uncompute wrap of a
#                   textbook reversible integer/bit circuit. THIS is the honest
#                   "backend-available today" set.
#   synthesizable — a well-defined, finite, exact IEEE bit-level algorithm
#                   (mantissa/exponent split: frexp/modf; the rounding family:
#                   ceil/floor/trunc/round/rint/nearbyint/lrint/llrint/lround/
#                   llround; logb's int→fp re-encode; the single-rounding fma).
#                   Buildable, but not off-the-shelf — no library routine to copy.
#   open          — no known ELEMENTARY reversible circuit: the transcendentals
#                   (sin/cos/tan/exp/log/…), algebraic-irrationals (sqrt/cbrt/
#                   hypot), powers (pow) and special functions (erf/tgamma/lgamma).
#                   A real reversible backend needs large polynomial / CORDIC /
#                   iterative-approximation circuits — an OPEN engineering effort,
#                   not "obtainable". The bulk of the math.h "90%".
# The tier is a JUDGMENT, deliberately conservative: a borderline fn tiers DOWN
# (toward less-available) so the "available" count never overclaims (Prime
# Directive — over-declining availability is safe, over-claiming it is the soft
# analog of a silent miscompile). Default (an unclassified B()) is `open` — the
# least-available tier — so an omission under-claims, never over-claims.
# ---------------------------------------------------------------------------
BACKEND_TIERS = ("standard", "synthesizable", "open")   # n/a is the non-tier value
BACKEND_EMOJI = {"standard": "🟩", "synthesizable": "🟨", "open": "🟥", "n/a": "▫️"}
BACKEND_LABEL = {"standard": "standard", "synthesizable": "synth",
                 "open": "open", "n/a": "n/a"}

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
#
# backend — the SECOND axis (bd e4jv). "Verified" above certifies the LOWERING
# only (the right reversible-template call sequence emits, links, signature-
# matches) — the runtime is TRACE-ONLY (each cq_template_* just prints its symbol;
# measure returns 0), so it does NOT certify that a correct reversible IMPLEMENTA-
# TION of those templates exists. The `backend` tier is a STATIC per-fn judgment
# (never measured) of whether such an implementation is obtainable, keyed on the
# NATURE of the emitted templates (see BACKEND_TIERS). It is ORTHOGONAL to the
# lowering column: a fn can lower yet have an `open` backend (most transcendentals),
# or have a `standard` backend yet NOT lower yet (signbit — declines today). Making
# the 1-vs-2 gap explicit stops the single-number overclaim that a compilable fn
# has a working reversible backend (Prime Directive).
# ---------------------------------------------------------------------------
def B(base, cat, args, ret="fp", flags=(), variants=("f", "", "l"), backend="open"):
    return dict(base=base, cat=cat, args=list(args), ret=ret,
                flags=set(flags), variants=list(variants), backend=backend)

# backend tier per fn (bd e4jv) — see BACKEND_TIERS. Keyed on the NATURE of the
# emitted templates, NOT on whether the fn lowers (that is the orthogonal
# Lowering column). Conservative: borderline fns tier toward less-available.
MATHH_SPEC = [
    # --- trigonometric --- (open: transcendental — no elementary reversible circuit)
    B("cos", "trig", ["fp"], flags=("errno",), backend="open"),
    B("sin", "trig", ["fp"], flags=("errno",), backend="open"),
    B("tan", "trig", ["fp"], flags=("errno",), backend="open"),
    B("acos", "trig", ["fp"], flags=("errno",), backend="open"),
    B("asin", "trig", ["fp"], flags=("errno",), backend="open"),
    B("atan", "trig", ["fp"], backend="open"),
    B("atan2", "trig", ["fp", "fp"], flags=("errno",), backend="open"),
    # --- hyperbolic --- (open: transcendental)
    B("cosh", "hyperbolic", ["fp"], flags=("errno",), backend="open"),
    B("sinh", "hyperbolic", ["fp"], flags=("errno",), backend="open"),
    B("tanh", "hyperbolic", ["fp"], backend="open"),
    B("acosh", "hyperbolic", ["fp"], flags=("errno",), backend="open"),
    B("asinh", "hyperbolic", ["fp"], backend="open"),
    B("atanh", "hyperbolic", ["fp"], flags=("errno",), backend="open"),
    # --- exponential / logarithmic ---
    B("exp", "exp_log", ["fp"], flags=("errno",), backend="open"),        # transcendental
    B("exp2", "exp_log", ["fp"], flags=("errno",), backend="open"),
    B("expm1", "exp_log", ["fp"], flags=("errno",), backend="open"),
    B("log", "exp_log", ["fp"], flags=("errno",), backend="open"),
    B("log10", "exp_log", ["fp"], flags=("errno",), backend="open"),
    B("log2", "exp_log", ["fp"], flags=("errno",), backend="open"),
    B("log1p", "exp_log", ["fp"], flags=("errno",), backend="open"),
    B("logb", "exp_log", ["fp"], backend="synthesizable"),                # exponent extract + int→fp re-encode
    B("ilogb", "exp_log", ["fp"], ret="int", backend="standard"),         # exponent bit-field extract → int
    B("ldexp", "exp_log", ["fp", "int"], backend="standard"),             # x·2^n = add n to exponent field
    B("scalbn", "exp_log", ["fp", "int"], backend="standard"),            # (same as ldexp, radix FLT_RADIX)
    B("scalbln", "exp_log", ["fp", "long"], backend="standard"),
    B("frexp", "exp_log", ["fp", "int*"], flags=("byref",), backend="synthesizable"),  # IEEE mantissa/exp split
    B("modf", "exp_log", ["fp", "fp*"], flags=("byref",), backend="synthesizable"),    # IEEE int/frac split
    # --- power --- (open: algebraic-irrational / transcendental, no elementary circuit)
    B("pow", "power", ["fp", "fp"], flags=("errno",), backend="open"),
    B("sqrt", "power", ["fp"], flags=("errno",), backend="open"),
    B("cbrt", "power", ["fp"], backend="open"),
    B("hypot", "power", ["fp", "fp"], backend="open"),
    # --- error / gamma --- (open: special functions)
    B("erf", "error_gamma", ["fp"], backend="open"),
    B("erfc", "error_gamma", ["fp"], flags=("errno",), backend="open"),
    B("tgamma", "error_gamma", ["fp"], flags=("errno",), backend="open"),
    B("lgamma", "error_gamma", ["fp"], flags=("errno",), backend="open"),
    # --- nearest integer --- (synthesizable: IEEE rounding = finite bit-field manip)
    B("ceil", "nearest_int", ["fp"], backend="synthesizable"),
    B("floor", "nearest_int", ["fp"], backend="synthesizable"),
    B("trunc", "nearest_int", ["fp"], backend="synthesizable"),
    B("round", "nearest_int", ["fp"], backend="synthesizable"),
    B("nearbyint", "nearest_int", ["fp"], backend="synthesizable"),
    B("rint", "nearest_int", ["fp"], backend="synthesizable"),
    B("lrint", "nearest_int", ["fp"], ret="long", backend="synthesizable"),
    B("llrint", "nearest_int", ["fp"], ret="long", backend="synthesizable"),
    B("lround", "nearest_int", ["fp"], ret="long", backend="synthesizable"),
    B("llround", "nearest_int", ["fp"], ret="long", backend="synthesizable"),
    # --- remainder --- (standard: modulo = stock reversible integer-style arithmetic)
    B("fmod", "remainder", ["fp", "fp"], flags=("errno",), backend="standard"),        # frem opcode
    B("remainder", "remainder", ["fp", "fp"], flags=("errno",), backend="standard"),
    B("remquo", "remainder", ["fp", "fp", "int*"], flags=("byref",), backend="standard"),  # remainder + integer quotient bits
    # --- manipulation ---
    B("copysign", "manipulation", ["fp", "fp"], backend="standard"),                   # sign-bit copy
    B("nextafter", "manipulation", ["fp", "fp"], flags=("errno",), backend="standard"),# bit-pattern ±1
    # fdim(x,y)=max(x−y,0): the compare-select is standard, but the RESULT is a
    # genuine IEEE fp subtraction (align + subtract + normalize + round-to-nearest-
    # even) — the SAME rounding machinery as fma / the rounding family, NOT a
    # directly-obtainable bit-field/modulo circuit. It is the lone manipulation fn
    # whose core operation rounds; tier DOWN to synthesizable (adversarial audit,
    # bd e4jv Rule-13 pass — over-claiming availability is the hazard).
    B("fdim", "manipulation", ["fp", "fp"], flags=("errno",), backend="synthesizable"),
    B("fmax", "manipulation", ["fp", "fp"], backend="standard"),                       # compare-select
    B("fmin", "manipulation", ["fp", "fp"], backend="standard"),                       # compare-select
    B("fma", "manipulation", ["fp", "fp", "fp"], backend="synthesizable"),             # fused mul-add: one IEEE round
    B("nan", "manipulation", ["str"], backend="n/a"),                                  # no taintable input
    # --- classification / comparison macros --- (standard: bit-field extract / fp compare)
    B("fpclassify", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isfinite", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isinf", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isnan", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isnormal", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("signbit", "classify_macro", ["fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isgreater", "classify_macro", ["fp", "fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isless", "classify_macro", ["fp", "fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
    B("isunordered", "classify_macro", ["fp", "fp"], ret="int", flags=("macro",), variants=("",), backend="standard"),
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
#
# `backend` (bd e4jv) defaults to "n/a": a static, non-lowering fn emits no
# quantum template, so it usually has no reversible-backend question. The one
# honest exception is a fn blocked ONLY at lowering whose numeric core is
# unambiguous stock reversible arithmetic — div/ldiv/lldiv (integer quotient +
# remainder), blocked solely by their div_t struct return (an aggregate-
# decomposition LOWERING gap), get backend="standard". This is exactly the
# two-axis point: the backend is standard even though the lowering is not yet
# there. The string parsers / alloc / RNG / noreturn / sort / mb families stay
# n/a — their difficulty is the memory/source model or they are by-design non-
# numeric, so there is no reversible-arithmetic backend to name.
def St(name, cat, sig, status, reason, backend="n/a"):
    return dict(static=True, name=name, cat=cat, sig=sig, status=status, reason=reason,
                backend=backend)

STDLIB_SPEC = [
    # PROBED (empirical): the integer-abs island -> @llvm.abs.iN -> curated reversible
    # template (the integer analog of math.h's fabs).
    B("abs", "integer", ["int"], ret="int", variants=("",), backend="standard"),   # integer abs (analog of fabs)
    B("labs", "integer", ["long"], ret="long", variants=("",), backend="standard"),
    B("llabs", "integer", ["llong"], ret="llong", variants=("",), backend="standard"),
    St("div", "integer", "div_t div(int, int)", "needs-aggregate",
       "returns a struct (div_t) — needs aggregate (NTuple/extractvalue) decomposition",
       backend="standard"),   # integer quotient+remainder = stock reversible arithmetic; only the struct return blocks lowering
    St("ldiv", "integer", "ldiv_t ldiv(long, long)", "needs-aggregate",
       "returns a struct (ldiv_t) — needs aggregate decomposition", backend="standard"),
    St("lldiv", "integer", "lldiv_t lldiv(long long, long long)", "needs-aggregate",
       "returns a struct (lldiv_t) — needs aggregate decomposition", backend="standard"),
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
                   flags=spec["flags"], cat=spec["cat"], base=spec["base"], suf=suf,
                   backend=spec["backend"])

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
        # p119 (Rule 18): a by-ref math out-param (frexp/modf/remquo) and any direct
        # libm / transcendental call is a LIBRARY function — recognition is retired;
        # it must be SOURCE-INJECTED (see INJECTION-CENSUS.md), NOT given a template.
        if byref:
            return ("library function (by-ref) — source-injection required (Rule 18)", raw)
        if "unknown callee" in low or ("unknown" in low and "call" in low):
            return ("library function — source-injection required (Rule 18)", raw)
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
        "backend": spec.get("backend", "n/a"),
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
                "backend": variant["backend"],
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

# A row counts as "lowers" (its templates are actually emitted+linked+run) iff its
# rollup reached compile — verified, accepted, or partial (≥1 mixture lowered).
# The backend-AVAILABLE gate is (backend == standard) AND (lowers): a standard
# backend that does not lower yet (signbit) is NOT available; an open backend that
# does lower (sin) is NOT available either. Only their intersection is "runnable
# correctly on a real reversible backend today" (modulo BACKEND-CORRECTNESS, the
# third level, which needs simulation and is deferred).
def _lowers(r):
    return r["rollup"] in ("verified", "accepted", "partial")

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
    # bd e4jv — the BACKEND axis (static per-fn tiers, orthogonal to lowering).
    be_standard = sum(1 for r in rows if r.get("backend") == "standard")
    be_synth = sum(1 for r in rows if r.get("backend") == "synthesizable")
    be_open = sum(1 for r in rows if r.get("backend") == "open")
    be_na = sum(1 for r in rows if r.get("backend", "n/a") == "n/a")
    # Self-consistency (Prime-Directive flavored): every row lands in exactly one
    # tier, so the four tiers MUST partition the total. A mis-typed or omitted
    # backend tier fails LOUDLY here rather than silently skewing the count.
    assert be_standard + be_synth + be_open + be_na == total, \
        f"backend tiers {be_standard}+{be_synth}+{be_open}+{be_na} != total {total}"
    backend_available = sum(1 for r in rows if r.get("backend") == "standard" and _lowers(r))
    pct_backend = (100.0 * backend_available / total) if total else 0.0
    return dict(total=total, verified=verified, accepted=accepted, partial=partial,
                compiles=compiles, not_yet=not_yet, out_design=out_design,
                longdouble=longdouble, pct_verified=pct_verified, pct_compiles=pct_compiles,
                be_standard=be_standard, be_synth=be_synth, be_open=be_open, be_na=be_na,
                backend_available=backend_available, pct_backend=pct_backend)

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

# bd e4jv — the backend-tier distribution as a bucket table (the SECOND axis).
def backend_bucket_table(s):
    return [
        "**Backend tiers** (a STATIC per-fn judgment of whether a correct *reversible "
        "implementation* of the emitted templates exists — a level ABOVE \"does it lower\"; "
        "the trace-only runtime never runs a real unitary):", "",
        f"**Backend-available (🟩 standard ∩ lowers): {s['backend_available']}/{s['total']} "
        f"({s['pct_backend']:.1f}%)** — the functions that could actually run correctly on a "
        "real reversible backend today (modulo backend-CORRECTNESS, which needs simulation "
        "and is deferred).", "",
        "| Backend tier | Count | Meaning |",
        "|---|---|---|",
        f"| 🟩 standard | {s['be_standard']} | reduces to stock reversible arithmetic / bit-ops "
        "(sign·exponent bit-field, compare-select, modulo, integer abs) — a correct reversible "
        "routine is directly obtainable (Bennett-copyable) |",
        f"| 🟨 synthesizable | {s['be_synth']} | a well-defined, finite, exact IEEE bit-field / "
        "rounding circuit (frexp/modf split, the rounding family, fma) — buildable, not off-the-shelf |",
        f"| 🟥 open | {s['be_open']} | no known elementary reversible circuit — transcendentals, "
        "algebraic-irrationals (sqrt/cbrt/hypot), powers, special functions |",
        f"| ▫️ n/a | {s['be_na']} | no reversible-function question (no taintable input / non-numeric) |",
    ]

def category_tables(rows):
    out = ["Legend — **Lowering**: ✅ verified · 🟢 accepted (golden pending) · 🟠 partial · "
           "🟡 not-yet (fixable) · ⚠️ error · ⛔ out-by-design. "
           "**Backend**: 🟩 standard · 🟨 synth · 🟥 open · ▫️ n/a "
           "(orthogonal axis — see the backend-tier table above).", ""]
    by_cat = {}
    for r in rows:
        by_cat.setdefault(r["cat"], []).append(r)
    for cat in dict.fromkeys(r["cat"] for r in rows):
        out += [f"### {cat}", "",
                "| Function | Signature | Mixtures (C/Q) | Lowering | Backend | Reason |",
                "|---|---|---|---|---|---|"]
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
            be = r.get("backend", "open")
            be_str = f"{BACKEND_EMOJI.get(be, '?')} {BACKEND_LABEL.get(be, be)}"
            out.append(f"| `{r['name']}`{flag_str} | `{r['sig']}` | {cell_str} | "
                       f"{EMOJI.get(r['rollup'], '?')} {r['rollup']} | {be_str} | {reason} |")
        out.append("")
    return out

def write_library_page(lib, s):
    lines = [f"# `{lib['name']}` quantum-coverage", "",
             "> Auto-generated by `tools/library_coverage/probe.py` — do not edit by hand.", "",
             lib["blurb"], "",
             f"**Compiles: {s['compiles']}/{s['total']} ({s['pct_compiles']:.1f}%)** — of which "
             f"**golden-verified: {s['verified']}/{s['total']} ({s['pct_verified']:.1f}%)**.", ""]
    # For math.h, the number above is the RECOGNITION floor — state the disjoint
    # injection scoreboard so this page can't be read as merged coverage (owner rule).
    if lib["slug"] == "mathh":
        lines += two_scoreboard_lines(short=True, census_link="../INJECTION-CENSUS.md") + [""]
    lines += bucket_table(s)
    lines += ["", "---", ""]
    lines += backend_bucket_table(s)
    lines.append("")
    lines += category_tables(lib["rows"])
    (COVERAGE_DIR / f"{lib['slug']}.md").write_text("\n".join(lines))

def aggregate(per_lib):
    keys = ("total", "verified", "accepted", "partial", "compiles", "not_yet", "out_design",
            "be_standard", "be_synth", "be_open", "be_na", "backend_available")
    agg = {k: sum(s[k] for _, s in per_lib) for k in keys}
    agg["pct_verified"] = 100.0 * agg["verified"] / agg["total"] if agg["total"] else 0.0
    agg["pct_compiles"] = 100.0 * agg["compiles"] / agg["total"] if agg["total"] else 0.0
    agg["pct_backend"] = 100.0 * agg["backend_available"] / agg["total"] if agg["total"] else 0.0
    return agg

# bd e4jv — the backend tier is a STATIC per-fn property carried by the spec.
# render() backfills it into any row from an OLDER results.json that predates the
# field (so `render` alone regenerates correct pages without a full re-probe);
# a fresh `run` writes it directly. Keyed by (slug, name) — names are unique per
# library. Missing → the safe under-claiming default (`open` for a probed fn).
def _spec_backend_map():
    m = {}
    for lib in LIBRARIES:
        d = {}
        for spec in lib["spec"]:
            if spec.get("static"):
                d[spec["name"]] = spec.get("backend", "n/a")
            else:
                for suf in spec["variants"]:
                    d[spec["base"] + suf] = spec.get("backend", "open")
        m[lib["slug"]] = d
    return m

def render(data=None):
    if data is None:
        data = json.loads(RESULTS.read_text())
    libs = data["libraries"]
    bmap = _spec_backend_map()
    for lib in libs:
        for r in lib["rows"]:
            if "backend" not in r:
                r["backend"] = bmap.get(lib["slug"], {}).get(r["name"], "open")
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
         f"**All libraries — lowering-verified: {agg['verified']}/{agg['total']} "
         f"({agg['pct_verified']:.1f}%)** &nbsp;·&nbsp; backend-available: "
         f"{agg['backend_available']}/{agg['total']} ({agg['pct_backend']:.1f}%).", "",
         *two_scoreboard_lines(short=False, census_link="INJECTION-CENSUS.md"), "",
         "Coverage has **two orthogonal axes** (bd e4jv). **Lowering** = *every* applicable "
         "classical/quantum (C/Q) argument mixture lowers, links, runs, **and** matches a committed "
         "golden trace — the compiler emits the right reversible-template call sequence. But the "
         "runtime is **trace-only** (each `cq_template_*` just prints its symbol; measure returns 0), "
         "so \"verified\" certifies the lowering, **not** that a correct reversible *implementation* "
         "of those templates exists. **Backend** is that second axis: a static per-fn tier — 🟩 "
         "`standard` (reversible routine directly obtainable), 🟨 `synthesizable` (buildable IEEE "
         "bit-field circuit, not off-the-shelf), 🟥 `open` (no known elementary reversible circuit: "
         "the transcendentals — the bulk of the math.h count). **Backend-available** = 🟩 standard "
         "**and** it lowers. A third level, backend-*correctness* (does it compute the right unitary), "
         "needs simulation and is deferred (owner, 2026-06-10). A loud decline is a *correct* "
         "(uncovered) outcome — never papered over to inflate a number (Prime Directive); the "
         "backend column exists to stop the single-number overclaim that a *compilable* fn has a "
         "*working reversible backend*.", "",
         "| Library | Fit | Lowers | Verified | Backend-avail | 🟩 std | 🟨 syn | 🟥 open | Cannot-yet | By-design | Detail |",
         "|---|---|---|---|---|---|---|---|---|---|---|"]
    for lib, s in per_lib:
        L.append(f"| `{lib['name']}` | {lib['fit']} | {s['compiles']}/{s['total']} ({s['pct_compiles']:.0f}%) "
                 f"| {s['verified']}/{s['total']} ({s['pct_verified']:.0f}%) "
                 f"| {s['backend_available']}/{s['total']} ({s['pct_backend']:.0f}%) "
                 f"| {s['be_standard']} | {s['be_synth']} | {s['be_open']} | {s['not_yet']} | "
                 f"{s['out_design']} | [detail](coverage/{lib['slug']}.md) |")
    L += ["", "## Adding a library", "",
          "Append a `Lib(name, include, slug, blurb, fit, SPEC)` entry to `LIBRARIES` in "
          "`probe.py` (define its `SPEC` list like `MATHH_SPEC`), then run "
          "`python3 tools/library_coverage/probe.py run`. The summary table, the per-library "
          "detail page, the `goldens/<slug>/` dir, and the README badge all regenerate "
          "automatically. After an adversarial correctness audit (Rule 13), commit goldens with "
          "`python3 tools/library_coverage/probe.py bless --lib <name>`.", "",
          "Each `B(...)`/`St(...)` also carries a **`backend=`** tier (🟩 `standard` · 🟨 "
          "`synthesizable` · 🟥 `open` · `n/a`) — a static per-fn judgment of the emitted "
          "templates' reversible-backend availability, orthogonal to whether the fn lowers. "
          "Omitting it defaults to the safe under-claiming `open`; the four tiers must partition "
          "the total or `summarize()` asserts loudly.", "",
          "Scoped-but-not-yet-wired candidate headers are in "
          "[`SCOPED-CANDIDATES.md`](SCOPED-CANDIDATES.md)."]
    COVERAGE_MD.write_text("\n".join(L))

README_START = "<!-- LIBRARY-COVERAGE:START -->"
README_END = "<!-- LIBRARY-COVERAGE:END -->"

def update_readme(per_lib, agg):
    if not README.exists():
        return
    L = [f"**Standard-library quantum-coverage — lowering-verified: {agg['verified']}/{agg['total']} "
         f"({agg['pct_verified']:.1f}%)** &nbsp;·&nbsp; backend-available: "
         f"{agg['backend_available']}/{agg['total']} ({agg['pct_backend']:.1f}%).", "",
         "Two axes (bd e4jv): **Lowering** = the compiler emits + links + golden-matches the "
         "reversible-template sequence. **Backend-available** = 🟩 `standard` (a correct reversible "
         "routine is directly obtainable) **and** it lowers — vs 🟨 `synthesizable` / 🟥 `open` "
         "(no known elementary reversible circuit — the transcendentals). The trace-only runtime "
         "proves the lowering, not the backend.", "",
         "| Library | Lowers | Verified | Backend-avail | 🟩 std | 🟨 syn | 🟥 open | By-design |",
         "|---|---|---|---|---|---|---|---|"]
    for lib, s in per_lib:
        L.append(f"| [`{lib['name']}`](tools/library_coverage/coverage/{lib['slug']}.md) "
                 f"| {s['compiles']}/{s['total']} ({s['pct_compiles']:.0f}%) "
                 f"| {s['verified']}/{s['total']} ({s['pct_verified']:.0f}%) "
                 f"| {s['backend_available']}/{s['total']} ({s['pct_backend']:.0f}%) "
                 f"| {s['be_standard']} | {s['be_synth']} | {s['be_open']} | {s['out_design']} |")
    L += ["", *two_scoreboard_lines(short=True),
          "", "Full tables: [`tools/library_coverage/COVERAGE.md`](tools/library_coverage/COVERAGE.md) "
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
