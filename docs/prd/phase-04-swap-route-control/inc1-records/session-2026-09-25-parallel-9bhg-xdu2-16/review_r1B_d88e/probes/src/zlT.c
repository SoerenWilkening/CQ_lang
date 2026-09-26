#include <stdlib.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int q2=cq_theta(n,.3); int r=t; if (m>2) r=cq_theta(t,.9); int s=r; if (q2>3) s=cq_theta(r,.2); return cq_measure(s)+cq_measure(q2); }
