int count_nonzero(unsigned char c0, double th) {
    unsigned char c = c0;
    cq_theta(&c, th);
    unsigned char s[4];
    s[0] = c; s[1] = c + 1; s[2] = c ^ 3; s[3] = 0;
    int n = 0;
    for (unsigned char *p = s; *p; p++)
        n++;
    return cq_measure(n);
}
