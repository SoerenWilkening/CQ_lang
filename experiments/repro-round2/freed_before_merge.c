double ytmp[4], yy[4];
static int step(int q, long dim) {
  if (q & 1) return 1;
  if (dim > 0) ytmp[0] = yy[0];
  if ((q >> 1) & 1) return 1;
  for (long i = 0; i < dim; i++) ytmp[i & 3] = yy[i & 3];
  return 0;
}
int hang(int q0, long dim, double th) { int q = q0; cq_theta(&q, th); return cq_measure(step(q, dim)); }
