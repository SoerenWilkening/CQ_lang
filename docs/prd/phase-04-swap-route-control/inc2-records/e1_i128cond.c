int slice(void) {
    __int128 q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);
    p = cq_theta(p, 0.25);
    if (q > (__int128)5) { p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2; }
    return cq_measure(p);
}
int main(void){(void)slice();return 0;}
