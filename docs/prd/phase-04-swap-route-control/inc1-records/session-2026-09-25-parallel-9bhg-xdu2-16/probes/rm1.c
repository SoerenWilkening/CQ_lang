#include <stdlib.h>
int h(int a, int k);
int G;
__attribute__((noinline)) int f(int m, int c) { int q = cq_theta(m, .5); int t = h(q, m); if (c > 2) return t; return q; }
int main(int argc, char **argv) { int m = atoi(argv[1]); G = f(m, atoi(argv[2])); return 0; }
