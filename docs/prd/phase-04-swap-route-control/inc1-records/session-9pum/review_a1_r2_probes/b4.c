/* iteration-local bool minted INSIDE a guarded sub-block of the body */
int ext(int); int opaque(void);
int slice(int u){ int acc=0;
  for (int i=0;i<3;++i){ if (opaque()) { _Bool b = cq_theta((_Bool)0, 0.5); if (b) cq_phi(0.3); acc += cq_measure(b); } acc += ext(i); }
  return acc; }
int main(void){(void)slice(2);return 0;}
