/* ROUND 4 / ArithLowering.cpp:967-969: the M-C in-place conversion decides
   "nothing reads P after this" with a MEMORY-BLIND walk.  Here P (=q) is parked
   in a rail bank and read back AFTER the add. */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;      /* q parked in every cell */
  int t = q + 7;                              /* M-C candidate on q */
  s += cq_measure(t);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);   /* reads q back */
  return s;
}
int main(void) { return slice(1); }
