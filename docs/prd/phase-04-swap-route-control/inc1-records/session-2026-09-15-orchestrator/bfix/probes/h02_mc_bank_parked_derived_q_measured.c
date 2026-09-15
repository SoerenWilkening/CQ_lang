__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int t = q + 7;
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = t;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);          /* q ALSO measured — the aliasing question */
}
int main(void) { return slice(1); }
