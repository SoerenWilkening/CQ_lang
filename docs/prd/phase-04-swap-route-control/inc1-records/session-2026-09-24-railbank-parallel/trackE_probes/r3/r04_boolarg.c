#include <stdlib.h>
__attribute__((noinline)) int g(int k) { return cq_theta(k, 0.7); }
__attribute__((noinline)) static int slice(_Bool c) {
  int q = cq_theta(0, 0.5);
  int a = 7;
  if ((q > 1) & c) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { int r = g(atoi(argv[1])); return slice(r == atoi(argv[2])); }
