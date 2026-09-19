/* BOUNDARY (PHI form): two DISTINCT tainted registers muxed by a classical
   condition. A call in each arm keeps clang -O1 from if-converting to select. */
int slice(int u) {
  int a;
  if (u > 0) a = cq_theta(0, 0.25); else a = cq_theta(0, 0.75);
  return cq_measure(a);
}
int main(void) { return slice(4); }
