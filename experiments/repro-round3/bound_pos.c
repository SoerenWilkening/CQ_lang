/* cq-7guqg (GSL gsl_sf_coupling_3j_e -> gsl_sf_lnchoose_e, reduced): one callee called with its first quantum integer
   argument bounded by 7 and, at another call, its second bounded by the same 7. Two specializations, one clone name
   (__cq_q_g_11_b7): both were constructed into one function (two bodies, the second's entry block left without a
   terminator), and the pass crashed. */
__attribute__((noinline)) static unsigned g(unsigned a, unsigned b)
{
  unsigned s = 0;
  for (unsigned i = 0; i < a; i++)
    s += b ^ i;
  return s;
}
unsigned f(unsigned x0, unsigned y0, double th)
{
  unsigned x = x0, y = y0;
  cq_theta(&x, th);
  cq_theta(&y, th);
  return g(x & 7, y) + g(y, x & 7);
}
