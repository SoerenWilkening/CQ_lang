/* tests/loops-classical probes (cq-w3cd): a classical branch nested in a quantum arm of a trip (CR rule 8:
 * the classical part stays a classical branch; rule 9 merges), andthe mixed joins it makes.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec carm.c -o carm.O1.ll */
#include <stdbool.h>
#include "CQ.h"
int a_diamond(int n, int c, double t) {      /* arms meet at the quantum join directly */
  int x = 0; cq_theta(&x, t); int s = 0;
  for (int i = 0; i < n; i++) { if (x == i) { if (c == i) s += 3; else s += x; } }
  return cq_measure(s);
}
int a_inner(int n, int c, double t) {        /* the classical arms meet inside the quantum arm */
  int x = 0; cq_theta(&x, t); int s = 0;
  for (int i = 0; i < n; i++) { if (x & 1) { int y = (c > i) ? x + i : x - i; s ^= y * 3; } s += 1; }
  return cq_measure(s);
}
int a_phase(int n, int c, double t) {        /* phases in the classical arms of a quantum arm */
  int x = 0; cq_theta(&x, t);
  for (int i = 0; i < n; i++) { if (x == i) { if (c & (1 << i)) cq_phi(t); else cq_phi(t / 2); } }
  return cq_measure(x);
}
