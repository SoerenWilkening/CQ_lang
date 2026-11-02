#include "CQ.h"
/* cq-gujb (rules 8, 9, 18, 20): a clone's caller cell written in sequence across classical branches is one value
   of the clone: (a) an unconditional store, then a store under a quantum predicate inside a classical arm
   (musl remquo's *quo); (b) a store an earlier store reaches, on a classical arm, and quantum arms under another
   (musl __rem_pio2f's *y); (c) stores on classical arms, one path writing
   nothing, then a read of the cell and a later store (musl __rem_pio2's y[0] read back); (d) a store an earlier
   store reaches, on classical arms, some paths writing nothing (the caller's content stays). */
__attribute__((noinline)) static double sa(double x, int k, int *q) {
  *q = 0;
  if (k > 2) {
    double t = x * x;
    if (t > 1.0) {
      *q = k + 1;
      return t - x;
    }
  }
  return x * 2.0;
}
__attribute__((noinline)) static int sb(double x, int k, double *y) {
  double u = x + 1.0;
  *y = u;
  if (u < -2.0)
    return k;
  if (k & 1) {
    *y = x - 3.0;
    return k + 1;
  }
  if (k & 2) {
    if (x < 0.5) {
      *y = x * x;
      return k + 2;
    }
  }
  return k;
}
__attribute__((noinline)) static double sc(double x, int k, double *y) {
  if (k > 0) {
    *y = x;
    double t = x * x;
    if (t > 0.5) {
      *y = t - x;
      if (k > 9)
        return t;
    }
  } else {
    *y = 2.0 * x;
  }
  double r = *y + 1.0;
  if (k > 5)
    *y = r * 3.0;
  return r;
}
__attribute__((noinline)) static int sd(double x, int k, double *y) {
  if (k > 3) {
    double t = x * 3.0;
    if (t > 1.0) {
      *y = t;
      if (k > 9)
        return 1;
    }
  }
  if (k > 6)
    *y = x + k;
  return 0;
}
double clone_cell_seq_a(double x0, double th, int k) {
  double x = x0;
  cq_theta(&x, th);
  int q = 7;
  double r = sa(x, k, &q);
  return cq_measure(r) + cq_measure(q);
}
double clone_cell_seq_b(double x0, double th, int k, double init) {
  double x = x0;
  cq_theta(&x, th);
  double y = 0.5, w = init;
  int r = sb(x, k, &y);
  int r2 = sb(x * 3.0, k + 1, &w);
  return cq_measure(y) + cq_measure(w) + cq_measure(r) + cq_measure(r2);
}
double clone_cell_seq_c(double x0, double th, int k) {
  double x = x0;
  cq_theta(&x, th);
  double z = -1.0;
  double r = sc(x, k, &z);
  return cq_measure(z) + cq_measure(r);
}
double clone_cell_seq_d(double x0, double th, int k) {
  double x = x0;
  cq_theta(&x, th);
  double v = 4.0;
  int r = sd(x, k, &v);
  return cq_measure(v) + cq_measure(r);
}
