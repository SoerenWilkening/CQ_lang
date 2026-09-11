int ext_f(int a);
int slice(void) { int q = cq_theta(3, 0.5); int m = cq_measure(q);
  int y = 5; if (q > 5) y = ext_f(7); return m + cq_measure(y); }
int main(void){ (void) slice(); return 0; }
