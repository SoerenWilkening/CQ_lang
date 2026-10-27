#!/usr/bin/env python3
"""Unit tests of the C oracle (cq-w0-chk-oracle): small C programs, each exercising one CR §2/§6 row or
one event, compiled with clang -O1 like the corpus and run through oracle.run_samples / run_sample /
trace_sample. Needs chk-drivers' drivers.driver_source (see fixture.py)."""
from __future__ import annotations

import math
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
        for x, n in [(0, 0), (1, 0), (3, 1), (4, 2), (31, 4), (32, 5)]:
            ev = tr({"call": 0, "args": [i32(x), HALF, pa]})
            self.assertEqual(trips(ev), [n], (x, ev))
            self.assertEqual(ev[0], {"ev": "site", "fn": "loop_q", "site": 0, "kind": "theta",
                                     "angle": HALF, "reg": hex(x)})
            phis = [e for e in ev if e["ev"] == "site" and e["kind"] == "phi"]
            self.assertEqual(len(phis), 1 if n == 2 else 0)
            if phis:
                self.assertEqual(phis[0]["angle"], pa)
                self.assertIsNone(phis[0]["reg"])
            self.assertEqual(ev[-1], {"ev": "ret", "v": hex(n)})
        for x, n in [(0, 0), (1, 1), (7, 3), (0xFF, 8)]:
            self.assertEqual(trips(tr({"call": 1, "args": [i32(x), HALF]})), [n], x)
        ev = tr({"call": 2, "args": [i32(3), HALF]})
        self.assertEqual([e.get("kind", e["ev"]) for e in ev], ["invert_begin", "theta", "invert_end", "ret"])
        self.assertIsNone(ev[-1]["v"])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [i32(4), HALF, pa]})
        self.assertEqual(rr.side, "c")
        self.assertEqual(rr.sample, {"call": 0, "args": [i32(4), HALF, pa]})
        self.assertEqual([r["gate"] for r in rr.rotations], ["ry", "phase"])
        self.assertEqual(rr.measured, ["0x2"])
        self.assertEqual(rr.violations, [])

    def test_fp_output_typed_and_subst(self):
        o1 = compile_c("fpout", "double id_q(double x0, double t) { double x = x0; cq_theta(&x, t); return x + 1; }")
        sp = spec("fpout", "double id_q(double,double)", [("id_q", ["double", "double"])])
        rr = oracle.run_sample(o1, sp, {"call": 0, "args": [f64(1.0), HALF]})
        self.assertEqual(rr.outputs["ret"], {"w": "f64", "v": f64(2.0)})
        r = oracle.run_samples(o1, sp, [{"call": 0, "args": [f64(1.0), HALF], "subst": {"id_q:0": f64(5.0)}}])[0]
        self.assertEqual(r.events[0]["reg"], f64(5.0))
        self.assertEqual(r.events[-1]["v"], f64(6.0))


class Outcomes(unittest.TestCase):
    def test_terminations(self):
        o1 = compile_c("term", """
#include <stdlib.h>
#include <signal.h>
int abort_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); if (x == k) abort(); return cq_measure(x); }
int trap_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); if (x == k) __builtin_trap(); return x; }
int raise_q(int x0, double t, int k) { int x = x0; cq_theta(&x, t); if (x == k) raise(SIGABRT); return x; }
volatile int sink;
int spin_q(unsigned x0, double t) { unsigned x = x0; cq_theta(&x, t); while (x != 0) { x += 2; sink++; } return x; }
""")
        sp = spec("term", "int abort_q(int,double,int);int trap_q(int,double,int);int raise_q(int,double,int);"
                  "int spin_q(unsigned,double)",
                  [("abort_q", ["int", "double", "int"]), ("trap_q", ["int", "double", "int"]),
                   ("raise_q", ["int", "double", "int"]), ("spin_q", ["unsigned", "double"])])
        rs = oracle.run_samples(o1, sp, [
            {"call": 0, "args": [i32(2), HALF, i32(2)]}, {"call": 0, "args": [i32(1), HALF, i32(2)]},
            {"call": 1, "args": [i32(2), HALF, i32(2)]}, {"call": 2, "args": [i32(2), HALF, i32(2)]},
            {"call": 3, "args": [i32(1), HALF]}, {"call": 3, "args": [i32(2**32 - 4), HALF]}],
            timeout_ms=5000, tripcap=100000)
        self.assertEqual([(r.outcome, r.failed) for r in rs],
                         [("noreturn:abort", False), ("ret", False), ("noreturn:llvm.trap", False),
                          ("raise:6", False), ("", True), ("ret", False)])
        self.assertIn("nonterminating", rs[4].reason)
        with self.assertRaises(oracle.OracleError):
            oracle.trace_sample(o1, sp, {"call": 3, "args": [i32(1), HALF]})
        rr = oracle.run_sample(o1, sp, {"call": 3, "args": [i32(1), HALF]})
        self.assertTrue(rr.violations)


if __name__ == "__main__":
    unittest.main(verbosity=2)
