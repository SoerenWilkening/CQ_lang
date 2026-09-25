#include <stdlib.h>
int h(int a, int k); int ext_f(int x);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int y = 5; if (q > 5) y = ext_f(7); return t + y; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m) * 3; }
