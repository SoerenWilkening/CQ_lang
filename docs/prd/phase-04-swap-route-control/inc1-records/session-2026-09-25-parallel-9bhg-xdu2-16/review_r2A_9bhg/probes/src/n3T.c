#include <stdlib.h>
int out1(int a, int b); int out2(int a, int b); int out3(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return (m + 1) * 2 + m; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return f(m) + n; }
