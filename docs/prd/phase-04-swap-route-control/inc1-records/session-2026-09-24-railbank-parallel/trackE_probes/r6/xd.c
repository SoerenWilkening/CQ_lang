#include <stdlib.h>
int h(int a, int k);
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int t = h(q, m); return cq_measure(t * n); }
