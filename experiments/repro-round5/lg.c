double g(double *m, unsigned long n, double s) { double t = 0; for (unsigned long i = 0; i < n; i++) t += m[i] * s; return t; }
