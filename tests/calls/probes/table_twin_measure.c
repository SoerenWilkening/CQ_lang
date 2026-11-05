__attribute__((noinline)) static int g(int v,int w){ return cq_measure(v)+w; }
__attribute__((noinline)) static int h(int v,int w){ return v-w; }
static int (*const tab[2])(int,int) = {g,h};
int e_cl(int x0, int w0, double tx, double ty, int c) {
  int x = x0, w = w0;
  cq_theta(&x, tx);
  cq_theta(&w, ty);
  int r = tab[c & 1](x, w);
  return cq_measure(r * r);
}
int e_rail(int x0, int w0, double tx, double ty, int c) {
  int x = x0, w = w0, y = c;
  cq_theta(&x, tx);
  cq_theta(&w, ty);
  cq_theta(&y, tx+ty);
  int r = tab[y & 1](x, w);
  return cq_measure(r * r);
}
