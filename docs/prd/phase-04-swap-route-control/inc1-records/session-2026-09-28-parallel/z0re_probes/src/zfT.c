#include <stdlib.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m + 1); int q2=cq_theta(n,.3); int q3=cq_theta(n+1,.6); int r=t; if (q2>3) r=cq_theta(t,.2); int s=r; if (q3>2) s=cq_theta(r,.4); return cq_measure(s)+cq_measure(q2)+cq_measure(q3); }
