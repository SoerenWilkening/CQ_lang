#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int arr[4] = {0,0,0,0}; arr[q & 3] = 7; int x = arr[n & 3]; int u = g2(x, q); return cq_measure(u); }
