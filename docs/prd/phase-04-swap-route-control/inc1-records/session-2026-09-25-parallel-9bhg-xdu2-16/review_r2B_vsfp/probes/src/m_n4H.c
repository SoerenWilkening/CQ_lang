#include <stdlib.h>
int out1(int a, int b); int out2(int a, int b); int out3(int a, int b);
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int t = (n + 1) * 2 + n; int u = out1(q, t); return cq_measure(u); }
