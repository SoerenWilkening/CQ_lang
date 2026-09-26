int main(int argc, char **argv) {
  int q = cq_theta(0, 0.7);
  int q2 = cq_theta(1, 0.4);
  int r;
  if (argc > 3) { volatile int z = 1; r = q; } else { r = q2; }
  r = cq_theta(r, 0.2);
  return cq_measure(r);
}
