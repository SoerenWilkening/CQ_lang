#!/usr/bin/env python3
"""Unit tests of the C oracle (cq-w0-chk-oracle): small C programs, each exercising one CR §2/§6 row or
one event, compiled with clang -O1 like the corpus and run through oracle.run_samples / run_sample /
trace_sample. Needs chk-drivers' drivers.driver_source (see fixture.py)."""
from __future__ import annotations

import math
import re
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path

import fixture as fx
from cqcheck import oracle
from cqcheck.contracts import DriverSpec

TMP = Path(tempfile.mkdtemp(prefix="cqo-test."))


def compile_c(name: str, src: str) -> Path:
    d = TMP / name
    d.mkdir(exist_ok=True)
    c = d / f"{name}.c"
    c.write_text(src)
    o1 = d / f"{name}.O1.ll"
    subprocess.run([oracle._tool("clang"), "-target", "x86_64-apple-macosx16.0.0", "-O1", "-S", "-emit-llvm",
                    "-include", str(oracle.SPEC / "CQ.h"), str(c), "-o", str(o1)], check=True)
    return o1


def spec(name: str, protos: str, calls, setup: str = "") -> DriverSpec:
    """calls: [(fn, [ctype...])]"""
    return DriverSpec(name, [p.strip() + ";" for p in protos.split(";") if p.strip()], setup,
                      [{"fn": fn, "args": [{"ctype": t, "quantum": False} for t in ts]} for fn, ts in calls])


def i32(v: int) -> str:
    return "0x%08x" % (v & 0xFFFFFFFF)


def i64(v: int) -> str:
    return "0x%016x" % (v & 0xFFFFFFFFFFFFFFFF)


def f64(x: float) -> str:
    return "0x%016x" % struct.unpack("<Q", struct.pack("<d", x))[0]


def f80(x: float) -> str:
    return fx.sampling.hexw(fx.drivers.parse_ctype("long double"), fx.sampling.f80_from_float(x))


HALF = f64(0.5)


def rets(o1, sp, samples):
    out = []
    for r in oracle.run_samples(o1, sp, samples):
        assert not r.failed, (r.sample, r.reason, r.notes)
        out.append(next(e["v"] for e in r.events if e["ev"] == "ret"))
    return out


def _no_mem(outputs):
    """outputs without the memory and address tables (asserted on their own, FlatMemory below)."""
    return {k: v for k, v in outputs.items() if k not in ("mem", "objects", "regions", "k2", "reads")}


class Totalization(unittest.TestCase):
    """CR §2 rows in the C program."""

    def test_int_div_rem(self):
        o1 = compile_c("divrem", """
int sdiv_q(int x0, double t, int d) { int x = x0; cq_theta(&x, t); return x / d; }
int srem_q(int x0, double t, int d) { int x = x0; cq_theta(&x, t); return x % d; }
unsigned udiv_q(unsigned x0, double t, unsigned d) { unsigned x = x0; cq_theta(&x, t); return x / d; }
unsigned urem_q(unsigned x0, double t, unsigned d) { unsigned x = x0; cq_theta(&x, t); return x % d; }
""")
        sp = spec("divrem", "int sdiv_q(int,double,int);int srem_q(int,double,int);"
                  "unsigned udiv_q(unsigned,double,unsigned);unsigned urem_q(unsigned,double,unsigned)",
                  [("sdiv_q", ["int", "double", "int"]), ("srem_q", ["int", "double", "int"]),
                   ("udiv_q", ["unsigned", "double", "unsigned"]), ("urem_q", ["unsigned", "double", "unsigned"])])
        S = lambda c, a, b: {"call": c, "args": [i32(a), HALF, i32(b)]}
        got = rets(o1, sp, [S(0, 5, 0), S(0, -5, 0), S(0, -2**31, -1), S(0, 7, 2),
                            S(1, 5, 0), S(1, -2**31, -1), S(1, 7, -2),
                            S(2, 5, 0), S(2, 7, 2), S(3, 5, 0), S(3, 7, 4)])
        self.assertEqual(got, ["0xffffffff", "0x1", "0x80000000", "0x3",   # sdiv: -1, +1, INT_MIN, 3
                               "0x5", "0x0", "0x1",                        # srem: a, 0, 1
                               "0xffffffff", "0x3", "0x5", "0x3"])         # udiv 2^W-1; urem a

    def test_shift_amount_mod_w(self):
        o1 = compile_c("shifts", """
int shl_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); return x << k; }
long long ashr_q(long long x0, double t, int k) { long long x = x0; cq_theta(&x, t); return x >> k; }
""")
        sp = spec("shifts", "int shl_q(int,double,int);long long ashr_q(long long,double,int)",
                  [("shl_q", ["int", "double", "int"]), ("ashr_q", ["long long", "double", "int"])])
        got = rets(o1, sp, [{"call": 0, "args": [i32(3), HALF, i32(33)]},
                            {"call": 0, "args": [i32(3), HALF, i32(32)]},
                            {"call": 1, "args": [i64(-256), HALF, i32(68)]}])
        self.assertEqual(got, ["0x6", "0x3", "0xfffffffffffffff0"])   # 33 -> 1, 32 -> 0, 68 -> 4

    def test_fptoint_rows(self):
        o1 = compile_c("fpto", """
signed char s8(double x0, double t) { double x = x0; cq_theta(&x, t); return (signed char)x; }
int s32(double x0, double t) { double x = x0; cq_theta(&x, t); return (int)x; }
unsigned u32(double x0, double t) { double x = x0; cq_theta(&x, t); return (unsigned)x; }
unsigned long long u64(double x0, double t) { double x = x0; cq_theta(&x, t); return (unsigned long long)x; }
int l32(long double x0, double t) { long double x = x0; cq_theta(&x, t); return (int)x; }
unsigned long long l64(long double x0, double t) { long double x = x0; cq_theta(&x, t); return (unsigned long long)x; }
""")
        sp = spec("fpto", "signed char s8(double,double);int s32(double,double);unsigned u32(double,double);"
                  "unsigned long long u64(double,double);int l32(long double,double);"
                  "unsigned long long l64(long double,double)",
                  [("s8", ["double", "double"]), ("s32", ["double", "double"]), ("u32", ["double", "double"]),
                   ("u64", ["double", "double"]), ("l32", ["long double", "double"]),
                   ("l64", ["long double", "double"])])
        nan = math.nan
        S = lambda c, x: {"call": c, "args": [f64(x) if c < 4 else f80(x), HALF]}
        got = rets(o1, sp, [S(0, nan), S(0, 300.0), S(1, nan), S(1, 3e9), S(2, nan), S(2, -1.0),
                            S(3, nan), S(3, 2.0**63 + 4096), S(4, nan), S(4, -7.9), S(5, nan), S(5, 2.0**63)])
        # CR §2: NaN -> s8 0, s32 INT_MIN, u32 0, u64 2^63; 300.0 -> s8 44; f80: fist with indefinite.
        self.assertEqual(got, ["0x0", "0x2c", "0x80000000", "0x80000000", "0x0", "0xffffffff",
                               "0x8000000000000000", "0x8000000000001000", "0x80000000", "0xfffffff9",
                               "0x0", "0x8000000000000000"])

    def test_maxnum_fmuladd_ctz(self):
        o1 = compile_c("misc", """
double fmax_q(double x0, double t, double c) { double x = x0; cq_theta(&x, t); return __builtin_fmax(x, c); }
int ctz_q(unsigned x0, double t) { unsigned x = x0; cq_theta(&x, t); return __builtin_ctz(x); }
int abs_q(int x0, double t) { int x = x0; cq_theta(&x, t); return __builtin_abs(x); }
""")
        sp = spec("misc", "double fmax_q(double,double,double);int ctz_q(unsigned,double);int abs_q(int,double)",
                  [("fmax_q", ["double", "double", "double"]), ("ctz_q", ["unsigned", "double"]),
                   ("abs_q", ["int", "double"])])
        got = rets(o1, sp, [{"call": 0, "args": [f64(math.nan), HALF, f64(2.0)]},
                            {"call": 0, "args": [f64(-0.0), HALF, f64(0.0)]},
                            {"call": 1, "args": [i32(0), HALF]}, {"call": 2, "args": [i32(-2**31), HALF]}])
        self.assertEqual(got, ["0x4000000000000000", "0x8000000000000000", "0x20", "0x80000000"])


class Memory(unittest.TestCase):
    """CR §6: indeterminate reads and reads outside an object are 0."""

    def test_reads(self):
        o1 = compile_c("mem", """
#include <stdlib.h>
static const int T[4] = {1, 2, 3, 4};
static const int U[4] = {9, 9, 9, 9};
__attribute__((noinline)) static void put(int *a, int i, int v) { a[i] = v; }
int uninit_q(int x0, double t) { int a[4]; int x = x0; cq_theta(&x, t); put(a, x & 1, 5); return a[(x & 1) ^ 1] + U[0] - 9; }
int heap_q(int x0, double t) { int x = x0; cq_theta(&x, t); int *p = malloc(16); put(p, x & 1, x);
    int r = p[(x & 1) ^ 1]; free(p); return r; }
int table_q(unsigned x0, double t) { unsigned x = x0; cq_theta(&x, t); return T[x] + U[1] - 9; }
int store_q(unsigned x0, double t) { unsigned x = x0; cq_theta(&x, t); int a[2] = {1, 2}, b[2] = {3, 4};
    put(a, x, 7); put(b, 0, b[0]); return a[0] + a[1] + b[0] + b[1]; }
""")
        sp = spec("mem", "int uninit_q(int,double);int heap_q(int,double);int table_q(unsigned,double);"
                  "int store_q(unsigned,double)",
                  [("uninit_q", ["int", "double"]), ("heap_q", ["int", "double"]),
                   ("table_q", ["unsigned", "double"]), ("store_q", ["unsigned", "double"])])
        got = rets(o1, sp, [{"call": 0, "args": [i32(0), HALF]}, {"call": 1, "args": [i32(1), HALF]},
                            {"call": 2, "args": [i32(2), HALF]}, {"call": 2, "args": [i32(5), HALF]},
                            {"call": 2, "args": [i32(1000000), HALF]}, {"call": 3, "args": [i32(1), HALF]},
                            {"call": 3, "args": [i32(2), HALF]}, {"call": 3, "args": [i32(3), HALF]}])
        # uninit 0; heap 0; T[2] = 3; T[5] (U lies right after T) and T[10^6] read 0; an
        # out-of-object store is dropped, never landing in b.
        self.assertEqual(got, ["0x0", "0x0", "0x3", "0x0", "0x0", "0xf", "0xa", "0xa"])


    def test_byval_and_varargs_objects(self):
        # A byval parameter copy and the areas va_start points at (register save area, overflow
        # area) are objects of the callee's frame: reads there are the passed values (cq-be73).
        o1 = compile_c("byvalva", """
#include <stdarg.h>
struct big { long a[5]; };
__attribute__((noinline)) static long sumb(struct big b) { return b.a[0] + b.a[2] + b.a[4]; }
long byval_q(long x0, double t, long c) { long x = x0; cq_theta(&x, t); struct big b = {{x, 1, c, 3, 4}};
    return sumb(b); }
__attribute__((noinline)) static int vhelp(int n, va_list ap) { int s = 0; for (int i = 0; i < n; i++)
    s = s * 3 + va_arg(ap, int); return s; }
__attribute__((noinline)) static int vsum(int n, ...) { va_list ap, bp; va_start(ap, n); va_copy(bp, ap);
    int s = vhelp(n, ap); s += vhelp(n, bp); va_end(bp); va_end(ap); return s; }
int va_q(int x0, double t, int c) { int x = x0; cq_theta(&x, t); return vsum(9, x, c, 1, 2, 3, 4, 5, 6, 7); }
__attribute__((noinline)) static long double vld(int n, ...) { va_list ap; va_start(ap, n); long double s = 0;
    for (int i = 0; i < n; i++) s = s * 2 + va_arg(ap, long double); va_end(ap); return s; }
long double vld_q(long double x0, double t) { long double x = x0; cq_theta(&x, t); return vld(3, x, 1.0L, x); }
__attribute__((noinline)) static double vdbl(int n, ...) { va_list ap; va_start(ap, n); double s = 0;
    for (int i = 0; i < n; i++) s = s * 2 + va_arg(ap, double); va_end(ap); return s; }
double vdbl_q(double x0, double t) { double x = x0; cq_theta(&x, t);
    return vdbl(10, x, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, x); }
""")
        sp = spec("byvalva", "long byval_q(long,double,long);int va_q(int,double,int);"
                  "long double vld_q(long double,double);double vdbl_q(double,double)",
                  [("byval_q", ["long", "double", "long"]), ("va_q", ["int", "double", "int"]),
                   ("vld_q", ["long double", "double"]), ("vdbl_q", ["double", "double"])])
        runs = oracle.run_samples(o1, sp, [{"call": 0, "args": [i64(10), HALF, i64(20)]},
                                           {"call": 1, "args": [i32(2), HALF, i32(1)]},
                                           {"call": 2, "args": [f80(3.0), HALF]},
                                           {"call": 3, "args": [f64(1.0), HALF]}])
        for r in runs:
            self.assertFalse(r.failed, (r.sample, r.reason))
            self.assertNotIn("oob-load", r.notes)
        got = [next(e["v"] for e in r.events if e["ev"] == "ret") for r in runs]
        h = 0
        for v in [2, 1, 1, 2, 3, 4, 5, 6, 7]:
            h = h * 3 + v
        self.assertEqual(got, ["0x22", hex(2 * h), f80(3.0 * 4 + 2 + 3.0), f64(2.0**9 + 2.0**8 + 2 + 1.0)])

    def test_driver_object(self):
        # a driver object is a function-local static ("__cqo_drv_main.tab"): an object like any
        # other, readable from the program (regression of cq-8ay)
        o1 = compile_c("drvobj", "double pick_q(const double *c, double x0, double t) "
                                 "{ double x = x0; cq_theta(&x, t); return x + c[2]; }")
        sp = spec("drvobj", "double pick_q(const double*,double,double)",
                  [("pick_q", ["const double*", "double", "double"])],
                  setup="static const double tab[4] = {1, 2, 3, 4};")
        self.assertEqual(rets(o1, sp, [{"call": 0, "args": ["tab", f64(0.5), HALF]}]), [f64(3.5)])

    def test_stackrestore_ends_vlas(self):
        # cq-t3kb: llvm.stackrestore deallocates the allocas made since its stacksave, so their
        # objects end there (a read through a pointer kept past the scope is outside every object:
        # 0, oob-load), and a VLA in a loop leaves no object per trip behind: 2^20 trips, each
        # reading an older local, run within the default hang guard at a 2^20 budget (109's
        # vla_loop_q hit the guard: every access scanned one stale object per trip so far)
        o1 = compile_c("vla", """
__attribute__((noinline)) static void put(int *a, int v) { a[0] = v; }
__attribute__((noinline)) static int get(int *a) { return a[0]; }
int vla_q(int n, int m) { volatile int acc = 0;
    for (int i = 0; i < m; i++) { int v[n]; put(v, 1); acc += get(v); } return acc; }
int dangle_q(int n) { int *p; { int v[n]; put(v, 7); p = v; } return get(p); }
""")
        sp = spec("vla", "int vla_q(int,int);int dangle_q(int)",
                  [("vla_q", ["int", "int"]), ("dangle_q", ["int"])])
        self.assertIn("llvm.stackrestore", o1.read_text())
        runs = oracle.run_samples(o1, sp, [{"call": 0, "args": [i32(3), i32((1 << 20) - 1)]},
                                           {"call": 1, "args": [i32(3)]}],
                                  timeout_ms=oracle.DEFAULT_TIMEOUT_MS, tripcap=1 << 20, trips_only=True)
        self.assertEqual([r.outcome for r in runs], ["ret", "ret"], [(r.reason, r.notes) for r in runs])
        self.assertEqual([next(e["v"] for e in r.events if e["ev"] == "ret") for r in runs],
                         [hex((1 << 20) - 1), "0x0"])
        self.assertIn("oob-load", runs[1].notes)


class DefaultEnv(unittest.TestCase):
    """Owner ruling on cq-0r1i: non-constrained fp ops run round-to-nearest and raise no flags,
    whatever mode the program set; constrained ops (FENV_ACCESS) see the live mode and flags."""

    SRC = """
#include <fenv.h>
%s
double y_q(double x0, double t, double c) { double x = x0; cq_theta(&x, t); fesetround(FE_UPWARD);
    double y = x * c; fesetround(FE_TONEAREST); return cq_measure(y); }
int f_q(double x0, double t, double c) { double x = x0; cq_theta(&x, t); fesetround(FE_UPWARD);
    feclearexcept(FE_ALL_EXCEPT); double y = x * c; long long q = (long long)(y * 1e300 * 1e300);
    volatile double z = (double)(q | 1); (void)z; int f = fetestexcept(FE_ALL_EXCEPT); fesetround(FE_TONEAREST);
    return cq_measure(f); }
"""

    def run2(self, name, pragma):
        o1 = compile_c(name, self.SRC % pragma)
        sp = spec(name, "double y_q(double,double,double);int f_q(double,double,double)",
                  [("y_q", ["double", "double", "double"]), ("f_q", ["double", "double", "double"])])
        a = 1.0 + 2.0**-52
        return rets(o1, sp, [{"call": 0, "args": [f64(a), HALF, f64(a)]},
                             {"call": 1, "args": [f64(a), HALF, f64(a)]}])

    def test_plain_ops_default_env(self):
        # (1 + 2^-52)^2 = 1 + 2^-51 + 2^-104: nearest 1 + 2^-51, upward 1 + 2^-51 + 2^-52. Plain ops:
        # nearest and no flags (although the product overflows and the conversion is invalid).
        self.assertEqual(self.run2("dflenv", ""), [f64(1.0 + 2.0**-51), "0x0"])

    def test_constrained_ops_live_env(self):
        # FENV_ACCESS: the live mode rounds up; INEXACT, OVERFLOW and INVALID are observed.
        y, f = self.run2("dflenv_strict", "#pragma STDC FENV_ACCESS ON")
        self.assertEqual(y, f64(1.0 + 2.0**-51 + 2.0**-52))
        self.assertEqual(int(f, 16) & 0x29, 0x29)
class Fenv(unittest.TestCase):
    """Rule 23's fenv model in the C program (cq-fvs2): five IEEE flags, no FE_DENORMAL;
    feraiseexcept(m) is flags | m; fesetround of an invalid mode returns 1 and keeps the mode."""

    def test_fenv_calls(self):
        o1 = compile_c("fenvm", """
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
int denorm_q(double x0, double t, double k) { double x = x0; cq_theta(&x, t); feclearexcept(FE_ALL_EXCEPT);
    int r = x > k; return fetestexcept(FE_ALL_EXCEPT) * 2 + r; }
int raise_q(int x0, double t) { int x = x0; cq_theta(&x, t); feclearexcept(FE_ALL_EXCEPT);
    feraiseexcept(x); return fetestexcept(FE_ALL_EXCEPT); }
int round_q(int x0, double t) { int x = x0; cq_theta(&x, t); int rc = fesetround(x); int m = fegetround();
    fesetround(FE_TONEAREST); return rc * 0x10000 + m; }
int flagset_q(int x0, double t) { int x = x0; cq_theta(&x, t); feclearexcept(FE_ALL_EXCEPT);
    feraiseexcept(FE_INEXACT | FE_INVALID); fexcept_t s; fegetexceptflag(&s, FE_INEXACT);
    feclearexcept(FE_ALL_EXCEPT); feraiseexcept(FE_UNDERFLOW); fesetexceptflag(&s, x);
    return fetestexcept(FE_ALL_EXCEPT); }
int update_q(int x0, double t) { int x = x0; cq_theta(&x, t); fenv_t e; feclearexcept(FE_ALL_EXCEPT);
    feholdexcept(&e); feraiseexcept(x); feupdateenv(&e); return fetestexcept(FE_ALL_EXCEPT); }
""")
        sp = spec("fenvm", "int denorm_q(double,double,double);int raise_q(int,double);int round_q(int,double);"
                  "int flagset_q(int,double);int update_q(int,double)",
                  [("denorm_q", ["double", "double", "double"]), ("raise_q", ["int", "double"]),
                   ("round_q", ["int", "double"]), ("flagset_q", ["int", "double"]), ("update_q", ["int", "double"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        got = rets(o1, sp, [S(0, "0x0010000000000000", HALF, f64(3.0)),   # subnormal-free normal: no flag
                            S(0, "0x0000000000000001", HALF, f64(0.0)),   # subnormal operand: DENORMAL hidden
                            S(1, i32(8), HALF), S(1, i32(0x3f), HALF),
                            S(2, i32(0x800), HALF), S(2, i32(8), HALF), S(2, i32(-1), HALF),
                            S(3, i32(0x20), HALF), S(3, i32(0x30), HALF),
                            S(4, i32(8), HALF)])
        self.assertEqual(got, ["0x0", "0x1", "0x8", "0x3d", "0x800", "0x10000", "0x10000",
                               "0x30", "0x20", "0x8"])


class ShadowPerSpecialization(unittest.TestCase):
    """CR rule 2 (cq-gsms2): one body, two specializations. The result of a call whose specialization holds it classical never
    was a rail, a read; the same function's result in the specialization that holds it as a rail is a measurement."""

    def test_read_and_measure_of_one_callee(self):
        o1 = compile_c("specsh", """
__attribute__((noinline)) static int pick(int x) { int r; if (x & 1) r = x * 3; else r = x + 1; return r; }
int both(int a, int b, double t) {
    int q = b;
    cq_theta(&q, t);
    int c = pick(a), d = pick(q);
    return cq_measure(c) + cq_measure(d);
}
""")
        sp = spec("specsh", "int both(int,int,double)", [("both", ["int", "int", "double"])])
        for a in (0, 1, 6, 7):
            ev = oracle.trace_sample(o1, sp, {"call": 0, "args": [i32(a), i32(a + 1), HALF]})
            kinds = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] != "theta"]
            self.assertEqual(kinds, ["read", "measure"], (a, ev))


class Events(unittest.TestCase):
    def test_sites_trips_ret(self):
        o1 = compile_c("ev", """
int loop_q(unsigned x0, double t, double p) {
    unsigned x = x0; int n = 0;
    cq_theta(&x, t);
    while (x > 1) { x >>= 1; n++; }
    if (n == 2) cq_phi(p);
    return cq_measure(n);
}
int header_q(unsigned x0, double t) {
    unsigned x = x0; int n = 0;
    cq_theta(&x, t);
    for (;;) { if (x == 0) break; x &= x - 1; n++; }
    return cq_measure(n);
}
void inv_q(int x0, double t) { int x = x0; cq_invert_begin(); cq_theta(&x, t); cq_invert_end(); }
""")
        sp = spec("ev", "int loop_q(unsigned,double,double);int header_q(unsigned,double);void inv_q(int,double)",
                  [("loop_q", ["unsigned", "double", "double"]), ("header_q", ["unsigned", "double"]),
                   ("inv_q", ["int", "double"])])
        pa = f64(0.25)
        tr = lambda s: oracle.trace_sample(o1, sp, s)
        trips = lambda ev: [e["n"] for e in ev if e["ev"] == "trip"]
        for x, n in [(0, 0), (1, 0), (3, 1), (4, 2), (31, 4)]:   # at most K = 4 trips: run to the end
            ev = tr({"call": 0, "args": [i32(x), HALF, pa]})
            self.assertEqual(trips(ev), [n], (x, ev))
            # a trace starts with the `enter` of the function the driver calls (compare._meas_extra: the functions an input enters)
            self.assertEqual(ev[0], {"ev": "enter", "fn": "loop_q"})
            self.assertEqual(ev[1], {"ev": "site", "fn": "loop_q", "site": 0, "kind": "theta",
                                     "angle": HALF, "reg": hex(x), "pre": hex(x)})   # pre: cq-3o3v
            phis = [e for e in ev if e["ev"] == "site" and e["kind"] == "phi"]
            self.assertEqual(len(phis), 1 if n == 2 else 0)
            if phis:
                self.assertEqual(phis[0]["angle"], pa)
                self.assertIsNone(phis[0]["reg"])
            self.assertEqual(ev[-1], {"ev": "ret", "v": hex(n)})
        for x, n in [(0, 0), (1, 1), (7, 3), (0xF, 4)]:
            self.assertEqual(trips(tr({"call": 1, "args": [i32(x), HALF]})), [n], x)
        ev = tr({"call": 2, "args": [i32(3), HALF]})
        self.assertEqual([e.get("kind", e["ev"]) for e in ev], ["invert_begin", "theta", "invert_end", "ret"])   # no cq_measure in inv_q: no enter
        self.assertIsNone(ev[-1]["v"])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [i32(4), HALF, pa]})
        self.assertEqual(rr.side, "c")
        self.assertEqual(rr.sample, {"call": 0, "args": [i32(4), HALF, pa]})
        self.assertEqual([(r["ev"], r["kind"]) for r in rr.rotations], [("site", "theta"), ("site", "phi")])
        self.assertEqual(rr.rotations[0], {"ev": "site", "fn": "loop_q", "site": 0, "kind": "theta",
                                           "angle": HALF, "reg": hex(4), "pre": hex(4),
                                           "nmeas": 0})   # nmeas: cq-459d
        self.assertEqual(rr.measured, [{"h": None, "w": "i32", "v": "0x2"}])
        self.assertEqual(_no_mem(rr.outputs), {"ret": [{"call": 0, "fn": "loop_q", "v": {"w": "i32", "v": "0x2"}}],
                                               "end": "ret",
                                               "loops": [{"loop": "loop_q:%6", "act": 0, "n": 2, "capped": False}],
                                               "stdout": "", "effects": [],
                                               "entered": ["loop_q"]})   # the functions this input enters
        self.assertEqual(rr.violations, [])
        self.assertIsNone(rr.kept)
        self.assertIsNone(rr.clean)
        rr = oracle.run_sample(o1, sp, {"call": 2, "args": [i32(3), HALF]})
        self.assertEqual([r["kind"] for r in rr.rotations], ["invert_begin", "theta", "invert_end"])
        self.assertEqual(rr.outputs["ret"], [])
        # T1.2: loop ids are "<fn>:<header>", the header label as spelled in the input .O1.ll
        text = Path(o1).read_text()
        for e in tr({"call": 0, "args": [i32(31), HALF, pa]}) + tr({"call": 1, "args": [i32(7), HALF]}):
            if e["ev"] == "trip":
                fn, hdr = e["loop"].split(":", 1)
                self.assertIn(fn, ("loop_q", "header_q"), e)
                self.assertRegex(hdr, r"^%[-\w.$]+$", e)
                body = text[text.index(f"@{fn}("):]
                body = body[:body.index("\n}")]
                self.assertRegex(body, rf"(?m)^{re.escape(hdr[1:])}:", (e, body))

    def test_guard_skip_through_preheader(self):
        # cq-ly85: the guard reaches the header through a preheader block (the shape of example 55);
        # a skip reports n = 0, and a path that returns before the guard reports nothing.
        o1 = compile_c("gp", """
int gp_q(int m0, double t, int c, int early) {
    int m = m0;
    cq_theta(&m, t);
    if (early == 7) return cq_measure(m);
    int a[4] = {0, 0, 0, 0};
    for (int i = 0; i <= m; i++) a[i] = i * c;
    return cq_measure(a[m - 1]);
}
""")
        text = Path(o1).read_text()
        # the shape under test: the guard's taken edge enters a preheader that branches to the header
        self.assertRegex(text, r"br i1 %\d+, label %\d+, label %(\d+)\n\n\1:[^\n]*\n(  [^\n]*\n)*?  br label %\d+\n", text)
        sp = spec("gp", "int gp_q(int,double,int,int)", [("gp_q", ["int", "double", "int", "int"])])
        trips = lambda ev: [e["n"] for e in ev if e["ev"] == "trip"]
        for m, n in [(-1, 0), (-5, 0), (0, 1), (2, 3)]:
            ev = oracle.trace_sample(o1, sp, {"call": 0, "args": [i32(m), HALF, i32(3), i32(0)]})
            self.assertEqual(trips(ev), [n], (m, ev, text))
        for m in (-1, 2):
            ev = oracle.trace_sample(o1, sp, {"call": 0, "args": [i32(m), HALF, i32(3), i32(7)]})
            self.assertEqual(trips(ev), [], (m, ev))

    def test_fp_output_typed_and_subst(self):
        o1 = compile_c("fpout", "double id_q(double x0, double t) { double x = x0; cq_theta(&x, t); return x + 1; }")
        sp = spec("fpout", "double id_q(double,double)", [("id_q", ["double", "double"])])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [f64(1.0), HALF]})
        self.assertEqual(rr.outputs["ret"], [{"call": 0, "fn": "id_q", "v": {"w": "f64", "v": f64(2.0)}}])
        r = oracle.run_samples(o1, sp, [{"call": 0, "args": [f64(1.0), HALF], "subst": {"id_q:0": f64(5.0)}}])[0]
        self.assertEqual(r.events[0]["reg"], f64(5.0))
        self.assertEqual(r.events[0]["pre"], f64(1.0))   # cq-3o3v: the register before the substitution
        self.assertEqual(r.events[-1]["v"], f64(6.0))


    def test_subst_per_reach(self):
        """cq-6m2 (cq-arch Z4): a list gives reach r its entry r mod len; a site with no entry keeps its
        value; reg is the chosen value; the values steer the C program (q[i] controls the next theta)."""
        o1 = compile_c("subst", """
int chain(int n, double t, double c) {
    _Bool q[8]; int s = 0;
    for (int i = 0; i < n; i++) { q[i] = 0; cq_theta(&q[i], t); }
    for (int i = 0; i + 1 < n; i++) if (q[i]) cq_theta(&q[i + 1], c);
    for (int i = 0; i < n; i++) s = 2 * s + cq_measure(q[i]);
    return s;
}""")
        sp = spec("subst", "int chain(int,double,double)", [("chain", ["int", "double", "double"])])
        sites = {k: v for k, v in oracle.site_callees(o1).items() if v.startswith("cq_theta_")}
        (first, second) = sorted(sites)
        args = [i32(4), HALF, f64(0.25)]
        k0, k1 = f"{first[0]}:{first[1]}", f"{second[0]}:{second[1]}"
        cases = [
            ({}, "0x0", []),
            ({k0: "0x1"}, "0xf", ["0x1"] * 4 + ["0x1"] * 3),
            ({k0: ["0x1", "0x0"]}, "0xa", ["0x1", "0x0", "0x1", "0x0", "0x0", "0x0"]),   # second: identity
            ({k0: ["0x1", "0x0", "0x0", "0x0"], k1: ["0x0"]}, "0x8", ["0x1", "0x0", "0x0", "0x0", "0x0"]),
            ({k0: "0x1", k1: ["0x1", "0x0"]}, "0xd", ["0x1"] * 4 + ["0x1", "0x0"]),   # q = 1 1 0 1
        ]
        runs = oracle.run_samples(o1, sp, [{"call": 0, "args": args, **({"subst": sub} if sub else {})}
                                           for sub, _, _ in cases])
        for (sub, ret, regs), r in zip(cases, runs):
            self.assertFalse(r.failed, (sub, r.reason))
            th = [e["reg"] for e in r.events if e["ev"] == "site" and e["kind"] == "theta"]
            if sub:
                self.assertEqual(th, regs, sub)
            self.assertEqual(next(e["v"] for e in r.events if e["ev"] == "ret"), ret, sub)


class Outcomes(unittest.TestCase):
    def test_terminations(self):
        o1 = compile_c("term", """
#include <stdlib.h>
#include <signal.h>
int abort_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); if (x == k) abort(); return cq_measure(x); }
int trap_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); if (x == k) __builtin_trap(); return x; }
int raise_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); if (x == k) raise(SIGABRT); return x; }
/* cq-rjagm (owner Q3): a runaway loop that does not allocate (no memory access: no shadow node per trip); the constant
   controlling expression keeps it from being assumed to terminate (no mustprogress). */
int spin_q(unsigned x0, double t, unsigned c) { unsigned x = x0; cq_theta(&x, t); for (;;) { if (c == 0) break; c += 2; }
    return x + c; }
""")
        sp = spec("term", "int abort_q(int,double,int);int trap_q(int,double,int);int raise_q(int,double,int);"
                  "int spin_q(unsigned,double,unsigned)",
                  [("abort_q", ["int", "double", "int"]), ("trap_q", ["int", "double", "int"]),
                   ("raise_q", ["int", "double", "int"]), ("spin_q", ["unsigned", "double", "unsigned"])])
        rs = oracle.run_samples(o1, sp, [
            {"call": 0, "args": [i32(2), HALF, i32(2)]}, {"call": 0, "args": [i32(1), HALF, i32(2)]},
            {"call": 1, "args": [i32(2), HALF, i32(2)]}, {"call": 2, "args": [i32(2), HALF, i32(2)]},
            {"call": 3, "args": [i32(0), HALF, i32(1)]}, {"call": 3, "args": [i32(0), HALF, i32(2**32 - 4)]}],
            timeout_ms=5000, tripcap=100000)
        self.assertEqual([(r.outcome, r.failed) for r in rs],
                         [("noreturn:abort", False), ("ret", False), ("noreturn:llvm.trap", False),
                          ("raise:6", False), ("", True), ("ret", False)])
        # a classical loop is never cut at K: it runs to the end (here, to the trip cap)
        self.assertIn("nonterminating", rs[4].reason)
        self.assertEqual(rs[5].loops, [])
        with self.assertRaises(oracle.OracleError):
            oracle.trace_sample(o1, sp, {"call": 3, "args": [i32(0), HALF, i32(1)]})
        rr = oracle.run_sample(o1, sp, {"call": 3, "args": [i32(0), HALF, i32(1)]})
        self.assertEqual(len(rr.violations), 1)
        self.assertEqual(rr.violations[0]["what"], "c_oracle")
        self.assertIsNone(rr.violations[0]["h"])
        self.assertIn("nonterminating", rr.violations[0]["msg"])
        self.assertEqual(rr.outputs["ret"], [])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [i32(2), HALF, i32(2)]})
        self.assertEqual(_no_mem(rr.outputs), {"ret": [], "end": "noreturn:abort", "loops": [], "stdout": "", "effects": [],
                                                 "entered": ["abort_q"]})
        self.assertEqual(rr.violations, [])

    def test_no_wall_clock_outcome(self):
        # cq-sqn6: nontermination is the trip-cap step budget, never a clock. A runaway sample ends at
        # the cap with the same result whatever timeout_ms is (here far below the run's wall time), and
        # the hang guard, reached only past the budget, is an internal error, never a sample outcome.
        o1 = compile_c("spin", r"""
volatile int sink;
int spin_q(unsigned x0, double t, unsigned c) { unsigned x = x0; cq_theta(&x, t); while (c != 0) { c += 2; sink++; }
    return x + c; }
""")
        sp = spec("spin", "int spin_q(unsigned,double,unsigned)", [("spin_q", ["unsigned", "double", "unsigned"])])
        smp = [{"call": 0, "args": [i32(0), HALF, i32(1)]}, {"call": 0, "args": [i32(0), HALF, i32(0)]}]
        want = None
        for to in (50, 2000):
            rs = oracle.run_samples(o1, sp, smp * 3, timeout_ms=to, tripcap=20000)
            got = [(r.outcome, r.failed, r.reason, r.notes, r.events) for r in rs]
            self.assertEqual([(g[0], g[1]) for g in got], [("", True), ("ret", False)] * 3, to)
            self.assertIn("nonterminating", rs[0].reason)
            want = want or got
            self.assertEqual(got, want, to)
        with self.assertRaisesRegex(oracle.OracleError, "hang guard"):
            oracle.run_samples(o1, sp, smp, timeout_ms=100, tripcap=10 ** 15)


KSRC = r"""
volatile int sink;
/* a quantum-exit loop (guarded, tested at the latch) with a phase in its body */
int halve_q(unsigned x0, double t, double p) {
    unsigned x = x0; int n = 0;
    cq_theta(&x, t);
    while (x > 1) { cq_phi(p); x >>= 1; n++; sink++; }
    return cq_measure(n);
}
/* never exits for an even x0 */
int stuck_q(unsigned x0, double t) { unsigned x = x0; cq_theta(&x, t); while (x != 1) { x = x * 3 + 2; sink++; } return x; }
/* tested at its header (no guard): a trip is test then body */
int header_q(unsigned x0, double t) {
    unsigned x = x0; int n = 0;
    cq_theta(&x, t);
    for (;;) { if (x == 0) break; x &= x - 1; n++; sink++; }
    return cq_measure(n);
}
/* classical bound with a quantum exit (rule 14: no cutoff; the shape of example 26) */
int scan_q(unsigned x0, double t, int c) {
    int x = x0; int i; cq_theta(&x, t);
    for (i = 0; i < c; i++) { if (x == i + 7) break; }
    return cq_measure(i);
}
/* a classical loop in a quantum function */
int count_q(unsigned x0, double t, int c) {
    unsigned x = x0; int s = 0; cq_theta(&x, t);
    for (int i = 0; i < c; i++) { s += i; sink++; }
    return cq_measure(x + s);
}
/* a quantum-exit loop entered once per trip of a classical loop */
int nest_q(unsigned x0, double t, int c) {
    unsigned x = x0; int s = 0; cq_theta(&x, t);
    for (int i = 0; i < c; i++) { unsigned y = x << i; while (y > 1) { y >>= 1; s++; sink++; } sink++; }
    return cq_measure(s);
}
/* one function called classically and quantumly */
__attribute__((noinline)) static int steps(unsigned x) {
    int n = 0; while (x > 1) { x = (x & 1) ? 3 * x + 1 : x / 2; n++; sink++; } return n;
}
int both_q(unsigned x0, double t, unsigned c) { unsigned x = x0; int a = steps(c); cq_theta(&x, t); return a + cq_measure(steps(x)); }
/* quantum-depth recursion, entered from outside its cycle */
__attribute__((noinline)) static int chain(int n, int a) { if (n <= 0) return a; return a - chain(n - 1, a + 1); }
int rec_q(int n0, double t, int a) { int n = n0; cq_theta(&n, t); return cq_measure(chain(n, a)); }
/* quantum-depth recursion entered by the driver's own call */
int selfrec_q(int n, double t, int d) { if (d) cq_theta(&n, t); if (n <= 0) return 0; return n - selfrec_q(n - 1, t, 0); }
/* CQ_K(f, k) */
CQ_K(kq2, 2)
int kq2(unsigned x0, double t) { unsigned x = x0; int n = 0; cq_theta(&x, t); while (x > 1) { x >>= 1; n++; sink++; } return cq_measure(n); }
"""


class Cutoff(unittest.TestCase):
    """CR §6 at eb8a11a (ruling cq-1di, bead cq-8ay): every quantum-exit loop and quantum-depth
    recursion stops after K trips; the cq-arch T2 records in outputs["loops"]."""

    @classmethod
    def setUpClass(cls):
        cls.o1 = compile_c("kcut", KSRC)
        fns = [("halve_q", ["unsigned", "double", "double"]), ("stuck_q", ["unsigned", "double"]),
               ("header_q", ["unsigned", "double"]), ("scan_q", ["unsigned", "double", "int"]),
               ("count_q", ["unsigned", "double", "int"]), ("nest_q", ["unsigned", "double", "int"]),
               ("both_q", ["unsigned", "double", "unsigned"]), ("rec_q", ["int", "double", "int"]),
               ("selfrec_q", ["int", "double", "int"]), ("kq2", ["unsigned", "double"])]
        cls.sp = spec("kcut", ";".join(f"int {f}({','.join(ts)})" for f, ts in fns), fns)
        cls.call = {f: i for i, (f, _) in enumerate(fns)}
        text = cls.o1.read_text()
        cls.text = text

    def run1(self, fn, *args, **kw):
        return oracle.run_samples(self.o1, self.sp, [{"call": self.call[fn], "args": list(args)}], **kw)[0]

    def rr(self, fn, *args):
        return oracle.run_sample(self.o1, self.sp, {"call": self.call[fn], "args": list(args)})

    def loop_id(self, fn):
        ids = {e["loop"] for x in range(2, 9) for e in self.run1(fn, i32(x), HALF, *([HALF] if fn == "halve_q" else [])).events
               if e["ev"] == "trip"}
        self.assertEqual(len(ids), 1, ids)
        return ids.pop()

    def test_at_most_k_trips_unchanged(self):
        lid = self.loop_id("halve_q")
        for x, n in [(0, 0), (1, 0), (2, 1), (4, 2), (8, 3), (31, 4)]:
            r = self.run1("halve_q", i32(x), HALF, HALF)
            self.assertFalse(r.failed, r.reason)
            self.assertEqual(r.outcome, "ret")
            self.assertEqual([e["n"] for e in r.events if e["ev"] == "trip"], [n])
            self.assertEqual(sum(1 for e in r.events if e.get("kind") == "phi"), n)
            self.assertEqual(r.events[-1], {"ev": "ret", "v": hex(n)})
            self.assertEqual(r.loops, [{"loop": lid, "act": 0, "n": n, "capped": False}])
        rr = self.rr("halve_q", i32(31), HALF, HALF)
        self.assertEqual(rr.outputs["ret"], [{"call": 0, "fn": "halve_q", "v": {"w": "i32", "v": "0x4"}}])
        self.assertEqual(rr.violations, [])

    def test_more_than_k_trips_capped(self):
        lid = self.loop_id("halve_q")
        for x in (32, 1000, 2**32 - 1):
            r = self.run1("halve_q", i32(x), HALF, HALF)
            self.assertFalse(r.failed, r.reason)
            self.assertEqual(r.outcome, f"cap:{lid}")
            self.assertEqual([e for e in r.events if e["ev"] in ("trip", "ret")], [])   # no exit, no return
            # cut: the theta and the K phases of trips 1..K; nothing measured yet
            self.assertEqual(r.loops, [{"loop": lid, "act": 0, "n": 4, "capped": True, "cut": 5, "mcut": 0}])
            self.assertEqual(sum(1 for e in r.events if e.get("kind") == "phi"), 4)
        rr = self.rr("halve_q", i32(32), HALF, HALF)
        self.assertEqual(rr.violations, [])                 # a capped run is not a violation (T2.7)
        self.assertEqual(rr.outputs["ret"], [])
        self.assertEqual(rr.outputs["end"], f"cap:{lid}")
        self.assertEqual(len(rr.rotations), rr.outputs["loops"][0]["cut"])
        ev = oracle.trace_sample(self.o1, self.sp, {"call": 0, "args": [i32(32), HALF, HALF]})
        # the trace also holds the `enter` of the called function (compare._meas_extra): the sites are what is compared
        self.assertEqual([e["ev"] for e in ev if e["ev"] == "enter"], ["enter"])
        self.assertEqual([e["kind"] for e in ev if e["ev"] != "enter"], ["theta"] + ["phi"] * 4)

    def test_nonterminating_capped(self):
        for x in (0, 2, 6):
            r = self.run1("stuck_q", i32(x), HALF, timeout_ms=3000, tripcap=1000)
            self.assertFalse(r.failed, r.reason)
            self.assertTrue(r.outcome.startswith("cap:stuck_q:%"), r.outcome)
            self.assertEqual([(l["n"], l["capped"]) for l in r.loops], [(4, True)])
        r = self.run1("stuck_q", i32(1), HALF)
        self.assertEqual((r.outcome, [(l["n"], l["capped"]) for l in r.loops]), ("ret", [(0, False)]))

    def test_header_tested(self):
        # T1.2: n counts the bodies; the header run that exits begins no trip. Cut after the K-th body
        # only when the next header test admits a (K+1)-th.
        for x, n in [(0, 0), (1, 1), (7, 3), (0xF, 4)]:
            r = self.run1("header_q", i32(x), HALF)
            self.assertEqual((r.outcome, [(l["n"], l["capped"]) for l in r.loops]), ("ret", [(n, False)]), x)
        for x in (0x1F, 0xFF):
            r = self.run1("header_q", i32(x), HALF)
            self.assertTrue(r.outcome.startswith("cap:"), (x, r.outcome))
            self.assertEqual([(l["n"], l["capped"], l["cut"], l["mcut"]) for l in r.loops], [(4, True, 1, 0)])

    def test_classical_loops_run_to_completion(self):
        for fn, x, c, want in [("scan_q", 0, 20, 20), ("scan_q", 16, 50, 9), ("count_q", 3, 100, 3 + 4950)]:
            r = self.run1(fn, i32(x), HALF, i32(c))
            self.assertEqual(r.outcome, "ret", (fn, r.reason))
            self.assertEqual(r.events[-1]["v"], hex(want))
            self.assertEqual(r.loops, [], fn)

    def test_nested_activations(self):
        # inner loop: x << i halved to 1; x = 1 gives i trips on outer trip i
        r = self.run1("nest_q", i32(1), HALF, i32(4))
        self.assertEqual(r.outcome, "ret")
        lid = r.loops[0]["loop"]
        # an activation's identity is the call path leading to it hashed with its how-many-th there, the same on every
        # sample that reaches it (cqo_rt.c next_act, cq-rdsdj); nest_q's loop is entered from the driver's call: path 0
        act = lambda i: ((i * 0x9E3779B97F4A7C15) & (2**64 - 1)) >> 1
        self.assertEqual(r.loops, [{"loop": lid, "act": act(i), "n": i, "capped": False} for i in range(4)])
        self.assertEqual(r.events[-1]["v"], hex(0 + 1 + 2 + 3))
        r = self.run1("nest_q", i32(1), HALF, i32(9))
        self.assertEqual(r.outcome, f"cap:{lid}")
        self.assertEqual([(l["act"], l["n"], l["capped"]) for l in r.loops],
                         [(act(0), 0, False), (act(1), 1, False), (act(2), 2, False), (act(3), 3, False),
                          (act(4), 4, False), (act(5), 4, True)])

    def test_classical_and_quantum_call_of_one_function(self):
        # steps(27) = 111 trips on the classical call: never cut; steps(x) on the quantum call is.
        r = self.run1("both_q", i32(16), HALF, i32(27))
        self.assertEqual(r.outcome, "ret", r.reason)
        self.assertEqual(r.events[-1]["v"], hex(111 + 4))
        self.assertEqual([(l["n"], l["capped"]) for l in r.loops], [(4, False)])
        r = self.run1("both_q", i32(3), HALF, i32(27))
        self.assertTrue(r.outcome.startswith("cap:steps:%"), r.outcome)
        self.assertEqual([(l["n"], l["capped"]) for l in r.loops], [(4, True)])
        self.assertIn("steps", next(e["loop"] for e in r.events if e["ev"] == "trip"))  # the classical one ran

    def test_quantum_depth_recursion(self):
        # the recursion's activation is named by the call path to it (a hash, cqo_rt.c next_act): the same on every
        # sample that reaches it, whatever n is
        act = self.run1("rec_q", i32(1), HALF, i32(10)).loops[0]["act"]
        for n in (-3, 0, 1, 4):
            r = self.run1("rec_q", i32(n), HALF, i32(10))
            self.assertEqual(r.outcome, "ret", r.reason)
            self.assertEqual(r.loops, [{"loop": "chain:recursion", "act": act, "n": max(n, 0), "capped": False}])
        self.assertEqual(self.run1("rec_q", i32(4), HALF, i32(10)).events[-1]["v"],
                         hex(10 - (11 - (12 - (13 - 14)))))
        for n in (5, 1000):
            r = self.run1("rec_q", i32(n), HALF, i32(10))
            self.assertEqual(r.outcome, "cap:chain:recursion", r.reason)
            self.assertEqual(r.loops, [{"loop": "chain:recursion", "act": act, "n": 4, "capped": True,
                                        "cut": 1, "mcut": 0}])
        for n, capped in [(0, False), (3, False), (4, False), (6, True)]:
            r = self.run1("selfrec_q", i32(n), HALF, i32(1))
            self.assertEqual([(l["loop"], l["n"], l["capped"]) for l in r.loops],
                             [("selfrec_q:recursion", 4 if capped else n, capped)], (n, r.outcome, r.reason))
            self.assertEqual(r.outcome, "cap:selfrec_q:recursion" if capped else "ret")

    def test_k_resolution(self):
        # CQ_K(kq2, 2) beats the global flag and the default; a per-function flag beats CQ_K.
        caps = lambda r: [(l["n"], l["capped"]) for l in r.loops]
        self.assertEqual(caps(self.run1("kq2", i32(4), HALF)), [(2, False)])
        self.assertEqual(caps(self.run1("kq2", i32(8), HALF)), [(2, True)])
        self.assertEqual(caps(self.run1("kq2", i32(8), HALF, k_default=6)), [(2, True)])
        self.assertEqual(caps(self.run1("kq2", i32(8), HALF, k={"kq2": 3})), [(3, False)])
        self.assertEqual(caps(self.run1("kq2", i32(16), HALF, k={"kq2": 3})), [(3, True)])
        self.assertEqual(caps(self.run1("halve_q", i32(64), HALF, HALF, k_default=6)), [(6, False)])
        self.assertEqual(caps(self.run1("halve_q", i32(128), HALF, HALF, k_default=6)), [(6, True)])
        self.assertEqual(caps(self.run1("halve_q", i32(128), HALF, HALF, k={"kq2": 9}, k_default=6)), [(6, True)])


class HostOutput(unittest.TestCase):
    """cq-e4jk: the program's stdout per sample (unbuffered: kept up to an abort or a fatal raise, and
    not carried into the next sample) and its host-effect calls, in SampleRun.stdout/effects and side
    'c' outputs["stdout"]/["effects"], never in the events."""

    def test_stdout_and_effects(self):
        o1 = compile_c("hostout", r"""
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
int out_q(int x, int k) {
    printf("x=%d\n", x);
    if (x > k) remove("/nonexistent/cq_e4jk");
    if (x == 7) raise(SIGABRT);
    if (x == 8) abort();
    return x;
}
""")
        sp = spec("hostout", "int out_q(int,int)", [("out_q", ["int", "int"])])
        smp = [{"call": 0, "args": [i32(x), i32(3)]} for x in (1, 5, 7, 8, 2)]
        runs = oracle.run_samples(o1, sp, smp)
        self.assertEqual([r.stdout for r in runs], ["x=1\n", "x=5\n", "x=7\n", "x=8\n", "x=2\n"])
        # rulings Q8: remove is the stand-in: its pointer and the string it reads; raise is real
        rm = ("remove", "/nonexistent/cq_e4jk")
        short = lambda r: [(e["name"], e["args"][0]["cap"]) if e["name"] == "remove" else (e["name"], e["args"]) for e in r.effects]
        self.assertEqual([short(r) for r in runs],
                         [[], [rm], [rm, ("raise", [{"w": "i32", "v": "0x6"}])], [rm], []])
        self.assertEqual([r.outcome for r in runs], ["ret", "ret", "raise:6", "noreturn:abort", "ret"])
        for r in runs:
            self.assertFalse(any(e["ev"] in ("stdout", "effect") for e in r.events), r.events)
        rr = oracle.run_result(runs[1], sp, o1)
        self.assertEqual((rr.outputs["stdout"], rr.outputs["effects"][0]["args"][0]["cap"]), ("x=5\n", rm[1]))


class DiskCaps(unittest.TestCase):
    """cq-3fjt: a batch whose trace would pass $CQO_TRACE_MAX bytes is an OracleError (an internal
    error of the checker, never a sample outcome), not GBs on disk; a batch under it is unaffected."""

    def test_trace_cap(self):
        import os
        old = {k: os.environ.get(k) for k in ("CQO_TRACE_MAX", "CQE_CACHE")}
        with tempfile.TemporaryDirectory() as cache:
            os.environ["CQE_CACHE"] = cache
            os.environ["CQO_TRACE_MAX"] = "200000"
            try:
                o1 = compile_c("diskcap", r"""
int rot_q(int x0, double t, int n) { int x = x0; for (int i = 0; i < n; ++i) cq_theta(&x, t); return cq_measure(x); }
""")
                sp = spec("diskcap", "int rot_q(int,double,int)", [("rot_q", ["int", "double", "int"])])
                rs = oracle.run_samples(o1, sp, [{"call": 0, "args": [i32(1), HALF, i32(3)]}], tripcap=10 ** 7)
                self.assertEqual([(r.outcome, r.failed) for r in rs], [("ret", False)])
                self.assertEqual(sum(e.get("kind") == "theta" for e in rs[0].events), 3)
                with self.assertRaisesRegex(oracle.OracleError, "cq-3fjt"):
                    oracle.run_samples(o1, sp, [{"call": 0, "args": [i32(1), HALF, i32(10 ** 6)]}], tripcap=10 ** 7)
            finally:   # the runner of this program keeps the cap: no other test runs it
                for k, v in old.items():
                    if v is None:
                        os.environ.pop(k, None)
                    else:
                        os.environ[k] = v


class WideUIToF80(unittest.TestCase):
    """CR §2 (owner ruling cq-cqcj): uitofp from more than 128 bits to f80 is never negative (LLVM 19's
    ExpandLargeFpConvert sets the sign from the top bit; the oracle clears it)."""

    def test_top_bit(self):
        o1 = compile_c("wideu80", """
long double wide(unsigned x, unsigned y) {
    unsigned _BitInt(129) v = ((unsigned _BitInt(129))x << 128) | y;
    return (long double)v; }
""")
        sp = spec("wideu80", "long double wide(unsigned,unsigned)", [("wide", ["unsigned", "unsigned"])])
        got = rets(o1, sp, [{"call": 0, "args": [i32(1), i32(0)]}, {"call": 0, "args": [i32(1), i32(3)]},
                            {"call": 0, "args": [i32(0), i32(5)]}])
        self.assertEqual(got, [f80(2.0**128), f80(2.0**128), f80(5.0)])


class Collapse(unittest.TestCase):
    """CR rule 2, owner ruling cq-r6bc (bead cq-y1ll): a cq_measure counts as a gate only when its operand
    is not classical by the data-flow collapse (computed only from measured rails and classical values,
    before or after the measurement); otherwise the site logs kind "read" and nothing is measured."""

    def test_measure_counting(self):
        o1 = compile_c("collapse", """
#include <fenv.h>
int after(int x0, double t) { int x = x0; cq_theta(&x, t); int m = cq_measure(x); int y = x + 1; return m + cq_measure(y); }
int still_q(int x0, int z0, double t) {
    int x = x0, z = z0; cq_theta(&x, t); cq_theta(&z, t);
    int m = cq_measure(x); int y = x + z; return m + cq_measure(y); }
int before(int x0, double t, int c) { int x = x0; cq_theta(&x, t); int y = x * c + 3; int m = cq_measure(x); return m + cq_measure(y); }
int reread(int x0, double t) { int x = x0; cq_theta(&x, t); int a = cq_measure(x); return a + cq_measure(x); }
__attribute__((noinline)) static int rd(int v, int k) { int m = cq_measure(v); return m > k ? m : k; }
int in_callee(int x0, double t, int k, int c) { int x = x0; cq_theta(&x, t); int y = x + c; int m = rd(x, k); return m + cq_measure(y); }
int arm_q(int x0, int z0, double t, int k) {
    int x = x0, z = z0, m = 0; cq_theta(&x, t); cq_theta(&z, t);
    if (x > k) m = z;
    int mx = cq_measure(x); return mx + cq_measure(m); }
int arm_c(int x0, double t, int k, int c) {
    int x = x0, m = c; cq_theta(&x, t);
    if (x > k) m = c + 5;
    int mx = cq_measure(x); return mx + cq_measure(m); }
int rotated(int x0, double t, double u) { int x = x0; cq_theta(&x, t); int m = cq_measure(x); cq_theta(&x, u); return m + cq_measure(x); }
int stored(int x0, int z0, double t, int i) {
    int x = x0, z = z0, a[2]; cq_theta(&x, t); cq_theta(&z, t);
    a[0] = x + 1; a[1] = z; int m = cq_measure(x); return m + cq_measure(a[i & 1]); }
double fenv_tested(double x0, double th, double c, double k) {
    double x = x0; cq_theta(&x, th);
    fesetround(FE_UPWARD); feclearexcept(FE_INEXACT);
    double y = x * c;
    if (y > k) feraiseexcept(FE_INEXACT);
    int f = fetestexcept(FE_INEXACT);
    return cq_measure(y) + (double)cq_measure(f); }
""")
        sp = spec("collapse", "int after(int,double);int still_q(int,int,double);int before(int,double,int);"
                  "int reread(int,double);int in_callee(int,double,int,int);int arm_q(int,int,double,int);"
                  "int arm_c(int,double,int,int);int rotated(int,double,double);int stored(int,int,double,int);"
                  "double fenv_tested(double,double,double,double)",
                  [("after", ["int", "double"]), ("still_q", ["int", "int", "double"]),
                   ("before", ["int", "double", "int"]), ("reread", ["int", "double"]),
                   ("in_callee", ["int", "double", "int", "int"]), ("arm_q", ["int", "int", "double", "int"]),
                   ("arm_c", ["int", "double", "int", "int"]), ("rotated", ["int", "double", "double"]),
                   ("stored", ["int", "int", "double", "int"]),
                   ("fenv_tested", ["double", "double", "double", "double"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        cases = [  # (sample, gates, classical reads)
            (S(0, i32(5), HALF), 1, 1),
            (S(1, i32(5), i32(7), HALF), 2, 0),
            (S(2, i32(5), HALF, i32(3)), 1, 1),
            (S(3, i32(5), HALF), 1, 1),
            (S(4, i32(5), HALF, i32(2), i32(9)), 1, 1),
            (S(5, i32(5), i32(7), HALF, i32(2)), 2, 0),     # m = x > k ? z : 0, z never measured
            (S(5, i32(1), i32(7), HALF, i32(2)), 2, 0),     # the arm not run: still z's merge
            (S(6, i32(5), HALF, i32(2), i32(9)), 1, 1),     # m = x > k ? c + 5 : c: classical with x
            (S(6, i32(1), HALF, i32(2), i32(9)), 1, 1),
            (S(7, i32(5), HALF, HALF), 2, 0),               # rotated again: a new rail
            (S(8, i32(5), i32(7), HALF, i32(0)), 1, 1),     # a[0] = x + 1
            (S(8, i32(5), i32(7), HALF, i32(1)), 2, 0),     # a[1] = z
            (S(9, f64(1.5), HALF, f64(3.0), f64(4.0)), 1, 1),   # 65: f collapses with y
            (S(9, f64(0.5), HALF, f64(3.0), f64(4.0)), 1, 1),
        ]
        for smp, gates, reads in cases:
            rr = oracle.run_sample(o1, sp, smp)
            self.assertEqual(rr.violations, [], smp)
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, reads), (smp, ev))
            self.assertEqual(len(rr.measured), gates, smp)
            self.assertFalse(any(r.get("kind") == "read" for r in rr.rotations), smp)

    def test_static_collapse(self):
        """CR rule 2, 406-408 (cq-ndtt, cq-g72r): collapse is static. A value measured on some classical paths only stays a
        rail after the join, also on the samples that measured it (a later cq_measure of what is computed from it is a
        measurement); measured on every path, it collapses. Measuring a classical merge measures the merge, not the
        incoming it chose (kq: t * 7 is a measurement on both paths)."""
        o1 = compile_c("static_collapse", """
int pm_join(int a, double t, int c) { int x = a; cq_theta(&x, t); int y = x + 7, r = 0;
    if (c) r = cq_measure(y); return r + cq_measure(y * 3); }
int both(int a, double t, int c) { int x = a; cq_theta(&x, t); int y = x + 7, r;
    if (c) r = cq_measure(y); else r = 2 * cq_measure(y); return r + cq_measure(y * 3); }
int kq(int a, double th, int c) { int x = a; cq_theta(&x, th); int t = x & 6, y;
    if (c) y = t; else y = x | 1; int r = cq_measure(y); return r + cq_measure(t * 7); }
int pm_ret(int a, double t, int c) { int x = a; cq_theta(&x, t); int y = 3 * x + 1;
    if (c) return cq_measure(y); int z = y ^ 5; return cq_measure(x) + cq_measure(z & 1); }
""")
        sp = spec("static_collapse", "int pm_join(int,double,int);int both(int,double,int);int kq(int,double,int);"
                  "int pm_ret(int,double,int)",
                  [("pm_join", ["int", "double", "int"]), ("both", ["int", "double", "int"]),
                   ("kq", ["int", "double", "int"]), ("pm_ret", ["int", "double", "int"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        for smp, gates, reads in [(S(0, i32(5), HALF, i32(1)), 2, 0), (S(0, i32(5), HALF, i32(0)), 1, 0),
                                  (S(1, i32(5), HALF, i32(1)), 1, 1), (S(1, i32(5), HALF, i32(0)), 1, 1),
                                  (S(2, i32(5), HALF, i32(1)), 2, 0), (S(2, i32(5), HALF, i32(0)), 2, 0),
                                  # measured on one path only: a reader after it on that path still collapses
                                  (S(3, i32(5), HALF, i32(0)), 1, 1), (S(3, i32(5), HALF, i32(1)), 1, 0)]:
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, reads), (smp, ev))

    def test_vector_lane(self):
        """cq-d1cd (CR rule 2: cq_measure of a value that never was a rail is that value): a vector is lowered lane by lane;
        a lane computed from classical lanes alone is no rail, so its cq_measure is a read."""
        o1 = compile_c("vec_lane", """
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
typedef double v2 __attribute__((vector_size(16)));
double vec_op(double x0, double c, double th) { double x = x0; cq_theta(&x, th);
    v2 a = {x, c}; v2 b = {c, 3.0}; v2 r = a / b; return cq_measure(r[0]) + cq_measure(r[1]); }
double vec_q(double x0, double c, double th) { double x = x0; cq_theta(&x, th);
    v2 a = {x, c}; v2 b = {c, x}; v2 r = a / b; return cq_measure(r[0]) + cq_measure(r[1]); }
""")
        sp = spec("vec_lane", "double vec_op(double,double,double);double vec_q(double,double,double)",
                  [("vec_op", ["double", "double", "double"]), ("vec_q", ["double", "double", "double"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        for smp, gates, reads in [(S(0, f64(1.5), f64(2.0), HALF), 1, 1), (S(1, f64(1.5), f64(2.0), HALF), 2, 0)]:
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, reads), (smp, ev))

    def test_measure_in_a_loop_body(self):
        """Owner, cq-2z29a, cq-47f8h: a loop-carried value with a rail incoming is a rail. What is computed from the measured rail alone is a read on the
        later trips; a quantum condition no measurement fixes keeps it a rail, and each trip's cq_measure a measurement."""
        o1 = compile_c("loopbody", """
int body(unsigned x0, double t) { unsigned v = x0; cq_theta(&v, t); int n = 0; while (v & 1) { n += cq_measure(v); v >>= 1; } return n; }
int qexit(unsigned x0, unsigned y0, double t) { unsigned x = x0, y = y0; cq_theta(&x, t); cq_theta(&y, t); int n = 0;
    while ((x & 1) && !(y & 1)) { n += cq_measure(x); x >>= 1; } return n; }
""")
        sp = spec("loopbody", "int body(unsigned,double);int qexit(unsigned,unsigned,double)",
                  [("body", ["unsigned", "double"]), ("qexit", ["unsigned", "unsigned", "double"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        for smp, gates, reads in [(S(0, i32(1), HALF), 1, 0), (S(0, i32(3), HALF), 1, 1), (S(0, i32(7), HALF), 1, 2),
                                  (S(1, i32(1), i32(0), HALF), 1, 0), (S(1, i32(3), i32(0), HALF), 2, 0),
                                  (S(1, i32(7), i32(0), HALF), 3, 0)]:
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, reads), (smp, ev))


class ExitRead(unittest.TestCase):
    """Bead cq-4asj (CR rule 14 f981c89, taint's exitRead, cq-rmaf): a value of a loop whose exit is
    quantum read after the loop is the exit value, a rail selected by every trip's exit test, even
    where the value is classical in the loop (an affine induction): its cq_measure is a measurement,
    also once the last trip's x is measured (150); a second cq_measure of it is a read; returned from
    a tail-recursive count (09) likewise. After a loop with a classical exit it stays a read."""

    def test_exit_reads(self):
        o1 = compile_c("exit_read", """
int dowhile(int x0, double t, int a, int b, int c) {
    int x = x0, n = 0; cq_theta(&x, t);
    do { x = x * a + b; n++; } while (x > c);
    int mx = cq_measure(x); return mx + cq_measure(n); }
int twice(int x0, double t, int a, int b, int c) {
    int x = x0, n = 0; cq_theta(&x, t);
    do { x = x * a + b; n++; } while (x > c);
    int m = cq_measure(n); return m + cq_measure(n); }
static unsigned count(unsigned x, int n, unsigned k, unsigned a, unsigned b) {
    if (x > k) return count(x * a + b, n + 1, k, a, b); return n; }
int tail(int x0, double t, unsigned k, unsigned a, unsigned b) {
    unsigned x = x0; cq_theta(&x, t); return cq_measure(count(x, 0, k, a, b)); }
int bounded(int x0, double t, int m) {
    int x = x0, n = 0; cq_theta(&x, t);
    for (int i = 0; i < m; i++) { x += i; n += 2; }
    int mx = cq_measure(x); return mx + cq_measure(n); }
""")
        sp = spec("exit_read", "int dowhile(int,double,int,int,int);int twice(int,double,int,int,int);"
                  "int tail(int,double,unsigned,unsigned,unsigned);int bounded(int,double,int)",
                  [("dowhile", ["int", "double", "int", "int", "int"]),
                   ("twice", ["int", "double", "int", "int", "int"]),
                   ("tail", ["int", "double", "unsigned", "unsigned", "unsigned"]),
                   ("bounded", ["int", "double", "int"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        cases = [  # (sample, gates, classical reads)
            (S(0, i32(1), HALF, i32(2), i32(1), i32(5)), 2, 0),   # 150's failing sample: 2 trips
            (S(0, i32(0), HALF, i32(2), i32(1), i32(5)), 2, 0),   # 1 trip
            (S(1, i32(1), HALF, i32(2), i32(1), i32(5)), 1, 1),
            (S(2, i32(3), HALF, i32(0), i32(0), i32(0)), 1, 0),   # count's result: 1 trip
            (S(2, i32(0), HALF, i32(0), i32(0), i32(0)), 1, 0),   # no trip
            (S(3, i32(1), HALF, i32(3)), 1, 1),                   # classical exit: n is classical
        ]
        for smp, gates, reads in cases:
            rr = oracle.run_sample(o1, sp, smp)
            self.assertEqual(rr.violations, [], smp)
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, reads), (smp, ev))
            self.assertEqual(len(rr.measured), gates, smp)


class SameRail(unittest.TestCase):
    """Bead cq-425g (CR rule 2, ABI 1.3, owner ruling cq-r6bc): a second cq_measure of a value already
    measured is a classical read, also through a reload of the same cells (59, 120 at n = 1, rows = 1:
    q[0] and q[n - 1] are one rail) and through a lossless cast; a lossy cast measures only its own
    value. A slot taint holds as a rail whose cells hold a constant is measured (114 at n = 1), and a
    variadic actual read through the save areas is the actual (95, 109: never a false classical)."""

    def test_same_rail(self):
        o1 = compile_c("same_rail", """
#include <stdarg.h>
#include <stdbool.h>
int reload(const double *th, int n, double c) {
    bool q[n]; for (int i = 0; i < n; i++) q[i] = 0;
    for (int i = 0; i < n; i++) cq_theta(&q[i], th[i]);
    for (int i = 0; i + 1 < n; i++) if (q[i]) cq_theta(&q[i + 1], c);
    return cq_measure(q[0]) + cq_measure(q[n - 1]); }
int grid(const double *th, int rows, double c) {
    bool q[2][2] = {{0, 0}, {0, 0}};
    for (int i = 0; i < rows; i++) for (int j = 0; j < 2; j++) cq_theta(&q[i][j], th[2 * i + j]);
    for (int i = 0; i < rows; i++) if (q[i][0]) cq_theta(&q[i][1], c);
    if (q[0][1]) cq_theta(&q[rows - 1][1], c);
    return cq_measure(q[0][1]) + cq_measure(q[rows - 1][1]); }
int const_slot(int n, int k) {
    bool q[n]; for (int i = 0; i < n; i++) q[i] = (i >= n - k);
    for (int m = n; m >= 2; m--) if (q[m - 1]) cq_theta(&q[m - 2], 0.5);
    return cq_measure(q[0]); }
int lossy(int x0, double t) { int x = x0; cq_theta(&x, t); signed char c = (signed char)x; return cq_measure(c) + cq_measure(x); }
int widened(int x0, double t) { int x = x0; cq_theta(&x, t); long w = x; return (int)cq_measure(w) + cq_measure(x); }
__attribute__((noinline)) static int sum3(int n, ...) { va_list ap; va_start(ap, n); int s = 0;
    for (int i = 0; i < 3; i++) s += va_arg(ap, int); va_end(ap); return s + n; }
int va(int x0, double t, int a, int b) { int x = x0; cq_theta(&x, t); return cq_measure(sum3(1, a, x, b)); }
int r_live(int x0, double th, int n) {
    int x = x0; cq_theta(&x, th); int t = x + 1; cq_theta(&t, th); int s = t;
    for (int i = 0; i < n; i++) { s += x; cq_theta(&s, th); }
    return cq_measure(s) + cq_measure(t); }
int fs3(int q0, double th, unsigned i, unsigned j, unsigned k) {
    int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0}; int x = q0; cq_theta(&x, th);
    a[i & 3] = x; b[j & 3] = a[i & 3]; a[i & 3] = 0;
    int z = b[k & 3]; cq_theta(&z, th); b[k & 3] = z;
    return cq_measure(b[j & 3]) + cq_measure(x) * 5; }
int fs3b(int q0, double th, unsigned i, unsigned j, unsigned k) {
    int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0}; int x = q0; cq_theta(&x, th);
    a[i & 3] = x; b[j & 3] = a[i & 3]; a[i & 3] = 0;
    int z = b[k & 3]; cq_theta(&z, th); b[k & 3] = z;
    int mx = cq_measure(x); return mx * 5 + cq_measure(b[j & 3]); }
""")
        sp = spec("same_rail", "int reload(const double*,int,double);int grid(const double*,int,double);"
                  "int const_slot(int,int);int lossy(int,double);int widened(int,double);int va(int,double,int,int);"
                  "int r_live(int,double,int);int fs3(int,double,unsigned,unsigned,unsigned);"
                  "int fs3b(int,double,unsigned,unsigned,unsigned)",
                  [("reload", ["const double*", "int", "double"]), ("grid", ["const double*", "int", "double"]),
                   ("const_slot", ["int", "int"]), ("lossy", ["int", "double"]), ("widened", ["int", "double"]),
                   ("va", ["int", "double", "int", "int"]), ("r_live", ["int", "double", "int"]),
                   ("fs3", ["int", "double", "unsigned", "unsigned", "unsigned"]),
                   ("fs3b", ["int", "double", "unsigned", "unsigned", "unsigned"])],
                  setup="static double coef[4] = {0.3, 1.1, 0.7, 2.0};")
        S = lambda c, *a: {"call": c, "args": list(a)}
        cases = [  # (sample, gates, classical reads)
            (S(0, "coef", i32(1), HALF), 1, 1),     # q[0] is q[n - 1]
            (S(0, "coef", i32(2), HALF), 2, 0),
            (S(1, "coef", i32(1), HALF), 1, 1),     # q[0][1] is q[rows - 1][1], after quantum branches
            (S(1, "coef", i32(2), HALF), 2, 0),
            (S(2, i32(1), i32(0)), 1, 0),           # a slot rail holding a constant is measured
            (S(3, i32(5), HALF), 2, 0),             # (signed char)x leaves x's high bits unmeasured
            (S(4, i32(5), HALF), 1, 1),             # (long)x is x
            (S(5, i32(5), HALF, i32(2), i32(3)), 1, 0),   # sum3's result: the variadic x
            (S(6, i32(5), HALF, i32(0)), 1, 1),     # cq-q5sl: s is t at zero trips
            (S(6, i32(5), HALF, i32(1)), 2, 0),
            (S(7, i32(5), HALF, i32(0), i32(1), i32(2)), 1, 1),   # b[j] is x: either order (mem-n3 s3/s3b)
            (S(8, i32(5), HALF, i32(0), i32(1), i32(2)), 1, 1),
            (S(7, i32(5), HALF, i32(0), i32(1), i32(1)), 2, 0),   # b[j] rotated: another rail
            (S(8, i32(5), HALF, i32(0), i32(1), i32(1)), 2, 0),
        ]
        for smp, gates, reads in cases:
            rr = oracle.run_sample(o1, sp, smp)
            self.assertEqual(rr.violations, [], smp)
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, reads), (smp, ev))
            self.assertEqual(len(rr.measured), gates, smp)


class CollapseMerges(unittest.TestCase):
    """Review y1ll-n1 of the rule 2 collapse (bead cq-y1ll): (1) a merge the circuit holds as a rail,
    decided by a classical condition, is never classical because the incoming the sample ran is a
    constant (trip 0 of a loop, 25); (2) a constrained-FP result depends on the rounding mode and flags
    (80); (3) a library call writing through a pointer writes what may be the fp state (100: the flags
    come back through fesetexceptflag; taint holds the fexcept_t object as saved fp state, so a plain
    load of it is classical)."""

    def test_merges_and_fenv(self):
        o1 = compile_c("collapse_merges", """
#include <fenv.h>
int loop_acc(int x0, double t, int n, int c) {
    int x = x0; cq_theta(&x, t); int acc = 0;
    for (int i = 0; i < n; i++) acc = acc * c + x;
    return cq_measure(acc); }
int sel_const(int x0, double t, int b) { int x = x0; cq_theta(&x, t); int m = b ? x + 1 : 0; return cq_measure(m); }
#pragma STDC FENV_ACCESS ON
double qmode(double x0, double th, double k, double a, double b) {
    double x = x0; cq_theta(&x, th);
    fesetround(x > k ? FE_UPWARD : FE_DOWNWARD);
    double s = a + b;
    fesetround(FE_TONEAREST);
    return cq_measure(s); }
int saved_flags(double x0, double th, double c) {
    double x = x0; cq_theta(&x, th);
    double y = x / c;
    fexcept_t saved;
    fegetexceptflag(&saved, FE_INEXACT);
    double z = y * c;
    fesetexceptflag(&saved, FE_INEXACT);
    int m = (int)cq_measure(z);
    return m + cq_measure(fetestexcept(FE_ALL_EXCEPT)); }
#pragma STDC FENV_ACCESS OFF
int retry(int x0, double th, int k, int c, int m) {
    int x = x0; cq_theta(&x, th); int y;
recompute:
    if (x > k) { x -= k; goto recompute; }
    y = x * c;
    if (y > m) { x = x >> 1; goto recompute; }
    return cq_measure(y); }
""")
        sp = spec("collapse_merges", "int loop_acc(int,double,int,int);int sel_const(int,double,int);"
                  "double qmode(double,double,double,double,double);int saved_flags(double,double,double);"
                  "int retry(int,double,int,int,int)",
                  [("loop_acc", ["int", "double", "int", "int"]), ("sel_const", ["int", "double", "int"]),
                   ("qmode", ["double", "double", "double", "double", "double"]),
                   ("saved_flags", ["double", "double", "double"]),
                   ("retry", ["int", "double", "int", "int", "int"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        cases = [  # (sample, gates)
            (S(0, i32(5), HALF, i32(0), i32(3)), 1),    # trip 0: acc = 0 still a rail
            (S(0, i32(5), HALF, i32(3), i32(3)), 1),
            (S(1, i32(5), HALF, i32(0)), 1),            # the constant arm of a classical choice
            (S(1, i32(5), HALF, i32(1)), 1),
            (S(2, f64(1.5), HALF, f64(1.0), f64(0.1), f64(0.2)), 1),   # classical operands, quantum mode
            (S(3, f64(1.5), HALF, f64(3.0)), 2),        # the flags y's division raised, through saved
        ]
        for smp, gates in cases:
            rr = oracle.run_sample(o1, sp, smp)
            self.assertEqual(rr.violations, [], smp)
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), (gates, 0), (smp, ev))
            self.assertEqual(len(rr.measured), gates, smp)
        # 54's header test region (x > k, then x * c > m) holds the shadows' calls: still one test, so
        # x0 = 0, 5 begin 0, 1 trips (as before the shadows)
        for x0, n in ((0, 0), (5, 1)):
            rr = oracle.run_sample(o1, sp, S(4, i32(x0), HALF, i32(3), i32(2), i32(9)))
            self.assertEqual([l["n"] for l in rr.outputs["loops"]], [n], x0)


class CollapseRepin(unittest.TestCase):
    """Bead cq-vo6v (CR rule 2 at CQ_spec 75588cd). (1) 94: the cell an atomic writes and the atomic's
    result are distinct values: measuring a later load of the cell leaves a cmpxchg's {loaded, equal}
    quantum; an atomicrmw's result is the old cell itself (a second measurement of it is a read).
    (2) 102: a signal handler that loads nothing and calls nothing writes a function of the signal
    number, so a cell it may write under a quantum branch depends on the branch condition only and
    collapses with its sources' measurement; a handler that loads keeps the cell opaque (measured)."""

    def counts(self, o1, sp, cases):
        for smp, want in cases:
            rr = oracle.run_sample(o1, sp, smp)
            self.assertEqual(rr.violations, [], smp)
            ev = oracle.trace_sample(o1, sp, smp)
            got = [e["kind"] for e in ev if e["ev"] == "site" and e["kind"] in ("measure", "read")]
            self.assertEqual((got.count("measure"), got.count("read")), want, (smp, ev))
            self.assertEqual(len(rr.measured), want[0], smp)

    def test_atomics(self):
        o1 = compile_c("collapse_atomics", """
int atom(int x0, double t, int c, int e) {
    int x = x0; cq_theta(&x, t); int cell = c;
    __atomic_store_n(&cell, x, __ATOMIC_SEQ_CST);
    int old = __atomic_fetch_add(&cell, c, __ATOMIC_SEQ_CST);
    int expected = e;
    int ok = __atomic_compare_exchange_n(&cell, &expected, old, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    int now = __atomic_load_n(&cell, __ATOMIC_SEQ_CST);
    return cq_measure(now) + cq_measure(ok) + cq_measure(expected); }
int rmw_old(int x0, double t, int c) {
    int x = x0; cq_theta(&x, t); int cell = 0;
    __atomic_store_n(&cell, x, __ATOMIC_SEQ_CST);
    int old = __atomic_fetch_add(&cell, c, __ATOMIC_SEQ_CST);
    return cq_measure(x) + cq_measure(old); }
""")
        sp = spec("collapse_atomics", "int atom(int,double,int,int);int rmw_old(int,double,int);",
                  [("atom", ["int", "double", "int", "int"]), ("rmw_old", ["int", "double", "int"])])
        S = lambda c, *a: {"call": c, "args": list(a)}
        self.counts(o1, sp, [(S(0, i32(5), HALF, i32(3), i32(8)), (3, 0)),
                             (S(0, i32(5), HALF, i32(3), i32(1)), (3, 0)),
                             (S(1, i32(5), HALF, i32(3)), (1, 1))])

    def test_signal_handler(self):
        src = """
#include <signal.h>
static volatile sig_atomic_t hit;
static void h(int s) { hit = HANDLER; }
int handled(int x0, double t, int k) {
    int x = x0; cq_theta(&x, t); signal(SIGUSR1, h);
    if (x > k) raise(SIGUSR1);
    return cq_measure(x) + cq_measure(hit); }
"""
        S = lambda c, *a: {"call": c, "args": list(a)}
        for name, body, want in (("handler_args", "s", (1, 1)), ("handler_loads", "hit + s", (2, 0))):
            o1 = compile_c(name, src.replace("HANDLER", body))
            sp = spec(name, "int handled(int,double,int);", [("handled", ["int", "double", "int"])])
            self.counts(o1, sp, [(S(0, i32(5), HALF, i32(3)), want), (S(0, i32(1), HALF, i32(3)), want)])


class RunnerLeases(unittest.TestCase):
    """cq-5f7p: a runner another thread holds is never closed by the LRU eviction, so two evaluations
    in flight at once (threads of one process, MAX_RUNNERS small) never lose their runner directory
    (114 and 118 errored 'FileNotFoundError: .../cqo-run.*/samples' under load)."""

    SRC = "int f_q(int x0, double t) { int x = x0; cq_theta(&x, t); return x + %d; }\n"

    def setUp(self):
        oracle.close_runners()
        self.max = oracle.MAX_RUNNERS
        oracle.MAX_RUNNERS = 1   # every lease of a second executable evicts the first, if idle

    def tearDown(self):
        oracle.MAX_RUNNERS = self.max
        oracle.close_runners()

    def prog(self, n: int):
        name = f"lease{n}"
        o1 = compile_c(name, self.SRC % n)
        sp = spec(name, "int f_q(int,double)", [("f_q", ["int", "double"])])
        samples = [{"call": 0, "args": [i32(v), HALF]} for v in range(20)]
        exe = oracle.executable(o1, sp, oracle._pointer_samples(sp, samples))
        return exe, sp, samples, oracle.isolated(oracle.program(o1)[0])

    def batch(self, exe, sp, samples, iso):
        return [next(e["v"] for e in r.events if e["ev"] == "ret")
                for r in oracle._run_batch(exe, sp, samples, oracle.DEFAULT_TIMEOUT_MS, oracle.DEFAULT_TRIPCAP, iso)]

    def test_eviction_spares_a_leased_runner(self):
        (e1, s1, x1, i1), (e2, s2, x2, i2) = self.prog(1), self.prog(2)
        with oracle._lease(e1, 0) as r1:
            with oracle._lease(e2, 0) as r2:   # before cq-5f7p this closed r1 and removed its directory
                self.assertTrue(r1.dir.is_dir())
                r2.run(s2, x2, oracle.DEFAULT_TIMEOUT_MS, oracle.DEFAULT_TRIPCAP, i2)
            runs = r1.run(s1, x1, oracle.DEFAULT_TIMEOUT_MS, oracle.DEFAULT_TRIPCAP, i1)
            self.assertEqual(len(runs), len(x1))
        with oracle._lease(e2, 0):             # now r1 is idle: it is evicted and closed
            pass
        self.assertFalse(r1.dir.exists())

    def test_two_evaluations_concurrently(self):
        import threading
        progs = [self.prog(3), self.prog(4)]
        want = [[i32(v + 3) for v in range(20)], [i32(v + 4) for v in range(20)]]
        start = threading.Barrier(2)
        errors, got = [], [[], []]

        def one(j):
            try:
                start.wait()
                for _ in range(40):
                    got[j].append(self.batch(*progs[j]))
            except Exception as e:  # noqa: BLE001  (reported below, with its thread)
                errors.append(f"{j}: {type(e).__name__}: {e}")

        ts = [threading.Thread(target=one, args=(j,)) for j in (0, 1)]
        for t in ts:
            t.start()
        for t in ts:
            t.join()
        self.assertEqual(errors, [])
        for j in (0, 1):
            self.assertEqual(len(got[j]), 40)
            for g in got[j]:
                self.assertEqual([int(v, 16) for v in g], [int(v, 16) for v in want[j]])


class FlatMemory(unittest.TestCase):
    """CR §6, rulings Q8, Q16: named outputs, lifetime markers, direct host calls."""

    def test_named_output_in_memory(self):
        o1 = compile_c("gout", """
int dst = 7;
const int tab[2] = {1, 2};
int set_it(int x) { dst = x + tab[1]; return x; }
""")
        sp = spec("gout", "int set_it(int)", [("set_it", ["int"])])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [i32(9)]})
        self.assertEqual([(m["name"], m["w"], int(m["v"], 16)) for m in rr.outputs["mem"]], [("dst", "i32", 11)])
        self.assertTrue(any(o["name"] == "tab" and o["size"] == 8 for o in rr.outputs["objects"]), rr.outputs["objects"])
        self.assertTrue(any(o["name"] == "set_it" for o in rr.outputs["objects"]))

    def test_lifetime_start_keeps_the_trip_before(self):
        # rule 20's one block: a block-scoped object re-entered by a loop holds what the trip before left
        o1 = compile_c("lifetime", """
__attribute__((noinline)) void touch(int *p) { *p = *p + 1; }
int reenter(int n) {
    int r = 0;
    for (int i = 0; i < n; i++) { int a; touch(&a); r = a; }
    return r;
}
""")
        sp = spec("lifetime", "int reenter(int)", [("reenter", ["int"])])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [i32(2)]})
        self.assertEqual(rr.violations, [])
        self.assertEqual(rr.outputs["ret"][0]["v"], {"w": "i32", "v": "0x2"})

    def test_stand_ins_not_real_calls(self):
        # rulings Q8: nothing is printed, the result is fx_standin.h's, and an unknown callee logs too
        o1 = compile_c("stand", """
#include <stdio.h>
int ext_unknown(int);
int go(int x) { putchar(x); int r = ext_unknown(x); char b[8] = {0}; fgets(b, 8, stdin); return b[0] != 0 ? r : -1; }
""")
        sp = spec("stand", "int go(int)", [("go", ["int"])])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [i32(65)]})
        self.assertEqual(rr.violations, [])
        self.assertEqual(rr.outputs["stdout"], "")
        self.assertEqual([e["name"] for e in rr.outputs["effects"]], ["putchar", "ext_unknown", "fgets"])
        self.assertEqual(rr.outputs["effects"][0]["args"], [{"w": "i32", "v": "0x41"}])
        self.assertEqual(rr.outputs["effects"][2]["args"][0]["p"], 1)
        ret = rr.outputs["ret"][0]["v"]
        self.assertNotEqual(ret["v"], "0xffffffff")   # fgets stored the stand-in's line


if __name__ == "__main__":
    unittest.main(verbosity=2)
