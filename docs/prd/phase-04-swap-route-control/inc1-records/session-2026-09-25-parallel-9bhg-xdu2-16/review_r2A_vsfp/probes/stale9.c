int main(void) {
  int q = cq_theta(0, 0.7);
  int p = cq_theta(0, 0.2);
  double ang;
  if (q > 3) { volatile int z = 1; ang = 0.3; } else { ang = 0.9; }
  p = cq_theta(p, ang);
  return cq_measure(p);
}
