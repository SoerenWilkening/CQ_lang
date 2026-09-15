/* the bank's OWN rails go stale: the write loop parks a rail that the SAME loop
   then re-rotates on a later trip through a loop-carried register name */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) { b0[i] = q; q = cq_theta(q, 0.1); }
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
