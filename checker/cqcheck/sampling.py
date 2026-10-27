"""Checker input sampling (cq-w0-chk-drivers): DriverSpec to SampleSet.

Sample encoding (every consumer renders it with `drivers.c_value`): `{"call": i, "args": [...]}`
where `i` indexes DriverSpec.calls and each argument is

  * a scalar: the hex bit pattern of the C value at its storage width, "0x..." (`_Bool` "0x0" or
    "0x1"; `long double` the 80-bit x87 pattern);
  * a pointer: the C expression of the drivers.txt call, never varied.

Samples 0 .. len(calls)-1 are the drivers.txt calls themselves (the baseline), in order.

Classes (SampleSet.classes; every class is present, and a class with nothing in it says why):

  edge          per call: every quantum scalar input over 0, +-1, MIN, MAX (fp: 0, +-1, +-MAX,
                +-smallest normal), crossed when the product is small, one input at a time otherwise.
  specials      per call: every fp quantum input over +-0, +-Inf, NaN (quiet, negative with payload,
                signalling) and the smallest subnormal.
  exhaustive    per call: every input when the call's quantum scalar inputs total <= 16 bits.
  random_seed   {"seed", "quantum": per call, "classical": per call}: a seeded random set over the
                quantum inputs (classical arguments at their drivers.txt values) and a seeded set
                over the classical arguments.
  totalization  {"rows": [...]}: one entry per CR §2 row an instruction of the example can reach
                (site, row, the samples that hit it), or the reason it is empty.
  trips         {"K": 4, "loops": [...]}: per loop, a sample giving trip counts 0, K-1, K, K+1,
                or the reason the search found that count unreachable.

Per-call classes are `{"<call>": {"samples": [...]}}` or `{"<call>": {"empty": "<reason>"}}`.

The totalization rows and the trip counts are found by searching with a probe build of the
example's .O1.ll (`ProbeBuild`): the module with `cq_theta_*`/`cq_measure_*` as the identity,
`cq_phi` as a no-op, a probe before (or after) every instruction a §2 row names that logs its
operand values, an object table over globals, allocas, heap blocks and driver objects that turns
an address into (offset, object size), and a counter on every loop header. The probe build only
finds candidate inputs; it decides nothing about correctness. The trip samples are confirmed by
the C oracle's trip counters (`confirm_trips`).

Which candidates are kept: a quantum sample (edge, specials, exhaustive, random) is always kept.
A classical-set or search candidate is kept only when its probe run returns, or traps right after
a probe that hit a trapping §2 row (division by zero, INT_MIN / -1): a candidate on which the C
program itself does not terminate or faults (a negative VLA size, a read past a driver object) is
outside the program's input domain.
"""
from __future__ import annotations

import hashlib
import json
import math
import os
import random
import re

import struct
import subprocess
import tempfile
import threading
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path
from typing import Callable, Dict, List, Optional, Sequence, Set, Tuple

from cqcheck import drivers as D
from cqcheck.contracts import DriverSpec, SampleSet

K = 4
SEED = 20261027
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
EXHAUSTIVE_BITS = 16
N_RANDOM_QUANTUM = 32
N_RANDOM_CLASSICAL = 16
CROSS_LIMIT = 1024
SEARCH_BUDGET = 384          # probe runs per unmet target
SEARCH_BATCH = 48
PER_SAMPLE_MS = 250
PROBE_PROCS = int(os.environ.get("CQ_PROBE_PROCS", "4"))


# ------------------------------------------------------------------------------------------------
# Value encoding
# ------------------------------------------------------------------------------------------------

def hexw(ct: D.CType, bits: int) -> str:
    w = ct.storage_bits
    bits &= (1 << w) - 1
    if ct.bits == 1:
        return "0x1" if bits & 1 else "0x0"
    return "0x" + format(bits, "0%dx" % ((w + 3) // 4))


def f64_bits(x: float) -> int:
    return struct.unpack("<Q", struct.pack("<d", x))[0]


def f32_bits(x: float) -> int:
    return struct.unpack("<I", struct.pack("<f", x))[0]


def f80_from_fraction(q: Fraction) -> int:
    """Round-to-nearest-even x87 extended encoding of a rational."""
    if q == 0:
        return 0
    sign = 1 if q < 0 else 0
    q = abs(q)
    e = q.numerator.bit_length() - q.denominator.bit_length()
    if Fraction(2) ** e > q:
        e -= 1
    while Fraction(2) ** (e + 1) <= q:
        e += 1
    # q in [2^e, 2^(e+1)); mantissa 64 bits with the explicit integer bit
    m = q / (Fraction(2) ** (e - 63))
    mi = m.numerator // m.denominator
    rem = m - mi
    if rem > Fraction(1, 2) or (rem == Fraction(1, 2) and mi & 1):
        mi += 1
    if mi >> 64:
        mi >>= 1
        e += 1
    be = e + 16383
    if be <= 0 or be >= 0x7fff:
        D.unimplemented(f"f80 literal out of the normal range: {q}")
    return (sign << 79) | (be << 64) | mi


def f80_from_float(x: float) -> int:
    if math.isnan(x):
        return (0x7fff << 64) | (0xC000000000000000)
    if math.isinf(x):
        return ((1 if x < 0 else 0) << 79) | (0x7fff << 64) | (1 << 63)
    if x == 0:
        return (1 << 79) if math.copysign(1, x) < 0 else 0
    return f80_from_fraction(Fraction(x))


def encode_c_literal(ct: D.CType, text: str) -> str:
    """A drivers.txt argument as a sample value."""
    if ct.kind == "p":
        return text.strip()
    t = text.strip()
    if ct.kind == "i":
        if not re.fullmatch(r"[-+0-9xXa-fA-FuUlL()\s]+", t):
            D.unimplemented(f"integer literal {text!r}")
        v = eval(re.sub(r"(?<=[0-9a-fA-F])[uUlL]+", "", t), {"__builtins__": {}})  # digits, signs only
        return hexw(ct, int(v))
    q = Fraction(t) if not re.search(r"[xX]", t) else Fraction(float.fromhex(t))
    if ct.bits == 32:
        return hexw(ct, f32_bits(float(q)))
    if ct.bits == 64:
        return hexw(ct, f64_bits(float(q)))
    return hexw(ct, f80_from_fraction(q) if q != 0 else 0)


def fp_kind(bits: int, w: int) -> Tuple[str, Optional[Fraction]]:
    """('nan'|'inf'|'zero'|'sub'|'norm'|'noncanon', value) of an fp bit pattern of width w."""
    if w == 80:
        exp = (bits >> 64) & 0x7fff
        mant = bits & ((1 << 64) - 1)
        sign = -1 if bits >> 79 & 1 else 1
        ib = mant >> 63
        if exp == 0x7fff:
            if not ib:
                return "noncanon", None
            return ("inf", None) if mant == 1 << 63 else ("nan", None)
        if exp == 0:
            if mant == 0:
                return "zero", Fraction(0)
            return ("noncanon" if ib else "sub"), sign * Fraction(mant) * Fraction(2) ** (1 - 16383 - 63)
        if not ib:
            return "noncanon", None
        return "norm", sign * Fraction(mant) * Fraction(2) ** (exp - 16383 - 63)
    eb, mb = {16: (5, 10), 17: (8, 7), 32: (8, 23), 64: (11, 52)}[w]
    w = _fp_storage(w)
    exp = (bits >> mb) & ((1 << eb) - 1)
    mant = bits & ((1 << mb) - 1)
    sign = -1 if bits >> (w - 1) & 1 else 1
    bias = (1 << (eb - 1)) - 1
    if exp == (1 << eb) - 1:
        return ("inf", None) if mant == 0 else ("nan", None)
    if exp == 0:
        if mant == 0:
            return "zero", Fraction(0)
        return "sub", sign * Fraction(mant) * Fraction(2) ** (1 - bias - mb)
    return "norm", sign * Fraction((1 << mb) | mant) * Fraction(2) ** (exp - bias - mb)


def int_edges(ct: D.CType) -> List[int]:
    w = ct.bits
    if w == 1:
        return [0, 1]
    m = (1 << w) - 1
    if ct.signed:
        return [0, 1, m, 1 << (w - 1), (1 << (w - 1)) - 1]       # 0, 1, -1, MIN, MAX
    return [0, 1, m, 1 << (w - 1)]                                 # 0, 1, MAX (= -1), 2^(W-1)


def fp_edges(ct: D.CType) -> List[int]:
    if ct.bits == 32:
        vals = [0.0, 1.0, -1.0, 3.4028234663852886e38, -3.4028234663852886e38, 1.1754943508222875e-38,
                -1.1754943508222875e-38]
        return [f32_bits(v) for v in vals]
    if ct.bits == 64:
        vals = [0.0, 1.0, -1.0, 1.7976931348623157e308, -1.7976931348623157e308, 2.2250738585072014e-308,
                -2.2250738585072014e-308]
        return [f64_bits(v) for v in vals]
    mx = (0x7ffe << 64) | ((1 << 64) - 1)
    mn = (1 << 64) | (1 << 63)
    return [0, f80_from_float(1.0), f80_from_float(-1.0), mx, mx | (1 << 79), mn, mn | (1 << 79)]


def fp_specials(ct: D.CType) -> List[int]:
    if ct.bits == 32:
        return [0, 0x80000000, 0x7f800000, 0xff800000, 0x7fc00000, 0xffc12345, 0x7fa00000, 0x00000001]
    if ct.bits == 64:
        return [0, 1 << 63, 0x7ff0000000000000, 0xfff0000000000000, 0x7ff8000000000000,
                0xfff8000000012345, 0x7ff4000000000000, 1]
    inf = (0x7fff << 64) | (1 << 63)
    return [0, 1 << 79, inf, inf | (1 << 79), (0x7fff << 64) | 0xC000000000000000,
            (1 << 79) | (0x7fff << 64) | 0xC000000000012345, (0x7fff << 64) | 0xA000000000000000, 1]


def f80_noncanonical() -> List[int]:
    """Pseudo-NaN, pseudo-Inf, unnormal and pseudo-denormal x87 encodings (CR §2)."""
    return [(0x7fff << 64) | 0x4000000000000000, (0x7fff << 64), (0x3fff << 64) | 0x4000000000000000,
            (1 << 63) | 1]


# ------------------------------------------------------------------------------------------------
# Probe build
# ------------------------------------------------------------------------------------------------

RUNTIME_C = r"""
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdbool.h>
#include <sys/wait.h>
#include <sys/time.h>
#define CAP 64
static char cqd_buf[1 << 22]; static size_t cqd_len;
static int cqd_out_fd = -1;
static void cqd_out(const char *fmt, ...) {
    if (cqd_len > sizeof cqd_buf - 256) return;
    va_list ap; va_start(ap, fmt);
    int n = vsnprintf(cqd_buf + cqd_len, sizeof cqd_buf - cqd_len, fmt, ap);
    va_end(ap); if (n > 0) cqd_len += (size_t)n;
}
static unsigned char cqd_pcount[65536], cqd_mcount[65536];
void __cqd_p(int site, uint64_t a0, uint64_t a1, uint64_t b0, uint64_t b1, uint64_t c0, uint64_t c1,
             uint64_t r0, uint64_t r1) {
    if (cqd_pcount[site & 0xffff] >= CAP) return; cqd_pcount[site & 0xffff]++;
    cqd_out("p %d %llx %llx %llx %llx %llx %llx %llx %llx\n", site, (unsigned long long)a0, (unsigned long long)a1,
            (unsigned long long)b0, (unsigned long long)b1, (unsigned long long)c0, (unsigned long long)c1,
            (unsigned long long)r0, (unsigned long long)r1);
}
#define NOBJ 65536
static uintptr_t cqd_ob[NOBJ]; static uint64_t cqd_os[NOBJ]; static int cqd_nob;
void __cqd_reg(void *p, uint64_t size) {
    uintptr_t b = (uintptr_t)p; if (!b) return;
    int j = 0;
    for (int i = 0; i < cqd_nob; i++)
        if (!(cqd_ob[i] < b + (size ? size : 1) && b < cqd_ob[i] + (cqd_os[i] ? cqd_os[i] : 1))) {
            cqd_ob[j] = cqd_ob[i]; cqd_os[j] = cqd_os[i]; j++; }
    cqd_nob = j;
    if (cqd_nob < NOBJ) { cqd_ob[cqd_nob] = b; cqd_os[cqd_nob] = size; cqd_nob++; }
}
void __cqd_m(int site, void *root, void *addr) {
    if (cqd_mcount[site & 0xffff] >= CAP) return; cqd_mcount[site & 0xffff]++;
    uintptr_t r = (uintptr_t)root; int best = -1;
    for (int i = 0; i < cqd_nob; i++)
        if (cqd_ob[i] <= r && (best < 0 || cqd_ob[i] > cqd_ob[best])) best = i;
    if (best < 0) { cqd_out("m %d ? ?\n", site); return; }
    long long off = (long long)((intptr_t)addr - (intptr_t)cqd_ob[best]);
    cqd_out("m %d %lld %llu\n", site, off, (unsigned long long)cqd_os[best]);
}
#define NLOOP 4096
static long long cqd_cnt[NLOOP]; static unsigned char cqd_has[NLOOP], cqd_ctx[NLOOP], cqd_ent[NLOOP];
static unsigned char cqd_tc[NLOOP];
static void cqd_trip(int l, long long n) { if (cqd_tc[l] < CAP) { cqd_tc[l]++; cqd_out("t %d %lld\n", l, n); } }
void __cqd_hdr(int l, bool be) {
    if (!be || !cqd_has[l]) { if (cqd_has[l]) cqd_trip(l, cqd_cnt[l]); cqd_cnt[l] = 1; cqd_has[l] = 1; }
    else cqd_cnt[l]++;
    cqd_ent[l] = 1;
}
void __cqd_ctx(int l) {
    if (cqd_ctx[l] && !cqd_ent[l]) cqd_trip(l, 0);
    cqd_ctx[l] = 1; cqd_ent[l] = 0;
}
static int cqd_done;
static void cqd_finish(const char *how, int code) {
    if (cqd_done) return; cqd_done = 1;
    for (int l = 0; l < NLOOP; l++) {
        if (cqd_has[l]) cqd_trip(l, cqd_cnt[l]);
        if (cqd_ctx[l] && !cqd_ent[l]) cqd_trip(l, 0);
    }
    cqd_out("E %s %d\n", how, code);
    size_t o = 0; while (o < cqd_len) { ssize_t w = write(cqd_out_fd, cqd_buf + o, cqd_len - o); if (w <= 0) break; o += (size_t)w; }
}
static void cqd_sig(int s) { cqd_finish(s == SIGALRM ? "timeout" : "signal", s); _exit(100 + s); }
static void cqd_atexit(void) { cqd_finish("exit", 0); }
void cqd_end(void) { cqd_finish("exit", 0); _exit(0); }
static void cqd_child(int idx) {
    cqd_out("S %d\n", idx);
    int sigs[] = {SIGSEGV, SIGFPE, SIGBUS, SIGILL, SIGALRM, SIGABRT, SIGTRAP};
    for (unsigned i = 0; i < sizeof sigs / sizeof *sigs; i++) signal(sigs[i], cqd_sig);
    atexit(cqd_atexit);
    struct itimerval it = {{0, 0}, {PER_SAMPLE_MS / 1000, (PER_SAMPLE_MS % 1000) * 1000}};
    setitimer(ITIMER_REAL, &it, 0);
}
static void cqd_load(void *dst, size_t n, const char *hex) {
    unsigned char b[16] = {0}; size_t len = strlen(hex);
    if (len > 2 && hex[0] == '0' && (hex[1] == 'x' || hex[1] == 'X')) { hex += 2; len -= 2; }
    for (size_t i = 0; i < len && i < 32; i++) {
        char c = hex[len - 1 - i]; int v = (c >= '0' && c <= '9') ? c - '0' : (c | 32) - 'a' + 10;
        b[i / 2] |= (unsigned char)(v << (4 * (i % 2)));
    }
    memcpy(dst, b, n);
}
"""


@dataclass
class Site:
    id: int
    fn: str
    inst: str
    kind: str                     # div shift fsh fptoi fpres frem minmax ctz abs angle mem
    op: str                       # opcode or callee
    types: List[str]              # operand types (scalar element types)
    width: int = 0                # integer width W of the row (div, shift, fsh, ctz, abs)
    to_bits: int = 0              # fptoi destination width
    to_signed: bool = False
    consts: Dict[int, Optional[int]] = field(default_factory=dict)   # operand slot -> constant bits

    def key(self) -> str:
        return f"{self.fn}: {self.inst}"


@dataclass
class Loop:
    id: int
    fn: str
    header: str
    parent: Optional[int]
    blocks: Set[str]

    def key(self) -> str:
        """T1 (cq-mia): "<fn>:<header>", fn without "@", the header label as an operand."""
        return f"{self.fn[1:]}:{self.header}"


_FLAGS = {"nuw", "nsw", "exact", "disjoint", "fast", "nnan", "ninf", "nsz", "arcp", "contract", "afn",
          "reassoc", "nneg", "samesign", "tail", "musttail", "notail"}
_SCALAR_FP = {"half": 16, "bfloat": 17, "float": 32, "double": 64, "x86_fp80": 80}   # 17: bf16 (16 bits)


def _fp_storage(w: int) -> int:
    return 16 if w == 17 else w


def split_type(s: str) -> Tuple[str, str]:
    """(type, rest) for a text that starts with an LLVM type."""
    s = s.strip()
    if s[0] in "<[{":
        close = {"<": ">", "[": "]", "{": "}"}[s[0]]
        depth = 0
        for i, ch in enumerate(s):
            if ch == s[0]:
                depth += 1
            elif ch == close:
                depth -= 1
                if depth == 0:
                    return s[:i + 1], s[i + 1:].strip()
    m = re.match(r"([^\s,]+)", s)
    t = m.group(1)
    return t, s[len(t):].strip()


def vec_of(ty: str) -> Tuple[int, str]:
    m = re.fullmatch(r"<\s*(\d+)\s+x\s+(\S+)\s*>", ty)
    return (int(m.group(1)), m.group(2)) if m else (0, ty)


def int_width(ty: str) -> int:
    m = re.fullmatch(r"i(\d+)", ty)
    return int(m.group(1)) if m else 0


def const_bits(ty: str, v: str) -> Optional[int]:
    """The bit pattern of a scalar constant operand, or None when v is not a constant."""
    v = v.strip()
    if v.startswith("%") or v.startswith("@"):
        return None
    w = int_width(ty)
    if w:
        if v in ("true", "false"):
            return 1 if v == "true" else 0
        if re.fullmatch(r"-?\d+", v):
            return int(v) & ((1 << w) - 1)
        if v in ("poison", "undef", "zeroinitializer"):
            return 0
        return None
    if ty in _SCALAR_FP:
        if v.startswith("0xK"):
            return int(v[3:], 16)
        if v.startswith("0xH") or v.startswith("0xR"):
            return int(v[3:], 16)
        if v.startswith("0x"):
            b = int(v[2:], 16)
            if ty == "float":       # LLVM prints float constants as the double pattern
                return f32_bits(struct.unpack("<d", struct.pack("<Q", b))[0])
            return b
        try:
            x = float(v)
        except ValueError:
            return None
        return {16: lambda: struct.unpack("<H", struct.pack("<e", x))[0], 17: lambda: f32_bits(x) >> 16,
                32: lambda: f32_bits(x),
                64: lambda: f64_bits(x), 80: lambda: f80_from_float(x)}[_SCALAR_FP[ty]]()
    return None


def _operand_pairs(text: str) -> List[Tuple[str, str]]:
    """(type, value) of each call argument or typed operand."""
    out = []
    for a in D.split_operands(text):
        ty, rest = split_type(a)
        val = rest.split()[-1] if rest.split() else ""
        out.append((ty, val))
    return out


class Instrumenter:
    """Rewrites a .O1.ll into the probe build."""

    def __init__(self, mod: D.Module):
        self.mod = mod
        self.sites: List[Site] = []
        self.loops: List[Loop] = []
        self.n = 0

    def tmp(self) -> str:
        self.n += 1
        return f"%__cqd{self.n}"

    # bits of one scalar value: (lines, lo, hi)
    def bits(self, ty: str, v: str) -> Tuple[List[str], str, str]:
        if v.startswith("@"):
            t = self.tmp()
            return [f"{t} = ptrtoint ptr {v} to i64"], t, "0"
        if not v.startswith("%"):
            c = const_bits(ty, v)
            if c is None:
                if ty == "ptr":
                    return [], "0", "0"
                D.unimplemented(f"probe of constant {ty} {v}")
            return [], str(c & ((1 << 64) - 1)), str(c >> 64)
        lines: List[str] = []
        if ty in _SCALAR_FP:
            w = _fp_storage(_SCALAR_FP[ty])
            t = self.tmp()
            lines.append(f"{t} = bitcast {ty} {v} to i{w}")
            ty, v = f"i{w}", t
        if ty == "ptr":
            t = self.tmp()
            return [f"{t} = ptrtoint ptr {v} to i64"], t, "0"
        w = int_width(ty)
        if not w:
            D.unimplemented(f"probe of type {ty}")
        if w < 64:
            t = self.tmp()
            lines.append(f"{t} = zext {ty} {v} to i64")
            return lines, t, "0"
        if w == 64:
            return lines, v, "0"
        if w > 128:
            D.unimplemented(f"probe of i{w}")
        lo, sh, hi = self.tmp(), self.tmp(), self.tmp()
        lines += [f"{lo} = trunc {ty} {v} to i64", f"{sh} = lshr {ty} {v}, 64", f"{hi} = trunc {ty} {sh} to i64"]
        return lines, lo, hi

    def probe(self, site: int, ops: List[Tuple[str, str]], res: Optional[Tuple[str, str]]) -> List[str]:
        """A __cqd_p call per vector lane (one for a scalar)."""
        allv = ops + ([res] if res else [])
        lanes = max((vec_of(t)[0] for t, _ in allv), default=0)
        out: List[str] = []
        for lane in range(max(lanes, 1)):
            args = []
            for t, v in ops + [("", "")] * (3 - len(ops)) + [res or ("", "")]:
                if not t:
                    args += ["i64 0", "i64 0"]
                    continue
                n, et = vec_of(t)
                if n:
                    if v.startswith("%"):
                        e = self.tmp()
                        out.append(f"{e} = extractelement {t} {v}, i32 {lane}")
                        v = e
                    else:
                        D.unimplemented(f"probe of vector constant {t} {v}")
                    t = et
                ls, lo, hi = self.bits(t, v)
                out += ls
                args += [f"i64 {lo}", f"i64 {hi}"]
            out.append(f"call void @__cqd_p(i32 {site}, {', '.join(args)})")
        return out

    def add_site(self, f: D.Function, ins: D.Inst, kind: str, op: str, ops: List[Tuple[str, str]], **kw) -> Site:
        s = Site(len(self.sites), f.name, ins.text, kind, op,
                 [vec_of(t)[1] for t, _ in ops], **kw)
        s.consts = {i: const_bits(vec_of(t)[1], v) for i, (t, v) in enumerate(ops)}
        self.sites.append(s)
        return s

    # ---- loops -------------------------------------------------------------------------------
    def find_loops(self, f: D.Function) -> List[Loop]:
        preds = f.preds()
        order = f.order
        entry = order[0]
        # reverse postorder
        seen, post = set(), []

        def dfs(b):
            stack = [(b, iter(f.blocks[b][-1].successors()))]
            seen.add(b)
            while stack:
                n, it = stack[-1]
                nxt = next(it, None)
                if nxt is None:
                    stack.pop()
                    post.append(n)
                elif nxt not in seen and nxt in f.blocks:
                    seen.add(nxt)
                    stack.append((nxt, iter(f.blocks[nxt][-1].successors())))
        dfs(entry)
        rpo = post[::-1]
        num = {b: i for i, b in enumerate(rpo)}
        idom = {entry: entry}

        def inter(a, b):
            while a != b:
                while num[a] > num[b]:
                    a = idom[a]
                while num[b] > num[a]:
                    b = idom[b]
            return a
        changed = True
        while changed:
            changed = False
            for b in rpo[1:]:
                ps = [p for p in preds.get(b, []) if p in idom]
                if not ps:
                    continue
                new = ps[0]
                for p in ps[1:]:
                    new = inter(p, new)
                if idom.get(b) != new:
                    idom[b] = new
                    changed = True

        def dominates(a, b):
            while True:
                if a == b:
                    return True
                if b == entry:
                    return False
                b = idom[b]
        loops: Dict[str, Set[str]] = {}
        for b in rpo:
            for s in f.blocks[b][-1].successors():
                if s in num and num[s] <= num[b]:
                    if not dominates(s, b):
                        D.unimplemented(f"irreducible cycle in {f.name} ({b} -> {s})")
                    body = loops.setdefault(s, {s})
                    work = [b]
                    while work:
                        x = work.pop()
                        if x not in body:
                            body.add(x)
                            work += [p for p in preds.get(x, []) if p in num]
        out = []
        for h in sorted(loops, key=lambda h: num[h]):
            out.append(Loop(0, f.name, h, None, loops[h]))
        for lp in out:
            cands = [o for o in out if o is not lp and lp.header in o.blocks and lp.blocks <= o.blocks]
            if cands:
                par = min(cands, key=lambda o: len(o.blocks))
                lp.parent = out.index(par)
        return out

    # ---- the rewrite -------------------------------------------------------------------------
    def rewrite(self) -> str:
        mod = self.mod
        out_lines: List[str] = []
        fn_text: Dict[str, List[str]] = {}
        for f in mod.functions.values():
            fn_text[f.name] = self.rewrite_function(f)
        i = 0
        lines = mod.lines
        while i < len(lines):
            line = lines[i]
            s = D.strip_comment(line)
            if s.startswith("define "):
                m = re.search(r"(@(?:\"[^\"]*\"|[-A-Za-z$._0-9]+))\(", s)
                out_lines.append(line)
                out_lines += fn_text[m.group(1)]
                while not lines[i].startswith("}"):
                    i += 1
                out_lines.append("}")
                i += 1
                continue
            out_lines.append(line)
            i += 1
        out_lines += self.decls()
        return "\n".join(out_lines) + "\n"

    def decls(self) -> List[str]:
        d = ["declare void @__cqd_p(i32, i64, i64, i64, i64, i64, i64, i64, i64)",
             "declare void @__cqd_m(i32, ptr, ptr)", "declare void @__cqd_reg(ptr, i64)",
             "declare void @__cqd_hdr(i32, i1)", "declare void @__cqd_ctx(i32)"]
        d.append("define void @__cqd_globals() {")
        for g, line in self.mod.globals.items():
            m = re.search(r"\b(?:global|constant)\s+(.*)$", D.strip_comment(line))
            if not m or "thread_local" in line:
                continue
            ty, _ = split_type(m.group(1))
            d.append(f"  call void @__cqd_reg(ptr {g}, i64 ptrtoint (ptr getelementptr ({ty}, ptr null, i32 1) to i64))")
        d += ["  ret void", "}"]
        return d

    def rewrite_function(self, f: D.Function) -> List[str]:
        loops = self.find_loops(f)
        base = len(self.loops)
        for k, lp in enumerate(loops):
            lp.id = base + k
            if lp.parent is not None:
                lp.parent += base
        self.loops += loops
        by_header = {lp.header: lp for lp in loops}
        children: Dict[Optional[int], List[Loop]] = {}
        for lp in loops:
            children.setdefault(lp.parent, []).append(lp)
        preds = f.preds()
        body: List[str] = []
        for bi, b in enumerate(f.order):
            if bi > 0:
                body.append(f"{b[1:]}:")
            insts = f.blocks[b]
            pre: List[str] = []
            if bi == 0:
                pre += [f"call void @__cqd_ctx(i32 {lp.id})" for lp in children.get(None, [])]
            phis = [x for x in insts if x.op == "phi"]
            rest = [x for x in insts if x.op != "phi"]
            if b in by_header:
                lp = by_header[b]
                be = self.tmp()
                inc = ", ".join(f"[ {'true' if p in lp.blocks else 'false'}, {p} ]" for p in preds[b])
                body.append(f"  {be} = phi i1 {inc}")
            body += ["  " + x.text for x in phis]
            if b in by_header:
                lp = by_header[b]
                body.append(f"  call void @__cqd_hdr(i32 {lp.id}, i1 {be})")
                pre += [f"call void @__cqd_ctx(i32 {c.id})" for c in children.get(lp.id, [])]
            body += ["  " + x for x in pre]
            for ins in rest:
                before, after = self.instrument(f, ins)
                body += ["  " + x for x in before]
                body.append("  " + ins.text)
                body += ["  " + x for x in after]
        return body

    def instrument(self, f: D.Function, ins: D.Inst) -> Tuple[List[str], List[str]]:
        op = ins.op
        rhs = ins.text.split("=", 1)[1].strip() if ins.dest else ins.text
        if op in ("udiv", "sdiv", "urem", "srem", "shl", "lshr", "ashr", "fadd", "fsub", "fmul", "fdiv", "frem"):
            words = rhs.split()
            j = 1
            while words[j] in _FLAGS:
                j += 1
            tail = " ".join(words[j:])
            ty, rest = split_type(tail)
            a, b = [x.strip() for x in D.split_operands(rest)]
            ops = [(ty, a), (ty, b)]
            et = vec_of(ty)[1]
            if op in ("udiv", "sdiv", "urem", "srem"):
                s = self.add_site(f, ins, "div", op, ops, width=int_width(et))
                return self.probe(s.id, ops, None), []
            if op in ("shl", "lshr", "ashr"):
                s = self.add_site(f, ins, "shift", op, ops, width=int_width(et))
                return self.probe(s.id, ops, None), []
            s = self.add_site(f, ins, "frem" if op == "frem" else "fpres", op, ops)
            return [], self.probe(s.id, ops, (ty, ins.dest))
        if op in ("fptosi", "fptoui"):
            m = re.match(r"\w+\s+(.*)\s+to\s+(\S+)$", rhs)
            ty, rest = split_type(m.group(1))
            to = vec_of(m.group(2))[1]
            ops = [(ty, rest.strip())]
            s = self.add_site(f, ins, "fptoi", op, ops, to_bits=int_width(to), to_signed=(op == "fptosi"))
            return self.probe(s.id, ops, None), []
        if op == "call" and ins.callee:
            c = ins.callee
            pairs = _operand_pairs(", ".join(ins.call_args))
            ret_ty = None
            if ins.dest:
                m = re.search(r"call\s+(?:\w+\s+)*?(\S+|<[^>]*>)\s+@", ins.text)
                rt = re.search(r"\bcall\b(.*?)@", ins.text).group(1).split()
                rt = [w for w in rt if w not in _FLAGS and w not in ("noundef", "zeroext", "signext", "fastcc",
                                                                       "nnan", "ninf", "nsz", "arcp")]
                ret_ty = " ".join(rt) if rt else None
            base = re.sub(r"\.(?:[a-z]\d+|v\d+[a-z]\d+|p0)+$", "", c)
            if base in ("@llvm.fshl", "@llvm.fshr"):
                s = self.add_site(f, ins, "fsh", c, pairs, width=int_width(vec_of(pairs[0][0])[1]))
                return self.probe(s.id, pairs, None), []
            if base in ("@llvm.ctlz", "@llvm.cttz"):
                s = self.add_site(f, ins, "ctz", c, pairs[:1], width=int_width(vec_of(pairs[0][0])[1]))
                return self.probe(s.id, pairs[:1], None), []
            if base == "@llvm.abs":
                s = self.add_site(f, ins, "abs", c, pairs[:1], width=int_width(vec_of(pairs[0][0])[1]))
                return self.probe(s.id, pairs[:1], None), []
            if base in ("@llvm.maxnum", "@llvm.minnum"):
                s = self.add_site(f, ins, "minmax", c, pairs)
                return self.probe(s.id, pairs, None), []
            if base in ("@llvm.fma", "@llvm.fmuladd", "@llvm.sqrt"):
                s = self.add_site(f, ins, "fpres", c, pairs)
                return [], self.probe(s.id, pairs, (ret_ty, ins.dest))
            cm = re.match(r"@llvm\.experimental\.constrained\.(\w+)\.", c)
            if cm:
                kind = cm.group(1)
                data = [p for p in pairs if p[0] != "metadata"]
                if kind in ("fadd", "fsub", "fmul", "fdiv", "fma", "sqrt", "fmuladd"):
                    s = self.add_site(f, ins, "fpres", c, data)
                    return [], self.probe(s.id, data, (ret_ty, ins.dest))
                if kind == "frem":
                    s = self.add_site(f, ins, "frem", c, data)
                    return [], self.probe(s.id, data, (ret_ty, ins.dest))
                if kind in ("fptosi", "fptoui"):
                    tob = int(re.match(r"@llvm\.experimental\.constrained\.\w+\.i(\d+)", c).group(1))
                    s = self.add_site(f, ins, "fptoi", c, data[:1], to_bits=tob, to_signed=(kind == "fptosi"))
                    return self.probe(s.id, data[:1], None), []
                return [], []
            if c.startswith("@cq_theta_"):
                s = self.add_site(f, ins, "angle", c, pairs[1:2])
                return self.probe(s.id, pairs[1:2], None), []
            if c == "@cq_phi":
                s = self.add_site(f, ins, "angle", c, pairs[0:1])
                return self.probe(s.id, pairs[0:1], None), []
            if c in ("@malloc", "@calloc", "@realloc", "@aligned_alloc") and ins.dest:
                vals = [v for _, v in pairs]
                if c == "@malloc":
                    return [], [f"call void @__cqd_reg(ptr {ins.dest}, i64 {vals[0]})"]
                if c == "@aligned_alloc":
                    return [], [f"call void @__cqd_reg(ptr {ins.dest}, i64 {vals[1]})"]
                if c == "@realloc":
                    return [], [f"call void @__cqd_reg(ptr {ins.dest}, i64 {vals[1]})"]
                t = self.tmp()
                return [], [f"{t} = mul i64 {vals[0]}, {vals[1]}", f"call void @__cqd_reg(ptr {ins.dest}, i64 {t})"]
            return [], []
        if op == "alloca":
            m = re.match(r"alloca\s+(?:inalloca\s+)?(.*)$", rhs)
            ty, rest = split_type(m.group(1))
            cnt = None
            parts = D.split_operands(rest.lstrip(","))
            if parts and not parts[0].startswith("align") and not parts[0].startswith("addrspace"):
                cty, cv = split_type(parts[0])
                cnt = (cty, cv.split()[-1])
            size = f"ptrtoint (ptr getelementptr ({ty}, ptr null, i32 1) to i64)"
            after = []
            if cnt:
                cty, cv = cnt
                if cty != "i64":
                    t = self.tmp()
                    after.append(f"{t} = zext {cty} {cv} to i64")
                    cv = t
                t2 = self.tmp()
                after.append(f"{t2} = mul i64 {size}, {cv}")
                size = t2
            after.append(f"call void @__cqd_reg(ptr {ins.dest}, i64 {size})")
            return [], after
        if op in ("load", "store"):
            ptr_txt = ins.operands[1]
            pv = ptr_txt.split()[-1]
            if not pv.startswith("%"):
                return [], []
            root, variable = self.addr_root(f, pv)
            if not variable:
                return [], []
            s = self.add_site(f, ins, "mem", op, [])
            return [f"call void @__cqd_m(i32 {s.id}, ptr {root}, ptr {pv})"], []
        return [], []

    def addr_root(self, f: D.Function, v: str) -> Tuple[str, bool]:
        """Walk GEPs back to the base value; variable = some GEP index is not a constant, or the
        base is a phi/select (pointer induction, a pointer chosen at run time)."""
        variable = False
        for _ in range(64):
            d = f.defs.get(v)
            if d is None or d.op != "getelementptr":
                if d is not None and d.op in ("phi", "select"):
                    variable = True
                return v, variable
            parts = d.operands
            for idx in parts[2:]:
                if "%" in idx:
                    variable = True
            base = parts[1].split()[-1]
            if not base.startswith("%"):
                return base, variable
            v = base
        return v, variable


def _driver_main(spec: DriverSpec) -> str:
    """The probe driver: setup once, then per stdin line `idx call hex...` a forked child runs
    that call with those argument bits."""
    out = [D.DRIVER_PRELUDE, "#include <stdio.h>\n#include <stdlib.h>\n#include <unistd.h>\n#include <fcntl.h>\n"
           "#include <signal.h>\n#include <sys/wait.h>",
           "void __cqd_reg(void *, unsigned long long); void __cqd_globals(void);",
           "void cqd_child(int); void cqd_end(void); void cqd_load(void *, unsigned long, const char *); extern int cqd_out_fd;"]
    out += spec.protos
    out.append("int main(void) {")
    out.append("    " + spec.setup)
    out.append("    __cqd_globals();")
    out.append("    cqd_out_fd = open(getenv(\"CQD_OUT\"), O_WRONLY | O_CREAT | O_APPEND, 0644);")
    out.append("    char line[8192];")
    out.append("    while (fgets(line, sizeof line, stdin)) {")
    out.append("        char *tok[64]; int nt = 0; char *sv = 0;")
    out.append("        for (char *t = strtok_r(line, \" \\n\", &sv); t && nt < 64; t = strtok_r(0, \" \\n\", &sv)) tok[nt++] = t;")
    out.append("        if (nt < 2) continue;")
    out.append("        int idx = atoi(tok[0]), call = atoi(tok[1]); (void)call;")
    out.append("        fflush(stdout);")
    out.append("        pid_t pid = fork();")
    out.append("        if (pid == 0) {")
    out.append("            int dn = open(\"/dev/null\", O_WRONLY); dup2(dn, 1); dup2(dn, 2);")
    out.append("            cqd_child(idx);")
    out.append("            switch (call) {")
    for ci, call in enumerate(spec.calls):
        lines = [f"            case {ci}: {{"]
        actual = []
        for j, a in enumerate(call["args"]):
            ct = D.parse_ctype(a["ctype"])
            if ct.kind == "p":
                lines.append(f"                void *p{j} = 0; (void)p{j};")
                actual.append(None)
                continue
            n = 1 if ct.bits == 1 else (10 if ct.bits == 80 else ct.bits // 8)
            lines.append(f"                {ct.spelling} a{j}; memset(&a{j}, 0, sizeof a{j}); "
                         f"cqd_load(&a{j}, {n}, tok[{2 + j}]);")
            if ct.bits == 1:
                lines.append(f"                a{j} = (*(unsigned char *)&a{j}) & 1;")
            actual.append(f"a{j}")
        lines.append(f"                CQD_CALL_{ci};")
        lines.append("                break; }")
        out += lines
    out.append("            }")
    out.append("            cqd_end();")
    out.append("        }")
    out.append("        int st = 0; waitpid(pid, &st, 0);")
    out.append("    }")
    out.append("    return 0;\n}")
    return "\n".join(out) + "\n"


class ProbeBuild:
    def __init__(self, spec: DriverSpec, example_dir: Path, work: Path):
        self.spec = spec
        self.example_dir = Path(example_dir)
        self.work = work
        o1 = sorted(self.example_dir.glob("*.O1.ll"))
        if len(o1) != 1:
            D.unimplemented(f"{spec.example}: expected one .O1.ll")
        self.mod = D.read_module(o1[0])
        self.ins = Instrumenter(self.mod)
        self.exe = work / "probe"
        self.build()

    def build(self):
        w = self.work
        w.mkdir(parents=True, exist_ok=True)
        ll = self.ins.rewrite()
        stubs = []
        for name in ("@cq_phi", "@__cq_invert_begin", "@__cq_invert_end"):
            if name in self.mod.declares:
                stubs.append(_stub_for(self.mod.declares[name], identity=False))
        for name, line in self.mod.declares.items():
            if name.startswith("@cq_theta_") or name.startswith("@cq_measure_"):
                stubs.append(_stub_for(line, identity=True))
        (w / "probe.ll").write_text(ll)
        (w / "stubs.ll").write_text(_stub_module_header(self.mod) + "\n".join(stubs) + "\n")
        rt = RUNTIME_C.replace("PER_SAMPLE_MS", str(PER_SAMPLE_MS)).replace("static int cqd_out_fd", "int cqd_out_fd")
        rt = rt.replace("static void cqd_child", "void cqd_child").replace("static void cqd_load", "void cqd_load")
        (w / "rt.c").write_text(rt)
        (w / "driver.c").write_text(_driver_main(self.spec))
        self._splice_calls()
        self._link()

    def _splice_calls(self):
        """The call statements: the drivers.txt pointer expressions (the same in every sample of a
        call) and the scalar argument variables; each driver object is registered by its size."""
        w = self.work
        body = (w / "driver.c").read_text()
        parse_call = D.parse_call
        line = D.read_drivers_txt(self.example_dir.resolve().parent.parent / "_tools" / "drivers.txt")[self.spec.example]
        regs = []
        for ci, (ctext, call) in enumerate(zip(line.calls, self.spec.calls)):
            fn, args = parse_call(ctext)
            actual = []
            for j, (a, txt) in enumerate(zip(call["args"], args)):
                if D.parse_ctype(a["ctype"]).kind == "p":
                    actual.append(txt)
                    ident = D._ident_of(txt)
                    if ident:
                        regs.append(f"__cqd_reg((void *)&{ident}, sizeof({ident}));")
                else:
                    actual.append(f"a{j}")
            body = body.replace(f"CQD_CALL_{ci};", f"(void){fn}({', '.join(actual)});")
        body = body.replace("    __cqd_globals();", "    __cqd_globals();\n    " + " ".join(sorted(set(regs))))
        (w / "driver.c").write_text(body)

    def _link(self, extra: str = ""):
        w = self.work
        (w / "extra.ll").write_text(_stub_module_header(self.mod) + extra)
        cmd = [str(LLVM_BIN / "clang"), "-w", "-O0", "-target", "x86_64-apple-macosx", str(w / "probe.ll"),
               str(w / "stubs.ll"), str(w / "extra.ll"), str(w / "rt.c"), str(w / "driver.c"),
               "-include", "stdbool.h", "-lm", "-o", str(self.exe)]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            undef = re.findall(r'^\s+"_([^"]+)", referenced from', r.stderr, re.M)
            if undef and not extra:
                self._link(_undefined_stubs(self.mod, undef))
                return
            D.unimplemented(f"{self.spec.example}: probe build failed:\n{r.stderr[-3000:]}")

    def run(self, samples: Sequence[dict]) -> List["Obs"]:
        """One observation per sample (PROBE_PROCS probe processes in parallel)."""
        if not samples:
            return []
        lines = []
        for i, s in enumerate(samples):
            args = [("-" if D.parse_ctype(a["ctype"]).kind == "p" else v)
                    for a, v in zip(self.spec.calls[s["call"]]["args"], s["args"])]
            lines.append(" ".join([str(i), str(s["call"])] + args))
        nproc = max(1, min(PROBE_PROCS, len(lines) // 8 or 1))
        chunks = [lines[k::nproc] for k in range(nproc)]
        procs = []
        for k, ch in enumerate(chunks):
            outp = self.work / f"out.{os.getpid()}.{k}.txt"
            if outp.exists():
                outp.unlink()
            inp = self.work / f"in.{os.getpid()}.{k}.txt"
            env = dict(os.environ, CQD_OUT=str(outp))
            # stdin is a pipe: a child's exit() cannot rewind it under the parent
            pr = subprocess.Popen([str(self.exe)], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL, env=env)
            threading.Thread(target=_feed, args=(pr, "\n".join(ch) + "\n"), daemon=True).start()
            procs.append((pr, outp, inp, len(ch)))
        obs = [Obs() for _ in samples]
        for pr, outp, inp, n in procs:
            try:
                pr.wait(timeout=60 + n * (PER_SAMPLE_MS / 1000 + 0.2))
            except subprocess.TimeoutExpired:
                pr.kill()
                pr.wait()
            text = outp.read_text(errors="replace") if outp.exists() else ""
            for f in (outp, inp):
                if f.exists():
                    f.unlink()
            self._parse(text, obs)
        return obs

    @staticmethod
    def _parse(text: str, obs: List["Obs"]) -> None:
        cur = None
        for ln in text.splitlines():
            w = ln.split()
            if not w:
                continue
            if w[0] == "S":
                cur = obs[int(w[1])]
                cur.ran = True
            elif cur is None:
                continue
            elif w[0] == "p":
                v = [int(x, 16) for x in w[2:]]
                cur.p.setdefault(int(w[1]), []).append(
                    (v[0] | v[1] << 64, v[2] | v[3] << 64, v[4] | v[5] << 64, v[6] | v[7] << 64))
            elif w[0] == "m":
                if w[2] != "?":
                    cur.m.setdefault(int(w[1]), []).append((int(w[2]), int(w[3])))
            elif w[0] == "t":
                cur.t.setdefault(int(w[1]), []).append(int(w[2]))
            elif w[0] == "E":
                cur.end = w[1]
                cur.code = int(w[2])


def _feed(pr, text: str) -> None:
    try:
        pr.stdin.write(text.encode())
        pr.stdin.close()
    except (BrokenPipeError, OSError):
        pass


def _stub_module_header(mod: D.Module) -> str:
    out = []
    for ln in mod.lines:
        if ln.startswith("target ") or (ln.startswith("%") and "= type" in ln):
            out.append(ln)
    return "\n".join(out) + "\n"


def _zero_of(ty: str) -> str:
    if ty == "void":
        return ""
    if int_width(ty):
        return "0"
    if ty in ("half", "float", "double"):
        return "0.0"
    if ty == "x86_fp80":
        return "0xK00000000000000000000"
    if ty == "ptr":
        return "null"
    return "zeroinitializer"


def _stub_for(decl: str, identity: bool) -> str:
    m = re.match(r"declare\s+(.*?)\s*(@[-\w.$]+)\((.*)\)", D.strip_comment(decl))
    ret_words = [w for w in m.group(1).split() if w not in ("noundef", "zeroext", "signext", "dso_local", "nonnull")]
    ret = ret_words[-1] if ret_words else "void"
    params = [split_type(p)[0] for p in D.split_operands(m.group(3)) if p != "..."]
    ps = ", ".join(f"{t} %a{i}" for i, t in enumerate(params))
    if ret == "void":
        body = "ret void"
    elif identity:
        body = f"ret {ret} %a0"
    else:
        body = f"ret {ret} {_zero_of(ret)}"
    return f"define {ret} {m.group(2)}({ps}) {{\n  {body}\n}}"


def _undefined_stubs(mod: D.Module, names: List[str]) -> str:
    out = []
    for n in names:
        g = "@" + n
        if g in mod.declares:
            out.append(_stub_for(mod.declares[g], identity=False).replace("define ", "define weak ", 1))
        elif g in mod.globals:
            m = re.search(r"\bexternal\s+(?:local_unnamed_addr\s+|unnamed_addr\s+)*(?:global|constant)\s+(.*)$",
                          D.strip_comment(mod.globals[g]))
            if not m:
                D.unimplemented(f"undefined global {n}")
            ty, _ = split_type(m.group(1))
            out.append(f"{g} = weak global {ty} zeroinitializer")
        elif n.startswith("cqrt_"):
            out.append(f"define weak i32 {g}(i1 %a) {{\n  ret i32 0\n}}")
        else:
            D.unimplemented(f"undefined symbol {n} in the probe build")
    return "\n".join(out) + "\n"


@dataclass
class Obs:
    ran: bool = False
    end: str = "lost"
    code: int = 0
    p: Dict[int, List[Tuple[int, int, int, int]]] = field(default_factory=dict)
    m: Dict[int, List[Tuple[int, int]]] = field(default_factory=dict)
    t: Dict[int, List[int]] = field(default_factory=dict)

    @property
    def returned(self) -> bool:
        return self.end == "exit"


# ------------------------------------------------------------------------------------------------
# §2 rows
# ------------------------------------------------------------------------------------------------

@dataclass
class Row:
    site: Site
    row: str                      # CR §2 row name
    rel: List[int]                # operand slots the row depends on
    hit: Callable[[Tuple[int, int, int, int]], bool]
    dist: Callable[[Tuple[int, int, int, int]], float]
    traps: bool = False           # the native instruction faults on this input (probe build only)


def _signed(v: int, w: int) -> int:
    v &= (1 << w) - 1
    return v - (1 << w) if v >> (w - 1) else v


def _fpw(t: str) -> int:
    return _SCALAR_FP.get(t, 0)


def rows_for(site: Site) -> List[Row]:
    out: List[Row] = []
    W = site.width
    m = (1 << W) - 1 if W else 0
    k = site.kind
    if k == "div":
        out.append(Row(site, f"{site.op}(a, 0)", [1], lambda r: r[1] & m == 0,
                       lambda r: min(r[1] & m, (-r[1]) & m), traps=True))
        if site.op in ("sdiv", "srem"):
            mn = 1 << (W - 1)
            out.append(Row(site, f"{site.op}(INT_MIN, -1)", [0, 1],
                           lambda r: r[0] & m == mn and r[1] & m == m,
                           lambda r: (abs(_signed(r[0], W) + mn) > 0) + (abs(_signed(r[1], W) + 1) > 0) +
                           min(abs(_signed(r[0], W) + mn), 1 << 62) / float(1 << 63), traps=True))
    elif k in ("shift", "fsh"):
        s = 1 if k == "shift" else 2
        name = "shl/lshr/ashr" if k == "shift" else "fshl/fshr"
        out.append(Row(site, f"{name} amount = W", [s], lambda r: r[s] & m == W, lambda r: abs((r[s] & m) - W)))
        out.append(Row(site, f"{name} amount > W", [s], lambda r: r[s] & m > W,
                       lambda r: 0 if r[s] & m > W else W + 1 - (r[s] & m)))
    elif k == "fptoi":
        fw = _fpw(site.types[0])
        fam = "fptosi/fptoui from f80" if fw == 80 else "fptosi/fptoui from f16/f32/f64"
        lo = -(1 << (site.to_bits - 1)) if site.to_signed else 0
        hi = (1 << (site.to_bits - 1)) - 1 if site.to_signed else (1 << site.to_bits) - 1

        def rng(r):
            kd, val = fp_kind(r[0], fw)
            if kd in ("norm", "sub", "zero"):
                tv = math.trunc(val)
                return lo <= tv <= hi
            return None

        def rdist(r):
            kd, val = fp_kind(r[0], fw)
            if kd not in ("norm", "sub", "zero"):
                return 1e300
            tv = math.trunc(val)
            return 0 if (tv < lo or tv > hi) else float(min(tv - lo + 1, hi - tv + 1))
        out.append(Row(site, f"{fam}: NaN", [0], lambda r: fp_kind(r[0], fw)[0] == "nan",
                       lambda r: 0 if fp_kind(r[0], fw)[0] == "nan" else 1))
        out.append(Row(site, f"{fam}: +-Inf", [0], lambda r: fp_kind(r[0], fw)[0] == "inf",
                       lambda r: 0 if fp_kind(r[0], fw)[0] == "inf" else 1))
        out.append(Row(site, f"{fam}: out of range", [0], lambda r: rng(r) is False, rdist))
        if fw == 80:
            out.append(Row(site, "f80 non-canonical operand", [0], lambda r: fp_kind(r[0], 80)[0] == "noncanon",
                           lambda r: 0 if fp_kind(r[0], 80)[0] == "noncanon" else 1))
    elif k in ("fpres", "frem", "minmax"):
        n = len(site.types)
        fws = [_fpw(t) for t in site.types]
        if not all(fws):
            return out

        def kinds(r):
            return [fp_kind(r[i], fws[i])[0] for i in range(n)]
        if k == "fpres":
            rw = fws[0]
            out.append(Row(site, f"{site.op} NaN operand", list(range(n)), lambda r: "nan" in kinds(r),
                           lambda r: 0 if "nan" in kinds(r) else 1))
            def inv_dist(r):
                ks = kinds(r)
                if "nan" not in ks and fp_kind(r[3], rw)[0] == "nan":
                    return 0
                # graded: an invalid operation needs infinities or zeros among its operands
                return 1 - 0.25 * sum(1 for x in ks if x in ("inf", "zero"))
            out.append(Row(site, f"{site.op} invalid (default NaN)", list(range(n)),
                           lambda r: "nan" not in kinds(r) and fp_kind(r[3], rw)[0] == "nan", inv_dist))
        elif k == "frem":
            out.append(Row(site, "frem(x, 0)", [1], lambda r: kinds(r)[1] == "zero", lambda r: 0 if kinds(r)[1] == "zero" else 1))
            out.append(Row(site, "frem(+-Inf, y)", [0], lambda r: kinds(r)[0] == "inf", lambda r: 0 if kinds(r)[0] == "inf" else 1))
            out.append(Row(site, "frem(x, +-Inf)", [1], lambda r: kinds(r)[1] == "inf", lambda r: 0 if kinds(r)[1] == "inf" else 1))
            out.append(Row(site, "frem NaN operand", [0, 1], lambda r: "nan" in kinds(r), lambda r: 0 if "nan" in kinds(r) else 1))
        else:
            out.append(Row(site, f"{site.op} NaN operand", [0, 1], lambda r: "nan" in kinds(r),
                           lambda r: 0 if "nan" in kinds(r) else 1))
            sb = [_fp_storage(w) - 1 for w in fws]
            out.append(Row(site, f"{site.op} +0 vs -0", [0, 1],
                           lambda r: kinds(r) == ["zero", "zero"] and (r[0] >> sb[0]) & 1 != (r[1] >> sb[1]) & 1,
                           lambda r: 0 if (kinds(r) == ["zero", "zero"] and (r[0] >> sb[0]) & 1 != (r[1] >> sb[1]) & 1) else 1))
        if 80 in fws:
            out.append(Row(site, "f80 non-canonical operand", list(range(n)),
                           lambda r: any(fws[i] == 80 and fp_kind(r[i], 80)[0] == "noncanon" for i in range(n)),
                           lambda r: 0 if any(fws[i] == 80 and fp_kind(r[i], 80)[0] == "noncanon" for i in range(n)) else 1))
    elif k == "ctz":
        out.append(Row(site, f"{site.op.split('.')[1]}(0)", [0], lambda r: r[0] & m == 0, lambda r: min(r[0] & m, 1 << 60)))
    elif k == "abs":
        mn = 1 << (W - 1)
        out.append(Row(site, "abs(INT_MIN)", [0], lambda r: r[0] & m == mn, lambda r: abs(_signed(r[0], W) + mn)))
    elif k == "angle":
        out.append(Row(site, "rotation angle NaN", [0], lambda r: fp_kind(r[0], 64)[0] == "nan",
                       lambda r: 0 if fp_kind(r[0], 64)[0] == "nan" else 1))
        out.append(Row(site, "rotation angle +-Inf", [0], lambda r: fp_kind(r[0], 64)[0] == "inf",
                       lambda r: 0 if fp_kind(r[0], 64)[0] == "inf" else 1))
    elif k == "mem":
        # r = (offset, size, 0, 0) for memory sites
        out.append(Row(site, f"{site.op} index = n", [], lambda r: r[0] == r[1],
                       lambda r: abs(r[0] - r[1])))
        out.append(Row(site, f"{site.op} index > n", [], lambda r: r[0] > r[1] or r[0] < 0,
                       lambda r: 0 if (r[0] > r[1] or r[0] < 0) else r[1] - r[0] + 1))
    return out


def _records(o: Obs, site: Site) -> List[Tuple[int, int, int, int]]:
    if site.kind == "mem":
        return [(off, size, 0, 0) for off, size in o.m.get(site.id, [])]
    return o.p.get(site.id, [])


def static_reason(row: Row) -> Optional[str]:
    """The reason a row can never be hit when every operand it reads is a constant."""
    if not row.rel:
        return None
    c = row.site.consts
    if any(c.get(i) is None for i in row.rel):
        return None
    probe = [0, 0, 0, 0]
    for i in row.rel:
        probe[i] = c[i]
    try:
        if row.hit(tuple(probe)):
            return None
    except Exception:  # noqa: BLE001 - a row that cannot evaluate on constants is searched
        return None
    vals = ", ".join(f"operand {i} is the constant {hex(c[i])}" for i in row.rel)
    return vals


# ------------------------------------------------------------------------------------------------
# Sample generation
# ------------------------------------------------------------------------------------------------

def _example_seed(example: str) -> int:
    return SEED ^ int(hashlib.sha256(example.encode()).hexdigest()[:8], 16)


class Gen:
    def __init__(self, spec: DriverSpec, baselines: List[List[str]]):
        self.spec = spec
        self.base = baselines
        self.cts = [[D.parse_ctype(a["ctype"]) for a in c["args"]] for c in spec.calls]
        self.samples: List[dict] = []
        self.index: Dict[Tuple[int, Tuple[str, ...]], int] = {}

    def add(self, call: int, args: Sequence[str]) -> int:
        key = (call, tuple(args))
        if key not in self.index:
            self.index[key] = len(self.samples)
            self.samples.append({"call": call, "args": list(args)})
        return self.index[key]

    def quantum_slots(self, call: int) -> List[int]:
        return [j for j, a in enumerate(self.spec.calls[call]["args"])
                if a["quantum"] and self.cts[call][j].kind != "p"]

    def classical_slots(self, call: int) -> List[int]:
        return [j for j, a in enumerate(self.spec.calls[call]["args"])
                if not a["quantum"] and self.cts[call][j].kind != "p"]

    def has_driver_object(self, call: int) -> bool:
        return any(ct.kind == "p" for ct in self.cts[call])

    def with_values(self, call: int, vals: Dict[int, int]) -> List[str]:
        a = list(self.base[call])
        for j, v in vals.items():
            a[j] = hexw(self.cts[call][j], v)
        return a

    def classical_domain(self, call: int, j: int) -> Tuple[int, int]:
        """Integer classical arguments: around the drivers.txt value. In a call that passes a driver
        object the value bounds what the call reads of it, so the domain is [0, value]."""
        ct = self.cts[call][j]
        b = int(self.base[call][j], 16)
        if ct.signed:
            b = _signed(b, ct.bits)
        tmin = -(1 << (ct.bits - 1)) if ct.signed else 0
        tmax = (1 << (ct.bits - 1)) - 1 if ct.signed else (1 << ct.bits) - 1
        if ct.bits == 1:
            return 0, 1
        if self.has_driver_object(call) and b > 0:
            return 0, b
        lo = b if b < 0 else 0
        hi = max(2 * abs(b), 8)
        return max(lo, tmin), min(hi, tmax)

    def random_quantum(self, rng: random.Random, ct: D.CType) -> int:
        w = ct.storage_bits
        if ct.kind == "i":
            if ct.bits == 1:
                return rng.randrange(2)
            if rng.random() < 0.5:
                return rng.getrandbits(ct.bits)
            return rng.randrange(-16, 17) & ((1 << ct.bits) - 1)
        if rng.random() < 0.5:
            b = rng.getrandbits(w)
            if ct.bits == 80:
                b |= 1 << 63 if (b >> 64) & 0x7fff else 0     # canonical explicit integer bit
            return b
        x = rng.uniform(-16, 16)
        return {32: f32_bits, 64: f64_bits, 80: f80_from_float}[ct.bits](x)

    def random_classical(self, rng: random.Random, call: int, j: int) -> int:
        ct = self.cts[call][j]
        if ct.kind == "i":
            lo, hi = self.classical_domain(call, j)
            return rng.randint(lo, hi) & ((1 << ct.bits) - 1)
        x = rng.uniform(-2 * math.pi, 2 * math.pi)
        return {32: f32_bits, 64: f64_bits, 80: f80_from_float}[ct.bits](x)


def _cross(sets: List[List[int]], limit: int) -> List[List[int]]:
    total = 1
    for s in sets:
        total *= len(s)
    if total <= limit:
        out = [[]]
        for s in sets:
            out = [o + [v] for o in out for v in s]
        return out
    return []


def per_call_classes(g: Gen, rng: random.Random) -> Dict[str, dict]:
    spec = g.spec
    edge, specials, exhaustive, rq = {}, {}, {}, {}
    for ci, call in enumerate(spec.calls):
        key = str(ci)
        qs = g.quantum_slots(ci)
        cts = g.cts[ci]
        pointee = [j for j, a in enumerate(call["args"]) if a["quantum"] and cts[j].kind == "p"]
        why_none = ("no scalar argument of this call flows into a cq_theta_* register"
                    + (f"; the quantum input is the memory behind argument {pointee[0]} "
                       f"(drivers.txt: {g.base[ci][pointee[0]]}), whose values the drivers.txt setup fixes"
                       if pointee else "; every cq_theta_* register is computed inside the program"))
        if not qs:
            edge[key] = {"empty": why_none}
            specials[key] = {"empty": why_none}
            exhaustive[key] = {"samples": [g.add(ci, g.base[ci])], "bits": 0,
                               "note": "no quantum scalar input: the one input is the drivers.txt call"}
            rq[key] = {"empty": why_none}
        else:
            # edge
            sets = [int_edges(cts[j]) if cts[j].kind == "i" else fp_edges(cts[j]) for j in qs]
            combos = _cross(sets, CROSS_LIMIT)
            idx = []
            if combos:
                for c in combos:
                    idx.append(g.add(ci, g.with_values(ci, dict(zip(qs, c)))))
            else:
                for j, s in zip(qs, sets):
                    for v in s:
                        idx.append(g.add(ci, g.with_values(ci, {j: v})))
                for t in range(max(len(s) for s in sets)):
                    idx.append(g.add(ci, g.with_values(ci, {j: s[t % len(s)] for j, s in zip(qs, sets)})))
            edge[key] = {"samples": sorted(set(idx))}
            # specials
            fq = [j for j in qs if cts[j].kind == "f"]
            if not fq:
                specials[key] = {"empty": "no floating-point quantum input in this call"}
            else:
                ssets = [fp_specials(cts[j]) for j in fq]
                combos = _cross(ssets, CROSS_LIMIT)
                idx = []
                if combos:
                    for c in combos:
                        idx.append(g.add(ci, g.with_values(ci, dict(zip(fq, c)))))
                else:
                    for j, s in zip(fq, ssets):
                        for v in s:
                            idx.append(g.add(ci, g.with_values(ci, {j: v})))
                specials[key] = {"samples": sorted(set(idx))}
            # exhaustive
            bits = sum(cts[j].bits for j in qs)
            if bits <= EXHAUSTIVE_BITS:
                idx = []
                for n in range(1 << bits):
                    vals, sh = {}, 0
                    for j in qs:
                        vals[j] = (n >> sh) & ((1 << cts[j].bits) - 1)
                        sh += cts[j].bits
                    idx.append(g.add(ci, g.with_values(ci, vals)))
                exhaustive[key] = {"samples": idx, "bits": bits}
            else:
                exhaustive[key] = {"empty": f"the quantum inputs of this call total {bits} bits > {EXHAUSTIVE_BITS}"}
            # random over the quantum inputs
            idx = []
            for _ in range(N_RANDOM_QUANTUM):
                idx.append(g.add(ci, g.with_values(ci, {j: g.random_quantum(rng, cts[j]) for j in qs})))
            rq[key] = {"samples": sorted(set(idx))}
    return {"edge": edge, "specials": specials, "exhaustive": exhaustive, "rq": rq}


def classical_candidates(g: Gen, rng: random.Random) -> Dict[int, List[List[str]]]:
    out = {}
    for ci in range(len(g.spec.calls)):
        cs = g.classical_slots(ci)
        qs = g.quantum_slots(ci)
        cands = []
        if cs:
            for t in range(N_RANDOM_CLASSICAL * 2):
                vals = {j: g.random_classical(rng, ci, j) for j in cs}
                if t % 2 and qs:
                    vals.update({j: g.random_quantum(rng, g.cts[ci][j]) for j in qs})
                cands.append(g.with_values(ci, vals))
        out[ci] = cands
    return out


def _valid(o: Obs, rows_by_site: Dict[int, List[Row]]) -> bool:
    if o.returned:
        return True
    if o.end == "signal" and o.code in (8,):          # SIGFPE: a trapping §2 row in the native build
        for sid, recs in o.p.items():
            for row in rows_by_site.get(sid, []):
                if row.traps and any(row.hit(r) for r in recs):
                    return True
    return False


class Searcher:
    """Mutation search over the scalar arguments of one call, guided by a distance to the target."""

    def __init__(self, g: Gen, pb: ProbeBuild, rows_by_site, rng: random.Random):
        self.g, self.pb, self.rows_by_site, self.rng = g, pb, rows_by_site, rng
        self.cache: Dict[Tuple[int, Tuple[str, ...]], Obs] = {}
        self.runs = 0

    def observe(self, cands: List[Tuple[int, List[str]]]) -> List[Obs]:
        todo = [(c, a) for c, a in cands if (c, tuple(a)) not in self.cache]
        uniq = list(dict.fromkeys((c, tuple(a)) for c, a in todo))
        if uniq:
            obs = self.pb.run([{"call": c, "args": list(a)} for c, a in uniq])
            self.runs += len(uniq)
            for k, o in zip(uniq, obs):
                self.cache[k] = o
        return [self.cache[(c, tuple(a))] for c, a in cands]

    def interesting(self, call: int, j: int) -> List[int]:
        ct = self.g.cts[call][j]
        w = ct.bits
        m = (1 << ct.storage_bits) - 1
        if ct.kind == "i":
            vals = set(int_edges(ct)) | {k & m for k in range(-2, 2 * 64 + 3)}
            vals |= {(1 << e) & m for e in range(w)} | {((1 << e) + 1) & m for e in range(w)}
            if not self.g.spec.calls[call]["args"][j]["quantum"]:
                lo, hi = self.search_domain(call, j)
                vals = {v for v in vals if lo <= (_signed(v, w) if ct.signed and w > 1 else v) <= hi}
            return sorted(vals)
        vals = fp_edges(ct) + fp_specials(ct)
        for x in (0.5, 2.0, 3.0, 1e10, -1e10, 2.0 ** 31, 2.0 ** 32, 2.0 ** 63, 2.0 ** 64, -2.0 ** 31 - 1, 300.0):
            vals.append({32: f32_bits, 64: f64_bits, 80: f80_from_float}[w](x))
        if w == 80:
            vals += f80_noncanonical()
        return vals

    def search_domain(self, call: int, j: int) -> Tuple[int, int]:
        """A search may give a classical integer any value of its type (the validity check drops a
        candidate the C program cannot run), except in a call that passes a driver object, where
        the classical domain keeps the call inside the object."""
        g = self.g
        ct = g.cts[call][j]
        if g.has_driver_object(call) or ct.bits == 1:
            return g.classical_domain(call, j)
        if ct.signed:
            return -(1 << (ct.bits - 1)), (1 << (ct.bits - 1)) - 1
        return 0, (1 << ct.bits) - 1

    def mutate(self, call: int, args: List[str]) -> List[str]:
        g = self.g
        slots = g.quantum_slots(call) + g.classical_slots(call)
        a = list(args)
        for _ in range(self.rng.choice((1, 1, 2))):
            j = self.rng.choice(slots)
            ct = g.cts[call][j]
            cur = int(a[j], 16)
            r = self.rng.random()
            if r < 0.2:
                v = self.rng.choice(self.interesting(call, j))
            elif r < 0.4:
                core = int_edges(ct) if ct.kind == "i" else fp_edges(ct) + fp_specials(ct)
                if ct.kind == "i" and not g.spec.calls[call]["args"][j]["quantum"]:
                    lo, hi = self.search_domain(call, j)
                    core = [x for x in core if lo <= (_signed(x, ct.bits) if ct.signed and ct.bits > 1 else x) <= hi] or [cur]
                v = self.rng.choice(core)
            elif ct.kind == "i" and r < 0.8:
                d = self.rng.choice((1, -1)) * self.rng.choice((1, 1, 2, 3, 5, 8, 16, 100, 1 << 10, 1 << 20))
                v = cur + d
                if not g.spec.calls[call]["args"][j]["quantum"]:
                    lo, hi = self.search_domain(call, j)
                    sv = _signed(v, ct.bits) if ct.signed and ct.bits > 1 else v & ((1 << ct.bits) - 1)
                    v = min(max(sv, lo), hi)
            elif g.spec.calls[call]["args"][j]["quantum"]:
                v = g.random_quantum(self.rng, ct)
            elif ct.kind == "i":
                lo, hi = self.search_domain(call, j)
                v = self.rng.randint(lo, hi) if self.rng.random() < 0.3 else g.random_classical(self.rng, call, j)
            else:
                v = g.random_classical(self.rng, call, j)
            a[j] = hexw(ct, v)
        return a

    def search(self, pool: List[Tuple[int, List[str]]], dist: Callable[[Obs], float],
               budget: int = SEARCH_BUDGET) -> Optional[Tuple[int, List[str]]]:
        """The first candidate with distance 0, or None after the budget."""
        self.observe(pool)
        scored = []
        # every candidate observed so far (the pool and earlier searches) is a starting point
        for (c, a), o in self.cache.items():
            if not _valid(o, self.rows_by_site):
                continue
            d = dist(o)
            if d == 0:
                return c, list(a)
            scored.append((d, c, list(a)))
        if not scored:
            return None
        spent = 0
        while spent < budget:
            self.rng.shuffle(scored)
            scored.sort(key=lambda t: t[0])
            elite = scored[:8]
            batch = []
            for _ in range(SEARCH_BATCH):
                d, c, a = self.rng.choice(elite)
                if not (self.g.quantum_slots(c) or self.g.classical_slots(c)):
                    continue
                batch.append((c, self.mutate(c, a)))
            if not batch:
                return None
            spent += len(batch)
            for (c, a), o in zip(batch, self.observe(batch)):
                if not _valid(o, self.rows_by_site):
                    continue
                d = dist(o)
                if d == 0:
                    return c, a
                scored.append((d, c, a))
        return None


# ------------------------------------------------------------------------------------------------
# The SampleSet
# ------------------------------------------------------------------------------------------------

def _cache_dir() -> Path:
    return Path(os.environ.get("CQ_SAMPLES_CACHE", D.REPO / "build" / "chk-drivers"))


def _cache_key(spec: DriverSpec, example_dir: Path) -> str:
    h = hashlib.sha256()
    h.update(json.dumps([spec.example, spec.protos, spec.setup, spec.calls], sort_keys=True).encode())
    for p in sorted(Path(example_dir).glob("*.O1.ll")):
        h.update(p.read_bytes())
    h.update(Path(__file__).read_bytes())
    h.update(Path(D.__file__).read_bytes())
    return h.hexdigest()[:20]


def sample_set(spec: DriverSpec, example_dir: Path) -> SampleSet:
    """The SampleSet of one example (cq-zew). Deterministic; cached under build/chk-drivers/."""
    example_dir = Path(example_dir)
    key = _cache_key(spec, example_dir)
    cache = _cache_dir() / f"{spec.example}.{key}.json"
    if cache.exists():
        d = json.loads(cache.read_text())
        return SampleSet(**d)
    ss = build_sample_set(spec, example_dir)
    cache.parent.mkdir(parents=True, exist_ok=True)
    tmp = cache.with_suffix(f".tmp{os.getpid()}")
    tmp.write_text(json.dumps({"example": ss.example, "samples": ss.samples, "classes": ss.classes},
                              sort_keys=True))
    tmp.replace(cache)
    return ss


def build_sample_set(spec: DriverSpec, example_dir: Path) -> SampleSet:
    example_dir = Path(example_dir)
    line = D.read_drivers_txt(example_dir.resolve().parent.parent / "_tools" / "drivers.txt")[spec.example]
    baselines = D.baseline_values(line, spec)
    g = Gen(spec, baselines)
    for ci in range(len(spec.calls)):
        g.add(ci, baselines[ci])          # samples 0 .. ncalls-1 are the drivers.txt calls
    seed = _example_seed(spec.example)
    rng = random.Random(seed)
    pc = per_call_classes(g, rng)

    with tempfile.TemporaryDirectory(prefix=f"cqd-{spec.example}-") as tmp:
        pb = ProbeBuild(spec, example_dir, Path(tmp))
        sites = pb.ins.sites
        rows_by_site: Dict[int, List[Row]] = {s.id: rows_for(s) for s in sites}
        searcher = Searcher(g, pb, rows_by_site, random.Random(seed + 1))

        # the classical seeded set: kept when the C program runs to completion on it
        cc = classical_candidates(g, rng)
        rc = {}
        for ci in range(len(spec.calls)):
            cs = g.classical_slots(ci)
            if not cs:
                rc[str(ci)] = {"empty": "no classical scalar argument in this call"}
                continue
            cands = [(ci, a) for a in cc[ci]]
            obs = searcher.observe(cands)
            kept = [g.add(c, a) for (c, a), o in zip(cands, obs) if _valid(o, rows_by_site)][:N_RANDOM_CLASSICAL]
            if kept:
                rc[str(ci)] = {"samples": kept}
            else:
                rc[str(ci)] = {"empty": f"none of {len(cands)} seeded classical candidates ran to completion "
                                        f"in the C program (outcomes: "
                                        f"{sorted(set(o.end for o in obs))})"}

        # the pool every search starts from: all samples so far (capped, deterministic)
        pool_idx = list(range(len(g.samples)))
        if len(pool_idx) > 2000:
            pool_idx = pool_idx[:len(spec.calls)] + random.Random(seed + 2).sample(pool_idx[len(spec.calls):], 2000)
        pool = [(g.samples[i]["call"], g.samples[i]["args"]) for i in pool_idx]
        pool_obs = searcher.observe(pool)
        reached_sites: Set[int] = set()
        for o in pool_obs:
            reached_sites |= set(o.p) | set(o.m)

        # totalization rows
        tot_rows = []
        for s in sites:
            for row in rows_by_site[s.id]:
                entry = {"site": s.key(), "row": row.row}
                sr = static_reason(row)
                if sr:
                    entry["empty"] = f"cannot be hit: {sr}"
                    tot_rows.append(entry)
                    continue
                hits = [g.index[(c, tuple(a))] for (c, a), o in zip(pool, pool_obs)
                        if any(row.hit(r) for r in _records(o, s)) and (c, tuple(a)) in g.index]
                if not hits:
                    def dist(o, s=s, row=row):
                        recs = _records(o, s)
                        return min((row.dist(r) for r in recs), default=1e308)
                    found = searcher.search(pool, dist)
                    if found:
                        hits = [g.add(*found)]
                if hits:
                    entry["samples"] = sorted(set(hits))[:16]
                else:
                    seen_vals = sorted({row.dist(r) for o in pool_obs for r in _records(o, s)})[:3]
                    entry["empty"] = (f"unreachable by search: the site ran in "
                                      f"{sum(1 for o in pool_obs if _records(o, s))} of {len(pool)} pool samples"
                                      + (f", closest distances {seen_vals}" if seen_vals else
                                         " (the drivers never reach it)")
                                      + f"; {searcher.runs} probe runs in total")
                tot_rows.append(entry)
        totalization = {"rows": tot_rows} if tot_rows else {
            "rows": [], "empty": "no instruction of the example is named by a CR §2 row"}

        # trips
        bounded = [str(ci) for ci in range(len(spec.calls)) if g.has_driver_object(ci) and g.classical_slots(ci)]
        bound_note = (f"; in calls {', '.join(bounded)} (which pass a driver object) an integer classical "
                      f"argument ranges over [0, its drivers.txt value]") if bounded else ""
        loops_out = trip_classes(spec, example_dir, g, pb, searcher, pool, pool_obs, rows_by_site, bound_note)
        trips_cls = {"K": K, "loops": loops_out}
        if not loops_out:
            trips_cls["empty"] = "the example has no loop"

    classes = {
        "edge": pc["edge"],
        "specials": pc["specials"],
        "exhaustive": pc["exhaustive"],
        "random_seed": {"seed": seed, "quantum": pc["rq"], "classical": rc},
        "totalization": totalization,
        "trips": trips_cls,
    }
    return SampleSet(example=spec.example, samples=g.samples, classes=classes)


def legacy_oracle_loop_ids(loops: List[Loop], fn_order: Sequence[str]) -> Dict[int, str]:
    """TEMPORARY: the spelling the C oracle on main still emits, `<fn>/<k>` with k the loop's index in
    LLVM's LoopInfo::getLoopsInPreorder, until it conforms to T1 (`<fn>:<header>`, cq-mia). Siblings
    are taken in the reverse postorder of their headers over the CFG in successor order (the order
    find_loops numbers them in); the preorder is a depth-first walk of the loop tree in that order.
    Used only to read oracle events; the SampleSet spells loops per T1."""
    out: Dict[int, str] = {}
    for fn in fn_order:
        mine = [lp for lp in loops if lp.fn == fn]          # in find_loops order (header RPO)
        k = 0

        def walk(parent):
            nonlocal k
            for lp in mine:
                if lp.parent == parent:
                    out[lp.id] = f"{fn[1:]}/{k}"
                    k += 1
                    walk(lp.id)
        walk(None)
    return out


def trip_classes(spec, example_dir, g, pb, searcher, pool, pool_obs, rows_by_site, bound_note) -> List[dict]:
    """Per loop and per target trip count, a sample on which the C oracle's trip counter reports that
    count. The probe build's header counters drive the search; candidates within one trip of a target
    (the probe counts header executions, the oracle trips begun, and a skipped guard as 0) go to the
    C oracle, which decides."""
    from cqcheck import oracle
    loops = pb.ins.loops
    if not loops:
        return []
    legacy = legacy_oracle_loop_ids(loops, list(pb.mod.functions))
    to_t1 = {v: loops[k].key() for k, v in legacy.items()}
    oid = {lp.id: lp.key() for lp in loops}
    targets = (0, K - 1, K, K + 1)
    cands: List[Tuple[int, Tuple[str, ...]]] = []

    def near(o: Obs, lp: Loop, t: int) -> bool:
        ns = o.t.get(lp.id, [])
        return any(abs(n - t) <= 1 for n in ns) or (t == 0 and not ns)

    for lp in loops:
        for t in targets:
            found = None
            if not any(near(o, lp, t) for o in pool_obs):
                def dist(o, lp=lp, t=t):
                    return min((abs(n - t) for n in o.t.get(lp.id, [])), default=1e308)
                found = searcher.search(pool, dist)
                if found:
                    cands.append((found[0], tuple(found[1])))
            picked = [k for k, o in searcher.cache.items() if _valid(o, rows_by_site) and near(o, lp, t)]
            picked.sort(key=lambda k: (k not in g.index, g.index.get(k, 0)))
            cands += picked[:24]
    cands = list(dict.fromkeys([(c, tuple(a)) for c, a in
                                [(g.samples[i]["call"], g.samples[i]["args"]) for i in range(len(spec.calls))]] + cands))
    o1 = sorted(Path(example_dir).glob("*.O1.ll"))[0]
    runs = oracle.run_samples(o1, spec, [{"call": c, "args": list(a)} for c, a in cands])
    seen: Dict[str, Set[int]] = {}
    for (c, a), r in zip(cands, runs):
        if r.failed:
            continue
        for e in r.events:
            if e.get("ev") == "trip":
                e["loop"] = to_t1.get(e["loop"], e["loop"])
                seen.setdefault(e["loop"], set()).add(int(e["n"]))
    known = set(oid.values())
    stray = sorted(set(seen) - known)
    if stray:
        D.unimplemented(f"{spec.example}: the C oracle reports loops {stray} the probe build does not know "
                        f"(probe loops {sorted(known)})")
    out = []
    for lp in loops:
        trips = {}
        for t in targets:
            hit = None
            for (c, a), r in zip(cands, runs):
                if not r.failed and any(e.get("ev") == "trip" and e["loop"] == oid[lp.id] and int(e["n"]) == t
                                        for e in r.events):
                    hit = g.add(c, list(a))
                    break
            if hit is not None:
                trips[str(t)] = {"sample": hit}
                continue
            obs_c = sorted(seen.get(oid[lp.id], set()))
            if not obs_c and not any(lp.id in o.t for o in searcher.cache.values()):
                why = "the loop is never reached from the drivers.txt calls"
            else:
                why = (f"no input found: the C oracle's trip counts on {len(cands)} candidates are "
                       f"{obs_c[:12]}{' ...' if len(obs_c) > 12 else ''}"
                       + (" (it reports 0 only when a guard branch skips the loop)" if t == 0 else "")
                       + f"; {searcher.runs} probe runs searched")
            trips[str(t)] = {"empty": why + bound_note}
        out.append({"loop": lp.key(),
                    "parent": (loops[lp.parent].key() if lp.parent is not None else None), "trips": trips})
    return out


def confirm_trips(ss: SampleSet, trip_events: Callable[[dict], List[dict]],
                  to_t1: Optional[Dict[str, str]] = None) -> List[str]:
    """Check the trip samples against the C oracle's trip counters. `trip_events(sample)` returns the
    oracle's events for one sample (oracle.trace_sample); `to_t1` maps a legacy oracle loop id to the
    T1 spelling (empty once the oracle conforms). Returns the disagreements."""
    to_t1 = to_t1 or {}
    bad = []
    for lp in ss.classes["trips"]["loops"]:
        for target, e in lp["trips"].items():
            if "sample" not in e:
                continue
            try:
                evs = trip_events(ss.samples[e["sample"]])
            except Exception as x:  # noqa: BLE001 - a sample the oracle cannot run is a disagreement
                bad.append(f"{ss.example}: loop {lp['loop']}: sample {e['sample']}: {x}")
                continue
            ns = [int(x["n"]) for x in evs if x.get("ev") == "trip" and to_t1.get(x.get("loop"), x.get("loop")) == lp["loop"]]
            if int(target) not in ns:
                bad.append(f"{ss.example}: loop {lp['loop']}: sample {e['sample']} "
                           f"gives trips {ns} in the C oracle, the class says {target}")
    return bad


REQUIRED_CLASSES = ("edge", "specials", "totalization", "trips", "random_seed", "exhaustive")


def check_sample_set(spec: DriverSpec, ss: SampleSet) -> List[str]:
    """The acceptance of cq-w0-chk-drivers for one example: every class present, or empty with a
    reason. Returns the problems."""
    bad = []
    n = len(ss.samples)
    if set(ss.classes) != set(REQUIRED_CLASSES):
        bad.append(f"classes {sorted(ss.classes)}")

    def per_call(name, d):
        for ci in range(len(spec.calls)):
            e = d.get(str(ci))
            if e is None:
                bad.append(f"{name}: call {ci} missing")
            elif "samples" in e:
                if not e["samples"] or any(not (0 <= i < n) for i in e["samples"]):
                    bad.append(f"{name}: call {ci}: bad samples")
            elif not e.get("empty"):
                bad.append(f"{name}: call {ci}: neither samples nor a reason")
    c = ss.classes
    per_call("edge", c.get("edge", {}))
    per_call("specials", c.get("specials", {}))
    per_call("exhaustive", c.get("exhaustive", {}))
    per_call("random_seed.quantum", c.get("random_seed", {}).get("quantum", {}))
    per_call("random_seed.classical", c.get("random_seed", {}).get("classical", {}))
    t = c.get("totalization", {})
    if not t.get("rows") and not t.get("empty"):
        bad.append("totalization: no rows and no reason")
    for r in t.get("rows", []):
        if not r.get("samples") and not r.get("empty"):
            bad.append(f"totalization: {r.get('site')} {r.get('row')}: neither samples nor a reason")
    tr = c.get("trips", {})
    if not tr.get("loops") and not tr.get("empty"):
        bad.append("trips: no loops and no reason")
    for lp in tr.get("loops", []):
        for target in (0, K - 1, K, K + 1):
            e = lp["trips"].get(str(target))
            if not e or ("sample" not in e and not e.get("empty")):
                bad.append(f"trips: {lp['loop']} trip {target}: neither a sample nor a reason")
    for i, s in enumerate(ss.samples[:len(spec.calls)]):
        if s["call"] != i:
            bad.append(f"sample {i} is not the drivers.txt call {i}")
    return bad


def _summary(ss: SampleSet) -> str:
    c = ss.classes
    rows = c["totalization"]["rows"]
    hit = sum(1 for r in rows if r.get("samples"))
    lps = c["trips"]["loops"]
    tr_hit = sum(1 for lp in lps for e in lp["trips"].values() if "sample" in e)
    return (f"{ss.example}: {len(ss.samples)} samples; rows {hit}/{len(rows)} hit; "
            f"trip targets {tr_hit}/{4 * len(lps)} found")


def _one(n: str, confirm: bool = False):
    d = D.example_dir(n)
    spec = D.driver_spec(n, d)
    ss = sample_set(spec, d)
    bad: List[str] = []
    if confirm:
        from cqcheck import oracle
        o1 = sorted(d.glob("*.O1.ll"))[0]
        ins = Instrumenter(D.read_module(o1))
        # renumber as rewrite_function does: ids are positions, parents offset per function
        loops, base = [], 0
        for f in ins.mod.functions.values():
            fl = ins.find_loops(f)
            for k, lp in enumerate(fl):
                lp.id = base + k
                lp.parent = None if lp.parent is None else lp.parent + base
            loops += fl
            base += len(fl)
        legacy = legacy_oracle_loop_ids(loops, list(ins.mod.functions))
        to_t1 = {v: loops[k].key() for k, v in legacy.items()}
        bad = confirm_trips(ss, lambda smp: oracle.trace_sample(o1, spec, smp), to_t1)
    return n, spec, ss, bad


def main(argv=None) -> int:
    import argparse
    import concurrent.futures as cf
    ap = argparse.ArgumentParser(prog="cqcheck.sampling")
    ap.add_argument("examples", nargs="*")
    ap.add_argument("-j", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--confirm", action="store_true",
                    help="check every trip sample against the C oracle (oracle.trace_sample)")
    a = ap.parse_args(argv)
    names = a.examples or D.all_examples()
    names = [n for n in names]
    status = 0

    with cf.ProcessPoolExecutor(max_workers=a.j) as ex:
        futs = {ex.submit(_one, n, a.confirm): n for n in names}
        for fu in cf.as_completed(futs):
            n = futs[fu]
            try:
                n, spec, ss, unconfirmed = fu.result()
            except Exception as e:  # noqa: BLE001
                print(f"{n}: ERROR {e}")
                status = 1
                continue
            bad = check_sample_set(spec, ss) + unconfirmed
            print(_summary(ss) + ("" if not bad else f"  PROBLEMS: {bad}"))
            if bad:
                status = 1
            if a.verbose:
                print(json.dumps(ss.classes["totalization"], indent=1))
                print(json.dumps(ss.classes["trips"], indent=1))
    return status


if __name__ == "__main__":
    raise SystemExit(main())
