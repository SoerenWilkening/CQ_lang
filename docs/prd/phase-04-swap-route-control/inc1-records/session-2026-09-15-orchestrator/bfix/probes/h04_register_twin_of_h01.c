__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int t = q + 7;
  return cq_measure(t) + cq_measure(t) + cq_measure(t);
}
int main(void) { return slice(1); }
