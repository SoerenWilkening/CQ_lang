/* GMP mpn_mu_divappr_q (reduced): a loop whose only quantum exit goes to a noreturn arm (an assertion) and whose live
   exit is classical with no count LLVM computes; a pointer it walks is read after it by a classical loop's address. */
void abort(void);
unsigned long buf[16];
int abortexit(unsigned x0, double th, unsigned n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  buf[x & 15] = x;
  unsigned long *p = buf + 12;
  long qn = (n & 7) + 1, in = ((n >> 3) & 3) + 1;
  for (;;) {
    in = in < qn ? in : qn;
    p -= in;
    if (p[0] > 1000)
      abort();
    qn -= in;
    if (qn == 0)
      break;
  }
  unsigned long s = 0;
  for (unsigned k = 0; k < ((n >> 6) & 3); k++)
    s += p[k];
  return (int)s;
}
