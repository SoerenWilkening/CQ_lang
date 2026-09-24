#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int v = 3; if (q > 5) { printf("%d", q); v = 7; } return cq_measure(v * m); }
