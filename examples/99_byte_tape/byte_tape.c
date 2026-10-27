#include <stdio.h>
int byte_tape(unsigned char x0, double th, int k) {
    unsigned char x = x0;
    cq_theta(&x, th);
    unsigned char buf[3] = { x, (unsigned char)(x + 1), 'z' };
    fwrite(buf, 1, 3, stdout);
    if (x > k)
        fputs("hi\n", stdout);
    return cq_measure(x);
}
