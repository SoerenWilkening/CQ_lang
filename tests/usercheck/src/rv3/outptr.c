/* cq-jqjf: f writes through its pointer parameter, a measured value and a classical one; the memory the pointer
   reaches is a named output read after the call on both sides (CR §6 item 1). */
void f(int *out, int a, double t) { int q = a; cq_theta(&q, t);
  out[0] = cq_measure(q * 3 + 1);
  out[1] = a ^ 5; }
