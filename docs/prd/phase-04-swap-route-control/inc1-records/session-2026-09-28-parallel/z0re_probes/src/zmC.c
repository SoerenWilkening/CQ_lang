#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q, m); int q2=cq_theta(n,.3); int r=t; if (q2>3) r=cq_theta(t,.2); else r=cq_theta(t,.5); int s=r; if (m>1) s=cq_theta(r,.1); return cq_measure(s)+cq_measure(q2); }
