struct P { unsigned char a, b; };
unsigned char out[4];
__attribute__((noinline)) static void g(struct P p){ out[p.b & 3] = p.a; }
int e(int k){ unsigned char c=0; cq_theta(&c,.5);
  struct P q = { (unsigned char)k, (unsigned char)(k >> 8) }, s = { c, c };
  if (c & 1) g(q);   /* a _ctl clone whose packed formal has no quantum field */
  g(s);
  return (int)cq_measure(out[0] + out[1] + out[2] + out[3]); }
