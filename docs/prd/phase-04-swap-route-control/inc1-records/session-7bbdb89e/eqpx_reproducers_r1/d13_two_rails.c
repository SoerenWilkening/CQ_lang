int slice(int u){ int a=cq_theta(u,0.5); int b=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ a = a ^ 7; b = b ^ 3; }
  return cq_measure(a)+cq_measure(b); }
int main(void){ (void)slice(5); return 0; }
