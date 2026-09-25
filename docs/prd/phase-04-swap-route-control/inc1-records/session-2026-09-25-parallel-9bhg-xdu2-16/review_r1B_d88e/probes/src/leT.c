#include <stdlib.h>
int g(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int r=t; if (m>3) r=cq_theta(t,.2); int w=cq_theta(n,.1); int z=(r>5)?w:cq_theta(w,.3); return cq_measure(z)+cq_measure(r); }
