double g(double *m, unsigned long n, double s);
double D[4] = {1, 2, 3, 4};
int main(void) { double s = 0; cq_theta(&s, 1.0); return cq_measure((int)g(D, 4, s)); }
