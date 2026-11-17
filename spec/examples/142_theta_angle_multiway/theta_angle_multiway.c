int theta_nested_angle_select(int x0, double th, int k1, int k2, int r0, double a, double b, double c) {
    int x = x0;
    cq_theta(&x, th);
    int r = r0;
    cq_theta(&r, x > k1 ? a : (x > k2 ? b : c));   /* three-way Ry angle: a select of selects on two quantum flags */
    return cq_measure(r) + cq_measure(x);
}
int theta_switch_angle(int x0, double th, int r0, double p0, double p1, double p2, double p3) {
    int x = x0;
    cq_theta(&x, th);
    double ang;
    switch (x & 3) {                              /* four-way Ry angle chosen by a quantum scrutinee */
    case 0:  ang = p0; break;
    case 1:  ang = p1; break;
    case 2:  ang = p2; break;
    default: ang = p3; break;
    }
    int r = r0;
    cq_theta(&r, ang);
    return cq_measure(r) + cq_measure(x);
}
int theta_table_angle(int x0, double th, int r0) {
    static const double tab[4] = { 0.1, 0.2, 0.3, 0.4 };
    int x = x0;
    cq_theta(&x, th);
    int r = r0;
    cq_theta(&r, tab[x & 3]);                     /* Ry angle read from a constant table at a quantum index */
    return cq_measure(r) + cq_measure(x);
}
