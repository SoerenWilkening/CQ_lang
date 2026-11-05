#!/usr/bin/env python3
"""tests/bus-alloc: the shapes of rules 16 Allocation, 20 Allocation, 22 and §0 K2 no corpus example witnesses.

probes/alloc.O1.ll (clang -O1 -include CQ.h of alloc.c): cq-lower and cq-verify accept it, the entry's structural facts
hold, and the entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
probes/k2.O1.ll: K2's resolution, structural only: a rail size or length with no bound has inputs past any K2 the
sampler cannot compare against C.
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
