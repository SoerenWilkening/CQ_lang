int main(void) {
  int q = cq_theta(0, 0.5);
  int acc = 0;
  for (int i = 0; i < 3; i++) {
    if (q > 5) cq_phi(0.3);
    int t = q & 7;
    int a = cq_theta(t, 0.1);
    q = cq_theta(a, 0.9);
    acc += cq_measure(a);
  }
  return acc + cq_measure(q);
}
