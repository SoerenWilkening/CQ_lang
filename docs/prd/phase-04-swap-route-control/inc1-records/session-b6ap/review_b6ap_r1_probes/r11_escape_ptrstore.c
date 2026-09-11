#include <stdio.h>
int arr[4];
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  arr[1] = m;
  printf("%d %d\n", cq_measure(a), arr[1]);
  return 0;
}
