int main(void) {
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { volatile int z = 1; r = 5; } else { r = 9; }
  r = cq_theta(r, 0.2);
  return cq_measure(r);
}
