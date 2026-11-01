#!/usr/bin/env python3
"""Differential test of checker/rt/tmpl_cmp.c against native x86-64 code (cq-w0-tmpl-cmp).

Generates native.ll (one function per op and width: the LLVM IR operation itself, operands and
result through memory) and table.inc, compiles native.ll with clang-19 -O1, links it with
harness.c and the family source, and runs the harness. See harness.c for the input classes.

Widths: every corpus width of these ops (icmp i1 i8 i32 i64 i128; select i8 i32 i64 i128 f32 f64
f80; min/max, abs, overflow, sat at i32/i64), plus i1, i7, i100, and i16, i256, f16 and bf16 for every op
the width applies to.

Self-test: every mutant in MUTANTS (one textual fault in a copy of tmpl_cmp.c) must be rejected by
the same harness before the real run counts. A mutant run stops at its first disagreement
(harness --first): the verdict is the same as a full run's, at a fraction of the time.

Usage: difftest.py [--clang CLANG] [--work DIR]
"""
import argparse
import os
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RT = ROOT / "checker" / "rt"

INT_WIDTHS = [1, 7, 8, 16, 32, 64, 100, 128, 256]
FP_TYPES = {"f16": (16, "half"), "bf16": (16, "bfloat"), "f32": (32, "float"), "f64": (64, "double"), "f80": (80, "x86_fp80")}
PREDS = ["eq", "ne", "ugt", "uge", "ult", "ule", "sgt", "sge", "slt", "sle"]
BINOPS = {  # template op -> IR producing %r (iW) or %f (i1) from %x, %y
    "smax": ("llvm.smax", "val"), "smin": ("llvm.smin", "val"),
    "umax": ("llvm.umax", "val"), "umin": ("llvm.umin", "val"),
    "uadd_sat": ("llvm.uadd.sat", "val"), "usub_sat": ("llvm.usub.sat", "val"),
    "sadd_sat": ("llvm.sadd.sat", "val"), "ssub_sat": ("llvm.ssub.sat", "val"),
    "uadd_overflow": ("llvm.uadd.with.overflow", "ovf"), "sadd_overflow": ("llvm.sadd.with.overflow", "ovf"),
    "usub_overflow": ("llvm.usub.with.overflow", "ovf"), "ssub_overflow": ("llvm.ssub.with.overflow", "ovf"),
    "umul_overflow": ("llvm.umul.with.overflow", "ovf"), "smul_overflow": ("llvm.smul.with.overflow", "ovf"),
}


# (name, original text in tmpl_cmp.c, faulty replacement). Each original must occur exactly once.
MUTANTS = [
    ("scmp-sign-flipped", "if (sa != sb) return sa ? -1 : 1;", "if (sa != sb) return sa ? 1 : -1;"),
    ("add-no-carry", "    carry = (int)c;\n", "    carry = 0;\n"),
    ("add-no-partial-carry", "carry = (int)((r[W.nw - 1] >> rem) & 1);", "carry = 0;"),
    ("sub-borrow-chain", "borrow = (ai < bi) || (ai == bi && borrow) ? 1 : 0;", "borrow = (ai < bi) ? 1 : 0;"),
    ("load-no-mask", "  mask_top(x, W.nw, W.bits);\n}", "}"),
    ("select-arms-swapped", "load(r, c ? &args[1] : &args[2], W);", "load(r, c ? &args[2] : &args[1], W);"),
    ("sle-strict", 'else if (!strcmp(pred, "sle")) *res = s <= 0;', 'else if (!strcmp(pred, "sle")) *res = s < 0;'),
    ("ssub-cond", "return put_i1(out, sa != sb && sign(r, W) != sa);", "return put_i1(out, sa == sb && sign(r, W) != sa);"),
    ("smul-int-min-product", "(ge_pow2(p, pw, k) && !eq_pow2(p, pw, k))", "ge_pow2(p, pw, k)"),
    ("umul-bound", "ge_pow2(p, 2 * W.nw, W.bits)", "ge_pow2(p, 2 * W.nw, W.bits + 1)"),
    ("mul-carry-lost", "    p[i + nw] = (uint64_t)c;\n", ""),
    ("abs-no-neg", "    if (sign(a, W)) {", "    if (0) {"),
    ("uaddsat-no-saturate", "memset(r, 0xff, W.nw * sizeof(uint64_t));", ";"),
    ("ssat-clamp-swapped", "memset(r, sa ? 0 : 0xff, W.nw", "memset(r, sa ? 0xff : 0, W.nw"),
    ("ssubsat-cond", "(isadd ? sa == sb : sa != sb)", "(isadd ? sa == sb : sa == sb)"),
    ("smax-is-umax", "case OP_SMAX: return put(out, scmp(a, b, W) >= 0", "case OP_SMAX: return put(out, ucmp(a, b, W.nw) >= 0"),
    ("out-preset-unchecked", "if (!out->w || out->bits != bits || out->kind != kind || out->nw != need) {", "if (!out->w) {"),
]


def store_bits(w):  # bytes the harness buffer gives an operand: whole bytes
    return (w + 7) // 8 * 8


def load_int(ptr, w, name):
    sb = store_bits(w)
    if sb == w:
        return [f"  %{name} = load i{w}, ptr %{ptr}, align 8"]
    return [f"  %{name}.m = load i{sb}, ptr %{ptr}, align 8", f"  %{name} = trunc i{sb} %{name}.m to i{w}"]


def store_int(val, w):
    sb = (w + 63) // 64 * 64
    if sb == w:
        return [f"  store i{w} %{val}, ptr %o, align 8"]
    return [f"  %{val}.z = zext i{w} %{val} to i{sb}", f"  store i{sb} %{val}.z, ptr %o, align 8"]


def gen():
    fns, decls, table = [], set(), []

    def add(op, pred, wname, kind, bits, nargs, rbits, body):
        name = f"n_{op}{'_' + pred if pred else ''}_{wname}"
        fns.append(f"define void @{name}(ptr %a, ptr %b, ptr %c, ptr %o) {{\n" + "\n".join(body) + "\n  ret void\n}\n")
        table.append((op, pred, wname, kind, bits, nargs, rbits, name))

    for w in INT_WIDTHS:
        t = f"i{w}"
        xy = load_int("a", w, "x") + load_int("b", w, "y")
        for p in PREDS:
            add("icmp", p, t, "i", w, 2, 1, xy + [f"  %f = icmp {p} {t} %x, %y"] + store_int("f", 1))
        add("select", "", t, "i", w, 3, w,
            load_int("a", 1, "cnd") + load_int("b", w, "x") + load_int("c", w, "y") +
            [f"  %r = select i1 %cnd, {t} %x, {t} %y"] + store_int("r", w))
        decls.add(f"declare {t} @llvm.abs.{t}({t}, i1)")
        add("abs", "", t, "i", w, 1, w, load_int("a", w, "x") + [f"  %r = call {t} @llvm.abs.{t}({t} %x, i1 false)"] + store_int("r", w))
        for op, (intr, k) in BINOPS.items():
            if k == "val":
                decls.add(f"declare {t} @{intr}.{t}({t}, {t})")
                body = xy + [f"  %r = call {t} @{intr}.{t}({t} %x, {t} %y)"] + store_int("r", w)
                add(op, "", t, "i", w, 2, w, body)
            else:
                decls.add(f"declare {{{t}, i1}} @{intr}.{t}({t}, {t})")
                body = xy + [f"  %s = call {{{t}, i1}} @{intr}.{t}({t} %x, {t} %y)", "  %f = extractvalue {" + t + ", i1} %s, 1"] + store_int("f", 1)
                add(op, "", t, "i", w, 2, 1, body)
    for wname, (bits, ty) in FP_TYPES.items():
        body = load_int("a", 1, "cnd") + [
            f"  %x = load {ty}, ptr %b, align 8", f"  %y = load {ty}, ptr %c, align 8",
            f"  %r = select i1 %cnd, {ty} %x, {ty} %y", f"  store {ty} %r, ptr %o, align 8"]
        add("select", "", wname, "f", bits, 3, bits, body)

    ll = "; generated by tests/tmpl-cmp/difftest.py\ntarget triple = \"x86_64-apple-macosx16.0.0\"\n\n" + "\n".join(sorted(decls)) + "\n\n" + "\n".join(fns)
    inc = ["/* generated by tests/tmpl-cmp/difftest.py */"]
    inc += [f"void {r[7]}(const uint64_t *, const uint64_t *, const uint64_t *, uint64_t *);" for r in table]
    inc.append("static const entry_t TABLE[] = {")
    inc += [f'  {{"{op}", "{pred}", "{wn}", \'{k}\', {b}, {n}, {rb}, {nm}}},' for op, pred, wn, k, b, n, rb, nm in table]
    inc.append("};")
    return ll, "\n".join(inc) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clang", default="/usr/local/opt/llvm@19/bin/clang")
    ap.add_argument("--work")
    a = ap.parse_args()
    work = Path(a.work) if a.work else Path(tempfile.mkdtemp(prefix="tmpl-cmp-"))
    work.mkdir(parents=True, exist_ok=True)
    ll, inc = gen()
    (work / "native.ll").write_text(ll)
    (work / "table.inc").write_text(inc)
    if subprocess.run([a.clang, "-O1", "-c", str(work / "native.ll"), "-o", str(work / "native.o")]).returncode:
        print("FAIL: native.ll does not compile", file=sys.stderr)
        return 1

    # One executable (cq-24uw): the harness, the real family and every mutant, mutant k compiled
    # with cqe_register_op renamed to cq_mut_reg_k (harness --mutant k runs on its registrations
    # alone and stops at the first disagreement). A fresh executable per mutant cost about a second
    # each (compile, link, first-exec scan) and ran every case.
    cc = [a.clang, "-O1", "-std=c17", "-I", str(RT), "-I", str(work)]
    werr = ["-Wall", "-Wextra", "-Werror"]
    orig = (RT / "tmpl_cmp.c").read_text()
    units = [cc + werr + ["-c", str(HERE / "harness.c"), "-o", str(work / "harness.o")],
             cc + werr + ["-c", str(RT / "tmpl_cmp.c"), "-o", str(work / "tmpl_cmp.o")]]
    objs = [work / "harness.o", work / "tmpl_cmp.o", work / "mutreg.o"]
    reg = ['#include "cqe.h"', "void cq_mut_register(int, const char *, cqe_op_fn);"]
    live, survivors = [], 0
    for k, (name, old, new) in enumerate(MUTANTS):
        if orig.count(old) != 1:
            print(f"FAIL: mutant {name}: its original text occurs {orig.count(old)} times", file=sys.stderr)
            survivors += 1
            continue
        src = work / f"mutant_{name}.c"
        src.write_text(orig.replace(old, new))
        units.append(cc + ["-w", f"-Dcqe_register_op=cq_mut_reg_{k}", "-c", str(src), "-o", str(work / f"mutant_{name}.o")])
        objs.append(work / f"mutant_{name}.o")
        reg.append(f"void cq_mut_reg_{k}(const char *op, cqe_op_fn fn) {{ cq_mut_register({k}, op, fn); }}")
        live.append((k, name))
    (work / "mutreg.c").write_text("\n".join(reg) + "\n")
    units.append(cc + werr + ["-c", str(work / "mutreg.c"), "-o", str(work / "mutreg.o")])
    jobs = max(1, min(4, int(os.environ.get("CQCHECK_JOBS", "2"))))
    with ThreadPoolExecutor(jobs) as ex:
        if any(ex.map(lambda c: subprocess.run(c).returncode, units)):
            print("FAIL: the test executable does not build (harness, family or a mutant)", file=sys.stderr)
            return 1
    exe = work / "difftest"
    if subprocess.run([a.clang, *map(str, objs), str(work / "native.o"), "-o", str(exe)]).returncode:
        print("FAIL: the test executable does not link", file=sys.stderr)
        return 1

    # Self-test first: every mutant must be rejected.
    # A mutant runs on the quick set first; only one the quick set does not reject runs again on
    # the CQ_FULL set when CQ_FULL is on. A disagreement is a disagreement in either set, so the
    # verdict is the full run's, without the full sweeps of every entry ahead of the first miss.
    quick_env = {k: v for k, v in os.environ.items() if k != "CQ_FULL"}
    for k, name in live:
        for env in (quick_env, None):
            r = subprocess.run([str(exe), "--mutant", str(k)], capture_output=True, text=True, env=env)
            killed = r.returncode not in (0, 3) and ("MISMATCH" in r.stderr or "FAIL:" in r.stderr)
            if killed or r.returncode == 3 or os.environ.get("CQ_FULL", "0") in ("", "0"):
                break
        print(f"mutant {name}: {'rejected' if killed else 'NOT LINKED' if r.returncode == 3 else 'SURVIVED'}")
        survivors += 0 if killed else 1
    if survivors:
        print(f"FAIL: {survivors} of {len(MUTANTS)} mutants not rejected", file=sys.stderr)
        return 1
    print(f"self-test: {len(MUTANTS)} of {len(MUTANTS)} mutants rejected")

    r = subprocess.run([str(exe)])
    if r.returncode:
        print(f"FAIL: difftest exited {r.returncode}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
