/* ROUND 4 subject: a bank cell parks the result of an out-of-place template add,
   the M-C late-reassignment candidate (ArithLowering.cpp:967-969 has no
   railStoredToRailBank subtraction). */
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int t = q + 7;
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = t;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s;
}
int main(void) { return slice(1); }
