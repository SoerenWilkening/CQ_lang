#include <stdlib.h>
#include <string.h>
__attribute__((noinline)) int tw(int k) { return k * 3; }
__attribute__((noinline)) static int slice(int m, int n, const char *s) {
  int q = cq_theta(0, 0.5);
  int a = 7;
  if ((q > 1) & (abs(m) == n) ) a += 3;
  if ((q > 2) & ((int)strlen(s) == tw(n))) a += 1;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2]), argv[1]); }
