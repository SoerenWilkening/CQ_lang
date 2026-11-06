#include "CQ.h"
#include <stdlib.h>
// USERCHECK top
// USERCHECK value
// USERCHECK live_exit
// USERCHECK in_classical_arm
// USERCHECK classical_test
// USERCHECK classical_switch
// USERCHECK classical_switch_arm
// USERCHECK under_arm
// USERCHECK no_live_exit
// USERCHECK two_levels
// USERCHECK in_k_loop
// USERCHECK guarded_in_k_loop
// USERCHECK k_in_classical_in_k
// cq-2mg1f: a classical-bound loop with an edge into a noreturn arm (rules 14, 16), with or without an enclosing K-loop.

// The bead's probe: the quantum exit test goes to the arm, the latch keeps the classical bound.
int top(int b) {
  cq_theta(&b, 1.0);
  int s = 0;
  for (int j = 0; j < 3; j++) {
    if ((b >> j) == 5) abort();
    s += 1;
  }
  return cq_measure(s);
}

int value(int b) {
  cq_theta(&b, 1.0);
  int s = 0;
  for (int j = 0; j < 3; j++) {
    if ((b >> j) == 5) abort();
    s += b >> j;
  }
  return cq_measure(s);
}

// A quantum exit into the arm and one into the continuation: -O1 folds them into a switch.
int live_exit(int b, int n) {
  cq_theta(&b, 1.0);
  int s = 0;
  for (int j = 0; j < n; j++) {
    if ((b >> j) == 5) abort();
    if ((b >> j) == 2) break;
    s += j;
  }
  return cq_measure(s + b);
}

// The exit test sits in a classical arm of the trip: the trip predicate joins.
int in_classical_arm(int b, int n) {
  cq_theta(&b, 1.0);
  int s = b;
  for (int j = 0; j < n; j++) {
    if (j & 1) {
      if ((b >> j) == 5) abort();
    }
    s += j;
  }
  return cq_measure(s);
}

// A classical test into the arm with a quantum exit in the same loop, classical bound elsewhere.
int classical_test(int b, int n, int m) {
  cq_theta(&b, 1.0);
  int s = 0;
  for (int j = 0; j < n; j++) {
    if (j == m) exit(1);
    if ((b >> j) == 2) break;
    s += j;
  }
  return cq_measure(s + b);
}

int classical_switch(int b, int n, int m) {
  cq_theta(&b, 1.0);
  int s = b;
  for (int j = 0; j < n; j++) {
    switch (j - m) {
    case 2: exit(1);
    case 7: exit(2);
    default: break;
    }
    s += j;
  }
  return cq_measure(s);
}

// The same switch under a quantum predicate: abort flags with their classical terms seeded, no real call.
int classical_switch_arm(int b, int n, int m) {
  cq_theta(&b, 1.0);
  int s = b;
  if (b & 1)
    for (int j = 0; j < n; j++) {
      switch (j - m) {
      case 2: exit(1);
      case 7: exit(2);
      default: break;
      }
      s += j;
    }
  return cq_measure(s);
}

// The whole loop under a quantum arm; the arm itself branches on a rail.
int under_arm(int b, int n) {
  cq_theta(&b, 1.0);
  int s = 0;
  if (b & 1)
    for (int j = 0; j < n; j++) {
      if ((b >> j) == 5) {
        if (b & 2) abort();
        else exit(2);
      }
      s += b;
    }
  return cq_measure(s);
}

// Case 1 with no live exit at all: the classical test into the arm is the only way out.
int no_live_exit(int b, int m) {
  cq_theta(&b, 1.0);
  int s = b;
  for (int j = 0;; j++) {
    if (j == m) exit(0);
    s += j;
  }
  return cq_measure(s);
}

int two_levels(int b, int n, int m) {
  cq_theta(&b, 1.0);
  int s = 0;
  for (int i = 0; i < n; i++)
    for (int j = 0; j < m; j++) {
      if (((b >> i) ^ j) == 5) abort();
      s += b >> j;
    }
  return cq_measure(s);
}

// Inside a K-loop the arm is an exit edge of that loop too: a_K and later trips exclude it.
int in_k_loop(int b) {
  cq_theta(&b, 1.0);
  int s = 0;
  int i = 0;
  while ((b >> i) != 0 && i < 9) {
    for (int j = 0; j < 3; j++) {
      if (((b >> i) ^ j) == 5) abort();
      s += 1;
    }
    i++;
  }
  return cq_measure(s);
}

// The same behind a classical guard: the K-loop's trip joins the stop rail with a |0> seed on the skip path.
int guarded_in_k_loop(int b, int n) {
  cq_theta(&b, 1.0);
  int s = 0;
  int i = 0;
  while ((b >> i) != 0) {
    if (n > 0)
      for (int j = 0; j < n; j++) {
        if (((b >> i) ^ j) == 5) abort();
        s += j;
      }
    i++;
  }
  return cq_measure(s);
}

// A K-loop inside a classical loop inside a K-loop: its flags cross the classical unit.
int k_in_classical_in_k(int b) {
  cq_theta(&b, 1.0);
  int s = 0;
  int o = 0;
  while ((b >> o) != 0) {
    for (int j = 0; j < 2; j++) {
      int i = 0;
      while (((b >> j) >> i) != 0) {
        if ((b ^ i) == 9) abort();
        i++;
      }
      s += i;
    }
    o++;
  }
  return cq_measure(s);
}
