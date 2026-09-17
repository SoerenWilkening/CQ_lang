int slice(int x) {
  int acc = 0;
  for (int i = 0; i < 100; ++i) {
    int q = cq_theta(x, 0.25);
    int w = q * 2;
    w = cq_theta(w, 0.5);
    acc += cq_measure(q) + cq_measure(w);
  }
  return acc;
}
int main(void) { return slice(1); }
