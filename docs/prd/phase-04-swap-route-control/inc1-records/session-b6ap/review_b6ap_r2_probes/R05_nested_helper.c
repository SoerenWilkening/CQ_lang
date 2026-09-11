// R05 — r20 where the (noinline) helper itself calls a second noinline helper
// (the 6.3 TRANSITIVE path) with the peeled mux.
#include <stdio.h>
__attribute__((noinline)) static int inner(int x) { return x * 3; }
__attribute__((noinline)) static int outer(int x) { return inner(x) + 1; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3); a = cq_theta(a, 0.4);
  int m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  int t = outer(m);
  printf("%d %d\n", cq_measure(a), cq_measure(t));
  return 0;
}
