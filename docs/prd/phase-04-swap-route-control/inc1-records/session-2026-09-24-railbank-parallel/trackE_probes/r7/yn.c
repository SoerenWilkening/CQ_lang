#include <stdlib.h>
int w(int a, int k);
int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int u = w(q, m); return cq_measure(u) + cq_measure(q); }
