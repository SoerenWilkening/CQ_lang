/* tests/uncompute probe (cq-a24ig, CR rules 6, 14, 27 "Cutoff", owner ruling Q2 of 2026-11-14): a helper the table clone
 * of kc reaches by name has its K-loop cut at the received K, so every rail a trip after the first mints is cleaned at
 * the return under a run flag. The items under one flag share it and one block (was: each item minted its own chain of
 * run phis over every trip copy and got a block of its own; musl mbsrtowcs grew from 4.9 MB to 76.7 MB).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec kcut_items.c -o kcut_items.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int h(int x) {
  int s = 0;
  while (x > 3) {
    s += (x * 3) ^ (x + 7);
    s -= (x & 12) * 5;
    x = (x >> 1) - 1;
  }
  return s;
}
int kc(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  return cq_measure(h(x));
}
