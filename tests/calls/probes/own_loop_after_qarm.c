int tab[8]={3,1,4,1,5,9,2,6};
__attribute__((noinline)) int h1(int x){ return x*3+1; }
__attribute__((noinline)) int h2(int x){ return x*5+2; }
__attribute__((noinline)) int r(int s){ double t=0.25; if(tab[s&7]>3) cq_phi(0.3); int k=0; for(int i=0;i<s;i++){ if(i&1) k=h1(k); else k=h2(k); } return k+tab[0]; }
int f(int a){ return cq_measure(r(a&3)); }
