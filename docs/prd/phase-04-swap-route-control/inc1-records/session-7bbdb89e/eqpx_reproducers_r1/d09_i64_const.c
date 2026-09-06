int slice(int u){ long long r=cq_theta((long long)u,0.3);
  for(int i=0;i<3;i++){ r = r ^ 7; }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
