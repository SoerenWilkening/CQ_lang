/* clearance probe S: the 6.5 arm is AFTER the loop; the loop's immediate is a plain constant (control: must stay byte-identical) */
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ r = r ^ 7; }
  int y=5; if (q>5) y=ext_f(7);
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
