static volatile int KK = 7;
double hf(double a, double k) { if (a > 3.0) (void)KK; return k * 3.0; }
