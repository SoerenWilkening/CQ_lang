/* tests/loops-cutoff trip-CFG probes (cq-b58q, CR rules 14, 8, 9, 13): a K-loop trip is any acyclic code, its
 * branches and switches on classical or quantum conditions (rule 14: "same chain"); a classical term of a trip
 * predicate is a seed rail (rule 8), a classical phi of the trip a classical select (rule 9).
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate trip_cfg.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_cfg.c -o trip_cfg.O1.ll */
#include "CQ.h"
/* A classical branch in the body (the division keeps it a branch), its arms merged by a classical phi. */
int tc_branch(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do {
    int t;
    if (c > i) t = 100 / (c - i); else t = i * 5;
    acc = acc * 3 + t;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* A switch on a classical scrutinee in the body. */
int tc_switch(int x0, double th, int m) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do {
    switch ((m + i) & 3) {
    case 0: acc += 7; break;
    case 1: acc = acc / 3 + 100 / (m | 1); break;
    case 2: acc -= 2; break;
    default: acc ^= 9;
    }
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* A switch on a quantum scrutinee in the body. */
int tc_qswitch(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do {
    switch ((x + i) & 3) {
    case 0: acc += 7; break;
    case 1: acc *= 3; break;
    case 2: acc -= 2; break;
    default: acc ^= 9;
    }
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* A phase under a classical condition inside the trip. */
int tc_phase(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  int i = 0;
  do {
    if ((c >> i) & 1) cq_phi(0.375);
    i++;
  } while ((x >> i) & 1);
  return cq_measure(x);
}
/* A classical and a quantum branch nested in the body. */
int tc_nested(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  int acc = 0, i = 0;
  do {
    if (c > i) {
      if ((x >> (i + 4)) & 1) acc += 100 / (c - i);
      else acc -= 1;
    }
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
