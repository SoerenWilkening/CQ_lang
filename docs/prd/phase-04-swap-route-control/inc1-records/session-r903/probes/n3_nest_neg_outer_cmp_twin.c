int main(void) {
  int a = cq_theta(0, 0.5);
  int b = cq_theta(0, 0.3);
  if (!(a > 5)) { cq_phi(0.2); if (b > 5) cq_phi(0.3); }
  return cq_measure(a) + cq_measure(b);
}
