// cq-ezgjn: plain cqcc with the bundle manifest non-empty. cq-ywym5: an entry named like a generated driver's argument.
int g[4];
int a1(int x0, int y0, int i, double t) {
  int x = cq_theta_si32(x0, t);
  int y = g[x & 3];
  g[(x >> 2) & 3] = x + 1;
  return cq_measure_si32(y + 5);
}
