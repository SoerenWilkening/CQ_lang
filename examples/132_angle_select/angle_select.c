int phi_angle_select(int x0, double th, int k, double a, double b) {
    int x = x0;
    cq_theta(&x, th);
    cq_phi(x > k ? a : b);                 /* the angle is a select on a quantum flag */
    return cq_measure(x);
}
int theta_angle_select(int x0, double th, int k, int r0, double a, double b) {
    int x = x0;
    cq_theta(&x, th);
    int r = r0;
    cq_theta(&r, x > k ? a : b);           /* Ry by one of two angles, chosen by a quantum flag */
    return cq_measure(r) + cq_measure(x);
}
int nested_angle_select(int x0, double th, int k1, int k2, double a, double b, double c) {
    int x = x0;
    cq_theta(&x, th);
    cq_phi(x > k1 ? a : (x > k2 ? b : c)); /* three-way angle: a select of selects */
    return cq_measure(x);
}
int shared_angle_select(int x0, double th, int k, int r0, double a, double b) {
    int x = x0;
    cq_theta(&x, th);
    double ang = x > k ? a : b;
    int r = r0;
    cq_phi(ang);                           /* one select feeds two rotation consumers */
    cq_theta(&r, ang);
    return cq_measure(r) + cq_measure(x);
}
