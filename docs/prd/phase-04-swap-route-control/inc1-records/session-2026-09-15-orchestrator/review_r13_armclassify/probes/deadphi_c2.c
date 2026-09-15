/* attempt 2: a classical if/else whose merged _Bool is never read. */
int example(int u, int cl) {
  _Bool b = cq_theta(u != 0, 0.5);
  _Bool d;
  if (cl) d = b ^ 1; else d = 0;
  (void)d;
  return cq_measure(b);
}
