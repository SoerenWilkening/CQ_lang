/* clearance probe C: the immediate reaches the loop THROUGH an alloca (7.5 Shadow) written in a 6.5 arm */
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int buf[2]; buf[0]=5; buf[1]=3;
  if (q>5) buf[0]=ext_f(7);
  int w = buf[0] & 7;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
