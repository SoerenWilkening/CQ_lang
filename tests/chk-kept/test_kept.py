#!/usr/bin/env python3
"""tests/chk-kept (cq-71g9): rails CR §6 item 1 names as kept, against the leak rule.

Each GOOD program is green under `cqcheck user`: a no-twin clone's {res, flags} result (rule 18; q1, q4b, q4c), a loading
clone's result a memory version change overtook before its twin (rule 18; q5), the
dispatch's final copy-out (rule 19; q3), a no-twin table clone's result through its pop-only twin (§1.4; e_rail, r3).
Each MUTANT is a real leak of that shape, and must be rejected by the leak rule, not merely rejected (rule24_*: by the
effect comparison).
"""
import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(__file__).parent / "src"
CALLS = ROOT / "tests" / "calls" / "probes"
SAMPLES = 16


def fn_re(name):
    return re.compile(rf"(?ms)^define [^\n]*@{re.escape(name)}\(.*?^}}\n")


def sub1(pat, rep, text):
    out, n = re.subn(pat, rep, text, count=1)
    assert n == 1, f"mutant pattern did not apply: {pat}"
    return out


def in_fn(name, edit, text):
    m = fn_re(name).search(text)
    assert m, f"no function {name}"
    return text[:m.start()] + edit(m.group(0)) + text[m.end():]


def empty_twin(name, text):
    """A table twin that should zero and free its result does nothing."""
    def edit(body):
        return body[:body.index("{\n") + 2] + "  ret void\n}\n"
    return in_fn(name, edit, text)


def dropped_twin_struct(text):
    """A pure {res, flags} clone keeps a twin by rule 18; the caller loses the call, finalize would drop the twin."""
    text = fn_re("__cq_q_scaled_10_unc").sub("", text)
    def edit(body):
        while True:
            m = re.search(r"  call void @__cq_q_scaled_10_unc\(i32 (%\d+), i32 (%\d+),[^\n]*\n", body)
            if not m:
                return body
            body = body.replace(m.group(0), "")
            body = body.replace(f"  call void @cqrt_free(i32 {m.group(1)})\n", "")
            body = body.replace(f"  call void @cqrt_free(i32 {m.group(2)})\n", "")
    return in_fn("sc_twice", edit, in_fn("sc_measure", edit, text))


def no_twin_inner(text):
    """A no-twin clone's results are kept; its intermediate rails are not: one left uncomputed."""
    def edit(body):
        m = re.search(r"  call void @cq_template_add_i32_unc\(i32 (%\d+),[^\n]*\n", body)
        return body.replace(m.group(0), "").replace(f"  call void @cqrt_free(i32 {m.group(1)})\n", "")
    # the clone suffix is a numbering of the pass, not a property: find f's _ctl clone by shape
    return in_fn(re.search(r"@(__cq_q_f_\d+_ctl)\(", text).group(1), edit, text)


def second_copy(text):
    """Rule 19 names one copy-out of the dispatch's value: a second one is nobody's."""
    def edit(body):
        return sub1(r"(  (%\d+) = call i32 @cqrt_alloc_i32\(i32 0\)\n)(  call void @cqrt_copy_i32\(i32 (%\d+), i32 \2\)\n"
                    r"  call void @cq_template_select_i32_unc\(i32 \4,)",
                    r"  %cq.extra = call i32 @cqrt_alloc_i32(i32 0)\n  call void @cqrt_copy_i32(i32 \4, i32 %cq.extra)\n\1\3",
                    body)
    return in_fn("q3", edit, text)


def lost_twin(fn, twin, text):
    """A call of a loading clone loses its twin though nothing overtakes it, its result left live."""
    def edit(body):
        m = re.search(rf"  call void @{twin}\(i32 %\d+, i32 (%\d+),[^\n]*\n", body)
        return body.replace(m.group(0), "").replace(f"  call void @cqrt_free(i32 {m.group(1)})\n", "")
    return in_fn(fn, edit, text)


GOOD = [(SRC / "q1", "q1"), (SRC / "q3", "q3"), (SRC / "q4", "q4b"), (SRC / "q4", "q4c"), (SRC / "q5", "q5"),
        (CALLS / "table_twin_measure", "e_rail"), (CALLS / "twin_rot_in_loop", "r3")]
MUTANTS = [
    ("rule18_dropped_twin_struct", CALLS / "partial_flags", "sc_measure", dropped_twin_struct),
    ("rule18_no_twin_inner", SRC / "q4", "q4b", no_twin_inner),
    ("t14_empty_twin_rail", CALLS / "table_twin_measure", "e_rail", lambda t: empty_twin("__cq_q_h_11_t_ctl_unc", t)),
    ("t14_empty_twin_ptr", SRC / "q1", "q1", lambda t: empty_twin("__cq_q_inc_1_t_unc", t)),
    # a classical-path measurement leaves the twin (Q3, rulings3 E): this `_t` is off the no-twin list
    ("t14_empty_twin_classical_measure", CALLS / "table_twin_measure", "e_cl", lambda t: empty_twin("__cq_q_g_11_t_unc", t)),
    ("rule19_second_copy", SRC / "q3", "q3", second_copy),
    # rule 18, cq-xbpw6: the C program overtakes no call here, the store is in the other arm, though it is emitted before the twin
    ("rule18_lost_twin_other_arm", CALLS / "twin_other_arm_store", "other_arm",
     lambda t: lost_twin("other_arm", "__cq_q_rd_1_ctl_unc", t)),
    # rule 18: the C program overtakes one of the two calls, and a second one lost its twin
    ("rule18_lost_twin_beside_overtaken", SRC / "q5", "q5", lambda t: lost_twin("q5", "__cq_q_rd_1_ctl_unc", t)),
    # an observable volatile store is a bus store (cq-6b2i1): one lost is the bytes lost; nothing but the memory comparison
    # sees it, the entry returns nothing
    ("rule24_lost_volatile_store", ROOT / "tests" / "eff-conc" / "probes" / "vol_observable", "vol_quantum_observable",
     lambda t: sub1(r"  call void @cqrt_qram_store_i32_hl\(i32 %\d+, i64 ptrtoint \(ptr @sink to i64\), i32 %\d+\)\n", "", t)),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--only", help="regex over the case names")
    a = ap.parse_args()
    bad = 0

    def lower(stem, tmp):
        out = Path(tmp) / (stem.name + ".lowered.ll")
        subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S",
                        str(stem) + ".O1.ll", "-o", str(out)], check=True)
        return out

    def user(stem, low, entry):
        r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(stem) + ".O1.ll", "--lowered", str(low),
                            "--entry", entry, "--samples", str(SAMPLES)],
                           cwd=ROOT / "checker", capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr

    with tempfile.TemporaryDirectory() as tmp:
        for stem, entry in GOOD:
            if a.only and not re.search(a.only, entry):
                continue
            rc, text = user(stem, lower(stem, tmp), entry)
            print(("ok   " if rc == 0 else "FAIL ") + f"good {entry}" + ("" if rc == 0 else ": " + text.strip()[-400:]))
            bad += rc != 0
        for name, stem, entry, mutate in MUTANTS:
            if a.only and not re.search(a.only, name):
                continue
            low = lower(stem, tmp)
            low.write_text(mutate(low.read_text()))
            rc, text = user(stem, low, entry)
            good = rc == 1 and (("memory output" if name.startswith("rule24") else "a leak; cq-tt2j") in text)
            print(("ok   " if good else "FAIL ") + f"mutant {name}" + ("" if good else f": exit {rc}: " + text.strip()[-400:]))
            bad += not good
    print("FAILED" if bad else "ok")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
