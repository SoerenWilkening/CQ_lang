#include <stdio.h>
/* Rule 16: a host call with classical arguments in a callee that is called after a tape event is an effect entry. */
__attribute__((noinline)) static void mark(int c) { putchar(c); }
int host_call_behind_printf(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    printf("%d", x);                          /* a format entry with a rail field: the backend defers it */
    mark(c);                                  /* called after an event: its putchar must stay behind the printf */
    return cq_measure(x);
}
