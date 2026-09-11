/* the _Bool twin of od1 (the RAIL ladder, shipped since 1b) */
int slice(int u){ _Bool b=cq_theta((_Bool)(u&1),0.5); int acc=0;
  for (int i=0;i<3;++i){ if(b) cq_phi(0.3); if(i==2) acc+=cq_measure(b); }
  return acc; }
int main(void){(void)slice(2);return 0;}
