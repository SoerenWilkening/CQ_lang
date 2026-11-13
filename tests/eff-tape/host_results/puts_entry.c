/* cq-025xt (owner ruling 2026-11-13; CR rule 16 Results): after an effect entry under a quantum predicate (an event),
 * puts is an effect entry: its result is musl's (puts.c: 0 when the write succeeds), whatever the host returns. */
#include <stdio.h>
int puts_entry(int x) {
  int q = x & 1;
  cq_theta(&q, 0.5);
  if (q & 1)
    putchar('!');
  int r = puts("e");
  return r * 256 + (cq_measure(q) & 1);
}
