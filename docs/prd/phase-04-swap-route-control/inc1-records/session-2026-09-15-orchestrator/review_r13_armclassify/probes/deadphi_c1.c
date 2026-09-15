/* Does clang -O1 ever leave a DEAD i1 phi over a tainted i1 pure op?  attempt 1:
   a self-referential loop-carried accumulator that is never read. */
int example(int u) {
  _Bool b = cq_theta(u != 0, 0.5);
  _Bool acc = 0;
  for (int i = 0; i < 4; ++i) acc = acc ^ b;
  (void)acc;
  return cq_measure(b);
}
