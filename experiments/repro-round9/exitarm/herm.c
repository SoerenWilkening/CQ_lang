#include "CQ.h"
/* cq-vbep9 reduced from GSL gsl_sf_hermite_prob_array_deriv (arrangement 1010: m and x quantum, nmax and res classical):
 * the error return under `nmax < 0 || m < 0` (one quantum test) joins the return of a classically bounded loop with
 * quantum exits that runs only where nmax > 1. Before the fix the walker read the loop's result on the paths with
 * nmax <= 1, where the loop never ran (pred, Flags.cpp: "a merge arm reads a value minted where it does not reach"). */
__attribute__((noinline)) int hermc(int m, int nmax, double x, double *res) {
  if ((nmax | m) < 0) return 1;
  if (m == 0) {
    if (nmax < 2) return 0;
    double p0 = 1, p1 = x;
    for (int k = 1; k < nmax; k++) {
      if (p1 > 8.0 || p1 < -8.0) return 0;
      if (p0 > 64.0 / k) return 0;
      double p = x * p1 - k * p0;
      p0 = p1;
      p1 = p;
      res[k + 1] = p;
    }
    return 0;
  }
  if (nmax < m) return 4;
  return 2;
}
int herm(int m0, int nmax, double x0, double tm, double tx, double *res) {
  int m = m0; cq_theta(&m, tm);
  double x = x0; cq_theta(&x, tx);
  return hermc(m, nmax, x, res);
}
/* The same body in the entry. */
int herme(int m0, int nmax, double x0, double tm, double tx, double *res) {
  int m = m0; cq_theta(&m, tm);
  double x = x0; cq_theta(&x, tx);
  if ((nmax | m) < 0) return 1;
  if (m == 0) {
    if (nmax < 2) return 0;
    double p0 = 1, p1 = x;
    for (int k = 1; k < nmax; k++) {
      if (p1 > 8.0 || p1 < -8.0) return 0;
      if (p0 > 64.0 / k) return 0;
      double p = x * p1 - k * p0;
      p0 = p1;
      p1 = p;
      res[k + 1] = p;
    }
    return 0;
  }
  if (nmax < m) return 4;
  return 2;
}
