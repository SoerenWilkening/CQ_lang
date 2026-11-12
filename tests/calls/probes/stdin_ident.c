/* tests/calls probe, owner ruling 2026-11-12 (cq-cyjua first half): an INPUT call whose FILE* is a quantum rail is never
   deferred: on a basis input it is performed at once on the one stream (ruling Q5), consumes what the C program consumes,
   and its stores are quantum. The FILE* is stdin or stderr by x & 1: under the checker every input call reads the one
   stream whatever its FILE (ruling Q5), so the C program reads the same bytes either way. */
#include <stdio.h>
int stdin_ident(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    FILE *fs[2] = {stdin, stderr};
    FILE *f = fs[x & 1];
    char b[8] = {0};
    char *p = fgets(b, 4, f);
    int c = getc(f);
    return cq_measure((p != 0) + b[0] * 3 + b[1] * 5 + c * 7 + x);
}
