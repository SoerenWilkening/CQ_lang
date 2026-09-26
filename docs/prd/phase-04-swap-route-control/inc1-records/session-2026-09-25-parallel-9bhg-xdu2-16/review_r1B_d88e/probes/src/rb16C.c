#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=q2; if (m>3) r=cq_theta(q2,.2); int s=r+t; return cq_measure(s); }
