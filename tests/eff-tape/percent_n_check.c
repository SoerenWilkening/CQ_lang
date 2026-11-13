/* cq-jp8qu (owner ruling 2026-11-12, output-call results): a quantum char printed before %n. The circuit computes
 * printf's result and the %n count with the lifted __cq_count_snprintf (musl: n = 1, result 1 on every input); the
 * measured n * 16 + r is compared against the C program, whose reference runs the same musl count natively.
 * Checked by percent_n_check.sh (slow). */
#include <stdio.h>
int pn(int xv) {
  cq_theta(&xv, 0.3);
  int n = -1;
  int r = printf("%c%n", 'a' + (xv & 1), &n);
  cq_measure(n * 16 + r);
  return 0;
}
