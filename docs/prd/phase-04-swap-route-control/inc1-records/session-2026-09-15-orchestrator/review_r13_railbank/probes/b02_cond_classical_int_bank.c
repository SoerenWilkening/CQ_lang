int slice(int seed) {
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) {
    int t = 0;
    if ((seed >> i) & 1) t = cq_theta(t, 0.5);   /* CLASSICAL condition, int cells */
    b0[i] = t;
  }
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s;
}
int main(void) { return slice(5); }
