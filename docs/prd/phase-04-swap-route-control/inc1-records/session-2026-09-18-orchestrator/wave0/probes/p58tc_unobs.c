int slice(int x, int n) {
  int acc = 0;
  for (int i = 0; i < n; ++i) {
    int q = cq_theta(x, 0.25);
    int w = q * 2;
    w = cq_theta(w, 0.5);
    int z = q * 3;              /* record minted after T, NEVER observed */
    (void)z;
    acc += cq_measure(w);
  }
  return acc;
}
int main(void) { return slice(1, 3); }
