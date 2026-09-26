#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); volatile int vt=t; int r=cq_theta(m,.4); if (m>3) r=cq_theta(r,.2); return cq_measure(r)+vt; }
