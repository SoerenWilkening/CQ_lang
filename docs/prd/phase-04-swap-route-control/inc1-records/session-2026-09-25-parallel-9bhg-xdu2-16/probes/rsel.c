#include <stdlib.h>
int h(int a, int k); int ext_f(int x);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int q2 = cq_theta(m, .25); int r = f(m) > 2 ? q2 + 1 : q2; return cq_measure(r); }
