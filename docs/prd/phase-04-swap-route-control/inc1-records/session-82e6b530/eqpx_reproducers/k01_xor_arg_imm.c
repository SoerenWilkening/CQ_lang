/* CAPABILITY CONTROL: a loop rail xor whose immediate is a function ARGUMENT
   (classical, non-Constant). An isa<Constant>(Imm) fence at the LOOP writers
   would refuse this. */
__attribute__((noinline))
int run(int seed, int n){ int r=cq_theta(seed,0.3);
  for(int i=0;i<3;i++){ r = r ^ n; }
  return cq_measure(r); }
int main(void){ (void)run(5,9); return 0; }
