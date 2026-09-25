#include <stdlib.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int q2=cq_theta(n,.3); int r=t; if (q2>3) r=cq_theta(t,.2); int w=cq_theta(r,.9); return cq_measure(w)+cq_measure(q2); }
