int main(void) {
  int q = cq_theta(0, 0.3);
  int t = q & 1;
  if (t) cq_phi(0.3);
  return cq_measure(q);
}
