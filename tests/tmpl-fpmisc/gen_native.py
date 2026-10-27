#!/usr/bin/env python3
"""Differential test generator for checker/rt/tmpl_fpmisc.c (cq-w0-tmpl-fpmisc).

Writes <outdir>/native.ll: one function per case, `void @n<K>(ptr %in, ptr %out)`, that loads its
operands from %in (operand i at byte offset 64*i), applies the LLVM IR operation the template
denotes and stores the result to %out. Compiled by clang-19 -O1 with the corpus target attributes
(penryn), it is the native x86-64 reference. Also writes <outdir>/cases.inc, one CASE(...) line per
function, read by diff.c.

Integer operands are loaded as whole 64-bit words and truncated, so no load reads a partial byte;
results are stored at their own type and masked by the harness.
"""
import sys
from pathlib import Path

FP = {"f16": "half", "bf16": "bfloat", "f32": "float", "f64": "double"}
FPS = ["f16", "bf16", "f32", "f64"]
# fpext/fptrunc direction, clang 19's spelling: f16 < bf16 < f32 < f64.
RANK = {"f16": 0, "bf16": 1, "f32": 2, "f64": 3}


def bits(ty):
    """Width of a template type: 'bf16' -> 16, 'f64' -> 64, 'i7' -> 7."""
    return int(ty[-2:]) if ty == "bf16" else int(ty[1:])
# Corpus widths (BACKEND_ABI §2) plus i1, i7, i100 (bead), plus the legalization boundaries of
# fptosi/fptoui (17..31, 32, 33..63, 64, 65..128, > 128).
INTS = [1, 7, 8, 16, 24, 31, 32, 33, 48, 63, 64, 65, 80, 100, 127, 128, 129, 200, 256]
FCMP = ["false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord",
        "ueq", "ugt", "uge", "ult", "ule", "une", "uno", "true"]
# is_fpclass masks: every single class bit, the corpus mask 264 (isnormal), and some unions.
MASKS = [1 << b for b in range(10)] + [0, 3, 264, 516, 144, 96, 1023, 0x2aa, 0x155]
ATTRS = ('attributes #0 = { noinline nounwind "target-cpu"="penryn" '
         '"target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" '
         '"tune-cpu"="generic" }')


def QUIET(src, dst):
    """dst = src * 1.0 with the 1.0 read through a volatile load, so nothing folds it away: an SSE
    mulss quiets an sNaN and keeps its payload (llvm.canonicalize has no x86 lowering in LLVM 19)."""
    return [f"%one.{dst[1:]} = load volatile float, ptr @fpmisc.one", f"{dst} = fmul float {src}, %one.{dst[1:]}"]


def resize(n, m):
    """The integer cast opcode from iN to iM (zero-extending; %hi and %sh are nonnegative)."""
    return "trunc" if n > m else "zext" if n < m else "bitcast"


def JAM(n, ty, sfx, signed, jb=64, final=None):
    """IR computing iN %a0 -> ty correctly rounded via a jb-bit jammed magnitude and ldexp.

    With final (bf16), ty is the exact intermediate f32: the jammed magnitude has at most jb = 24
    bits, so u64 -> f32 and ldexp are exact (or overflow to Inf, beyond the range of bf16 as well;
    the two share their exponent range), and the one rounding is the native f32 -> final fptrunc.
    The sign is applied in f32, before that rounding (RNE is symmetric)."""
    i = f"i{n}"
    b = []
    if signed:
        b += [f"%neg = icmp slt {i} %a0, 0", f"%ng = sub {i} 0, %a0", f"%abs = select i1 %neg, {i} %ng, {i} %a0"]
    else:
        b += [f"%abs = add {i} %a0, 0"]
    b += [f"%lz = call {i} @llvm.ctlz.{i}({i} %abs, i1 false)", f"%n = sub {i} {n}, %lz",
          f"%big = icmp ugt {i} %n, {jb}", f"%sm = sub {i} %n, {jb}", f"%sh = select i1 %big, {i} %sm, {i} 0",
          f"%hi = lshr {i} %abs, %sh", f"%bit = shl {i} 1, %sh", f"%mask = sub {i} %bit, 1",
          f"%lo = and {i} %abs, %mask", f"%st = icmp ne {i} %lo, 0", f"%h64 = {resize(n, 64)} {i} %hi to i64",
          "%s64 = zext i1 %st to i64", "%j = or i64 %h64, %s64", f"%f = uitofp i64 %j to {ty}",
          f"%e = {resize(n, 32)} {i} %sh to i32",
          f"%{'g' if signed else 'r'} = call {ty} @llvm.ldexp.{sfx}.i32({ty} %f, i32 %e)"]
    res = "%s" if final else "%r"
    if signed:
        b += [f"%gn = fneg {ty} %g", f"{res} = select i1 %neg, {ty} %gn, {ty} %g"]
    elif final:
        b[-1] = b[-1].replace("%r = call", "%s = call")
    if final:
        b += [f"%r = fptrunc {ty} %s to {final}"]
    return b


def words(n):
    return (n + 63) // 64


class Gen:
    def __init__(self):
        self.fns = []
        self.cases = []
        self.decls = set()

    def load(self, i, ty):
        """IR lines loading operand i of template type ty ('f64', 'i7', ...) as %a<i>."""
        p = f"%p{i}"
        lines = [f"  {p} = getelementptr i8, ptr %in, i64 {64 * i}"]
        if ty in FP:
            lines.append(f"  %a{i} = load {FP[ty]}, ptr {p}")
        else:
            n = bits(ty)
            m = 64 * words(n)
            if m == n:
                lines.append(f"  %a{i} = load i{n}, ptr {p}")
            else:
                lines.append(f"  %w{i} = load i{m}, ptr {p}")
                lines.append(f"  %a{i} = trunc i{m} %w{i} to i{n}")
        return lines

    def irty(self, ty):
        return FP[ty] if ty in FP else ty

    def add(self, op, pred, w, to, ins, outty, body, aux=0):
        k = len(self.cases)
        lines = [f"define void @n{k}(ptr %in, ptr %out) #0 {{"]
        for i, ty in enumerate(ins):
            lines += self.load(i, ty)
        lines += [f"  {l}" for l in body]
        lines += [f"  store {self.irty(outty)} %r, ptr %out", "  ret void", "}"]
        self.fns.append("\n".join(lines))
        outbits = bits(outty)  # i1 -> 1, f64 -> 64, bf16 -> 16, i7 -> 7
        in1 = ins[1] if len(ins) > 1 else ""
        self.cases.append(f'CASE({k}, "{op}", "{pred}", "{w}", "{to}", "{ins[0]}", "{in1}", {outbits}, {aux})')

    def intrinsic(self, name, ret, args):
        self.decls.add(f"declare {ret} @{name}({', '.join(args)})")

    def build(self):
        for t in FPS:
            ty = FP[t]
            for pr in FCMP:
                self.add("fcmp", pr, t, "", [t, t], "i1", [f"%r = fcmp {pr} {ty} %a0, %a1"])
            for op, intr in [("floor", "floor"), ("ceil", "ceil"), ("trunc", "trunc"),
                             ("rint", "rint"), ("round", "round")]:
                nm = f"llvm.{intr}.{ty_suffix(t)}"
                self.intrinsic(nm, ty, [ty])
                self.add(op, "", t, "", [t], t, [f"%r = call {ty} @{nm}({ty} %a0)"])
            nm = f"llvm.fabs.{ty_suffix(t)}"
            self.intrinsic(nm, ty, [ty])
            if t == "f16":
                # TABLE: native half fabs is soft-promoted through f32 and quiets an sNaN; BACKEND_ABI
                # §2.10 (and LangRef) say "clear the sign bit". Reference = the bit operation.
                self.add("fabs", "", t, "", [t], t, ["%i = bitcast half %a0 to i16", "%j = and i16 %i, 32767",
                                                     "%r = bitcast i16 %j to half"])
            else:
                self.add("fabs", "", t, "", [t], t, [f"%r = call {ty} @{nm}({ty} %a0)"])
            for op, intr in [("copysign", "copysign")] + ([] if t == "f16" else [("fmax", "maxnum"), ("fmin", "minnum")]):
                nm = f"llvm.{intr}.{ty_suffix(t)}"
                self.intrinsic(nm, ty, [ty, ty])
                self.add(op, "", t, "", [t, t], t, [f"%r = call {ty} @{nm}({ty} %a0, {ty} %a1)"])
            if t == "f16":
                # TABLE: native half maxnum/minnum (promoted through f32) returns a, not b, for two
                # NaNs and quiets; CR §2 fixes isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), bits
                # unchanged. Reference = that formula as IR selects on the half values.
                for op, pr in (("fmax", "ogt"), ("fmin", "olt")):
                    self.add(op, "", t, "", [t, t], t, [
                        "%na = fcmp uno half %a0, %a0", "%nb = fcmp uno half %a1, %a1",
                        f"%c = fcmp {pr} half %a1, %a0", "%m = select i1 %c, half %a1, half %a0",
                        "%m2 = select i1 %nb, half %a0, half %m", "%r = select i1 %na, half %a1, half %m2"])
            nm = f"llvm.is.fpclass.{ty_suffix(t)}"
            self.intrinsic(nm, "i1", [ty, "i32"])
            for m in MASKS:
                self.add("is_fpclass", "", t, "", [t], "i1", [f"%r = call i1 @{nm}({ty} %a0, i32 {m})"], aux=m)
        for s in FPS:
            for d in FPS:
                if s == "f16" and d == "f32":
                    # TABLE: native f16 -> f32 is compiler-rt __extendhfsf2 (penryn has no F16C),
                    # which keeps an sNaN signalling; BACKEND_ABI §2.6 says the NaN comes out quiet,
                    # as x86. Reference = fpext then a multiply by 1.0 (quiets, keeps the payload).
                    self.add("fpext", "", s, d, [s], d, ["%e = fpext half %a0 to float"] + QUIET("%e", "%r"))
                elif {s, d} == {"f16", "bf16"}:
                    # TABLE: clang 19 spells (__bf16)h as fpext half to bfloat and (_Float16)b as
                    # fptrunc bfloat to half, but LLVM 19's IR parser rejects both casts (equal
                    # widths), so no native code exists. Reference: the exact widening to f32
                    # (fpext + quieting, see f16 -> f32 above; bfloat -> float is a bare shift that
                    # would keep an sNaN), then the native single rounding f32 -> d.
                    self.add("fpext" if RANK[d] > RANK[s] else "fptrunc", "", s, d, [s], d,
                             [f"%e = fpext {FP[s]} %a0 to float"] + QUIET("%e", "%q") +
                             [f"%r = fptrunc float %q to {FP[d]}"])
                elif s == "bf16" and d == "f32":
                    # TABLE: native bfloat -> float is a bare 16-bit shift and keeps an sNaN
                    # signalling; BACKEND_ABI §2.6 (and CR §1.1: bf16 has the NaN rules of the IEEE
                    # widths) say the NaN comes out quiet. Reference = fpext then quieting.
                    self.add("fpext", "", s, d, [s], d, ["%e = fpext bfloat %a0 to float"] + QUIET("%e", "%r"))
                elif s == "f32" and d == "bf16":
                    # TABLE: native float -> bfloat leaves an sNaN whose payload survives the
                    # truncation signalling (0x7fa00000 -> 0x7fa0); the fptrunc NaN rule quiets it
                    # (0x7fe0). Reference = quieting in f32 (payload kept), then the native fptrunc.
                    self.add("fptrunc", "", s, d, [s], d, QUIET("%a0", "%q") + ["%r = fptrunc float %q to bfloat"])
                elif RANK[d] > RANK[s]:
                    self.add("fpext", "", s, d, [s], d, [f"%r = fpext {FP[s]} %a0 to {FP[d]}"])
                elif RANK[d] < RANK[s]:
                    self.add("fptrunc", "", s, d, [s], d, [f"%r = fptrunc {FP[s]} %a0 to {FP[d]}"])
        for n in INTS:
            it = f"i{n}"
            for t in FPS:
                if (t == "f16" and n > 64) or (t == "f32" and n > 128):
                    # TABLE. int -> f16 at N > 64 lowers to __floattihf/__floatuntihf, which neither
                    # compiler-rt 19 nor libSystem provides (no native code exists), and LLVM 19's
                    # ExpandLargeFpConvert gets int -> f16/f32 overflow wrong at N > 128 (uitofp i129
                    # 2^129-1 -> -0.0). BACKEND_ABI §2.6: correctly rounded, RNE, overflow to Inf.
                    # Reference: the magnitude jammed to 64 bits (top 64 bits, lower bits ORed into
                    # bit 0: exact for any rounding to <= 62 bits), the native u64 -> T conversion
                    # (verified correct by the N = 64 cases), llvm.ldexp, then the sign. (A route
                    # through f64 or f32 double-rounds: 2^53 + 2^29 + 1 -> f32 is off by one ulp.)
                    self.intrinsic(f"llvm.ctlz.i{n}", f"i{n}", [f"i{n}", "i1"])
                    self.intrinsic(f"llvm.ldexp.{ty_suffix(t)}.i32", FP[t], [FP[t], "i32"])
                    for op in ("sitofp", "uitofp"):
                        body = JAM(n, FP[t], ty_suffix(t), op == "sitofp")
                        self.add(op, "", it, t, [it], t, body)
                if t == "bf16" and n > 24:
                    # TABLE. Native int -> bfloat is int -> float, then fptrunc float -> bfloat: two
                    # roundings, wrong once N > 24 (2^24 + 2^16 + 1 -> 0x4b80, correctly rounded
                    # 0x4b81), and at N > 128 the ExpandLargeFpConvert overflow bug as above.
                    # BACKEND_ABI §2.6 / CR §1.1: correctly rounded, RNE. Reference: the magnitude
                    # jammed to 24 bits, exact in f32, scaled by ldexp in f32 (exact), signed, then
                    # the native f32 -> bf16 fptrunc as the single rounding (cq-b7e).
                    self.intrinsic(f"llvm.ctlz.i{n}", f"i{n}", [f"i{n}", "i1"])
                    self.intrinsic("llvm.ldexp.f32.i32", "float", ["float", "i32"])
                    for op in ("sitofp", "uitofp"):
                        self.add(op, "", it, t, [it], t, JAM(n, "float", "f32", op == "sitofp", 24, "bfloat"))
                if t in ("f16", "bf16") and (n > 64 if t == "f16" else n > 128):
                    # bf16 -> N > 128 is ExpandLargeFpConvert on the bfloat itself, which reads an
                    # sNaN's payload unquieted (0x7f81 -> 0x81 << 121); the f32 route quiets it
                    # (0xc1 << 121), as for f16 below.
                    # fptosi/fptoui f16 -> N > 64: LLVM 19 lowers 65..128 to __fixhfti/__fixunshfti
                    # (missing as above) and N > 128 to code that is not the f32 route (f16 Inf ->
                    # i129 gives -2^31). CR §2 says f16 goes via f32, so the reference is the f32
                    # route; the f16 -> f32 step is fpext + quieting (the quiet NaN of BACKEND_ABI
                    # §2.6, see fpext above).
                    # (an arithmetic fence keeps InstCombine from folding the fpext back in)
                    self.intrinsic("llvm.arithmetic.fence.f32", "float", ["float"])
                    for op in ("fptosi", "fptoui"):
                        self.add(op, "", t, it, [t], it, [f"%e = fpext {FP[t]} %a0 to float"] + QUIET("%e", "%q") + [
                                                          "%f = call float @llvm.arithmetic.fence.f32(float %q)",
                                                          f"%r = {op} float %f to i{n}"])
                    continue
                if t == "f32" and n > 128:
                    for op in ("fptosi", "fptoui"):
                        self.add(op, "", t, it, [t], it, [f"%r = {op} {FP[t]} %a0 to i{n}"])
                    continue
                if not (t == "bf16" and n > 24):
                    for op in ("sitofp", "uitofp"):
                        self.add(op, "", it, t, [it], t, [f"%r = {op} i{n} %a0 to {FP[t]}"])
                for op in ("fptosi", "fptoui"):
                    self.add(op, "", t, it, [t], it, [f"%r = {op} {FP[t]} %a0 to i{n}"])

    def write(self, out):
        out = Path(out)
        out.mkdir(parents=True, exist_ok=True)
        ll = ['; generated by tests/tmpl-fpmisc/gen_native.py; do not edit',
              'target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"',
              'target triple = "x86_64-apple-macosx16.0.0"', "",
              "@fpmisc.one = global float 1.0", ""]
        ll += self.fns + [""] + sorted(self.decls) + ["", ATTRS, ""]
        (out / "native.ll").write_text("\n".join(ll))
        (out / "cases.inc").write_text("\n".join(self.cases) + "\n")


def ty_suffix(t):
    return {"f16": "f16", "bf16": "bf16", "f32": "f32", "f64": "f64"}[t]


if __name__ == "__main__":
    g = Gen()
    g.build()
    g.write(sys.argv[1])
