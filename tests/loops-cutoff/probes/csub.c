/* tests/loops-cutoff classically bounded loop inside a K-loop trip (cq-h5uj, cq-odo1; CR rule 14 case 1 or 3 inside
 * case 2): the inner loop stays a classical loop over its classical bound, lowered once per unrolled trip under the
 * trip predicate, behind a real classical branch on the trip's classical path to its header (a zero-trip guard false
 * skips it; its values read after it are |0> there). musl __rem_pio2_large's `for (fw = 0, j = 0; j <= jx; j++)`
 * inside its quantum `for (i = jz + 1; i <= jz + k; i++)`. Each entry is checked §6 against its own C program
 * (cqcheck user). Regenerate csub.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec csub.c -o csub.O1.ll */
#include "CQ.h"
/* The hang repro of cq-h5uj: a classical bound m (m = 0 skips the inner loop: -O1's guard before the rotated loop). */
int cs_guard(int x0, int m0, double th) {
  int m = m0 & 7;   /* a small classical bound (each inner trip pushes its frame) */
  int x = x0 & 7; cq_theta(&x, th);
  int j = 0, s = 0;
  while (j < x) {
    for (int i = 0; i < m; i++)
      s += i ^ j;
    j++;
  }
  return cq_measure(s);
}
/* A constant bound (no guard): the inner loop runs in every trip; its value read after it in place. */
int cs_const(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 0;
  do {
    int t = acc;
    for (int k = 0; k < 3; k++)
      t = t * 3 + k + i;
    acc = t;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* A classical loop reading memory at a quantum index in each trip (the __rem_pio2_large shape: f[jx + i - j]). */
double cs_mem(int x0, int n0, const double *c, double th) {
  int n = n0 & 7;
  int x = x0 & 3; cq_theta(&x, th);
  double f[8], acc = 0;
  for (int k = 0; k < 8; k++)
    f[k] = c[k];
  for (int i = 0; i < x; i++) {
    double fw = 0;
    for (int j = 0; j < n; j++)
      fw += c[j] * f[(i + 3 - j) & 7];
    acc += fw;
  }
  return cq_measure(acc);
}
/* A case-3 loop (classical bound with a quantum exit) inside a K trip. */
int cs_case3(int x0, int m0, double th) {
  int m = m0 & 7;
  int x = x0; cq_theta(&x, th);
  int i = 0, s = 0;
  do {
    int k;
    for (k = 0; k < m; k++)
      if ((x >> (k + 4)) & 1)
        break;
    s += k;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(s);
}
/* A classical loop in a K-loop's exit arm (after a break of the K-loop), its bound m guarded. */
int cs_arm(int x0, int m0, double th) {
  int m = m0 & 7;
  int x = x0; cq_theta(&x, th);
  int i = 0, r = 0;
  do {
    if ((x >> (i + 8)) & 1)
      goto found;
    i++;
  } while ((x >> i) & 1);
  r = i;
  goto join;
found:
  for (int k = 0; k < m; k++)
    r = r * 3 + ((x >> k) & 5) + i;
join:
  return cq_measure(r);
}
/* A bound that varies per trip (the K-loop's induction): trip 0 skips the inner loop by its guard. */
int cs_tri(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, s = 1;
  do {
    for (int k = 0; k < i; k++)
      s = s * 3 + (k ^ x);
    i++;
  } while ((x >> i) & 1);
  return cq_measure(s);
}
