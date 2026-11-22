__attribute__((noinline)) static int h(unsigned char b){ return b*3; }
__attribute__((noinline)) static int g(unsigned v){ return h((unsigned char)v) + (int)(v>>8); }
int e(int k){ unsigned char c=0; cq_theta(&c,.5); unsigned x=c;
  int r = g((x>>(k&7))&1);            /* and 1: the upper field 0 */
  r += g((x&1) ^ (unsigned)k*257);     /* xor: the upper field k*257's */
  r += g(k>3 ? (x>>1)&1 : (unsigned)k*65537); /* select on a classical condition */
  return (int)cq_measure(r); }
