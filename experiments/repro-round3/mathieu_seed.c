/* cq-xspwx (GSL gsl_sf_mathieu_Mc_e, reduced): a classical branch on `order` picks one of two K-loops with a quantum exit,
   both exiting into one block with a double phi. The walker lays the even arm's loop out, then the odd arm behind a
   classical guard whose skip edge (taken on the even arm's path) goes to that block. The skip found no incoming outside
   the loop units and seeded |0> with ConstantInt::get on a double type (`i0 0` into cqrt_alloc_f64); typed right, the
   seed would still have replaced the even loop's result by 0.0 on that path. (The entry returns an int: a double entry
   result does not pass cqcheck on either build, cq-xspwx report.) */
#define N 8
int calls;
__attribute__((noinline)) static double jn_(int k, double x) { calls++; return x * k + 1.0; }
__attribute__((noinline)) static double yn_(int k, double x) { calls++; return x - k; }
__attribute__((noinline)) static double sgn(double e) { calls++; return ((long)e & 1) ? -1.0 : 1.0; }
__attribute__((noinline)) static int char_a(int order, double q, double *a) { *a = q * order; return order > 6; }
__attribute__((noinline)) static int fill(int order, double q, double a, double *c)
{
  for (int k = 0; k < N; k++)
    c[k] = k < 3 ? (q + a) / (k + 1) : 0.0;
  return 0;
}
int mc(int kind, int order, double q, double *result)
{
  double coeff[N], amax = 0.0, fn = 0.0, aa;
  if (q <= 0.0)
    return 1;
  if (kind < 1 || kind > 2)
    return 2;
  int status = char_a(order, q, &aa);
  if (status)
    return status;
  status = fill(order, q, aa, coeff);
  if (status)
    return status;
  if (order % 2 == 0) {
    for (int kk = 0; kk < N; kk++) {
      amax = amax > __builtin_fabs(coeff[kk]) ? amax : __builtin_fabs(coeff[kk]);
      if (__builtin_fabs(coeff[kk]) / amax < 1e-14)
        break;
      double z = kind == 1 ? jn_(kk, 2.0) : yn_(kk, 2.0);
      fn += sgn(0.5 * order + kk) * coeff[kk] * z;
    }
  } else {
    for (int kk = 0; kk < N; kk++) {
      amax = amax > __builtin_fabs(coeff[kk]) ? amax : __builtin_fabs(coeff[kk]);
      if (__builtin_fabs(coeff[kk]) / amax < 1e-14)
        break;
      double z = kind == 1 ? jn_(kk + 1, 3.0) : yn_(kk + 1, 3.0);
      fn += sgn(0.5 * (order - 1) + kk) * coeff[kk] * (z + 1.0);
    }
  }
  *result = fn / coeff[0];
  return 0;
}
int f(double q0, double th, int order, int kind)
{
  double q = q0, r = 0;
  cq_theta(&q, th);
  mc(kind, order, q, &r);
  return (int)(r * 64.0);
}
