/* A QRAM SHADOW store: TAINTED index, tainted value, bounded local array.
   The rail-bank carve excludes it by two explicit conjuncts; the PROMOTER never
   asks qramCarveVerdict, so this measures whether the axes really are disjoint. */
int main(void) { int q = cq_theta(2, 0.5); int m[4] = {0};
  m[q] = cq_theta(7, 0.25); return cq_measure(m[q]); }
