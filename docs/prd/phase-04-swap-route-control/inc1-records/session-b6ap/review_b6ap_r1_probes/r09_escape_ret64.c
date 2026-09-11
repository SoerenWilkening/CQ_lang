#include <stdio.h>
long long probe(int seed) {
  int q = cq_theta(seed, 0.3);
  int a = cq_theta(seed, 0.4);
  long long m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  (void)cq_measure(a);
  return m;
}
int main(void){ printf("%lld\n", probe(0)); return 0; }
