int ext_f(int a); int opaque(void); int ext(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);
    int z = 0; if (opaque()) z = ext(1);
    int b  = cq_theta(y, 0.25);
    int b3 = cq_theta(y, 0.9);
    if (b > 1) cq_phi(0.3);
    int b2 = cq_theta(b, -0.25);
    return cq_measure(b3) + cq_measure(b2) + z;
}
int main(void){ (void) slice(); return 0; }
