int main(void) {
  int q = cq_theta(0, 0.7);
  double ang;
  if (q > 3) { ang = 0.3; } else { ang = 0.9; }
  cq_phi(ang);
  return cq_measure(q);
}
