#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=cq_theta(t,.1); for (int i=0;i<n;i++) r=cq_theta(r,.2); return cq_measure(r); }
