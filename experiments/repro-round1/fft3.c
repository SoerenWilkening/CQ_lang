/* fft (cq-aqr5v): a classically bounded loop whose pre-header guard is `q && n != 0` (q a quantum phi) in the block that
   branches straight into the loop header, the loop's exit block also reached from an earlier return (the preheader does
   not dominate it). */
double out[16];
const double in[4] = {1, 2, 3, 4};
int f(unsigned x0, double th, unsigned long n, unsigned long s)
{
  unsigned x = x0;
  cq_theta(&x, th);
  if (n > 4)
    return 1;
  if (s > 4) s = 4;
  long nf = (x >> 4) & 3;
  int state = 0;
  for (long k = 0; k < nf; k++)
    if ((x >> k) & 1)
      state = 1 - state;
  if (state == 1)
    for (unsigned long i = 0; i < n; i++)
      out[i * s] = in[i];
  return 0;
}
