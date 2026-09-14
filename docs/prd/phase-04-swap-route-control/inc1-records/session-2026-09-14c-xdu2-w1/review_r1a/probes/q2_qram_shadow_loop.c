int main(void) { int q = cq_theta(2, 0.5); int m[4] = {0}; int s = 0;
  for (int i = 0; i < 4; ++i) { m[q] = cq_theta(i, 0.25); }
  s += cq_measure(m[0]); return s; }
