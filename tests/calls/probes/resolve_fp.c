/* tests/calls probe (cq-sd95; CR rules 19, 27, §1.3 clone_resolve): a call through a function pointer with no
 * in-module candidate (an entry's parameter) and a quantum argument is the call of the function's registered
 * all-handles clone, clone_resolve(fp, 0), every actual a handle (a classical one a seed rail) and K trailing;
 * under a quantum predicate its _ctl, clone_resolve(fp, 1), merged by select; the twin is clone_resolve(fp, 2).
 * "lower": the callee is outside the program, so neither oracle can run it. */
int r_plain(int (*fp)(int), int x) { cq_theta(&x, 0.3); return cq_measure(fp(x)); }
int r_ctl(int (*fp)(int, int), int x, int c) {
  cq_theta(&x, 0.3);
  int r = 0;
  if (x & 1) r = fp(x, c);
  return cq_measure(r);
}
