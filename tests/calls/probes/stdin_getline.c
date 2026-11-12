/* tests/calls probe, ruling Q5 (cq-wjysl): getline twice on one buffer it allocates and grows, getdelim on a space, fgetln
   (the line's address and length), each consuming from the one stream; the second getline under a quantum predicate. */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
int stdin_getline(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    char *line = 0;
    size_t cap = 0;
    ssize_t n1 = getline(&line, &cap, stdin);
    int a = line[0];
    ssize_t n2 = 0;
    if (x & 1)
        n2 = getline(&line, &cap, stdin);
    int b = line[1];
    ssize_t n3 = getdelim(&line, &cap, ' ', stdin);
    int c = line[0];
    size_t len = 0;
    char *l = fgetln(stdin, &len);
    int d = l ? l[0] : -1;
    free(line);
    return cq_measure((int)n1 + (int)n2 * 3 + (int)n3 * 5 + a * 7 + b * 11 + c * 13 + d * 17 + (int)len * 19 + x);
}
