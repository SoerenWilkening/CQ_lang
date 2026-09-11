int ext_f(int a); int opaque(void); int ext(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);
    int z = 0; if (opaque()) z = ext(1);
    int r = 0; r = cq_theta(r, 0.25);
    int m = cq_measure(y);
    if (r > y) cq_phi(0.3);
    return cq_measure(r) + m + z;
}
int main(void){ (void) slice(); return 0; }
