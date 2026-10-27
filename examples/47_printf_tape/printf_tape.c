#include <stdio.h>
int printf_quantum(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    printf("%d\n", x);
    return cq_measure(x);
}
int printf_under_quantum_if(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k)
        printf("big %d\n", x);
    return cq_measure(x);
}
int printf_mixed(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int y = x + c;
    printf("%d %d %d\n", x, c, y);
    return cq_measure(y);
}
