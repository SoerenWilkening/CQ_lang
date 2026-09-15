/* attempt 3: the merged _Bool is read only by a branch that -O1 can fold away. */
int example(int u, int cl) {
  _Bool b = cq_theta(u != 0, 0.5);
  _Bool d;
  if (cl) d = b ^ 1; else d = 0;
  if (d && 0) return 7;
  return cq_measure(b);
}
