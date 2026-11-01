"""Checker self-test and baseline (module chk-selftest, bead cq-w0-chk-selftest; cq-arch Z1).

    selftest() -> int      `cqcheck selftest`: exit status, 0 iff every check below holds
    baseline() -> int      `cqcheck baseline`: every reference against itself and its C program

Self-test (CLAUDE.md "The §6 checker", Self-test; NORTHSTAR principle 5). No green counts until a
mutated reference and an empty output are both rejected. Three parts:

1. Control. Every reference a mutant is cut from is evaluated as itself
   (report.evaluate(ex, ex.reference, short_circuit=False, reference_mode=True)) and must be green.
   A mutant of a reference that is not green proves nothing: its rejection might be the
   reference's own failure. Such a mutant is reported as unproven, never counted as rejected.
2. Mutants. tests/mutants/mutants.json lists them: a reference plus textual edits, one class each
   (CLASSES). Each is written under $CQ_BUILD_DIR/mutants/<id>/ (never into CQ_spec), must still
   parse (llvm-as), and is evaluated like its reference (reference_mode=True: it is a reference
   with one change, and plain cq-verify rejects every reference by design, cq-arch V1). It is
   rejected when the §6 check against the reference FAILs with a reason that matches its class's
   pattern, and the C-oracle check FAILs with its class's pattern when the class predicts one
   (otherwise the C-oracle check may pass or fail, but never ERROR). ERROR is never a rejection:
   it is a check that could not be decided. A mutant of a class in ROTATION_ONLY must also be
   caught by the rotation-list comparator (cq-lkth): with every site substituted, a skipped or
   moved Ry also skips or moves its substitution, so the outputs may differ first and compare never
   reaches the rotation list. When the evaluation does not FAIL on the rotation list against both
   oracles, the mutant is evaluated again with cq_theta substitution off, where the evaluator
   leaves every value as it is (an Ry is logged, not applied), and that run must so FAIL. Its
   control (the reference against itself with substitution off) must be green too, or the mutant
   is unproven. (A register only cq_theta substitution sets, 59's bits, reads 0 without it: there
   the evaluation with substitution already fails on the rotation list.)
3. Empty output. For every example of the corpus (counted from the directory), an empty lowered
   module (zero bytes: the pass emitted nothing) is evaluated as our output (reference_mode=False)
   and must FAIL both §6 checks, each with a reason that names the missing definition.

Every mutant class must have at least one mutant (a class without one is a failure). The verdicts
are written to $CQ_BUILD_DIR/cqcheck/selftest/ (JSON lines), never to `run`'s verdict store.

Baseline (bead cq-w0-chk-baseline runs it): for every example,
report.evaluate(ex, ex.reference, short_circuit=False, reference_mode=True). Verdicts go to
$CQ_BUILD_DIR/cqcheck/baseline/ (never `run`'s store: a reference's verdict is not ours, so it never
reaches `progress`). Exit 0 iff every example is green.

Both run examples in parallel, $CQCHECK_JOBS at a time (default: the CPU count), and check
spec.lock first (drift exits 1).
"""
from __future__ import annotations

import concurrent.futures
import json
import os
import re
import subprocess
import sys
import threading
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

from cqcheck import report
from cqcheck.contracts import Verdict, to_json

MUTANTS_FILE = report.ROOT / "tests" / "mutants" / "mutants.json"

_ROT_REF = r"rotation list differs"
_ROT_C = r"C site .* (has no lowered gate|reached .*)|lowered gate #\d+ .* corresponds to no C site|C order puts"
_MEAS = r"measurement \d+ reads .* != "
_OUT_REF = r"outputs .* != "
_RET_C = r"returns .* != "
_HOST_OUT = r"host stdout differs"
_HOST_FX = r"host effects differ"

# class -> (description, pattern a reason of the reference check must match, pattern for the
# C-oracle check or None when the class is invisible to the C program).
CLASSES: Dict[str, Tuple[str, str, Optional[str]]] = {
    "swapped_select_arms": ("a select takes the other arm: the value it feeds is measured or returned",
                            f"{_MEAS}|{_OUT_REF}", f"{_MEAS}|{_RET_C}"),
    # a deleted Ry, or one on the complement, also skips or moves its cq_theta substitution (CR §6
    # item 1, every site substituted since cq-lvkq): the outputs differ before the rotation list does
    "flipped_predicate": ("a comparison is negated (forward and uncompute alike): the gate it controls "
                          "fires on the complement", f"{_ROT_REF}|{_MEAS}|{_OUT_REF}", f"{_ROT_C}|{_MEAS}|{_RET_C}"),
    "dropped_unc": ("a rail is freed without its uncompute: the free sees a dirty rail",
                    r"violations on our side: .*'what': 'dirty_free'", r"violations on our side: .*'what': 'dirty_free'"),
    "extra_free": ("a rail is freed twice or while live",
                   r"violations on our side: .*'what': '(bad_handle|use_after_free)'",
                   r"violations on our side: .*'what': '(bad_handle|use_after_free)'"),
    "dropped_free": ("a clean rail is never freed: kept garbage at exit",
                     r"rail\(s\) .* kept on our side that the reference does not keep", None),
    # CR §6 item 1 (cq-tt2j): a rail its sources could still clean, left live, is a leak against C too
    "leaked_garbage": ("a rail is neither uncomputed nor freed: entangled garbage live at exit",
                       r"rail\(s\) .* kept on our side that the reference does not keep",
                       r"a leak; cq-tt2j"),
    # a Ry at another angle takes no cq_theta reach of the C program's (dispatch.c, substitution
    # matches the angle): its target keeps its value and the outputs may differ first (39)
    "changed_angle": ("a rotation or phase takes another angle", f"{_ROT_REF}|{_MEAS}|{_OUT_REF}",
                      f"{_ROT_C}|{_MEAS}|{_RET_C}"),
    # with substitution the other control also moves a substitution (125: measurement 1 reads 0x3)
    "changed_control": ("a controlled rotation is controlled by another rail", f"{_ROT_REF}|{_MEAS}|{_OUT_REF}",
                        f"{_ROT_C}|{_MEAS}|{_RET_C}"),
    "dropped_rotation": ("a rotation or phase is deleted", f"{_ROT_REF}|{_MEAS}|{_OUT_REF}",
                         f"{_ROT_C}|{_MEAS}|{_RET_C}"),
    "added_rotation": ("a rotation is added", _ROT_REF, _ROT_C),
    "changed_measured_rail": ("a measurement reads another rail", _MEAS, _MEAS),
    "kloop_one_trip_short": ("a K-bounded loop runs K-1 trips: inputs with K trips get another result "
                             "and a_K", f"{_MEAS}|{_OUT_REF}", rf"{_MEAS}|{_RET_C}|a_K of loop"),
    "phase_moved_flag": ("a phase sits on another flag", _ROT_REF, _ROT_C),
    # host output (cq-e4jk, compare.py "Host output"): the tape's printed text and performed effects
    "changed_tape_output": ("a tape field takes another value: the text the tape prints changes",
                            _HOST_OUT, _HOST_OUT),
    "dropped_tape_effect": ("a tape effect entry is deleted: the host call is never performed",
                            _HOST_FX, _HOST_FX),
}

# Classes whose evaluation may FAIL on an output difference before the rotation list: each must also
# FAIL on these patterns, with substitution or else without it (module docstring, cq-lkth).
ROTATION_ONLY: Dict[str, Tuple[str, str]] = {
    "flipped_predicate": (_ROT_REF, _ROT_C),
    "changed_control": (_ROT_REF, _ROT_C),
    "dropped_rotation": (_ROT_REF, _ROT_C),
    "changed_angle": (_ROT_REF, _ROT_C),
}

# The empty output: no definition, so the build of our side fails at the link on the entry symbol.
EMPTY_PATTERN = r"violations on our side: .*'what': 'build'.*Undefined symbols"


# --------------------------------------------------------------------------------------------
# Mutants


class MutantError(Exception):
    """A mutant that cannot be built (an edit that does not apply, a text that does not parse)."""


@dataclass
class Mutant:
    id: str
    cls: str
    example: str
    edits: List[dict]
    note: str = ""


def load_mutants(path: Path = MUTANTS_FILE) -> List[Mutant]:
    data = json.loads(path.read_text())
    out, seen = [], set()
    for m in data["mutants"]:
        mu = Mutant(m["id"], m["class"], m["example"], m["edits"], m.get("note", ""))
        if mu.id in seen:
            raise MutantError(f"{path}: duplicate mutant id {mu.id}")
        if mu.cls not in CLASSES:
            raise MutantError(f"{mu.id}: unknown class {mu.cls!r} (CLASSES: {sorted(CLASSES)})")
        if not mu.edits:
            raise MutantError(f"{mu.id}: no edits")
        seen.add(mu.id)
        out.append(mu)
    return out


def apply_edits(text: str, edits: Sequence[dict], what: str = "") -> str:
    for i, e in enumerate(edits):
        old, new = e["old"], e["new"]
        n = text.count(old)
        if e.get("all"):
            if n < 1:
                raise MutantError(f"{what}: edit {i}: {old!r} does not occur")
            text = text.replace(old, new)
        else:
            if n != 1:
                raise MutantError(f"{what}: edit {i}: {old!r} occurs {n} times, not once")
            text = text.replace(old, new, 1)
    return text


def mutant_dir() -> Path:
    return report.build_dir() / "mutants"


def materialize(m: Mutant, ex: report.Example) -> Path:
    """The mutant's lowered.ll under mutant_dir()/<id>/ (the directory holds no .O1.ll, so the
    evaluator types declared clones by the example's own .O1.ll)."""
    ref = ex.reference.read_text()
    text = apply_edits(ref, m.edits, m.id)
    if text == ref:
        raise MutantError(f"{m.id}: the edits leave the reference unchanged")
    d = mutant_dir() / m.id
    d.mkdir(parents=True, exist_ok=True)
    dest = d / ex.reference.name
    if not dest.exists() or dest.read_text() != text:
        dest.write_text(text)
    r = subprocess.run([str(report.LLVM_BIN / "llvm-as"), "-o", os.devnull, str(dest)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise MutantError(f"{m.id}: the mutant does not parse: {r.stderr.strip()[:500]}")
    return dest


def empty_output(ex: report.Example) -> Path:
    d = mutant_dir() / "empty" / ex.name
    d.mkdir(parents=True, exist_ok=True)
    dest = d / ex.reference.name
    if not dest.exists() or dest.stat().st_size:
        dest.write_text("")
    return dest


# --------------------------------------------------------------------------------------------
# Judging verdicts


def _reasons(v: Verdict, oracle: str) -> List[str]:
    p = f"{oracle}: "
    return [r[len(p):] for r in v.reasons if r.startswith(p)]


def _judge(v: Verdict, ref_pat: str, c_pat: Optional[str]) -> List[str]:
    """Why `v` is not the predicted rejection ([] = rejected as predicted)."""
    why = []
    if v.s6 != report.FAIL:
        why.append(f"s6 is {v.s6}, not fail")
    elif not any(re.search(ref_pat, r, re.S) for r in _reasons(v, "ref")):
        why.append(f"no ref reason matches /{ref_pat}/")
    if c_pat is None:
        if v.c_oracle not in (report.PASS, report.FAIL):
            why.append(f"c_oracle is {v.c_oracle}")
    elif v.c_oracle != report.FAIL:
        why.append(f"c_oracle is {v.c_oracle}, not fail")
    elif not any(re.search(c_pat, r, re.S) for r in _reasons(v, "c")):
        why.append(f"no c reason matches /{c_pat}/")
    return why


@dataclass
class Outcome:
    kind: str                  # control, mutant, empty
    id: str
    example: str
    cls: str
    ok: bool
    why: List[str] = field(default_factory=list)
    verdict: Optional[Verdict] = None
    verdict_off: Optional[Verdict] = None     # substitution off (ROTATION_ONLY classes)


def _short(v: Optional[Verdict], n: int = 2) -> str:
    if v is None:
        return ""
    head = f"s6={v.s6} c={v.c_oracle} verifier={v.verifier}"
    rs = [r if len(r) < 300 else r[:300] + "..." for r in v.reasons[:n]]
    return head + "".join(f"\n      {r}" for r in rs)


def _record(store: Path, o: Outcome, lock: threading.Lock) -> None:
    line = json.dumps({"kind": o.kind, "id": o.id, "example": o.example, "class": o.cls, "ok": o.ok,
                       "why": o.why, "verdict": json.loads(to_json(o.verdict)) if o.verdict else None,
                       "verdict_subst_off": json.loads(to_json(o.verdict_off)) if o.verdict_off else None},
                      sort_keys=True)
    with lock:
        with (store / "outcomes.jsonl").open("a") as f:
            f.write(line + "\n")
        mark = "ok  " if o.ok else "FAIL"
        print(f"{mark} {o.kind:<7} {o.id:<32} {o.example:<28} {'; '.join(o.why)}", flush=True)
        if not o.ok:
            print("      " + _short(o.verdict, 3), flush=True)
            if o.verdict_off is not None:
                print("      substitution off: " + _short(o.verdict_off, 3), flush=True)


def _control(ex: report.Example, substitution: bool) -> Outcome:
    cid = ex.name if substitution else f"{ex.name}/subst-off"
    try:
        v = report.evaluate(ex, ex.reference, short_circuit=False, reference_mode=True,
                            substitution=substitution)
        # the gate (cq-g8md): a reference with uncovered targets listed is an accepted control (UNCOVERED)
        return Outcome("control", cid, ex.name, "", report.accepted(v),
                       ([] if report.green(v) else ["UNCOVERED: accepted by the gate, not green"])
                       if report.accepted(v) else ["the reference is not green against itself and its C program"], v)
    except Exception as e:  # noqa: BLE001 - reported, never green
        return Outcome("control", cid, ex.name, "", False, [f"{type(e).__name__}: {e}"])


def needs_subst_off(cls: str, v: Verdict) -> bool:
    """A ROTATION_ONLY mutant whose evaluation `v` does not FAIL on the rotation list itself."""
    return cls in ROTATION_ONLY and bool(_judge(v, *ROTATION_ONLY[cls]))


def judge_mutant(cls: str, v: Verdict, v_off: Optional[Verdict]) -> List[str]:
    """Why a mutant of class `cls` is not the predicted rejection ([] = rejected as predicted): `v`
    is its evaluation, `v_off` the one with substitution off (read only when needs_subst_off)."""
    _, ref_pat, c_pat = CLASSES[cls]
    why = _judge(v, ref_pat, c_pat)
    if needs_subst_off(cls, v):
        if v_off is None:
            why.append("the rotation list is not a reason, and no evaluation with substitution off")
        else:
            why += [f"substitution off: {w}" for w in _judge(v_off, *ROTATION_ONLY[cls])]
    return why


def _example_job(ex: report.Example, mutants: List[Mutant], empty: bool, emit) -> List[Outcome]:
    """Control, then the mutants of ex (only if the control is green; a mutant judged with
    substitution off also needs that control green), then the empty output."""
    out: List[Outcome] = []
    if mutants:
        ctl = _control(ex, True)
        emit(ctl)
        out.append(ctl)
        ctl_off: List[Outcome] = []         # the control with substitution off, once, when needed
        for m in mutants:
            if not ctl.ok:
                o = Outcome("mutant", m.id, ex.name, m.cls, False, ["unproven: the control is not green"])
            else:
                try:
                    path = materialize(m, ex)
                    v = report.evaluate(ex, path, short_circuit=False, reference_mode=True)
                    v_off = None
                    if needs_subst_off(m.cls, v):
                        if not ctl_off:
                            ctl_off.append(_control(ex, False))
                            emit(ctl_off[0])
                            out.append(ctl_off[0])
                        if ctl_off[0].ok:
                            v_off = report.evaluate(ex, path, short_circuit=False, reference_mode=True,
                                                    substitution=False)
                    why = judge_mutant(m.cls, v, v_off)
                    if needs_subst_off(m.cls, v) and not ctl_off[0].ok:
                        why.append("unproven: the control with substitution off is not green")
                    o = Outcome("mutant", m.id, ex.name, m.cls, not why, why, v, v_off)
                except Exception as e:  # noqa: BLE001
                    o = Outcome("mutant", m.id, ex.name, m.cls, False, [f"{type(e).__name__}: {e}"])
            emit(o)
            out.append(o)
    if empty:
        try:
            v = report.evaluate(ex, empty_output(ex), short_circuit=False, reference_mode=False)
            why = _judge(v, EMPTY_PATTERN, EMPTY_PATTERN)
            o = Outcome("empty", ex.name, ex.name, "empty_output", not why, why, v)
        except Exception as e:  # noqa: BLE001
            o = Outcome("empty", ex.name, ex.name, "empty_output", False, [f"{type(e).__name__}: {e}"])
        emit(o)
        out.append(o)
    return out


def _spec_lock() -> int:
    from cqcheck import speclock   # in this process, stamped (cq-8m6v)
    return speclock.check()


def _jobs() -> int:
    return max(1, int(os.environ.get("CQCHECK_JOBS", str(os.cpu_count() or 1))))


def selftest(only: Optional[Sequence[str]] = None, empty: Optional[Sequence[str]] = None) -> int:
    """The self-test (module docstring). With no arguments (the CLI): every mutant and the empty
    output for every example. `only` restricts the mutants to these ids and `empty` the empty
    output to these examples ([] = none); a restricted run is iteration, never the acceptance, and
    says so."""
    if _spec_lock() != 0:
        return 1
    try:
        mutants = load_mutants()
        every = report.all_examples()
        by_name = {e.name: e for e in every}
        for m in mutants:
            if m.example not in by_name:
                raise MutantError(f"{m.id}: no example {m.example}")
            materialize(m, by_name[m.example])      # every mutant applies and parses, run or not
    except (MutantError, ValueError, KeyError, RuntimeError) as e:
        print(f"cq: selftest: {e}", file=sys.stderr)
        return 1
    missing = sorted(set(CLASSES) - {m.cls for m in mutants})
    restricted = only is not None or empty is not None
    if only is not None:
        unknown = set(only) - {m.id for m in mutants}
        if unknown:
            print(f"cq: selftest: unknown mutant ids {sorted(unknown)}", file=sys.stderr)
            return 1
        mutants = [m for m in mutants if m.id in set(only)]
    empty_set = {e.name for e in every} if empty is None else \
        {e.name for e in report.resolve_examples(empty)} if empty else set()

    store = report.out_dir() / "selftest"
    store.mkdir(parents=True, exist_ok=True)
    (store / "outcomes.jsonl").write_text("")
    lock = threading.Lock()
    by_ex: Dict[str, List[Mutant]] = {}
    for m in mutants:
        by_ex.setdefault(m.example, []).append(m)
    todo = [e for e in every if e.name in by_ex or e.name in empty_set]
    # mutant examples first: they are the short part, and the long tail is the empty outputs
    todo.sort(key=lambda e: (e.name not in by_ex, int(e.number)))
    print(f"selftest: {len(mutants)} mutants over {len(by_ex)} references, empty output for "
          f"{len(empty_set)} of {len(every)} examples, {_jobs()} jobs", flush=True)
    outcomes: List[Outcome] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=_jobs()) as pool:
        futs = [pool.submit(_example_job, e, by_ex.get(e.name, []), e.name in empty_set,
                            lambda o: _record(store, o, lock)) for e in todo]
        for f in futs:
            outcomes += f.result()

    print(summary(outcomes, missing, len(every), restricted))
    ok = all(o.ok for o in outcomes) and not missing and \
        sum(1 for o in outcomes if o.kind == "empty") == len(empty_set)
    return 0 if ok else 1


def summary(outcomes: Sequence[Outcome], missing: Sequence[str], n_examples: int, restricted: bool) -> str:
    lines = ["", "class                    mutants  rejected  examples"]
    for cls in CLASSES:
        ms = [o for o in outcomes if o.kind == "mutant" and o.cls == cls]
        lines.append(f"{cls:<24} {len(ms):>7}  {sum(o.ok for o in ms):>8}  "
                     f"{', '.join(sorted({o.example.split('_')[0] for o in ms}, key=int))}")
    ctl = [o for o in outcomes if o.kind == "control"]
    emp = [o for o in outcomes if o.kind == "empty"]
    lines.append(f"controls green: {sum(o.ok for o in ctl)}/{len(ctl)}")
    lines.append(f"empty output rejected: {sum(o.ok for o in emp)}/{len(emp)} "
                 f"(corpus: {n_examples} examples)")
    if missing:
        lines.append(f"classes without a mutant: {', '.join(missing)}")
    bad = [o for o in outcomes if not o.ok]
    if bad:
        lines.append(f"not as predicted: {len(bad)}: " + ", ".join(f"{o.kind}:{o.id}" for o in bad))
    if restricted:
        lines.append("restricted run (only/empty given): not the self-test's acceptance")
    return "\n".join(lines)


# --------------------------------------------------------------------------------------------
# Baseline


def baseline(only: Optional[Sequence[str]] = None) -> int:
    """Every reference against itself and against its C program (module docstring). `only`
    restricts the examples (iteration; the CLI gives none)."""
    if _spec_lock() != 0:
        return 1
    try:
        examples = report.resolve_examples(only) if only else report.all_examples()
    except (ValueError, RuntimeError) as e:
        print(e, file=sys.stderr)
        return 2
    store = report.out_dir() / "baseline"
    store.mkdir(parents=True, exist_ok=True)
    lock = threading.Lock()

    def one(ex: report.Example) -> Verdict:
        try:
            v = report.evaluate(ex, ex.reference, short_circuit=False, reference_mode=True)
        except Exception as e:  # noqa: BLE001 - an ERROR verdict with its reason, never dropped
            v = Verdict(ex.name, report.ERROR, report.ERROR, report.ERROR, None,
                        [f"baseline: {type(e).__name__}: {e}"])
        with lock:
            (store / f"{ex.name}.json").write_text(to_json(v) + "\n")
            st = report.state(v)
            unc = report.uncovered(v) if st == report.UNCOVERED else []
            print(f"{'ok  ' if st == report.GREEN else 'UNCOVERED' if unc else 'FAIL'} {ex.name}  s6={v.s6} "
                  f"c={v.c_oracle} verifier={v.verifier}"
                  + (f"  {unc[0][:200]}" if unc else f"  {v.reasons[0][:200]}" if v.reasons and st != report.GREEN else ""),
                  flush=True)
        return v

    with concurrent.futures.ThreadPoolExecutor(max_workers=_jobs()) as pool:
        verdicts = list(pool.map(one, examples))
    print(report.format_table(verdicts))
    print(f"baseline verdicts: {store}")
    if len(verdicts) != len(examples):
        print(f"cq: {len(examples)} examples, {len(verdicts)} verdicts", file=sys.stderr)
        return 1
    return 0 if all(report.accepted(v) for v in verdicts) else 1       # the gate: UNCOVERED accepted
