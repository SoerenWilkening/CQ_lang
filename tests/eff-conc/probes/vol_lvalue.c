#include "CQ.h"
/* cq-6b2i1: an observable volatile access is a bus access, the overlay makes it a host access for a HOST cell and a
   correct one for a QUANTUM cell. v1..v3: a volatile lvalue over a non-volatile object holding a rail, so C defines the
   value (§6). vl1, vl3, vl5: objects that are volatile themselves. vp_*: under a quantum predicate; vc: a local whose
   address is only compared stays on the bus. */
__attribute__((noinline)) static int rd(volatile int *p) { return *p; }
int v1(int x, double th) { cq_theta(&x, th); int a = x + 1; int r = rd(&a); return cq_measure(r); }

int g2;
int v2(int x, double th) { cq_theta(&x, th); g2 = x; int r = *(volatile int *)&g2; return cq_measure(r); }

int g3;
int v3(int x, double th) { cq_theta(&x, th); g3 = x; *(volatile int *)&g3 = 5; return cq_measure(g3 + x); }

volatile int gv1;
int vl1(int x, double th) { cq_theta(&x, th); gv1 = x; return cq_measure(gv1 + 1); }

int vl3(int x, double th, int k) {
  volatile int a, b;
  volatile int *p = (k & 1) ? &a : &b;
  cq_theta(&x, th);
  a = x;
  b = x + 1;
  return cq_measure(*p);
}

static volatile int gv5 = 3;
int *q5;
__attribute__((noinline)) static void cap(int *p) { q5 = p; }
int vl5(int x, double th) { cap((int *)&gv5); cq_theta(&x, th); *q5 = x; return cq_measure(gv5 + 1); }

/* The load under a predicate, unguarded and merged, over a HOST cell and over a QUANTUM cell; the cell changes in the arm. */
volatile int gp = 11;
int vp_host(int x, double th, int k) {
  cq_theta(&x, th);
  int r = 7;
  if (x > k) r = gp;
  return cq_measure(r + x);
}
int gq;
int vp_quantum(int x, double th, int k) {
  cq_theta(&x, th);
  gq = x + 1;
  int r = 7;
  if (x > k) { r = *(volatile int *)&gq; gq = r + 2; }
  return cq_measure(r + gq);
}
/* The same, in a callee reached under the predicate (its _ctl clone), and at an address rail under the predicate. */
__attribute__((noinline)) static int rdg(void) { return gp + 1; }
int vp_ctl(int x, double th) {
  cq_theta(&x, th);
  int r = 2;
  if (x & 1) r = rdg();
  return cq_measure(r + x);
}
volatile int tab[4] = {3, 4, 5, 6};
int vp_rail(int x, double th, int k) {
  cq_theta(&x, th);
  int r = 1;
  if (x > k) { r = tab[x & 3]; tab[x & 3] = r + 1; }
  return cq_measure(r + tab[0]);
}
/* A store of a rail under a predicate (p_vol_obs_pred has the classical value). */
volatile int gs;
int vs_pred(int x, double th, int k) {
  cq_theta(&x, th);
  gs = 1;
  if (x > k) gs = x;
  return cq_measure(gs);
}
/* A local whose address is compared: observable by rule 24's test, and on the bus. */
int vc(int x, double th, int *o) {
  volatile int a = 4;
  int same = (int *)&a == o;
  cq_theta(&x, th);
  a = 9;
  return cq_measure(a + x + same);
}
