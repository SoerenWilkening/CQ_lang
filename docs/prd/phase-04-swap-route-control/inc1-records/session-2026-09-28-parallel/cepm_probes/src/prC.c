#include <stdlib.h>
int h(int a, int k);
#include <stdio.h>
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); printf("%d\n", t); return cq_measure(q); }
