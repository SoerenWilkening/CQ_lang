/* the register twin of f06 — the GREEN half of the pair */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;
  int s = cq_measure(c) + cq_measure(c) + cq_measure(c);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
