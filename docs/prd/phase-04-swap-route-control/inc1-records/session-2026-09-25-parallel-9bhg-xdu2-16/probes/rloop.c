#include <stdlib.h>
int h(int a, int k); int ext_f(int x);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int s = 0; for (int i = 0; i < f(m); i++) s += i; return s; }
