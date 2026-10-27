int quantum_strlen(const double *th, int cap) {          /* cap <= 4: the buffer size */
    char s[4] = {0, 0, 0, 0};
    for (int i = 0; i < cap; i++) {
        s[i] = 'a';
        cq_theta(&s[i], th[i]);                            /* every char is quantum */
    }
    int n = 0;
    while (n < cap && s[n] != 0)                           /* exit on a quantum NUL, bounded by the buffer */
        n++;
    return cq_measure(n);
}
int quantum_strcmp(const double *ta, const double *tb, int cap) {
    char a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0};
    for (int i = 0; i < cap; i++) {
        a[i] = b[i] = 'a';
        cq_theta(&a[i], ta[i]);
        cq_theta(&b[i], tb[i]);
    }
    int i = 0;
    while (i < cap && a[i] != 0 && a[i] == b[i])            /* two quantum exit conditions */
        i++;
    return cq_measure(i < cap ? a[i] - b[i] : 0);          /* the chars at the quantum exit index */
}
