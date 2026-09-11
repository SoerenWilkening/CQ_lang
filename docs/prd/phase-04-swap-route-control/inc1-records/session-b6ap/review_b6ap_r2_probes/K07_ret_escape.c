// K07 — K06 cleaned: the mux reaches an i32 `ret` (an ALLOWED escape).
#include <stdio.h>
__attribute__((noinline)) static int body(int seed) {
  int q = 0, a = 0;
  q = cq_theta(seed, 0.3);
  a = cq_theta(seed, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  if (cq_measure(a) + cq_measure(n) > 100) return 0;
  return m;
}
int main(void) { printf("%d\n", body(0)); return 0; }
