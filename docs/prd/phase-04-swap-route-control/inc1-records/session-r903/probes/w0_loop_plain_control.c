int main(void) {
  int q = cq_theta(0, 0.5);
  for (int i = 0; i < 3; i++) {
    if (q > 5) cq_phi(0.3);
    q = cq_theta(q, 0.1);
  }
  return cq_measure(q);
}
