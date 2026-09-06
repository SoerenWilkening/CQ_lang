int slice(int u){ int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ r = r + 5; r = cq_theta(r,0.1); }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
