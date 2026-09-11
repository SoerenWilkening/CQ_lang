/* iteration-local bool, LOOP-INVARIANT seed (does -O1 hoist the mint out?) */
int ext(int);
int slice(int u){ int acc=0;
  for (int i=0;i<3;++i){ _Bool b = cq_theta((_Bool)(u&1), 0.5); if (b) cq_phi(0.3); acc += cq_measure(b) + ext(i); }
  return acc; }
int main(void){(void)slice(2);return 0;}
