/* Failure 3 (loops-classical: a mirror item reads a value defined in a segment that does not dominate its own): a case-3
   loop's quantum exit test inside a classical arm of the trip (k & 1) whose in-loop edge goes on to more code of the arm
   before the arm rejoins at the latch; the exit's flag is made in the arm's segment and read by the latch's captures. */
int a[8];
int f(unsigned x0, double th, int n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  for (int k = 0; k < n && k < 6; k++) {
    if (k & 1) {
      a[6] += 1;
      if ((x >> k) & 1) {
        a[0] = k;
        return 5;
      }
      a[5] += 2;
    }
    a[1 + k] += 1;
  }
  return 0;
}
