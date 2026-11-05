/* tests/spine probe (CR rules 5, 20): under a quantum predicate every bus access is _controlled, a constant global's
 * too (`_hl_controlled`); the copy's _unc takes the same control; a kept store keeps its control rail. */
static const int ROM[2] = {7, 9};
int g = 5, h = 6;
int arm_access(int x0, double tx, int y0, double ty) {
  int x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  int r = 0;
  if (x > 0) {
    r = g + ROM[1];
    h = y;
  } else {
    r = h - ROM[0];
    g = 3;
  }
  return cq_measure(r);
}
