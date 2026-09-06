int slice(int u){ int r=cq_theta(u,0.3);
  int w; switch(u & 3){ case 0: w=1; break; case 1: w=2; break; case 2: w=4; break; default: w=8; }
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
