/* tests/spine probe (CR rule 20 Store size): a vector access is one access per lane at address + i*S. */
typedef int v2i __attribute__((vector_size(8)));
v2i vg = {3, 4}, vh;
int leaves(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  v2i t = vg;
  t[0] += x;
  vh = t;
  return cq_measure(vh[0] + vh[1]);
}
