#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m); }
