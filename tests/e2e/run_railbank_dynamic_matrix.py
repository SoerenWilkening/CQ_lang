#!/usr/bin/env python3
"""Compile a rail-bank C admission matrix at clang -O1 and check each verdict.

The expectations live in a JSON sidecar next to the matrix source,
``<SOURCE>.cases.json``, so several matrix sources (one per track) can be
registered as separate ctest entries without editing this runner:

  {"cases": {"<id>": {"accept": bool, "diagnostic": str|null,
                      "require_railbank": bool (default true),
                      "stage1_contains_in_order": [str, ...] (optional),
                      "stage1_note": str (optional)}},
   "twins": [{"rolled": id, "twin": id, "argv": [str, ...],
              "dropped_twin_lines": [str, ...]}]}

An accept row must lower at exit 0, carry ``!cq.railbank`` (unless it is a
twin's unrolled side or sets ``require_railbank: false``), emit no
``cqrt_qram_*`` and never park a literal (any integer value, ``undef``,
``poison``) in a ``!cq.railbank`` object (resolved through getelementptr hops;
a classical store into a non-bank object is not a parked handle — see
``literal_bank_stores``).  A decline row must exit
non-zero with ``diagnostic`` in stderr.  A twin pair is LINKED, run, and its
rolled trace must be byte-identical to the hand-unrolled twin's after exactly
the listed identity lines are dropped (CLAUDE.md §1 Witnesses).

Every row is checked and every failure reported; the summary line prints the
denominator so a vacuous run (0 cases) can never read as a pass (CLAUDE.md L10).
"""

from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys
import tempfile


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=False)


def load_expectations(source: str) -> tuple[dict[int, dict], list[dict]]:
    sidecar = pathlib.Path(source + ".cases.json")
    def no_duplicate_keys(pairs: list[tuple[str, object]]) -> dict:
        # json.loads keeps the LAST of two equal keys silently; a duplicated
        # case id would drop a row and still report a pass (Track B, 2026-09-24).
        keys = [k for k, _ in pairs]
        dups = sorted({k for k in keys if keys.count(k) > 1})
        if dups:
            raise SystemExit(f"{sidecar}: duplicate key(s) {dups}")
        return dict(pairs)
    doc = json.loads(sidecar.read_text(), object_pairs_hook=no_duplicate_keys)
    cases = {int(k): v for k, v in doc["cases"].items()}
    twins = doc.get("twins", [])
    if not cases:
        raise SystemExit(f"{sidecar}: no cases (a vacuous matrix is not a pass)")
    for tw in twins:
        for side in ("rolled", "twin"):
            if tw[side] not in cases or not cases[tw[side]]["accept"]:
                raise SystemExit(f"{sidecar}: twin {side} {tw[side]} is not an accept row")
    return cases, twins


_DEFINE = re.compile(r'^define [^@]*@("[^"]*"|[-\w.$]+)\(', re.M)
# A local name: quoted, or the full unquoted identifier class LLVM prints
# (`[-a-zA-Z$._0-9]`, Rule-13 orchestrator round 1: `-`/`$` were missed).
_NAME = r'(?:"[^"]*"|[-\w.$]+)'
_BANK_ALLOCA = re.compile(r"^\s*%(" + _NAME + r") = alloca [^\n]*!cq\.railbank\b", re.M)
_GEP = re.compile(r"^\s*%(" + _NAME + r") = getelementptr [^\n]*?ptr %(" + _NAME + r"),", re.M)
# ANY non-SSA stored value — an integer literal of any value and width, `true`/
# `false`, `undef`, `poison`, a constant expression — is not a rail handle.
# `atomic`/`volatile` and a missing `, align` must not hide it (Rule-13 review
# P3-1). The operand is split from the address by anchoring on the LAST
# `, ptr %<name>` of the line, never by the first comma: a constant expression
# (`getelementptr (…, …)`, `add (…, …)`) contains commas of its own (Rule-13
# round 2, P3-3), and a constant can never name a `%` local, so the last such
# anchor is the address. A store through a phi/select of addresses is NOT
# resolved here — `declineNonHandleBankStores` (getUnderlyingObject) is the
# compiler's real gate.
_STORE_HEAD = re.compile(r"^\s*store (?:atomic )?(?:volatile )?i\d+ ")
_STORE_ADDR = re.compile(r", ptr %(" + _NAME + r")(?=[\s,]|$)")


def _stores(body: str):
    """Yield (stored operand text, address name) for every integer store."""
    for line in body.splitlines():
        head = _STORE_HEAD.match(line)
        if not head:
            continue
        addrs = list(_STORE_ADDR.finditer(line, head.end()))
        if not addrs:
            continue  # a store to a global / non-local address: never a bank
        last = addrs[-1]
        yield line[head.end():last.start()].strip(), last.group(1)


def literal_bank_stores(lowered_text: str) -> list[tuple[str, str, str]]:
    """Every store of a NON-SSA value (a literal, `undef`, `poison`, a constant
    expression) whose address resolves (through getelementptr hops) to an alloca
    carrying `!cq.railbank`. Returns (function, stored value, pointer name).

    A literal in a rail bank is never a handle: handle 0 is a live rail in this
    runtime, and any other literal names a rail nobody minted for that cell.

    ⚠ Scoped to the OBJECT, not to the promoter's `%cq.bank.addr` name (bd
    test_C_libtooling-xdu2.9). The name is minted for every relocated cell
    store BEFORE the carve decides whether the object is a bank, so a dead
    cell whose object is correctly NOT a bank (it parks the classical seed 0)
    carried the name too; and a literal reaching a bank through any other
    address spelling carried none. Names are function-local, so each
    function body is resolved separately."""
    hits: list[tuple[str, str, str]] = []
    starts = [(m.start(), m.group(1)) for m in _DEFINE.finditer(lowered_text)]
    if len(starts) != len(re.findall(r"^define ", lowered_text, re.M)):
        raise SystemExit("literal_bank_stores: a `define` line was not parsed")
    for idx, (start, fn) in enumerate(starts):
        end = starts[idx + 1][0] if idx + 1 < len(starts) else len(lowered_text)
        body = lowered_text[start:end]
        banks = set(_BANK_ALLOCA.findall(body))
        base = dict(_GEP.findall(body))
        for val, ptr in _stores(body):
            if val.startswith("%"):
                continue  # an SSA value: the compiler's postcondition asks if it is a handle
            p, hops = ptr, 0
            while p in base and hops < 64:
                p, hops = base[p], hops + 1
            if p in banks:
                hits.append((fn, val.strip(), ptr))
    return hits


def check_case(case_id: int, spec: dict, twin_sides: set[int],
               stage1: pathlib.Path, lowered: pathlib.Path,
               lower_result: subprocess.CompletedProcess[str]) -> list[str]:
    errs: list[str] = []
    if spec["accept"]:
        if lower_result.returncode != 0:
            return [f"CASE={case_id}: expected accept\n{lower_result.stderr}"]
        stage1_text = stage1.read_text()
        lowered_text = lowered.read_text()
        pos = 0
        for needle in spec.get("stage1_contains_in_order", []):
            pos = stage1_text.find(needle, pos)
            if pos < 0:
                errs.append(f"CASE={case_id}: {spec.get('stage1_note', 'stage-1 shape moved')}"
                            f" (missing {needle!r})")
                break
        require_bank = spec.get("require_railbank", True) and case_id not in twin_sides
        if require_bank and "!cq.railbank" not in lowered_text:
            errs.append(f"CASE={case_id}: accepted bank lacks !cq.railbank")
        if "cqrt_qram_" in lowered_text:
            errs.append(f"CASE={case_id}: rail bank emitted cqrt_qram_*")
        for fn, val, ptr in literal_bank_stores(lowered_text):
            errs.append(f"CASE={case_id}: rail bank parks a non-handle literal "
                        f"(@{fn}: store {val} -> %{ptr})")
    else:
        if lower_result.returncode == 0:
            errs.append(f"CASE={case_id}: expected a loud decline")
        elif spec["diagnostic"] not in lower_result.stderr:
            errs.append(f"CASE={case_id}: missing diagnostic: {spec['diagnostic']}\n"
                        f"{lower_result.stderr}")
    return errs


def main() -> int:
    if len(sys.argv) != 8:
        print("usage: run_railbank_dynamic_matrix.py CLANG CQ_OPT PASS INCLUDE "
              "SOURCE RUNTIME_LIB TEMPLATES_LIB", file=sys.stderr)
        return 2
    clang, cq_opt, plugin, include, source, runtime, templates = sys.argv[1:]
    cases, twins = load_expectations(source)
    # Only the UNROLLED side of a twin is bankless by design.
    twin_sides = {tw["twin"] for tw in twins}
    name = pathlib.Path(source).stem
    errors: list[str] = []

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = pathlib.Path(temp_dir)
        for case_id, spec in sorted(cases.items()):
            stage1 = temp / f"case-{case_id}.ll"
            lowered = temp / f"case-{case_id}.lowered.ll"
            compile_result = run([
                clang, f"-I{include}", "-include", "CQ.h", "-O1",
                "-emit-llvm", "-S", f"-DCASE={case_id}", source,
                "-o", str(stage1),
            ])
            if compile_result.returncode != 0:
                errors.append(f"CASE={case_id}: clang failed\n{compile_result.stderr}")
                continue
            lower_result = run([
                cq_opt, "-load-pass-plugin", plugin, "-passes=cq-lowering",
                "-S", str(stage1), "-o", str(lowered),
            ])
            errors += check_case(case_id, spec, twin_sides, stage1, lowered,
                                 lower_result)

        for tw in twins:
            rolled, twin = tw["rolled"], tw["twin"]
            dropped = set(tw.get("dropped_twin_lines", []))
            traces = []
            for case_id in (rolled, twin):
                exe = temp / f"case-{case_id}.exe"
                link = run([clang, str(temp / f"case-{case_id}.lowered.ll"),
                            templates, runtime, "-o", str(exe)])
                if link.returncode != 0:
                    errors.append(f"CASE={case_id}: link failed\n{link.stderr}")
                    break
                traces.append(run([str(exe), *tw.get("argv", [])]).stdout.splitlines())
            if len(traces) != 2:
                continue
            rolled_trace = traces[0]
            twin_trace = [ln for ln in traces[1] if ln not in dropped]
            if len(traces[1]) - len(twin_trace) != len(dropped):
                errors.append(f"TWIN {rolled}/{twin}: expected to drop exactly "
                              f"{len(dropped)} identity line(s)")
            elif not rolled_trace or rolled_trace != twin_trace:
                errors.append(f"TWIN {rolled}/{twin}: rolled trace is not "
                              "byte-identical to the hand-unrolled twin")

    for err in errors:
        print(err, file=sys.stderr)
    accepted = sum(1 for c in cases.values() if c["accept"])
    print(f"{name}: {len(cases)} case(s): {accepted} accept, "
          f"{len(cases) - accepted} decline; {len(twins)} twin(s); "
          f"{len(errors)} failure(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
