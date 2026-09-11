/* f03 — an i32 seed equal to a live i32 register pinned on the arm edge. */
int slice(int y) {
  int q = cq_theta(y, 0.2);
  _Bool b = cq_theta((_Bool)(q & 1), 0.5);
  int r = 7;
  if (b) { r = cq_theta(7, 0.9); }
  return (int)cq_measure(b) + cq_measure(r) + cq_measure(q);
}
int main(void){(void)slice(1);return 0;}
