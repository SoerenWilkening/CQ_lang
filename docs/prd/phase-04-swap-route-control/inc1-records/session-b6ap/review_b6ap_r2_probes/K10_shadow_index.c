// K10 — the mux indexes a SHADOW (alloca) array (`lowerShadowMemory`, :593).
#include <stdio.h>
__attribute__((noinline)) static int body(int seed) {
  int arr[8] = {0,1,2,3,4,5,6,7};
  int q = cq_theta(seed, 0.3);
  int a = cq_theta(seed, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int v = arr[m & 7];
  return cq_measure(a) + cq_measure(v) + cq_measure(n);
}
int main(void) { printf("%d\n", body(0)); return 0; }
