#!/usr/bin/env python3
"""Write the Track-B re-measurement probes (bank + register twin) to probes/."""
import pathlib

D = pathlib.Path(__file__).parent / "probes"
D.mkdir(exist_ok=True)

MAIN_F = "int main(void) { return slice(1); }\n"
MAIN_R = "int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }\n"
SIG_F = "__attribute__((noinline)) int slice(int seed) {\n"
SIG_R = "__attribute__((noinline)) int slice(int n, int seed) {\n  if (n <= 1) return 0;\n"

P = {}

def fixed(name, body, reg=None):
    P[name + ".bank.c"] = SIG_F + body + "}\n" + MAIN_F
    if reg:
        P[name + ".reg.c"] = SIG_F + reg + "}\n" + MAIN_F

def rt(name, body, reg=None):
    P[name + ".bank.c"] = SIG_R + body + "}\n" + MAIN_R
    if reg:
        P[name + ".reg.c"] = SIG_R + reg + "}\n" + MAIN_R

STALE_REG = """  int q = cq_theta(seed, 0.5);
  int c = q;
  q = cq_theta(q, 0.7);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
"""
fixed("s01_fixed_parkloop_ry_measloop", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", STALE_REG)
rt("s02_rt_parkloop_ry_measloop", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q);
""")
fixed("s03_fixed_parkloop_ry_constidx", """  int q = cq_theta(seed, 0.5);
  int b[3];
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  return cq_measure(b[1]) + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  q = cq_theta(q, 0.7);
  return cq_measure(c) + cq_measure(q);
""")
rt("s04_rt_parkloop_ry_constidx", """  int q = cq_theta(seed, 0.5);
  int b[n];
  for (int i = 0; i < n; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  return cq_measure(b[1]) + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  q = cq_theta(q, 0.7);
  return cq_measure(c) + cq_measure(q);
""")
fixed("s05_fixed_straightpark_ry_measloop", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  b[0] = q; b[1] = q; b[2] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", STALE_REG)
rt("s06_rt_straightpark_ry_measloop", """  if (n != 3) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  b[0] = q; b[1] = q; b[2] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""")
LEGIT_REG = """  int q = cq_theta(seed, 0.5);
  int c = q;
  int s = cq_measure(c) + cq_measure(c) + cq_measure(c);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
"""
fixed("s07_fixed_legit", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
""", LEGIT_REG)
rt("s08_rt_legit", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
""")
fixed("s09_fixed_theta_arg0_stale", """  int q = cq_theta(seed, 0.5);
  int b[3];
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  int r = cq_theta(b[1], 0.3);
  return cq_measure(r) + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  q = cq_theta(q, 0.7);
  int r = cq_theta(c, 0.3);
  return cq_measure(r) + cq_measure(q);
""")
rt("s10_rt_theta_arg0_stale_loop", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(cq_theta(b[i], 0.3));
  return s + cq_measure(q);
""")
fixed("s11_fixed_dtzb_add", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = q + 3;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  q = q + 3;
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
""")
fixed("s12_fixed_dtzb_xor", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q ^= 5;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  q ^= 5;
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
""")
fixed("s13_fixed_dtzb_add_measure_first", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  int t = q + 3;
  s += cq_measure(t);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s;
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  int t = q + 3;
  int s = cq_measure(t);
  return s + cq_measure(c) + cq_measure(c) + cq_measure(c);
""")
fixed("s14_fixed_ry_inside_measloop", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  for (int i = 0; i < 3; ++i) { s += cq_measure(b[i]); q = cq_theta(q, 0.7); }
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  for (int i = 0; i < 3; ++i) { s += cq_measure(c); q = cq_theta(q, 0.7); }
  return s + cq_measure(q);
""")
fixed("s15_fixed_park_carried_phi", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) { b[i] = q; q = cq_theta(q, 0.7); }
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c0 = q; q = cq_theta(q, 0.7);
  int c1 = q; q = cq_theta(q, 0.7);
  int c2 = q; q = cq_theta(q, 0.7);
  return cq_measure(c0) + cq_measure(c1) + cq_measure(c2) + cq_measure(q);
""")
rt("s16_rt_park_carried_phi", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) { b[i] = q; q = cq_theta(q, 0.7); }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""")
fixed("s17_bool_stale", """  _Bool q = cq_theta((_Bool)seed, 0.5);
  _Bool b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  _Bool q = cq_theta((_Bool)seed, 0.5);
  _Bool c = q;
  q = cq_theta(q, 0.7);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
""")
rt("s18_rt_stale_before_park", """  int q = cq_theta(seed, 0.5);
  int c = q;
  q = cq_theta(q, 0.7);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = c;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""")
rt("s19_rt_sibling_register_rotated", """  int r = cq_theta(seed, 0.2);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
  r = cq_theta(r, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(r);
""")
rt("s20_rt_percell_theta", """  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + seed;
""")
fixed("s21_fixed_dtzb_loop_add", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  for (int k = 0; k < 3; ++k) q += seed;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  for (int k = 0; k < 3; ++k) q += seed;
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
""")
rt("s22_rt_dtzb_add", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  q = q + 3;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  q = q + 3;
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q);
""")
# the dtzb relabel that is REALLY in place: a loop-carried in-place add on the
# PARKED rail with a later bank read, the park inside the same loop as the add.
fixed("s23_fixed_park_then_inplace_add_same_loop", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) { b[i] = q; q += 1; }
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c0 = q; q += 1;
  int c1 = q; q += 1;
  int c2 = q; q += 1;
  return cq_measure(c0) + cq_measure(c1) + cq_measure(c2) + cq_measure(q);
""")
# measure BETWEEN two relabels: part legit, part stale.
fixed("s24_fixed_ry_between_two_measure_loops", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  s += cq_measure(b[0]);
  q = cq_theta(q, 0.7);
  s += cq_measure(b[2]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  s += cq_measure(c);
  q = cq_theta(q, 0.7);
  s += cq_measure(c);
  return s + cq_measure(q);
""")
# a Rz (diagonal, cq_phi) between park and read: must NOT be a stale read.
fixed("s25_fixed_phi_between", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  cq_phi(0.4);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q;
  cq_phi(0.4);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
""")

rt("s26_rt_dtzb_runtime_loop_xor", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int k = 0; k < n; ++k) q ^= k;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  for (int k = 0; k < n; ++k) q ^= k;
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q);
""")
rt("s27_rt_dtzb_runtime_loop_add_measfirst", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int k = 0; k < n; ++k) q += k;
  s += cq_measure(q);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s;
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  for (int k = 0; k < n; ++k) q += k;
  s += cq_measure(q);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s;
""")
rt("s28_rt_classical_cond_ry", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  if (n > 2) q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""", """  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  if (n > 2) q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q);
""")
rt("s29_rt_tainted_cond_ry", """  int q = cq_theta(seed, 0.5);
  _Bool r = cq_theta((_Bool)0, 0.3);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  if (r) q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q) + cq_measure(r);
""", """  int q = cq_theta(seed, 0.5);
  _Bool r = cq_theta((_Bool)0, 0.3);
  int c = q; int s = 0;
  if (r) q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q) + cq_measure(r);
""")
fixed("s30_fixed_two_banks_one_stale", """  int q = cq_theta(seed, 0.5);
  int b[3], d[3]; int s = 0;
  for (int i = 0; i < 3; ++i) d[i] = cq_theta(d[i], 0.2);
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]) + cq_measure(d[i]);
  return s + cq_measure(q);
""")
# the rotation is in a CALLEE (noinline) — the relabel is interprocedural.
P["s31_fixed_ry_in_callee.bank.c"] = """__attribute__((noinline)) int rot(int x) { return cq_theta(x, 0.7); }
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = rot(q);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
""" + MAIN_F
P["s31_fixed_ry_in_callee.reg.c"] = """__attribute__((noinline)) int rot(int x) { return cq_theta(x, 0.7); }
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;
  q = rot(q);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
}
""" + MAIN_F

COND_TAIL = """  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
"""
rt("c01_rt_condpark_invariant_uninit", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) if (i & 1) b[i] = q;
""" + COND_TAIL)
rt("c02_rt_condpark_invariant_zeroinit", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = 0;
  for (int i = 0; i < n; ++i) if (i & 1) b[i] = q;
""" + COND_TAIL)
fixed("c03_fixed_condpark_invariant_zeroinit", """  int q = cq_theta(seed, 0.5);
  int b[3] = {0}; int s = 0;
  for (int i = 0; i < 3; ++i) if (i & 1) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""")
rt("c04_rt_select_park_invariant_or_theta", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = (i & 1) ? q : cq_theta(b[i], 0.5);
""" + COND_TAIL)
rt("c05_rt_condprep_or_park", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) { if (i & 1) b[i] = q; else b[i] = cq_theta(b[i], 0.5); }
""" + COND_TAIL)
rt("c06_rt_passH_invariant", """  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) { int t = q; if (seed > i) b[i] = t; }
""" + COND_TAIL)
fixed("c07_fixed_select_park_invariant_or_theta", """  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = (i & 1) ? q : cq_theta(b[i], 0.5);
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
""")
# grover main-shaped: conditional prep on a classical cond, then a later
# relabel on an UNRELATED register (must stay accepted)
rt("c08_rt_condprep_classical_sibling_rotated", """  int r = cq_theta(seed, 0.2);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) if (seed > i) b[i] = cq_theta(b[i], 0.5);
  r = cq_theta(r, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(r);
""")
rt("c09_rt_select_park_two_invariants", """  int q = cq_theta(seed, 0.5);
  int p = cq_theta(seed, 0.25);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = (i & 1) ? q : p;
""" + COND_TAIL)

G_HEAD = """#include <stdlib.h>
int main(int argc, char **argv) {
  int n = 5;
  if (argc > 1) n = atoi(argv[1]);
  if (n <= 1) return 1;
  int z[n]; int Z = 0;
  for (int i = 0; i < n; i++) { z[i] = rand() % 100; Z += z[i]; }
  Z /= 2;
  int b[n]; int s = 0;
"""
# g01: the grover prep with the ARM THETA ALSO ESCAPING THE LOOP (last trip's
# rail), relabelled after the loop, then the bank measured.
P["g01_condprep_arm_escapes_relabelled.bank.c"] = G_HEAD + """  int t = 0;
  for (int i = 0; i < n; i++) { if (Z >= z[i]) { t = cq_theta(b[i], 0.5); b[i] = t; } }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s + cq_measure(t);
}
"""
P["g02_passH_arm_escapes_relabelled.bank.c"] = G_HEAD + """  int t = 0;
  for (int i = 0; i < n; i++) { t = cq_theta(b[i], 0.5); if (Z >= z[i]) b[i] = t; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s + cq_measure(t);
}
"""
P["g03_uncond_escapes_relabelled.bank.c"] = G_HEAD + """  int t = 0;
  for (int i = 0; i < n; i++) { t = cq_theta(b[i], 0.5); b[i] = t; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s + cq_measure(t);
}
"""
P["g04_condprep_cellread_escapes_relabelled.bank.c"] = G_HEAD + """  int t = 0;
  for (int i = 0; i < n; i++) { if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5); t = b[i]; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s + cq_measure(t);
}
"""
P["g05_condprep_legit.bank.c"] = G_HEAD + """  for (int i = 0; i < n; i++) { if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5); }
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s;
}
"""
# the arm theta escapes and is MEASURED (no relabel) -- a legit order control.
P["g06_passH_arm_escapes_measured_only.bank.c"] = G_HEAD + """  int t = 0;
  for (int i = 0; i < n; i++) { t = cq_theta(b[i], 0.5); if (Z >= z[i]) b[i] = t; }
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s + cq_measure(t);
}
"""

H_MAIN = "int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }\n"
H_SIG = "__attribute__((noinline)) static int slice(int n) {\n  if (n <= 0) return 0;\n  int b[n]; int Z = 4 * n; int s = 0;\n"
# h01: CASE 14 shape, the prep theta ALSO escapes the loop and is relabelled.
P["h01_passH_t_escapes_relabelled.bank.c"] = H_SIG + """  int t = 0;
  for (int i = 0; i < n; ++i) { t = cq_theta(b[i], 0.5); if (Z >= 2) b[i] = t; if (b[i]) Z -= 2; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(t) + cq_measure(Z);
}
""" + H_MAIN
P["h01_passH_t_escapes_relabelled.reg.c"] = """__attribute__((noinline)) static int slice(int n) {
  int Z = cq_theta(4 * n, 0.0); int s = 0;
  int t0 = cq_theta(0, 0.5); int b0 = 0; if (Z >= 2) b0 = t0; if (b0) Z -= 2;
  int t1 = cq_theta(0, 0.5); int b1 = 0; if (Z >= 2) b1 = t1; if (b1) Z -= 2;
  int t2 = cq_theta(0, 0.5); int b2 = 0; if (Z >= 2) b2 = t2; if (b2) Z -= 2;
  t2 = cq_theta(t2, 0.7);
  s += cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
  return s + cq_measure(t2) + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
"""
# h02: the seed-path prep (theta IN the arm) with the arm theta escaping.
P["h02_condprep_t_escapes_relabelled.bank.c"] = H_SIG + """  int t = 0;
  for (int i = 0; i < n; ++i) { if (Z >= 2) { t = cq_theta(b[i], 0.5); b[i] = t; } if (b[i]) Z -= 2; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(t) + cq_measure(Z);
}
""" + H_MAIN
# h03: CASE 14 + the cell read escapes (t = b[i] after the store), relabelled.
P["h03_passH_cell_escapes_relabelled.bank.c"] = H_SIG + """  int t = 0;
  for (int i = 0; i < n; ++i) { int u = cq_theta(b[i], 0.5); if (Z >= 2) b[i] = u; if (b[i]) Z -= 2; t = b[i]; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(t) + cq_measure(Z);
}
""" + H_MAIN
# h04: CASE 15 (seed-path prep, guarded) -- the control, must accept.
P["h04_condprep_control.bank.c"] = H_SIG + """  for (int i = 0; i < n; ++i) { if (Z >= 2) b[i] = cq_theta(b[i], 0.5); if (b[i]) Z -= 2; }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(Z);
}
""" + H_MAIN
# h05: CASE 14 control + a relabel on Z (a DIFFERENT wire) between the loops.
P["h05_passH_control.bank.c"] = H_SIG + """  for (int i = 0; i < n; ++i) { int t = cq_theta(b[i], 0.5); if (Z >= 2) b[i] = t; if (b[i]) Z -= 2; }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(Z);
}
""" + H_MAIN
# h06: seed-path prep, then the invariant-park stale shape on a second bank.
P["h06_condprep_plus_invariant_stale.bank.c"] = H_SIG + """  int q = cq_theta(n, 0.3); int d[n];
  for (int i = 0; i < n; ++i) { if (Z >= 2) b[i] = cq_theta(b[i], 0.5); if (b[i]) Z -= 2; }
  for (int i = 0; i < n; ++i) d[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]) + cq_measure(d[i]);
  return s + cq_measure(q) + cq_measure(Z);
}
""" + H_MAIN

fixed("s32_fixed_bool_percell", """  _Bool b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = cq_theta(b[i], 0.5);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + seed;
""")

for name, text in P.items():
    (D / name).write_text(text)
print(len(P), "files")
