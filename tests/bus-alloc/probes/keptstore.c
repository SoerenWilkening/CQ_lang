// cq-xoc4: a kept store's value rail is a classical merge (phi) whose store a classical branch bypasses: on the paths
// with no store its arms (a template result and a load copy) are undone, never kept.
unsigned ks_phi(unsigned x0, unsigned y0, double tx, double ty, unsigned c, unsigned d) {
  unsigned x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty);
  unsigned a[4] = {c, c + 1, c + 2, d};
  unsigned r;
  if (c & 1) { a[x & 3] = y; r = a[(x + 1) & 3]; }
  else { a[(x + 2) & 3] = y * 3u; r = a[x & 3] + 1; }
  if (d & 2) a[(x + 3) & 3] = r;
  return cq_measure(a[(x + 1) & 3] ^ a[d & 3]);
}
