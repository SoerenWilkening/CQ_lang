#include <stdlib.h>
int h(int a, int k); int ext_f(int x);
__attribute__((noinline)) int f2(int m) { int q = cq_theta(m, .5); return h(q, m); }
__attribute__((noinline)) int f1(int m) { return f2(m) * 2; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return cq_measure(f1(m)); }
