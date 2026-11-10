/* cq-5yuk9 (§1.4): static helpers clang -O1 makes `internal fastcc`: their clones, the twins and every call of one are fastcc. */
static __attribute__((noinline)) int h(int x, int y){ return x*y + (x^y); }
static __attribute__((noinline)) int g(int x){ return h(x, x+1) - 3; }
static __attribute__((noinline)) int w(const int *p, int x){ return p[x&3] ^ x; }
int e(int k){ char c=0; cq_theta(&c,.5); int m[4]={k,3,k+1,7}; int a=h(c,k); int r=0; if(c&1) r=h(a,c)+g(c)+w(m,a); int z=r*a; return cq_measure(z); }
