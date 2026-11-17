#!/usr/bin/env python3
"""Generate the CQ float-template library from one table.

Writes, under softfloat/:
  cq/cqsf_roots.c   the roots: one C function per (operation, width, variant) on the C float types of
                    the template operands; `cqcc --cq-lib` lowers them. Each calls its integer-only
  cq/cqsf_inner.c   body, which wraps cq/cqsf.h (compiled apart, see INNER_PRE).
  cq/cqsf_shims.c   one definition per float template symbol (forward and _unc): it calls the root's
                    table clone with a fixed K, copies the result out and uncomputes (CR §1.4 table
                    clones; BACKEND_ABI §2.1 forward/_unc contract). Plain C, compiled natively.
  cq/cqsf_roots_x.ll  the roots of the INT_X conversions (integer widths other than 1, 8, 16, 32, 64) as
                    LLVM IR, so that each takes and returns a rail of its template's own width (C passes a
                    _BitInt(100) as two i64 and a _BitInt(200) in memory), with a native test entry
                    cqsft_<root>(ptr in, i32 mode, ptr out) per root (dropped by build.sh's internalize).
  cqsf.roots        the default root list; cqsf_f80.roots the f80 one (see F80 below).
  build/manifest.json  every template symbol: its root, K, operand kinds (read by the tests).

The symbol list is the grammar of CR §1.2 / BACKEND_ABI §2.1 expanded over the table:
  cq_template_<op>[_<pred>]_<W>[_to_<W2>][_<shape>][_rm|_rmq][_exc][_unc]
restricted to what CQ's pass can emit (pass/lib/eff/fenv/Fenv.cpp, pass/lib/abi/Abi.cpp): a mode only on
the ops whose constrained intrinsic carries one, `_exc` on every op that has a constrained form, `_lh`
only on non-commutative ops or for a NaN literal (so on every binary fp op), compares only `_hl`, `_ll`
(binary) / `_l` (unary, casts) / `lll` (fma) only with `_rmq`, is_fpclass only `_hl`.

Run `python3 softfloat/gen/gen_cqsf.py [--check-corpus DIR]`.
"""
import argparse
import itertools
import json
import re
import sys
from pathlib import Path

SF = Path(__file__).resolve().parent.parent

# ---- formats --------------------------------------------------------------------------------------
# token: (C type of an operand/literal, bit-pattern C type, bits)
FP = {
    "f16": ("_Float16", "uint16_t", 16),
    "bf16": ("__bf16", "uint16_t", 16),
    "f32": ("float", "uint32_t", 32),
    "f64": ("double", "uint64_t", 64),
    "f80": ("long double", "struct extFloat80M", 80),
}
ARITH_W = ["f16", "bf16", "f32", "f64"]   # bf16: cqsf.h computes through f32 rounded to odd (CR §1.1)
# f80: extF80_add/mul/div/sqrt/rem crash cq-lower today (pred: Walker::next, cq-pfpy); the f80 roots are
# generated into their own list, cqsf_f80.roots, and are not part of the default library.
F80_W = ["f80"]
INT_FROM = [1, 8, 16, 32, 64]     # sitofp/uitofp sources
INT_TO = [8, 16, 32, 64]          # fptosi/fptoui targets (CR §2 rows)
# The other integer widths C reaches (_BitInt(N), __int128), both directions, every fp width. One width of
# each CR §2 class: signed/unsigned <= 32 (c32, f80 fist16/fist32), 33..63 (c64, fist64), 64 < N <= 128
# (compiler-rt), N > 128 (ExpandLargeFpConvert). The grammar allows any N: a width is added here (up to 256,
# the four limbs of cq/cqsf_int.h) and needs nothing else.
INT_X = [7, 24, 48, 100, 128, 200]
PREDS = ["oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno"]

# K per root: no root has a loop but the frem ones (SoftFloat's remainder loop, 29 quotient bits per trip,
# then a do/while of at most a few trips). The value covers the largest exponent difference of the format.
K_DEFAULT = 1
K_FREM = {"f16": 8, "bf16": 16, "f32": 16, "f64": 80, "f80": 1200}   # bf16: f32's loop on the extension


def int_ctype(n, signed):
    if n == 1:
        return "bool"
    if n in (8, 16, 32, 64):
        return f"{'' if signed else 'u'}int{n}_t"
    return f"{'' if signed else 'unsigned '}_BitInt({n})"


# ---- the operation table ----------------------------------------------------------------------------
# An op instance: template stem (op[_pred]_W[_to_W2]), sfx function, operand kinds (data), result kind,
# has_mode, has_exc, shapes allowed (without the mode variants), the root stem for flags.
class Inst:
    def __init__(self, stem, fn, ins, out, mode, exc, shapes, k=K_DEFAULT, xroot=None, plainroot=None):
        self.stem, self.fn, self.ins, self.out = stem, fn, ins, out
        self.mode, self.exc, self.shapes, self.k = mode, exc, shapes, k
        self.xroot = xroot          # a shared flags root (fcmp: one per quiet/signalling compare)
        self.plainroot = plainroot  # a shared value root (fcmps: the fcmp root)
        self.xw = None              # an INT_X conversion: (N, signed, fp width, "itofp" | "fptoi")


def kind(w):
    """Operand kind: ('fp', W) or ('int', N, signed)."""
    return w


def table(widths, int_from=INT_FROM, int_to=INT_TO):
    out = []
    for W in widths:
        fw = ("fp", W)
        for op in ["fadd", "fsub", "fmul", "fdiv", "frem"]:
            out.append(Inst(f"{op}_{W}", f"sfx_{op}_{W}", [fw, fw], fw, True, True,
                            ["", "hl", "lh"], K_FREM[W] if op == "frem" else K_DEFAULT))
        for op in ["fmax", "fmin"]:
            out.append(Inst(f"{op}_{W}", f"sfx_{op}_{W}", [fw, fw], fw, False, True, ["", "hl", "lh"]))
        # f80: SoftFloat has no extF80_mulAdd; cqsf_f80.h writes one (cqsf_extF80_mulAdd)
        out.append(Inst(f"fma_{W}", f"sfx_fma_{W}", [fw, fw, fw], fw, True, True,
                        ["", "qlq", "qql", "qll", "lqq", "lql", "llq"]))
        out.append(Inst(f"sqrt_{W}", f"sfx_sqrt_{W}", [fw], fw, True, True, [""]))
        out.append(Inst(f"rint_{W}", f"sfx_rint_{W}", [fw], fw, True, True, [""]))
        for op in ["floor", "ceil", "trunc", "round"]:
            out.append(Inst(f"{op}_{W}", f"sfx_{op}_{W}", [fw], fw, False, True, [""]))
        for p in PREDS:
            out.append(Inst(f"fcmp_{p}_{W}", f"sfx_fcmpq_{p}_{W}", [fw, fw], ("int", 1, False), False, True,
                            ["", "hl"], xroot=f"fcmpq_{W}"))
            out.append(Inst(f"fcmps_{p}_{W}", f"sfx_fcmps_{p}_{W}", [fw, fw], ("int", 1, False), False, True,
                            ["", "hl"], xroot=f"fcmps_{W}", plainroot=f"fcmp_{p}_{W}"))
        out.append(Inst(f"is_fpclass_{W}", f"sfx_is_fpclass_{W}", [fw, ("int", 32, False)], ("int", 1, False),
                        False, False, ["hl"]))
    return out


def casts(widths):
    out = []
    if "f80" not in widths:
        for a, b in [("f16", "f32"), ("f16", "f64"), ("f32", "f64"), ("bf16", "f32"), ("bf16", "f64")]:
            out.append(Inst(f"fpext_{a}_to_{b}", f"sfx_fpext_{a}_to_{b}", [("fp", a)], ("fp", b), False, True, [""]))
        for a, b in [("f32", "f16"), ("f64", "f16"), ("f64", "f32"), ("f32", "bf16"), ("f64", "bf16")]:
            out.append(Inst(f"fptrunc_{a}_to_{b}", f"sfx_fptrunc_{a}_to_{b}", [("fp", a)], ("fp", b), True, True, [""]))
        for b in ["f16", "bf16", "f32", "f64"]:
            for n in INT_FROM:
                out.append(Inst(f"sitofp_i{n}_to_{b}", f"sfx_si_to_{b}", [("int", n, True)], ("fp", b), True, True, [""]))
                out.append(Inst(f"uitofp_i{n}_to_{b}", f"sfx_ui_to_{b}", [("int", n, False)], ("fp", b), True, True, [""]))
        for a in ["f16", "bf16", "f32", "f64"]:
            for n in INT_TO:
                out.append(Inst(f"fptosi_{a}_to_i{n}", f"sfx_fptosi_{a}_to_i{n}", [("fp", a)], ("int", n, True),
                                False, True, [""]))
                out.append(Inst(f"fptoui_{a}_to_i{n}", f"sfx_fptoui_{a}_to_i{n}", [("fp", a)], ("int", n, False),
                                False, True, [""]))
    else:
        for a in ["f16", "f32", "f64"]:
            out.append(Inst(f"fpext_{a}_to_f80", f"sfx_fpext_{a}_to_f80", [("fp", a)], ("fp", "f80"), False, True, [""]))
            out.append(Inst(f"fptrunc_f80_to_{a}", f"sfx_fptrunc_f80_to_{a}", [("fp", "f80")], ("fp", a), True, True, [""]))
        for n in INT_FROM:
            out.append(Inst(f"sitofp_i{n}_to_f80", "sfx_si_to_f80", [("int", n, True)], ("fp", "f80"), True, True, [""]))
            out.append(Inst(f"uitofp_i{n}_to_f80", "sfx_ui_to_f80", [("int", n, False)], ("fp", "f80"), True, True, [""]))
        for n in INT_TO:
            out.append(Inst(f"fptosi_f80_to_i{n}", f"sfx_fptosi_f80_to_i{n}", [("fp", "f80")], ("int", n, True),
                            False, True, [""]))
            out.append(Inst(f"fptoui_f80_to_i{n}", f"sfx_fptoui_f80_to_i{n}", [("fp", "f80")], ("int", n, False),
                            False, True, [""]))
    return out


def casts_x(widths):
    """sitofp/uitofp from and fptosi/fptoui to the INT_X widths, for every fp width of the group."""
    fps = ["f80"] if "f80" in widths else ["f16", "bf16", "f32", "f64"]
    out = []
    for n in INT_X:
        for t in fps:
            for sg, op in [(True, "sitofp"), (False, "uitofp")]:
                i = Inst(f"{op}_i{n}_to_{t}", None, [("int", n, sg)], ("fp", t), True, True, [""])
                i.xw = (n, sg, t, "itofp")
                out.append(i)
            for sg, op in [(True, "fptosi"), (False, "fptoui")]:
                i = Inst(f"{op}_{t}_to_i{n}", None, [("fp", t)], ("int", n, sg), False, True, [""])
                i.xw = (n, sg, t, "fptoi")
                out.append(i)
    return out


# The INT_X roots. The inner function (C, cq/cqsf_inner.c) takes and returns integers whose IR is fixed:
#   an fp operand: its bit pattern (uint16_t zeroext i16, uint32_t i32, uint64_t i64, f80 the pair i64, i16);
#   an iN source: N <= 64 the 64-bit extension (i64), else its 128- or 256-bit extension as 2 or 4 uint64_t
#   limbs (i64 each; C would pass an unsigned __int128 as two i64 anyway);
#   an iN result: N <= 64 int64_t (i64), else unsigned __int128, which C returns as { i64, i64 };
#   a flags root returns uint32_t (i32). The IR declarations must match the C definitions exactly: a call
#   with another function type links silently and works natively by register luck, but is not the callee.
# The outer root (IR, cq/cqsf_roots_x.ll) has the template's types and does the extension, the limb split,
# the truncation and, above 128 bits, the result word of cq/cqsf_int.h.
IRT = {"f16": "half", "bf16": "bfloat", "f32": "float", "f64": "double", "f80": "x86_fp80"}
IRB = {"f16": "i16", "bf16": "i16", "f32": "i32", "f64": "i64"}
CB = {"f16": "uint16_t", "bf16": "uint16_t", "f32": "uint32_t", "f64": "uint64_t", "f80": "struct extFloat80M"}


def make_root_x(inst, variant):
    """variant: '' (RNE), 'm' (mode operand), 'x' (flags; with the mode operand where the op has one)."""
    n, sg, t, d = inst.xw
    name = f"cqsf_{inst.stem}" + {"": "", "m": "_m", "x": "_x"}[variant]
    hasm = variant == "m" or (variant == "x" and inst.mode)
    ctx = "cqsf_mode(m)" if hasm else "softfloat_round_near_even"
    sgs = "true" if sg else "false"
    if d == "itofp":
        if n <= 64:
            cps, call = [f"{'int64_t' if sg else 'uint64_t'} a0"], f"sfx_{'si' if sg else 'ui'}_to_{t}(&c, a0)"
        elif n <= 128:
            cps = ["uint64_t a0", "uint64_t a1"]
            call = f"sfx_wi_to_{t}(&c, cqsf_u256_of128(((cqsf_u128)a1 << 64) | a0, {sgs}), {sgs}, false)"
        else:
            cps = [f"uint64_t a{k}" for k in range(4)]
            call = f"sfx_wi_to_{t}(&c, (struct cqsf_u256){{a0, a1, a2, a3}}, {sgs}, true)"
        rt = CB[t]
    else:
        cps = [f"{CB[t]} a0"]
        if n <= 64:
            call, rt = f"sfx_fptoi_n_{t}(&c, a0, {n}, {sgs})", "int64_t"
        elif n <= 128:
            call, rt = f"sfx_fptoi_ti_{t}(&c, a0, {sgs})", "cqsf_u128"
        else:
            call, rt = f"sfx_fptoi_xl_{t}(&c, a0, {n}, {sgs})", "cqsf_u128"
    if hasm:
        cps.append("uint32_t m")
    if variant == "x":
        body, rt = f"    (void){call};\n    return cqsf_x86flags(c.exceptionFlags);\n", "uint32_t"
    else:
        body = f"    return {call};\n"
    inner = (f"{rt} cqsfi_{name[5:]}({', '.join(cps)}) {{\n"
             f"    struct sf_ctx c = {{{ctx}, 0}};\n" + body + "}\n")
    # the outer root, IR
    ins_ty = f"i{n}" if d == "itofp" else IRT[t]
    out_ty = "i32" if variant == "x" else (IRT[t] if d == "itofp" else f"i{n}")
    L = [f"define {out_ty} @{name}({ins_ty} %a{', i32 %m' if hasm else ''}) {{"]
    args = []
    if d == "itofp":
        ext = "sext" if sg else "zext"
        if n <= 64:
            L.append(f"  %w = {ext} i{n} %a to i64")
            args.append("i64 %w")
        elif n <= 128:
            src = "%a"
            if n < 128:
                L.append(f"  %w = {ext} i{n} %a to i128")
                src = "%w"
            L += [f"  %l0 = trunc i128 {src} to i64", f"  %s1 = lshr i128 {src}, 64", "  %l1 = trunc i128 %s1 to i64"]
            args += ["i64 %l0", "i64 %l1"]
        else:
            sh = "ashr" if sg else "lshr"
            for k in range(4):
                if k == 0:
                    L.append(f"  %l0 = trunc i{n} %a to i64")
                elif 64 * k < n:
                    L.append(f"  %s{k} = {sh} i{n} %a, {64 * k}")
                    L.append(f"  %l{k} = trunc i{n} %s{k} to i64")
                elif sg:
                    L.append(f"  %s{k} = ashr i{n} %a, {n - 1}")
                    L.append(f"  %l{k} = trunc i{n} %s{k} to i64")
                else:
                    L.append(f"  %l{k} = add i64 0, 0")
                args.append(f"i64 %l{k}")
    elif t == "f80":
        L += ["  %b = bitcast x86_fp80 %a to i80", "  %b0 = trunc i80 %b to i64", "  %b1s = lshr i80 %b, 64",
              "  %b1 = trunc i80 %b1s to i16"]
        args += ["i64 %b0", "i16 %b1"]
    else:
        L.append(f"  %b = bitcast {IRT[t]} %a to {IRB[t]}")
        args.append(f"{IRB[t]}{' zeroext' if IRB[t] == 'i16' else ''} %b")
    if hasm:
        args.append("i32 %m")
    if variant == "x":
        irr = "i32"
    elif d == "itofp":
        irr = "{ i64, i16 }" if t == "f80" else IRB[t]
    else:
        irr = "i64" if n <= 64 else "{ i64, i64 }"
    rattr = " zeroext" if irr == "i16" else ""
    L.append(f"  %r = call{rattr} {irr} @cqsfi_{name[5:]}({', '.join(args)})")
    if variant == "x":
        L.append("  ret i32 %r")
    elif d == "itofp":
        if t == "f80":
            L += ["  %r0 = extractvalue { i64, i16 } %r, 0", "  %r1 = extractvalue { i64, i16 } %r, 1",
                  "  %z0 = zext i64 %r0 to i80", "  %z1 = zext i16 %r1 to i80", "  %z2 = shl i80 %z1, 64",
                  "  %z = or i80 %z2, %z0", "  %v = bitcast i80 %z to x86_fp80"]
        else:
            L.append(f"  %v = bitcast {IRB[t]} %r to {IRT[t]}")
        L.append(f"  ret {IRT[t]} %v")
    elif n <= 64:
        L += [f"  %v = trunc i64 %r to i{n}", f"  ret i{n} %v"]
    elif n <= 128:
        L += ["  %r0 = extractvalue { i64, i64 } %r, 0", "  %r1 = extractvalue { i64, i64 } %r, 1",
              "  %z0 = zext i64 %r0 to i128", "  %z1 = zext i64 %r1 to i128", "  %z2 = shl i128 %z1, 64",
              "  %z = or i128 %z2, %z0"]
        if n < 128:
            L += [f"  %v = trunc i128 %z to i{n}", f"  ret i{n} %v"]
        else:
            L.append("  ret i128 %z")
    else:
        mx = (1 << (n - 1)) - 1
        L += ["  %m0 = extractvalue { i64, i64 } %r, 0", "  %info = extractvalue { i64, i64 } %r, 1",
              "  %sh = and i64 %info, 65535", "  %ng1 = lshr i64 %info, 16", "  %neg = trunc i64 %ng1 to i1",
              "  %st1 = lshr i64 %info, 17", "  %sat = trunc i64 %st1 to i1",
              f"  %mw = zext i64 %m0 to i{n}", f"  %sw = zext i64 %sh to i{n}", f"  %v0 = shl i{n} %mw, %sw",
              f"  %nv = sub i{n} 0, %v0", f"  %v1 = select i1 %neg, i{n} %nv, i{n} %v0",
              f"  %sv = select i1 %neg, i{n} {-mx - 1}, i{n} {mx}", f"  %v = select i1 %sat, i{n} %sv, i{n} %v1",
              f"  ret i{n} %v"]
    L.append("}")
    T = [f"define void @cqsft_{name[5:]}(ptr %in, i32 %m, ptr %out) {{", f"  %a = load {ins_ty}, ptr %in",
         f"  %r = call {out_ty} @{name}({ins_ty} %a{', i32 %m' if hasm else ''})", f"  store {out_ty} %r, ptr %out",
         "  ret void", "}"]
    dargs = ", ".join(x.rsplit(" ", 1)[0] for x in args)
    r = Root(name, inst.ins + ([("int", 32, False)] if hasm else []),
             ("int", 32, False) if variant == "x" else inst.out, inner, "", inst.k)
    r.ir = "\n".join(L) + "\n"
    r.irdecl = f"declare{rattr} {irr} @cqsfi_{name[5:]}({dargs})\n"
    r.ir_test = "\n".join(T) + "\n"
    r.proto = None
    return r

# ---- C spelling -------------------------------------------------------------------------------------
def ctype(k):
    return FP[k[1]][0] if k[0] == "fp" else int_ctype(k[1], k[2])


def wtok(k):
    return k[1] if k[0] == "fp" else f"i{k[1]}"


def ictype(k):
    """The inner (integer-only) C type of an operand of kind k."""
    if k[0] == "fp":
        return FP[k[1]][1]
    return int_ctype(k[1], k[2])


def to_sfx(k, expr):
    """Inner: an operand as the argument the sfx_* function takes (int sources widened to 64 bits)."""
    if k[0] == "fp":
        return expr
    n, s = k[1], k[2]
    if n == 1 and s:
        return f"(-(int64_t)({expr}))"      # sitofp i1: true is -1
    return f"((int64_t)({expr}))" if s else f"((uint64_t)({expr}))"


def to_bits(k, expr):
    """Outer: an operand (C value of the template's type) as the inner operand."""
    return f"CQSF_BITS_{k[1]}({expr})" if k[0] == "fp" else expr


def from_bits(k, expr):
    return f"CQSF_FROM_{k[1]}({expr})" if k[0] == "fp" else expr


# The inner functions: integer-only, every SoftFloat function always_inline. They are compiled apart
# from the outer roots, so clang -O1 never sees a float type in them and cannot turn their bit tests
# back into fcmp/fabs (InstCombine does that through a bitcast).
INNER_PRE = """/* Generated by softfloat/gen/gen_cqsf.py: do not edit. The integer-only bodies of the roots. */
#pragma clang attribute push (__attribute__((always_inline)), apply_to = function)
#include "sf_unity.h"
#include "cqsf.h"
#include "cqsf_f80.h"
#include "cqsf_int.h"
#pragma clang attribute pop
"""

# The outer roots: the template's operand types, a bitcast and one call of the inner function.
OUTER_PRE = """/* Generated by softfloat/gen/gen_cqsf.py: do not edit. The roots of the CQ float-template library:
 * each takes and returns the C types of its template's operands, so its table clone takes rails of the
 * template's own widths, and calls its integer-only inner function (cqsf_inner.c, a separate unit). */
#include <stdbool.h>
#include <stdint.h>
struct extFloat80M { uint64_t signif; uint16_t signExp; };   /* as SoftFloat's, little-endian */
union cqsf_u80 { long double d; struct { uint64_t m; uint16_t e; } s; };
static inline struct extFloat80M cqsf_bits_f80(long double x) {
    union cqsf_u80 u = {.d = x}; return (struct extFloat80M){u.s.m, u.s.e};
}
static inline long double cqsf_from_f80(struct extFloat80M a) {
    union cqsf_u80 u = {.d = 0}; u.s.m = a.signif; u.s.e = a.signExp; return u.d;
}
#define CQSF_BITS_f16(x) __builtin_bit_cast(uint16_t, (_Float16)(x))
#define CQSF_BITS_bf16(x) __builtin_bit_cast(uint16_t, (__bf16)(x))
#define CQSF_BITS_f32(x) __builtin_bit_cast(uint32_t, (float)(x))
#define CQSF_BITS_f64(x) __builtin_bit_cast(uint64_t, (double)(x))
#define CQSF_BITS_f80(x) cqsf_bits_f80(x)
#define CQSF_FROM_f16(x) __builtin_bit_cast(_Float16, (uint16_t)(x))
#define CQSF_FROM_bf16(x) __builtin_bit_cast(__bf16, (uint16_t)(x))
#define CQSF_FROM_f32(x) __builtin_bit_cast(float, (uint32_t)(x))
#define CQSF_FROM_f64(x) __builtin_bit_cast(double, (uint64_t)(x))
#define CQSF_FROM_f80(x) cqsf_from_f80(x)
"""


class Root:
    def __init__(self, name, ins, out, inner, outer, k):
        self.name, self.ins, self.out, self.inner, self.outer, self.k = name, ins, out, inner, outer, k


def make_root(name, ins, out, ctx_init, expr_of, flags, k):
    """expr_of(args) is the sfx call on the inner operands; flags: return the x86 flag word instead."""
    args = [f"a{i}" for i in range(len(ins))]
    iparams = [f"{ictype(t)} {a}" for t, a in zip(ins, args)]
    oparams = [f"{ctype(t)} {a}" for t, a in zip(ins, args)]
    rtype_i = "uint32_t" if flags else ictype(out)
    rtype_o = "uint32_t" if flags else ctype(out)
    call = expr_of(args)
    body = (f"    (void){call};\n    return cqsf_x86flags(c.exceptionFlags);\n" if flags else f"    return {call};\n")
    inner = (f"{rtype_i} cqsfi_{name[5:]}({', '.join(iparams)}) {{\n"
             f"    struct sf_ctx c = {{{ctx_init}, 0}};\n" + body + "}\n")
    icall = f"cqsfi_{name[5:]}({', '.join(to_bits(t, a) for t, a in zip(ins, args))})"
    outer = (f"{rtype_i} cqsfi_{name[5:]}({', '.join(ictype(t) for t in ins)});\n"
             f"{rtype_o} {name}({', '.join(oparams)}) {{ return {icall if flags else from_bits(out, icall)}; }}\n")
    r = Root(name, ins, ("int", 32, False) if flags else out, inner, outer, k)
    r.proto = f"{rtype_o} {name}({', '.join(ctype(t) for t in ins)});"
    return r


def roots_for(inst):
    """The roots an instance needs: plain (RNE), _m (mode operand), _x (x86 flags; mode operand if any)."""
    rs = []
    if inst.xw:
        return [make_root_x(inst, v) for v in (["", "m", "x"] if inst.mode else ["", "x"])]
    n = len(inst.ins)
    data = lambda args: f"{inst.fn}(&c, {', '.join(to_sfx(t, a) for t, a in zip(inst.ins, args[:n]))})"
    m32 = [("int", 32, False)]
    if inst.plainroot is None:
        rs.append(make_root(f"cqsf_{inst.stem}", inst.ins, inst.out, "softfloat_round_near_even", data, False, inst.k))
    if inst.mode:
        rs.append(make_root(f"cqsf_{inst.stem}_m", inst.ins + m32, inst.out, f"cqsf_mode(a{n})", data, False, inst.k))
    if inst.exc and inst.xroot is None:
        rs.append(make_root(f"cqsf_{inst.stem}_x", inst.ins + (m32 if inst.mode else []), inst.out,
                            f"cqsf_mode(a{n})" if inst.mode else "softfloat_round_near_even", data, True, inst.k))
    return rs


def xroots(widths):
    """The shared flags roots of the compares: one quiet, one signalling per width."""
    rs = []
    for W in widths:
        fw = ("fp", W)
        for q in ["q", "s"]:
            rs.append(make_root(f"cqsf_fcmp{q}_{W}_x", [fw, fw], ("int", 1, False), "softfloat_round_near_even",
                                lambda a, q=q, W=W: f"sfx_fcmp{q}_oeq_{W}(&c, {a[0]}, {a[1]})", True, K_DEFAULT))
    return rs


# ---- template symbols --------------------------------------------------------------------------------
class Sym:
    """One forward template symbol and the root call that implements it."""
    def __init__(self, name, inst, shape, rm, exc):
        self.name, self.inst, self.shape, self.rm, self.exc = name, inst, shape, rm, exc


def shape_letters(inst, shape):
    n = len(inst.ins)
    if shape == "":
        return ["h"] * n
    return ["h" if c in "hq" else "l" for c in shape]


def symbols(insts):
    syms = []
    for inst in insts:
        n = len(inst.ins)
        lit_all = {1: "l", 2: "ll", 3: "lll"}[n]
        shapes = list(inst.shapes)
        rms = ["", "_rm", "_rmq"] if inst.mode else [""]
        for shape, rm, exc in itertools.product(shapes + [lit_all], rms, ["", "_exc"]):
            if exc and not inst.exc:
                continue
            if shape == lit_all and rm != "_rmq":
                continue   # no quantum operand otherwise
            if inst.stem.startswith("is_fpclass") and shape == lit_all:
                continue
            if shape == lit_all and shape in inst.shapes:
                continue
            sh = f"_{shape}" if shape else ""
            syms.append(Sym(f"cq_template_{inst.stem}{sh}{rm}{exc}", inst, shape, rm, exc))
    return syms


SHIM_PRE = """/* Generated by softfloat/gen/gen_cqsf.py: do not edit. The float templates of BACKEND_ABI §2 as calls
 * of the lowered SoftFloat roots (cqsf_roots.c). A template computes o ^= f(args) and its _unc does the
 * same: each shim calls the root's table clone (CR §1.4: every formal a handle, K last), copies the
 * result rail into o, and calls the clone's twin, which uncomputes the clone and frees its result.
 * A literal operand (and a literal _rm mode) becomes a seed rail for the call, freed after it. */
#include <stdbool.h>
#include <stdint.h>

void cqrt_free(int32_t h);
int32_t cqrt_alloc_i1(bool v);
int32_t cqrt_alloc_i8(int8_t v);
int32_t cqrt_alloc_i16(int16_t v);
int32_t cqrt_alloc_i32(int32_t v);
int32_t cqrt_alloc_i64(int64_t v);
int32_t cqrt_alloc_f16(_Float16 v);
int32_t cqrt_alloc_bf16(__bf16 v);
int32_t cqrt_alloc_f32(float v);
int32_t cqrt_alloc_f64(double v);
int32_t cqrt_alloc_f80(long double v);
void cqrt_copy_i1(int32_t s, int32_t d);
void cqrt_copy_i8(int32_t s, int32_t d);
void cqrt_copy_i16(int32_t s, int32_t d);
void cqrt_copy_i32(int32_t s, int32_t d);
void cqrt_copy_i64(int32_t s, int32_t d);
void cqrt_copy_f16(int32_t s, int32_t d);
void cqrt_copy_bf16(int32_t s, int32_t d);
void cqrt_copy_f32(int32_t s, int32_t d);
void cqrt_copy_f64(int32_t s, int32_t d);
void cqrt_copy_f80(int32_t s, int32_t d);
"""


def lit_ctype(k):
    """The C type of a literal operand of kind k (the LLVM operand type of the template)."""
    if k[0] == "fp":
        return FP[k[1]][0]
    return int_ctype(k[1], True) if k[1] != 1 else "bool"


def zero_of(k):
    return "0"


def shim_for(sym, rootinfo):
    inst = sym.inst
    letters = shape_letters(inst, sym.shape)
    if sym.exc:
        root = (f"cqsf_{inst.xroot}_x" if inst.xroot else f"cqsf_{inst.stem}_x")
        takes_mode = inst.mode and not inst.xroot
        out = ("int", 32, False)
    elif sym.rm:
        root, takes_mode, out = f"cqsf_{inst.stem}_m", True, inst.out
    else:
        root = f"cqsf_{inst.plainroot}" if inst.plainroot else f"cqsf_{inst.stem}"
        takes_mode, out = False, inst.out
    r = rootinfo[root]
    nform = len(r.ins)
    clone = f"__cq_q_{root}_{'1' * nform}_t"
    params, seeds, cargs = [], [], []
    for i, (k, l) in enumerate(zip(inst.ins, letters)):
        if l == "h":
            params.append(f"int32_t a{i}")
            cargs.append(f"a{i}")
        elif k[0] == "int" and k[1] > 128:   # LLVM passes an iN literal, N > 128, as N/64 i64 parts
            nl = (k[1] + 63) // 64
            params.append(", ".join(f"uint64_t l{i}_{j}" for j in range(nl)))
            seeds.append((f"s{i}", f"cqrt_alloc_{wtok(k)}({', '.join(f'l{i}_{j}' for j in range(nl))})"))
            cargs.append(f"s{i}")
        else:
            params.append(f"{lit_ctype(k)} l{i}")
            seeds.append((f"s{i}", f"cqrt_alloc_{wtok(k)}(l{i})"))
            cargs.append(f"s{i}")
    if sym.rm == "_rm":
        params.append("int32_t m")
        if takes_mode:
            seeds.append(("sm", "cqrt_alloc_i32(m)"))
            cargs.append("sm")
    elif sym.rm == "_rmq":
        params.append("int32_t m")
        if takes_mode:
            cargs.append("m")
    elif takes_mode:   # _exc of a mode op in the default mode
        seeds.append(("sm", "cqrt_alloc_i32(0)"))
        cargs.append("sm")
    if len(cargs) != nform:
        raise SystemExit(f"gen_cqsf: {sym.name}: {len(cargs)} clone arguments for {root} ({nform} formals)")
    ow = wtok(out)
    body = []
    for s, e in seeds:
        body.append(f"    int32_t {s} = {e};")
    body.append(f"    int32_t r = {clone}({', '.join(cargs + [f'{r.k}'])});")
    body_tail = [f"    cqrt_copy_{ow}(r, o);",
                 f"    {clone}_unc({', '.join(['r'] + cargs + [f'{r.k}'])});"]
    body_tail += [f"    cqrt_free({s});" for s, _ in reversed(seeds)]
    zero = ", ".join(["0"] * ((out[1] + 63) // 64)) if out[0] == "int" and out[1] > 128 else "0"
    fwd = (f"int32_t {sym.name}({', '.join(params) or 'void'}) {{\n" + "\n".join(body) + "\n"
           f"    int32_t o = cqrt_alloc_{ow}({zero});\n" + "\n".join(body_tail) + "\n    return o;\n}\n")
    unc = (f"void {sym.name}_unc({', '.join(['int32_t o'] + params)}) {{\n" + "\n".join(body) + "\n"
           + "\n".join(body_tail) + "\n}\n")
    decl = (f"int32_t {clone}({', '.join(['int32_t'] * (nform + 1))});\n"
            f"void {clone}_unc({', '.join(['int32_t'] * (nform + 2))});\n")
    return clone, decl, fwd + unc, root


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check-corpus", help="CQ_spec examples dir: every float template the corpus declares must be generated")
    a = ap.parse_args()

    groups = {"default": table(ARITH_W) + casts(ARITH_W) + casts_x(ARITH_W),
              "f80": table(F80_W) + casts(F80_W) + casts_x(F80_W)}
    allroots, rootinfo, rootlists = [], {}, {}
    for g, insts in groups.items():
        rs = []
        for inst in insts:
            rs += roots_for(inst)
        rs += xroots(ARITH_W if g == "default" else F80_W)
        names = [r.name for r in rs]
        if len(set(names)) != len(names):
            raise SystemExit("gen_cqsf: duplicate root")
        rootlists[g] = rs
        for r in rs:
            rootinfo[r.name] = r
        allroots += rs

    (SF / "cq" / "cqsf_inner.c").write_text(INNER_PRE + "\n" + "\n".join(r.inner for r in allroots))
    croots = [r for r in allroots if not hasattr(r, "ir")]
    xroots_ = [r for r in allroots if hasattr(r, "ir")]
    (SF / "cq" / "cqsf_roots.c").write_text(OUTER_PRE + "\n" + "\n".join(r.outer for r in croots))
    (SF / "cq" / "cqsf_roots.h").write_text("/* Generated by softfloat/gen/gen_cqsf.py: the roots' C prototypes. */\n"
                                           "#include <stdbool.h>\n#include <stdint.h>\n" + "\n".join(r.proto for r in croots) + "\n"
                                           "/* The INT_X roots (cqsf_roots_x.ll) through memory: cqsft_<root>(operand, mode, result). */\n"
                                           + "".join(f"void cqsft_{r.name[5:]}(const void *in, uint32_t m, void *out);\n" for r in xroots_))
    (SF / "cq" / "cqsf_roots_x.ll").write_text(
        "; Generated by softfloat/gen/gen_cqsf.py: do not edit. The roots of the INT_X conversions (cq/cqsf_int.h)\n"
        "; with the template's own operand types, and their native test entries cqsft_*.\n\n"
        + "".join(r.irdecl for r in xroots_) + "\n" + "\n".join(r.ir for r in xroots_) + "\n" + "\n".join(r.ir_test for r in xroots_))
    (SF / "cqsf.roots").write_text("".join(r.name + "\n" for r in rootlists["default"]))
    (SF / "cqsf_f80.roots").write_text("".join(r.name + "\n" for r in rootlists["f80"]))

    manifest, shims, decls, seen = {}, [], {}, set()
    for g, insts in groups.items():
        for sym in symbols(insts):
            clone, decl, code, root = shim_for(sym, rootinfo)
            if sym.name in seen:
                raise SystemExit(f"gen_cqsf: duplicate symbol {sym.name}")
            seen.add(sym.name)
            decls.setdefault(g, {})[clone] = decl
            shims.append((g, code))
            manifest[sym.name] = {"group": g, "root": root, "k": rootinfo[root].k, "shape": sym.shape,
                                  "rm": sym.rm, "exc": bool(sym.exc), "ins": sym.inst.ins, "out": sym.inst.out,
                                  "stem": sym.inst.stem, "x": bool(sym.inst.xw)}
    xdecl = "".join(f"int32_t cqrt_alloc_i{n}({', '.join(['uint64_t'] * ((n + 63) // 64)) if n > 128 else int_ctype(n, True)});\n"
                    f"void cqrt_copy_i{n}(int32_t s, int32_t d);\n" for n in INT_X if n not in (1, 8, 16, 32, 64))
    for g in groups:
        text = SHIM_PRE + xdecl + "".join(decls[g].values()) + "\n" + "\n".join(code for gg, code in shims if gg == g)
        (SF / "cq" / ("cqsf_shims.c" if g == "default" else "cqsf_shims_f80.c")).write_text(text)
    (SF / "build").mkdir(exist_ok=True)
    (SF / "build" / "manifest.json").write_text(json.dumps(manifest, indent=0))
    nsym = {g: sum(1 for m in manifest.values() if m["group"] == g) for g in groups}
    print(f"gen_cqsf: roots default {len(rootlists['default'])}, f80 {len(rootlists['f80'])}; "
          f"template symbols (forward; each has its _unc) default {nsym['default']}, f80 {nsym['f80']}")

    if a.check_corpus:
        ex = Path(a.check_corpus)
        corpus = set()
        for f in ex.glob("*/*.lowered.ll"):
            corpus |= set(re.findall(r"@(cq_template_[A-Za-z0-9_]+)", f.read_text()))
        fp_re = re.compile(r"^cq_template_(fadd|fsub|fmul|fdiv|frem|fma|sqrt|fcmps?|fmax|fmin|floor|ceil|trunc_f|rint|round|"
                           r"is_fpclass|fpext|fptrunc|sitofp|uitofp|fptosi|fptoui)")
        want = {s[:-4] if s.endswith("_unc") else s for s in corpus if fp_re.match(s)}
        missing = sorted(w for w in want if w not in seen)
        print(f"gen_cqsf: corpus float templates {len(want)}; generated {len(want) - len(missing)}; "
              f"missing {len(missing)}: {' '.join(missing)}")


if __name__ == "__main__":
    main()
