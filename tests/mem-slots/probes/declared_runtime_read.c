#include "CQ.h"
/* cq-e5lj (CR rule 27): a run-time-index read after a declared clone call, dominating (decl_rt1) or on some paths
   only (decl_rt): the load names the twin pseudo rail and every cell handle at the call. Main stopped at both. */
extern void ext_mod(int *p);
int decl_rt(int k, int x0, double th) {
  int a[4];
  for (int i = 0; i < 4; i++) { a[i] = x0 + i; cq_theta(&a[i], th); }
  if (k == 3) ext_mod(a);
  return cq_measure(a[k & 3]);
}
extern void ext_mod(int *p);
int decl_rt1(int k, int x0, double th) {
  int a[4];
  for (int i = 0; i < 4; i++) { a[i] = x0 + i; cq_theta(&a[i], th); }
  ext_mod(a);
  return cq_measure(a[k & 3]);
}
