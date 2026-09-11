// CF1 — a `freeze` of a value DERIVED from the peeled mux; the re-asked
// `declineTaintEscapes` performs the Phase-7.1 identity-freeze FOLD (a mutation)
// on it, which the once-only run could not.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int w = m * 3;
  printf("%d %d %d\n", cq_measure(a), cq_measure(w), cq_measure(n));
  return 0;
}
