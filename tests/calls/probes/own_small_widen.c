int tab[8]={3,1,4,1,5,9,2,6};
__attribute__((noinline)) long q(int n){ return (unsigned)tab[n&7]; }
int f(int a){ cq_theta(&a, 1.0); long p=q(3); return (int)cq_measure((int)p)+(int)(p>>32)+cq_measure(a); }
