#!/usr/bin/env python3
"""tests/chk-kept (cq-71g9): rails CR §6 item 1 names as kept, against the leak rule.

Each GOOD program is green under `cqcheck user`: a no-twin clone's {res, flags} result (rule 18; q1, q4b, q4c), a loading
clone's result a memory version change overtook before its twin (rule 18; q5, and q6 through a clone whose name has `_b`
bounds, cq-usir7), the
dispatch's final copy-out (rule 19; q3), a no-twin table clone's result through its pop-only twin (§1.4; e_rail, r3),
rule 14's kept overflow predicate a_K of a K-loop in a clone called in an arm the C program does not take (q7, cq-1leyz),
rule 20's kept overflow predicate n > K2 of a rail-sized allocation in such a clone (q8, cq-0ldab), rule 22's unpredicated
n > K2 of a memset and a memcpy whose length is a rail (q9, cq-dl7da), and the same under an arm's predicate c, the kept
(n > K2) & c read as an a_K by kept_ak_module (q10, cq-cwl9g), and calloc's kept or_i1(overflow, n*s > K2) in such a
clone (q11, owner 2026-11-12 cq-mrdkr).
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


def lost_rd_twin(fn, nth, text):
    """The nth call of rd's twin in fn is lost, and the free of its result (review, cq-yz4hw, cq-41lsp, cq-0r50n)."""
    def edit(body):
        ms = list(re.finditer(r"  call void @__cq_q_rd_1(_ctl)?_unc\(([^)]*)\)\n", body))
        m = ms[nth]
        args = re.findall(r"i32 (%\w+)", m.group(2))
        r = args[1] if m.group(1) else args[0]
        return sub1(rf"  call void @cqrt_free\(i32 {r}\)\n", "", body.replace(m.group(0), ""))
    return in_fn(fn, edit, text)


def every_rd_twin_lost(text):
    """Every call of rd's twin in the module is lost, so canonicalization drops its definition (cq-534kh)."""
    out, cur = [], None
    lines = text.splitlines(True)
    drop = set()
    for i, ln in enumerate(lines):
        m = re.match(r"\s+call void @__cq_q_rd_1(_ctl)?_unc\(([^)]*)\)", ln)
        if m:
            args = re.findall(r"i32 (%\w+)", m.group(2))
            r = args[1] if m.group(1) else args[0]
            drop.add(i)
            for j in range(i + 1, len(lines)):
                if lines[j].startswith("}"):
                    break
                if lines[j].strip() == f"call void @cqrt_free(i32 {r})":
                    drop.add(j)
                    break
    assert drop
    return "".join(ln for i, ln in enumerate(lines) if i not in drop)


def kept_chain_pred(text):
    """A chain predicate of the K-loop that is not a_K (it controls the trip's selects and feeds a_K) loses its _unc and
    its free: an i1 left live that the a_K identification must not take (cq-1leyz)."""
    def edit(body):
        m = re.search(r"  call void @cqrt_and_i1\(i32 %\d+, i32 %\d+, i32 (%\d+)\)\n  call void @cqrt_free\(i32 \1\)\n", body)
        return body.replace(m.group(0), "")
    return in_fn("__cq_q_steps_1_ctl", edit, text)


def k2_lookalike(text):
    """A second icmp_ugt_i64_hl(n, K2) of the allocation's size, just before the kept one, left live: it reads what the
    kept n > K2 reads, but no allocation follows it, so the n > K2 identification must not take it (cq-0ldab)."""
    def edit(body):
        return sub1(r"(  %\d+ = call i32 @cq_template_icmp_ugt_i64_hl\(i32 (%\d+), i64 4096\)\n)",
                    r"  %cq.look = call i32 @cq_template_icmp_ugt_i64_hl(i32 \2, i64 4096)\n\1", body)
    return in_fn("__cq_q_fill_1_ctl", edit, text)


def k2_trips_lookalike(text):
    """A second icmp_ugt_i64_hl(n, K2) of the memset's length, just before the kept one, left live: it reads what the kept
    n > K2 reads, but the intrinsic's K2 trips do not follow it, so the rule-22 n > K2 identification must not take it
    (cq-dl7da)."""
    def edit(body):
        return sub1(r"(  %\d+ = call i32 @cq_template_icmp_ugt_i64_hl\(i32 (%\d+), i64 4096\)\n  %\d+ = call i32 @cqrt_alloc_i8\()",
                    r"  %cq.look = call i32 @cq_template_icmp_ugt_i64_hl(i32 \2, i64 4096)\n\1", body)
    return in_fn("q9", edit, text)


def calloc_or_lookalike(text):
    """An or_i1 of the overflow and the compare into a second fresh i1 rail, just before the kept one, left live: it reads
    what the kept or_i1(overflow, n*s > K2) reads, but the allocation does not follow it, so the calloc n > K2
    identification must not take it (cq-mrdkr)."""
    def edit(body):
        return sub1(r"(  (%\d+) = call i32 @cqrt_alloc_i1\(i1 false\)\n  call void @cqrt_or_i1\(i32 (%\d+), i32 (%\d+), i32 \2\)\n)",
                    r"  %cq.look = call i32 @cqrt_alloc_i1(i1 false)\n  call void @cqrt_or_i1(i32 \3, i32 \4, i32 %cq.look)\n\1",
                    body)
    return in_fn("__cq_q_fillc_1_ctl", edit, text)


def calloc_or_read(text):
    """The kept or_i1(overflow, n*s > K2) itself, also read after the allocation (xor-ed into a scratch rail and back,
    the scratch freed at 0: its value unchanged, still not known): a rail something reads is no kept n > K2, so it is a
    leak (cq-mrdkr)."""
    def edit(body):
        return sub1(r"(  (%\d+) = call i32 @cqrt_alloc_i1\(i1 false\)\n  call void @cqrt_or_i1\(i32 %\d+, i32 %\d+, i32 \2\)\n"
                    r"(?:  call void @[-\w.$]+\([^\n]*\n)*?  %\d+ = call ptr @__cq_alloc\(i64 4096, i64 16\)\n)",
                    r"\1  %cq.rd = call i32 @cqrt_alloc_i1(i1 false)\n  call void @cqrt_xor_i1(i32 \2, i32 %cq.rd)\n"
                    r"  call void @cqrt_xor_i1(i32 \2, i32 %cq.rd)\n  call void @cqrt_free(i32 %cq.rd)\n", body)
    out = in_fn("__cq_q_fillc_1_ctl", edit, text)
    return out if "declare void @cqrt_xor_i1(" in out else out + "declare void @cqrt_xor_i1(i32, i32)\n"


def lost_twin(fn, twin, text):
    """A call of a loading clone loses its twin though nothing overtakes it, its result left live."""
    def edit(body):
        m = re.search(rf"  call void @{twin}\(i32 %\d+, i32 (%\d+),[^\n]*\n", body)
        return body.replace(m.group(0), "").replace(f"  call void @cqrt_free(i32 {m.group(1)})\n", "")
    return in_fn(fn, edit, text)


GOOD = [(SRC / "q1", "q1"), (SRC / "q1c", "q1c"), (SRC / "q3", "q3"), (SRC / "q4", "q4b"), (SRC / "q4", "q4c"), (SRC / "q5", "q5"), (SRC / "q6", "q6"),
        (SRC / "q7", "q7"), (SRC / "q8", "q8"), (SRC / "q9", "q9"), (SRC / "q10", "q10"), (SRC / "q11", "q11"),
        (SRC / "p3", "p3"), (SRC / "p4", "p4"), (SRC / "p5", "p5"), (SRC / "p6", "p6"),
        (CALLS / "table_twin_measure", "e_rail"), (CALLS / "twin_rot_in_loop", "r3")]
MUTANTS = [
    ("rule18_dropped_twin_struct", CALLS / "partial_flags", "sc_measure", dropped_twin_struct),
    ("rule18_no_twin_inner", SRC / "q4", "q4b", no_twin_inner),
    ("t14_empty_twin_rail", CALLS / "table_twin_measure", "e_rail", lambda t: empty_twin("__cq_q_h_11_t_ctl_unc", t)),
    # q1's pointer is a volatile load, an address rail (rules 20, 24; since e8788b4): the dispatch calls _t_ctl and its twin, never
    # _t_unc, which only a classical pointer reaches (rule 19): q1c
    ("t14_empty_twin_ptr", SRC / "q1", "q1", lambda t: empty_twin("__cq_q_inc_1_t_ctl_unc", t)),
    ("t14_empty_twin_classical_ptr", SRC / "q1c", "q1c", lambda t: empty_twin("__cq_q_inc_1_t_unc", t)),
    # a classical-path measurement leaves the twin (Q3, rulings3 E): this `_t` is off the no-twin list
    ("t14_empty_twin_classical_measure", CALLS / "table_twin_measure", "e_cl", lambda t: empty_twin("__cq_q_g_11_t_unc", t)),
    ("rule19_second_copy", SRC / "q3", "q3", second_copy),
    # rule 18, cq-xbpw6: the C program overtakes no call here, the store is in the other arm, though it is emitted before the twin
    ("rule18_lost_twin_other_arm", CALLS / "twin_other_arm_store", "other_arm",
     lambda t: lost_twin("other_arm", "__cq_q_rd_1_ctl_unc", t)),
    # rule 18: the C program overtakes one of the two calls, and a second one lost its twin
    ("rule18_lost_twin_beside_overtaken", SRC / "q5", "q5", lambda t: lost_twin("q5", "__cq_q_rd_1_ctl_unc", t)),
    # cq-usir7: the same with a bounded clone (§1.4 `_b`): the second arm's call loses its twin
    ("rule18_lost_twin_bounded_clone", SRC / "q6", "q6", lambda t: lost_twin("q6", "__cq_q_rd_1_b3_ctl_unc", t)),
    # cq-1leyz: a K-loop's chain predicate other than a_K left live is still a leak
    ("rule14_kept_chain_pred", SRC / "q7", "q7", kept_chain_pred),
    # cq-0ldab: an i1 that looks like rule 20's n > K2 but precedes no allocation, left live, is still a leak
    ("rule20_k2_lookalike", SRC / "q8", "q8", k2_lookalike),
    # cq-dl7da: an i1 that looks like rule 22's n > K2 but the intrinsic's K2 trips do not follow, left live, is still a leak
    ("rule22_k2_lookalike", SRC / "q9", "q9", k2_trips_lookalike),
    # cq-mrdkr: calloc's or_i1(overflow, n*s > K2) into a rail no allocation follows, or the kept one also read, is a leak
    ("rule20_calloc_or_lookalike", SRC / "q11", "q11", calloc_or_lookalike),
    ("rule20_calloc_or_read", SRC / "q11", "q11", calloc_or_read),
    # cq-yz4hw: a classical call of rd is overtaken; the quantum call after the store is not
    ("rule18_lost_twin_after_store", SRC / "p3", "p3", lambda t: lost_rd_twin("p3", 0, t)),
    # cq-534kh: no store in the program, and no twin left to define
    ("rule18_every_twin_lost_no_store", SRC / "p4", "p4", every_rd_twin_lost),
    # cq-41lsp: the store comes after the consumer is measured; what the outcome feeds reads no rail
    ("rule18_lost_twin_before_store_measured", SRC / "p5", "p5", lambda t: lost_rd_twin("p5", 0, t)),
    # cq-0r50n: the store ends the trip; the next trip's readers read the next call's result
    ("rule18_lost_twin_in_loop", SRC / "p6", "p6", lambda t: lost_rd_twin("p6", 0, t)),
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
