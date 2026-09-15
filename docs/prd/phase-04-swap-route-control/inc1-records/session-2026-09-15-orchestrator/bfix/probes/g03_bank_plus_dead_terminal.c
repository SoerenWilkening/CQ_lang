/* a bank BESIDE an ordinary dead-terminal chain, so the spine actually emits
   an adjoint + free in the same function */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int d = q + 3;                 /* dead terminal -> _unc + cqrt_free */
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.25);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q) + (d & 0);
}
int main(void) { return slice(1); }
