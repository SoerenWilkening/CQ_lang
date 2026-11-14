#include "CQ.h"
#include <stdlib.h>
// USERCHECK two_tests
// USERCHECK classical_inner
// USERCHECK in_arm
// USERCHECK status_phi
// USERCHECK siblings
// USERCHECK classical_guard
// USERCHECK nested_inner
// USERCHECK nested_no_live_exit
// USERCHECK nested_three
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
// cq-o75xb: a classical guard into a noreturn arm. Owner ruling 2026-11-11 Q7 (cq-edr1f): this module holds abort events
// and the function is externally visible, so an event can precede the exit: the effect entry exit under a |1> seed,
// then abort_i1 of it (a real host exit is noreturn_real_exit.c's).
int classical_guard(int a, int c) {
  cq_theta(&a, 1.0);
  if (c & 1) exit(0);
  int i = 0;
  while (1) {
    i++;
    if ((a >> i) == 3) exit(0);
    g += 1;
  }
  return 0;
}
// cq-9isy0: the inner loop's edge into the arm is an exit edge of the outer loop too: its a_K reads 0 once the arm fired.
int nested_inner(int a, int b) {
  cq_theta(&a, 1.0);
  cq_theta(&b, 1.0);
  int s = 0;
  for (int i = 0; (a >> i) != 0; i++)
    for (int j = 0; (b >> j) != 0; j++) {
      if ((b >> j) == 5) abort();
      s += 1;
    }
  return cq_measure(s);
}
// The same, the outer loop's only way out being the inner loop's arm.
void nested_no_live_exit(int b) {
  cq_theta(&b, 1.0);
  for (;;) {
    for (int j = 0; (b >> j) != 0; j++) {
      if ((b >> j) == 5) abort();
      g += 1;
    }
    g += 2;
  }
}
// Three levels: the arm stops both enclosing chains.
int nested_three(int a, int b, int d) {
  cq_theta(&a, 1.0);
  cq_theta(&b, 1.0);
  cq_theta(&d, 1.0);
  int s = 0;
  for (int i = 0; (a >> i) != 0; i++)
    for (int j = 0; (b >> j) != 0; j++)
      for (int k = 0; (d >> k) != 0; k++) {
        if ((d >> k) == 5) abort();
        s += 1;
      }
  return cq_measure(s);
}
