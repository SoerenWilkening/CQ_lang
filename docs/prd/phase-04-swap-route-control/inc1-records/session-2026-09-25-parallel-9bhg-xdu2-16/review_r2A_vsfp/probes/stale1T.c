int main(void) {
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { r = 5; } else { r = 9; }
  q = cq_theta(q, 0.3);
  return cq_measure(q) + cq_measure(r);
}
