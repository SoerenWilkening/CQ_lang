#!/usr/bin/env python3
"""The cross-module Python API of the checker, frozen by cq-zew (Z1 in cq-arch), made checkable.

FROZEN below is the whole frozen list. For each entry:

1. Once the owning module defines the name, it is defined exactly once at module level, and its
   signature starts with the frozen parameters (same names, order, kinds and defaults). Extra
   parameters are allowed only after them and only with a default (they are private to the owner).
   A name that is not defined yet is PENDING: reported, and a failure only under --require-all
   (the wave-0 coordinator's gate, once every owner has landed).
2. report.SIBLING_API (what report.evaluate calls) is a subset of FROZEN with the same text.
3. Unless --no-bd: the Z1 comment on cq-arch contains every line `--print` emits (Z1 is the frozen
   text; this table is its checkable copy, so the two cannot drift apart).

Usage: check_api.py [--require-all] [--no-bd] [--print]
Exit 0 only when every check holds; every failure is printed.
"""
import argparse
import dataclasses
import importlib
import inspect
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))

REQ = object()  # a parameter with no default

# (module, owner module, owner bead, name, params, returns, consumers)
# params: (name, type, kind, default) with kind "p" (positional-or-keyword) or "k" (keyword-only).
FROZEN = [
    ("drivers", "chk-drivers", "cq-w0-chk-drivers", "driver_spec",
     [("example", "str", "p", REQ), ("example_dir", "Path", "p", REQ)], "DriverSpec",
     "chk-report (cq-w0-chk-report), chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline)"),
    ("drivers", "chk-drivers", "cq-w0-chk-drivers", "driver_source",
     [("spec", "DriverSpec", "p", REQ), ("samples", "Sequence[dict]", "p", REQ), ("before_call", "str", "k", ""), ("after_call", "str", "k", ""),
      ("main_name", "str", "k", "main")], "str",
     "chk-core (cq-w0-chk-core, run.py), chk-oracle (cq-w0-chk-oracle, oracle.py), usercheck (cq-w1-usercheck)"),
    ("sampling", "chk-drivers", "cq-w0-chk-drivers", "sample_set",
     [("spec", "DriverSpec", "p", REQ), ("example_dir", "Path", "p", REQ)], "SampleSet",
     "chk-report (cq-w0-chk-report), chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline), "
     "usercheck (cq-w1-usercheck)"),
    ("run", "chk-core", "cq-w0-chk-core", "run_sample",
     [("lowered", "Path", "p", REQ), ("spec", "DriverSpec", "p", REQ), ("sample", "dict", "p", REQ), ("side", "str", "p", REQ)], "RunResult",
     "chk-report (cq-w0-chk-report), chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline), "
     "usercheck (cq-w1-usercheck)"),
    ("oracle", "chk-oracle", "cq-w0-chk-oracle", "run_sample",
     [("o1", "Path", "p", REQ), ("spec", "DriverSpec", "p", REQ), ("sample", "dict", "p", REQ)], "RunResult",
     "chk-report (cq-w0-chk-report), chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline), "
     "usercheck (cq-w1-usercheck)"),
    ("oracle", "chk-oracle", "cq-w0-chk-oracle", "trace_sample",
     [("o1", "Path", "p", REQ), ("spec", "DriverSpec", "p", REQ), ("sample", "dict", "p", REQ)], "List[dict]",
     "chk-drivers (cq-w0-chk-drivers, sampling.py trip search), usercheck (cq-w1-usercheck)"),
    ("compare", "chk-compare", "cq-w0-chk-compare", "compare",
     [("ours", "Sequence[RunResult]", "p", REQ), ("other", "Sequence[RunResult]", "p", REQ), ("against", "str", "p", REQ), ("classical_key", "Optional[Callable[[dict], Hashable]]", "p", None)],
     "List[str]",
     "chk-report (cq-w0-chk-report), chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline), "
     "usercheck (cq-w1-usercheck)"),
    ("compare", "chk-compare", "cq-w0-chk-compare", "classical_key_from_driver",
     [("driver", "DriverSpec", "p", REQ)], "Callable[[dict], Hashable]",
     "chk-report (cq-w0-chk-report), chk-selftest (cq-w0-chk-selftest), usercheck (cq-w1-usercheck)"),
    ("mutants", "chk-selftest", "cq-w0-chk-selftest", "selftest", [], "int",
     "chk-report (cq-w0-chk-report, cli selftest)"),
    ("mutants", "chk-selftest", "cq-w0-chk-selftest", "baseline", [], "int",
     "chk-report (cq-w0-chk-report, cli baseline), chk-baseline (cq-w0-chk-baseline, runs it)"),
    ("user", "usercheck", "cq-w1-usercheck", "main",
     [("o1", "str", "p", REQ), ("lowered", "str", "p", REQ), ("entry", "str", "p", REQ), ("samples", "Optional[int]", "p", REQ)], "int",
     "chk-report (cq-w0-chk-report, cli user), driver (cq-w1-driver, cqcc --cq-check via the CLI)"),
    ("report", "chk-report", "cq-w0-chk-report", "evaluate",
     [("ex", "Example", "p", REQ), ("ours", "Optional[Path]", "p", REQ), ("oracle", "str", "p", "both"), ("lower_error", "str", "p", ""),
      ("short_circuit", "bool", "p", True), ("diff_out", "Optional[Path]", "p", None), ("reference_mode", "bool", "p", False)], "Verdict",
     "chk-report (cli run), chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline)"),
    ("report", "chk-report", "cq-w0-chk-report", "all_examples",
     [("spec", "Optional[Path]", "p", None)], "List[Example]",
     "chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline)"),
    ("report", "chk-report", "cq-w0-chk-report", "resolve_examples",
     [("names", "Sequence[str]", "p", REQ), ("spec", "Optional[Path]", "p", None)], "List[Example]",
     "chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline)"),
    ("report", "chk-report", "cq-w0-chk-report", "green",
     [("v", "Verdict", "p", REQ)], "bool",
     "chk-selftest (cq-w0-chk-selftest), chk-baseline (cq-w0-chk-baseline)"),
]

# Names that are not functions. report.Example: frozen dataclass fields and properties.
EXAMPLE_FIELDS = ["name", "dir"]
EXAMPLE_PROPS = ["number", "base", "c", "o1", "reference"]
VERDICT_CONSTANTS = {"PASS": "pass", "FAIL": "fail", "ERROR": "error", "NOT_RUN": "not-run"}

failures = []
pending = []


def fail(msg):
    failures.append(msg)
    print("FAIL:", msg)


def fmt_default(d):
    return "" if d is REQ else " = " + repr(d)


def fmt_sig(params, returns):
    pos = [f"{n}: {t}{fmt_default(d)}" for n, t, k, d in params if k == "p"]
    kw = [f"{n}: {t}{fmt_default(d)}" for n, t, k, d in params if k == "k"]
    parts = pos + (["*"] + kw if kw else [])
    return f"({', '.join(parts)}) -> {returns}"


def z1_lines():
    out = []
    for mod, owner, bead, name, params, ret, consumers in FROZEN:
        out.append(f"{mod}.{name}{fmt_sig(params, ret)}  [{owner}, {bead}; consumers: {consumers}]")
    out.append("report.Example(name: str, dir: Path), frozen dataclass; properties number, base, c, o1, "
               "reference  [chk-report, cq-w0-chk-report; consumers: chk-selftest (cq-w0-chk-selftest), "
               "chk-baseline (cq-w0-chk-baseline)]")
    out.append("report.PASS = 'pass', report.FAIL = 'fail', report.ERROR = 'error', report.NOT_RUN = 'not-run'"
               "  [chk-report, cq-w0-chk-report; consumers: chk-selftest (cq-w0-chk-selftest), "
               "chk-baseline (cq-w0-chk-baseline)]")
    return out


def defined_once(src, name):
    n = len(re.findall(rf"^(?:async\s+)?(?:def|class)\s+{re.escape(name)}\b", src, re.M))
    n += len(re.findall(rf"^{re.escape(name)}\s*(?::[^=\n]*)?=", src, re.M))
    return n


KIND = {"p": inspect.Parameter.POSITIONAL_OR_KEYWORD, "k": inspect.Parameter.KEYWORD_ONLY}


def check_signature(where, fn, params):
    try:
        sig = inspect.signature(fn)
    except (TypeError, ValueError) as e:
        fail(f"{where}: no signature: {e}")
        return
    actual = list(sig.parameters.values())
    if len(actual) < len(params):
        fail(f"{where}: has {len(actual)} parameters, frozen {len(params)}: {sig}")
        return
    for (n, _t, k, d), a in zip(params, actual):
        if a.name != n:
            fail(f"{where}: parameter {a.name!r} where the frozen list has {n!r}: {sig}")
        if a.kind != KIND[k] and not (k == "k" and a.kind == inspect.Parameter.POSITIONAL_OR_KEYWORD):
            fail(f"{where}: parameter {n!r} is {a.kind.description}, frozen {KIND[k].description}")
        if d is REQ and a.default is not inspect.Parameter.empty:
            fail(f"{where}: parameter {n!r} has a default; frozen as required")
        if d is not REQ and (a.default is inspect.Parameter.empty or a.default != d):
            fail(f"{where}: parameter {n!r} default {a.default!r}, frozen {d!r}")
    for a in actual[len(params):]:
        if a.kind in (inspect.Parameter.VAR_POSITIONAL, inspect.Parameter.VAR_KEYWORD):
            continue
        if a.default is inspect.Parameter.empty:
            fail(f"{where}: extra parameter {a.name!r} has no default (callers pass only the frozen ones)")


def check_modules():
    for mod, owner, bead, name, params, ret, _ in FROZEN:
        where = f"{mod}.{name} ({owner}, {bead})"
        path = ROOT / "checker" / "cqcheck" / f"{mod}.py"
        src = path.read_text()
        try:
            m = importlib.import_module(f"cqcheck.{mod}")
        except Exception as e:  # noqa: BLE001 - an unimportable module is a failure, never pending
            fail(f"{where}: importing cqcheck.{mod}: {type(e).__name__}: {e}")
            continue
        fn = getattr(m, name, None)
        if fn is None:
            pending.append(where)
            continue
        if not callable(fn):
            fail(f"{where}: not callable")
            continue
        count = defined_once(src, name)
        if count != 1:
            fail(f"{where}: defined {count} times at module level in {path.name} (frozen: exactly once)")
        check_signature(where, fn, params)

    from cqcheck import report
    ex = report.Example
    if not dataclasses.is_dataclass(ex) or not ex.__dataclass_params__.frozen:
        fail("report.Example: not a frozen dataclass")
    elif [f.name for f in dataclasses.fields(ex)] != EXAMPLE_FIELDS:
        fail(f"report.Example: fields {[f.name for f in dataclasses.fields(ex)]}, frozen {EXAMPLE_FIELDS}")
    for p in EXAMPLE_PROPS:
        if not isinstance(getattr(ex, p, None), property):
            fail(f"report.Example.{p}: not a property")
    for c, v in VERDICT_CONSTANTS.items():
        if getattr(report, c, None) != v:
            fail(f"report.{c} = {getattr(report, c, None)!r}, frozen {v!r}")

    frozen_text = {(mod, name): fmt_sig(params, ret) for mod, _, _, name, params, ret, _ in FROZEN}
    frozen_owner = {(mod, name): owner for mod, owner, _, name, _, _, _ in FROZEN}
    for mod, owner, name, text in report.SIBLING_API:
        if (mod, name) not in frozen_text:
            fail(f"report.SIBLING_API: {mod}.{name} is not in the frozen list")
            continue
        if owner != frozen_owner[(mod, name)]:
            fail(f"report.SIBLING_API: {mod}.{name} owner {owner!r}, frozen {frozen_owner[(mod, name)]!r}")
        if not _same_sig_names(text, frozen_text[(mod, name)]):
            fail(f"report.SIBLING_API: {mod}.{name} {text} disagrees with the frozen {frozen_text[(mod, name)]}")


def _param_names(text):
    inner = text[text.index("(") + 1:text.rindex(") ->")]
    names, depth, cur = [], 0, ""
    for ch in inner + ",":
        if ch in "[(":
            depth += 1
        elif ch in "])":
            depth -= 1
        if ch == "," and depth == 0:
            tok = cur.strip()
            if tok and tok != "*":
                names.append(re.match(r"[A-Za-z_]\w*", tok).group(0))
            cur = ""
        else:
            cur += ch
    return names, text[text.rindex("->") + 2:].strip()


def _same_sig_names(a, b):
    return _param_names(a) == _param_names(b)


def check_z1():
    out = subprocess.run(["bd", "comments", "cq-arch", "--json"], cwd=ROOT, capture_output=True, text=True)
    if out.returncode != 0:
        fail(f"bd comments cq-arch failed: {out.stderr.strip()}")
        return
    data = json.loads(out.stdout)
    texts = [c.get("text") or c.get("body") or "" for c in (data if isinstance(data, list) else [])]
    z1 = [t for t in texts if t.lstrip().startswith("Z1")]
    if len(z1) != 1:
        fail(f"cq-arch: expected exactly one comment starting with Z1, found {len(z1)}")
        return
    body = " ".join(z1[0].split())
    for line in z1_lines():
        if " ".join(line.split()) not in body:
            fail(f"cq-arch Z1 lacks the frozen line: {line}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--require-all", action="store_true", help="a name not defined yet fails")
    ap.add_argument("--no-bd", action="store_true", help="skip the cross-check against cq-arch Z1")
    ap.add_argument("--print", action="store_true", help="print the frozen lines (Z1's list) and exit")
    a = ap.parse_args()
    if a.print:
        print("\n".join(f"- {l}" for l in z1_lines()))
        return 0
    check_modules()
    if not a.no_bd:
        check_z1()
    for p in pending:
        print(("FAIL: " if a.require_all else "PENDING: ") + p + " is not defined yet")
    if a.require_all:
        failures.extend(pending)
    n = len(FROZEN) + 2
    print(f"checker API (cq-zew Z1): {n} frozen entries, {len(pending)} pending, {len(failures)} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
