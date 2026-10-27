#!/usr/bin/env python3
"""Differential test of checker/rt/tmpl_cmp.c against native x86-64 code (cq-w0-tmpl-cmp).

Generates native.ll (one function per op and width: the LLVM IR operation itself, operands and
result through memory) and table.inc, compiles native.ll with clang-19 -O1, links it with
harness.c and the family source, and runs the harness. See harness.c for the input classes.

Widths: every corpus width of these ops (icmp i1 i8 i32 i64 i128; select i8 i32 i64 i128 f32 f64
f80; min/max, abs, overflow, sat at i32/i64), plus i1, i7, i100, and i16, i256, f16 and bf16 for every op
the width applies to.

Self-test: every mutant in MUTANTS (one textual fault in a copy of tmpl_cmp.c) must be rejected by
the same harness before the real run counts.

Usage: difftest.py [--clang CLANG] [--work DIR]
"""
import argparse
import subprocess
import sys
import tempfile
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

    def build(src, exe, warn=True):
        flags = ["-Wall", "-Wextra", "-Werror"] if warn else ["-w"]
        return subprocess.run([a.clang, "-O1", "-std=c17", *flags, "-I", str(RT), "-I", str(work),
                               str(HERE / "harness.c"), str(src), str(work / "native.o"), "-o", str(exe)]).returncode

    # Self-test first: every mutant must be rejected.
    orig = (RT / "tmpl_cmp.c").read_text()
    survivors = 0
    for name, old, new in MUTANTS:
        if orig.count(old) != 1:
            print(f"FAIL: mutant {name}: its original text occurs {orig.count(old)} times", file=sys.stderr)
            survivors += 1
            continue
        src = work / f"mutant_{name}.c"
        src.write_text(orig.replace(old, new))
        exe = work / f"mutant_{name}"
        if build(src, exe, warn=False):
            print(f"FAIL: mutant {name} does not compile", file=sys.stderr)
            survivors += 1
            continue
        r = subprocess.run([str(exe)], capture_output=True, text=True)
        killed = r.returncode != 0 and "MISMATCH" in r.stderr or "FAIL:" in r.stderr
        print(f"mutant {name}: {'rejected' if killed else 'SURVIVED'}")
        survivors += 0 if killed else 1
    if survivors:
        print(f"FAIL: {survivors} of {len(MUTANTS)} mutants not rejected", file=sys.stderr)
        return 1
    print(f"self-test: {len(MUTANTS)} of {len(MUTANTS)} mutants rejected")

    exe = work / "difftest"
    if build(RT / "tmpl_cmp.c", exe):
        print("FAIL: harness does not build", file=sys.stderr)
        return 1
    r = subprocess.run([str(exe)])
    if r.returncode:
        print(f"FAIL: difftest exited {r.returncode}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
