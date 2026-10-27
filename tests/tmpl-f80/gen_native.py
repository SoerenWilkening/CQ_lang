#!/usr/bin/env python3
"""Generate the native side of the tmpl-f80 differential test (cq-w0-tmpl-f80).

Writes <out>/native.ll (one plain and one strictfp function per case, the same LLVM IR operation
the template stands for, compiled by clang-19 -O1 for the corpus CPU) and <out>/cases.inc (the case
table the harness iterates). Every function has the signature
    void (ptr out, ptr a, ptr b, ptr c)
loading its operands from a, b, c and storing the result to out.

The plain function is the value reference at the default mode. The strict function uses the
constrained intrinsics (round.dynamic, fpexcept.strict) and is the reference for _rm/_rmq values
(the harness sets the mode with fesetround) and for _exc (fetestexcept around the call).
"""
import sys
from pathlib import Path

F80 = "x86_fp80"
FT = {"f16": "half", "bf16": "bfloat", "f32": "float", "f64": "double"}
INT_WIDTHS = [1, 7, 8, 9, 15, 16, 24, 31, 32, 33, 40, 63, 64, 65, 80, 100, 128, 129, 200]
PREDS = ["false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord",
         "uno", "ueq", "ugt", "uge", "ult", "ule", "une", "true"]
CLASS_MASKS = [1 << b for b in range(10)] + [3, 0x3FF, 264, 0x90, 0x60, 0x204, 0x1F8, 0x207]
RD, EX = 'metadata !"round.dynamic"', 'metadata !"fpexcept.strict"'

cases = []   # (kind, op, pred, w, to, nargs, extra)
fns = []
decls = set()


def emit(cid, tys, rty, plain, strict):
    """tys: operand IR types; plain/strict: lists of body lines computing %r."""
    for tag, body, attr in (("nv", plain, ""), ("ns", strict, " strictfp")):
        lines = [f"define void @{tag}_{cid}(ptr %o, ptr %pa, ptr %pb, ptr %pc){attr} {{"]
        for i, t in enumerate(tys):
            lines.append(f"  %{'abc'[i]} = load {t}, ptr %p{'abc'[i]}, align 1")
        lines += ["  " + l for l in body]
        lines.append(f"  store {rty} %r, ptr %o, align 1")
        lines.append("  ret void")
        lines.append("}")
        fns.append("\n".join(lines))


def add(kind, op, pred, w, to, nargs, tys, rty, plain, strict, extra=0):
    cid = len(cases)
    cases.append((kind, op, pred, w, to, nargs, extra))
    emit(cid, tys, rty, plain, strict)


def cfn(name, ret, args):
    decls.add(f"declare {ret} @{name}({', '.join(args)})")
    return name


def nonative(kind, op, w, to, rty):
    zero = "0xK00000000000000000000" if rty == F80 else "0"
    body = [f"%r = select i1 true, {rty} {zero}, {rty} {zero}"]
    add(kind, op, "", w, to, 1, [], rty, body, body, extra=1)


# binary arithmetic
for op in ["fadd", "fsub", "fmul", "fdiv", "frem"]:
    n = cfn(f"llvm.experimental.constrained.{op}.f80", F80, [F80, F80, "metadata", "metadata"])
    add("K_BIN", op, "", "f80", "", 2, [F80, F80], F80,
        [f"%r = {op} {F80} %a, %b"],
        [f"%r = call {F80} @{n}({F80} %a, {F80} %b, {RD}, {EX}) strictfp"])

# unary
add("K_SIGN", "fneg", "", "f80", "", 1, [F80], F80, [f"%r = fneg {F80} %a"], [f"%r = fneg {F80} %a"])
n = cfn("llvm.fabs.f80", F80, [F80])
add("K_SIGN", "fabs", "", "f80", "", 1, [F80], F80, [f"%r = call {F80} @{n}({F80} %a)"],
    [f"%r = call {F80} @{n}({F80} %a) strictfp"])
n = cfn("llvm.copysign.f80", F80, [F80, F80])
add("K_SIGN", "copysign", "", "f80", "", 2, [F80, F80], F80, [f"%r = call {F80} @{n}({F80} %a, {F80} %b)"],
    [f"%r = call {F80} @{n}({F80} %a, {F80} %b) strictfp"])
for op, rounded in [("sqrt", True), ("rint", True), ("floor", False), ("ceil", False), ("trunc", False),
                    ("round", False)]:
    p = cfn(f"llvm.{op}.f80", F80, [F80])
    md = [RD, EX] if rounded else [EX]
    s = cfn(f"llvm.experimental.constrained.{op}.f80", F80, [F80] + ["metadata"] * len(md))
    add("K_UN", op, "", "f80", "", 1, [F80], F80, [f"%r = call {F80} @{p}({F80} %a)"],
        [f"%r = call {F80} @{s}({F80} %a, {', '.join(md)}) strictfp"])
p = cfn("llvm.fma.f80", F80, [F80] * 3)
s = cfn("llvm.experimental.constrained.fma.f80", F80, [F80] * 3 + ["metadata"] * 2)
add("K_FMA", "fma", "", "f80", "", 3, [F80] * 3, F80, [f"%r = call {F80} @{p}({F80} %a, {F80} %b, {F80} %c)"],
    [f"%r = call {F80} @{s}({F80} %a, {F80} %b, {F80} %c, {RD}, {EX}) strictfp"])
for op, intr in [("fmax", "maxnum"), ("fmin", "minnum")]:
    p = cfn(f"llvm.{intr}.f80", F80, [F80, F80])
    s = cfn(f"llvm.experimental.constrained.{intr}.f80", F80, [F80, F80, "metadata"])
    add("K_MINMAX", op, "", "f80", "", 2, [F80, F80], F80, [f"%r = call {F80} @{p}({F80} %a, {F80} %b)"],
        [f"%r = call {F80} @{s}({F80} %a, {F80} %b, {EX}) strictfp"])

# compares
for op in ["fcmp", "fcmps"]:
    s = cfn(f"llvm.experimental.constrained.{op}.f80", "i1", [F80, F80, "metadata", "metadata"])
    for pr in PREDS:
        if pr in ("false", "true"):
            strict = [f"%r = fcmp {pr} {F80} %a, %b"]
        else:
            strict = [f'%r = call i1 @{s}({F80} %a, {F80} %b, metadata !"{pr}", {EX}) strictfp']
        add("K_CMP", op, pr, "f80", "", 2, [F80, F80], "i1", [f"%r = fcmp {pr} {F80} %a, %b"], strict)

# is_fpclass (mask is an immarg literal: one function per mask)
p = cfn("llvm.is.fpclass.f80", "i1", [F80, "i32"])
for m in CLASS_MASKS:
    add("K_CLASS", "is_fpclass", "", "f80", "", 2, [F80], "i1", [f"%r = call i1 @{p}({F80} %a, i32 {m})"],
        [f"%r = call i1 @{p}({F80} %a, i32 {m}) strictfp"], extra=m)

# fp casts
for w, t in FT.items():
    decls.add(f"declare {F80} @llvm.experimental.constrained.fpext.f80.{w}({t}, metadata)")
    decls.add(f"declare {t} @llvm.experimental.constrained.fptrunc.{w}.f80({F80}, metadata, metadata)")
    add("K_FPEXT", "fpext", "", w, "f80", 1, [t], F80, [f"%r = fpext {t} %a to {F80}"],
        [f"%r = call {F80} @llvm.experimental.constrained.fpext.f80.{w}({t} %a, {EX}) strictfp"])
    if w in ("bf16", "f16"):
        # No native code: LLVM 19 cannot select fptrunc x86_fp80 -> bfloat ("Unsupported library
        # call operation"), and fptrunc x86_fp80 -> half calls __truncxfhf2, which neither the
        # macOS libSystem nor brew llvm@19's libclang_rt.osx.a provides (link fails). The function
        # stores a zero and the harness checks every form against the CR §2 table (extra 1).
        nonative("K_FPTRUNC", "fptrunc", "f80", w, "i16")
        continue
    add("K_FPTRUNC", "fptrunc", "", "f80", w, 1, [F80], t, [f"%r = fptrunc {F80} %a to {t}"],
        [f"%r = call {t} @llvm.experimental.constrained.fptrunc.{w}.f80({F80} %a, {RD}, {EX}) strictfp"])

# int <-> f80
for n in INT_WIDTHS:
    it = f"i{n}"
    big = n > 128
    if big:
        # No native code above 128 bits: LLVM 19 cannot select the constrained conversions, and
        # the plain ones go through fp128 (__extendxftf2 / __trunctfxf2), which neither libSystem
        # nor libclang_rt.osx.a provides. Checked against the table in every form (extra 1).
        for op in ["sitofp", "uitofp"]:
            nonative("K_ITOFP", op, it, "f80", F80)
        for op in ["fptosi", "fptoui"]:
            nonative("K_FPTOI", op, "f80", it, it)
        continue
    for op in ["sitofp", "uitofp"]:
        plain = [f"%r = {op} {it} %a to {F80}"]
        decls.add(f"declare {F80} @llvm.experimental.constrained.{op}.f80.{it}({it}, metadata, metadata)")
        add("K_ITOFP", op, "", it, "f80", 1, [it], F80, plain,
            [f"%r = call {F80} @llvm.experimental.constrained.{op}.f80.{it}({it} %a, {RD}, {EX}) strictfp"])
    for op in ["fptosi", "fptoui"]:
        plain = [f"%r = {op} {F80} %a to {it}"]
        decls.add(f"declare {it} @llvm.experimental.constrained.{op}.{it}.f80({F80}, metadata)")
        add("K_FPTOI", op, "", "f80", it, 1, [F80], it, plain,
            [f"%r = call {it} @llvm.experimental.constrained.{op}.{it}.f80({F80} %a, {EX}) strictfp"])


out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
(out / "native.ll").write_text(
    'target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"\n'
    'target triple = "x86_64-apple-macosx"\n\n' + "\n\n".join(fns) + "\n\n" + "\n".join(sorted(decls)) + "\n")
inc = []
for i, (kind, op, pred, w, to, nargs, extra) in enumerate(cases):
    inc.append(f'CASE({i}, {kind}, "{op}", "{pred}", "{w}", "{to}", {nargs}, {extra})')
(out / "cases.inc").write_text("\n".join(inc) + "\n")
