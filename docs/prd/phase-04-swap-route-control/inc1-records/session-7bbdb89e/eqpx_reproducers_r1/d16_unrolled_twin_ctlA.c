int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  r = r ^ 7; r = r ^ 7; r = r ^ 7;
  return cq_measure(r)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
