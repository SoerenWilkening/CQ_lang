__attribute__((noinline)) static int *pick(int *a, unsigned k) {
    return (k & 1) ? a + ((k >> 1) & 3) : (int *)0;   /* returns a pointer into a, or NULL */
}
int ptr_return(unsigned x0, double th, int a0) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[4] = {a0, a0 + 1, a0 + 2, a0 + 3};
    int *p = pick(a, x);                 /* the pointer is quantum data: an i64 */
    int r = p ? *p : -1;                 /* NULL test, then a load through it */
    return cq_measure(r);
}
