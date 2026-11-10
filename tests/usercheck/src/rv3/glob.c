/* cq-jqjf: f writes a global, a measured value and a classical one; a writable global of the program is a named
   output read after the call on both sides (CR §6 item 1). */
int G[2];
int f(int a, double t) { int q = a; cq_theta(&q, t);
  G[0] = cq_measure(q + 7);
  G[1] = a * 2;
  return a; }
