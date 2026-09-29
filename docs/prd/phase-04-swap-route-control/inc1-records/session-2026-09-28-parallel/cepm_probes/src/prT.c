#include <stdlib.h>
void g(int a);
#include <stdio.h>
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); int t = m + 1; printf("%d\n", t); return cq_measure(q); }
