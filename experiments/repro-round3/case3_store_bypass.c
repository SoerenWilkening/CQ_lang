/* cq-o546l reduced: a case-3 loop (classical bound, quantum exit) whose exit value is the control of a store that a
   classical branch can skip. Rule 5 keeps the control rail only with a store that ran; the loop's exit capture was kept
   outright, so on n <= 2 it stayed live. */
double Y[4];
__attribute__((noinline)) static int step(int q, long n)
{
  int st = 0;
  for (int k = 0; k < 3; k++)
    if ((q >> k) & 1) {
      st = k + 1;
      goto out;
    }
  if (n > 2)
    Y[n & 3] = 1.5;
out:
  return st;
}
int h(int q0, long n, double th)
{
  int q = q0;
  cq_theta(&q, th);
  return cq_measure(step(q, n & 7));
}
