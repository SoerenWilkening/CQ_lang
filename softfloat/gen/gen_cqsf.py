#!/usr/bin/env python3
"""Generate the CQ float-template library from one table.

Writes, under softfloat/:
  cq/cqsf_roots.c   the roots: one C function per (operation, width, variant) on the C float types of
                    the template operands; `cqcc --cq-lib` lowers them. Each calls its integer-only
  cq/cqsf_inner.c   body, which wraps cq/cqsf.h (compiled apart, see INNER_PRE).
  cq/cqsf_shims.c   one definition per float template symbol (forward and _unc): it calls the root's
                    table clone with a fixed K, copies the result out and uncomputes (CR §1.4 table
                    clones; BACKEND_ABI §2.1 forward/_unc contract). Plain C, compiled natively.
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
ARITH_W = ["f16", "f32", "f64"]
# f80: extF80_add/mul/div/sqrt/rem crash cq-lower today (pred: Walker::next, cq-pfpy); the f80 roots are
# generated into their own list, cqsf_f80.roots, and are not part of the default library.
F80_W = ["f80"]
INT_FROM = [1, 8, 16, 32, 64]     # sitofp/uitofp sources
INT_TO = [8, 16, 32, 64]          # fptosi/fptoui targets (CR §2 rows)
PREDS = ["oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno"]

# K per root: no root has a loop but the frem ones (SoftFloat's remainder loop, 29 quotient bits per trip,
# then a do/while of at most a few trips). The value covers the largest exponent difference of the format.
K_DEFAULT = 1
K_FREM = {"f16": 8, "f32": 16, "f64": 80, "f80": 1200}


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
        if W != "f80":   # SoftFloat has no extF80_mulAdd
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
        out.append(Inst("is_fpclass_bf16", "sfx_is_fpclass_bf16", [("fp", "bf16"), ("int", 32, False)], ("int", 1, False),
                        False, False, ["hl"]))
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
    fwd = (f"int32_t {sym.name}({', '.join(params) or 'void'}) {{\n" + "\n".join(body) + "\n"
           f"    int32_t o = cqrt_alloc_{ow}(0);\n" + "\n".join(body_tail) + "\n    return o;\n}\n")
    unc = (f"void {sym.name}_unc({', '.join(['int32_t o'] + params)}) {{\n" + "\n".join(body) + "\n"
           + "\n".join(body_tail) + "\n}\n")
    decl = (f"int32_t {clone}({', '.join(['int32_t'] * (nform + 1))});\n"
            f"void {clone}_unc({', '.join(['int32_t'] * (nform + 2))});\n")
    return clone, decl, fwd + unc, root


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check-corpus", help="CQ_spec examples dir: every float template the corpus declares must be generated")
    a = ap.parse_args()

    groups = {"default": table(ARITH_W) + casts(ARITH_W), "f80": table(F80_W) + casts(F80_W)}
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
    (SF / "cq" / "cqsf_roots.c").write_text(OUTER_PRE + "\n" + "\n".join(r.outer for r in allroots))
    (SF / "cq" / "cqsf_roots.h").write_text("/* Generated by softfloat/gen/gen_cqsf.py: the roots' C prototypes. */\n"
                                           "#include <stdbool.h>\n#include <stdint.h>\n" + "\n".join(r.proto for r in allroots) + "\n")
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
                                  "stem": sym.inst.stem}
    for g in groups:
        text = SHIM_PRE + "".join(decls[g].values()) + "\n" + "\n".join(code for gg, code in shims if gg == g)
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
