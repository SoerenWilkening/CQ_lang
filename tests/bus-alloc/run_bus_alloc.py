#!/usr/bin/env python3
"""tests/bus-alloc: the shapes of rules 16 Allocation, 20 Allocation, 22 and §0 K2 no corpus example witnesses.

probes/alloc.O1.ll (clang -O1 -include CQ.h of alloc.c): cq-lower and cq-verify accept it, the entry's structural facts
hold, and the entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
probes/k2.O1.ll: K2's resolution, structural only: a rail size or length with no bound has inputs past any K2 the
sampler cannot compare against C.
probes/alloc_nobuiltin.O1.ll (clang -O1 -fno-builtin -include CQ.h of alloc_nobuiltin.c, cq-15amv): malloc, calloc, realloc
and free with no allockind, the allocation by its rule-16 name alone, at rail sizes, the result compared with NULL; each
entry has a __cq_alloc and is §6-equal to its C program (the full `cqcheck user`).
probes/inplace.O1.ll, probes/inplace_loop.O1.ll: rule 5's in-place form, the shapes that stay the form and the shapes that
are a kept store instead; each entry §6-equal to its C program (`--light`).
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
OUT = ROOT / "build" / "tests" / "bus-alloc" / "out"

ALLOC = r"call ptr @__cq_alloc\(i64 %s, i64 %s\)"
OVERFLOW = r"@cq_template_icmp_ugt_i64_hl\("
# entry -> (patterns that must occur, patterns that must not)
ENTRIES = {
    "p_calloc": ([ALLOC % ("16", "16")], [OVERFLOW]),
    "p_calloc_rail": ([ALLOC % ("4096", "16")], [OVERFLOW]),   # (x & 3) + 1 is at most 4 elements: B <= K2
    "p_aligned": ([ALLOC % ("64", "64")], []),
    "p_vla_rail": ([ALLOC % ("4096", "16")], [OVERFLOW, "stacksave", "stackrestore"]),
    "p_copy_runtime": (["@cqrt_qram_load_i8_hl\\(", "@cqrt_qram_store_i8_hl\\("], []),
    "p_copy_pred": (["@cqrt_qram_load_i8_hl_controlled\\(", "@cqrt_qram_store_i8_hl_controlled\\("], []),
    "p_copy_len_pred": (["@cqrt_and_i1\\(", "@cq_template_icmp_ugt_i64_hl_unc\\("], []),
    "p_set_rail": (["@cqrt_qram_store_i8_hl_controlled\\("], []),
    "p_set_pred": (["@cqrt_qram_store_i8_controlled\\(", "@cq_template_add_i64_hl_unc\\("], ["@cqrt_alloc_i8\\(i8 7\\).*\n.*\n.*@cqrt_alloc_i8\\(i8 7\\)"]),
    "p_copy_rails": (["@cqrt_qram_load_i8\\(", "@cqrt_qram_store_i8\\("], []),
    "p_move": (["@cqrt_push\\(", "@cqrt_pop\\("], []),
    # The length's load copy: un-copied and freed before the copy's first store (rule 5 sentence 1).
    "p_len_loaded": ([r"(?s)@cqrt_qram_load_i8_unc\(i32 (%\d+),[^\n]*\n\s*call void @cqrt_free\(i32 \1\)(?:(?!@cqrt_qram_load_i8_unc).)*"
                      r"@cqrt_pop\(\)"], []),
    "p_realloc_pred": ([ALLOC % ("16", "16"), "@cqrt_qram_load_i64_hl_controlled\\("], []),
    "p_free_pred": ([], ["@free\\("]),
    "p_vla_loop": ([], ["stacksave", "stackrestore"]),
}
# cq-15amv: the allocation by name (no allockind); entry -> its __cq_alloc calls (size, align).
NOBUILTIN = {
    "n_calloc_count": [("4096", "16")],
    "n_calloc_size": [("4096", "16")],
    "n_calloc_both": [("4096", "16")],
    "n_calloc_wide": [("4096", "16")],
    "n_malloc": [("4096", "16")],
    "n_malloc_fold": [("4096", "16")],   # cq-yt5lz: the result classical over a == NULL, no measurement
    "n_realloc": [("4", "16"), ("4096", "16")],
}
# Rule 5 In-place form: entry -> does its body hold the form's swaps at i32?
SWAP = r"@cqrt_qram_swap_i32"
INPLACE = {
    "inplace": {
        "ip_read_add": True,             # cq-q148y: a plain load's copy for the reader, the form at the store
        "ip_read_theta": False,          # cq-q148y: the reader needs the swap-in before a bus load: a kept store
        "ip_read_theta_nobus": True,
        "ip_before_prev": False,         # cq-i2gdy: a step before the preceding store is not in the interval
        "ip_before_prev_change": False,
        "ip_change_reader": False,       # the second change's address is not computed before the first: d = 0
        "ip_change_reader_d": True,
        "ip_prev_form_reader": True,
        "ip_loop_k": False,              # cq-5cie9: the store runs again without its load
        "ip_loop_classical": False,
        "ip_loop_classical_i": False,
        "ip_narrow_prev": False,         # cq-6cup9: the preceding store does not cover the wide cell
        "ip_wide_prev": True,
        "ip_wide_prev_change": False,    # a change of the interval may have written the high cells
        "ip_wide_prev_change_q": False,
    },
    "inplace_loop": {"ip_loop_theta_out": False, "ip_loop_theta_other": False, "ip_loop_theta_measure": False,
                     "ip_loop_theta_after": False},
}
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


def body(module, fn):
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def lower(a, src, out, *flags):
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", *flags, "-S", str(src), "-o", str(out)],
                       capture_output=True, text=True)
    if r.returncode:
        return "cq-lower: " + r.stderr.strip()
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output", str(out)],
                       capture_output=True, text=True)
    return "cq-verify: " + v.stderr.strip() if v.returncode else None




def check_k2(a):
    bad = []
    src = PROBES / "k2.O1.ll"

    def bodies(*flags):
        out = OUT / "k2.lowered.ll"
        e = lower(a, src, out, *flags)
        if e:
            bad.append(e)
            return None
        return out.read_text()

    t = bodies()
    if t:
        # CQ_K2(k_used, 32) over the default; the overflow predicate kept with no _unc.
        for fn, k in (("k_used", 32), ("k_plain", 4096)):
            b = body(t, fn)
            if f"@__cq_alloc(i64 {k}, i64 16)" not in b or f"icmp_ugt_i64_hl(i32 %" not in b or "icmp_ugt_i64_hl_unc" in b:
                bad.append(f"{fn}: not K2 = {k} with a kept n > K2")
        b = body(t, "k_len")
        if "icmp eq i64 %" not in b or ", 4096\n" not in b:
            bad.append("k_len: the copy's trip bound is not K2 = 4096")
        b = body(t, "k_len_bound")
        if ", 7\n" not in b or "i64 4096" in b:
            bad.append("k_len_bound: the copy's trip bound is not B = 7, with no overflow predicate")
        b = body(t, "k_len_pred")
        # cq-fti6: the kept overflow is (n > K2) & c, the raw compare undone before the load loop
        if not re.search(r"(?s)icmp_ugt_i64_hl\(i32 %\d+, i64 4096\).*?@cqrt_and_i1\(.*?icmp_ugt_i64_hl_unc\(i32 %\d+, i32 %\d+, i64 4096\)", b):
            bad.append("k_len_pred: the kept overflow is not (n > K2) & c with the raw compare undone")
        b = body(t, "k_align")
        if "@__cq_alloc(i64 64, i64 4096)" not in b:
            bad.append("k_align: a rail alignment is not K2 rounded up to a power of two")
    t = bodies("-cq-k2-default=100")
    if t:
        b = body(t, "k_plain")
        if "@__cq_alloc(i64 100, i64 16)" not in b:
            bad.append("-cq-k2-default does not reach k_plain")
        if "@__cq_alloc(i64 32, i64 16)" not in body(t, "k_used"):
            bad.append("CQ_K2 does not win over -cq-k2-default")
        if "@__cq_alloc(i64 64, i64 128)" not in body(t, "k_align"):
            bad.append("k_align: K2 = 100 does not round up to 128")
    t = bodies("-cq-k2=k_used=64", "-cq-k2-default=100")
    if t and "@__cq_alloc(i64 64, i64 16)" not in body(t, "k_used"):
        bad.append("-cq-k2 does not win over CQ_K2")
    return bad


def check_inplace(a):
    failures = 0
    for name, entries in INPLACE.items():
        chosen = [fn for fn in entries if not a.entry or fn in a.entry]
        if not chosen:
            continue
        src, lowered = PROBES / f"{name}.O1.ll", OUT / f"{name}.lowered.ll"
        e = lower(a, src, lowered)
        if e:
            print(f"FAIL {name}: {e}")
            failures += len(chosen)
            continue
        text = lowered.read_text()
        for fn in chosen:
            b = body(text, fn)
            why = []
            if not b:
                why.append("no lowered body")
            if SURFACE.search(b):
                why.append("a CQ.h surface call is left")
            if bool(re.search(SWAP, b)) != entries[fn]:
                why.append("the form's swaps " + ("are missing" if entries[fn] else "are there"))
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(lowered),
                                "--entry", fn, "--light"], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1][:400])
            print(("FAIL " if why else "ok   ") + fn + ("" if not why else ": " + "; ".join(why)))
            failures += bool(why)
    return failures


def check_nobuiltin(a):
    failures = 0
    chosen = [fn for fn in NOBUILTIN if not a.entry or fn in a.entry]
    if not chosen:
        return 0
    src, lowered = PROBES / "alloc_nobuiltin.O1.ll", OUT / "alloc_nobuiltin.lowered.ll"
    e = lower(a, src, lowered)
    if e:
        print(f"FAIL alloc_nobuiltin: {e}")
        return len(chosen)
    text = lowered.read_text()
    for fn in chosen:
        b = body(text, fn)
        why = []
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        why += [f"no {ALLOC % sa}" for sa in NOBUILTIN[fn] if not re.search(ALLOC % sa, b)]
        if re.search(r"call [^@]*@(malloc|calloc|realloc|free)\(", b):
            why.append("a host allocation call is left")
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(lowered),
                            "--entry", fn], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1][:400])
        print(("FAIL " if why else "ok   ") + fn + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return failures


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    failures = 0
    for why in check_k2(a):
        print("FAIL k2: " + why)
        failures += 1
    failures += check_inplace(a)
    failures += check_nobuiltin(a)
    src, lowered = PROBES / "alloc.O1.ll", OUT / "alloc.lowered.ll"
    e = lower(a, src, lowered)
    if e:
        print("FAIL " + e)
        return 1
    text = lowered.read_text()
    for fn, (must, mustnot) in ENTRIES.items():
        if a.entry and fn not in a.entry:
            continue
        b = body(text, fn)
        why = []
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        why += [f"no {p}" for p in must if not re.search(p, b)]
        why += [f"has {p}" for p in mustnot if re.search(p, b)]
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(lowered),
                            "--entry", fn, "--samples", "40"], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1][:400])
        print(("FAIL " if why else "ok   ") + fn + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
