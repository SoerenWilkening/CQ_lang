__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;
  int t = q + 7;
  int s = cq_measure(t);
  return s + cq_measure(c) + cq_measure(c) + cq_measure(c);
}
int main(void) { return slice(1); }
