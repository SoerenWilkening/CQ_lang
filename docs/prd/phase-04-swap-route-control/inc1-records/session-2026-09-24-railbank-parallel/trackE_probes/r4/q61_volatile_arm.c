#include <stdlib.h>
__attribute__((noinline)) static int slice(int m, int n) {
  volatile _Bool flag = (m == n);
  int q = cq_theta(0, 0.5);
  int a = 7;
  if ((q > 1) & flag) { flag = 0; a += 3; }
  return cq_measure(a) + flag;
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
