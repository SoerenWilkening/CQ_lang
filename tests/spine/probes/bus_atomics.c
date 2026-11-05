/* tests/spine probe (CR rules 4, 24): cmpxchg and atomicrmw are a bus load, the templates and a kept store. */
_Atomic int c1 = 2, c2 = 3, c3 = 4;
int atomics(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  int a = __c11_atomic_exchange(&c1, x, 5);
  int exp = 3;
  __c11_atomic_compare_exchange_strong(&c2, &exp, x, 5, 5);
  int b = __c11_atomic_fetch_and(&c3, x, 5);
  return cq_measure(a + exp + b);
}
