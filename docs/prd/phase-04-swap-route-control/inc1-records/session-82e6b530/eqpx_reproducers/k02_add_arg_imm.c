__attribute__((noinline))
int run(int seed, int n){ int r=cq_theta(seed,0.3);
  for(int i=0;i<3;i++){ r = r + n; r = cq_theta(r,0.1); }
  return cq_measure(r); }
int main(void){ (void)run(5,9); return 0; }
