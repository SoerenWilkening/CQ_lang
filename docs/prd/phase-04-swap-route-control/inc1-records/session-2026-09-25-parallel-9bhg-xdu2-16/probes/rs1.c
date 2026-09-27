#include <stdlib.h>
int h(int a, int k);
int G;
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return cq_theta(t, .3); }
int main(int argc, char **argv) { int m = atoi(argv[1]); G = f(m); return 0; }
