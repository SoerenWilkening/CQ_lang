static long A[4096];
static long *T[4] = { &A[5], &A[42], &A[79], &A[116] };
int main(void) {
    for (int i = 0; i < 4096; i++) A[i] = i * 7 + 1;
    unsigned char q = 2; cq_theta(&q, 0.0);
    long *p = T[q & 3]; return (int)cq_measure(*p & 127);
}
