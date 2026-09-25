#include <stdlib.h>
int g(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int r=t; if (m>3) r=cq_theta(t,.2); int u=g(r,n); return cq_measure(u); }
