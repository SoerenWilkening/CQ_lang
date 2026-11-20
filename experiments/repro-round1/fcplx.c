// cq-zd8jo: a <2 x float> (gsl_complex_float) phi joining a K-loop's exits, quantum key.
typedef struct { float dat[2]; } gsl_complex_float;
__attribute__((noinline)) gsl_complex_float find(const float *keys, const gsl_complex_float *vals, int n, float k) {
  for (int i = 0; i < n; i++)
    if (keys[i] == k) return vals[i];
  gsl_complex_float z = {{0, 0}};
  return z;
}
int fcplx(int x0, double th) {
  float keys[3] = {1, 2, 3};
  gsl_complex_float vals[3] = {{{1, 2}}, {{3, 4}}, {{5, 6}}};
  int x = x0;
  cq_theta(&x, th);
  gsl_complex_float z = find(keys, vals, 3, (float)(x & 3));
  return cq_measure((int)(z.dat[0] + 10 * z.dat[1]));
}
