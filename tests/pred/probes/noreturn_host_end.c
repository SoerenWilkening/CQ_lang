#include "CQ.h"
#include <stdlib.h>
// USERCHECK classical
// USERCHECK quantum
// USERCHECK after_measure
// USERCHECK classical_after_arm
// cq-tdqrq: a real host exit ends the shot with rails live; an exit under a quantum condition is rule 16's flag.

int classical(int b, int c) {
  cq_theta(&b, 1.0);
  int s = b * 3;
  if (c & 1) exit(1);
  if (c & 2) exit(2);
  return cq_measure(s);
}

int quantum(int b) {
  cq_theta(&b, 1.0);
  int s = b * 3;
  if (b & 1) exit(1);
  return cq_measure(s);
}

// The measured value is classical from there on: the exit is real and its condition varies with b.
int after_measure(int b) {
  cq_theta(&b, 1.0);
  int s = b * 3;
  int m = cq_measure(b & 1);
  if (m) exit(3);
  return cq_measure(s);
}

// A classical exit behind a quantum exit: on a shot whose flag reads 1 the first end was the quantum one.
int classical_after_arm(int b, int c) {
  cq_theta(&b, 1.0);
  int s = b * 3;
  if (b & 1) exit(4);
  if (c & 1) exit(5);
  return cq_measure(s);
}
