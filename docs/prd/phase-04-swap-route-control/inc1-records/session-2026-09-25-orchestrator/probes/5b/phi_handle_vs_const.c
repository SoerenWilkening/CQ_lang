/* THE 5b-i SUBJECT in its barest form: a tainted handle muxed with a CONSTANT
   under a classical condition. */
int slice(int u) {
  int a = 5;
  if (u > 0) a = cq_theta(0, 0.25);
  return cq_measure(a);
}
int main(void) { return slice(4); }
