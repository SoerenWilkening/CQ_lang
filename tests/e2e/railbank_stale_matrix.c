/* railbank_stale_matrix.c — bd xdu2.1 (Track B, session 2026-09-24-railbank-parallel).
 *
 * C-level clang -O1 matrix for the stale-reader fence's MEMORY HOP
 * (`railBankParkedRails`, OpcodeLowering.cpp): a rail parked in a rail-bank cell
 * must be adjudicated exactly as its register spelling is.  Negative rows are
 * programs whose register spelling has no valid circuit (a parked name read
 * after a non-diagonal relabel) — every one must DECLINE; the diagnostic pinned
 * is the wall that fires TODAY, which for several rows is an earlier fence than
 * the reader fence (the row's comment says so).  Positive rows are the
 * capability and legitimate-order controls that a fix of this class must not
 * break; four are LINKED and byte-compared against their array-free twins.
 *
 * Expectations: railbank_stale_matrix.c.cases.json (schema at the top of
 * run_railbank_dynamic_matrix.py).  Probe provenance and re-measurement:
 * docs/prd/phase-04-swap-route-control/inc1-records/
 *   session-2026-09-24-railbank-parallel/TRACK_B.md.
 */
#include "CQ.h"
#include <stdlib.h>

#define CASE_FIXED_STALE_INVARIANT_PARK 1
#define CASE_RUNTIME_STALE_INVARIANT_PARK 2
#define CASE_FIXED_STALE_CONSTIDX_READ 3
#define CASE_RUNTIME_STALE_CONSTIDX_READ 4
#define CASE_FIXED_STALE_THETA_ARG0 5
#define CASE_RUNTIME_STALE_THETA_ARG0_LOOP 6
#define CASE_FIXED_RY_INSIDE_MEASURE_LOOP 7
#define CASE_RUNTIME_PARK_CARRIED_PHI 8
#define CASE_BOOL_STALE_INVARIANT_PARK 9
#define CASE_RUNTIME_STALE_BEFORE_PARK 10
#define CASE_RUNTIME_DTZB_LOOP_XOR 11
#define CASE_FIXED_SECOND_BANK_INVARIANT 12
#define CASE_RUNTIME_CONDPREP_BESIDE_STALE 13
#define CASE_RUNTIME_PASSH_THETA_ESCAPES 14
#define CASE_RUNTIME_CONDPREP_THETA_ESCAPES 15
#define CASE_RUNTIME_UNCOND_THETA_ESCAPES 16
#define CASE_FIXED_STRAIGHT_LINE_PARK 17
#define CASE_FIXED_LEGIT_ORDER 20
#define CASE_FIXED_LEGIT_ORDER_TWIN 21
#define CASE_FIXED_PARKED_PARENT_ADD 22
#define CASE_FIXED_PARKED_PARENT_ADD_TWIN 23
#define CASE_FIXED_PHASE_BETWEEN 24
#define CASE_FIXED_PHASE_BETWEEN_TWIN 25
#define CASE_RUNTIME_PARKED_PARENT_ADD_LOOP 26
#define CASE_RUNTIME_PARKED_PARENT_ADD_LOOP_TWIN 27
#define CASE_RUNTIME_PERCELL_SIBLING_ROTATED 28
#define CASE_RUNTIME_PERCELL 29
#define CASE_RUNTIME_CONDPREP_CONTROL 30
#define CASE_RUNTIME_PASSH_CONTROL 31

#ifndef CASE
#define CASE CASE_FIXED_STALE_INVARIANT_PARK
#endif

#if CASE == CASE_FIXED_STALE_INVARIANT_PARK
/* DECLINE — bd xdu2.1's own program (review F-1): invariant rail parked, relabelled by Ry, cells measured after. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_STALE_INVARIANT_PARK
/* DECLINE — row 1 on the xdu2.4 runtime-sized int b[n] bank (the isArrayAllocation branch of the hop). */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_FIXED_STALE_CONSTIDX_READ
/* DECLINE — row 1 read by a constant-index cq_measure(b[1]) -- declines at the carve, before the fence. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3];
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  return cq_measure(b[1]) + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_STALE_CONSTIDX_READ
/* DECLINE — row 3 on a runtime-sized bank. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n];
  for (int i = 0; i < n; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  return cq_measure(b[1]) + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_FIXED_STALE_THETA_ARG0
/* DECLINE — a cq_theta arg-0 read of the stale parked rail (constant index). */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3];
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  int r = cq_theta(b[1], 0.3);
  return cq_measure(r) + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_STALE_THETA_ARG0_LOOP
/* DECLINE — a cq_theta arg-0 read of the stale parked rail in a loop -- D5 refuses the reader. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(cq_theta(b[i], 0.3));
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_FIXED_RY_INSIDE_MEASURE_LOOP
/* DECLINE — relabel INSIDE the measure loop: trip 2 onward reads a stale name. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  for (int i = 0; i < 3; ++i) { s += cq_measure(b[i]); q = cq_theta(q, 0.7); }
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_PARK_CARRIED_PHI
/* DECLINE — the parked value is the loop-carried q, rotated after each park in the same loop. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) { b[i] = q; q = cq_theta(q, 0.7); }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_BOOL_STALE_INVARIANT_PARK
/* DECLINE — row 1 at _Bool cells. */
__attribute__((noinline)) int slice(int seed) {
  _Bool q = cq_theta((_Bool)seed, 0.5);
  _Bool b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_STALE_BEFORE_PARK
/* DECLINE — the rail is relabelled BEFORE it is parked (twin-gate row p05, runtime-sized). */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int c = q;
  q = cq_theta(q, 0.7);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = c;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_RUNTIME_DTZB_LOOP_XOR
/* DECLINE — parked rail relabelled by a runtime-trip in-place xor loop, then the cells measured. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int k = 0; k < n; ++k) q ^= k;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_FIXED_SECOND_BANK_INVARIANT
/* DECLINE — a per-cell-theta bank beside a stale invariant bank, one measure loop over both. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3], d[3]; int s = 0;
  for (int i = 0; i < 3; ++i) d[i] = cq_theta(d[i], 0.2);
  for (int i = 0; i < 3; ++i) b[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]) + cq_measure(d[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_CONDPREP_BESIDE_STALE
/* DECLINE — the xdu2.4 conditional-prep (grover) bank beside a stale invariant bank. */
__attribute__((noinline)) static int slice(int n) {
  if (n <= 0) return 0;
  int b[n]; int Z = 4 * n; int s = 0;
  int q = cq_theta(n, 0.3); int d[n];
  for (int i = 0; i < n; ++i) { if (Z >= 2) b[i] = cq_theta(b[i], 0.5); if (b[i]) Z -= 2; }
  for (int i = 0; i < n; ++i) d[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]) + cq_measure(d[i]);
  return s + cq_measure(q) + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#elif CASE == CASE_RUNTIME_PASSH_THETA_ESCAPES
/* DECLINE — PASS-H prep whose theta also escapes the loop and is relabelled after it. */
__attribute__((noinline)) static int slice(int n) {
  if (n <= 0) return 0;
  int b[n]; int Z = 4 * n; int s = 0;
  int t = 0;
  for (int i = 0; i < n; ++i) { t = cq_theta(b[i], 0.5); if (Z >= 2) b[i] = t; if (b[i]) Z -= 2; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(t) + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#elif CASE == CASE_RUNTIME_CONDPREP_THETA_ESCAPES
/* DECLINE — seed-path conditional prep whose arm theta escapes the loop and is relabelled. */
__attribute__((noinline)) static int slice(int n) {
  if (n <= 0) return 0;
  int b[n]; int Z = 4 * n; int s = 0;
  int t = 0;
  for (int i = 0; i < n; ++i) { if (Z >= 2) { t = cq_theta(b[i], 0.5); b[i] = t; } if (b[i]) Z -= 2; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(t) + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#elif CASE == CASE_RUNTIME_UNCOND_THETA_ESCAPES
/* DECLINE — per-cell theta that ALSO escapes the loop and is relabelled -- the in-loop-minted rail stale through its LCSSA name. */
int main(int argc, char **argv) {
  int n = 5;
  if (argc > 1) n = atoi(argv[1]);
  if (n <= 1) return 1;
  int z[n]; int Z = 0;
  for (int i = 0; i < n; i++) { z[i] = rand() % 100; Z += z[i]; }
  Z /= 2;
  int b[n]; int s = 0;
  int t = 0;
  for (int i = 0; i < n; i++) { t = cq_theta(b[i], 0.5); b[i] = t; }
  t = cq_theta(t, 0.7);
  for (int i = 0; i < n; i++) s += cq_measure(b[i]);
  return s + cq_measure(t);
}

#elif CASE == CASE_FIXED_STRAIGHT_LINE_PARK
/* DECLINE — straight-line park b[0]=b[1]=b[2]=q (no write loop): not a bank. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  b[0] = q; b[1] = q; b[2] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_FIXED_LEGIT_ORDER
/* ACCEPT — GREEN: row 1 with the measure loop moved ABOVE the rotation (review f06). */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_FIXED_LEGIT_ORDER_TWIN
/* ACCEPT — array-free twin of 20. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;
  int s = cq_measure(c) + cq_measure(c) + cq_measure(c);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_FIXED_PARKED_PARENT_ADD
/* ACCEPT — GREEN: t = q + 3 after the park, cells read after -- must stay OUT of place. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  int t = q + 3;
  s += cq_measure(t);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s;
}
int main(void) { return slice(1); }

#elif CASE == CASE_FIXED_PARKED_PARENT_ADD_TWIN
/* ACCEPT — array-free twin of 22. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;
  int t = q + 3;
  int s = cq_measure(t);
  return s + cq_measure(c) + cq_measure(c) + cq_measure(c);
}
int main(void) { return slice(1); }

#elif CASE == CASE_FIXED_PHASE_BETWEEN
/* ACCEPT — GREEN: a register-free cq_phi (diagonal, deleted as a global phase) between park and read. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  cq_phi(0.4);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_FIXED_PHASE_BETWEEN_TWIN
/* ACCEPT — array-free twin of 24. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;
  cq_phi(0.4);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
}
int main(void) { return slice(1); }

#elif CASE == CASE_RUNTIME_PARKED_PARENT_ADD_LOOP
/* ACCEPT — GREEN: runtime bank, a runtime-trip add loop on the parked parent, measured first. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int k = 0; k < n; ++k) q += k;
  s += cq_measure(q);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_RUNTIME_PARKED_PARENT_ADD_LOOP_TWIN
/* ACCEPT — array-free twin of 26. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  for (int k = 0; k < n; ++k) q += k;
  s += cq_measure(q);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_RUNTIME_PERCELL_SIBLING_ROTATED
/* ACCEPT — GREEN: the capability plus an unrelated register rotated between the loops. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int r = cq_theta(seed, 0.2);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
  r = cq_theta(r, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_RUNTIME_PERCELL
/* ACCEPT — GREEN: the canonical runtime per-cell theta bank. */
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + seed;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }

#elif CASE == CASE_RUNTIME_CONDPREP_CONTROL
/* ACCEPT — GREEN: the xdu2.4 seed-path conditional prep (store value = merge phi). */
__attribute__((noinline)) static int slice(int n) {
  if (n <= 0) return 0;
  int b[n]; int Z = 4 * n; int s = 0;
  for (int i = 0; i < n; ++i) { if (Z >= 2) b[i] = cq_theta(b[i], 0.5); if (b[i]) Z -= 2; }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#elif CASE == CASE_RUNTIME_PASSH_CONTROL
/* ACCEPT — GREEN: the xdu2.4 PASS-H emptied-arm prep (store value = select). */
__attribute__((noinline)) static int slice(int n) {
  if (n <= 0) return 0;
  int b[n]; int Z = 4 * n; int s = 0;
  for (int i = 0; i < n; ++i) { int t = cq_theta(b[i], 0.5); if (Z >= 2) b[i] = t; if (b[i]) Z -= 2; }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(Z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }

#else
#error unknown CASE
#endif
