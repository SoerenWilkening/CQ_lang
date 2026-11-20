/* cq-rb96s (GLPK spx_update_d, reduced): the exit value of one K-loop is read by a second K-loop and again after it. */
double tab[9] = {1.5, 2, -1, 0.5, 3, 1, 2, 4, 1};
double ap[9] = {2, 1, 4, -2, 0.25, 1, 3, 2, 1};
double d[9] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
int upd(unsigned x0, double th, int q)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int m = x & 3, n = m + ((x >> 2) & 3);
  double dq = tab[0];
  for (int i = 1; i <= m; i++)
    dq += ap[i] * tab[i];
  double old = d[q & 7];
  double dq2 = dq / ap[2];
  d[q & 7] = dq2;
  for (int j = 1; j <= n - m; j++)
    if (j != (q & 7))
      d[j] -= ap[j] * dq2;
  double r = __builtin_fabs(dq - old) / (__builtin_fabs(dq) + 1.0);
  return r > 0.5;
}
