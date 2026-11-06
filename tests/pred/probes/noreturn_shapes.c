#include "CQ.h"
#include <stdlib.h>
// USERCHECK two_tests
// USERCHECK classical_inner
// USERCHECK in_arm
// USERCHECK status_phi
// USERCHECK siblings
// cq-172vi, cq-0etzs: noreturn arms around them. -O1 merges the aborts of two_tests into one block with two false edges.
int g;
int two_tests(int a) {
  cq_theta(&a, 1.0);
  if (a & 1) abort();
  g += 1;
  if (a & 2) abort();
  return cq_measure(a);
}
// A classical test's false edge inside a quantum arm.
int classical_inner(int a, int c) {
  cq_theta(&a, 1.0);
  int r = 0;
  if (a > 3) {
    if (c & 4) exit(1);
    r = 5;
  }
  return r + cq_measure(a);
}
// A dead end with a quantum branch of its own, on a false edge.
int in_arm(int a) {
  cq_theta(&a, 1.0);
  if (a & 2) {
    if (a & 4) g += 1;
    abort();
  }
  return cq_measure(a);
}
// The shared arm reads a phi: the guard's edge and the trip's edge give different statuses.
void status_phi(int a) {
  cq_theta(&a, 1.0);
  int i = 0;
  if (a == 7) exit(9);
  while (1) {
    i++;
    if ((a >> i) == 7) exit(i);
    g += 1;
  }
}
// Two K-loops in a row exit into one merged arm, each one's edges outside the other.
int siblings(int a, int b) {
  cq_theta(&a, 1.0);
  cq_theta(&b, 1.0);
  int s = 0;
  for (int i = 0; (a >> i) != 0; i++) {
    if ((a >> i) == 5) abort();
    s += 1;
  }
  for (int j = 0; (b >> j) != 0; j++) {
    if ((b >> j) == 5) abort();
    s += 2;
  }
  return cq_measure(s);
}
