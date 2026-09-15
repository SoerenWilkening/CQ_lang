int out[3];
int slice(int seed) {
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
  for (int i = 0; i < 3; ++i) out[i] = b0[i];   /* parked rail copied to a GLOBAL */
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s;
}
int main(void) { return slice(0); }
