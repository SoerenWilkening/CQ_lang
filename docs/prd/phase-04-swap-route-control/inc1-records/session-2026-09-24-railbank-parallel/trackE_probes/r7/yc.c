#include <stdlib.h>
int h(int a, int k); int g(int a);
int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (g(t) > 3) r = m + 5; return cq_measure(r); }
