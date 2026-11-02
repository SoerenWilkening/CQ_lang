#include "CQ.h"
/* cq-z75a (CR rules 9, 20, 24): a store under a quantum predicate into a cell an llvm.lifetime.start left undef is
   select(p, v, undef) = v, unguarded; a volatile local (unobservable) or atomic store is the plain store (musl's
   FORCE_EVAL in exp10f's specialcase: the lowered select read a handle no store had written). */
double f_once(double x) {
  double y = x;
  if (x < 1.0) {
    volatile double v = 0x1p-1022;
    y = v * 0x1p-1022;
  }
  return y;
}
double f_twice(double x) {
  volatile double v;
  double y = x;
  if (x < 1.0) v = 2.0;
  if (x < 0.5) { v = 3.0; y = v + x; }
  if (x < 1.0) y = y + v;
  return y;
}
int f_atomic(int x) {
  int y = x;
  if (x > 3) {
    _Atomic int a;
    __atomic_store_n((int *)&a, 7, __ATOMIC_SEQ_CST);
    y = __atomic_load_n((int *)&a, __ATOMIC_SEQ_CST) + x;
  }
  return y;
}
double e_once(double a) { cq_theta(&a, 0.3); return cq_measure(f_once(a)); }
double e_twice(double a) { cq_theta(&a, 0.3); return cq_measure(f_twice(a)); }
int e_atomic(int a) { cq_theta(&a, 0.3); return cq_measure(f_atomic(a)); }
