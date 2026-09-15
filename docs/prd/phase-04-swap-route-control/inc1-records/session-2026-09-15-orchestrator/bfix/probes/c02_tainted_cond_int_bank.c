int slice(int seed) {
  int b0[3]; int s = 0;
  int q = cq_theta(seed, 0.5);
  for (int i = 0; i < 3; ++i) {
    int t = 0;
    if (q) t = cq_theta(t, 0.25);
    b0[i] = t;
  }
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
