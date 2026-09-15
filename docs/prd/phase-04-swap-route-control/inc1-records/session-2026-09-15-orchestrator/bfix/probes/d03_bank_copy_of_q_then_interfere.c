/* the same hazard with NO arithmetic at all: every cell parks the SAME rail */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  q = cq_theta(q, 0.9);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
