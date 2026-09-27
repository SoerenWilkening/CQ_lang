#include <stdlib.h>
int h(int a, int k); int ext_f(int x);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int (*volatile fp)(int) = f;
int main(int argc, char **argv) { int m = atoi(argv[1]); return fp(m); }
